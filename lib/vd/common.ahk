ParseGUID(stringified) {
    guid := Buffer(16)
    DllCall(
        "ole32.dll\CLSIDFromString",
        "Str", stringified,
        "Ptr", guid,
        "HRESULT",
    )
    return guid
}

StringifyGUID(guid) {
    ptr := 0
    if guid is Integer {
        ptr := guid
    } else if guid is String {
        ptr := StrPtr(guid)
    } else if guid is Buffer {
        ptr := guid.Ptr
    } else {
        return ""
    }

    len := StrLen("{________-____-____-____-____________}") + 1
    VarSetStrCapacity(&stringified, len)
    DllCall(
        "ole32.dll\StringFromGUID2",
        "Ptr", ptr,
        "Ptr", StrPtr(stringified),
        "Int", len,
        "Int",
    )
    return StrGet(StrPtr(stringified))
}
