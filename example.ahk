#Requires AutoHotkey v2.0-beta
#SingleInstance force
#UseHook true
A_MaxHotkeysPerInterval := 1000
#WinActivateForce

KeyHistory(0)
ListLines(false)
ProcessSetPriority("H")

DetectHiddenWindows(true)

#include lib\miguru\miguru.ahk
Miguru := MiguruWM()

log(fmt, args*) {
    s := Format(fmt, args*)
    FileAppend(s "`n", "*")
}

; Right Alt ..............................................................{{{1

#Hotif GetKeyState("RAlt", "P") and !GetKeyState("Shift", "P")

;; §  1  2  3  4  5  6  7  8  9  0  -  =
*sc29::
*sc02::
*sc03::
*sc04::
*sc05::
*sc06::
*sc07::
*sc08::
*sc09::
*sc0a::
*sc0b::
*sc0c::
*sc0d::
;; q  w  e  r  t  y  u  i  o  p  [  ]
*sc10::
*sc11::
*sc12::
*sc13::
*sc14::
*sc15::
*sc16::
*sc17::Send("#{Tab}")
*sc18::
*sc19::
*sc1a::
*sc1b::
;; a  s  d  f  g  h  j  k  l  ;  '  \
*sc1e::Miguru.FocusWorkspace(1)
*sc1f::Miguru.FocusWorkspace(2)
*sc20::Miguru.FocusWorkspace(3)
*sc21::Miguru.FocusWorkspace(4)
*sc22::Miguru.FocusWorkspace(5)
*sc23::
*sc24::
*sc25::
*sc26::
*sc27::
*sc28::
*sc2b::
;; `  z  x  c  v  b  n  m  ,  .  /
*sc56::
*sc2c::
*sc2d::
*sc2e::
*sc2f::
*sc30::
*sc31::
*sc32::
*sc33::
*sc34::
*sc35::

;..........................................................................}}}

; Right Alt (Shifted) ....................................................{{{1

#Hotif GetKeyState("RAlt", "P") and GetKeyState("Shift", "P")

;; §  1  2  3  4  5  6  7  8  9  0  -  =
*sc29::
*sc02::
*sc03::
*sc04::
*sc05::
*sc06::
*sc07::
*sc08::
*sc09::
*sc0a::
*sc0b::
*sc0c::
*sc0d::
;; q  w  e  r  t  y  u  i  o  p  [  ]
*sc10::
*sc11::
*sc12::
*sc13::
*sc14::
*sc15::
*sc16::
*sc17::
*sc18::
*sc19::
*sc1a::
*sc1b::
;; a  s  d  f  g  h  j  k  l  ;  '  \
*sc1e::Miguru.SendToWorkspace(1)
*sc1f::Miguru.SendToWorkspace(2)
*sc20::Miguru.SendToWorkspace(3)
*sc21::Miguru.SendToWorkspace(4)
*sc22::Miguru.SendToWorkspace(5)
*sc23::
*sc24::
*sc25::
*sc26::
*sc27::
*sc28::
*sc2b::
;; `  z  x  c  v  b  n  m  ,  .  /
*sc56::
*sc2c::
*sc2d::
*sc2e::
*sc2f::
*sc30::
*sc31::
*sc32::
*sc33::
*sc34::
*sc35::

;..........................................................................}}}

#Hotif

F1:: {
    Reload
    TrayTip("MiguruWM", "Reloaded")
}
