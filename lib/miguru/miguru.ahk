#include api.ahk
#include events.ahk
#include monitors.ahk
#include utils.ahk
#include workspaces.ahk

WS_THICKFRAME       := 0x00040000
WS_DLGFRAME         := 0x00400000
WS_CAPTION          := 0x00C00000
WS_VISIBLE          := 0x10000000
WS_CHILD            := 0x40000000
WS_EX_DLGMODALFRAME := 0x00000001
WS_EX_TOPMOST       := 0x00000008
WS_EX_CLICKTHROUGH  := 0x00000020
WS_EX_TOOLWINDOW    := 0x00000080
WS_EX_WINDOWEDGE    := 0x00000100
WS_EX_APPWINDOW     := 0x00040000
WS_EX_LAYERED       := 0x00080000

DetectHiddenWindows(true)

class MiguruWM extends WMEvents {
    __New(opts := {}) {
        defaults := opts.HasProp("defaults") ? opts.defaults : {}
        this._opts := {
            defaults: {
                layout: defaults.HasProp("layout")
                    ? defaults.layout : "tall",
                masterSize: defaults.HasProp("masterSize")
                    ? defaults.masterSize : 0.5,
                masterCount: defaults.HasProp("masterCount")
                    ? defaults.masterCount : 1,
                padding: defaults.HasProp("padding")
                    ? defaults.padding : 0,
                spacing: defaults.HasProp("spacing")
                    ? defaults.spacing : 0,
            },
        }

        this._monitors := MonitorList()
        this._workspaces := WorkspaceList(this._monitors, this._opts.defaults)
        this._managed := Map()
        this._delayed := Timeouts()

        debug("Options {}", Stringify(this._opts))
        debug("MonitorList {}", String(this._monitors))

        super.__New()
        this._initWithCurrentDesktopAndWindows()
        MiguruAPI.Init(this)
    }

    Options => this._opts.Clone()

    _onWindowEvent(event, hwnd) {
        switch event {
        case EV_WINDOW_FOCUSED:
            monitor := this._monitors.ByWindow(hwnd)
            if monitor && monitor !== this.activeMonitor {
                this.activeMonitor := monitor
                debug("Monitor {} is now active", monitor.Index)
            }
            goto fallthrough
        case EV_WINDOW_SHOWN, EV_WINDOW_UNCLOAKED, EV_WINDOW_RESTORED, EV_WINDOW_REPOSITIONED:
            fallthrough:
            window := this._manage(hwnd)
            if !window {
                return
            }

            monitor := this._monitors.ByWindow(window.handle)
            wsIdx := this.VD.DesktopByWindow(window.handle)
            if monitor !== window.monitor || wsIdx !== window.workspace.Index {
                this._reassociate(window, monitor, this._workspaces[monitor, wsIdx])
            }

            try {
                if WinGetMinMax("ahk_id" window.handle) >= 0 {
                    if !window.workspace.Appear(window.handle) {
                        switch event {
                        case EV_WINDOW_FOCUSED:
                            window.workspace.ActiveWindow := window.handle
                        case EV_WINDOW_REPOSITIONED:
                            window.workspace.Retile()
                        }
                    }
                }
            } catch TargetError {
                return this._drop(window.handle)
            }
        case EV_WINDOW_HIDDEN, EV_WINDOW_CLOAKED, EV_WINDOW_MINIMIZED:
            window := this._managed.Get(hwnd, 0)
            if window {
                this._hide(event, window)
            }
        case EV_WINDOW_DESTROYED:
            this._drop(hwnd)
        case EV_WINDOW_CREATED:
            ; Do nothing
        default:
            throw "Unknown window event: " event
        }
    }

    _onDesktopEvent(event, args) {
        switch event {
        case EV_DESKTOP_CHANGED:
            this._delayed.Drop("hide")
            this._delayed.Drop("activate")

            this.activeWsIdx := args.now
            debug("Current desktop changed from {} to {}", args.was, args.now)

            b := this._activate.Bind(this, this.activeMonitor, this.activeWsIdx)
            this._delayed.Add(b, 250, "activate")
        case EV_DESKTOP_RENAMED:
            debug("Desktop {} was renamed to {}", args.desktop, args.name)
        case EV_DESKTOP_CREATED:
            debug("Desktop {} was created", args.desktop)
        case EV_DESKTOP_DESTROYED:
            debug("Desktop {} was destroyed", args.desktopId)
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
                info("Monitor {} is active or non-existent", index)
                return
            }

            monitor := this._monitors.ByIndex(index)
            switch req.type {
            case "focus-monitor":
                ws := this._workspaces[monitor, this.activeWsIdx]
                if ws.MruTile {
                    WinActivate("ahk_id" ws.MruTile.data)
                } else {
                    ; If there is no tile associated, focus the monitor by
                    ; activating its taskbar.
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

                ; Retile again to mitigate cross-DPI issues
                b := window.workspace.Retile.Bind(window.workspace)
                this._delayed.Add(b, 10, "retile")

                if !req.follow {
                    return
                }
                this.activeMonitor := monitor
            }

            ; Also place the cursor in the middle of the specified screen for
            ; e.g. PowerToys Run
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
        debug("MonitorList {}", String(this._monitors))

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

    _manage(hwnd) {
        try {
            if this._managed.Has(hwnd) {
                info("ignore 0x{:08x} because it's already managed", hwnd)
                return this._managed[hwnd]
            }

            wsIdx := this.VD.DesktopByWindow(hwnd)
            if !wsIdx {
                procname := "N/A"
                try {
                    procname := WinGetProcessName("ahk_id" hwnd)
                }
                info("DesktopByWindow didn't work for 0x{:08x} procname={}",
                    hwnd, procname)
                return ""
            }

            style := WinGetStyle("ahk_id" hwnd)
            exstyle := WinGetExStyle("ahk_id" hwnd)
            if style & WS_VISIBLE == 0 {
                info("ignore 0x{:08x} because it's not visible", hwnd)
                return ""
            } else if IsWindowCloaked(hwnd) {
                info("ignore 0x{:08x} because it's cloaked", hwnd)
                return ""
            } else if style & WS_CAPTION == 0 {
                info("ignore 0x{:08x} because it has no WS_CAPTION", hwnd)
                return ""
            } else if exstyle & WS_EX_WINDOWEDGE == 0 {
                info("ignore 0x{:08x} because it has no WS_EX_WINDOWEDGE", hwnd)
                return ""
            } else if exstyle & WS_EX_DLGMODALFRAME !== 0 {
                info("ignore 0x{:08x} because it has WS_EX_DLGMODALFRAME", hwnd)
                return ""
            }

            monitor := this._monitors.ByWindow(hwnd)
            ws := this._workspaces[monitor, wsIdx]

            window := {
                handle: hwnd,
                monitor: monitor,
                workspace: ws,
            }
            this._managed[hwnd] := window

            wincls := WinGetClass("ahk_id" hwnd)
            title := WinGetTitle("ahk_id" hwnd)
            procname := WinGetProcessName("ahk_id" hwnd)
            debug("Now managing 0x{:08x} on ({}, {}) proc={} class={} title=`"{}`"",
                hwnd, monitor.Index, ws.Index, procname, wincls, title)

            return window
        } catch TargetError {
            return ""
        }
    }

    _drop(hwnd) {
        if !this._managed.Has(hwnd) {
            return ""
        }

        window := this._managed.Delete(hwnd)
        window.workspace.Disappear(hwnd)
        monitorIdx := this._monitors.Has(window.monitor)
            ? window.monitor.Index
            : -1
        extra := ""
        try {
            extra .= " proc=" WinGetProcessName("ahk_id" hwnd)
            extra .= " class=" WinGetClass("ahk_id" hwnd)
            extra .= " title='" WinGetTitle("ahk_id" hwnd) "'"
        }
        debug("Dropped 0x{:08x} from ({}, {}){}",
            hwnd, monitorIdx, window.workspace.Index, extra)
        return window
    }

    _reassociate(window, monitor, workspace) {
        debug("Window 0x{:08x} moved from ({}, {}) to ({}, {})",
            window.handle,
            window.monitor.Index, window.workspace.Index,
            monitor.Index, workspace.Index)
        window.workspace.Disappear(window.handle, false)
        window.monitor := monitor
        window.workspace := workspace
        workspace.Appear(window.handle)
    }

    _hide(event, window, wait := true) {
        if wait {
            this._delayed.Drop("hide")

            b := this._hide.Bind(this, event, window, false)
            this._delayed.Add(b, 400, "hide")
            return
        }

        window.workspace.Disappear(window.handle)
    }

    _activate(monitor, wsIdx) {
        if wsIdx !== this.activeWsIdx {
            debug("Don't activate because workspace changed")
            return
        } else if monitor !== this.activeMonitor {
            debug("Don't activate because monitor changed")
            return
        }

        ws := this._workspaces[monitor, wsIdx]
        hwnd := ws.ActiveWindow
        if hwnd && hwnd !== WinExist("A") {
            WinActivate("ahk_id" hwnd)
        }
    }
}
