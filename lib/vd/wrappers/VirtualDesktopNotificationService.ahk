SID_IVirtualDesktopNotificationService_19044 := "{A501FDEC-4A09-464C-AE4E-1B9C21B84918}"

class VirtualDesktopNotificationService extends InterfaceWrapper {
    Static Interfaces := [
        IVirtualDesktopNotificationService_19044,
    ]

    __New(immersiveShell) {
        IUnknown.FromSID(
            this,
            immersiveShell,
            SID_IVirtualDesktopNotificationService_19044,
        )

        this._handlers := Map()
    }

    Register(handler) {
        cookie := this.wrapped.Register(handler)
        this._handlers[handler] := cookie
        Return cookie > 0
    }

    Unregister(handler) {
        cookie := this._handlers[handler]
        this.wrapped.Unregister(cookie)
        this._handlers.Delete(handler)
    }

    UnregisterAll() {
        for handler, cookie in this._handlers {
            this.wrapped.Unregister(cookie)
        }
        this._handlers.Clear()
    }
}
