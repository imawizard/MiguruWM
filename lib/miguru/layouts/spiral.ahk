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
                workArea.left + opts.padding.left,
                workArea.top + opts.padding.top,
                masterWidth - opts.spacing // 2,
                usableHeight,
            )

            slaveWidth := usableWidth - masterWidth
            this._retileSpiralPane(
                ws,
                firstSlave,
                slaveCount,
                workArea.left + opts.padding.left + masterWidth + opts.spacing // 2,
                workArea.top + opts.padding.top,
                slaveWidth - opts.spacing // 2,
                usableHeight,
                "down",
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

    _retileSpiralPane(ws, tile, count, x, y, totalWidth, totalHeight, splitDirection) {
        spacing := ws._opts.spacing > 0 && count > 1
            ? ws._opts.spacing // 2
            : 0
        height := Round((totalHeight - spacing * Max(count - 2, 0)) / count)

        ratio := this._opts.ratio

        get_sub_container(w) {
            x := window[2], y := window[3]
            w := window[4], h := window[5]
            switch window[1] {
            case "right":
                return [
                    "down",
                    x + w + spacing * 2,
                    y,
                    Round(w / ratio),
                    h,
                ]
            case "down":
                return [
                    "left",
                    x,
                    y + h + spacing * 2,
                    w,
                    Round(h / ratio),
                ]
            case "left":
                return [
                    "up",
                    x - spacing * 2 - Round(w / ratio),
                    y,
                    Round(w / ratio),
                    h,
                ]
            case "up":
                return [
                    "right",
                    x,
                    y - spacing * 2 - Round(h / ratio),
                    w,
                    Round(h / ratio),
                ]
            }
        }

        get_first_window_in_container(container) {
            x := container[2], y := container[3]
            w := container[4], h := container[5]
            switch container[1] {
            case "right":
                return [
                    "right",
                    x,
                    y,
                    Round((w - spacing * 2) * ratio / (ratio + 1)),
                    h,
                ]
            case "down":
                return [
                    "down",
                    x,
                    y,
                    w,
                    Round((h - spacing * 2) * ratio / (ratio + 1)),
                ]
            case "left":
                return [
                    "left",
                    x + Round((w - spacing * 2)/(ratio+1)) + spacing*2,
                    y,
                    Round((w - spacing * 2) * ratio / (ratio + 1)),
                    h,
                ]
            case "up":
                return [
                    "up",
                    x,
                    y + Round((h - spacing * 2) / (ratio + 1)) + spacing * 2,
                    w,
                    Round((h - spacing * 2) * ratio / (ratio + 1)),
                ]
            }
        }

        container := [splitDirection, x, y, totalWidth, totalHeight]

        try {
            loop count - 1 {
                window := get_first_window_in_container(container)
                ws._moveWindow(
                    tile.data,
                    window[2],
                    window[3],
                    window[4],
                    window[5],
                )
                container := get_sub_container(window)
                tile := tile.next
            }

            ws._moveWindow(
                tile.data,
                container[2],
                container[3],
                container[4],
                container[5],
            )
        } catch TargetError as err {
            throw WorkspaceList.Workspace.WindowError(tile.data, err)
        } catch OSError as err {
            throw WorkspaceList.Workspace.WindowError(tile.data, err)
        }
        return tile
    }
}
