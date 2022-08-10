Global SID_IVirtualDesktopNotificationService_19044 := "{A501FDEC-4A09-464C-AE4E-1B9C21B84918}"

class VirtualDesktopNotificationService {
    __New(immersiveShell) {
        serviceObj := CreateFromSIDs(immersiveShell
            , SID_IVirtualDesktopNotificationService_19044
            , "")
        if !serviceObj {
            Throw "Could not create VirtualDesktopNotificationService"
        }

        this.service := ConstructInterface(serviceObj
            , IVirtualDesktopNotificationService_19044
            , "")
        ObjRelease(serviceObj)
        if !this.service {
            Throw "Could not find IVirtualDesktopNotificationService"
        }

        this.handlers := {}
    }

    __Delete() {
        ObjRelease(this.service.ptr)
    }

    Register(listener) {
        handler := listener.ptr
        cookie := this.service.Register(handler)
        this.handlers[handler] := cookie
        Return cookie > 0
    }

    Unregister(listener) {
        handler := listener.ptr
        cookie := this.handlers[handler]
        Return this.service.Unregister(cookie)
    }
}

Global IID_IVirtualDesktopNotification_19044  := "{C179334C-4295-40D3-BEA1-C654D965605A}"
Global IID_IVirtualDesktopNotification2_19044 := "{1BA7CF30-3591-43FA-ABFA-4AAF7ABEEDB7}"

class VirtualDesktopNotificationListener extends ComObject {
    __New(callback) {
        base.__New([""
            , IID_IVirtualDesktopNotification_19044
            , IID_IVirtualDesktopNotification2_19044
            , ""], [""
            , "VirtualDesktopCreated"
            , "VirtualDesktopDestroyBegin"
            , "VirtualDesktopDestroyFailed"
            , "VirtualDesktopDestroyed"
            , "ViewVirtualDesktopChanged"
            , "CurrentVirtualDesktopChanged"
            , "VirtualDesktopRenamed"
            , ""])
        this.fn := callback
    }

    VirtualDesktopCreated(desktop) {
        this := Object(A_EventInfo)
        this.fn.Call("desktop_created"
            , { desktop: new VirtualDesktop(desktop)})
    }

    VirtualDesktopDestroyBegin(desktop, fallback) {
        this := Object(A_EventInfo)
        this.fn.Call("desktop_destroy_begin"
            , { desktop: new VirtualDesktop(desktop)
            , fallback: new VirtualDesktop(fallback) })
    }

    VirtualDesktopDestroyFailed(desktop, fallback) {
        this := Object(A_EventInfo)
        this.fn.Call("desktop_destroy_failed"
            , { desktop: new VirtualDesktop(desktop)
            , fallback: new VirtualDesktop(fallback) })
    }

    VirtualDesktopDestroyed(desktop, fallback) {
        this := Object(A_EventInfo)
        this.fn.Call("desktop_destroyed"
            , { desktop: new VirtualDesktop(desktop)
            , fallback: new VirtualDesktop(fallback) })
    }

    ViewVirtualDesktopChanged(view) {
        this := Object(A_EventInfo)
        this.fn.Call("view_changed"
            , { view: new ApplicationView(view) })
    }

    CurrentVirtualDesktopChanged(desktopFrom, desktopTo) {
        this := Object(A_EventInfo)
        this.fn.Call("desktop_changed"
            , { now: new VirtualDesktop(desktopTo)
            , was: new VirtualDesktop(desktopFrom) })
    }

    VirtualDesktopRenamed(desktop, hstr) {
        this := Object(A_EventInfo)
        len := 0
        str := DllCall("combase\WindowsGetStringRawBuffer"
            , "Ptr", hstr
            , "UIntP", len
            , "Ptr")
        this.fn.Call("desktop_renamed"
            , { desktop: new VirtualDesktop(desktop)
            , name: StrGet(str) })
    }
}
