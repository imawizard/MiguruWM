#Requires AutoHotkey v2
#SingleInstance force
#WinActivateForce
A_MaxHotkeysPerInterval := 1000
KeyHistory(0), ListLines(false), ProcessSetPriority("H")
A_IconTip := "「 Miguru Window Manager 」"

#include lib\miguru\miguru.ahk

GroupAdd("MIGURU_AUTOFLOAT", "Microsoft Teams-Benachrichtigung ahk_exe Teams.exe")
GroupAdd("MIGURU_AUTOFLOAT", "Microsoft Teams-Notification ahk_exe Teams.exe")
GroupAdd("MIGURU_AUTOFLOAT", "ahk_exe QuickLook.exe")

mwm := MiguruWM({
    padding: 0,
    spacing: 0,
})

mod1 := "Alt"

; Keybindings .............................................................{{{1

#Hotif GetKeyState(mod1, "P") and !GetKeyState("Shift", "P")

*1::mwm.FocusWorkspace(1)
*2::mwm.FocusWorkspace(2)
*3::mwm.FocusWorkspace(3)
*4::mwm.FocusWorkspace(4)
*5::mwm.FocusWorkspace(5)
*6::mwm.FocusWorkspace(6)
*7::mwm.FocusWorkspace(7)
*8::mwm.FocusWorkspace(8)
*9::mwm.FocusWorkspace(9)

*w::mwm.FocusMonitor("primary", -1)
*e::mwm.FocusMonitor("primary")
*r::mwm.FocusMonitor("primary", +1)

*j::mwm.FocusWindow("next")
*k::mwm.FocusWindow("previous")
*m::mwm.FocusWindow("master")

*h::mwm.SetMasterSize(, -0.01)
*l::mwm.SetMasterSize(, +0.01)

*,::mwm.SetMasterCount(, +1)
*.::mwm.SetMasterCount(, -1)

*t::mwm.FloatWindow(, false)
*p::OpenSearch()
*q::Reload()

*Enter::mwm.SwapWindow("master")
*Space::CycleLayouts()

*vk01::{
    MouseGetPos(, , &hwnd)
    if !hwnd {
        return
    }
    mwm.FloatWindow(hwnd)
    PostMessage(WM_SYSCOMMAND, SC_MOVE, , , "ahk_id" hwnd)
    PostMessage(WM_KEYDOWN, VK_LEFT, , , "ahk_id" hwnd)
    PostMessage(WM_KEYUP, VK_LEFT, , , "ahk_id" hwnd)
    PostMessage(WM_KEYDOWN, VK_RIGHT, , , "ahk_id" hwnd)
    PostMessage(WM_KEYUP, VK_RIGHT, , , "ahk_id" hwnd)
    KeyWait("vk01")
    Send("{vk01 Up}")
}

*vk02::{
    MouseGetPos(, , &hwnd)
    if !hwnd {
        return
    }
    mwm.FloatWindow(hwnd)
    PostMessage(WM_SYSCOMMAND, SC_SIZE, , , "ahk_id" hwnd)
    PostMessage(WM_KEYDOWN, VK_DOWN, , , "ahk_id" hwnd)
    PostMessage(WM_KEYUP, VK_DOWN, , , "ahk_id" hwnd)
    PostMessage(WM_KEYDOWN, VK_RIGHT, , , "ahk_id" hwnd)
    PostMessage(WM_KEYUP, VK_RIGHT, , , "ahk_id" hwnd)
    KeyWait("vk02")
    Send("{vk01 Up}")
}

#Hotif GetKeyState(mod1, "P") and GetKeyState("Shift", "P")

*1::mwm.SendToWorkspace(1)
*2::mwm.SendToWorkspace(2)
*3::mwm.SendToWorkspace(3)
*4::mwm.SendToWorkspace(4)
*5::mwm.SendToWorkspace(5)
*6::mwm.SendToWorkspace(6)
*7::mwm.SendToWorkspace(7)
*8::mwm.SendToWorkspace(8)
*9::mwm.SendToWorkspace(9)

*w::mwm.SendToMonitor("primary", -1)
*e::mwm.SendToMonitor("primary")
*r::mwm.SendToMonitor("primary", +1)

*j::mwm.SwapWindow("next")
*k::mwm.SwapWindow("previous")

*c::WinClose("A")
*q::ExitApp()

*Enter::OpenTerminal()
*Space::ResetLayout()

; ..........................................................................}}}

; Helper functions ........................................................{{{1

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

    current := mwm.Layout()
    next := cycle[Mod(m[current], cycle.Length) + 1]

    TrayTip("Set layout to " next)
    mwm.SetLayout(next)
}

ResetLayout() {
    defaults := mwm.Options

    mwm.SetLayout(defaults.layout)
    mwm.SetMasterSize(defaults.masterSize)
    mwm.SetMasterCount(defaults.masterCount)
    mwm.SetPadding(defaults.padding)
    mwm.SetSpacing(defaults.spacing)
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
