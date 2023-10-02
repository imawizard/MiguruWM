class TallLayout {
    __New(opts := {}) {
        this._opts := ObjMerge({
            displayName: "Tall",
            masterCountMax: -1,
            flipped: false,
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
        opts := ws._opts
        masterCount := Min(opts.masterCount, ws._tiled.Count)
        slaveCount := ws._tiled.Count - masterCount
        workArea := ws._monitor.WorkArea

        if this._opts.masterCountMax >= 0 {
            masterCount := Min(masterCount, this._opts.masterCountMax)
        }

        usableWidth := workArea.Width
            - opts.padding.left
            - opts.padding.right
        usableHeight := workArea.Height
            - opts.padding.top
            - opts.padding.bottom

        if masterCount >= 1 && slaveCount >= 1 {
            tile := ws._tiled.First
            masterWidth := Round(usableWidth * opts.masterSize)
            slaveWidth := usableWidth - masterWidth

            if !this._opts.flipped {
                counts := [masterCount, slaveCount]
                widths := [masterWidth, slaveWidth]
            } else {
                loop masterCount {
                    tile := tile.next
                }
                counts := [slaveCount, masterCount]
                widths := [slaveWidth, masterWidth]
            }

            next := this._retilePane(
                ws,
                tile,
                counts[1],
                workArea.Left + opts.padding.left,
                workArea.Top + opts.padding.top,
                widths[1] - opts.spacing // 2,
                usableHeight,
            )

            this._retilePane(
                ws,
                next,
                counts[2],
                workArea.Left + opts.padding.left
                    + widths[1] + opts.spacing // 2,
                workArea.Top + opts.padding.top,
                widths[2] - opts.spacing // 2,
                usableHeight,
            )
        } else {
            this._retilePane(
                ws,
                ws._tiled.First,
                masterCount || ws._tiled.Count,
                workArea.Left + opts.padding.left,
                workArea.Top + opts.padding.top,
                usableWidth,
                usableHeight,
            )
        }
    }

    _retilePane(ws, tile, count, x, startY, totalWidth, totalHeight) {
        spacing := ws._opts.spacing > 0 && count > 1
            ? ws._opts.spacing // 2
            : 0
        height := Round((totalHeight - spacing * Max(count - 2, 0)) / count)
        y := startY

        loop count {
            try {
                ws._moveWindow(
                    tile.data,
                    x,
                    y,
                    totalWidth,
                    height - spacing,
                )
            } catch TargetError as err {
                throw WindowError(tile.data, err)
            } catch OSError as err {
                if !DllCall("IsHungAppWindow", "Ptr", tile.data, "Int") {
                    throw WindowError(tile.data, err)
                }
            }
            y += height + spacing
            tile := tile.next
        }
        return tile
    }
}
