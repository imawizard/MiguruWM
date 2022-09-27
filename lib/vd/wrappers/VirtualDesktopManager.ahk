Global CLSID_IVirtualDesktopManager_19044       := "{AA509086-5CA9-4C25-8F95-589D3C07B48A}"
Global CLSID_IVirtualDesktopManager_22000       := "{B2F925B9-5A0F-4D2E-9F4D-2B1507593C10}"
Global SID_IVirtualDesktopManagerInternal_19044 := "{C5E0CDCA-7B6E-41B2-9FC4-D93975CC467B}"

class VirtualDesktopManager {
    __New(immersiveShell) {
        managerObj := CreateFromCLSIDs(""
            , CLSID_IVirtualDesktopManager_19044
            , CLSID_IVirtualDesktopManager_22000
            , "")
        if !managerObj {
            Throw "Could not create VirtualDesktopManager"
        }

        this.manager := ConstructInterface(managerObj
            , IVirtualDesktopManager_19044
            , "")
        ObjRelease(managerObj)
        if !this.manager {
            Throw "Could not find IVirtualDesktopManager"
        }

        managerInternalObj := CreateFromSIDs(immersiveShell
            , SID_IVirtualDesktopManagerInternal_19044
            , "")
        if !managerInternalObj {
            Throw "Could not create VirtualDesktopManagerInternal"
        }

        this.managerInternal := ConstructInterface(managerInternalObj
            , IVirtualDesktopManagerInternal3_19044
            , IVirtualDesktopManagerInternal2_19044
            , IVirtualDesktopManagerInternal_19044
            , IVirtualDesktopManagerInternal_22000
            , IVirtualDesktopManagerInternal_22489
            , "")
        ObjRelease(managerInternalObj)
        if !this.managerInternal {
            Throw "Could not find IVirtualDesktopManagerInternal"
        }
    }

    __Delete() {
        ObjRelease(this.manager.ptr)
        ObjRelease(this.managerInternal.ptr)
    }

    IsWindowOnCurrentVirtualDesktop(hwnd) {
        Return this.manager.IsWindowOnCurrentVirtualDesktop(hwnd)
    }

    GetWindowDesktopId(hwnd) {
        Return this.manager.GetWindowDesktopId(hwnd)
    }

    MoveWindowToDesktop(desktopId, hwnd) {
        Return this.manager.MoveWindowToDesktop()
    }

    GetCount() {
        Return this.managerInternal.GetCount()
    }

    MoveViewToDesktop(view, desktop) {
        Return this.managerInternal.MoveViewToDesktop(view.Ptr(), desktop.Ptr())
    }

    CanViewMoveDesktops(view) {
        Return this.managerInternal.CanViewMoveDesktops(view.Ptr())
    }

    GetCurrentDesktop() {
        desktop := this.managerInternal.GetCurrentDesktop()
        Return desktop ? new VirtualDesktop(desktop) : false
    }

    GetDesktops() {
        desktops := this.managerInternal.GetDesktops()
        Return desktops ? new VirtualDesktopArray(desktops) : false
    }

    GetAdjacentDesktop(desktop, direction) {
        desktop := this.managerInternal.GetAdjacentDesktop(desktop.Ptr(), direction)
        Return desktop ? new VirtualDesktop(desktop) : false
    }

    SwitchDesktop(desktop) {
        Return this.managerInternal.SwitchDesktop(desktop.Ptr())
    }

    CreateDesktop() {
        desktop := this.managerInternal.CreateDesktop()
        Return desktop ? new VirtualDesktop(desktop) : false
    }

    RemoveDesktop(desktop, fallback) {
        Return this.managerInternal.RemoveDesktop(desktop.Ptr(), fallback.Ptr())
    }

    FindDesktop(desktopId) {
        desktop := this.managerInternal.FindDesktop(desktopId)
        Return desktop ? new VirtualDesktop(desktop) : false
    }

    SetDesktopName(desktop, name) {
        Return this.managerInternal.SetDesktopName(desktop.Ptr(), name)
    }
}

class VirtualDesktopArray {
    __New(ptr) {
        this.a := new IObjectArray(ptr)
    }

    __Delete() {
        ObjRelease(this.a.ptr)
    }

    Ptr() {
        Return this.a.ptr
    }

    GetCount() {
        Return this.a.GetCount()
    }

    GetAt(index) {
        obj := this.a.GetAt(index)
        if !obj {
            Return false
        }

        desktop := new VirtualDesktop(obj)
        ObjRelease(obj)
        Return desktop
    }
}
