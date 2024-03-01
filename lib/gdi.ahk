;; See https://learn.microsoft.com/de-de/windows/win32/gdiplus/-gdiplus-flatapi-flat

PixelFormatIndexed   := 0x00010000
PixelFormatGDI       := 0x00020000
PixelFormatAlpha     := 0x00040000
PixelFormatPAlpha    := 0x00080000
PixelFormatExtended  := 0x00100000
PixelFormatCanonical := 0x00200000

PixelFormat32bppRGB   :=  9 | (32 << 8) | PixelFormatGDI
PixelFormat32bppARGB  := 10 | (32 << 8) | PixelFormatAlpha | PixelFormatGDI | PixelFormatCanonical
PixelFormat32bppPARGB := 11 | (32 << 8) | PixelFormatAlpha | PixelFormatPAlpha | PixelFormatGDI

_gdiplus := GdiPlus()

class GdiPlus {
    __New() {
        token := 0
        input := Buffer(4 + A_PtrSize + 4 + 4, 0)
        NumPut("UInt", 1, input, 0)
        if DllCall(
            "gdiplus.dll\GdiplusStartup",
            "UInt*", &token,
            "Ptr", input,
            "Ptr", 0,
            "Int",
        ) {
            throw "GDI+ startup failed"
        }
        this._token := token
    }

    __Delete() {
        token := this._token
        DllCall(
            "gdiplus.dll\GdiplusShutdown",
            "UInt*", &token,
        )
    }
}

class GdiBitmap {
    __New(width, height, format := PixelFormat32bppARGB) {
        handle := 0
        DllCall(
            "gdiplus.dll\GdipCreateBitmapFromScan0",
            "Int", width,
            "Int", height,
            "Int", 0,
            "UInt", format,
            "Ptr", 0,
            "Ptr*", &handle,
            "Int",
        )
        this._handle := handle
        this._graphics := GdiGraphics.FromImage(this)
        this._width := width
        this._height := height
    }

    __Delete() {
        DllCall(
            "gdiplus.dll\GdipDisposeImage",
            "Ptr", this,
            "Int",
        )
    }

    Ptr => this._handle
    Canvas => this._graphics
    Width => this._width
    Height => this._height

    ToIcon() {
        icon := 0
        DllCall(
            "gdiplus.dll\GdipCreateHICONFromBitmap",
            "Ptr", this,
            "Ptr*", &icon,
            "Int",
        )
        return icon
    }
}

FontStyleRegular    := 0
FontStyleBold       := 1 << 0
FontStyleItalic     := 1 << 1
FontStyleBoldItalic := FontStyleBold | FontStyleItalic
FontStyleUnderline  := 1 << 2
FontStyleStrikeout  := 1 << 3

class GdiFont {
    __New(name, size, style := FontStyleRegular) {
        this._size := size
        this._style := style

        family := 0
        DllCall(
            "gdiplus.dll\GdipCreateFontFamilyFromName",
            "Str", name,
            "Ptr", 0,
            "Ptr*", &family,
            "Int",
        )
        this._family := family

        handle := 0
        DllCall(
            "gdiplus.dll\GdipCreateFont",
            "Ptr", family,
            "Float", size,
            "Int", style,
            "UInt", 0,
            "Ptr*", &handle,
            "Int",
        )
        this._handle := handle
    }

    __Delete() {
        DllCall(
            "gdiplus.dll\GdipDeleteFontFamily",
            "Ptr", this._family,
            "Int",
        )
        DllCall(
            "gdiplus.dll\GdipDeleteFont",
            "Ptr", this,
            "Int",
        )
    }

    Ptr => this._handle
    Family => this._family
    Size => this._size
    Style => this._style
}

class GdiBrush {
    __New(color) {
        handle := 0
        DllCall(
            "gdiplus.dll\GdipCreateSolidFill",
            "UInt", color,
            "Ptr*", &handle,
            "Int",
        )
        this._handle := handle
    }

    __Delete() {
        DllCall(
            "gdiplus.dll\GdipDeleteBrush",
            "Ptr", this,
            "Int",
        )
    }

    Ptr => this._handle
}

class GdiPen {
    __New(color, width := 1) {
        handle := 0
        DllCall(
            "gdiplus.dll\GdipCreatePen1",
            "UInt", color,
            "Float", width,
            "UInt", 0,
            "Ptr*", &handle,
            "Int",
        )
        this._handle := handle
    }

    __Delete() {
        DllCall(
            "gdiplus.dll\GdipDeletePen",
            "Ptr", this,
            "Int",
        )
    }

    Ptr => this._handle
}

class GdiRect {
    __New(x, y, width, height) {
        buf := Buffer(4 * 4)
        NumPut("Float", x,      buf, 0 * 4)
        NumPut("Float", y,      buf, 1 * 4)
        NumPut("Float", width,  buf, 2 * 4)
        NumPut("Float", height, buf, 3 * 4)
        this.buf := buf
    }

    Ptr => this.buf.Ptr
}

StringFormatFlagsDirectionRightToLeft  := 0x00000001
StringFormatFlagsDirectionVertical     := 0x00000002
StringFormatFlagsNoFitBlackBox         := 0x00000004
StringFormatFlagsDisplayFormatControl  := 0x00000020
StringFormatFlagsNoFontFallback        := 0x00000400
StringFormatFlagsMeasureTrailingSpaces := 0x00000800
StringFormatFlagsNoWrap                := 0x00001000
StringFormatFlagsLineLimit             := 0x00002000
StringFormatFlagsNoClip                := 0x00004000
StringFormatFlagsBypassGDI             := 0x80000000

StringAlignmentNear   := 0
StringAlignmentCenter := 1
StringAlignmentFar    := 2

class GdiStringFormat {
    __New(flags := StringFormatFlagsNoClip) {
        handle := 0
        DllCall(
            "gdiplus.dll\GdipCreateStringFormat",
            "UInt", flags,
            "Int", 0,
            "Ptr*", &handle,
            "Int",
        )
        this._handle := handle
    }

    __Delete() {
        DllCall(
            "gdiplus.dll\GdipDeleteStringFormat",
            "Ptr", this,
            "Int",
        )
    }

    Ptr => this._handle

    Align {
        set {
            DllCall(
                "gdiplus.dll\GdipSetStringFormatAlign",
                "Ptr", this,
                "UInt", value,
                "Int",
            )
        }
    }

    LineAlign {
        set {
            DllCall(
                "gdiplus.dll\GdipSetStringFormatLineAlign",
                "Ptr", this,
                "UInt", value,
                "Int",
            )
        }
    }
}

FillModeAlternate := 0
FillModeWinding   := 1

class GdiPath {
    __New(fillMode := FillModeAlternate) {
        handle := 0
        DllCall(
            "gdiplus.dll\GdipCreatePath",
            "UInt", fillMode,
            "Ptr*", &handle,
            "Int",
        )
        this._handle := handle
    }

    __Delete() {
        DllCall(
            "gdiplus.dll\GdipDeletePath",
            "Ptr", this,
            "Int",
        )
    }

    Ptr => this._handle

    Close() {
        DllCall(
            "gdiplus.dll\GdipClosePathFigure",
            "Ptr", this,
            "Int",
        )
    }

    MoveTo(x, y) {
        DllCall(
            "gdiplus.dll\GdipAddPathLine",
            "Ptr", this,
            "Float", x,
            "Float", y,
            "Float", x,
            "Float", y,
            "Int",
        )
    }

    LineTo(x, y) {
        buf := Buffer(4 * 2)
        DllCall(
            "gdiplus.dll\GdipGetPathLastPoint",
            "Ptr", this,
            "Ptr", buf,
            "Int",
        )
        x1 := NumGet(buf, 0, "Float")
        y1 := NumGet(buf, 4, "Float")
        this.Line(x1, y1, x, y)
    }

    Line(x1, y1, x2, y2) {
        DllCall(
            "gdiplus.dll\GdipAddPathLine",
            "Ptr", this,
            "Float", x1,
            "Float", y1,
            "Float", x2,
            "Float", y2,
            "Int",
        )
    }

    Rectangle(x, y, width, height) {
        DllCall(
            "gdiplus.dll\GdipAddPathRectangle",
            "Ptr", this,
            "Float", x,
            "Float", y,
            "Float", width,
            "Float", height,
            "Int",
        )
    }

    Arc(x, y, width, height, startAngle, sweepAngle) {
        DllCall(
            "gdiplus.dll\GdipAddPathArc",
            "Ptr", this,
            "Float", x,
            "Float", y,
            "Float", width,
            "Float", height,
            "Float", startAngle,
            "Float", sweepAngle,
            "Int",
        )
    }

    Bezier(x1, y1, x2, y2, x3, y3, x4, y4) {
        DllCall(
            "gdiplus.dll\GdipAddPathBezier",
            "Ptr", this,
            "Float", x1,
            "Float", y1,
            "Float", x2,
            "Float", y2,
            "Float", x3,
            "Float", y3,
            "Float", x4,
            "Float", y4,
            "Int",
        )
    }

    Text(s, rect, format, font) {
        DllCall(
            "gdiplus.dll\GdipAddPathString",
            "Ptr", this,
            "Str", s,
            "Int", -1,
            "Ptr", font.Family,
            "Int", font.Style,
            "Float", font.Size,
            "Ptr", rect,
            "Ptr", format,
            "Int",
        )
    }
}

SystemDefault            := 0
SingleBitPerPixelGridFit := 1
SingleBitPerPixel        := 2
AntiAliasGridFit         := 3
AntiAlias                := 4

class GdiGraphics {
    __New(handle) {
        this._handle := handle
    }

    __Delete() {
        DllCall(
            "gdiplus.dll\GdipDeleteGraphics",
            "Ptr", this,
            "Int",
        )
    }

    Ptr => this._handle

    static FromImage(image) {
        handle := 0
        DllCall(
            "gdiplus.dll\GdipGetImageGraphicsContext",
            "Ptr", image,
            "UInt*", &handle,
            "Int",
        )
        return GdiGraphics(handle)
    }

    TextRenderingHint {
        set {
            DllCall(
                "gdiplus.dll\GdipSetTextRenderingHint",
                "Ptr", this,
                "Int", value,
                "Int",
            )
        }
    }

;     _drawRectangle(x, y, width, height, pen) {
;         DllCall(
;             "gdiplus.dll\GdipDrawRectangle",
;             "Ptr", this,
;             "Ptr", pen,
;             "Float", x,
;             "Float", y,
;             "Float", width,
;             "Float", height,
;             "Int",
;         )
;     }

;     _fillRectangle(x, y, width, height, brush) {
;         DllCall(
;             "gdiplus.dll\GdipFillRectangle",
;             "Ptr", this,
;             "Ptr", brush,
;             "Float", x,
;             "Float", y,
;             "Float", width,
;             "Float", height,
;             "Int",
;         )
;     }

    ; _drawString(s, rect, format, font, brush) {
    ;     DllCall(
    ;         "gdiplus.dll\GdipDrawString",
    ;         "Ptr", this,
    ;         "Str", s,
    ;         "Int", -1,
    ;         "Ptr", font,
    ;         "Ptr", rect,
    ;         "Ptr", format,
    ;         "Ptr", brush,
    ;         "Int",
    ;     )
    ; }

    ; _drawBezier(x1, y1, x2, y2, x3, y3, x4, y4, pen) {
    ;     DllCall(
    ;         "gdiplus.dll\GdipDrawBezier",
    ;         "Ptr", this,
    ;         "Ptr", pen,
    ;         "Float", x1,
    ;         "Float", y1,
    ;         "Float", x2,
    ;         "Float", y2,
    ;         "Float", x3,
    ;         "Float", y3,
    ;         "Float", x4,
    ;         "Float", y4,
    ;         "Int",
    ;     )
    ; }

    _drawPath(pen, path) {
        DllCall(
            "gdiplus.dll\GdipDrawPath",
            "Ptr", this,
            "Ptr", pen,
            "Ptr", path,
            "Int",
        )
    }

    _fillPath(brush, path) {
        DllCall(
            "gdiplus.dll\GdipFillPath",
            "Ptr", this,
            "Ptr", brush,
            "Ptr", path,
            "Int",
        )
    }

    RoundedRectangle(x, y, width, height, radius, pen, brush) {
;         kappa := 0.5522847498
;
;         xRadius:= 8
;         yRadius:= 8
;
;         path := GdiPath()
;         originX := x, originY := y + height
;         topLeftX := x, topLeftY := y
;         topRightX := x + width, topRightY := y
;         bottomRightX := x + width, bottomRightY := y + height
;
;         ;; top left
;         startX := topLeftX + xRadius, startY := topLeftY
;         endX := topLeftX, endY := topLeftY - yRadius
;         control1X := startX - kappa * xRadius, control1Y := startY
;         control2X := endX, control2Y := endY + kappa * yRadius
;         ; this._drawBezier(startX, startY, control1X, control1Y, control2X, control2Y, endX, endY, pen)
;
;         ; path.MoveTo(startX, startY)
;         path.Bezier(startX, startY, control1X, control1Y, control2X, control2Y, endX, endY)
;         ; path.LineTo(0, 10)
;         ; path.LineTo(10, 10)
;         ; path.LineTo(10, 0)
;
;         ;; top right
;         startX := topRightX, startY := topRightY - yRadius
;         endX := topRightX - xRadius, endY := topRightY
;         control1X := startX, control1Y := startY + kappa * yRadius
;         control2X := endX + kappa * xRadius, control2Y := endY
;         ; this._drawBezier(startX, startY, control1X, control1Y, control2X, control2Y, endX, endY, pen)
;         ; path.LineTo(startX, startY)
;         ; path.Bezier(startX, startY, control1X, control1Y, control2X, control2Y, endX, endY)
;
;         ;; bottom right
;         startX := bottomRightX - xRadius, startY := bottomRightY
;         endX := bottomRightX, endY := bottomRightY + yRadius
;         control1X := startX + kappa * yRadius, control1Y := startY
;         control2X := endX, control2Y := endY - kappa * xRadius
;         ; this._drawBezier(startX, startY, control1X, control1Y, control2X, control2Y, endX, endY, pen)
;         ; path.LineTo(startX, startY)
;         ; path.Bezier(startX, startY, control1X, control1Y, control2X, control2Y, endX, endY)
;
;         ;; bottom left
;         startX := originX, startY := originY + yRadius
;         endX := originX + xRadius, endY := originY
;         control1X := startX, control1Y := startY - kappa * yRadius
;         control2X := endX - kappa * xRadius, control2Y := endY
;         ; this._drawBezier(startX, startY, control1X, control1Y, control2X, control2Y, endX, endY, pen)
        ; path.LineTo(startX, startY)
        ; path.Bezier(startX, startY, control1X, control1Y, control2X, control2Y, endX, endY)

        ; path.Rectangle(x, y, width, height)

        path := GdiPath()
        path.Arc(x, y, radius, radius, 180, 90)
        path.Arc(x + width - radius - 1, y, radius, radius, 270, 90)
        path.Arc(x + width - radius - 1, y + height - radius - 1, radius, radius, 0, 90)
        path.Arc(x, y + height - radius - 1, radius, radius, 90, 90)
        path.Close()
        this._fillPath(brush, path)
        this._drawPath(pen, path)
    }

    Text(s, x, y, width, height, font, pen, brush) {
        rect := GdiRect(x, y, width, height)
        format := GdiStringFormat()
        format.Align := StringAlignmentCenter
        format.LineAlign := StringAlignmentCenter

        path := GdiPath()
        path.Text(s, rect, format, font)
        path.Close()
        this._fillPath(brush, path)
        this._drawPath(pen, path)
    }

    Triangle(x, y, width, height, pen, brush, skew := 0) {
        path := GdiPath()
        path.Rectangle(x, y, width, height)
        path.Close()
        this._fillPath(brush, path)
        this._drawPath(pen, path)
    }

    Rectangle(x, y, width, height, pen, brush) {
        path := GdiPath()
        path.Rectangle(x, y, width, height)
        path.Close()
        this._fillPath(brush, path)
        this._drawPath(pen, path)
    }

    Arc(x, y, width, height, startAngle, sweepAngle, pen, brush) {
        path := GdiPath()
        path.Arc(x, y, width, height, startAngle, sweepAngle)
        path.Close()
        this._fillPath(brush, path)
        this._drawPath(pen, path)
    }
}
