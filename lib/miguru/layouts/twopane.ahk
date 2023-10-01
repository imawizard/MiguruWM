class TwoPaneLayout extends TallLayout {
    __New(opts := {}) {
        this._opts := ObjMerge({
            displayName: "Two-Panes",
            flipped: false,
        }, opts)
        this._secondWindow := ""
    }

    ActiveWindowChanged(ws) {
        if ws._mruTile !== ws._tiled.First {
            this._secondWindow := ws._mruTile
            this.Retile(ws)
        }
    }

    Retile(ws) {
        opts := ws._opts
        workArea := ws._monitor.WorkArea

        usableWidth := workArea.Width
            - opts.padding.left
            - opts.padding.right
        usableHeight := workArea.Height
            - opts.padding.top
            - opts.padding.bottom

        if ws._tiled.Count > 1 {
            tile := ws._tiled.First
            masterWidth := Round(usableWidth * opts.masterSize)
            slaveWidth := usableWidth - masterWidth

            if !this._opts.flipped {
                lefts := [0, masterWidth + opts.spacing // 2]
            } else {
                lefts := [slaveWidth + opts.spacing // 2, 0]
            }

            next := this._retilePane(
                ws,
                tile,
                1,
                lefts[1] + workArea.Left + opts.padding.left,
                workArea.Top + opts.padding.top,
                masterWidth - opts.spacing // 2,
                usableHeight,
            )

            while next !== ws._tiled.First {
                if next !== this._secondWindow {
                    this._retilePane(
                        ws,
                        next,
                        1,
                        lefts[2] + workArea.Left + opts.padding.left,
                        workArea.Top + opts.padding.top,
                        slaveWidth - opts.spacing // 2,
                        usableHeight,
                    )
                }
                next := next.next
            }

            if this._secondWindow {
                this._retilePane(
                    ws,
                    this._secondWindow,
                    1,
                    lefts[2] + workArea.Left + opts.padding.left,
                    workArea.Top + opts.padding.top,
                    slaveWidth - opts.spacing // 2,
                    usableHeight,
                )
            }
        } else {
            this._retilePane(
                ws,
                ws._tiled.First,
                1,
                workArea.Left + opts.padding.left,
                workArea.Top + opts.padding.top,
                usableWidth,
                usableHeight,
            )
        }
    }
}
