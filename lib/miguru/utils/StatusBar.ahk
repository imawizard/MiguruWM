class StatusBar {
    __New(opts := {}) {
        opts := ObjMerge({
            color: "0x080808",
        }, opts)
    }

    __Delete() {
    }

    MonitorChanged(idx) {
        this._monitorIdx := idx
        this._update()
    }

    MonitorCountChanged(count) {
        this._monitorCount := count
        this._update()
    }

    WorkspaceChanged(idx) {
        this._wsIdx := idx
        this._update()
    }

    WorkspaceCountChanged(count) {
        this._wsCount := count
        this._update()
    }

    LayoutChanged(layout) {
        this._layout := layout
        ;; Do nothing
    }

    _update() {
    }
}
