class InterfaceWrapper {
    __New(ptr := "") {
        this.wrapped := ""

        if ptr {
            this.Ptr := ptr
        }
    }

    Ptr {
        get => this.wrapped ? this.wrapped.Ptr : 0
        set {
            if !value {
                return
            }

            a := %this.__Class%.Interfaces
            for i, t in a {
                v := t()
                try {
                    ;; v takes ownership of the pointer.
                    v.Ptr := value

                    ;; But only if its Ptr setter didn't return early.
                    if v.Ptr {
                        this.wrapped := v
                        return
                    }
                } catch as err {
                    ;; If it failed, we have to make sure we don't lose the
                    ;; pointer after v is freed.
                    if v.Ptr {
                        ObjAddRef(value)
                    }
                    ;; Swallow every error but E_NOINTERFACE.
                    if !InStr(err.Message, Format("{:x}", E_NOINTERFACE)) {
                        throw
                    }
                }
            }

            msg := "None of these interfaces seem to be supported:`n"
            for t in a {
                msg .= "`t" t.Prototype.__Class " (" t.GUID ")`n"
            }
            throw msg
        }
    }
}
