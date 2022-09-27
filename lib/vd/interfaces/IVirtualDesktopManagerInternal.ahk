class IVirtualDesktopManagerInternal_19044 extends IUnknown {
    static GUID    := "{F31574D6-B682-4CDC-BD56-1827860ABEC6}"
    static Methods := [
        "GetCount",
        "MoveViewToDesktop",
        "CanViewMoveDesktops",
        "GetCurrentDesktop",
        "GetDesktops",
        "GetAdjacentDesktop",
        "SwitchDesktop",
        "CreateDesktop",
        "RemoveDesktop",
        "FindDesktop",
    ]

    GetCount() {
        ret := 0
        this._funcs["GetCount"](
            "Int*", &ret,
            "HRESULT",
        )
        return ret
    }

    MoveViewToDesktop(view, desktop) {
        res := this._funcs["MoveViewToDesktop"](
            "Ptr", view,
            "Ptr", desktop,
            "HRESULT",
        )
        switch res {
        case E_NOT_VALID_STATE:
            ; can't move window because e.g. it's a popup/child
        }
        return res == 0
    }

    CanViewMoveDesktops(view) {
        ret := 0
        this._funcs["CanViewMoveDesktops"](
            "Ptr", view,
            "Int*", &ret,
            "HRESULT",
        )
        return ret > 0
    }

    GetCurrentDesktop(out) {
        this._funcs["GetCurrentDesktop"](
            "Ptr*", out,
            "HRESULT",
        )
    }

    GetDesktops(out) {
        this._funcs["GetDesktops"](
            "Ptr*", out,
            "HRESULT",
        )
    }

    GetAdjacentDesktop(out, desktop, direction) {
        res := this._funcs["GetAdjacentDesktop"](
            "Ptr", desktop,
            "Int", direction,
            "Ptr*", out,
            "UInt",
        )
        switch res {
        case E_OUTOFBOUNDS:
            ; there is no desktop on the left/right
        }
    }

    SwitchDesktop(desktop) {
        this._funcs["SwitchDesktop"](
            "Ptr", desktop,
            "HRESULT",
        )
    }

    CreateDesktop(out) {
        this._funcs["CreateDesktop"](
            "Ptr*", out,
            "HRESULT",
        )
    }

    RemoveDesktop(desktop, fallback) {
        this._funcs["RemoveDesktop"](
            "Ptr", desktop,
            "Ptr", fallback,
            "HRESULT",
        )
    }

    FindDesktop(out, desktopId) {
        this._funcs["FindDesktop"](
            "Ptr", desktopId,
            "Ptr*", out,
            "HRESULT",
        )
    }
}

class IVirtualDesktopManagerInternal2_19044 extends IVirtualDesktopManagerInternal_19044 {
    static GUID    := "{0F3A72B0-4566-487E-9A33-4ED302F6D6CE}"
    static Methods := [
        "Unknown1",
        "SetDesktopName",
    ]

    SetDesktopName(desktop, name) {
        str := 0
        DllCall(
            "combase\WindowsCreateString",
            "Str", name,
            "UInt", StrLen(name),
            "Ptr*", &str,
            "HRESULT",
        )
        this._funcs["SetDesktopName"](
            "Ptr", desktop,
            "Ptr", str,
            "HRESULT",
        )
        DllCall(
            "combase\WindowsDeleteString",
            "Ptr", str,
            "HRESULT",
        )
    }
}

class IVirtualDesktopManagerInternal3_19044 extends IVirtualDesktopManagerInternal2_19044 {
    static GUID    := "{FE538FF5-D53B-4F5A-9DAD-8E72873CB360}"
    static Methods := [
        "CopyDesktopState",
    ]

    CopyDesktopState(view1, view2) {
        this._funcs["CopyDesktopState"](
            "Ptr", view1,
            "Ptr", view2,
            "HRESULT",
        )
    }
}

class IVirtualDesktopManagerInternal_22000 extends IVirtualDesktopManagerInternal_19044 {
    static GUID    := "{B2F925B9-5A0F-4D2E-9F4D-2B1507593C10}"
    static Methods := [
        "MoveDesktop",
        "RemoveDesktop",
        "FindDesktop",
    ]

    Ptr {
        set {
            ; Build 22000 and 22489 seem to be using the same guid, so check
            ; here explicitely, based on the build number
            build := StrSplit(A_OSVersion, ".")[3]
            if build < 22489 {
                super.Ptr := value
            }
        }
    }

    GetCurrentDesktop(out) {
        this._funcs["GetCurrentDesktop"](
            "Ptr", 0,
            "Ptr*", out,
            "HRESULT",
        )
    }

    GetDesktops(out) {
        this._funcs["GetDesktops"](
            "Ptr", 0,
            "Ptr*", out,
            "HRESULT",
        )
    }

    SwitchDesktop(desktop) {
        this._funcs["SwitchDesktop"](
            "Ptr", 0,
            "Ptr", desktop
            "HRESULT",
        )
    }

    CreateDesktop(out) {
        this._funcs["CreateDesktop"](
            "Ptr", 0,
            "Ptr*", out,
            "HRESULT",
        )
    }

    MoveDesktop(desktop, handle, index) {
        this._funcs["MoveDesktop"](
            "Ptr", desktop,
            "Ptr", handle,
            "Int", index,
            "HRESULT",
        )
    }
}

class IVirtualDesktopManagerInternal_22489 extends IVirtualDesktopManagerInternal_22000 {
    static GUID    := "{B2F925B9-5A0F-4D2E-9F4D-2B1507593C10}"
    static Methods := [
        "GetAllCurrentDesktops",
        "GetDesktops",
        "GetAdjacentDesktop",
        "SwitchDesktop",
        "CreateDesktop",
        "MoveDesktop",
        "RemoveDesktop",
        "FindDesktop",
    ]

    Ptr {
        set {
            ; Build 22000 and 22489 seem to be using the same guid, so check
            ; here explicitely, based on the build number
            build := StrSplit(A_OSVersion, ".")[3]
            if build >= 22489 {
                super.Ptr := value
            }
        }
    }

    GetAllCurrentDesktops(out) {
        this._funcs["GetAllCurrentDesktops"](
            "Ptr*", out,
            "HRESULT",
        )
    }
}
