class RowLayout extends TallLayout {
    __New(opts := {}) {
        opts := ObjMerge({
            displayName: "Rows",
        }, opts)
        super.__New(ObjMerge({
            masterCountMax: 0,
        }, opts))
    }
}
