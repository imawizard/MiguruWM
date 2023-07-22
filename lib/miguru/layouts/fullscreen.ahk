class FullscreenLayout {
    __New(opts := {}) {
        this._opts := ObjMerge({
            displayName: "Fullscreen",
            nativeMaximize: false,
        }, opts)
    }

    DisplayName {
        get => this._opts.displayName
    }

    ActiveWindowChanged(ws) {
        this.Retile(ws)
    }

    Init(ws) {
        first := ws._tiled.First
        current := first
        loop {
            this._resizeWindow(ws, current.data)
            current := current.next
        } until current == first
    }

    Retile(ws) {
        if ws._mruTile {
            hwnd := ws._mruTile.data

            if !this._opts.nativeMaximize {
                this._resizeWindow(ws, hwnd)
            } else {
                WinMaximize("ahk_id" hwnd)
            }

            ;; Move window to the foreground, even in front of possible
            ;; siblings.
            try {
                WinSetAlwaysOnTop(true, "ahk_id" hwnd)
                WinSetAlwaysOnTop(false, "ahk_id" hwnd)
            }
        }
    }

    _resizeWindow(ws, hwnd) {
        opts := ws._opts
        workArea := ws._monitor.WorkArea

        try {
            ws._moveWindow(
                hwnd,
                workArea.left + opts.padding.left,
                workArea.top + opts.padding.top,
                workArea.Width - opts.padding.left - opts.padding.right,
                workArea.Height - opts.padding.top - opts.padding.bottom,
            )
        } catch TargetError as err {
            throw WindowError(hwnd, err)
        } catch OSError as err {
            throw WindowError(hwnd, err)
        }
    }
}
