#Include %A_LineFile%\..\..\vd\vd.ahk
#Include %A_LineFile%\..\constants.ahk

class MiguruWM {
    __New() {
        this.VD := new VD(this._desktopEvListener.Bind(&this))
        this._setupWinEventHooks()

        msgproc := this._onMessage.Bind(&this)
        OnMessage(WM_EVENT  , msgproc)
        OnMessage(WM_COMMAND, msgproc)
        OnMessage(WM_QUERY  , msgproc)
    }

    __Delete() {
        this._destroyWinEventHooks()
    }

    _setupWinEventHooks() {
        this.callback := RegisterCallback(this._windowEvListener, F, , &this)

        this._registerWinEventHook(EVENT_SYSTEM_FOREGROUND)
        this._registerWinEventHook(EVENT_SYSTEM_MINIMIZESTART, EVENT_SYSTEM_MINIMIZEEND)
        this._registerWinEventHook(EVENT_OBJECT_CREATE, EVENT_OBJECT_DESTROY)
        this._registerWinEventHook(EVENT_OBJECT_SHOW, EVENT_OBJECT_HIDE)
        this._registerWinEventHook(EVENT_OBJECT_FOCUS)
        this._registerWinEventHook(EVENT_OBJECT_CLOAKED, EVENT_OBJECT_UNCLOAKED)
    }

    _registerWinEventHook(min, max := 0) {
        hook := DllCall("SetWinEventHook"
            , "UInt", min
            , "UInt", max ? max : min
            , "Ptr", 0
            , "Ptr", this.callback
            , "UInt", 0
            , "UInt", 0
            , "UInt", WINEVENT_OUTOFCONTEXT
            , "Ptr")

        if !this.hooks {
            this.hooks := []
        }
        this.hooks.Push(hook)
    }

    _destroyWinEventHooks() {
        for i, hook in this.hooks {
            DllCall("UnhookWinEvent"
                , "Ptr", hook
                , "Int")
        }
        DllCall("GlobalFree"
            , "Ptr", this.callback
            , "Ptr")
    }

    _windowEvListener(event, hwnd, objectId, childId, threadId, timestamp) {
        Critical 100
        hook := this, this := Object(A_EventInfo)

        if (!hwnd || objectId != OBJID_WINDOW) {
            ; Only listen to window events, ignore events regarding controls.
            Return
        }

        Switch event {
        Case EVENT_OBJECT_SHOW:
            PostMessage, WM_EVENT, EV_WINDOW_SHOWN, hwnd, , % "ahk_id" A_ScriptHwnd
        Case EVENT_OBJECT_UNCLOAKED:
            PostMessage, WM_EVENT, EV_WINDOW_UNCLOAKED, hwnd, , % "ahk_id" A_ScriptHwnd
        Case EVENT_SYSTEM_MINIMIZEEND:
            PostMessage, WM_EVENT, EV_WINDOW_RESTORED, hwnd, , % "ahk_id" A_ScriptHwnd
        Case EVENT_OBJECT_HIDE:
            PostMessage, WM_EVENT, EV_WINDOW_HIDDEN, hwnd, , % "ahk_id" A_ScriptHwnd
        Case EVENT_OBJECT_CLOAKED:
            PostMessage, WM_EVENT, EV_WINDOW_CLOAKED, hwnd, , % "ahk_id" A_ScriptHwnd
        Case EVENT_SYSTEM_MINIMIZESTART:
            PostMessage, WM_EVENT, EV_WINDOW_MINIMIZED, hwnd, , % "ahk_id" A_ScriptHwnd
        Case EVENT_OBJECT_CREATE:
            PostMessage, WM_EVENT, EV_WINDOW_CREATED, hwnd, , % "ahk_id" A_ScriptHwnd
        Case EVENT_OBJECT_DESTROY:
            PostMessage, WM_EVENT, EV_WINDOW_DESTROYED, hwnd, , % "ahk_id" A_ScriptHwnd
        Case EVENT_SYSTEM_FOREGROUND, EVENT_OBJECT_FOCUS:
            PostMessage, WM_EVENT, EV_WINDOW_FOCUSED, hwnd, , % "ahk_id" A_ScriptHwnd
        }
    }

    _desktopEvListener(event, args) {
        Critical 100
        this := Object(this)

        Switch event {
        Case "desktop_changed":
            PostMessage, WM_EVENT, EV_DESKTOP_CHANGED, Object(args), , % "ahk_id" A_ScriptHwnd
        Case "desktop_renamed":
            PostMessage, WM_EVENT, EV_DESKTOP_RENAMED, Object(args), , % "ahk_id" A_ScriptHwnd
        Case "desktop_created":
            PostMessage, WM_EVENT, EV_DESKTOP_CREATED, Object(args), , % "ahk_id" A_ScriptHwnd
        Case "desktop_destroyed":
            PostMessage, WM_EVENT, EV_DESKTOP_DESTROYED, Object(args), , % "ahk_id" A_ScriptHwnd
        }
    }

    _notify(event, hwnd) {
        index := this.VD.DesktopByWindow(hwnd)
        if !index {
            Return
        }

        log("Window: {:x}, Desktop: {}, Event: {}", hwnd, index, event)
    }


    _onMessage(wparam, lparam, msg) {
        Critical 100
        this := Object(this)

        Switch msg {
        Case WM_EVENT:
            if (wparam <= EV_MAX_WINDOW) {
                ret := this._onWindowEvent(wparam, lparam)
            } else if (wparam <= EV_MAX_DESKTOP) {
                ret := this._onDesktopEvent(wparam, Object(lparam))
                ObjRelease(lparam)
            }
        Case WM_COMMAND:
            ret := this._onCommand(wparam, lparam)
        Case WM_QUERY:
            ret := this._onQuery(wparam, lparam)
        }
        Return ret
    }

    _onWindowEvent(event, hwnd) {
        Switch event {
        Case EV_WINDOW_SHOWN:
            index := this.VD.DesktopByWindow(hwnd)
            if !index {
                Return
            }
            log("Window {:x} is shown on Desktop {}", hwnd, index)
        Case EV_WINDOW_UNCLOAKED:
            index := this.VD.DesktopByWindow(hwnd)
            if !index {
                Return
            }
            log("Window {:x} is uncloaked on Desktop {}", hwnd, index)
        Case EV_WINDOW_RESTORED:
        Case EV_WINDOW_HIDDEN:
        Case EV_WINDOW_CLOAKED:
        Case EV_WINDOW_MINIMIZED:
        Case EV_WINDOW_CREATED:
        Case EV_WINDOW_DESTROYED:
        Case EV_WINDOW_FOCUSED:
        }
    }

    _onDesktopEvent(event, args) {
        Switch event {
        Case EV_DESKTOP_CHANGED:
            log("Current desktop changed from {} to {}", args.was, args.now)
        Case EV_DESKTOP_RENAMED:
            log("Desktop {} was renamed to {}", args.desktop, args.name)
        Case EV_DESKTOP_CREATED:
            log("Desktop {} was created", args.desktop)
        Case EV_DESKTOP_DESTROYED:
            log("Desktop {} was destroyed", args.desktopId)
        }
    }

    _onCommand(cmd, param) {
        Switch cmd {
        }
    }

    _onQuery(query, param) {
        Switch query {
        }
    }

    ; API ..................................................................{{{

    FocusWorkspace(target) {
        this.VD.FocusDesktop(target)
    }

    SendToWorkspace(target) {
        this.VD.SendWindowToDesktop(WinExist("A"), target)
    }

    ; ......................................................................}}}
}
