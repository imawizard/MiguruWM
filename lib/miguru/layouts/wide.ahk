class WideLayout {
    __New(opts := {}) {
        this._opts := ObjMerge({
            displayName: "Wide",
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
            masterHeight := Round(usableHeight * opts.masterSize)
            slaveHeight := usableHeight - masterHeight

            if !this._opts.flipped {
                counts := [masterCount, slaveCount]
                heights := [masterHeight, slaveHeight]
            } else {
                loop masterCount {
                    tile := tile.next
                }
                counts := [slaveCount, masterCount]
                heights := [slaveHeight, masterHeight]
            }

            next := this._retilePane(
                ws,
                tile,
                counts[1],
                workArea.Left + opts.padding.left,
                workArea.Top + opts.padding.top,
                usableWidth,
                heights[1] - opts.spacing // 2,
            )
            this._retilePane(
                ws,
                next,
                counts[2],
                workArea.Left + opts.padding.left,
                workArea.Top + opts.padding.top
                    + masterHeight + opts.spacing // 2,
                usableWidth,
                heights[2] - opts.spacing // 2,
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

    _retilePane(ws, tile, count, startX, y, totalWidth, totalHeight) {
        spacing := ws._opts.spacing > 0 && count > 1
            ? ws._opts.spacing // 2
            : 0
        width := Round((totalWidth - spacing * Max(count - 2, 0)) / count)
        x := startX

        try {
            loop count {
                ws._moveWindow(
                    tile.data,
                    x,
                    y,
                    width - spacing,
                    totalHeight,
                )
                x += width + spacing
                tile := tile.next
            }
        } catch TargetError as err {
            throw WindowError(tile.data, err)
        } catch OSError as err {
            throw WindowError(tile.data, err)
        }
        return tile
    }
}
