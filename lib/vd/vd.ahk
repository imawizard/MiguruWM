#Include %A_LineFile%\..\common.ahk
#Include %A_LineFile%\..\interfaces\IApplicationView.ahk
#Include %A_LineFile%\..\interfaces\IApplicationViewCollection.ahk
#Include %A_LineFile%\..\interfaces\IObjectArray.ahk
#Include %A_LineFile%\..\interfaces\IVirtualDesktop.ahk
#Include %A_LineFile%\..\interfaces\IVirtualDesktopManager.ahk
#Include %A_LineFile%\..\interfaces\IVirtualDesktopManagerInternal.ahk
#Include %A_LineFile%\..\interfaces\IVirtualDesktopNotificationService.ahk
#Include %A_LineFile%\..\interfaces\IVirtualDesktopPinnedApps.ahk
#Include %A_LineFile%\..\wrappers\ApplicationView.ahk
#Include %A_LineFile%\..\wrappers\ApplicationViewCollection.ahk
#Include %A_LineFile%\..\wrappers\ComObject.ahk
#Include %A_LineFile%\..\wrappers\VirtualDesktop.ahk
#Include %A_LineFile%\..\wrappers\VirtualDesktopManager.ahk
#Include %A_LineFile%\..\wrappers\VirtualDesktopNotificationService.ahk
#Include %A_LineFile%\..\wrappers\VirtualDesktopPinnedApps.ahk

class VD {
    __New(callback := "", maxDesktops := 20) {
        CLSID_ImmersiveShell := "{C2F03A33-21F5-47FA-B4BB-156362A2F239}"
        immersiveShell := ComObjCreate(CLSID_ImmersiveShell, IID_Unknown)

        this.viewCollection := new ApplicationViewCollection(immersiveShell)
        this.manager := new VirtualDesktopManager(immersiveShell)
        this.notificationService := new VirtualDesktopNotificationService(immersiveShell)
        this.pinnedApps := new VirtualDesktopPinnedApps(immersiveShell)

        ObjRelease(immersiveShell)

        fn := this._eventListener.Bind(&this)
        this.listener := new VirtualDesktopNotificationListener(fn)
        this.notificationService.Register(this.listener)
        this.callback := callback

        this.MaxDesktops := maxDesktops
    }

    __Delete() {
        this.notificationService.Unregister(this.listener)
    }

    _eventListener(event, args) {
        this := Object(this)

        Switch event {
        Case "desktop_changed":
            this.callback.Call(event
                , { now: this._desktopIndexById(args.now.GetId())
                , was: this._desktopIndexById(args.was.GetId()) })
        Case "desktop_renamed":
            this.callback.Call(event
                , { desktop: this._desktopIndexById(args.desktop.GetId())
                , name: args.name })
        Case "desktop_created":
            this.callback.Call(event
                , { desktop: this._desktopIndexById(args.desktop.GetId()) })
        Case "desktop_destroyed":
            this.callback.Call(event
                , { desktopId: args.desktop.GetId()
                , fallback: this._desktopIndexById(args.fallback.GetId()) })
        Case "desktop_destroy_begin":
            this.callback.Call(event
                , { desktopId: args.desktop.GetId()
                , fallback: this._desktopIndexById(args.fallback.GetId()) })
        Case "desktop_destroy_failed":
            this.callback.Call(event
                , { desktopId: args.desktop.GetId()
                , fallback: this._desktopIndexById(args.fallback.GetId()) })
        Case "view_changed":
            this.callback.Call(event
                , { view: args.view })
        }
    }

    _desktop(index, ensure) {
        if (index < 1) {
            Return false
        }

        desktops := this.manager.GetDesktops()
        if (index <= desktops.GetCount()) {
            Return desktops.GetAt(index)
        }

        if !ensure {
            Return false
        } else if (index > this.MaxDesktops) {
            Return false
        }

        last := false
        Loop % index - desktops.GetCount() {
            last := this.manager.CreateDesktop()
        }
        Return last
    }

    _desktopIndexById(needle) {
        desktops := this.manager.GetDesktops()
        Loop % desktops.GetCount() {
            desktop := desktops.GetAt(A_Index)
            if (desktop.GetId() == needle) {
                Return A_Index
            }
        }
        Return 0
    }

    _sendWindowToDesktop(hwnd, index, ensure) {
        view := this.viewCollection.GetViewForHwnd(hwnd)
        if !view {
            Return false
        }
        desktop := this._desktop(index, ensure)
        if !desktop {
            Return false
        }
        this.manager.MoveViewToDesktop(view, desktop)
        Return desktop
    }

    ; API ..................................................................{{{

    ; Returns the number of virtual desktops, or 0 on error.
    Count() {
        desktops := this.manager.GetDesktops()
        Return desktops ? desktops.GetCount() : 0
    }

    ; Returns the 1-based index of the current desktop.
    CurrentDesktop() {
        current := this.manager.GetCurrentDesktop()
        Return this._desktopIndexById(current.GetId())
    }

    ; Returns the 1-based index of the created desktop, or 0 on error.
    CreateDesktop() {
        desktops := this.manager.GetDesktops()
        count := desktops.GetCount()
        if !this._desktop(count + 1, true) {
            Return 0
        }
        Return count + 1
    }

    ; Creates desktops if needed, returns false on error.
    EnsureDesktops(count) {
        Return this._desktop(count, true) != false
    }

    ; Returns the name of a specific desktop, or the current one's if index is 0.
    DesktopName(index := 0) {
        if (index < 0) {
            Return false
        } else if (index == 0) {
            desktop := this.manager.GetCurrentDesktop()
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
            desktop := this.manager.GetCurrentDesktop()
        } else {
            desktops := this.manager.GetDesktops()
            count := desktops.GetCount()
            if (index > count || count < 2) {
                Return false
            }
            desktop := desktops.GetAt(index)
        }

        if !desktop {
            Return false
        }
        fallback := this.manager.GetAdjacentDesktop(desktop, "right")
        if !fallback {
            fallback := this.manager.GetAdjacentDesktop(desktop, "left")
        }
        Return this.manager.RemoveDesktop(desktop, fallback)
    }

    ; Focuses a specific desktop. Creates new desktops on demand if ensure is
    ; true.
    FocusDesktop(index, ensure := true) {
        desktop := this._desktop(index, ensure)
        if !desktop {
            Return false
        }
        WinActivate, ahk_class Shell_TrayWnd
        Return this.manager.SwitchDesktop(desktop)
    }

    ; Sends a window to a specific desktop. Creates new desktops on demand if
    ; ensure is true.
    SendWindowToDesktop(hwnd, index, ensure := true) {
        Return this._sendWindowToDesktop(hwnd, index, ensure) != false
    }

    ; Returns the 1-based index of the desktop containing a specific window.
    DesktopByWindow(hwnd) {
        guid := this.manager.GetWindowDesktopId(hwnd)
        Return this._desktopIndexById(guid)
    }

    ; ......................................................................}}}
}
