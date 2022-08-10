#SingleInstance force
#UseHook on
#MaxHotkeysPerInterval 1000
#WinActivateForce

#NoEnv
#KeyHistory 0
ListLines, Off
SetBatchLines, -1
Process, Priority, , H

DetectHiddenWindows, On

#Include lib\miguru\miguru.ahk
Miguru := new MiguruWM()

log(fmt, args*) {
    s := Format(fmt, args*)
    FileAppend, %s% `n, *
}

; Right Alt ..............................................................{{{1

#if GetKeyState("RAlt", "P") and !GetKeyState("Shift", "P")

;; §  1  2  3  4  5  6  7  8  9  0  -  =
*sc29::Return
*sc02::Return
*sc03::Return
*sc04::Return
*sc05::Return
*sc06::Return
*sc07::Return
*sc08::Return
*sc09::Return
*sc0a::Return
*sc0b::Return
*sc0c::Return
*sc0d::Return
;; q  w  e  r  t  y  u  i  o  p  [  ]
*sc10::Return
*sc11::Return
*sc12::Return
*sc13::Return
*sc14::Return
*sc15::Return
*sc16::Return
*sc17::Send, #{Tab}
*sc18::Return
*sc19::Return
*sc1a::Return
*sc1b::Return
;; a  s  d  f  g  h  j  k  l  ;  '  \
*sc1e::Miguru.FocusWorkspace(1)
*sc1f::Miguru.FocusWorkspace(2)
*sc20::Miguru.FocusWorkspace(3)
*sc21::Miguru.FocusWorkspace(4)
*sc22::Miguru.FocusWorkspace(5)
*sc23::Return
*sc24::Return
*sc25::Return
*sc26::Return
*sc27::Return
*sc28::Return
*sc2b::Return
;; `  z  x  c  v  b  n  m  ,  .  /
*sc56::Return
*sc2c::Return
*sc2d::Return
*sc2e::Return
*sc2f::Return
*sc30::Return
*sc31::Return
*sc32::Return
*sc33::Return
*sc34::Return
*sc35::Return

;..........................................................................}}}

; Right Alt (Shifted) ....................................................{{{1

#if GetKeyState("RAlt", "P") and GetKeyState("Shift", "P")

;; §  1  2  3  4  5  6  7  8  9  0  -  =
*sc29::Return
*sc02::Return
*sc03::Return
*sc04::Return
*sc05::Return
*sc06::Return
*sc07::Return
*sc08::Return
*sc09::Return
*sc0a::Return
*sc0b::Return
*sc0c::Return
*sc0d::Return
;; q  w  e  r  t  y  u  i  o  p  [  ]
*sc10::Return
*sc11::Return
*sc12::Return
*sc13::Return
*sc14::Return
*sc15::Return
*sc16::Return
*sc17::Return
*sc18::Return
*sc19::Return
*sc1a::Return
*sc1b::Return
;; a  s  d  f  g  h  j  k  l  ;  '  \
*sc1e::Miguru.SendToWorkspace(1)
*sc1f::Miguru.SendToWorkspace(2)
*sc20::Miguru.SendToWorkspace(3)
*sc21::Miguru.SendToWorkspace(4)
*sc22::Miguru.SendToWorkspace(5)
*sc23::Return
*sc24::Return
*sc25::Return
*sc26::Return
*sc27::Return
*sc28::Return
*sc2b::Return
;; `  z  x  c  v  b  n  m  ,  .  /
*sc56::Return
*sc2c::Return
*sc2d::Return
*sc2e::Return
*sc2f::Return
*sc30::Return
*sc31::Return
*sc32::Return
*sc33::Return
*sc34::Return
*sc35::Return

;..........................................................................}}}

#if

F1::
    Reload
    TrayTip, MiguruWM, Reloaded
    Return
