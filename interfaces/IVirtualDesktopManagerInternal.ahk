class IVirtualDesktopManagerInternal_19044 {
    __New(obj) {
        this.ptr := ComObjQuery(obj, "{F31574D6-B682-4CDC-BD56-1827860ABEC6}")
        if this.ptr {
            this.methods := MethodTable(this.ptr
                , "GetCount"
                , "MoveViewToDesktop"
                , "CanViewMoveDesktops"
                , "GetCurrentDesktop"
                , "GetDesktops"
                , "GetAdjacentDesktop"
                , "SwitchDesktop"
                , "CreateDesktop"
                , "RemoveDesktop"
                , "FindDesktop")
        }
    }

    GetCount() {
        ret := 0
        if DllCall(this.methods["GetCount"]
            , "Ptr", this.ptr
            , "IntP", ret
            , "UInt") {
            Return -1
        }
        Return ret
    }

    MoveViewToDesktop(view, desktop) {
        Return DllCall(this.methods["MoveViewToDesktop"]
            , "Ptr", this.ptr
            , "Ptr", view
            , "Ptr", desktop
            , "UInt") == 0
    }

    CanViewMoveDesktops(view) {
        ret := 0
        DllCall(this.methods["CanViewMoveDesktops"]
            , "Ptr", this.ptr
            , "Ptr", view
            , "IntP", ret
            , "UInt")
        Return ret > 0
    }

    GetCurrentDesktop() {
        desktop := false
        DllCall(this.methods["GetCurrentDesktop"]
            , "Ptr", this.ptr
            , "PtrP", desktop
            , "UInt")
        Return desktop
    }

    GetDesktops() {
        desktops := false
        DllCall(this.methods["GetDesktops"]
            , "Ptr", this.ptr
            , "PtrP", desktops
            , "UInt")
        Return desktops
    }

    GetAdjacentDesktop(desktop, direction) {
        if (direction == "left") {
            direction := 3
        } else if (direction == "right") {
            direction := 4
        }
        found := false
        DllCall(this.methods["GetAdjacentDesktop"]
            , "Ptr", this.ptr
            , "Ptr", desktop
            , "Int", direction
            , "PtrP", found
            , "UInt")
        Return found
    }

    SwitchDesktop(desktop) {
        Return DllCall(this.methods["SwitchDesktop"]
            , "Ptr", this.ptr
            , "Ptr", desktop
            , "UInt") == 0
    }

    CreateDesktop() {
        desktop := false
        DllCall(this.methods["CreateDesktop"]
            , "Ptr", this.ptr
            , "PtrP", desktop
            , "UInt")
        Return desktop
    }

    RemoveDesktop(desktop, fallback) {
        Return DllCall(this.methods["RemoveDesktop"]
            , "Ptr", this.ptr
            , "Ptr", desktop
            , "Ptr", fallback
            , "UInt") == 0
    }

    FindDesktop(desktopId) {
        desktop := false
        DllCall(this.methods["FindDesktop"]
            , "Ptr", this.ptr
            , "Ptr", desktopId
            , "PtrP", desktop
            , "UInt")
        Return desktop
    }
}

class IVirtualDesktopManagerInternal2_19044 extends IVirtualDesktopManagerInternal_19044 {
    __New(obj) {
        this.ptr := ComObjQuery(obj, "{0F3A72B0-4566-487E-9A33-4ED302F6D6CE}")
        if this.ptr {
            this.methods := MethodTable(this.ptr
                , "GetCount"
                , "MoveViewToDesktop"
                , "CanViewMoveDesktops"
                , "GetCurrentDesktop"
                , "GetDesktops"
                , "GetAdjacentDesktop"
                , "SwitchDesktop"
                , "CreateDesktop"
                , "RemoveDesktop"
                , "FindDesktop"
                , "SetName")
        }
    }

    SetName(desktop, name) {
        str := 0
        DllCall("combase\WindowsCreateString"
            , "Str", name
            , "UInt", StrLen(name)
            , "PtrP", str
            , "UInt")
        ret := DllCall(this.methods["SetName"]
            , "Ptr", this.ptr
            , "Ptr", desktop
            , "Ptr", str
            , "UInt")
        DllCall("combase\WindowsDeleteString"
            , "Ptr", str
            , "UInt")
        Return ret == 0
    }
}

class IVirtualDesktopManagerInternal3_19044 extends IVirtualDesktopManagerInternal2_19044 {
    __New(obj) {
        this.ptr := ComObjQuery(obj, "{FE538FF5-D53B-4F5A-9DAD-8E72873CB360}")
        if this.ptr {
            this.methods := MethodTable(this.ptr
                , "GetCount"
                , "MoveViewToDesktop"
                , "CanViewMoveDesktops"
                , "GetCurrentDesktop"
                , "GetDesktops"
                , "GetAdjacentDesktop"
                , "SwitchDesktop"
                , "CreateDesktop"
                , "RemoveDesktop"
                , "FindDesktop"
                , "SetName"
                , "CopyDesktopState")
        }
    }

    CopyDesktopState(view1, view2) {
        Return DllCall(this.methods["CopyDesktopState"]
            , "Ptr", this.ptr
            , "Ptr", view1
            , "Ptr", view2
            , "UInt") == 0
    }
}

class IVirtualDesktopManagerInternal_22000 extends IVirtualDesktopManagerInternal_19044 {
    __New(obj) {
        this.ptr := ComObjQuery(obj, "{B2F925B9-5A0F-4D2E-9F4D-2B1507593C10}")
        if this.ptr {
            this.methods := MethodTable(this.ptr
                , "GetCount"
                , "MoveViewToDesktop"
                , "CanViewMoveDesktops"
                , "GetCurrentDesktop"
                , "GetDesktops"
                , "GetAdjacentDesktop"
                , "SwitchDesktop"
                , "CreateDesktop"
                , "MoveDesktop"
                , "RemoveDesktop"
                , "FindDesktop")
        }
    }

    GetCurrentDesktop() {
        desktop := false
        DllCall(this.methods["GetCurrentDesktop"]
            , "Ptr", this.ptr
            , "Ptr", 0
            , "PtrP", desktop
            , "UInt")
        Return desktop
    }

    GetDesktops() {
        desktops := false
        DllCall(this.methods["GetDesktops"]
            , "Ptr", this.ptr
            , "Ptr", 0
            , "PtrP", desktops
            , "UInt")
        Return desktops
    }

    SwitchDesktop(desktop) {
        Return DllCall(this.methods["SwitchDesktop"]
            , "Ptr", this.ptr
            , "Ptr", 0
            , "Ptr", desktop
            , "UInt") == 0
    }

    CreateDesktop() {
        desktop := false
        DllCall(this.methods["CreateDesktop"]
            , "Ptr", this.ptr
            , "Ptr", 0
            , "PtrP", desktop
            , "UInt")
        Return desktop
    }

    MoveDesktop(desktop, handle, index) {
        Return DllCall(this.methods["MoveDesktop"]
            , "Ptr", this.ptr
            , "Ptr", desktop
            , "Ptr", handle
            , "Int", index
            , "UInt") == 0
    }
}

class IVirtualDesktopManagerInternal_22489 extends IVirtualDesktopManagerInternal_22000 {
    __New(obj) {
        this.ptr := ComObjQuery(obj, "{B2F925B9-5A0F-4D2E-9F4D-2B1507593C10}")
        if this.ptr {
            this.methods := MethodTable(this.ptr
                , "GetCount"
                , "MoveViewToDesktop"
                , "CanViewMoveDesktops"
                , "GetCurrentDesktop"
                , "GetAllCurrentDesktops"
                , "GetDesktops"
                , "GetAdjacentDesktop"
                , "SwitchDesktop"
                , "CreateDesktop"
                , "MoveDesktop"
                , "RemoveDesktop"
                , "FindDesktop")
        }
    }

    GetAllCurrentDesktops() {
        desktops := false
        DllCall(this.methods["GetAllCurrentDesktops"]
            , "Ptr", this.ptr
            , "PtrP", desktops
            , "UInt")
        Return desktops
    }
}
