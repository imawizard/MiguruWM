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

tall := TallLayout()
wide := WideLayout()
fullscreen := FullscreenLayout({ nativeMaximize: false })
floating := FloatingLayout()
columns := WideLayout({ displayName: "Columns", masterCountMax: 0 })
rows := TallLayout({ displayName: "Rows", masterCountMax: 0 })
threecolumn := ThreeColumnLayout()
twopane := TwoPaneLayout()
spiral := SpiralLayout()

mwm := { __Call: (name, params*) => } ; Ignore requests while mwm isn't ready yet
mwm := MiguruWM({
    layout: tall,
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

    focusFollowsMouse: false,
    mouseFollowsFocus: false,

    followWindowToWorkspace: false,
    followWindowToMonitor: false,

    focusWorkspaceByWindow: false,

    delays: {
        retryManage: 100,
        windowHidden: 400,
        onDisplayChange: 1000,
        sendMonitorRetile: 100,
        retile2ndTime: 200,
    },

    showPopup: (text, opts) => Popup(text, opts),
})

MiguruWM.SetupTrayMenu()

mod1 := "Alt"

; Keybindings .............................................................{{{1

#Hotif GetKeyState(mod1, "P") and !GetKeyState("Shift", "P")

*1::mwm.Do("focus-workspace", { workspace: 1 })
*2::mwm.Do("focus-workspace", { workspace: 2 })
*3::mwm.Do("focus-workspace", { workspace: 3 })
*4::mwm.Do("focus-workspace", { workspace: 4 })
*5::mwm.Do("focus-workspace", { workspace: 5 })
*6::mwm.Do("focus-workspace", { workspace: 6 })
*7::mwm.Do("focus-workspace", { workspace: 7 })
*8::mwm.Do("focus-workspace", { workspace: 8 })
*9::mwm.Do("focus-workspace", { workspace: 9 })

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

*t::mwm.Do("float-window", { value: false })
*p::OpenSearch()
*q::Reload()

*Enter::mwm.Do("swap-window", { with: "master" })
*Space::mwm.Do("cycle-layout", { value: [tall, fullscreen, wide, floating, columns, rows, threecolumn, twopane, spiral] })

*vk01::MoveActiveWindow()
*vk02::ResizeActiveWindow()

#Hotif GetKeyState(mod1, "P") and GetKeyState("Shift", "P")

*1::mwm.Do("send-to-workspace", { workspace: 1 })
*2::mwm.Do("send-to-workspace", { workspace: 2 })
*3::mwm.Do("send-to-workspace", { workspace: 3 })
*4::mwm.Do("send-to-workspace", { workspace: 4 })
*5::mwm.Do("send-to-workspace", { workspace: 5 })
*6::mwm.Do("send-to-workspace", { workspace: 6 })
*7::mwm.Do("send-to-workspace", { workspace: 7 })
*8::mwm.Do("send-to-workspace", { workspace: 8 })
*9::mwm.Do("send-to-workspace", { workspace: 9 })

*w::mwm.Do("send-to-monitor", { monitor: 1 })
*e::mwm.Do("send-to-monitor", { monitor: 2 })
*r::mwm.Do("send-to-monitor", { monitor: 3 })

*j::mwm.Do("swap-window", { with: "next"     })
*k::mwm.Do("swap-window", { with: "previous" })

*c::try WinClose("A")
*q::ExitApp()

*Enter::OpenTerminal()
*Space::ResetLayout()

; ..........................................................................}}}

; Helper functions ........................................................{{{1

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

MoveActiveWindow() {
    MouseGetPos(, , &hwnd)
    if !hwnd {
        return
    }
    WinActivate("ahk_id" hwnd)
    mwm.Do("float-window", { hwnd: hwnd, value: true })
    PostMessage(WM_SYSCOMMAND, SC_MOVE,  , , "ahk_id" hwnd)
    PostMessage(WM_KEYDOWN,    VK_LEFT,  , , "ahk_id" hwnd)
    PostMessage(WM_KEYUP,      VK_LEFT,  , , "ahk_id" hwnd)
    PostMessage(WM_KEYDOWN,    VK_RIGHT, , , "ahk_id" hwnd)
    PostMessage(WM_KEYUP,      VK_RIGHT, , , "ahk_id" hwnd)
    KeyWait("vk01")
    Send("{vk01 Up}")
}

ResizeActiveWindow() {
    MouseGetPos(, , &hwnd)
    if !hwnd {
        return
    }
    WinActivate("ahk_id" hwnd)
    mwm.Do("float-window", { hwnd: hwnd, value: true })
    PostMessage(WM_SYSCOMMAND, SC_SIZE,  , , "ahk_id" hwnd)
    PostMessage(WM_KEYDOWN,    VK_DOWN,  , , "ahk_id" hwnd)
    PostMessage(WM_KEYUP,      VK_DOWN,  , , "ahk_id" hwnd)
    PostMessage(WM_KEYDOWN,    VK_RIGHT, , , "ahk_id" hwnd)
    PostMessage(WM_KEYUP,      VK_RIGHT, , , "ahk_id" hwnd)
    KeyWait("vk02")
    Send("{vk01 Up}")
}

; ..........................................................................}}}
