#Include %A_LineFile%\..\..\vd\vd.ahk

Global WINEVENT_OUTOFCONTEXT   := 0
Global WINEVENT_SKIPOWNTHREAD  := 1
Global WINEVENT_SKIPOWNPROCESS := 2
Global WINEVENT_INCONTEXT      := 4
Global OBJID_WINDOW            := 0

Global EVENT_SYSTEM_FOREGROUND     := 0x0003
Global EVENT_SYSTEM_CAPTURESTART   := 0x0008
Global EVENT_SYSTEM_CAPTUREEND     := 0x0009
Global EVENT_SYSTEM_MOVESIZESTART  := 0x000A
Global EVENT_SYSTEM_MOVESIZEEND    := 0x000B
Global EVENT_SYSTEM_MINIMIZESTART  := 0x0016
Global EVENT_SYSTEM_MINIMIZEEND    := 0x0017
Global EVENT_SYSTEM_DESKTOPSWITCH  := 0x0020
Global EVENT_OBJECT_CREATE         := 0x8000
Global EVENT_OBJECT_DESTROY        := 0x8001
Global EVENT_OBJECT_SHOW           := 0x8002
Global EVENT_OBJECT_HIDE           := 0x8003
Global EVENT_OBJECT_REORDER        := 0x8004
Global EVENT_OBJECT_FOCUS          := 0x8005
Global EVENT_OBJECT_STATECHANGE    := 0x800A
Global EVENT_OBJECT_LOCATIONCHANGE := 0x800B
Global EVENT_OBJECT_NAMECHANGE     := 0x800C
Global EVENT_OBJECT_CLOAKED        := 0x8017
Global EVENT_OBJECT_UNCLOAKED      := 0x8018
Global EVENT_OBJECT_DRAGCOMPLETE   := 0x8023

Global WM_AHK_USER := 0x1000
Global WM_EVENT    := WM_AHK_USER + 1
Global WM_COMMAND  := WM_AHK_USER + 2
Global WM_QUERY    := WM_AHK_USER + 3

Global EV_WINDOW_SHOWN      := 1
Global EV_WINDOW_UNCLOAKED  := 2
Global EV_WINDOW_RESTORED   := 3
Global EV_WINDOW_HIDDEN     := 4
Global EV_WINDOW_CLOAKED    := 5
Global EV_WINDOW_MINIMIZED  := 6
Global EV_WINDOW_CREATED    := 7
Global EV_WINDOW_DESTROYED  := 8
Global EV_WINDOW_FOCUSED    := 9
Global EV_MIN_WINDOW        := EV_WINDOW_SHOWN
Global EV_MAX_WINDOW        := EV_WINDOW_FOCUSED
Global EV_DESKTOP_CHANGED   := 10
Global EV_DESKTOP_RENAMED   := 11
Global EV_DESKTOP_CREATED   := 12
Global EV_DESKTOP_DESTROYED := 13
Global EV_MIN_DESKTOP       := EV_DESKTOP_CHANGED
Global EV_MAX_DESKTOP       := EV_DESKTOP_DESTROYED

class WMEvents {
    __New() {
        msgproc := this._onMessage.Bind(&this)
        OnMessage(WM_EVENT  , msgproc)
        OnMessage(WM_COMMAND, msgproc)
        OnMessage(WM_QUERY  , msgproc)

        winEvHooks := new WinEventHooks(RegisterCallback(this._windowEvListener, "F", , &this))
        winEvHooks.Register(EVENT_SYSTEM_FOREGROUND)
        winEvHooks.Register(EVENT_SYSTEM_MINIMIZESTART, EVENT_SYSTEM_MINIMIZEEND)
        winEvHooks.Register(EVENT_OBJECT_CREATE, EVENT_OBJECT_DESTROY)
        winEvHooks.Register(EVENT_OBJECT_SHOW, EVENT_OBJECT_HIDE)
        winEvHooks.Register(EVENT_OBJECT_FOCUS)
        winEvHooks.Register(EVENT_OBJECT_CLOAKED, EVENT_OBJECT_UNCLOAKED)
        this.winEvHooks := winEvHooks

        this.VD := new VD(this._desktopEvListener.Bind(&this))
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
}

class WinEventHooks {
    __New(callback) {
        this.callback := callback
        this.hooks := []
    }

    __Delete() {
        for i, hook in this.hooks {
            DllCall("UnhookWinEvent"
                , "Ptr", hook
                , "Int")
        }
        DllCall("GlobalFree"
            , "Ptr", this.callback
            , "Ptr")
    }

    Register(min, max := 0) {
        this.hooks.Push(DllCall("SetWinEventHook"
            , "UInt", min
            , "UInt", max ? max : min
            , "Ptr", 0
            , "Ptr", this.callback
            , "UInt", 0
            , "UInt", 0
            , "UInt", WINEVENT_OUTOFCONTEXT
            , "Ptr"))
    }
}
