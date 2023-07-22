class TallLayout {
    __New(opts := {}) {
        this._opts := ObjMerge({
            displayName: "Tall",
            masterCountMax: -1,
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
            masterWidth := Round(usableWidth * opts.masterSize)
            firstSlave := this._retilePane(
                ws,
                ws._tiled.First,
                masterCount,
                workArea.left + opts.padding.left,
                workArea.top + opts.padding.top,
                masterWidth - opts.spacing // 2,
                usableHeight,
            )

            slaveWidth := usableWidth - masterWidth
            this._retilePane(
                ws,
                firstSlave,
                slaveCount,
                workArea.left + opts.padding.left
                    + masterWidth + opts.spacing // 2,
                workArea.top + opts.padding.top,
                slaveWidth - opts.spacing // 2,
                usableHeight,
            )
        } else {
            this._retilePane(
                ws,
                ws._tiled.First,
                masterCount || ws._tiled.Count,
                workArea.left + opts.padding.left,
                workArea.top + opts.padding.top,
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

        try {
            Loop count {
                ws._moveWindow(
                    tile.data,
                    x,
                    y,
                    totalWidth,
                    height - spacing,
                )
                y += height + spacing
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
