STD_OUTPUT_HANDLE := -11
ENABLE_ECHO_INPUT := 0x0004

;; The logging levels can be set for a class, the auto-execute section or
;; everything unspecified, they are: warn, debug (default), info and trace.
;; Use the env variable AHK_LOG like below.
;;
;; Examples:
;;    ; Set logging for class MiguruWM to debug
;;    ; Set logging to warn for everything else
;;    AHK_LOG=miguruwm=debug
;;
;;    ; Set logging for class Workspace to warn
;;    ; Set logging for auto-execute section to debug
;;    ; Turn off logging for everything else
;;    AHK_LOG=off,auto-exec=debug,workspace=warn
;;
;;    ; Disable logging completely
;;    AHK_LOG=disable
class Logger {
    static Disabled := false
    static Labels := [
        "WARN",
        "DEBUG",
        "INFO",
        "TRACE",
    ]
    static Colors := [
        "1;31",
        "1;34",
        "1;38",
        "1;30",
    ]
    static NO_COLOR := EnvGet("NO_COLOR") !== ""
    static Levels := Map()
    static PrintModule := true

    static Init() {
        attached := DllCall(
            "AttachConsole",
            "UInt", -1,
            "Int",
        )

        if attached {
            handle := DllCall(
                "GetStdHandle",
                "UInt", STD_OUTPUT_HANDLE,
                "UInt",
            )
            mode := 0
            DllCall(
                "GetConsoleMode",
                "UInt", handle,
                "UInt*", &mode,
                "Int",
            )

            ;; If writing to stdout is not possible,
            if mode & ENABLE_ECHO_INPUT == 0 {
                con := DllCall("GetConsoleWindow", "Ptr")

                ;; and there is no cmd window associated,
                if DllCall("IsWindow", "Ptr", con, "Int")
                    && !DllCall("IsWindowVisible", "Ptr", con, "Int") {

                    ;; then undo AttachConsole.
                    DllCall("FreeConsole", "Int")
                    attached := false
                } else {
                    Logger.NO_COLOR := true
                }
            }
        }

        opts := StrLower(EnvGet("AHK_LOG"))
        if (!attached && opts == "") || opts == "disable" {
            Logger.Disabled := true
            return
        }

        if !attached {
            ;; If AHK_LOG was set but there's no attached console.
            DllCall("AllocConsole", "Int")
        }

        for part in StrSplit("debug," opts, ",") {
            if !part {
                continue
            }
            parts := StrSplit(part, "=")
            module := ""
            level := parts[1]
            if !level {
                continue
            } else if parts.Length >= 2 {
                module := parts[1]
                level := parts[2]
            }
            if level !== "off" {
                for v, l in Logger.Labels {
                    if level == StrLower(l) {
                        Logger.Levels[module] := v
                    }
                }
            } else {
                Logger.Levels[module] := 0
            }
        }
    }

    static Log(level, fmt, args*) {
        if Logger.Disabled {
            return
        }

        err := ""
        loop {
            err := Error("", -(A_Index + 1))
        } until InStr(err.What, ".") || IsInteger(err.What)

        module := !IsInteger(err.What)
            ? StrSplit(err.What, ".")[1]
            : "auto-exec"
        key := StrLower(module)
        max := Logger.Levels[Logger.Levels.Has(key) ? key : ""]

        if level <= max {
            s := ""
            if fmt is Func {
                s := Format(fmt()*)
            } else {
                s := Format(fmt, args*)
            }
            t := FormatTime(, "HH:mm:ss")
            m := Logger.PrintModule && module
                ? module !== "auto-exec"
                    ? " " module
                    : ""
                : ""

            l := Logger.Labels[level]
            c := Logger.Colors[level]
            if c && !Logger.NO_COLOR {
                l := Chr(27) "[" c "m" l Chr(27) "[0m"
            }

            FileAppend(t "." A_MSec m " [" l "] " s "`n", "*")
        }
    }
}

Logger.Init()

trace(fmt, args*) {
    Logger.Log(4, fmt, args*)
}

info(fmt, args*) {
    Logger.Log(3, fmt, args*)
}

debug(fmt, args*) {
    Logger.Log(2, fmt, args*)
}

warn(fmt, args*) {
    Logger.Log(1, fmt, args*)
}
