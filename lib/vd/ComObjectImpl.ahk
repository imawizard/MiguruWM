E_NOTIMPL         := 0x80004001
E_NOINTERFACE     := 0x80004002
E_ELEMENTNOTFOUND := 0x8002802b
E_OUTOFBOUNDS     := 0x80028ca1
E_CLASSNOTREG     := 0x80040154
E_INVALIDARG      := 0x80070057
E_NOT_VALID_STATE := 0x8007139f

class ComObjectImpl {
    __New() {
        this._buf := this._createVTable()
        this._vtables := Map(IUnknown.GUID, this._buf)

        for k, v in %this.base.__Class%.VTables {
            if v is Array {
                this._vtables[StrUpper(k)] := this._createVTable(v*)
            }
        }
        for k, v in %this.base.__Class%.VTables {
            if v is String {
                this._vtables[StrUpper(k)] := this._vtables[v]
            }
        }
    }

    __Delete() {
        for _, v in this._vtables {
            loop v.Size // A_PtrSize {
                A_Index += A_PtrSize - 1
                callback := NumGet(v.Ptr, A_Index, "Ptr")
                if callback {
                    CallbackFree(callback)
                    NumPut("Ptr", 0, v.Ptr, A_Index)
                }
            }
        }
    }

    _createVTable(methods*) {
        methods := ["QueryInterface", "AddRef", "Release", methods*]

        vtable := Buffer((methods.Length + 2) * A_PtrSize)
        NumPut("Ptr", vtable.Ptr + A_PtrSize, vtable)
        NumPut("Ptr", 0, vtable, (methods.Length + 1) * A_PtrSize)

        for i, name in methods {
            ;; Bind `method` instead of closing over it, because we're in a loop.
            method := this.%name%
            ;; Bind `this` without incrementing its reference counter.
            self := ObjPtr(this)

            callback := CallbackCreate(
                ;; Transparently skip the COM object's `thisptr` and restore
                ;; the AHK object's `this` (by using ObjFromPtrAddRef which
                ;; also increments the object's reference counter, so it's not
                ;; freed afterwards as ObjFromPtr* actually takes ownership).
                ((fn, self, thisptr, args*) =>
                    fn.Call(ObjFromPtrAddRef(self), args*))
                .Bind(method, self),
                "F", ; XXX: Is `fast` safe here?
                method.MinParams,
            )
            NumPut("Ptr", callback, vtable, i * A_PtrSize)
        }
        return vtable
    }

    Ptr {
        get => this._buf.Ptr
    }

    QueryInterface(iid, out) {
        if !out {
            return E_INVALIDARG
        }

        guid := StrUpper(StringifyGUID(iid))
        for k, v in this._vtables {
            if guid == k {
                NumPut("Ptr", v.Ptr, out)
                this.AddRef()
                return 0
            }
        }

        NumPut("Ptr", 0, out)
        return E_NOINTERFACE
    }

    AddRef() {
        return ObjAddRef(ObjPtr(this))
    }

    Release() {
        return ObjRelease(ObjPtr(this))
    }
}
