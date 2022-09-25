class IVirtualDesktopManagerInternal_19044 extends IUnknown {
    Static GUID    := "{F31574D6-B682-4CDC-BD56-1827860ABEC6}"
    Static Methods := [
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
            "IntP", &ret,
            "HRESULT",
        )
        Return ret
    }

    MoveViewToDesktop(view, desktop) {
        res := this._funcs["MoveViewToDesktop"](
            "Ptr", view,
            "Ptr", desktop,
            "HRESULT",
        )
        Switch res {
        Case E_NOT_VALID_STATE:
            ; can't move window because e.g. it's a popup/child
        }
        Return res == 0
    }

    CanViewMoveDesktops(view) {
        ret := 0
        this._funcs["CanViewMoveDesktops"](
            "Ptr", view,
            "IntP", &ret,
            "HRESULT",
        )
        Return ret > 0
    }

    GetCurrentDesktop(out) {
        this._funcs["GetCurrentDesktop"](
            "PtrP", out,
            "HRESULT",
        )
    }

    GetDesktops(out) {
        this._funcs["GetDesktops"](
            "PtrP", out,
            "HRESULT",
        )
    }

    GetAdjacentDesktop(out, desktop, direction) {
        res := this._funcs["GetAdjacentDesktop"](
            "Ptr", desktop,
            "Int", direction,
            "PtrP", out,
            "UInt",
        )
        Switch res {
        Case E_OUTOFBOUNDS:
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
            "PtrP", out,
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
            "PtrP", out,
            "HRESULT",
        )
    }
}

class IVirtualDesktopManagerInternal2_19044 extends IVirtualDesktopManagerInternal_19044 {
    Static GUID    := "{0F3A72B0-4566-487E-9A33-4ED302F6D6CE}"
    Static Methods := [
        "Unknown1",
        "SetDesktopName",
    ]

    SetDesktopName(desktop, name) {
        str := 0
        DllCall(
            "combase\WindowsCreateString",
            "Str", name,
            "UInt", StrLen(name),
            "PtrP", &str,
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
    Static GUID    := "{FE538FF5-D53B-4F5A-9DAD-8E72873CB360}"
    Static Methods := [
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
    Static GUID    := "{B2F925B9-5A0F-4D2E-9F4D-2B1507593C10}"
    Static Methods := [
        "MoveDesktop",
        "RemoveDesktop",
        "FindDesktop",
    ]

    Ptr {
        set {
            ; Build 22000 and 22489 seem to be using the same guid, so check
            ; here explicitely, based on the build number
            build := StrSplit(A_OSVersion, ".")[3]
            if (build < 22489) {
                super.Ptr := value
            }
        }
    }

    GetCurrentDesktop(out) {
        this._funcs["GetCurrentDesktop"](
            "Ptr", 0,
            "PtrP", out,
            "HRESULT",
        )
    }

    GetDesktops(out) {
        this._funcs["GetDesktops"](
            "Ptr", 0,
            "PtrP", out,
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
            "PtrP", out,
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
    Static GUID    := "{B2F925B9-5A0F-4D2E-9F4D-2B1507593C10}"
    Static Methods := [
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
            if (build >= 22489) {
                super.Ptr := value
            }
        }
    }

    GetAllCurrentDesktops(out) {
        this._funcs["GetAllCurrentDesktops"](
            "PtrP", out,
            "HRESULT",
        )
    }
}
