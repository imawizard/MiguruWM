class ThreeColumnLayout extends TallLayout {
    __New(opts := {}) {
        this._opts := ObjMerge({
            displayName: "Three-Columns",
            positioning: ["mid", "left", "right"],
            masterSizeFactor: 1.0,
            masterCountMax: -1,
            showEmptyTertiary: true,
        }, opts)

        ExpectInSet(this._opts, "positioning", "mid", "left", "right")
        m := Map()
        for pos in this._opts.positioning {
            m[pos] := ""
        }
        if m.Count !== 3 {
            throw "'positioning' must contain distinct values"
        }
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
            masterWidth := Round(usableWidth * opts.masterSize
                * this._opts.masterSizeFactor)
            slaveWidth := usableWidth - masterWidth
            spacing := opts.spacing // 2

            tile := ws._tiled.First
            positioning := this._opts.positioning

            if slaveCount == 1 && !this._opts.showEmptyTertiary {
                if positioning[1] == "left" || positioning[2] == "right" {
                    leftCount := masterCount
                    rightCount := slaveCount
                } else {
                    loop masterCount {
                        tile := tile.next
                    }
                    leftCount := slaveCount
                    rightCount := masterCount
                }

                next := this._retilePane(
                    ws,
                    tile,
                    masterCount,
                    workArea.Left + opts.padding.left,
                    workArea.Top + opts.padding.top,
                    masterWidth - spacing,
                    usableHeight,
                )

                slaveWidth := usableWidth - masterWidth
                this._retilePane(
                    ws,
                    next,
                    slaveCount,
                    workArea.Left + opts.padding.left
                        + masterWidth + spacing,
                    workArea.Top + opts.padding.top,
                    slaveWidth - spacing,
                    usableHeight,
                )
            } else {
                slaveWidth := slaveWidth // 2
                secondary := CircularList()
                tertiary := CircularList()

                tmp := tile
                loop masterCount {
                    tmp := tmp.next
                }

                pivot := Ceil(slaveCount / 2)
                loop pivot {
                    secondary.Append(tmp.data)
                    tmp := tmp.next
                }
                loop slaveCount - pivot {
                    tertiary.Append(tmp.data)
                    tmp := tmp.next
                }

                switch positioning[1] {
                case "left":
                    next := this._retilePane(
                        ws,
                        tile,
                        masterCount,
                        workArea.Left + opts.padding.left,
                        workArea.Top + opts.padding.top,
                        masterWidth - spacing,
                        usableHeight,
                    )
                    x1 := workArea.Left + opts.padding.left + masterWidth + spacing
                    x2 := x1 + slaveWidth + spacing
                case "mid":
                    next := this._retilePane(
                        ws,
                        tile,
                        masterCount,
                        workArea.Left + opts.padding.left
                            + slaveWidth + spacing,
                        workArea.Top + opts.padding.top,
                        masterWidth - spacing * 2,
                        usableHeight,
                    )
                    x1 := workArea.Left + opts.padding.left
                    x2 := x1 + slaveWidth + masterWidth + spacing
                case "right":
                    next := this._retilePane(
                        ws,
                        tile,
                        masterCount,
                        workArea.Left + opts.padding.left
                            + slaveWidth * 2 + spacing * 2,
                        workArea.Top + opts.padding.top,
                        masterWidth - spacing,
                        usableHeight,
                    )
                    x1 := workArea.Left + opts.padding.left
                    x2 := workArea.Left + opts.padding.left + slaveWidth + spacing
                }

                if positioning[2] == "right" || positioning[3] == "left" {
                    tmp := x1
                    x1 := x2
                    x2 := tmp
                }

                this._retilePane(
                    ws,
                    secondary.First,
                    secondary.Count,
                    x1,
                    workArea.Top + opts.padding.top,
                    slaveWidth - spacing,
                    usableHeight,
                )

                if tertiary.Count > 0 {
                    this._retilePane(
                        ws,
                        tertiary.First,
                        tertiary.Count,
                        x2,
                        workArea.Top + opts.padding.top,
                        slaveWidth - spacing,
                        usableHeight,
                    )
                }
            }
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
}
