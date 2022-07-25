Global GMEM_ZEROINIT := 0x40
Global E_INVALIDARG  := 0x80070057
Global E_NOINTERFACE := 0x80004002

Global IID_Unknown          := "{00000000-0000-0000-C000-000000000046}"
Global IID_ObjectArray      := "{92CA9DCD-5622-4BBA-A805-5E9F541BD8C9}"
Global IID_ServiceProvider  := "{6D5140C1-7436-11CE-8034-00AA006009FA}"

CreateFromCLSIDs(clsids*) {
    oldErrlvl := ComObjError()
    ComObjError(false)

    ptr := false
    for i, clsid in clsids {
        if ptr {
            Break
        } else if !clsid {
            Continue
        }
        ptr := ComObjCreate(clsid, IID_Unknown)
    }

    ComObjError(oldErrlvl)
    Return ptr
}

CreateFromSIDs(obj, sids*) {
    oldErrlvl := ComObjError()
    ComObjError(false)

    ptr := false
    for i, sid in sids {
        if ptr {
            Break
        } else if !sid {
            Continue
        }
        ptr := ComObjQuery(obj, sid, IID_Unknown)
    }

    ComObjError(oldErrlvl)
    Return ptr
}

ConstructInterface(obj, classes*) {
    oldErrlvl := ComObjError()
    ComObjError(false)

    interface := false
    for i, constructor in classes {
        if interface.ptr {
            Break
        } else if !constructor {
            Continue
        }
        interface := new constructor(obj)
    }

    ComObjError(oldErrlvl)
    Return interface.ptr ? interface : false
}

MethodTable(ptr, names*) {
    filtered := ["QueryInterface", "AddRef", "Release"]
    for i, name in names {
        if name {
            filtered.Push(name)
        }
    }
    table := {}
    for i, name in filtered {
        table[name] := NumGet(NumGet(ptr + 0) + A_PtrSize * (i - 1))
    }
    Return table
}

AllocMethodTable(obj, names*) {
    filtered := ["QueryInterface", "AddRef", "Release"]
    for i, name in names {
        if name {
            filtered.Push(name)
        }
    }

    vtable := DllCall("GlobalAlloc"
        , "UInt", GMEM_ZEROINIT
        , "UInt", (filtered.Length() + 1) * A_PtrSize
        , "Ptr")

    for i, name in filtered {
        callback := RegisterCallback(obj[name], , , &obj)
        NumPut(callback, vtable+0, (i - 1) * A_PtrSize)
    }
    Return vtable
}

FreeMethodTable(table) {
    offset := 0
    Loop {
        callback := NumGet(table + 0, offset, "Ptr")
        if !callback {
            Break
        }
        DllCall("GlobalFree"
            , "Ptr", callback
            , "Int")
        offset += A_PtrSize
    }
    DllCall("GlobalFree"
        , "Ptr", table
        , "Int")
}

ParseGUID(stringified) {
    guid := DllCall("GlobalAlloc"
        , "UInt", 0
        , "UInt", 16
        , "Ptr")
    DllCall("ole32.dll\CLSIDFromString"
        , "Str", stringified
        , "Ptr", guid
        , "UInt")
    Return guid
}

StringifyGUID(guid) {
    len := StrLen("{________-____-____-____-____________}") + 1
    VarSetCapacity(stringified, len * 2)
    DllCall("ole32.dll\StringFromGUID2"
        , "Ptr", guid
        , "Ptr", &stringified
        , "Int", len * 2)
    Return StrGet(&stringified, "UTF-16")
}
