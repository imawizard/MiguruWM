#include api.ahk
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
        this._delayed := Timeouts()

        windowTracking := GetSpiInt(SPI_GETACTIVEWINDOWTRACKING)
        if windowTracking !== this._opts.focusFollowsMouse {
            this._oldFFM := windowTracking
            SetSpiInt(SPI_SETACTIVEWINDOWTRACKING, this._opts.focusFollowsMouse)
        }

        super.__New()
        this._initWithCurrentDesktopAndWindows()
        MiguruAPI.Init(this)
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

            try {

                ;; To not miss any windows that were already created and thus
                ;; e.g. appear for the first time by unhiding instead of
                ;; creation, add new windows on any event.
                window := this._manage(hwnd)
                if !window {
                    return
                }

                monitor := this._monitors.ByWindow(window.handle)
                wsIdx := this.VD.DesktopByWindow(window.handle)

                ;; Adjust when a window changed desktop or monitor.
                if monitor !== window.monitor ||
                    wsIdx > 0 && wsIdx !== window.workspace.Index {
                    ws := this._workspaces[monitor, wsIdx]
                    this._reassociate(window, monitor, ws)
                }

                if WinGetMinMax("ahk_id" window.handle) >= 0 {
                    if !window.workspace.AddIfNew(window.handle) {
                        switch event {
                        case EV_WINDOW_FOCUSED:
                            debug(() => ["Focused: {} D={} {}",
                                this.VD.DesktopName(wsIdx), monitor.Index,
                                WinInfo(window.handle)])

                            window.workspace.ActiveWindow := window.handle

                        case EV_WINDOW_REPOSITIONED:
                            debug(() => ["Repositioned: {} D={} {}",
                                this.VD.DesktopName(wsIdx), monitor.Index,
                                WinInfo(window.handle)])

                            window.workspace.Retile()
                        }
                    }
                }

            } catch TargetError {
                warn("Lost window while trying to manage it {}", WinInfo(hwnd))
                this._drop(hwnd)
            } catch OSError as err {
                warn("Dropping window ({}): {}", WinInfo(hwnd), err.Message)
                this._drop(hwnd)
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
        getWorkspace() {
            monitor := this.activeMonitor
            if req.HasProp("monitor") && req.monitor {
                if req.monitor == "primary" {
                    monitor := this.activeMonitor
                } else if req.monitor > 0 && req.monitor <= 4 {
                    monitor := this._monitors.ByIndex(req.monitor)
                } else {
                    throw "Unexpected '" req.monitor "' as request.monitor"
                }
            }

            wsIdx := this.activeWsIdx
            if req.HasProp("workspace") && req.workspace {
                if req.workspace > 0 && req.workspace <= 20 {
                    wsIdx := req.workspace
                } else {
                    throw "Unexpected '" req.workspace "' as request.workspace"
                }
            }

            return this._workspaces[monitor, wsIdx]
        }

        focusMonitor(monitor) {
            ws := this._workspaces[monitor, this.activeWsIdx]
            if ws.WindowCount > 0 {
                ws.Focus("active")
            } else {
                ;; If there is no tile associated, focus the monitor by
                ;; activating its taskbar.
                taskbar := monitor.Taskbar()
                if !taskbar {
                    warn("Can't focus monitor {} without a tile or a taskbar",
                        index)
                    return
                }

                WinActivate("ahk_id" taskbar)

                ;; Also place the cursor in the middle of the specified
                ;; screen for e.g. PowerToys Run.
                old := A_CoordModeMouse
                CoordMode("Mouse", "Screen")
                MouseMove(monitor.Area.CenterX, monitor.Area.CenterY, 0)
                CoordMode("Mouse", old)
            }
        }

        switch req.type {
        case "focus-monitor", "send-monitor":
            activeIdx := this.activeMonitor.Index
            index := req.target == "primary"
                ? this._monitors.Primary.Index
                : req.target > 0 ? req.target : activeIdx
            index += req.delta

            if index == activeIdx {
                debug("Monitor #{} is already active", index)
                return
            } else if index < 1 || index > this._monitors.Count {
                warn("Monitor index {} is invalid", index)
                return
            }

            monitor := this._monitors.ByIndex(index)
            switch req.type {
            case "focus-monitor":
                focusMonitor(monitor)

            case "send-monitor":
                window := this._managed.Get(WinExist("A"), 0)
                if !window {
                    return
                }

                oldWs := window.workspace
                ws := this._workspaces[monitor, this.activeWsIdx]
                this._reassociate(window, monitor, ws)

                ;; Retile again to mitigate cross-DPI issues.
                this._delayed.Add(
                    ws.Retile.Bind(ws),
                    this._opts.delays.sendMonitorRetile,
                    "send-monitor-retile",
                )

                ;; The focus moved together with the active window to another
                ;; monitor, so just update the active monitor if follow is true.
                ;; Otherwise focus the recently left monitor again.
                if req.follow {
                    this.activeMonitor := monitor
                } else {
                    focusMonitor(this.activeMonitor)
                }
            }

        case "focus-window":
            ws := this._workspaces[this.activeMonitor, this.activeWsIdx]
            ws.Focus(req.target)

        case "swap-window":
            ws := getWorkspace()
            ws.Swap(req.target)

        case "float-window":
            ws := this._workspaces[this.activeMonitor, this.activeWsIdx]
            ws.Float(req.hwnd, req.value)

        case "layout":
            ws := getWorkspace()
            if !req.HasProp("value") {
                return ObjPtrAddRef({ layout: ws.Layout })
            }
            ws.Layout := req.value

        case "master-count":
            ws := getWorkspace()
            if req.HasProp("value") {
                ws.MasterCount := req.value
            } else if !req.HasProp("delta") {
                return ws.MasterCount
            }
            ws.MasterCount += req.delta

        case "master-size":
            ws := getWorkspace()
            if req.HasProp("value") {
                ws.MasterSize := req.value
            } else if !req.HasProp("delta") {
                return ws.MasterSize
            }
            ws.MasterSize += req.delta

        case "padding":
            ws := getWorkspace()
            if req.HasProp("value") {
                ws.Padding := req.value
            } else if !req.HasProp("delta") {
                return ws.Padding
            }
            ws.Padding += req.delta

        case "spacing":
            ws := getWorkspace()
            if req.HasProp("value") {
                ws.Spacing := req.value
            } else if !req.HasProp("delta") {
                return ws.Spacing
            }
            ws.Spacing += req.delta

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
            trace(() => ["Ignoring: already managed {} D={} {}",
                this.VD.DesktopName(this._managed[hwnd].workspace.Index),
                this._managed[hwnd].monitor.Index,
                WinInfo(hwnd)])
            return this._managed[hwnd]
        }

        wsIdx := this.VD.DesktopByWindow(hwnd)
        if !wsIdx {
            trace(() => ["Ignoring: unknown desktop {}", WinInfo(hwnd)])
            return ""
        } else if wsIdx < 0 {
            debug(() => ["Desktop not yet assigned {}", WinInfo(hwnd)])
            return ""
        }

        style := WinGetStyle("ahk_id" hwnd)
        if style & WS_CAPTION == 0 {
            trace(() => ["Ignoring: no titlebar {} {}",
                this.VD.DesktopName(wsIdx), WinInfo(hwnd)])
            return ""
        } else if style & WS_VISIBLE == 0 || IsWindowCloaked(hwnd) {
            trace(() => ["Ignoring: hidden {} {}",
                this.VD.DesktopName(wsIdx), WinInfo(hwnd)])
            return ""
        } else if WinExist("ahk_id" hwnd " ahk_group MIGURU_IGNORE") {
            trace(() => ["Ignoring: ahk_group {} {}",
                this.VD.DesktopName(wsIdx), WinInfo(hwnd)])
            return ""
        }

        ;; Throws if window needs elevated access.
        WinGetProcessName("ahk_id" hwnd)

        monitor := this._monitors.ByWindow(hwnd)
        ws := this._workspaces[monitor, wsIdx]

        debug(() => ["Managing: {} D={} {}",
            this.VD.DesktopName(ws.Index), monitor.Index,
            WinInfo(hwnd)])

        window := {
            handle: hwnd,
            monitor: monitor,
            workspace: ws,
        }
        this._managed[hwnd] := window

        return window
    }

    ;; When a window gets destroyed or accessing it results in a TargetError,
    ;; remove from the global list.
    _drop(hwnd) {
        if !this._managed.Has(hwnd) {
            return ""
        }

        window := this._managed.Delete(hwnd)
        window.workspace.Remove(hwnd)
        monitorIdx := this._monitors.Has(window.monitor)
            ? window.monitor.Index
            : -1

        debug(() => ["Dropping: {} D={} {}",
            this.VD.DesktopName(window.workspace.Index), monitorIdx,
            WinInfo(hwnd)])

        return window
    }

    ;; Remove a window from its workspace and add it to another.
    _reassociate(window, monitor, workspace) {
        debug(() => ["Moved: {} D={} -> {} D={} - {}",
            this.VD.DesktopName(window.workspace.Index), window.monitor.Index,
            this.VD.DesktopName(workspace.Index), monitor.Index,
            WinInfo(window.handle)])

        window.workspace.Remove(window.handle, false)
        window.monitor := monitor
        window.workspace := workspace
        workspace.AddIfNew(window.handle)
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
        window.workspace.Remove(hwnd, false)
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
