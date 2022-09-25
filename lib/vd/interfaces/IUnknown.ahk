VT_UNKNOWN := 13

class IUnknown {
    Static GUID    := "{00000000-0000-0000-C000-000000000046}"
    Static Methods := [
        "QueryInterface",
        "AddRef",
        "Release",
    ]

    __New() {
        this._value := ComValue(VT_UNKNOWN, 0)
    }

    Ptr {
        get => this._value.Ptr
        set {
            if value == 0 {
                Return
            }

            ; Take ownership of the interface pointer
            this._value.Ptr := value

            classes := []
            proto := this.Base
            while proto && proto !== IUnknown.Base.Prototype {
                classes.Push(%proto.__Class%)
                proto := proto.Base
            }

            guid := ""
            methods := []
            loop classes.Length {
                c := classes[-A_Index]
                if c.HasOwnProp("GUID") {
                    guid := c.GUID
                }
                if c.HasOwnProp("Methods") {
                    methods.Push(c.Methods*)
                }
            }

            ; Filter dupes in methods
            filtered := []
            uniq := Map()
            loop methods.Length {
                i := methods.Length - A_Index + 1
                m := methods[i]
                if !uniq.Has(m) {
                    uniq[m] := i
                }
            }
            for i, m in methods {
                if (i == uniq[m]) {
                    filtered.Push(m)
                }
            }

            if guid && guid !== IUnknown.GUID {
                ; Might throw an error
                this._value := ComObjQuery(value, guid)
            }

            this._funcs := Map()
            for i, name in filtered {
                this._funcs[name] := ComCall.Bind(i - 1, this)
            }
        }
    }

    Static FromCLSID(out, clsids*) {
        cv := ""
        for i, clsid in clsids {
            try {
                cv := ComObject(clsid, IUnknown.GUID)
                Break
            } catch as err {
                if !InStr(err.Message, Format("{:x}", E_CLASSNOTREG)) {
                    Throw Error(err.Message ": " clsid, err.What, err.Extra)
                }
            }
        }
        if !cv {
            msg := "None of these CLSIDs was found:"
            for clsid in clsids {
                msg .= "`n`t" clsid
            }
            Throw msg
        }
        ObjAddRef(out.Ptr := cv.Ptr)
    }

    Static FromSID(out, obj, sids*) {
        cv := ""
        for i, sid in sids {
            try {
                cv := ComObjQuery(obj, sid, IUnknown.GUID)
                Break
            } catch as err {
                if !InStr(err.Message, Format("{:x}", E_NOTIMPL)) {
                    Throw Error(err.Message ": " sid, err.What, err.Extra)
                }
            }
        }
        if !cv {
            msg := "None of these services is implemented:"
            for sid in sids {
                msg .= "`n`t" sid
            }
            Throw msg
        }
        ObjAddRef(out.Ptr := cv.Ptr)
    }
}
