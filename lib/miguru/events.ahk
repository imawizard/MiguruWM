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

WM_WININICHANGE  := 0x001A
WM_SETTINGCHANGE := WM_WININICHANGE
WM_DISPLAYCHANGE := 0x007E
WM_DEVICECHANGE  := 0x0219
WM_DPICHANGED    := 0x02E0

DBT_DEVNODES_CHANGED      := 0x0007
SPI_SETWORKAREA           := 0x002F
SPI_SETLOGICALDPIOVERRIDE := 0x009F

WM_AHK_USER := 0x1000
WM_EVENT    := WM_AHK_USER + 1
WM_REQUEST  := WM_AHK_USER + 2

EV_WINDOW_SHOWN        := 1
EV_WINDOW_UNCLOAKED    := 2
EV_WINDOW_RESTORED     := 3
EV_WINDOW_HIDDEN       := 4
EV_WINDOW_CLOAKED      := 5
EV_WINDOW_MINIMIZED    := 6
EV_WINDOW_CREATED      := 7
EV_WINDOW_DESTROYED    := 8
EV_WINDOW_FOCUSED      := 9
EV_WINDOW_POSITIONING  := 10
EV_WINDOW_REPOSITIONED := 11
EV_MIN_WINDOW          := EV_WINDOW_SHOWN
EV_MAX_WINDOW          := EV_WINDOW_REPOSITIONED
EV_DESKTOP_CHANGED     := 20
EV_DESKTOP_RENAMED     := 21
EV_DESKTOP_CREATED     := 22
EV_DESKTOP_DESTROYED   := 23
EV_MIN_DESKTOP         := EV_DESKTOP_CHANGED
EV_MAX_DESKTOP         := EV_DESKTOP_DESTROYED

class WMEvents {
    static Stringified := Map(
        EV_WINDOW_SHOWN,        "EV_WINDOW_SHOWN",
        EV_WINDOW_UNCLOAKED,    "EV_WINDOW_UNCLOAKED",
        EV_WINDOW_RESTORED,     "EV_WINDOW_RESTORED",
        EV_WINDOW_HIDDEN,       "EV_WINDOW_HIDDEN",
        EV_WINDOW_CLOAKED,      "EV_WINDOW_CLOAKED",
        EV_WINDOW_MINIMIZED,    "EV_WINDOW_MINIMIZED",
        EV_WINDOW_CREATED,      "EV_WINDOW_CREATED",
        EV_WINDOW_DESTROYED,    "EV_WINDOW_DESTROYED",
        EV_WINDOW_FOCUSED,      "EV_WINDOW_FOCUSED",
        EV_WINDOW_POSITIONING,  "EV_WINDOW_POSITIONING",
        EV_WINDOW_REPOSITIONED, "EV_WINDOW_REPOSITIONED",
        EV_DESKTOP_CHANGED,     "EV_DESKTOP_CHANGED",
        EV_DESKTOP_RENAMED,     "EV_DESKTOP_RENAMED",
        EV_DESKTOP_CREATED,     "EV_DESKTOP_CREATED",
        EV_DESKTOP_DESTROYED,   "EV_DESKTOP_DESTROYED",
    )

    __New() {
        this.msgproc :=
            ((fn, self, args*) =>
                fn.Call(ObjFromPtrAddRef(self), args*))
            .Bind(this._onMessage, ObjPtr(this))

        this.msgs := [
            WM_EVENT,
            WM_REQUEST,
            WM_DISPLAYCHANGE,
            WM_SETTINGCHANGE,
        ]
        for msg in this.msgs {
            OnMessage(msg, this.msgproc)
        }

        method := this._windowEvListener
        winEvHooks := WinEventHooks(
            CallbackCreate(
                ((fn, self, args*) =>
                    fn.Call(ObjFromPtrAddRef(self), args*))
                .Bind(method, ObjPtr(this)),
                "F", ; XXX: Is `fast` safe here?
                method.MinParams - 1,
            )
        )
        winEvHooks.Register(EVENT_SYSTEM_FOREGROUND)
        winEvHooks.Register(EVENT_SYSTEM_MINIMIZESTART, EVENT_SYSTEM_MINIMIZEEND)
        winEvHooks.Register(EVENT_OBJECT_CREATE, EVENT_OBJECT_DESTROY)
        winEvHooks.Register(EVENT_OBJECT_SHOW, EVENT_OBJECT_HIDE)
        winEvHooks.Register(EVENT_OBJECT_FOCUS)
        winEvHooks.Register(EVENT_OBJECT_CLOAKED, EVENT_OBJECT_UNCLOAKED)
        winEvHooks.Register(EVENT_SYSTEM_MOVESIZESTART, EVENT_SYSTEM_MOVESIZEEND)
        this.winEvHooks := winEvHooks

        this.VD := VD(
            ((fn, self, args*) =>
                fn.Call(ObjFromPtrAddRef(self), args*))
            .Bind(this._desktopEvListener, ObjPtr(this))
        )
    }

    __Delete() {
        for msg in this.msgs {
            OnMessage(msg, this.msgproc, 0)
        }
    }

    _onMessage(wparam, lparam, msg, hwnd) {
        Critical 1000

        ret := 0
        switch msg {
        case WM_EVENT:
            if wparam <= EV_MAX_WINDOW {
                trace(() => ["{}: {}",
                    WMEvents.Stringified[wparam], WinInfo(lparam)])
                ret := this._onWindowEvent(wparam, lparam)
            } else if wparam <= EV_MAX_DESKTOP {
                args := ObjFromPtr(lparam)
                trace(() => ["{}: {}",
                    WMEvents.Stringified[wparam], StringifySL(args)])
                ret := this._onDesktopEvent(wparam, args)
            }
        case WM_REQUEST:
            req := ObjFromPtr(wparam)
            debug(() => ["WM_REQUEST: {}", StringifySL(req)])
            try {
                ret := this._onRequest(req)
            } catch String as err {
                warn("Request failed: " err)
            }
        case WM_DISPLAYCHANGE, WM_DPICHANGED:
            debug("WM_DISPLAYCHANGE: lparam=0x{:08x} wparam=0x{:08x}",
                lparam, wparam)
            ret := this._onDisplayChange()
        case WM_SETTINGCHANGE:
            if wparam == SPI_SETWORKAREA {
                debug("SPI_SETWORKAREA: lparam={}", lparam)
                ret := this._onDisplayChange()
            }
        }
        return ret
    }

    _windowEvListener(hook, event, hwnd, objectId, childId, threadId, timestamp) {
        if !hwnd || objectId !== OBJID_WINDOW {
            ;; Only listen to window events, ignore events regarding controls.
            return
        }

        ;; Restrict handling of events for tracing and testing.
        ;static allow := Map(
        ;    "explorer.exe", true,
        ;    "teams.exe", true,
        ;)
        ;try {
        ;    if !allow.Get(StrLower(WinGetProcessName("ahk_id" hwnd)), false) {
        ;        return
        ;    }
        ;} catch {
        ;    return
        ;}

        try {
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
            case EVENT_SYSTEM_MOVESIZESTART:
                PostMessage(WM_EVENT, EV_WINDOW_POSITIONING, hwnd, , "ahk_id" A_ScriptHwnd)
            case EVENT_SYSTEM_MOVESIZEEND:
                PostMessage(WM_EVENT, EV_WINDOW_REPOSITIONED, hwnd, , "ahk_id" A_ScriptHwnd)
            default:
                throw "Unhandled window event: " event
            }
        } catch TargetError {
            ;; Ignore if A_ScriptHwnd is already gone
        }
    }

    _desktopEvListener(event, args) {
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
