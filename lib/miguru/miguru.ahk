#include events.ahk
#include monitors.ahk
#include utils.ahk
#include workspaces.ahk

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

class MiguruWM extends WMEvents {
    ;; The constructor accepts an object containing options. The defaults are:
    ;;    #include lib\miguru\miguru.ahk
    ;;
    ;;    mwm := MiguruWM({
    ;;        layout: "tall",
    ;;        masterSize: 0.5,
    ;;        masterCount: 1,
    ;;        padding: 0,
    ;;        spacing: 0,
    ;;        tilingMinWidth: 0,
    ;;        tilingMinHeight: 0,
    ;;        tilingInsertion: "before-mru",
    ;;        floatingAlwaysOnTop: false,
    ;;        nativeMaximize: false,
    ;;    })
    ;;    mwm.FocusWindow("next")
    ;;
    ;; tilingMinWidth/tilingMinHeight
    ;;   New windows are automatically tiled, except when their width or height is
    ;;   smaller than the respective option or they fall into one of the groups
    ;;   mentioned below, in which case they are floating.
    ;; tilingInsertion
    ;;   Specifies where new tiled windows are inserted. Possible values are:
    ;;   - "first": a new window will become the new master window
    ;;   - "last": it will become the last window in the secondary pane
    ;;   - "before-mru": it will become the previous window of the most recently
    ;;      used one, means FocusWindow("next") would focus that
    ;;   - "after-mru": it will become the next window of the most recently used one
    ;; nativeMaximize
    ;;   If true, Windows are maximized in fullscreen-layout.
    ;;
    ;; There are two ahk window-groups:
    ;;    GroupAdd("MIGURU_AUTOFLOAT", criteria)
    ;;    GroupAdd("MIGURU_IGNORE", criteria)
    ;;
    ;; The first group floats all new windows that match the criteria of one entry.
    ;; Floating windows won't get positioned or resized automatically like tiled
    ;; windows. Also when iterating through the windows with FocusWindow(), they
    ;; come after the tiled ones.
    ;; New windows that match an entry of the second group won't be picked up. So
    ;; they are neither moved/resized nor focused with FocusWindow().
    ;;
    ;; Additionally, mwm.VD is an instance of vd.ahk:
    ;;    mwm.VD.RenameDesktop(mwm.VD.Count(), "Last Desktop")
    __New(opts := {}) {
        this._opts := ObjMerge({
            layout: "tall",
            masterSize: 0.5,
            masterCount: 1,
            padding: 0,
            spacing: 0,

            tilingMinWidth: 0,
            tilingMinHeight: 0,
            tilingInsertion: "before-mru",
            floatingAlwaysOnTop: false,
            nativeMaximize: false,

            focusFollowsMouse: false,
            mouseFollowsFocus: false,

            delays: {
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

        windowTracking := GetSpiInt(SPI_GETACTIVEWINDOWTRACKING)
        if windowTracking !== this._opts.focusFollowsMouse {
            this._oldFFM := windowTracking
            SetSpiInt(SPI_SETACTIVEWINDOWTRACKING, this._opts.focusFollowsMouse)
        }

        super.__New()
        this._initWithCurrentDesktopAndWindows()
    }

    ;; Focuses a specific monitor which are ordered by coordinates.
    ;;    Do("focus-monitor", { monitor: 2 })
    ;;
    ;; Moves the active window to another monitor's workspace.
    ;;    Do("send-to-monitor", { monitor: 2[, follow: true] })
    ;;
    ;; Cycles through a workspace's windows.
    ;;  hwnd can be specified as anchor. If not set, the starting point is the
    ;;  workspace's active window, the most recently active tile or the first
    ;;  floating window.
    ;;    Do("focus-window", { target: "next" | "previous" | "master" })
    ;;
    ;; Swaps a tiled window with another one.
    ;;  If hwnd is not specified, it defaults to WinExist("A").
    ;;    Do("swap-window", { with: "next" | "previous" | "master" })
    ;;
    ;; Floats or tiles a specific window or the currently active one.
    ;;    Do("float-window", { hwnd: WinExist("A"), value: "toggle" | true | false })
    ;;
    ;; Like Set(), monitor and workspace can be specified.
    Do(what, opts := {}) {
        PostMessage(WM_REQUEST, ObjPtrAddRef(ObjMerge({
            type: what,
        }, opts)), , , "ahk_id" A_ScriptHwnd)
    }

    ;; Sets the layout of a monitor's workspace
    ;;    Set("layout", { value: "fullscreen" })
    ;;
    ;; Shrinks or expands the master pane
    ;;    Set("master-size", { value: 3 })
    ;;
    ;; Changes the space to the border of the screen.
    ;;    Set("padding", { value: 3 })
    ;;
    ;; Changes the gaps between windows.
    ;;    Set("spacing", { value: 3 })
    ;;
    ;; Additional keys are
    ;;  monitor: 2 | { anchor: "current" | "primary" | "first" | "last", offset: 3 }
    ;;  workspace: 4 | { anchor: "current", offset: 3 }
    ;;  delta: 0.01
    Set(what, opts := {}) {
        this.Do("set-" what, opts)
    }

    ;; Returns the number of windows that would be put into the master pane
    ;;    Get("master-count", opts)
    ;;
    ;; Returns the current size of the master pane
    ;;    Get("master-size", opts)
    ;;
    ;; Returns the space to the border of the screen
    ;;    Get("padding", opts)
    ;;
    ;; Returns the gap between windows
    ;;    Get("spacing", opts)
    Get(what, opts := {}) {
        res := SendMessage(WM_REQUEST, ObjPtrAddRef(ObjMerge({
            type: "get-" what,
        }, opts)), , , "ahk_id" A_ScriptHwnd)
        if res <= 0 {
            return res
        }
        return ObjFromPtr(res).value
    }

    __Delete() {
        if this.HasProp("_oldFFM") {
            SetSpiInt(SPI_SETACTIVEWINDOWTRACKING, this._oldFFM)
        }
    }

    Options => ObjClone(this._opts)

    _onWindowEvent(event, hwnd) {
        switch event {
        case EV_WINDOW_FOCUSED:
            monitor := this._monitors.ByWindow(hwnd)

            ;; Set currently active monitor if changed.
            if monitor !== this.activeMonitor {
                debug("Active Display: #{} -> #{}",
                    this.activeMonitor.Index, monitor.Index)

                this.activeMonitor := monitor
            }

            goto fallthrough

        case EV_WINDOW_SHOWN, EV_WINDOW_UNCLOAKED, EV_WINDOW_RESTORED, EV_WINDOW_REPOSITIONED:
            fallthrough:

            ;; To not miss any windows that were already created and thus
            ;; e.g. appear for the first time by unhiding instead of
            ;; creation, add new windows on any event.
            window := this._manage(hwnd)
            if !window {
                return
            }

            monitor := this._monitors.ByWindow(hwnd)
            wsIdx := this.VD.DesktopByWindow(hwnd)
            switch wsIdx {
            case 0, VD_UNASSIGNED_WINDOW, VD_UNKNOWN_DESKTOP:
                warn(() => ["Invalid desktop for managed window {}",
                    WinInfo(hwnd)])
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
            } catch as err {
                warn("Dropping window: {} {}",
                    err.Message, WinInfo(hwnd))
                this._drop(hwnd)
                return
            }

            ws := window.workspace
            if !ws.AddIfNew(hwnd) {
                switch event {
                case EV_WINDOW_FOCUSED:
                    debug(() => ["Focused: D={} WS={} {}",
                        monitor.Index, wsIdx, WinInfo(hwnd)])

                    ws.ActiveWindow := hwnd

                case EV_WINDOW_REPOSITIONED:
                    debug(() => ["Repositioned: D={} WS={} {}",
                        monitor.Index, wsIdx, WinInfo(hwnd)])

                    ws.Retile()
                }
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

            this.activeWsIdx := args.now

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
                if req.monitor is Object {
                    switch req.monitor.anchor {
                    case "current":
                        ;; Do nothing
                    case "primary":
                        idx := this._monitors.Primary.Index
                    case "first":
                        idx := 1
                    case "last":
                        idx := this._monitors.Count
                    default:
                        throw "Unexpected '" StringifySL(req.monitor) "' as request.monitor"
                    }
                    idx += req.HasProp("offset") ? req.offset : 0
                } else if req.monitor {
                    idx := req.monitor
                }
            }
            if idx > this._monitors.Count {
                throw "Monitor " idx " doesn't exist"
            }
            return this._monitors.ByIndex(idx)
        }

        getWorkspace(monitor := getMonitor()) {
            idx := this.activeWsIdx
            if req.HasProp("workspace") {
                if req.workspace is Object {
                    switch req.monitor.anchor {
                    case "current":
                        ;; Do nothing
                    default:
                        throw "Unexpected '" StringifySL(req.workspace) "' as request.workspace"
                    }
                    idx += req.HasProp("offset") ? req.offset : 0
                } else if req.workspace {
                    idx := req.workspace
                }
            }
            return this._workspaces[monitor, idx]
        }

        switch req.type {
        case "focus-monitor":
            getWorkspace().Focus()

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

            ;; Retile again to mitigate cross-DPI issues.
            this._delayed.Add(
                newWs.Retile.Bind(newWs),
                this._opts.delays.sendMonitorRetile,
                "send-monitor-retile",
            )

            ;; The focus moved together with the active window to another
            ;; monitor, so just update the active monitor if follow is true.
            ;; Otherwise focus the recently left monitor again.
            if req.HasProp("follow") && req.follow {
                this.activeMonitor := monitor
            } else {
                ws := this._workspaces[this.activeMonitor, this.activeWsIdx]
                ws.Focus(unset, unset, true)
            }

        case "focus-window":
            ws := getWorkspace()
            hwnd := req.HasProp("hwnd") ? req.hwnd : ""
            ws.Focus(hwnd, req.target, this._opts.mouseFollowsFocus)

        case "swap-window":
            ws := getWorkspace()
            hwnd := req.HasProp("hwnd") ? req.hwnd : WinExist("A")
            ws.Swap(hwnd, req.with)

        case "float-window":
            ws := getWorkspace()
            ws.Float(req.hwnd, req.value)

        case "get-layout":
            return ObjPtrAddRef({ value: getWorkspace().Layout })
        case "set-layout":
            ws := getWorkspace()
            ws.Layout := req.value

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
                ws.Padding += req.delta
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
        this.activeWsIdx := this.VD.CurrentDesktop()


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
    _manage(hwnd) {
        if this._managed.Has(hwnd) {
            trace(() => ["Ignoring: already managed D={} WS={} {}",
                this._managed[hwnd].monitor.Index,
                this._managed[hwnd].workspace.Index,
                WinInfo(hwnd)])
            return this._managed[hwnd]
        }

        wsIdx := this.VD.DesktopByWindow(hwnd)
        pinned := false
        if !wsIdx {
            trace(() => ["Ignoring: unknown desktop {}", WinInfo(hwnd)])
            return ""
        } else if wsIdx < 0 {
            switch wsIdx {
            case VD_UNASSIGNED_WINDOW:
                debug(() => ["Desktop not yet assigned {}", WinInfo(hwnd)])
                return ""
            case VD_UNKNOWN_DESKTOP:
                warn(() => ["Desktop {} is unknown: {}",
                    this.VD.DesktopGUIDByWindow(hwnd), WinInfo(hwnd)])
                return ""
            case VD_PINNED_WINDOW:
                info(() => ["window is pinned {}", WinInfo(hwnd)])
                pinned := true
            case VD_PINNED_APP:
                info(() => ["app is pinned {}", WinInfo(hwnd)])
                pinned := true
            }
        }

        try {
            ;; Throws if window needs elevated access.
            WinGetProcessName("ahk_id" hwnd)

            style := WinGetStyle("ahk_id" hwnd)
            if style & WS_CAPTION == 0 {
                trace(() => ["Ignoring: no titlebar WS={} {}",
                    ws.Index, WinInfo(hwnd)])
                return ""
            } else if style & WS_VISIBLE == 0 || IsWindowCloaked(hwnd) {
                trace(() => ["Ignoring: hidden WS={} {}",
                    ws.Index, WinInfo(hwnd)])
                return ""
            } else if WinExist("ahk_id" hwnd " ahk_group MIGURU_IGNORE") {
                trace(() => ["Ignoring: ahk_group WS={} {}",
                    ws.Index, WinInfo(hwnd)])
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
            window.workspace.Remove(hwnd, true, this._opts.mouseFollowsFocus)
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
