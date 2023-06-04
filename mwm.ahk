#Requires AutoHotkey v2
#SingleInstance force
#WinActivateForce
#Warn VarUnset, Off
A_MaxHotkeysPerInterval := 1000
KeyHistory(0), ListLines(false), ProcessSetPriority("H")

#include *i lib\miguru\miguru.ahk
#include *i lib\Popup.ahk

GroupAdd("MIGURU_AUTOFLOAT", "Microsoft Teams-Benachrichtigung" " ahk_exe Teams.exe"                                                  )
GroupAdd("MIGURU_AUTOFLOAT", "Microsoft Teams-Notification"     " ahk_exe Teams.exe"                                                  )
GroupAdd("MIGURU_AUTOFLOAT",                                    " ahk_exe QuickLook.exe"                                              )
GroupAdd("MIGURU_AUTOFLOAT",                                    " ahk_exe outlook.exe"              " ahk_class MsoSplash"            )
GroupAdd("MIGURU_AUTOFLOAT",                                    " ahk_exe explorer.exe"             " ahk_class OperationStatusWindow")
GroupAdd("MIGURU_AUTOFLOAT",                                    " ahk_exe taskmgr.exe"                                                )
GroupAdd("MIGURU_AUTOFLOAT", "Calculator"                       " ahk_exe ApplicationFrameHost.exe"                                   )
GroupAdd("MIGURU_AUTOFLOAT",                                    " ahk_exe zeal.exe"                                                   )

GroupAdd("MIGURU_DECOLESS",                                     " ahk_exe qutebrowser.exe"                                            )
GroupAdd("MIGURU_DECOLESS",                                     " ahk_exe alacritty.exe"                                              )

if !IsSet(MiguruWM) {
    prog := RegExReplace(A_ScriptName, "i)\.ahk$", ".exe")
    if FileExist(prog) {
        Run(prog)
    }
    ExitApp()
}

mwm := MiguruWM({
    layout: "Tall",
    masterSize: 0.5,
    masterCount: 1,
    padding: {
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
    },
    spacing: 0,

    tilingMinWidth: 0,
    tilingMinHeight: 0,
    tilingInsertion: "before-mru",
    floatingAlwaysOnTop: false,
    nativeMaximize: false,

    focusFollowsMouse: false,
    mouseFollowsFocus: false,

    followWindowToMonitor: false,

    delays: {
        retryManage: 100,
        windowHidden: 400,
        onDisplayChange: 1000,
        sendMonitorRetile: 100,
    },

    showPopup: (text, opts) => Popup(text, opts),
})

MiguruWM.SetupTrayMenu()

mod1 := "Alt"

; Keybindings .............................................................{{{1

#Hotif GetKeyState(mod1, "P") and !GetKeyState("Shift", "P")

*1::mwm.VD.FocusDesktop(1)
*2::mwm.VD.FocusDesktop(2)
*3::mwm.VD.FocusDesktop(3)
*4::mwm.VD.FocusDesktop(4)
*5::mwm.VD.FocusDesktop(5)
*6::mwm.VD.FocusDesktop(6)
*7::mwm.VD.FocusDesktop(7)
*8::mwm.VD.FocusDesktop(8)
*9::mwm.VD.FocusDesktop(9)

*w::mwm.Do("focus-monitor", { monitor: 1 })
*e::mwm.Do("focus-monitor", { monitor: 2 })
*r::mwm.Do("focus-monitor", { monitor: 3 })

*j::mwm.Do("focus-window", { target: "next"     })
*k::mwm.Do("focus-window", { target: "previous" })
*m::mwm.Do("focus-window", { target: "master"   })

*l::mwm.Set("master-size", { delta:  0.01 })
*h::mwm.Set("master-size", { delta: -0.01 })

*,::mwm.Set("master-count", { delta:  1 })
*.::mwm.Set("master-count", { delta: -1 })

*t::mwm.Do("float-window", { hwnd: WinExist("A"), value: false })
*p::OpenSearch()
*q::Reload()

*Enter::mwm.Do("swap-window", { with: "master" })
*Space::CycleLayouts()

*vk01::{
    MouseGetPos(, , &hwnd)
    if !hwnd {
        return
    }
    mwm.Do("float-window", { hwnd: hwnd, value: true })
    PostMessage(WM_SYSCOMMAND, SC_MOVE,  , , "ahk_id" hwnd)
    PostMessage(WM_KEYDOWN,    VK_LEFT,  , , "ahk_id" hwnd)
    PostMessage(WM_KEYUP,      VK_LEFT,  , , "ahk_id" hwnd)
    PostMessage(WM_KEYDOWN,    VK_RIGHT, , , "ahk_id" hwnd)
    PostMessage(WM_KEYUP,      VK_RIGHT, , , "ahk_id" hwnd)
    KeyWait("vk01")
    Send("{vk01 Up}")
}

*vk02::{
    MouseGetPos(, , &hwnd)
    if !hwnd {
        return
    }
    mwm.Do("float-window", { hwnd: hwnd, value: true })
    PostMessage(WM_SYSCOMMAND, SC_SIZE,  , , "ahk_id" hwnd)
    PostMessage(WM_KEYDOWN,    VK_DOWN,  , , "ahk_id" hwnd)
    PostMessage(WM_KEYUP,      VK_DOWN,  , , "ahk_id" hwnd)
    PostMessage(WM_KEYDOWN,    VK_RIGHT, , , "ahk_id" hwnd)
    PostMessage(WM_KEYUP,      VK_RIGHT, , , "ahk_id" hwnd)
    KeyWait("vk02")
    Send("{vk01 Up}")
}

#Hotif GetKeyState(mod1, "P") and GetKeyState("Shift", "P")

*1::mwm.VD.SendWindowToDesktop(WinExist("A"), 1), mwm.VD.FocusDesktop(1)
*2::mwm.VD.SendWindowToDesktop(WinExist("A"), 2), mwm.VD.FocusDesktop(2)
*3::mwm.VD.SendWindowToDesktop(WinExist("A"), 3), mwm.VD.FocusDesktop(3)
*4::mwm.VD.SendWindowToDesktop(WinExist("A"), 4), mwm.VD.FocusDesktop(4)
*5::mwm.VD.SendWindowToDesktop(WinExist("A"), 5), mwm.VD.FocusDesktop(5)
*6::mwm.VD.SendWindowToDesktop(WinExist("A"), 6), mwm.VD.FocusDesktop(6)
*7::mwm.VD.SendWindowToDesktop(WinExist("A"), 7), mwm.VD.FocusDesktop(7)
*8::mwm.VD.SendWindowToDesktop(WinExist("A"), 8), mwm.VD.FocusDesktop(8)
*9::mwm.VD.SendWindowToDesktop(WinExist("A"), 9), mwm.VD.FocusDesktop(9)

*w::mwm.Do("send-to-monitor", { monitor: 1 })
*e::mwm.Do("send-to-monitor", { monitor: 2 })
*r::mwm.Do("send-to-monitor", { monitor: 3 })

*j::mwm.Do("swap-window", { with: "next"     })
*k::mwm.Do("swap-window", { with: "previous" })

*c::WinClose("A")
*q::ExitApp()

*Enter::OpenTerminal()
*Space::ResetLayout()

; ..........................................................................}}}

; Helper functions ........................................................{{{1

CycleLayouts() {
    cycle := [
        "Tall",
        "Wide",
        "Fullscreen",
        "Floating",
    ]

    m := Map()
    for i, l in cycle {
        m[l] := i
    }

    current := mwm.Get("layout")
    next := cycle[Mod(m[current], cycle.Length) + 1]

    mwm.Set("layout", { value: next })
}

ResetLayout() {
    defaults := mwm.Options

    mwm.Set("layout", { value: defaults.layout })
    mwm.Set("master-size", { value: defaults.masterSize })
    mwm.Set("master-count", { value: defaults.masterCount })
    mwm.Set("padding", { value: defaults.padding })
    mwm.Set("spacing", { value: defaults.spacing })
}

GetSHAppFolderPath(hwnd := 0) {
    if !hwnd {
        hwnd := WinExist("A")
    }
    res := ""
    app := ComObject("Shell.Application")
    for window in app.Windows {
        if window && window.hwnd == hwnd {
            res := window.Document.Folder.Self.Path
            break
        }
    }
    return res
}

OpenTerminal() {
    wd := EnvGet("USERPROFILE")
    if WinGetProcessName("A") == "explorer.exe" {
        path := GetSHAppFolderPath()
        if path && Substr(path, 1, 2) !== "::" {
            wd := path
        }
    }
    Run("wt.exe -d " wd)
}

OpenTaskView() {
    Send("#{Tab}")
}

OpenSearch() {
    Send("#s")
}

ShowDesktop() {
    Send("#d")
}

; ..........................................................................}}}
