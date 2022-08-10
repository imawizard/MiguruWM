class IVirtualDesktopManager_19044 {
    __New(obj) {
        this.ptr := ComObjQuery(obj, "{A5CD92FF-29BE-454C-8D04-D82879FB3F1B}")
        if this.ptr {
            this.methods := MethodTable(this.ptr
                , "IsWindowOnCurrentVirtualDesktop"
                , "GetWindowDesktopId"
                , "MoveWindowToDesktop")
        }
    }

    IsWindowOnCurrentVirtualDesktop(hwnd) {
        ret := 0
        DllCall(this.methods["IsWindowOnCurrentVirtualDesktop"]
            , "Ptr", this.ptr
            , "Ptr", hwnd
            , "IntP", ret
            , "UInt")
        Return ret > 0
    }

    GetWindowDesktopId(hwnd) {
        VarSetCapacity(desktopId, 16)
        if DllCall(this.methods["GetWindowDesktopId"]
            , "Ptr", this.ptr
            , "Ptr", hwnd
            , "Ptr", &desktopId
            , "UInt") {
            Return false
        }
        Return desktopId
    }

    MoveWindowToDesktop(desktopId, hwnd) {
        Return DllCall(this.methods["MoveWindowToDesktop"]
            , "Ptr", this.ptr
            , "Ptr", hwnd
            , "Ptr", desktopId
            , "UInt") == 0
    }
}
