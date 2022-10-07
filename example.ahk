#Requires AutoHotkey v2.0-beta
#SingleInstance force
#WinActivateForce
KeyHistory(0), ListLines(false), ProcessSetPriority("H")
A_IconTip := "見苦窓経営"

; Initial settings ........................................................{{{1

#include lib\miguru\miguru.ahk

Miguru := MiguruWM({
    defaults: {
        layout: "tall",
        padding: 0,
        spacing: 1,
    },
})

; Set the current workspace's padding/spacing
Miguru.SetPadding(22)
Miguru.SetSpacing(12)

; Show only columns on the leftmost monitor's current workspace
Miguru.SetLayout("wide", , 1)
Miguru.SetMasterCount(0, , , 1)

; Change the 4th workspace's layout
Miguru.SetMasterSize(0.6, , 4)
Miguru.SetMasterCount(2, , 4)

;..........................................................................}}}

; Right Alt ..............................................................{{{1

#Hotif GetKeyState("RAlt", "P") and !GetKeyState("Shift", "P")

*a::Miguru.FocusWorkspace(1)
*s::Miguru.FocusWorkspace(2)
*d::Miguru.FocusWorkspace(3)
*f::Miguru.FocusWorkspace(4)
*g::Miguru.FocusWorkspace(5)

*j::Miguru.FocusWindow("next")
*k::Miguru.FocusWindow("previous")
*m::Miguru.FocusWindow("master")

*h::Miguru.SetMasterSize(, -0.01)
*l::Miguru.SetMasterSize(, +0.01)

*w::Miguru.FocusMonitor("primary", -1)
*e::Miguru.FocusMonitor("primary")
*r::Miguru.FocusMonitor("primary", +1)

*1::TrayTip("Set layout to floating"),   Miguru.SetLayout("floating")
*2::TrayTip("Set layout to tall"),       Miguru.SetLayout("tall")
*3::TrayTip("Set layout to wide"),       Miguru.SetLayout("wide")
*4::TrayTip("Set layout to fullscreen"), Miguru.SetLayout("fullscreen")

*,::Miguru.SetMasterCount(, +1)
*.::Miguru.SetMasterCount(, -1)
*F1::Miguru.SetPadding(, -1)
*F2::Miguru.SetPadding(, +1)
*F3::Miguru.SetSpacing(, -1)
*F4::Miguru.SetSpacing(, +1)

*Enter::Miguru.SwapWindow("master")
*c::OpenTaskView()
*q::Reload()

;..........................................................................}}}

; Right Alt (Shifted) ....................................................{{{1

#Hotif GetKeyState("RAlt", "P") and GetKeyState("Shift", "P")

*a::Miguru.SendToWorkspace(1)
*s::Miguru.SendToWorkspace(2)
*d::Miguru.SendToWorkspace(3)
*f::Miguru.SendToWorkspace(4)
*g::Miguru.SendToWorkspace(5)

*j::Miguru.SwapWindow("next")
*k::Miguru.SwapWindow("previous")

*w::Miguru.SendToMonitor("primary", -1)
*e::Miguru.SendToMonitor("primary")
*r::Miguru.SendToMonitor("primary", +1)

*Enter::OpenTerminal()
*Space::CycleLayouts()
*c::WinClose("A")
*q::ExitApp()

;..........................................................................}}}

#Hotif

OpenTerminal() {
    wd := EnvGet("HOME")
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

CycleLayouts() {
    cycle := [
        "tall",
        "wide",
        "fullscreen",
        "floating",
    ]

    m := Map()
    for i, l in cycle {
        m[l] := i
    }

    current := Miguru.Layout()
    next := cycle[Mod(m[current], cycle.Length) + 1]

    TrayTip("Set layout to " next)
    Miguru.SetLayout(next)
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
