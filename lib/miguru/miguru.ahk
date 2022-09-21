#Include %A_LineFile%\..\api.ahk
#Include %A_LineFile%\..\events.ahk

class MiguruWM extends WMEvents {
    __New() {
        base.__New()

        for k, v in MiguruAPI {
            if IsFunc(v) {
                ObjRawSet(this, k, v)
            }
        }
    }

    _onWindowEvent(event, hwnd) {
        Switch event {
        Case EV_WINDOW_SHOWN:
            index := this.VD.DesktopByWindow(hwnd)
            if !index {
                Return
            }
            log("Window {:x} is shown on Desktop {}", hwnd, index)
        Case EV_WINDOW_UNCLOAKED:
            index := this.VD.DesktopByWindow(hwnd)
            if !index {
                Return
            }
            log("Window {:x} is uncloaked on Desktop {}", hwnd, index)
        Case EV_WINDOW_RESTORED:
        Case EV_WINDOW_HIDDEN:
        Case EV_WINDOW_CLOAKED:
        Case EV_WINDOW_MINIMIZED:
        Case EV_WINDOW_CREATED:
        Case EV_WINDOW_DESTROYED:
        Case EV_WINDOW_FOCUSED:
        }
    }

    _onDesktopEvent(event, args) {
        Switch event {
        Case EV_DESKTOP_CHANGED:
            log("Current desktop changed from {} to {}", args.was, args.now)
        Case EV_DESKTOP_RENAMED:
            log("Desktop {} was renamed to {}", args.desktop, args.name)
        Case EV_DESKTOP_CREATED:
            log("Desktop {} was created", args.desktop)
        Case EV_DESKTOP_DESTROYED:
            log("Desktop {} was destroyed", args.desktopId)
        }
    }

    _onCommand(cmd, param) {
        Switch cmd {
        }
    }

    _onQuery(query, param) {
        Switch query {
        }
    }
}
