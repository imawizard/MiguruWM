class FloatingLayout {
    __New(opts := {}) {
        this._opts := ObjMerge({
            displayName: "Floating",
        }, opts)
    }

    DisplayName {
        get => this._opts.displayName
    }

    ActiveWindowChanged(ws) {
        ;; Do nothing
    }

    Init(ws) {
        ;; Do nothing
    }

    Retile(ws) {
        ;; Do nothing
    }
}
