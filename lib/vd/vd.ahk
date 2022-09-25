#Include common.ahk
#Include ComObjectImpl.ahk
#Include InterfaceWrapper.ahk
#Include interfaces\IApplicationView.ahk
#Include interfaces\IApplicationViewCollection.ahk
#Include interfaces\IInspectable.ahk
#Include interfaces\IObjectArray.ahk
#Include interfaces\IServiceProvider.ahk
#Include interfaces\IUnknown.ahk
#Include interfaces\IVirtualDesktop.ahk
#Include interfaces\IVirtualDesktopManager.ahk
#Include interfaces\IVirtualDesktopManagerInternal.ahk
#Include interfaces\IVirtualDesktopNotificationService.ahk
#Include interfaces\IVirtualDesktopPinnedApps.ahk
#Include wrappers\ApplicationView.ahk
#Include wrappers\ApplicationViewCollection.ahk
#Include wrappers\VirtualDesktop.ahk
#Include wrappers\VirtualDesktopManager.ahk
#Include wrappers\VirtualDesktopManagerInternal.ahk
#Include wrappers\VirtualDesktopNotificationListener.ahk
#Include wrappers\VirtualDesktopNotificationService.ahk
#Include wrappers\VirtualDesktopPinnedApps.ahk

class VD {
    __New(callback := "", maxDesktops := 20) {
        CLSID_ImmersiveShell := "{C2F03A33-21F5-47FA-B4BB-156362A2F239}"
        immersiveShell := ComObject(CLSID_ImmersiveShell, IUnknown.GUID)

        this.viewCollection := ApplicationViewCollection(immersiveShell)
        this.manager := VirtualDesktopManager(immersiveShell)
        this.managerInternal := VirtualDesktopManagerInternal(immersiveShell)
        this.notificationService := VirtualDesktopNotificationService(immersiveShell)
        this.pinnedApps := VirtualDesktopPinnedApps(immersiveShell)

        if callback {
            w := (fn, self, cb, args*) => fn.Call(ObjFromPtrAddRef(self), cb, args*)
            w := w.Bind(this._eventListener, ObjPtr(this), callback)
            listener := VirtualDesktopNotificationListener(w)
            this.notificationService.Register(listener)
        }

        this.MaxDesktops := maxDesktops
    }

    __Delete() {
        this.notificationService.UnregisterAll()
    }

    _eventListener(callback, event, args) {
        Switch event {
        Case "desktop_changed":
            callback.Call(event, {
                now: this._desktopIndexById(args.now.GetId()),
                was: this._desktopIndexById(args.was.GetId()),
            })
        Case "desktop_renamed":
            callback.Call(event, {
                desktop: this._desktopIndexById(args.desktop.GetId()),
                name: args.name,
            })
        Case "desktop_created":
            callback.Call(event, {
                desktop: this._desktopIndexById(args.desktop.GetId()),
            })
        Case "desktop_destroyed":
            callback.Call(event, {
                desktopId: args.desktop.GetId(),
                fallback: this._desktopIndexById(args.fallback.GetId()),
            })
        Case "desktop_destroy_begin":
            callback.Call(event, {
                desktopId: args.desktop.GetId(),
                fallback: this._desktopIndexById(args.fallback.GetId()),
            })
        Case "desktop_destroy_failed":
            callback.Call(event, {
                desktopId: args.desktop.GetId(),
                fallback: this._desktopIndexById(args.fallback.GetId()),
            })
        Case "view_changed":
            callback.Call(event, {
                view: args.view,
            })
        }
    }

    _desktop(index, ensure) {
        if (index < 1) {
            Return false
        }

        desktops := this.managerInternal.GetDesktops()
        if (index <= desktops.GetCount()) {
            Return desktops.GetAt(index)
        }

        if !ensure {
            Return false
        } else if (index > this.MaxDesktops) {
            Return false
        }

        last := false
        Loop index - desktops.GetCount() {
            last := this.managerInternal.CreateDesktop()
        }
        Return last
    }

    _desktopIndexById(needle) {
        desktops := this.managerInternal.GetDesktops()
        Loop desktops.GetCount() {
            desktop := desktops.GetAt(A_Index)
            if (desktop.GetId() == needle) {
                Return A_Index
            }
        }
        Return 0
    }

    _sendWindowToDesktop(hwnd, index, ensure) {
        view := this.viewCollection.GetViewForHwnd(hwnd)
        if !view.Ptr {
            Return false
        }
        desktop := this._desktop(index, ensure)
        if !desktop.Ptr {
            Return false
        }
        this.managerInternal.MoveViewToDesktop(view, desktop)
        Return desktop
    }

    ; API ..................................................................{{{

    ; Returns the number of virtual desktops, or 0 on error.
    Count() {
        desktops := this.managerInternal.GetDesktops()
        Return desktops ? desktops.GetCount() : 0
    }

    ; Returns the 1-based index of the current desktop.
    CurrentDesktop() {
        current := this.managerInternal.GetCurrentDesktop()
        Return this._desktopIndexById(current.GetId())
    }

    ; Returns the 1-based index of the created desktop, or 0 on error.
    CreateDesktop() {
        desktops := this.managerInternal.GetDesktops()
        count := desktops.GetCount()
        if !this._desktop(count + 1, true) {
            Return 0
        }
        Return count + 1
    }

    ; Creates desktops if needed, returns false on error.
    EnsureDesktops(count) {
        Return this._desktop(count, true) !== false
    }

    ; Returns the name of a specific desktop, or the current one's if index is 0.
    DesktopName(index := 0) {
        if (index < 0) {
            Return false
        } else if (index == 0) {
            desktop := this.managerInternal.GetCurrentDesktop()
        } else {
            desktop := this._desktop(index, false)
        }
        name := desktop.GetName()
        if !name {
            if (index == 0) {
                name := "Desktop" this._desktopIndexById(desktop.GetId())
            } else {
                name := "Desktop" index
            }
        }
        Return name
    }

    ; Destroys a specific desktop and places its windows if any on the next
    ; desktop to the right. Uses the one to the left if the rightmost was
    ; desktop was removed. Destroys the current desktop if index is 0.
    RemoveDesktop(index := 0) {
        if (index < 0) {
            Return false
        } else if (index == 0) {
            desktop := this.managerInternal.GetCurrentDesktop()
        } else {
            desktops := this.managerInternal.GetDesktops()
            count := desktops.GetCount()
            if (index > count || count < 2) {
                Return false
            }
            desktop := desktops.GetAt(index)
        }

        if !desktop.Ptr {
            Return false
        }
        fallback := this.managerInternal.GetAdjacentDesktop(desktop, "right")
        if !fallback.Ptr {
            fallback := this.managerInternal.GetAdjacentDesktop(desktop, "left")
        }
        Return this.managerInternal.RemoveDesktop(desktop, fallback)
    }

    ; Focuses a specific desktop. Creates new desktops on demand if ensure is
    ; true.
    FocusDesktop(index, ensure := true) {
        desktop := this._desktop(index, ensure)
        if !desktop.Ptr {
            Return false
        }
        WinActivate("ahk_class Shell_TrayWnd")
        Return this.managerInternal.SwitchDesktop(desktop)
    }

    ; Sends a window to a specific desktop. Creates new desktops on demand if
    ; ensure is true.
    SendWindowToDesktop(hwnd, index, ensure := true) {
        Return this._sendWindowToDesktop(hwnd, index, ensure) !== false
    }

    ; Returns the 1-based index of the desktop containing a specific window.
    DesktopByWindow(hwnd) {
        guid := this.manager.GetWindowDesktopId(hwnd)
        Return this._desktopIndexById(guid)
    }

    ; ......................................................................}}}
}
