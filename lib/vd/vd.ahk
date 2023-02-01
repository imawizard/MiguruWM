#include common.ahk
#include ComObjectImpl.ahk
#include InterfaceWrapper.ahk
#include interfaces\IApplicationView.ahk
#include interfaces\IApplicationViewCollection.ahk
#include interfaces\IInspectable.ahk
#include interfaces\IObjectArray.ahk
#include interfaces\IServiceProvider.ahk
#include interfaces\IUnknown.ahk
#include interfaces\IVirtualDesktop.ahk
#include interfaces\IVirtualDesktopManager.ahk
#include interfaces\IVirtualDesktopManagerInternal.ahk
#include interfaces\IVirtualDesktopNotificationService.ahk
#include interfaces\IVirtualDesktopPinnedApps.ahk
#include wrappers\ApplicationView.ahk
#include wrappers\ApplicationViewCollection.ahk
#include wrappers\VirtualDesktop.ahk
#include wrappers\VirtualDesktopManager.ahk
#include wrappers\VirtualDesktopManagerInternal.ahk
#include wrappers\VirtualDesktopNotificationListener.ahk
#include wrappers\VirtualDesktopNotificationService.ahk
#include wrappers\VirtualDesktopPinnedApps.ahk

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
        switch event {
        case "desktop_changed":
            callback.Call(event, {
                now: this._desktopIndexById(args.now.GetId()),
                was: this._desktopIndexById(args.was.GetId()),
            })
        case "desktop_renamed":
            callback.Call(event, {
                desktop: this._desktopIndexById(args.desktop.GetId()),
                name: args.name,
            })
        case "desktop_created":
            callback.Call(event, {
                desktop: this._desktopIndexById(args.desktop.GetId()),
            })
        case "desktop_destroyed":
            callback.Call(event, {
                desktopId: args.desktop.GetId(),
                fallback: this._desktopIndexById(args.fallback.GetId()),
            })
        case "desktop_destroy_begin":
            callback.Call(event, {
                desktopId: args.desktop.GetId(),
                fallback: this._desktopIndexById(args.fallback.GetId()),
            })
        case "desktop_destroy_failed":
            callback.Call(event, {
                desktopId: args.desktop.GetId(),
                fallback: this._desktopIndexById(args.fallback.GetId()),
            })
        case "view_changed":
            callback.Call(event, {
                view: args.view,
            })
        }
    }

    _desktop(index, ensure) {
        if index < 1 {
            return false
        }

        desktops := this.managerInternal.GetDesktops()
        if index <= desktops.GetCount() {
            return desktops.GetAt(index)
        }

        if !ensure {
            return false
        } else if index > this.MaxDesktops {
            return false
        }

        last := false
        Loop index - desktops.GetCount() {
            last := this.managerInternal.CreateDesktop()
        }
        return last
    }

    _desktopIndexById(needle) {
        desktops := this.managerInternal.GetDesktops()
        Loop desktops.GetCount() {
            desktop := desktops.GetAt(A_Index)
            if desktop.GetId() == needle {
                return A_Index
            }
        }
        return 0
    }

    _sendWindowToDesktop(hwnd, index, ensure) {
        view := this.viewCollection.GetViewForHwnd(hwnd)
        if !view.Ptr {
            return false
        }
        desktop := this._desktop(index, ensure)
        if !desktop.Ptr {
            return false
        }
        this.managerInternal.MoveViewToDesktop(view, desktop)
        return desktop
    }

    ; API ..................................................................{{{

    ; Returns the number of virtual desktops, or 0 on error.
    Count() {
        desktops := this.managerInternal.GetDesktops()
        return desktops ? desktops.GetCount() : 0
    }

    ; Returns the 1-based index of the current desktop.
    CurrentDesktop() {
        current := this.managerInternal.GetCurrentDesktop()
        return this._desktopIndexById(current.GetId())
    }

    ; Returns the 1-based index of the created desktop, or 0 on error.
    CreateDesktop() {
        desktops := this.managerInternal.GetDesktops()
        count := desktops.GetCount()
        if !this._desktop(count + 1, true) {
            return 0
        }
        return count + 1
    }

    ; Creates desktops if needed, returns false on error.
    EnsureDesktops(count) {
        return this._desktop(count, true) !== false
    }

    ; Returns the name of a specific desktop, or the current one's if index is 0.
    DesktopName(index := 0) {
        if index < 0 {
            return false
        } else if index == 0 {
            desktop := this.managerInternal.GetCurrentDesktop()
        } else {
            desktop := this._desktop(index, false)
        }
        name := desktop.GetName()
        if !name {
            if index == 0 {
                name := "Desktop" this._desktopIndexById(desktop.GetId())
            } else {
                name := "Desktop" index
            }
        }
        return name
    }

    ; Renames a specific desktop by its 1-based index, or the current one if
    ; index is 0.
    RenameDesktop(name, index := 0) {
        if index < 0 {
            return false
        } else if index == 0 {
            desktop := this.managerInternal.GetCurrentDesktop()
        } else {
            desktop := this._desktop(index, false)
        }
        this.managerInternal.SetDesktopName(desktop, name)
        return true
    }

    ; Destroys a specific desktop and places its windows if any on the next
    ; desktop to the right. Uses the one to the left if the rightmost was
    ; desktop was removed. Destroys the current desktop if index is 0.
    RemoveDesktop(index := 0) {
        if index < 0 {
            return false
        } else if index == 0 {
            desktop := this.managerInternal.GetCurrentDesktop()
        } else {
            desktops := this.managerInternal.GetDesktops()
            count := desktops.GetCount()
            if index > count || count < 2 {
                return false
            }
            desktop := desktops.GetAt(index)
        }

        if !desktop.Ptr {
            return false
        }
        fallback := this.managerInternal.GetAdjacentDesktop(desktop, "right")
        if !fallback.Ptr {
            fallback := this.managerInternal.GetAdjacentDesktop(desktop, "left")
        }
        return this.managerInternal.RemoveDesktop(desktop, fallback)
    }

    ; Focuses a specific desktop. Creates new desktops on demand if ensure is
    ; true.
    FocusDesktop(index, ensure := true) {
        desktop := this._desktop(index, ensure)
        if !desktop.Ptr {
            return false
        }

        try {
            ; Fails if called when task view is open
            WinActivate("ahk_class Shell_TrayWnd")
        } catch TargetError {
            ; Do nothing
        }
        this.managerInternal.SwitchDesktop(desktop)

        ; Switch to last active window.
        Send("!{Esc}")
    }

    ; Sends a window to a specific desktop. Creates new desktops on demand if
    ; ensure is true.
    SendWindowToDesktop(hwnd, index, ensure := true) {
        return this._sendWindowToDesktop(hwnd, index, ensure) !== false
    }

    ; Returns the 1-based index of the desktop containing a specific window.
    DesktopByWindow(hwnd) {
        guid := this.manager.GetWindowDesktopId(hwnd)
        return this._desktopIndexById(guid)
    }

    ; ......................................................................}}}
}
