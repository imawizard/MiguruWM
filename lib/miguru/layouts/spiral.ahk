class SpiralLayout {
    __New(opts := {}) {
        this._opts := ObjMerge({
            displayName: "Spiral",
            masterCountMax: -1,
            ratio: 1.0
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
            ; currently, masterSize will be ignored
            masterWidth := Round((usableWIdth - ws._opts.spacing)* this._opts.ratio / (this._opts.ratio+1))
            firstSlave := this._tallRetilePane(
                ws,
                ws._tiled.First,
                masterCount,
                workArea.left + opts.padding.left,
                workArea.top + opts.padding.top,
                masterWidth - opts.spacing // 2,
                usableHeight,
            )
            slaveWidth := usableWidth - masterWidth
            this._spiralRetilePane(
                ws,
                firstSlave,
                slaveCount,
                workArea.left + opts.padding.left + masterWidth + opts.spacing // 2,
                workArea.top + opts.padding.top,
                slaveWidth - opts.spacing // 2,
                usableHeight,
                "down"
            )
        } else {
            this._tallRetilePane(
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

    _spiralRetilePane(ws, tile, count, x, y, totalWidth, totalHeight, splitDirection){
        spacing := ws._opts.spacing > 0 && count > 1
            ? ws._opts.spacing // 2
            : 0
        height := Round((totalHeight - spacing * Max(count - 2, 0)) / count)
        ratio := this._opts.ratio

        get_sub_container(cur_window){
            dir := cur_window[1]
            x := cur_window[2], y := cur_window[3]
            w := cur_window[4], h := cur_window[5]
            if dir=="right"
                return ["down", x + w + spacing * 2, y, Round(w/ratio), h]
            if dir=="down"
                return ["left", x, y + h + spacing * 2, w, Round(h/ratio)]
            if dir=="left"
                return ["up"  , x - spacing * 2 - Round(w/ratio), y, Round(w/ratio), h]
            if dir=="up"
                return ["right",x, y - spacing * 2 - Round(h/ratio) , w, Round(h/ratio)]
        }

        get_first_window_in_container(cur_container){
            dir := cur_container[1]
            x := cur_container[2], y := cur_container[3]
            w := cur_container[4], h := cur_container[5]
            if dir=="right"
                return ["right", x, y, Round((w-spacing*2)*ratio/(ratio+1)), h]
            if dir=="down"
                return ["down" , x, y, w, Round((h-spacing*2)*ratio/(ratio+1))]
            if dir=="left"
                return ["left" , x + Round((w-spacing*2)/(ratio+1)) + spacing*2, y, Round((w-spacing*2)*ratio/(ratio+1)), h]
            if dir=="up"
                return ["up"   , x, y + Round((h-spacing*2)/(ratio+1)) + spacing*2, w, Round((h-spacing*2)*ratio/(ratio+1))]
        }

        cur_container := [splitDirection,x,y,totalWidth,totalHeight]

        try {
        Loop count {
                cur_window := get_first_window_in_container(cur_container)
                cur_x := (A_Index == count) ? cur_container[2] : cur_window[2]
                cur_y := (A_Index == count) ? cur_container[3] : cur_window[3]
                cur_w := (A_Index == count) ? cur_container[4] : cur_window[4]
                cur_h := (A_Index == count) ? cur_container[5] : cur_window[5]
                ws._moveWindow(
                    tile.data,
                    cur_x,
                    cur_y,
                    cur_w,
                    cur_h,
                )
                tile := tile.next
                cur_container := get_sub_container(cur_window)
            }
        } catch TargetError as err {
            throw WorkspaceList.Workspace.WindowError(tile.data, err)
        } catch OSError as err {
            throw WorkspaceList.Workspace.WindowError(tile.data, err)
        }
        return tile
    }

    _tallRetilePane(ws, tile, count, x, startY, totalWidth, totalHeight) {
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
