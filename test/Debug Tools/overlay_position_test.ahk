; オーバーレイ位置確認用スクリプト
#NoEnv
#SingleInstance Force

; 設定値（settings.ahkと同じ値を使用）
overlayOffsetX := 0      ; 水平方向のオフセット
overlayOffsetY := -200   ; 垂直方向のオフセット
overlaySpacing := 90     ; 各要素間の間隔

; 画面解像度を取得
SysGet, screenWidth, 78
SysGet, screenHeight, 79

MsgBox, 0, 画面情報, 画面解像度: %screenWidth% x %screenHeight%

; 位置計算
totalWidth := overlaySpacing * 9
baseX := (screenWidth - totalWidth) / 2 + overlayOffsetX
baseY := screenHeight + overlayOffsetY

; テスト用GUI作成
Gui, Test:New, +AlwaysOnTop -Caption +ToolWindow
Gui, Test:Color, FF0000  ; 赤色の背景
Gui, Test:Show, x%baseX% y%baseY% w%totalWidth% h108

MsgBox, 0, 位置確認, 赤い帯が表示されている位置がオーバーレイの表示位置です。`n`n現在の設定：`nX位置: %baseX%`nY位置: %baseY%`n幅: %totalWidth%`n`n調整が必要な場合は、settings.ahkの以下の値を変更してください：`n- overlayOffsetX（現在: %overlayOffsetX%）`n- overlayOffsetY（現在: %overlayOffsetY%）`n- overlaySpacing（現在: %overlaySpacing%）

; 個別の要素位置も表示
Gui, Test:Destroy

Loop, 9 {
    xPos := baseX + (A_Index - 1) * overlaySpacing
    Gui, Test%A_Index%:New, +AlwaysOnTop -Caption +ToolWindow
    Gui, Test%A_Index%:Color, 00FF00  ; 緑色
    Gui, Test%A_Index%:Font, s16 cBlack Bold
    Gui, Test%A_Index%:Add, Text, x0 y30 w84 h20 Center, %A_Index%
    Gui, Test%A_Index%:Show, x%xPos% y%baseY% w84 h108
}

; マクロ状態表示の位置
macroStatusX := baseX + (totalWidth / 2) - 60
macroStatusY := baseY - 60
Gui, MacroTest:New, +AlwaysOnTop -Caption +ToolWindow
Gui, MacroTest:Color, 0000FF  ; 青色
Gui, MacroTest:Font, s14 cWhite Bold
Gui, MacroTest:Add, Text, x10 y5 w100 h25 Center, マクロ状態
Gui, MacroTest:Show, x%macroStatusX% y%macroStatusY% w120 h35

MsgBox, 0, 個別要素確認, 各要素の位置を確認してください：`n- 青: マクロ状態表示`n- 緑: 1～9の各要素`n`n問題がある場合の調整方法：`n`n1. 全体が右すぎる → overlayOffsetXを負の値に`n2. 全体が左すぎる → overlayOffsetXを正の値に`n3. 全体が下すぎる → overlayOffsetYをより小さい負の値に`n4. 要素間隔が狭い → overlaySpacingを大きく`n5. 要素間隔が広い → overlaySpacingを小さく

ExitApp