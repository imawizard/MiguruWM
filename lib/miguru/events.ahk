#include ..\vd\vd.ahk

WINEVENT_OUTOFCONTEXT   := 0
WINEVENT_SKIPOWNTHREAD  := 1
WINEVENT_SKIPOWNPROCESS := 2
WINEVENT_INCONTEXT      := 4
OBJID_WINDOW            := 0

EVENT_SYSTEM_FOREGROUND     := 0x0003
EVENT_SYSTEM_CAPTURESTART   := 0x0008
EVENT_SYSTEM_CAPTUREEND     := 0x0009
EVENT_SYSTEM_MOVESIZESTART  := 0x000A
EVENT_SYSTEM_MOVESIZEEND    := 0x000B
EVENT_SYSTEM_MINIMIZESTART  := 0x0016
EVENT_SYSTEM_MINIMIZEEND    := 0x0017
EVENT_SYSTEM_DESKTOPSWITCH  := 0x0020
EVENT_OBJECT_CREATE         := 0x8000
EVENT_OBJECT_DESTROY        := 0x8001
EVENT_OBJECT_SHOW           := 0x8002
EVENT_OBJECT_HIDE           := 0x8003
EVENT_OBJECT_REORDER        := 0x8004
EVENT_OBJECT_FOCUS          := 0x8005
EVENT_OBJECT_STATECHANGE    := 0x800A
EVENT_OBJECT_LOCATIONCHANGE := 0x800B
EVENT_OBJECT_NAMECHANGE     := 0x800C
EVENT_OBJECT_CLOAKED        := 0x8017
EVENT_OBJECT_UNCLOAKED      := 0x8018
EVENT_OBJECT_DRAGCOMPLETE   := 0x8023

WM_AHK_USER := 0x1000
WM_EVENT    := WM_AHK_USER + 1
WM_COMMAND  := WM_AHK_USER + 2
WM_QUERY    := WM_AHK_USER + 3

EV_WINDOW_SHOWN      := 1
EV_WINDOW_UNCLOAKED  := 2
EV_WINDOW_RESTORED   := 3
EV_WINDOW_HIDDEN     := 4
EV_WINDOW_CLOAKED    := 5
EV_WINDOW_MINIMIZED  := 6
EV_WINDOW_CREATED    := 7
EV_WINDOW_DESTROYED  := 8
EV_WINDOW_FOCUSED    := 9
EV_MIN_WINDOW        := EV_WINDOW_SHOWN
EV_MAX_WINDOW        := EV_WINDOW_FOCUSED
EV_DESKTOP_CHANGED   := 10
EV_DESKTOP_RENAMED   := 11
EV_DESKTOP_CREATED   := 12
EV_DESKTOP_DESTROYED := 13
EV_MIN_DESKTOP       := EV_DESKTOP_CHANGED
EV_MAX_DESKTOP       := EV_DESKTOP_DESTROYED

class WMEvents {
    __New() {
        w := (fn, self, args*) => fn.Call(ObjFromPtrAddRef(self), args*)
        msgproc := w.Bind(this._onMessage, ObjPtr(this))
        OnMessage(WM_EVENT  , msgproc)
        OnMessage(WM_COMMAND, msgproc)
        OnMessage(WM_QUERY  , msgproc)

        w := (fn, self, args*) => fn.Call(ObjFromPtrAddRef(self), args*)
        method := this._windowEvListener
        self := ObjPtr(this)
        b := w.Bind(method, self)
        callback := CallbackCreate(b, "F", method.MinParams - 1)
        winEvHooks := WinEventHooks(callback)
        winEvHooks.Register(EVENT_SYSTEM_FOREGROUND)
        winEvHooks.Register(EVENT_SYSTEM_MINIMIZESTART, EVENT_SYSTEM_MINIMIZEEND)
        winEvHooks.Register(EVENT_OBJECT_CREATE, EVENT_OBJECT_DESTROY)
        winEvHooks.Register(EVENT_OBJECT_SHOW, EVENT_OBJECT_HIDE)
        winEvHooks.Register(EVENT_OBJECT_FOCUS)
        winEvHooks.Register(EVENT_OBJECT_CLOAKED, EVENT_OBJECT_UNCLOAKED)
        this.winEvHooks := winEvHooks

        w := (fn, self, args*) => fn.Call(ObjFromPtrAddRef(self), args*)
        w := w.Bind(this._desktopEvListener, ObjPtr(this))
        this.VD := VD(w)
    }

    _onMessage(wparam, lparam, msg, hwnd) {
        Critical 100

        switch msg {
        case WM_EVENT:
            if wparam <= EV_MAX_WINDOW {
                ret := this._onWindowEvent(wparam, lparam)
            } else if wparam <= EV_MAX_DESKTOP {
                ret := this._onDesktopEvent(wparam, ObjFromPtr(lparam))
            }
        case WM_COMMAND:
            ret := this._onCommand(wparam, lparam)
        case WM_QUERY:
            ret := this._onQuery(wparam, lparam)
        }
        return ret
    }

    _windowEvListener(hook, event, hwnd, objectId, childId, threadId, timestamp) {
        Critical 100

        if !hwnd || objectId !== OBJID_WINDOW {
            ; Only listen to window events, ignore events regarding controls.
            return
        }

        switch event {
        case EVENT_OBJECT_SHOW:
            PostMessage(WM_EVENT, EV_WINDOW_SHOWN, hwnd, , "ahk_id" A_ScriptHwnd)
        case EVENT_OBJECT_UNCLOAKED:
            PostMessage(WM_EVENT, EV_WINDOW_UNCLOAKED, hwnd, , "ahk_id" A_ScriptHwnd)
        case EVENT_SYSTEM_MINIMIZEEND:
            PostMessage(WM_EVENT, EV_WINDOW_RESTORED, hwnd, , "ahk_id" A_ScriptHwnd)
        case EVENT_OBJECT_HIDE:
            PostMessage(WM_EVENT, EV_WINDOW_HIDDEN, hwnd, , "ahk_id" A_ScriptHwnd)
        case EVENT_OBJECT_CLOAKED:
            PostMessage(WM_EVENT, EV_WINDOW_CLOAKED, hwnd, , "ahk_id" A_ScriptHwnd)
        case EVENT_SYSTEM_MINIMIZESTART:
            PostMessage(WM_EVENT, EV_WINDOW_MINIMIZED, hwnd, , "ahk_id" A_ScriptHwnd)
        case EVENT_OBJECT_CREATE:
            PostMessage(WM_EVENT, EV_WINDOW_CREATED, hwnd, , "ahk_id" A_ScriptHwnd)
        case EVENT_OBJECT_DESTROY:
            PostMessage(WM_EVENT, EV_WINDOW_DESTROYED, hwnd, , "ahk_id" A_ScriptHwnd)
        case EVENT_SYSTEM_FOREGROUND, EVENT_OBJECT_FOCUS:
            PostMessage(WM_EVENT, EV_WINDOW_FOCUSED, hwnd, , "ahk_id" A_ScriptHwnd)
        }
    }

    _desktopEvListener(event, args) {
        Critical 100

        switch event {
        case "desktop_changed":
            PostMessage(WM_EVENT, EV_DESKTOP_CHANGED, ObjPtrAddRef(args), , "ahk_id" A_ScriptHwnd)
        case "desktop_renamed":
            PostMessage(WM_EVENT, EV_DESKTOP_RENAMED, ObjPtrAddRef(args), , "ahk_id" A_ScriptHwnd)
        case "desktop_created":
            PostMessage(WM_EVENT, EV_DESKTOP_CREATED, ObjPtrAddRef(args), , "ahk_id" A_ScriptHwnd)
        case "desktop_destroyed":
            PostMessage(WM_EVENT, EV_DESKTOP_DESTROYED, ObjPtrAddRef(args), , "ahk_id" A_ScriptHwnd)
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
            DllCall(
                "UnhookWinEvent",
                "Ptr", hook,
                "Int",
            )
        }
        CallbackFree(this.callback)
    }

    Register(min, max := 0) {
        this.hooks.Push(DllCall(
            "SetWinEventHook",
            "UInt", min,
            "UInt", max ? max : min,
            "Ptr", 0,
            "Ptr", this.callback,
            "UInt", 0,
            "UInt", 0,
            "UInt", WINEVENT_OUTOFCONTEXT,
            "Ptr",
        ))
    }
}
