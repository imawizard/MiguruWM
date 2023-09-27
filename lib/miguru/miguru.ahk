#include events.ahk
#include monitors.ahk
#include utils.ahk
#include workspaces.ahk
#include layouts\floating.ahk
#include layouts\fullscreen.ahk
#include layouts\spiral.ahk
#include layouts\tall.ahk
#include layouts\threecolumn.ahk
#include layouts\wide.ahk
#include FocusIndicator.ahk
#include HazeOver.ahk

WS_THICKFRAME       := 0x00040000
WS_SYSMENU          := 0x00080000
WS_DLGFRAME         := 0x00400000
WS_BORDER           := 0x00800000
WS_CAPTION          := 0x00C00000
WS_POPUP            := 0x80000000
WS_VISIBLE          := 0x10000000
WS_CHILD            := 0x40000000
WS_EX_DLGMODALFRAME := 0x00000001
WS_EX_TOPMOST       := 0x00000008
WS_EX_CLICKTHROUGH  := 0x00000020
WS_EX_TOOLWINDOW    := 0x00000080
WS_EX_WINDOWEDGE    := 0x00000100
WS_EX_CLIENTEDGE    := 0x00000200
WS_EX_STATICEDGE    := 0x00020000
WS_EX_APPWINDOW     := 0x00040000
WS_EX_LAYERED       := 0x00080000
WS_EX_NOACTIVATE    := 0x08000000

WM_QUIT := 0x012

WM_SYSCOMMAND := 0x112
SC_MOVE       := 0xf010
SC_SIZE       := 0xf000

WM_KEYDOWN := 0x100
WM_KEYUP   := 0x101

VK_LEFT  := 0x25
VK_UP    := 0x26
VK_RIGHT := 0x27
VK_DOWN  := 0x28

ERROR_ACCESS_DENIED     := 5
ERROR_INVALID_PARAMETER := 87

CTRL_C_EVENT     := 0
CTRL_BREAK_EVENT := 1
CTRL_CLOSE_EVENT := 2

DetectHiddenWindows(true)

;; Built-in constant isn't updated when dpi changes.
A_SystemDPI := A_ScreenDPI

class MiguruWM extends WMEvents {
    __New(opts := {}) {
        this._opts := ObjMerge({
            layout: "tall",
            masterSize: 0.5,
            masterCount: 1,
            padding: { left: 0, top: 0, right: 0, bottom: 0 },
            spacing: 0,

            tilingMinWidth: 0,
            tilingMinHeight: 0,
            tilingInsertion: "before-mru",
            floatingAlwaysOnTop: false,

            focusFollowsMouse: false,
            mouseFollowsFocus: false,

            followWindowToWorkspace: false,
            followWindowToMonitor: false,

            focusWorkspaceByWindow: false,

            showPopup: (*) =>,
            focusIndicator: {
                Show: (*) =>,
                Hide: (*) =>,
                Unmanaged: (*) =>,
                SetMonitorList: (*) =>,
                HideWhenPositioning: false,
                ShowOnFocusRequest: false,
                UpdateOnRetile: false,
            },

            delays: {
                retryManage: 100,
                windowHidden: 400,
                onDisplayChange: 1000,
                sendMonitorRetile: 100,
                retile2ndTime: 200,
            },
        }, opts)

        this._monitors := MonitorList()
        this._workspaces := WorkspaceList(this._monitors, ObjClone(this._opts))
        this._managed := Map()
        this._pinned := Map()
        this._delayed := Timeouts()

        this._maybeActiveWindow := ""
        this._opts.focusIndicator.SetMonitorList(this._monitors)

        windowTracking := GetSpiInt(SPI_GETACTIVEWINDOWTRACKING)
        if windowTracking !== this._opts.focusFollowsMouse {
            this._oldFFM := windowTracking
            SetSpiInt(SPI_SETACTIVEWINDOWTRACKING, this._opts.focusFollowsMouse)
        }

        super.__New()
        this._initWithCurrentDesktopAndWindows()
    }

    Do(what, opts := {}) {
        PostMessage(WM_REQUEST, ObjPtrAddRef(ObjMerge({
            type: what,
        }, opts)), , , "ahk_id" A_ScriptHwnd)
    }

    Set(what, opts := {}) {
        this.Do("set-" what, opts)
    }

    Get(what, opts := {}) {
        res := SendMessage(WM_REQUEST, ObjPtrAddRef(ObjMerge({
            type: "get-" what,
        }, opts)), , , "ahk_id" A_ScriptHwnd)
        if res <= 0 {
            return res
        }
        return ObjFromPtr(res).value
    }

    static Version {
        get => IsSet(MIGURU_VERSION)
            ? MIGURU_VERSION
            : "x.y.z"
    }

    static SetupTrayMenu() {
        tray := A_TrayMenu

        tray.Delete()
        tray.Add("Version " this.Version, (*) =>)
        tray.Disable("1&")
        tray.Add()
        tray.Add("Disable", TogglePause)
        tray.Add("Start Miguru on Login", ToggleAutostart)
        tray.Add("Edit script ...", (*) => Edit())
        tray.Add()
        tray.Add("Visit homepage ...", (*) =>
            Run("https://github.com/imawizard/MiguruWM"))
        tray.Add("Relaunch Miguru", (*) => Reload())
        tray.Add()
        tray.Add("Quit Miguru", (*) => ExitApp())

        TogglePause(*) {
            if !A_IsSuspended {
                tray.Rename("Disable", "Enable")
                Suspend(true)
            } else {
                tray.Rename("Enable", "Disable")
                Suspend(false)
            }
        }

        link := A_Startup "\" A_ScriptName ".lnk"
        if FileExist(link) {
            tray.Check("Start Miguru on Login")
        }

        ToggleAutostart(*) {
            if !FileExist(link) {
                FileCreateShortcut(A_ScriptFullPath, link, A_ScriptDir)
                tray.Check("Start Miguru on Login")
            } else {
                FileDelete(link)
                tray.Uncheck("Start Miguru on Login")
            }
        }

        A_IconTip := "「 Miguru Window Manager 」"
        TraySetIcon("*", , true)
    }

    __Delete() {
        if this.HasProp("_oldFFM") {
            SetSpiInt(SPI_SETACTIVEWINDOWTRACKING, this._oldFFM)
        }
    }

    Options => ObjClone(this._opts)

    _onWindowEvent(event, hwnd) {
        if A_IsSuspended {
            return
        }

        switch event {
        case EV_WINDOW_FOCUSED:
            if WinExist("ahk_id" hwnd
                " ahk_exe explorer.exe ahk_class VirtualDesktopGestureSwitcher")
             || WinExist("ahk_id" hwnd
                " ahk_exe explorer.exe ahk_class ForegroundStaging") {
                this.activeWsMonitors[this.activeWsIdx] := this.activeMonitor
                goto fallthrough
            }

            monitor := this._monitors.ByWindow(hwnd)

            ;; Set currently active monitor if changed.
            if monitor !== this.activeMonitor {
                debug("Active Display: #{} -> #{}",
                    this.activeMonitor.Index, monitor.Index)

                this.lastMonitor := this.activeMonitor
                this.activeMonitor := monitor
            }

            goto fallthrough

        case EV_WINDOW_SHOWN, EV_WINDOW_UNCLOAKED, EV_WINDOW_RESTORED, EV_WINDOW_REPOSITIONED:
            fallthrough:

            ;; To not miss any windows that were already created and thus
            ;; e.g. appear for the first time by unhiding instead of
            ;; creation, add new windows on any event.
            window := this._manage(event, hwnd)
            if !window {
                if event == EV_WINDOW_FOCUSED
                    && !WinExist("ahk_id" hwnd " ahk_group MIGURU_IGNORE") {
                    debug("Set active to non-managed {}", WinInfo(hwnd))
                    this._maybeActiveWindow := hwnd
                    this._opts.focusIndicator.Unmanaged(hwnd)
                }
                return
            }

            monitor := this._monitors.ByWindow(hwnd)
            wsIdx := this.VD.DesktopByWindow(hwnd)
            switch wsIdx {
            case 0, VD_UNASSIGNED_WINDOW, VD_UNKNOWN_DESKTOP:
                warn(() => ["Invalid desktop for managed window {}",
                    WinInfo(hwnd)])
                this._drop(hwnd)
                return
            case VD_PINNED_APP, VD_PINNED_WINDOW:
                if !this._pinned.Has(hwnd) {
                    debug(() => ["Window got pinned {}", WinInfo(hwnd)])
                    this._pinWindow(hwnd, window)
                }
            default:
                if this._pinned.Has(hwnd) {
                    debug(() => ["Window got unpinned {}", WinInfo(hwnd)])
                    this._unpinWindow(hwnd, window, wsIdx)
                }
            }

            ;; Adjust when a window changed desktop or monitor.
            if monitor !== window.monitor ||
                wsIdx > 0 && wsIdx !== window.workspace.Index {
                idx := wsIdx > 0 ? wsIdx : this.activeWsIdx
                ws := this._workspaces[monitor, idx]
                this._reassociate(hwnd, window, monitor, ws)
            }

            try {
                if WinGetMinMax("ahk_id" hwnd) < 0 {
                    return
                }

                ws := window.workspace
                if ws.AddIfNew(hwnd) {
                    this._delayed.Add(
                        ws.Retile.Bind(ws),
                        this._opts.delays.retile2ndTime,
                        "retile-2nd-time",
                    )
                }
            } catch as err {
                warn("Dropping window: {} {}", err.Message, WinInfo(hwnd))
                this._drop(hwnd)
                return
            }

            if event == EV_WINDOW_FOCUSED || hwnd == this._maybeActiveWindow {
                debug(() => ["Focused: D={} WS={} {}",
                    monitor.Index, ws.Index, WinInfo(hwnd)])

                ws.ActiveWindow := hwnd
                this._maybeActiveWindow := ""
                this._opts.focusIndicator.Show(hwnd)

                ;; If it's an explorer window, focus the content panel.
                if WinExist("ahk_id" hwnd
                    " ahk_exe explorer.exe ahk_class CabinetWClass") {
                    try {
                        ControlFocus("DirectUIHWND2", "ahk_id" hwnd)
                    } catch TargetError {
                        ;; Do nothing
                    } catch OSError {
                        ;; Do nothing
                    }
                }

            } else if event == EV_WINDOW_REPOSITIONED {
                debug(() => ["Repositioned: D={} WS={} {}",
                    monitor.Index, ws.Index, WinInfo(hwnd)])

                ws.Retile()
            }

        case EV_WINDOW_POSITIONING:
            if this._opts.focusIndicator.HideWhenPositioning {
                this._opts.focusIndicator.Hide()
            }

        case EV_WINDOW_HIDDEN, EV_WINDOW_CLOAKED, EV_WINDOW_MINIMIZED:
            this._hide(event, hwnd)

        case EV_WINDOW_DESTROYED:
            this._drop(hwnd)

        case EV_WINDOW_CREATED:
            ;; Do nothing

        default:
            throw "Unknown window event: " event
        }
    }

    _onDesktopEvent(event, args) {
        switch event {
        case EV_DESKTOP_CHANGED:

            ;; Discard pending window removals.
            this._delayed.Drop("window-hidden")

            debug(() => ["Active Desktop: {} -> {}",
                this.VD.DesktopName(args.was), this.VD.DesktopName(args.now)])

            this.lastWsIdx := this.activeWsIdx
            this.activeWsIdx := args.now
            this._opts.showPopup.Call(this.VD.DesktopName(args.now), {
                activeMonitor: this.activeMonitor.Index,
            })

            oldWs := this._workspaces[this.activeMonitor, args.was]
            newWs := this._workspaces[this.activeMonitor, args.now]

            oldWs.ActiveWindow := ""
            if newWs.WindowCount < 1 {
                this._opts.focusIndicator.Hide()
            } else {
                this._opts.focusIndicator.Show(newWs.ActiveWindow)
            }

            ;; Add pinned windows to the newly active workspace or retile.
            if this._pinned.Count > 0 {
                for k in this._pinned {
                    window := this._managed[k]
                    ws := this._workspaces[window.monitor, this.activeWsIdx]
                    if !ws.AddIfNew(k) {
                        ws.Retile()
                    }
                }
            }

        case EV_DESKTOP_RENAMED:
            debug("Renamed Desktop #{}: `"{}`"", args.desktop, args.name)

            ;; Do nothing

        case EV_DESKTOP_CREATED:
            debug(() => ["Created Desktop: {}",
                this.VD.DesktopName(args.desktop)])

            ;; Do nothing

        case EV_DESKTOP_DESTROYED:
            debug("Destroyed Desktop: #{}", args.desktopId)

            ;; Do nothing

        default:
            throw "Unknown desktop event: " event
        }
    }

    _onRequest(req) {
        getMonitor() {
            idx := this.activeMonitor.Index
            if req.HasProp("monitor") {
                anchor := ""
                offset := 0

                if req.monitor is Object {
                    anchor := req.monitor.anchor
                    if req.monitor.HasProp("offset") {
                        offset := req.monitor.offset
                    }
                } else if req.monitor {
                    anchor := req.monitor
                }

                switch anchor {
                case "current":
                    ;; Do nothing
                case "primary":
                    idx := this._monitors.Primary.Index
                case "next":
                    idx += 1
                case "previous":
                    idx -= 1
                case "first":
                    idx := 1
                case "last":
                    idx := this._monitors.Count
                case "mru":
                    if this.lastMonitor {
                        idx := this.lastMonitor.Index
                    }
                default:
                    if !IsInteger(anchor) {
                        throw "Unexpected '" StringifySL(req.monitor) "' as request.monitor"
                    }
                    idx := anchor
                }
                idx += offset
            }
            if idx < 1 || idx > this._monitors.Count {
                throw "Monitor " idx " doesn't exist"
            }
            return this._monitors.ByIndex(idx)
        }

        getWorkspace(monitor := getMonitor()) {
            idx := this.activeWsIdx
            if req.HasProp("workspace") {
                anchor := ""
                offset := 0

                if req.workspace is Object {
                    anchor := req.workspace.anchor
                    if req.workspace.HasProp("offset") {
                        offset := req.workspace.offset
                    }
                } else if req.workspace {
                    anchor := req.workspace
                }

                switch anchor {
                case "current":
                    ;; Do nothing
                case "next":
                    idx += 1
                case "previous":
                    idx -= 1
                case "first":
                    idx := 1
                case "last":
                    idx := this.VD.GetCount()
                case "mru":
                    if this.lastWsIdx {
                        idx := this.lastWsIdx
                    }
                default:
                    if !IsInteger(anchor) {
                        throw "Unexpected '" StringifySL(req.workspace) "' as request.workspace"
                    }
                    idx := anchor
                }
                idx += offset
            }
            return this._workspaces[monitor, idx]
        }

        switch req.type {
        case "focus-workspace":
            this.activeWsMonitors[this.activeWsIdx] := this.activeMonitor
            ws := getWorkspace()

            if this._opts.focusWorkspaceByWindow {
                if !req.HasProp("monitor") {
                    monitor := this.activeWsMonitors.Get(ws.Index, "")
                    if monitor {
                        ws := this._workspaces[monitor, ws.Index]
                    }
                }

                if ws.WindowCount > 0 && ws.ActiveWindow
                    && !this._pinned.Has(ws.ActiveWindow) {
                    this._focusWindow(ws.ActiveWindow)
                } else {
                    this.VD.FocusDesktop(ws.Index)
                }
            } else {
                this.VD.FocusDesktop(ws.Index)
            }

        case "send-to-workspace":
            ws := getWorkspace()
            hwnd := req.HasProp("hwnd") ? req.hwnd : WinExist("A")
            this.VD.SendWindowToDesktop(hwnd, ws.Index)

            follow := req.HasProp("follow")
                ? req.follow
                : this._opts.followWindowToWorkspace

            if follow {
                this.VD.FocusDesktop(ws.Index)
            } else {
                window := this._managed.Get(hwnd, 0)
                next := window.workspace.Remove(hwnd)
                ws.AddIfNew(hwnd)
                ws.ActiveWindow := hwnd
                this.activeWsMonitors[ws.Index] := ws._monitor
                if next {
                    this._focusWindow(next, false)
                } else if window.workspace.WindowCount == 0 {
                    this._focusWorkspace(window.workspace)
                }
            }

        case "focus-monitor":
            monitor := getMonitor()
            ws := this._workspaces[monitor, this.activeWsIdx]
            this._focusWorkspace(ws)

        case "send-to-monitor":
            hwnd := req.HasProp("hwnd") ? req.hwnd : WinExist("A")
            window := this._managed.Get(hwnd, 0)
            if !window {
                return
            }

            monitor := getMonitor()
            newWs := getWorkspace(monitor)
            oldWs := window.workspace
            this._reassociate(hwnd, window, monitor, newWs)

            follow := req.HasProp("follow")
                ? req.follow
                : this._opts.followWindowToMonitor

            ;; Make the thrown window the active one.
            newWs.ActiveWindow := hwnd

            ;; The focus moved together with the active window to another
            ;; monitor, so just update the active monitor if follow is true.
            ;; Otherwise focus the recently left monitor again.
            if follow {
                this.lastMonitor := this.activeMonitor
                this.activeMonitor := monitor
                this._opts.focusIndicator.Show(hwnd)
            } else {
                ws := this._workspaces[this.activeMonitor, this.activeWsIdx]
                this._focusWorkspace(ws)
            }

            ;; Retile again to mitigate cross-DPI issues.
            this._delayed.Add(
                newWs.Retile.Bind(newWs),
                this._opts.delays.sendMonitorRetile,
                "send-monitor-retile",
            )
            if follow {
                this._delayed.Add(
                    ((this, ws) => this._focusWindow(ws.ActiveWindow)).Bind(this, newWs),
                    this._opts.delays.sendMonitorRetile + 50,
                    "send-monitor-retile",
                )
            }

        case "focus-window":
            ws := getWorkspace()
            switch req.target {
            case "next-of-same-app":
                active := ""
                try active := WinExist("A")
                if active {
                    if req.HasProp("acrossWorkspaces")
                        ? req.acrossWorkspaces
                        : false {
                        hwnd := GetNextWindowOfApp(active)
                    } else {
                        fn := (this, found) =>
                            ws.Index == this.VD.DesktopByWindow(found)
                        hwnd := GetNextWindowOfApp(active, fn.Bind(this))
                    }
                }
            default:
                hwnd := ws.GetWindow(req.target)
            }
            if !hwnd {
                warn("Nothing to focus")
                return
            }

            if this._opts.focusIndicator.ShowOnFocusRequest {
                this._opts.focusIndicator.Show(hwnd)
            }
            this._focusWindow(hwnd)

        case "swap-window":
            ws := getWorkspace()
            hwnd := req.HasProp("hwnd") ? req.hwnd : WinExist("A")
            ws.Swap(hwnd, req.with, this._opts.mouseFollowsFocus)

        case "float-window":
            ws := getWorkspace()
            hwnd := req.HasProp("hwnd") ? req.hwnd : WinExist("A")
            ws.Float(hwnd, req.value)

        case "cycle-layout":
            ws := getWorkspace()
            cycle := req.value
            m := Map()
            for i, l in cycle {
                m[l] := i
            }
            current := m.Get(ws.Layout, 0)
            next := cycle[Mod(current, cycle.Length) + 1]
            this.Set("layout", { value: next })

        case "center-window":
            ws := getWorkspace()
            hwnd := req.HasProp("hwnd") ? req.hwnd : WinExist("A")
            ws.Float(hwnd, true)
            CenterWindow(hwnd)
            this._opts.focusIndicator.Show(WinExist("A"))

        case "resize-window":
            ws := getWorkspace()
            hwnd := req.HasProp("hwnd") ? req.hwnd : WinExist("A")
            ws.Float(hwnd, true)
            value := req.HasProp("value") ? req.value : 0
            if this._opts.focusIndicator.HideWhenPositioning {
                this._opts.focusIndicator.Hide()
            }
            switch value {
            case "maximize":
                WinMaximize("ahk_id" hwnd)
            case "fullscreen":
                opts := ws._opts
                workArea := ws._monitor.WorkArea

                ws._moveWindow(
                    hwnd,
                    workArea.left + opts.padding.left,
                    workArea.top + opts.padding.top,
                    workArea.Width - opts.padding.left - opts.padding.right,
                    workArea.Height - opts.padding.top - opts.padding.bottom,
                )
            default:
                ResizeWindow(hwnd, value)
            }
            this._opts.focusIndicator.Show(WinExist("A"))

        case "get-layout":
            return ObjPtrAddRef({ value: getWorkspace().Layout.DisplayName })
        case "set-layout":
            ws := getWorkspace()
            ws.Layout := req.value
            this._opts.showPopup.Call(ws.Layout.DisplayName, {
                activeMonitor: this.activeMonitor.Index,
            })
            this._delayed.Add(
                ws.Retile.Bind(ws),
                this._opts.delays.retile2ndTime,
                "retile-2nd-time",
            )

        case "get-master-count":
            return -getWorkspace().MasterCount
        case "set-master-count":
            ws := getWorkspace()
            if req.HasProp("value") {
                ws.MasterCount := req.value
            } else if req.HasProp("delta") {
                ws.MasterCount += req.delta
            }

        case "get-master-size":
            return -getWorkspace().MasterSize
        case "set-master-size":
            ws := getWorkspace()
            if req.HasProp("value") {
                ws.MasterSize := req.value
            } else if req.HasProp("delta") {
                ws.MasterSize += req.delta
            }

        case "get-padding":
            return -getWorkspace().Padding
        case "set-padding":
            ws := getWorkspace()
            if req.HasProp("value") {
                ws.Padding := req.value
            } else if req.HasProp("delta") {
                v := ws.Padding
                d := ObjMerge({
                    left: 0,
                    top: 0,
                    right: 0,
                    bottom: 0,
                }, req.delta)
                ws.Padding := {
                    left: v.left + d.left,
                    top: v.top + d.top,
                    right: v.right + d.right,
                    bottom: v.bottom + d.bottom,
                }
            }

        case "get-spacing":
            return -getWorkspace().Spacing
        case "set-spacing":
            ws := getWorkspace()
            if req.HasProp("value") {
                ws.Spacing := req.value
            } else if req.HasProp("delta") {
                ws.Spacing += req.delta
            }

        case "get-monitor-info":
            out := StrReplace(String(this._monitors), "`t", "  ")
            if !Logger.Disabled {
                debug(out)
            } else {
                MsgBox(out)
            }

        case "get-workspace-info":
            ws := this._workspaces[this.activeMonitor, this.activeWsIdx]
            out := StrReplace(String(ws), "`t", "  ")
            if !Logger.Disabled {
                debug(out)
            } else {
                MsgBox(out)
            }

        default:
            throw "Unknown request: " req.type
        }
    }

    _focusMonitor(monitor) {
        ;; If there is no tile associated, focus the monitor by
        ;; activating its taskbar.
        taskbar := monitor.Taskbar()
        if !taskbar {
            warn("Can't focus monitor {} without a taskbar", monitor.Index)
            return
        }

        WinActivate("ahk_id" taskbar)

        ;; Also place the cursor in the middle of the specified
        ;; screen for e.g. PowerToys Run.
        RunDpiAware(() =>
            DllCall(
                "SetCursorPos",
                "Int", monitor.WorkArea.CenterX,
                "Int", monitor.WorkArea.CenterY,
                "Int",
            )
        )
        return
    }

    _focusWindow(hwnd, mouseFollowsFocus := this._opts.mouseFollowsFocus) {
        if mouseFollowsFocus {
            RunDpiAware(() => (
                WinGetPos(&left, &top, &width, &height, "ahk_id" hwnd),
                DllCall(
                    "SetCursorPos",
                    "Int", left + width // 2,
                    "Int", top + height // 2,
                    "Int",
                ))
            )
        }

        try WinActivate("ahk_id" hwnd)
    }

    _focusWorkspace(ws) {
        hwnd := ws.GetWindow()
        if hwnd {
            this._focusWindow(hwnd)
        } else {
            this._focusMonitor(ws.Monitor)
        }
    }

    _onDisplayChange(wait := true) {
        if wait {
            this._delayed.Replace(
                this._onDisplayChange.Bind(this, false),
                this._opts.delays.onDisplayChange,
                "on-display-change",
            )
            return
        }

        this._monitors.Update()
        global A_SystemDPI := this._monitors.Primary.DPI
        this._opts.focusIndicator.SetMonitorList(this._monitors)

        gone := this._workspaces.Update(this._monitors)
        for monitor, workspaces in gone {
            for idx, ws in workspaces {
                for hwnd in ws.Hwnds {
                    this._drop(hwnd)
                }
            }
        }

        this._initWithCurrentDesktopAndWindows()
    }

    _initWithCurrentDesktopAndWindows() {
        this.activeMonitor := this._monitors.ByWindow(WinExist("A"))
        this.lastMonitor := ""
        this.activeWsIdx := this.VD.CurrentDesktop()
        this.lastWsIdx := 0
        this.activeWsMonitors := Map()

        old := A_DetectHiddenWindows
        DetectHiddenWindows(false)
        windows := WinGetList()
        DetectHiddenWindows(old)

        for hwnd in windows {
            this._onWindowEvent(EV_WINDOW_SHOWN, hwnd)
        }
        this._onWindowEvent(EV_WINDOW_FOCUSED, WinExist("A"))
    }

    ;; Add a window for which an event happened to the global list if it hasn't
    ;; been added yet.
    _manage(event, hwnd, retrycnt := -1) {
        if this._managed.Has(hwnd) {
            trace(() => ["Ignoring: already managed D={} WS={} {}",
                this._managed[hwnd].monitor.Index,
                this._managed[hwnd].workspace.Index,
                WinInfo(hwnd)])
            return this._managed[hwnd]
        }

        trace(() => ["New window {}", WinInfo(hwnd)])

        try {
            ;; Throws if window needs elevated access.
            WinGetProcessName("ahk_id" hwnd)

            if !DllCall("IsWindowVisible", "Ptr", hwnd, "Int") ||
                IsWindowCloaked(hwnd) {
                trace(() => ["Ignoring: hidden {}", WinInfo(hwnd)])
                return ""
            } else if WinExist("ahk_id" hwnd " ahk_group MIGURU_DECOLESS") {
                ;; Do nothing
            } else if WinGetStyle("ahk_id" hwnd) & WS_CAPTION == 0 {
                ;; NOTE: Would it make sense to auto-float these windows?
                debug(() => ["Ignoring: no titlebar {}", WinInfo(hwnd)])
                return ""
            } else if WinExist("ahk_id" hwnd " ahk_group MIGURU_IGNORE") {
                trace(() => ["Ignoring: ahk_group {}", WinInfo(hwnd)])
                return ""
            }
        } catch TargetError {
            warn(() => ["Lost window while trying to manage it: {}",
                WinInfo(hwnd)])
            return ""
        } catch OSError as err {
            warn(() => ["Failed to manage: {} {}", err.Message, WinInfo(hwnd)])
            return ""
        }

        wsIdx := this.VD.DesktopByWindow(hwnd)
        pinned := false
        switch wsIdx {
        case 0, VD_UNASSIGNED_WINDOW, VD_UNKNOWN_DESKTOP:
            ;; NOTE: Apparently some kind of racy, sometimes returns unknown at
            ;; first, but after a brief delay the correct desktop, so just retry.
            debug(() => ["Ignoring: unknown/unassigned desktop {}", WinInfo(hwnd)])
            if retrycnt < 0 {
                retrycnt := 1 ; retry once
            }
            if retrycnt > 0 {
                this._retryManage(event, hwnd, retrycnt - 1)
            }
            return ""
        case VD_PINNED_WINDOW:
            info(() => ["window is pinned {}", WinInfo(hwnd)])
            pinned := true
        case VD_PINNED_APP:
            info(() => ["app is pinned {}", WinInfo(hwnd)])
            pinned := true
        }

        monitor := this._monitors.ByWindow(hwnd)
        ws := this._workspaces[monitor, !pinned ? wsIdx : this.activeWsIdx]

        debug(() => ["Managing: D={} WS={} {}{}",
            monitor.Index, ws.Index,
            WinInfo(hwnd), pinned ? " (Pinned)" : ""])

        window := {
            monitor: monitor,
            workspace: ws,
        }
        this._managed[hwnd] := window

        if pinned {
            this._pinWindow(hwnd, window)
        }
        return window
    }

    _retryManage(event, hwnd, retrycnt, wait := true) {
        if wait {
            this._delayed.Add(
                this._retryManage.Bind(this, event, hwnd, retrycnt, false),
                this._opts.delays.retryManage,
                "retry-manage",
            )
            return
        }

        debug("Retry manage for {}", WinInfo(hwnd))
        if this._manage(event, hwnd, retrycnt) {
            this._onWindowEvent(EV_WINDOW_SHOWN, hwnd)
            this._onWindowEvent(EV_WINDOW_FOCUSED, WinExist("A"))
        }
    }

    _pinWindow(hwnd, window) {
        window.DefineProp("workspace", {
            Get: (self) => this._workspaces[self.monitor, this.activeWsIdx],
            Set: (self, v) => self.DefineProp("workspace", { Value: v }),
        })
        this._pinned[hwnd] := true
    }

    _unpinWindow(hwnd, window, wsIdx := 0) {
        debug(() => ["Unpinning window {}", WinInfo(hwnd)])

        if wsIdx > 0 {
            window.workspace := this._workspaces[window.monitor, wsIdx]
        }
        this._removePinnedWindow(hwnd, window, wsIdx)
        this._pinned.Delete(hwnd)
    }

    _removePinnedWindow(hwnd, window, wsIdx := 0) {
        for ws in this._workspaces {
            if ws.Monitor !== window.monitor || ws.Index !== wsIdx {
                ws.Remove(hwnd)
            }
        }
    }

    ;; When a window gets destroyed or accessing it results in a TargetError,
    ;; remove from the global list.
    _drop(hwnd) {
        if !this._managed.Has(hwnd) {
            return ""
        }

        window := this._managed.Delete(hwnd)
        if !this._pinned.Has(hwnd) {
            ;; FIXME: There seems to be cases where – when closing e.g. an
            ;; explorer window – a "hidden" event occurs first, then a "focus"
            ;; event according to z-order and lastly a "destroyed" event.
            ;; Because of the focus-switch the destroyed window is not the
            ;; active one anymore and Remove() won't return a window that were
            ;; to be activated.
            next := window.workspace.Remove(hwnd)
            if next && window.workspace.Index == this.activeWsIdx {
                this._focusWindow(next, false)
            }
        } else {
            this._unpinWindow(hwnd, window)
        }

        debug(() => ["Dropped: D={} WS={} {}",
            window.monitor.Index, window.workspace.Index, WinInfo(hwnd)])

        return window
    }

    ;; Remove a window from its workspace and add it to another.
    _reassociate(hwnd, window, monitor, workspace) {
        debug(() => ["Moved: D={} WS={} -> D={} WS={} - {}",
            window.monitor.Index, window.workspace.Index,
            monitor.Index, workspace.Index,
            WinInfo(hwnd)])

        if !this._pinned.Has(hwnd) {
            window.workspace.Remove(hwnd)
            window.monitor := monitor
            window.workspace := workspace
            workspace.AddIfNew(hwnd)
        } else {
            window.monitor := monitor
            this._removePinnedWindow(hwnd, window)
            workspace.AddIfNew(hwnd)
        }
    }

    ;; When a window vanishes, remove it from its previous workspace.
    ;; However, ignore hiding of windows when switching the active virtual
    ;; desktop by delaying the removal and removing pending hides if an
    ;; EV_DESKTOP_CHANGED happens within the delay.
    _hide(event, hwnd, wait := true) {
        if !this._managed.Has(hwnd)  {
            return
        }

        if wait {
            this._delayed.Replace(
                this._hide.Bind(this, event, hwnd, false),
                this._opts.delays.windowHidden,
                "window-hidden",
            )
            return
        }

        window := this._managed[hwnd]
        if !this._pinned.Has(hwnd) {
            window.workspace.Remove(hwnd)
        } else {
            this._removePinnedWindow(hwnd, window)
        }
    }
}

;; Post quit so the destructors get called which e.g. restore focus-follows-mouse.
SignalHandler(event) {
    switch event {
    case CTRL_C_EVENT:
        PostMessage(WM_QUIT, , , , "ahk_id" A_ScriptHwnd)
        return true
    }
    return false
}

DllCall(
    "SetConsoleCtrlHandler",
    "UInt", CallbackCreate(SignalHandler, "F"),
    "Int", true,
    "Int",
)
