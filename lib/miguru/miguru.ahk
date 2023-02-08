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
        }, opts)

        this._monitors := MonitorList()
        this._workspaces := WorkspaceList(this._monitors, ObjClone(this._opts))
        this._managed := Map()
        this._delayed := Timeouts()

        super.__New()
        this._initWithCurrentDesktopAndWindows()
        MiguruAPI.Init(this)
    }

    Options => ObjClone(this._opts)

    _onWindowEvent(event, hwnd) {
        switch event {
        case EV_WINDOW_FOCUSED:
            monitor := this._monitors.ByWindow(hwnd)

            ;; Set currently active monitor if changed.
            if monitor && monitor !== this.activeMonitor {
                debug("Focused: Display #{} -> Display #{}",
                    this.activeMonitor.Index, monitor.Index)
                this.activeMonitor := monitor
            }
            goto fallthrough
        case EV_WINDOW_SHOWN, EV_WINDOW_UNCLOAKED, EV_WINDOW_RESTORED, EV_WINDOW_REPOSITIONED:
            fallthrough:

            ;; To not miss any windows that were already created and thus e.g.
            ;; appear for the first time by unhiding instead of creation, add
            ;; new windows on any event.
            window := this._manage(hwnd)
            if !window {
                return
            }

            monitor := this._monitors.ByWindow(window.handle)
            wsIdx := this.VD.DesktopByWindow(window.handle)
            if monitor !== window.monitor || wsIdx > 0 && wsIdx !== window.workspace.Index {
                this._reassociate(window, monitor, this._workspaces[monitor, wsIdx])
            }

            try {
                if WinGetMinMax("ahk_id" window.handle) >= 0 {
                    if !window.workspace.AddIfNew(window.handle) {
                        switch event {
                        case EV_WINDOW_FOCUSED:
                            debug(() => ["Focused: {} D={} {}",
                                this.VD.DesktopName(wsIdx), monitor.Index,
                                WinInfo(window.handle)])
                            window.workspace.ActiveWindow := window.handle
                        case EV_WINDOW_REPOSITIONED:
                            window.workspace.Retile()
                        }
                    }
                }
            } catch TargetError {
                warn("Lost window while trying to manage it {}", WinInfo(hwnd))
                return this._drop(window.handle)
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
            this._delayed.Drop("hide")

            this.activeWsIdx := args.now
            debug(() => ["Focused: {} -> {}",
                this.VD.DesktopName(args.was), this.VD.DesktopName(args.now)])
        case EV_DESKTOP_RENAMED:
            debug("Renamed: Desktop #{} `"{}`"", args.desktop, args.name)
            ;; Do nothing
        case EV_DESKTOP_CREATED:
            debug(() => ["Created: {}", this.VD.DesktopName(args.desktop)])
            ;; Do nothing
        case EV_DESKTOP_DESTROYED:
            debug("Destroyed: Desktop #{}", args.desktopId)
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

        switch req.type {
        case "focus-monitor", "send-monitor":
            activeIdx := this.activeMonitor.Index
            index := req.target == "primary"
                ? this._monitors.Primary.Index
                : req.target > 0 ? req.target : activeIdx
            index += req.delta
            if index < 1 || index > this._monitors.Count || index == activeIdx {
                warn("Monitor {} is active or non-existent", index)
                return
            }

            monitor := this._monitors.ByIndex(index)
            switch req.type {
            case "focus-monitor":
                ws := this._workspaces[monitor, this.activeWsIdx]
                if ws.MruTile {
                    WinActivate("ahk_id" ws.MruTile.data)
                } else {
                    ;; If there is no tile associated, focus the monitor by
                    ;; activating its taskbar.
                    taskbar := monitor.Taskbar()
                    if taskbar {
                        WinActivate("ahk_id" taskbar)
                    } else {
                        warn("Can't focus monitor {} without a tile or a taskbar", index)
                    }
                }
            case "send-monitor":
                window := this._managed.Get(WinExist("A"), 0)
                if !window {
                    return
                }
                ws := this._workspaces[monitor, this.activeWsIdx]
                this._reassociate(window, monitor, ws)

                ;; Retile again to mitigate cross-DPI issues.
                b := window.workspace.Retile.Bind(window.workspace)
                this._delayed.Add(b, 10, "retile")

                if !req.follow {
                    return
                }
                this.activeMonitor := monitor
            }

            ;; Also place the cursor in the middle of the specified screen for
            ;; e.g. PowerToys Run.
            old := A_CoordModeMouse
            CoordMode("Mouse", "Screen")
            MouseMove(monitor.Area.CenterX, monitor.Area.CenterY)
            CoordMode("Mouse", old)
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

    _onDisplayChange(update := false) {
        if !update {
            this._delayed.Drop("monitor")

            b := this._onDisplayChange.Bind(this, true)
            this._delayed.Add(b, 1000, "monitor")
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
        try {
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
                trace(() => ["Ignoring: no titlebar {} {}", this.VD.DesktopName(wsIdx), WinInfo(hwnd)])
                return ""
            } else if style & WS_VISIBLE == 0 || IsWindowCloaked(hwnd) {
                trace(() => ["Ignoring: hidden {} {}", this.VD.DesktopName(wsIdx), WinInfo(hwnd)])
                return ""
            } else if WinExist("ahk_id" hwnd " ahk_group MIGURU_IGNORE") {
                trace(() => ["Ignoring: ahk_group {} {}", this.VD.DesktopName(wsIdx), WinInfo(hwnd)])
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
        } catch TargetError {
            warn("Lost window while trying to manage it {}", WinInfo(hwnd))
            return ""
        } catch OSError as err {
            if err.Number !== ERROR_ACCESS_DENIED {
                throw err
            }
            warn("Can't access window #{}", hwnd)
            return ""
        }
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
            this._delayed.Drop("hide")

            b := this._hide.Bind(this, event, hwnd, false)
            this._delayed.Add(b, 400, "hide")
            return
        }

        window := this._managed[hwnd]
        window.workspace.Remove(hwnd, false)
    }


}
