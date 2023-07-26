#include events.ahk
#include monitors.ahk
#include utils.ahk
#include workspaces.ahk
#include layouts\floating.ahk
#include layouts\fullscreen.ahk
#include layouts\tall.ahk
#include layouts\wide.ahk
#include layouts\threeColumns.ahk
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
    ;; The constructor accepts an object containing options. The defaults are:
    ;;   #include lib\miguru\miguru.ahk
    ;;
    ;;   mwm := MiguruWM({
    ;;
    ;;     # Default layout for all workspaces.
    ;;     layout: "tall",
    ;;
    ;;     # Default size of a workspace's master pane.
    ;;     masterSize: 0.5,
    ;;
    ;;     # Default number of windows to put in the master pane.
    ;;     masterCount: 1,
    ;;
    ;;     # Default gap between the edges of the display and the windows.
    ;;     padding: {
    ;;         left: 0,
    ;;         top: 0,
    ;;         right: 0,
    ;;         bottom: 0,
    ;;     },
    ;;
    ;;     ;; Default gap in-between of windows.
    ;;     spacing: 0,
    ;;
    ;;     # New windows are automatically tiled, except when their width or
    ;;     # height is smaller than the respective option or they fall into one
    ;;     # of the groups mentioned below, in which case they are floating.
    ;;     tilingMinWidth: 0,
    ;;     tilingMinHeight: 0,
    ;;
    ;;     # Specify where new tiled windows are inserted. Possible values are:
    ;;     # - "first": a new window will become the new master window
    ;;     # - "last": it will become the last window in the secondary pane
    ;;     # - "before-mru": it will become the previous window of the most
    ;;     #    recently
    ;;     # - "after-mru": it will become the next window of the most recently
    ;;     #    used one, means Do("focus-window", { target: "next" }) would
    ;;     #    focus the most recently used one
    ;;     # - "after-mru": it will become the next window of the most recently
    ;;     #    used one
    ;;     tilingInsertion: "before-mru",
    ;;
    ;;     # If true, floating windows will be put above tiling windows.
    ;;     floatingAlwaysOnTop: false,
    ;;
    ;;     # If true, uses SPI_SETACTIVEWINDOWTRACKING to activate focusing
    ;;     # windows through moving the mouse.
    ;;     focusFollowsMouse: false,
    ;;
    ;;     # If true, move the mouse to the center of a window when calling
    ;;     # `Do("focus-window", ...)`.
    ;;     mouseFollowsFocus: false,
    ;;
    ;;     # If true, calling `Do("send-to-monitor", ...) focuses the monitor
    ;;     # the window was send to.
    ;;     followWindowToMonitor: false,
    ;;
    ;;     # Callback that gets called to show popup messages.
    ;;     # `opts.activeMonitor` is the index of the current monitor (from left
    ;;     # to right).
    ;;     showPopup: (text, opts) => ...,
    ;;
    ;;     # Adjust the delay to wait for certain actions. Higher values give
    ;;     # more precise window handling, but less nice user experience.
    ;;     delays: {
    ;;
    ;;       # Specify the delay to try picking up new windows again if the
    ;;       # some apparently racy winapi/com functions failed the first time.
    ;;       retryManage: 100,
    ;;
    ;;       # Specify the delay to wait before handling a window's hide-event
    ;;       # as a close. Smaller values make retiling snappier when a window
    ;;       # disappears. However, it increases the possibility of falsely
    ;;       # recognizing the hide-event when switching virtual desktops as a
    ;;       # close which would result in windows being seen as new when
    ;;       # switching back to that virtual desktop, repositioning the windows
    ;;       # again and possibly differently.
    ;;       windowHidden: 400,
    ;;
    ;;       # Specify the delay to wait before windows are retiled when dis-/
    ;;       # connecting monitors. Again, a smaller values result in snappier
    ;;       # behaviour, but since it takes some time for message propagation
    ;;       # and windows to react to the display-change it could result in
    ;;       # incorrect window sizing and positioning.
    ;;       onDisplayChange: 1000,
    ;;
    ;;       # Specify the delay to wait before retiling a window's new monitor
    ;;       # a second time. Because when sending a window to another monitor,
    ;;       # the first shown-event is apparently that early that other winapi
    ;;       # functions for sizing and positioning don't yet work correctly
    ;;       # when dpi changes are involved.
    ;;       sendMonitorRetile: 100,
    ;;     },
    ;;   })
    ;;
    ;; There are three ahk window-groups:
    ;;
    ;;   # Float all new windows that match the criteria of an entry. Floating
    ;;   # windows won't get positioned or resized automatically like tiled
    ;;   # windows. Also when iterating through the windows with
    ;;   # `Do("focus-window", ...)`, they come after the tiled ones.
    ;;   GroupAdd("MIGURU_AUTOFLOAT", criteria)
    ;;
    ;;   # New windows that match an entry won't be picked up. So they are
    ;;   # neither moved/resized nor focused with `Do("focus-window", ...)`.
    ;;   GroupAdd("MIGURU_IGNORE", criteria)
    ;;
    ;;   # Explicitly handle windows that have no title bar like e.g. alacritty
    ;;   # or qutebrowser and would get ignored otherwise.
    ;;   GroupAdd("MIGURU_DECOLESS", criteria)
    ;;
    ;; Additionally, mwm.VD is an instance of ..\vd\vd.ahk:
    ;;   mwm.VD.RenameDesktop(mwm.VD.Count(), "Last Desktop")
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

            followWindowToMonitor: false,

            showPopup: (*) =>,
            focusIndicator: {
                Show: (*) =>,
                Hide: (*) =>,
                Unmanaged: (*) =>,
                SetMonitorList: (*) =>,
                HideWhenPositioning: false,
                ShowOnFocusRequest: false,
            },

            delays: {
                retryManage: 100,
                windowHidden: 400,
                onDisplayChange: 1000,
                sendMonitorRetile: 100,
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

    ;; Focuses a specific monitor which are ordered by coordinates.
    ;;   # Possible string-values for `monitor` and `monitor.anchor` are:
    ;;   # "current", "mru", "next", "previous", "primary", "first" and "last"
    ;;   Do("focus-monitor", { monitor: 1
    ;;                                  | "first"
    ;;                                  | { anchor: "first", offset: 0 } })
    ;;
    ;; Moves the active window to another monitor's workspace.
    ;;   # If `follow` false, then the focus is kept on the currently active
    ;;   # monitor (default is `followWindowToMonitor`).
    ;;   Do("send-to-monitor", { monitor: ...[, follow: true] })
    ;;
    ;; Cycles through a workspace's windows.
    ;;   # Possible values for `target` are:
    ;;   # "next", "previous" and "master"
    ;;   # `hwnd` can be specified as anchor. If not set, the starting point is
    ;;   # the workspace's active window, the most recently active tile or the
    ;;   # first floating window.
    ;;   Do("focus-window", { [hwnd: WinExist("ahk_exe explorer.exe"),]
    ;;                        target: "next" })
    ;;
    ;; Swaps a tiled window with another one.
    ;;   # Possible values for `with` are:
    ;;   # "next", "previous", "master"
    ;;   # If `hwnd` is not specified, it defaults to `WinExist("A")`.
    ;;   Do("swap-window", { [hwnd: WinExist("ahk_exe explorer.exe"),]
    ;;                        with: "next" })
    ;;
    ;; Floats or tiles a specific window or the currently active one.
    ;;   # Possible values for `value` are:
    ;;   # true, false, "toggle"
    ;;   Do("float-window", { hwnd: WinExist("A"),
    ;;                        value: "toggle" })
    Do(what, opts := {}) {
        PostMessage(WM_REQUEST, ObjPtrAddRef(ObjMerge({
            type: what,
        }, opts)), , , "ahk_id" A_ScriptHwnd)
    }

    ;; Sets the layout of a monitor's workspace.
    ;;   # Possible string-values for `workspace` and `workspace.anchor` are:
    ;;   # "current", "mru", "next", "previous", "first" and "last"
    ;;   Set("layout", { [workspace: 1 | "first"
    ;;                                 | { anchor: "first", offset: 0 },]
    ;;                   value: "fullscreen" })
    ;;
    ;; Put less or more windows in the master pane.
    ;;   Set("master-count", { [workspace: ...,]
    ;;                         [value: 2,]
    ;;                         [delta: 1,] })
    ;;
    ;; Shrinks or expands the master pane.
    ;;   Set("master-size", { [workspace: ...,]
    ;;                        [value: 0.6,]
    ;;                        [delta: 0.04,] })
    ;;
    ;; Changes the space to the border of the screen.
    ;;    Set("padding", { [value: { left: 3, right: 3 },]
    ;;                     [delta: { top: -1, bottom: -1 },] })
    ;;
    ;; Changes the gaps between windows.
    ;;    Set("spacing", { [value: 3,]
    ;;                     [delta: -2,] })
    Set(what, opts := {}) {
        this.Do("set-" what, opts)
    }

    ;; Returns the number of windows that would be put into the master pane
    ;;    Get("master-count"[, { ... }])
    ;;
    ;; Returns the current size of the master pane
    ;;    Get("master-size"[, { ... }])
    ;;
    ;; Returns the space to the border of the screen
    ;;    Get("padding"[, { ... }])
    ;;
    ;; Returns the gap between windows
    ;;    Get("spacing"[, { ... }])
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
                if event == EV_WINDOW_FOCUSED {
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
                ws.AddIfNew(hwnd)
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
                this._opts.focusIndicator.Show(hwnd)
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

        case "focus-window":
            ws := getWorkspace()
            hwnd := ws.GetWindow(req.target)
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
            this._opts.focusIndicator.Show(WinExist("A"))

        case "float-window":
            ws := getWorkspace()
            hwnd := req.HasProp("hwnd") ? req.hwnd : WinExist("A")
            ws.Float(hwnd, req.value)
            this._opts.focusIndicator.Show(WinExist("A"))

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

        case "get-layout":
            return ObjPtrAddRef({ value: getWorkspace().Layout.DisplayName })
        case "set-layout":
            ws := getWorkspace()
            ws.Layout := req.value
            this._opts.showPopup.Call(ws.Layout.DisplayName, {
                activeMonitor: this.activeMonitor.Index,
            })

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
