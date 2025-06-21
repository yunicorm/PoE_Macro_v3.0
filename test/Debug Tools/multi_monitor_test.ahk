; マルチディスプレイ環境診断スクリプト
#NoEnv
#SingleInstance Force

; 全体の仮想画面情報
SysGet, VirtualScreenWidth, 78
SysGet, VirtualScreenHeight, 79
SysGet, VirtualScreenX, 76
SysGet, VirtualScreenY, 77

info := "=== 仮想画面全体 ===`n"
info .= "サイズ: " . VirtualScreenWidth . " x " . VirtualScreenHeight . "`n"
info .= "開始位置: (" . VirtualScreenX . ", " . VirtualScreenY . ")`n`n"

; モニター数とプライマリモニター
SysGet, MonitorCount, MonitorCount
SysGet, MonitorPrimary, MonitorPrimary
info .= "=== モニター情報 ===`n"
info .= "モニター数: " . MonitorCount . "`n"
info .= "プライマリモニター: " . MonitorPrimary . "`n`n"

; 各モニターの詳細情報
Loop, %MonitorCount% {
    SysGet, Mon, Monitor, %A_Index%
    SysGet, MonWork, MonitorWorkArea, %A_Index%
    
    width := MonRight - MonLeft
    height := MonBottom - MonTop
    workWidth := MonWorkRight - MonWorkLeft
    workHeight := MonWorkBottom - MonWorkTop
    
    info .= "--- モニター " . A_Index
    if (A_Index = MonitorPrimary)
        info .= " (プライマリ)"
    info .= " ---`n"
    info .= "位置: (" . MonLeft . ", " . MonTop . ") ～ (" . MonRight . ", " . MonBottom . ")`n"
    info .= "サイズ: " . width . " x " . height . "`n"
    info .= "作業領域: " . workWidth . " x " . workHeight . "`n`n"
}

; Path of Exileウィンドウ情報
WinGetPos, gameX, gameY, gameWidth, gameHeight, ahk_exe PathOfExileSteam.exe
if (gameX != "") {
    info .= "=== Path of Exile ウィンドウ ===`n"
    info .= "位置: (" . gameX . ", " . gameY . ")`n"
    info .= "サイズ: " . gameWidth . " x " . gameHeight . "`n"
    
    ; どのモニターに表示されているか判定
    centerX := gameX + gameWidth/2
    centerY := gameY + gameHeight/2
    
    Loop, %MonitorCount% {
        SysGet, Mon, Monitor, %A_Index%
        if (centerX >= MonLeft && centerX <= MonRight && centerY >= MonTop && centerY <= MonBottom) {
            info .= "表示モニター: " . A_Index . "`n"
            break
        }
    }
} else {
    info .= "=== Path of Exile ===`n"
    info .= "ゲームが起動していません`n"
}

; 推奨設定
info .= "`n=== 推奨オーバーレイ設定 ===`n"

if (MonitorPrimary = 2 && MonitorCount = 3) {
    ; 3モニター構成で中央がプライマリの場合
    SysGet, Mon2, Monitor, 2
    recommendedOffsetY := -200
    info .= "中央モニター検出（3440x1440）`n"
    info .= "推奨 overlayOffsetY: " . recommendedOffsetY . "`n"
} else {
    info .= "標準設定を使用してください`n"
}

; 結果表示
Gui, Result:New, +Resize
Gui, Result:Font, s10, Consolas
Gui, Result:Add, Edit, w800 h600 ReadOnly, %info%
Gui, Result:Show,, マルチディスプレイ環境診断

; テスト表示
MsgBox, 4,, 各モニターにテストマーカーを表示しますか？
IfMsgBox Yes
{
    Loop, %MonitorCount% {
        SysGet, Mon, Monitor, %A_Index%
        centerX := (MonLeft + MonRight) / 2 - 50
        centerY := (MonTop + MonBottom) / 2 - 25
        
        Gui, Test%A_Index%:New, +AlwaysOnTop -Caption +ToolWindow
        Gui, Test%A_Index%:Color, FF0000
        Gui, Test%A_Index%:Font, s20 cWhite Bold
        Gui, Test%A_Index%:Add, Text, Center, モニター %A_Index%
        Gui, Test%A_Index%:Show, x%centerX% y%centerY% w100 h50
    }
    
    Sleep, 3000
    Loop, %MonitorCount% {
        Gui, Test%A_Index%:Destroy
    }
}

return

GuiClose:
ExitApp