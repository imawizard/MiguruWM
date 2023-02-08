#Requires AutoHotkey v2.0
#SingleInstance force
#WinActivateForce
A_MaxHotkeysPerInterval := 1000
KeyHistory(0), ListLines(false), ProcessSetPriority("H")
A_IconTip := "見苦窓経営"

; Initial settings ........................................................{{{1

#include lib\miguru\miguru.ahk

;; Floating windows can be focused when iterating via FocusWindow, however, they
;; are not re-positioned or resized.
GroupAdd("MIGURU_AUTOFLOAT", "Microsoft Teams-Benachrichtigung ahk_exe Teams.exe")
GroupAdd("MIGURU_AUTOFLOAT", "Microsoft Teams-Notification ahk_exe Teams.exe")

;; Neither tile nor float these windows, ignore them.
GroupAdd("MIGURU_IGNORE", "Window Spy ahk_class AutoHotkeyGUI")

Miguru := MiguruWM({
    ;; defaults
    ;layout: "tall",
    ;masterSize: 0.5,
    ;masterCount: 1,
    ;padding: 0,
    ;spacing: 0,
    ;tilingInsertion: "before-mru",

    ;; Float windows that are smaller in at least one of these aspects.
    tilingMinWidth: 200,
    tilingMinHeight: 200,

    ;; Insert new tiled windows as master. Possible are first, last, before-mru
    ;; and after-mru (most recently used tile).
    tilingInsertion: "first",

    ;; Place floating windows above tiled ones.
    floatingAlwaysOnTop: true,

    ;; Maximize windows in monocle layout.
    nativeMaximize: true,
})

;; Set the current workspace's padding/spacing.
Miguru.SetPadding(22)
Miguru.SetSpacing(12)

;; Show only columns by using the wide-layout with zero masters.
;; (likewise the wide-layout with zero masters results in just rows)
Miguru.SetLayout("wide")
Miguru.SetMasterCount(0)

;; Possibly create and rename a virtual desktop.
Miguru.VD.EnsureDesktops(7)
Miguru.VD.RenameDesktop("Browser", 7)

;..........................................................................}}}

; Right Alt ..............................................................{{{1

#Hotif GetKeyState("RAlt", "P") and !GetKeyState("Shift", "P")

*1::Miguru.FocusWorkspace(1)
*2::Miguru.FocusWorkspace(2)
*3::Miguru.FocusWorkspace(3)
*4::Miguru.FocusWorkspace(4)
*5::Miguru.FocusWorkspace(5)

*j::Miguru.FocusWindow("next")
*k::Miguru.FocusWindow("previous")
*m::Miguru.FocusWindow("master")

*h::Miguru.SetMasterSize(, -0.01)
*l::Miguru.SetMasterSize(, +0.01)

*w::Miguru.FocusMonitor("primary", -1)
*e::Miguru.FocusMonitor("primary")
*r::Miguru.FocusMonitor("primary", +1)

*,::Miguru.SetMasterCount(, +1)
*.::Miguru.SetMasterCount(, -1)

*t::Miguru.FloatWindow(, "toggle")
*Enter::Miguru.SwapWindow("master")
*c::OpenTaskView()
*q::Reload()

*F1::Miguru.SetPadding(, -1)
*F2::Miguru.SetPadding(, +1)
*F3::Miguru.SetSpacing(, -1)
*F4::Miguru.SetSpacing(, +1)

;..........................................................................}}}

; Right Alt (Shifted) ....................................................{{{1

#Hotif GetKeyState("RAlt", "P") and GetKeyState("Shift", "P")

*1::Miguru.SendToWorkspace(1)
*2::Miguru.SendToWorkspace(2)
*3::Miguru.SendToWorkspace(3)
*4::Miguru.SendToWorkspace(4)
*5::Miguru.SendToWorkspace(5)

*j::Miguru.SwapWindow("next")
*k::Miguru.SwapWindow("previous")

*w::Miguru.SendToMonitor("primary", -1)
*e::Miguru.SendToMonitor("primary")
*r::Miguru.SendToMonitor("primary", +1)

*Space::CycleLayouts()
*Enter::OpenTerminal()
*c::WinClose("A")
*q::ExitApp()

;..........................................................................}}}

#Hotif

+vk01::{
    MouseGetPos(, , &hwnd)
    if !hwnd {
        return
    }
    Miguru.FloatWindow(hwnd)
    PostMessage(WM_SYSCOMMAND, SC_MOVE, , , "ahk_id" hwnd)
    PostMessage(WM_KEYDOWN, VK_LEFT, , , "ahk_id" hwnd)
    PostMessage(WM_KEYUP, VK_LEFT, , , "ahk_id" hwnd)
    PostMessage(WM_KEYDOWN, VK_RIGHT, , , "ahk_id" hwnd)
    PostMessage(WM_KEYUP, VK_RIGHT, , , "ahk_id" hwnd)
    KeyWait("vk01")
    Send("{vk01 Up}")
}

+vk02::{
    MouseGetPos(, , &hwnd)
    if !hwnd {
        return
    }
    Miguru.FloatWindow(hwnd)
    PostMessage(WM_SYSCOMMAND, SC_SIZE, , , "ahk_id" hwnd)
    PostMessage(WM_KEYDOWN, VK_DOWN, , , "ahk_id" hwnd)
    PostMessage(WM_KEYUP, VK_DOWN, , , "ahk_id" hwnd)
    PostMessage(WM_KEYDOWN, VK_RIGHT, , , "ahk_id" hwnd)
    PostMessage(WM_KEYUP, VK_RIGHT, , , "ahk_id" hwnd)
    KeyWait("vk02")
    Send("{vk01 Up}")
}

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
        "monocle",
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
