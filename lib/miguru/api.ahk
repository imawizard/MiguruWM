class MiguruAPI {
    static Init(target) {
        api := MiguruAPI.Prototype
        for k in api.OwnProps() {
            desc := api.GetOwnPropDesc(k)
            if desc.HasMethod("Call")
                || desc.HasMethod("Get")
                || desc.HasMethod("Set") {
                target.DefineProp(k, desc)
            }
        }
    }

    ; Focus (and possibly create) a specific workspace.
    ;
    ; Examples:
    ;    FocusWorkspace(1) ; first
    ;    FocusWorkspace(, 1) ; current + 1
    FocusWorkspace(target := 0, delta := 0) {
        current := this.VD.CurrentDesktop()
        if !target {
            target := current
        }
        target += delta
        if current !== target {
            this.VD.FocusDesktop(target)
        }
    }

    ; Focus a specific monitor which are ordered by coordinates.
    ;
    ; Examples:
    ;    FocusMonitor(1) ; leftmost
    ;    FocusMonitor("primary") ; primary
    ;    FocusMonitor("primary", -1) ; one left from primary
    ;    FocusMonitor(, 1) ; one right from current
    FocusMonitor(target := 0, delta := 0) {
        req := { type: "focus-monitor", target: target, delta: delta }
        PostMessage(WM_REQUEST, ObjPtrAddRef(req), , , "ahk_id" A_ScriptHwnd)
    }

    ; Cycle through a workspace's windows.
    ;
    ; Examples:
    ;    FocusWindow("next") ; cycle forwards
    ;    FocusWindow("previous") ; cycle backwards
    ;    FocusWindow("master") ; focus first window of master pane
    FocusWindow(target) {
        req := { type: "focus-window", target: target }
        PostMessage(WM_REQUEST, ObjPtrAddRef(req), , , "ahk_id" A_ScriptHwnd)
    }

    ; Move the active window to another workspace.
    ;
    ; Examples:
    ;    SendToWorkspace(3) ; to third workspace
    ;    SendToWorkspace(, 1) ; to next workspace
    SendToWorkspace(target := 0, delta := 0, follow := true) {
        current := this.VD.CurrentDesktop()
        if !target {
            target := current
        }
        target += delta
        if current !== target {
            this.VD.SendWindowToDesktop(WinExist("A"), target)
            if follow {
                this.VD.FocusDesktop(target)
            }
        }
    }

    ; Move the active window to another monitor's workspace.
    ;
    ; Examples:
    ;    SendToMonitor(2) ; to second leftmost monitor
    ;    SendToMonitor("primary") ; to primary monitor
    ;    SendToMonitor(, 1) ; to next monitor
    SendToMonitor(target := 0, delta := 0, follow := true) {
        req := { type: "send-monitor" }
        req.target := target
        req.delta := delta
        req.follow := follow
        PostMessage(WM_REQUEST, ObjPtrAddRef(req), , , "ahk_id" A_ScriptHwnd)
    }

    ; Swap the active window with another one.
    ;
    ; Examples:
    ;    SwapWindow("next") ; with next one in cycle
    ;    SwapWindow("previous") ; with previous one in cycle
    ;    SwapWindow("master") ; with first one in master pane
    SwapWindow(target) {
        req := { type: "swap-window", target: target }
        PostMessage(WM_REQUEST, ObjPtrAddRef(req), , , "ahk_id" A_ScriptHwnd)
    }

    ; Set the layout of a monitor's workspace.
    ;
    ; Examples:
    ;    SetLayout("tall") ; current monitor's current workspace
    SetLayout(value, workspace := 0, monitor := 0) {
        return this._access("layout", workspace, monitor, value)
    }

    Layout(workspace := 0, monitor := 0) {
        return ObjFromPtr(this._access("layout", workspace, monitor)).layout
    }

    ; Set the number of windows placed into a workspace's master pane.
    ;
    ; Examples:
    ;    SetMasterCount(2) ; Make master pane contain two windows
    ;    SetMasterCount(, 2) ; Make master pane of the current monitor's current
    ;                          workspace contain two more windows
    SetMasterCount(value := unset, delta := 0, workspace := 0, monitor := 0) {
        return this._access("master-count", workspace, monitor, value ?? unset, delta)
    }

    MasterCount(workspace := 0, monitor := 0) {
        return this._access("master-count", workspace, monitor)
    }

    ; Resize the master pane.
    SetMasterSize(value := unset, delta := 0, workspace := 0, monitor := 0) {
        return this._access("master-size", workspace, monitor, value ?? unset, delta)
    }

    MasterSize(workspace := 0, monitor := 0) {
        return this._access("master-size", workspace, monitor)
    }

    ; Change the space to the border of the screen.
    ;
    ; Examples:
    ;    SetPadding(, -2)
    SetPadding(value := unset, delta := 0, workspace := 0, monitor := 0) {
        return this._access("padding", workspace, monitor, value ?? unset, delta)
    }

    Padding(workspace := 0, monitor := 0) {
        return this._access("padding", workspace, monitor)
    }

    ; Change the gaps between windows.
    ;
    ; Examples:
    ;    SetSpacing(20, 3, 2) ; for the third workspace of the second monitor
    SetSpacing(value := unset, delta := 0, workspace := 0, monitor := 0) {
        return this._access("spacing", workspace, monitor, value ?? unset, delta)
    }

    Spacing(workspace := 0, monitor := 0) {
        return this._access("spacing", workspace, monitor)
    }

    _access(type, workspace, monitor, value := unset, delta := unset) {
        req := { type: type }
        if !IsSet(value) && !IsSet(delta) {
            return SendMessage(WM_REQUEST, ObjPtrAddRef(req), , , "ahk_id" A_ScriptHwnd)
        } else {
            if IsSet(value) {
                req.value := value
            }
            if IsSet(delta) {
                req.delta := delta
            }
            req.workspace := workspace
            req.monitor := monitor
            PostMessage(WM_REQUEST, ObjPtrAddRef(req), , , "ahk_id" A_ScriptHwnd)
        }
    }
}
