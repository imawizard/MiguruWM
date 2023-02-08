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
;;    mwm.VD.RenameDesktop("Last Desktop", mwm.VD.Count())
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

    ;; Focuses (and possibly create) a specific workspace.
    ;;
    ;; Examples:
    ;;    FocusWorkspace(1)   ; First
    ;;    FocusWorkspace(, 1) ; Current + 1
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

    ;; Focuses a specific monitor which are ordered by coordinates.
    ;;
    ;; Examples:
    ;;    FocusMonitor(1)             ; Leftmost
    ;;    FocusMonitor("primary")     ; Primary
    ;;    FocusMonitor("primary", -1) ; One left from primary
    ;;    FocusMonitor(, 1)           ; One right from current
    FocusMonitor(target := 0, delta := 0) {
        req := { type: "focus-monitor", target: target, delta: delta }
        PostMessage(WM_REQUEST, ObjPtrAddRef(req), , , "ahk_id" A_ScriptHwnd)
    }

    ;; Cycles through a workspace's windows.
    ;;
    ;; Examples:
    ;;    FocusWindow("next")     ; Cycle forwards
    ;;    FocusWindow("previous") ; Cycle backwards
    ;;    FocusWindow("master")   ; Focus first window of master pane
    FocusWindow(target) {
        req := { type: "focus-window", target: target }
        PostMessage(WM_REQUEST, ObjPtrAddRef(req), , , "ahk_id" A_ScriptHwnd)
    }

    ;; Moves the active window to another workspace.
    ;;
    ;; Examples:
    ;;    SendToWorkspace(, 1)        ; To next workspace and follow
    ;;    SendToWorkspace(3, , false) ; To third workspace, but don't follow
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

    ;; Moves the active window to another monitor's workspace.
    ;;
    ;; Examples:
    ;;    SendToMonitor(2)          ; To second leftmost monitor and follow
    ;;    SendToMonitor("primary")  ; To primary monitor and follow
    ;;    SendToMonitor(, 1, false) ; To next monitor, but don't follow
    SendToMonitor(target := 0, delta := 0, follow := true) {
        req := { type: "send-monitor" }
        req.target := target
        req.delta := delta
        req.follow := follow
        PostMessage(WM_REQUEST, ObjPtrAddRef(req), , , "ahk_id" A_ScriptHwnd)
    }

    ;; Swaps the active window with another one.
    ;;
    ;; Examples:
    ;;    SwapWindow("next")     ; With next one in cycle
    ;;    SwapWindow("previous") ; With previous one in cycle
    ;;    SwapWindow("master")   ; With first one in master pane
    SwapWindow(target) {
        req := { type: "swap-window", target: target }
        PostMessage(WM_REQUEST, ObjPtrAddRef(req), , , "ahk_id" A_ScriptHwnd)
    }

    ;; Floats or tiles a specific window or the currently active one.
    ;;
    ;; Examples:
    ;;    FloatWindow()           ; Float if it was tiled
    ;;    FloatWindow(, false)    ; Tile if it was floating
    ;;    FloatWindow(, "toggle") ; Float or tile respectively
    FloatWindow(hwnd := "A", value := true) {
        if hwnd == "A" {
            hwnd := WinExist("A")
        }
        req := { type: "float-window", hwnd: hwnd, value: value }
        PostMessage(WM_REQUEST, ObjPtrAddRef(req), , , "ahk_id" A_ScriptHwnd)
    }

    ;; Set the layout of a monitor's workspace.
    ;;
    ;; Examples:
    ;;    SetLayout("tall") ; Current monitor's current workspace
    SetLayout(value, workspace := 0, monitor := 0) {
        return this._access("layout", workspace, monitor, value)
    }

    Layout(workspace := 0, monitor := 0) {
        return ObjFromPtr(this._access("layout", workspace, monitor)).layout
    }

    ;; Sets the number of windows placed into a workspace's master pane.
    ;;
    ;; Examples:
    ;;    SetMasterCount(2)   ; Make master pane contain two windows
    ;;    SetMasterCount(, 2) ; Make master pane of the current monitor's
    ;;                        ; current workspace contain two more windows
    SetMasterCount(value := unset, delta := 0, workspace := 0, monitor := 0) {
        return this._access("master-count", workspace, monitor, value ?? unset, delta)
    }

    ;; Returns the number of windows that would be put into the master pane.
    MasterCount(workspace := 0, monitor := 0) {
        return this._access("master-count", workspace, monitor)
    }

    ;; Shrinks or expands the master pane.
    ;;
    ;; Examples:
    ;;    SetMasterSize(0.62) ; Set it to 62%
    SetMasterSize(value := unset, delta := 0, workspace := 0, monitor := 0) {
        return this._access("master-size", workspace, monitor, value ?? unset, delta)
    }

    ;; Returns the current size of the master pane.
    MasterSize(workspace := 0, monitor := 0) {
        return this._access("master-size", workspace, monitor)
    }

    ;; Changes the space to the border of the screen.
    ;;
    ;; Examples:
    ;;    SetPadding(, -2) ; Decrease by two
    SetPadding(value := unset, delta := 0, workspace := 0, monitor := 0) {
        return this._access("padding", workspace, monitor, value ?? unset, delta)
    }

    ;; Returns the space to the border of the screen.
    Padding(workspace := 0, monitor := 0) {
        return this._access("padding", workspace, monitor)
    }

    ;; Changes the gaps between windows.
    ;;
    ;; Examples:
    ;;    SetSpacing(20, , 3, 2) ; For the third workspace of the second monitor
    SetSpacing(value := unset, delta := 0, workspace := 0, monitor := 0) {
        return this._access("spacing", workspace, monitor, value ?? unset, delta)
    }

    ;; Returns the gap between windows.
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
