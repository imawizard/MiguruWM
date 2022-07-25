class ComObject {
    __New(guids, methods) {
        this.vtable := AllocMethodTable(this, methods*)

        this.ptr := DllCall("GlobalAlloc"
            , "UInt", GMEM_ZEROINIT
            , "UInt", A_PtrSize
            , "Ptr")

        NumPut(this.vtable, this.ptr+0, , "Ptr")

        this.supportedGUIDs := [ParseGUID(IID_Unknown)]
        for i, guid in guids {
            if guid {
                this.supportedGUIDs.Push(ParseGUID(guid))
            }
        }
    }

    __Delete() {
        FreeMethodTable(this.vtable)
        for i, guid in this.supportedGUIDs {
            DllCall("GlobalFree"
                , "Ptr", guid
                , "Int")
        }
        DllCall("GlobalFree"
            , "Ptr", this.ptr
            , "Int")
    }

    QueryInterface(iid, out) {
        this := Object(A_EventInfo)

        if !out {
            Return E_INVALIDARG
        }

        for i, guid in this.supportedGUIDs {
            if DllCall("ole32\IsEqualGUID"
                , "Ptr", iid
                , "Ptr", guid) {
                NumPut(this.ptr, out + 0, "Ptr")
                this.AddRef()
                Return 0
            }
        }

        NumPut(0, out + 0, "Ptr")
        Return E_NOINTERFACE
    }

    AddRef() {
        this := Object(A_EventInfo)
        Return ObjAddRef(&this)
    }

    Release() {
        this := Object(A_EventInfo)
        Return ObjRelease(&this)
    }
}
