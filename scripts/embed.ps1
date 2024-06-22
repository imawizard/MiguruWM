$ico = ".\assets\togepī.ico"
$ahk = ".\mwm.ahk"
$out = ".\build"

$ahk2exe = ![string]::IsNullOrEmpty($env:AHK2EXE) `
  ? $env:AHK2EXE                                  `
  : ".\autohotkey\Compiler\Ahk2Exe.exe"

$base = ![string]::IsNullOrEmpty($env:AHK_STUB) `
  ? $env:AHK_STUB                               `
  : ".\autohotkey\AutoHotkey64.exe"

$version = ![string]::IsNullOrEmpty($env:VERSION) `
  ? $env:VERSION                                  `
  : "$(git log -n1 --format='%h') (commit hash)"

New-Item -Type Directory $out -Force | Out-Null

(((Get-Content $ahk) -replace '^\s*#include (?:\*i )?(.+)$', {
  "#include $(Resolve-Path $_.Groups[1])"
}) -match '^\s*#include .+$'), "MIGURU_VERSION := `"$version`""
  | Join-String -Separator `n
  | Tee-Object -FilePath (Join-Path $out "autoload.ahk")

Copy-Item $ahk (Join-Path $out "$(Split-Path $ahk -LeafBase).ahk")

& $ahk2exe                                               `
  /base $base                                            `
  /icon $ico                                             `
  /in (Join-Path $out "autoload.ahk")                    `
  /resourceid "#2"                                       `
  /out (Join-Path $out "$(Split-Path $ahk -LeafBase).exe")
