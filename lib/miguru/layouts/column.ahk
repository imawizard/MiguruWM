class ColumnLayout extends WideLayout {
    __New(opts := {}) {
        opts := ObjMerge({
            displayName: "Columns",
        }, opts)
        super.__New(ObjMerge({
            masterCountMax: 0,
        }, opts))
    }
}
