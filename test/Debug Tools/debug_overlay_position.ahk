; 現在のオーバーレイ位置をデバッグ
#NoEnv
#SingleInstance Force

; main.ahkと同じ設定値を読み込む
#Include %A_ScriptDir%\config\settings.ahk

; モニター情報取得（main.ahkと同じロジック）
SysGet, MonitorPrimary, MonitorPrimary  
SysGet, Mon, MonitorWorkArea, %MonitorPrimary%
monitorWidth := MonRight - MonLeft
monitorHeight := MonBottom - MonTop

; 位置計算（overlay.ahkと同じロジック）
totalWidth := overlaySpacing * 9
baseX := MonLeft + (monitorWidth - totalWidth) / 2 + overlayOffsetX
baseY := MonBottom + overlayOffsetY

; 結果表示
endX := baseX + totalWidth
overhang := (endX > MonRight) ? "右に" . (endX - MonRight) . "px" : "なし"

info := "【設定値】`n"
info .= "overlayOffsetX: " . overlayOffsetX . "`n"
info .= "overlayOffsetY: " . overlayOffsetY . "`n"
info .= "overlaySpacing: " . overlaySpacing . "`n`n"

info .= "【モニター情報】`n"
info .= "プライマリモニター番号: " . MonitorPrimary . "`n"
info .= "モニター範囲: (" . MonLeft . ", " . MonTop . ") ～ (" . MonRight . ", " . MonBottom . ")`n"
info .= "モニターサイズ: " . monitorWidth . " × " . monitorHeight . "`n`n"

info .= "【計算結果】`n"
info .= "オーバーレイ全体幅: " . totalWidth . "px`n"
info .= "開始位置: (" . baseX . ", " . baseY . ")`n"
info .= "終了位置: (" . endX . ", " . baseY . ")`n`n"

info .= "【診断】`n"
info .= "左端: " . baseX . " (モニター左端: " . MonLeft . ")`n"
info .= "右端: " . endX . " (モニター右端: " . MonRight . ")`n"
info .= "はみ出し: " . overhang

MsgBox, 0, デバッグ情報, %info%

; 実際に赤い枠で表示位置を示す
Gui, Debug:New, +AlwaysOnTop -Caption
Gui, Debug:Color, FF0000
Gui, Debug:Show, x%baseX% y%baseY% w%totalWidth% h108

; 中央に大きな矢印
centerX := baseX + totalWidth/2 - 50
centerY := baseY - 100
Gui, Arrow:New, +AlwaysOnTop -Caption
Gui, Arrow:Color, FFFF00
Gui, Arrow:Font, s30 Bold
Gui, Arrow:Add, Text,, ↓ここ↓
Gui, Arrow:Show, x%centerX% y%centerY%

MsgBox, 0,, 赤い枠がオーバーレイの表示位置です`n黄色い矢印が指している場所を確認してください`n`nOKを押すと終了します

ExitApp