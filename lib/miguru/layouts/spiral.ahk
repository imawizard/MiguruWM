SPIRAL_UP    := 1
SPIRAL_DOWN  := 2
SPIRAL_LEFT  := 3
SPIRAL_RIGHT := 4

class SpiralLayout extends TallLayout {
    __New(opts := {}) {
        this._opts := ObjMerge({
            displayName: "Spiral",
            masterCountMax: -1,
            ratio: 1.0,
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
            masterWidth := Round(usableWidth * this._opts.ratio / (this._opts.ratio + 1))
            firstSlave := this._retilePane(
                ws,
                ws._tiled.First,
                masterCount,
                workArea.Left + opts.padding.left,
                workArea.Top + opts.padding.top,
                masterWidth - opts.spacing // 2,
                usableHeight,
            )

            slaveWidth := usableWidth - masterWidth
            this._retileSpiralPane(
                ws,
                firstSlave,
                slaveCount,
                workArea.Left + opts.padding.left + masterWidth + opts.spacing // 2,
                workArea.Top + opts.padding.top,
                slaveWidth - opts.spacing // 2,
                usableHeight,
                SPIRAL_DOWN,
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

    _retileSpiralPane(ws, tile, count, x, y, totalWidth, totalHeight, splitDirection) {
        spacing := ws._opts.spacing > 0 && count > 1
            ? ws._opts.spacing
            : 0
        height := Round((totalHeight - spacing // 2 * Max(count - 2, 0)) / count)

        ratio := this._opts.ratio

        get_sub_container(w) {
            x := window[2], y := window[3]
            w := window[4], h := window[5]
            switch window[1] {
            case SPIRAL_RIGHT:
                return [
                    SPIRAL_DOWN,
                    x + w + spacing,
                    y,
                    Round(w / ratio),
                    h,
                ]
            case SPIRAL_DOWN:
                return [
                    SPIRAL_LEFT,
                    x,
                    y + h + spacing,
                    w,
                    Round(h / ratio),
                ]
            case SPIRAL_LEFT:
                return [
                    SPIRAL_UP,
                    x - spacing - Round(w / ratio),
                    y,
                    Round(w / ratio),
                    h,
                ]
            case SPIRAL_UP:
                return [
                    SPIRAL_RIGHT,
                    x,
                    y - spacing - Round(h / ratio),
                    w,
                    Round(h / ratio),
                ]
            }
        }

        get_first_window_in_container(container) {
            x := container[2], y := container[3]
            w := container[4], h := container[5]
            switch container[1] {
            case SPIRAL_RIGHT:
                return [
                    SPIRAL_RIGHT,
                    x,
                    y,
                    Round((w - spacing) * ratio / (ratio + 1)),
                    h,
                ]
            case SPIRAL_DOWN:
                return [
                    SPIRAL_DOWN,
                    x,
                    y,
                    w,
                    Round((h - spacing) * ratio / (ratio + 1)),
                ]
            case SPIRAL_LEFT:
                return [
                    SPIRAL_LEFT,
                    x + Round((w - spacing) / (ratio + 1)) + spacing,
                    y,
                    Round((w - spacing) * ratio / (ratio + 1)),
                    h,
                ]
            case SPIRAL_UP:
                return [
                    SPIRAL_UP,
                    x,
                    y + Round((h - spacing) / (ratio + 1)) + spacing,
                    w,
                    Round((h - spacing) * ratio / (ratio + 1)),
                ]
            }
        }

        container := [splitDirection, x, y, totalWidth, totalHeight]

        loop count - 1 {
            window := get_first_window_in_container(container)

            try {
                ws._moveWindow(
                    tile.data,
                    window[2],
                    window[3],
                    window[4],
                    window[5],
                )
            } catch TargetError as err {
                throw WindowError(tile.data, err)
            } catch OSError as err {
                if !DllCall("IsHungAppWindow", "Ptr", tile.data, "Int") {
                    throw WindowError(tile.data, err)
                }
            }
            container := get_sub_container(window)
            tile := tile.next
        }

        try {
            ws._moveWindow(
                tile.data,
                container[2],
                container[3],
                container[4],
                container[5],
            )
        } catch TargetError as err {
            throw WindowError(tile.data, err)
        } catch OSError as err {
            if !DllCall("IsHungAppWindow", "Ptr", tile.data, "Int") {
                throw WindowError(tile.data, err)
            }
        }
        return tile
    }
}
