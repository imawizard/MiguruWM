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

class MiguruWM {
    __New() {
        this.VD := new VD(this._desktopEvListener.Bind(&this))
        this._setupWinEventHooks()
    }

    __Delete() {
        this._destroyWinEventHooks()
    }

    _setupWinEventHooks() {
        this.callback := RegisterCallback(this._windowEvListener, , , &this)

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
        Critical
        this := Object(A_EventInfo)

        if (!hwnd || objectId != OBJID_WINDOW) {
            Return
        }

        Switch event {
        Case EVENT_OBJECT_SHOW:
            this._notify("Shown", hwnd)
        Case EVENT_OBJECT_UNCLOAKED:
            this._notify("Uncloaked", hwnd)
        Case EVENT_SYSTEM_MINIMIZEEND:
            this._notify("Restored", hwnd)
        Case EVENT_OBJECT_HIDE:
            this._notify("Hidden", hwnd)
        Case EVENT_OBJECT_CLOAKED:
            this._notify("Cloaked", hwnd)
        Case EVENT_SYSTEM_MINIMIZESTART:
            this._notify("Minimized", hwnd)
        Case EVENT_OBJECT_CREATE:
            this._notify("Created", hwnd)
        Case EVENT_OBJECT_DESTROY:
            this._notify("Destroyed", hwnd)
        Case EVENT_SYSTEM_FOREGROUND, EVENT_OBJECT_FOCUS:
            this._notify("Focused", hwnd)
        }
    }

    _desktopEvListener(event, args) {
        this := Object(this)

        Switch event {
        Case "desktop_changed":
            log("Current desktop changed from {} to {}", args.was, args.now)
        Case "desktop_renamed":
            log("Desktop {} was renamed to {}", args.desktop, args.name)
        }
    }

    _notify(event, hwnd) {
        index := this.VD.DesktopByWindow(hwnd)
        if !index {
            Return
        }

        log("Window: {:x}, Desktop: {}, Event: {}", hwnd, index, event)
    }

    ; API..................................................................{{{

    FocusWorkspace(target) {
        this.VD.FocusDesktop(target)
    }

    SendToWorkspace(target) {
        this.VD.SendWindowToDesktop(WinExist("A"), target)
    }
}
