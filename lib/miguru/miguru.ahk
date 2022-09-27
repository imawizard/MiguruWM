#include api.ahk
#include events.ahk

class MiguruWM extends WMEvents {
    __New() {
        super.__New()

        api := MiguruAPI.Prototype
        for v in api.OwnProps() {
            if api.GetOwnPropDesc(v).HasMethod("Call") {
                this.%v% := api.GetMethod(v)
            }
        }
    }

    _onWindowEvent(event, hwnd) {
        switch event {
        case EV_WINDOW_SHOWN:
            index := this.VD.DesktopByWindow(hwnd)
            if !index {
                return
            }
            log("Window {:x} is shown on Desktop {}", hwnd, index)
        case EV_WINDOW_UNCLOAKED:
            index := this.VD.DesktopByWindow(hwnd)
            if !index {
                return
            }
            log("Window {:x} is uncloaked on Desktop {}", hwnd, index)
        case EV_WINDOW_RESTORED:
        case EV_WINDOW_HIDDEN:
        case EV_WINDOW_CLOAKED:
        case EV_WINDOW_MINIMIZED:
        case EV_WINDOW_CREATED:
        case EV_WINDOW_DESTROYED:
        case EV_WINDOW_FOCUSED:
        }
    }

    _onDesktopEvent(event, args) {
        switch event {
        case EV_DESKTOP_CHANGED:
            log("Current desktop changed from {} to {}", args.was, args.now)
        case EV_DESKTOP_RENAMED:
            log("Desktop {} was renamed to {}", args.desktop, args.name)
        case EV_DESKTOP_CREATED:
            log("Desktop {} was created", args.desktop)
        case EV_DESKTOP_DESTROYED:
            log("Desktop {} was destroyed", args.desktopId)
        }
    }

    _onCommand(cmd, param) {
        switch cmd {
        }
    }

    _onQuery(query, param) {
        switch query {
        }
    }
}
