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

VD_UNKNOWN_DESKTOP   := -1
VD_UNASSIGNED_WINDOW := -2
VD_PINNED_WINDOW     := -3
VD_PINNED_APP        := -4

class VD {
    static windowIsPinnedDesktopGUID := ParseGUID("{C2DDEA68-66F2-4CF9-8264-1BFD00FBBBAC}")
    static appIsPinnedDesktopGUID := ParseGUID("{BB64D5B7-4DE3-4AB2-A87C-DB7601AEA7DC}")

    __New(callback := "", maxDesktops := 20) {
        CLSID_ImmersiveShell := "{C2F03A33-21F5-47FA-B4BB-156362A2F239}"
        immersiveShell := ComObject(CLSID_ImmersiveShell, IUnknown.GUID)

        this.viewCollection := ApplicationViewCollection(immersiveShell)
        this.manager := VirtualDesktopManager(immersiveShell)
        this.managerInternal := VirtualDesktopManagerInternal(immersiveShell)
        this.notificationService := VirtualDesktopNotificationService(immersiveShell)
        this.pinnedApps := VirtualDesktopPinnedApps(immersiveShell)

        if callback {
            this.notificationService.Register(
                VirtualDesktopNotificationListener(
                    ((fn, self, cb, args*) =>
                        fn.Call(ObjFromPtrAddRef(self), cb, args*))
                    .Bind(this._eventListener, ObjPtr(this), callback)
                )
            )
        }

        this.MaxDesktops := maxDesktops
    }

    ;; Returns the number of virtual desktops, or 0 on error.
    Count() {
        desktops := this.managerInternal.GetDesktops()
        return desktops ? desktops.GetCount() : 0
    }

    ;; Returns the 1-based index of the current desktop.
    CurrentDesktop() {
        current := this.managerInternal.GetCurrentDesktop()
        return this._desktopIndexById(current.GetId())
    }

    ;; Retrieves all desktops with their GUID and name.
    AllDesktops() {
        res := []
        desktops := this.managerInternal.GetDesktops()
        Loop desktops.GetCount() {
            desktop := desktops.GetAt(A_Index)
            res.Push({
                guid: StringifyGUID(desktop.GetId()),
                name: desktop.GetName() || "Desktop " A_Index
            })
        }
        return res
    }

    ;; Returns the 1-based index of the created desktop, or 0 on error.
    CreateDesktop() {
        desktops := this.managerInternal.GetDesktops()
        count := desktops.GetCount()
        if !this._desktop(count + 1, true) {
            return 0
        }
        return count + 1
    }

    ;; Creates desktops if needed, returns false on error.
    EnsureDesktops(count) {
        return this._desktop(count, true) !== false
    }

    ;; Returns the name of a specific desktop, or the current one's if index is 0.
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
                name := "Desktop " this._desktopIndexById(desktop.GetId())
            } else {
                name := "Desktop " index
            }
        }
        return name
    }

    ;; Returns the GUID of a specific desktop, or the current one's if index is 0.
    DesktopGUID(index := 0) {
        if index < 0 {
            return false
        } else if index == 0 {
            desktop := this.managerInternal.GetCurrentDesktop()
        } else {
            desktop := this._desktop(index, false)
        }
        return StringifyGUID(desktop.GetId())
    }

    ;; Renames a specific desktop by its 1-based index, or the current one if
    ;; index is 0.
    RenameDesktop(index := 0, name := "") {
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

    ;; Destroys a specific desktop and places its windows if any on the next
    ;; desktop to the right. Uses the one to the left if the rightmost was
    ;; desktop was removed. Destroys the current desktop if index is 0.
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

    ;; Focuses a specific desktop. Creates new desktops on demand if ensure is
    ;; true.
    FocusDesktop(index, ensure := true) {
        desktop := this._desktop(index, ensure)
        if !desktop.Ptr {
            return false
        }

        try {
            ;; Fails if called when task view is open.
            WinActivate("ahk_class Shell_TrayWnd")
        } catch TargetError {
            ;; Do nothing
        }
        this.managerInternal.SwitchDesktop(desktop)

        ;; Switch to last active window.
        Send("!{Esc}")
    }

    ;; Sends a window to a specific desktop. Creates new desktops on demand if
    ;; ensure is true.
    SendWindowToDesktop(hwnd, index, ensure := true) {
        return this._sendWindowToDesktop(hwnd, index, ensure) !== false
    }

    ;; Returns either the 1-based index of the desktop containing a specific
    ;; window, or a value less than 1, while a return value of 0 means that the
    ;; passed window wasn't found on any desktop or is non-existent and negative
    ;; values are part of an enum.
    DesktopByWindow(hwnd) {
        try {
            guid := this.manager.GetWindowDesktopId(hwnd)
            switch guid {
            case EmptyGUID:
                return VD_UNASSIGNED_WINDOW
            case VD.windowIsPinnedDesktopGUID:
                return VD_PINNED_WINDOW
            case VD.appIsPinnedDesktopGUID:
                return VD_PINNED_APP
            }
            desktop := this._desktopIndexById(guid)
            return desktop ? desktop : VD_UNKNOWN_DESKTOP
        } catch OSError as err {
            if err.Number !== E_ELEMENTNOTFOUND && err.Number !== E_INVALIDARG {
                throw err
            }
            return 0
        }
    }

    ;; Returns the GUID of the desktop containing a specific window, or an empty
    ;; string in case the window wasn't found on any or is non-existent.
    DesktopGUIDByWindow(hwnd) {
        try {
            return StringifyGUID(this.manager.GetWindowDesktopId(hwnd))
        } catch OSError as err {
            if err.Number !== E_ELEMENTNOTFOUND && err.Number !== E_INVALIDARG {
                throw err
            }
            return ""
        }
    }

    ;; Returns true if the specified window or all windows of the app the window
    ;; belongs to are pinned.
    IsWindowPinned(hwnd) {
        view := this.viewCollection.GetViewForHwnd(hwnd)
        if !view.Ptr {
            return false
        } else if this.pinnedApps.IsViewPinned(view) {
            return true
        }

        appId := view.GetAppUserModelId()
        if !appId {
            return false
        }
        return this.pinnedApps.IsAppIdPinned(appId)
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
}
