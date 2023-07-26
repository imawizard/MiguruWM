class ThreeColumnsLayout {
    __New(opts := {}) {
        this._opts := ObjMerge({
            displayName: "Three Columns",
            masterPos: "mid",
            masterCountMax: -1,
            masterExtraSize: 1.3,
            slaveReverse: false
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
            masterWidth := Round(usableWidth * opts.masterSize * this._opts.masterExtraSize)
            slaveWidth := usableWidth - masterWidth
            if slaveCount == 1 {
                this.retileTwoWindows(ws, masterWidth, slaveWidth, usableWidth, usableHeight)
            } else{
                this.retileMoreThanTwo(ws, masterWidth, slaveWidth, usableWidth, usableHeight)
            }
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


    _threeColumnsRetilePane(ws, tile, count, colFirst_x, colFirst_y, colSecond_x, colSecond_y, totalWidth, totalHeight) {
        spacing := ws._opts.spacing > 0 && count > 1
            ? ws._opts.spacing // 2
            : 0

        colFirst_slave_num := Integer(count/2)
        colSecond_slave_num := count - colFirst_slave_num

        colSecond_spacing := ws._opts.spacing > 0 && colSecond_slave_num > 1
            ? ws._opts.spacing // 2
            : 0
        colFirst_spacing  := ws._opts.spacing > 0 && colFirst_slave_num > 1
            ? ws._opts.spacing // 2
            : 0

        colSecond_height := Round((totalHeight - colSecond_spacing * Max(colSecond_slave_num - 2, 0)) / colSecond_slave_num)
        colFirst_height := Round((totalHeight - colFirst_spacing * Max(colFirst_slave_num - 2, 0)) / colFirst_slave_num)

        whichColNum := this._opts.slaveReverse = true ? -1 : 1
        try {
            Loop count {
                if this._opts.slaveReverse = false {
                    if A_Index <= colSecond_slave_num{
                        ws._moveWindow(
                            tile.data,
                            colSecond_x,
                            colSecond_y,
                            totalWidth,
                            colSecond_height - colSecond_spacing,
                        )
                        colSecond_y += colSecond_height + colSecond_spacing
                    }
                    else{
                        ws._moveWindow(
                            tile.data,
                            colFirst_x,
                            colFirst_y,
                            totalWidth,
                            colFirst_height - colFirst_spacing,
                        )
                        colFirst_y += colFirst_height + colFirst_spacing
                    }
                } else{
                    if A_Index <= colSecond_slave_num{
                        ws._moveWindow(
                            tile.data,
                            colFirst_x,
                            colFirst_y,
                            totalWidth,
                            colSecond_height - colFirst_spacing,
                        )
                        colFirst_y += colSecond_height + colFirst_spacing
                    }
                    else{
                        ws._moveWindow(
                            tile.data,
                            colSecond_x,
                            colSecond_y,
                            totalWidth,
                            colFirst_height - colSecond_spacing,
                        )
                        colSecond_y += colFirst_height + colSecond_spacing
                    }
                }
                tile := tile.next
            }
        } catch TargetError as err {
            throw WindowError(tile.data, err)
        } catch OSError as err {
            throw WindowError(tile.data, err)
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




    retileTwoWindows(ws, masterWidth, slaveWidth, usableWidth, usableHeight) {
        opts := ws._opts
        masterCount := Min(opts.masterCount, ws._tiled.Count)
        slaveCount := ws._tiled.Count - masterCount
        workArea := ws._monitor.WorkArea
        if this._opts.masterPos != "right" {
            firstSlave := this._tallRetilePane(
                ws,
                ws._tiled.First,
                masterCount,
                workArea.left + opts.padding.left,
                workArea.top + opts.padding.top,
                masterWidth - opts.spacing // 2,
                usableHeight,
            )
            this._tallRetilePane(
                ws,
                firstSlave,
                slaveCount,
                workArea.left + opts.padding.left
                    + masterWidth + opts.spacing // 2,
                workArea.top + opts.padding.top,
                slaveWidth -  opts.spacing // 2,
                usableHeight,
            )
        } else if this._opts.masterPos = "right" {
            firstSlave := this._tallRetilePane(
                ws,
                ws._tiled.First,
                masterCount,
                workArea.left + opts.padding.left + slaveWidth + opts.spacing // 2,
                workArea.top + opts.padding.top,
                masterWidth - opts.spacing // 2,
                usableHeight,
            )
            this._tallRetilePane(
                ws,
                firstSlave,
                slaveCount,
                workArea.left + opts.padding.left,
                workArea.top + opts.padding.top,
                slaveWidth -  opts.spacing // 2,
                usableHeight,
            )
        } else{
            throw WindowError(tile.data, Error("Invalid option: masterPos"))
        }
    }

    retileMoreThanTwo(ws, masterWidth, slaveWidth, usableWidth, usableHeight){
        opts := ws._opts
        masterCount := Min(opts.masterCount, ws._tiled.Count)
        slaveCount := ws._tiled.Count - masterCount
        workArea := ws._monitor.WorkArea

        masterWidth := Round(usableWidth * opts.masterSize * this._opts.masterExtraSize)
        slaveWidth := Round((usableWidth - masterWidth) // 2)
        switch this._opts.masterPos{
            case "left":
                firstSlave := this._tallRetilePane(
                    ws,
                    ws._tiled.First,
                    masterCount,
                    workArea.left + opts.padding.left,
                    workArea.top + opts.padding.top,
                    masterWidth - opts.spacing,
                    usableHeight,
                )
                this._threeColumnsRetilePane(
                    ws,
                    firstSlave,
                    slaveCount,
                    workArea.right - opts.padding.right - slaveWidth + opts.spacing // 2,
                    workArea.top + opts.padding.top,
                    workArea.left + opts.padding.left + masterWidth + opts.spacing // 2,
                    workArea.top + opts.padding.top,
                    slaveWidth - opts.spacing // 2,
                    usableHeight,
                )
            case "mid":
                firstSlave := this._tallRetilePane(
                    ws,
                    ws._tiled.First,
                    masterCount,
                    workArea.left + opts.padding.left
                        + slaveWidth + opts.spacing // 2,
                    workArea.top + opts.padding.top,
                    masterWidth - opts.spacing,
                    usableHeight,
                )
                this._threeColumnsRetilePane(
                    ws,
                    firstSlave,
                    slaveCount,
                    workArea.left + opts.padding.left,
                    workArea.top + opts.padding.top,
                    workArea.right - opts.padding.right - slaveWidth + opts.spacing // 2,
                    workArea.top + opts.padding.top,
                    slaveWidth - opts.spacing // 2,
                    usableHeight,
                )
            case "right":
                firstSlave := this._tallRetilePane(
                    ws,
                    ws._tiled.First,
                    masterCount,
                    workArea.right - opts.padding.right - masterWidth + opts.spacing // 2,
                    workArea.top + opts.padding.top,
                    masterWidth - opts.spacing,
                    usableHeight,
                )
                this._threeColumnsRetilePane(
                    ws,
                    firstSlave,
                    slaveCount,
                    workArea.left + opts.padding.left,
                    workArea.top + opts.padding.top,
                    workArea.left + opts.padding.left + slaveWidth + opts.spacing // 2,
                    workArea.top + opts.padding.top,
                    slaveWidth - opts.spacing // 2,
                    usableHeight,
                )
            default:
                throw WindowError(tile.data, Error("Invalid option: masterPos"))
        }
    }
}
