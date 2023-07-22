class WideLayout {
    __New(opts := {}) {
        this._opts := ObjMerge({
            displayName: "Wide",
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
            masterHeight := Round(usableHeight * opts.masterSize)
            firstSlave := this._retilePane(
                ws,
                ws._tiled.First,
                masterCount,
                workArea.left + opts.padding.left,
                workArea.top + opts.padding.top,
                usableWidth,
                masterHeight - opts.spacing // 2,
            )

            slaveHeight := usableHeight - masterHeight
            this._retilePane(
                ws,
                firstSlave,
                slaveCount,
                workArea.left + opts.padding.left,
                workArea.top + opts.padding.top
                    + masterHeight + opts.spacing // 2,
                usableWidth,
                slaveHeight - opts.spacing // 2,
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

    _retilePane(ws, tile, count, startX, y, totalWidth, totalHeight) {
        spacing := ws._opts.spacing > 0 && count > 1
            ? ws._opts.spacing // 2
            : 0
        width := Round((totalWidth - spacing * Max(count - 2, 0)) / count)
        x := startX

        try {
            Loop count {
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
