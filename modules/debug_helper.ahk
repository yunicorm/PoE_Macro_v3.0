; ==============================================================================
; デバッグヘルパーモジュール
; ==============================================================================

; --- デバッグ情報表示GUI ---
CreateDebugOverlay() {
    global debugMode
    if (!debugMode) {
        return
    }
    
    Gui, DebugInfo:Destroy
    Gui, DebugInfo:+AlwaysOnTop -Caption +ToolWindow +E0x20
    Gui, DebugInfo:Color, 000000
    Gui, DebugInfo:Font, s10 cFFFF00, Consolas
    
    ; デバッグ情報表示エリア
    Gui, DebugInfo:Add, Text, x5 y5 w300 h200 vDebugInfo_Text, Debug Mode Active
    
    ; 画面右上に表示
    SysGet, Mon, Monitor, 1
    debugX := MonRight - 320
    debugY := MonTop + 20
    
    Gui, DebugInfo:Show, NoActivate x%debugX% y%debugY% w310 h210
    WinSet, TransColor, 000000, DebugInfo
    WinSet, Transparent, 200, DebugInfo
    
    ; 更新タイマー開始
    SetTimer, UpdateDebugInfo, 100
}

; --- デバッグ情報更新 ---
UpdateDebugInfo() {
    global isRunning, tinctureActive, isCasting
    global currentExertCounts, manaBurnStacks
    global lastRightClickTime
    
    debugText := "=== PoE Macro Debug Info ===`n"
    debugText .= "Status: " . (isRunning ? "RUNNING" : "STOPPED") . "`n"
    debugText .= "-----------------------------`n"
    
    ; Tincture状態
    debugText .= "Tincture: " . (tinctureActive ? "ACTIVE" : "INACTIVE") . "`n"
    debugText .= "Mana Burn: " . manaBurnStacks . " stacks`n"
    
    ; スキルキュー状態
    debugText .= "Casting: " . (isCasting ? "YES" : "NO") . "`n"
    
    ; 右クリックからの経過時間
    if (lastRightClickTime > 0) {
        elapsed := Round((A_TickCount - lastRightClickTime) / 1000, 1)
        debugText .= "Right Click: " . elapsed . "s ago`n"
    }
    
    ; Exertカウント
    debugText .= "-----------------------------`n"
    debugText .= "Exert Counts:`n"
    for key, count in currentExertCounts {
        debugText .= "  " . key . ": " . count . "`n"
    }
    
    GuiControl, DebugInfo:, DebugInfo_Text, %debugText%
}

; --- デバッグオーバーレイ破棄 ---
DestroyDebugOverlay() {
    SetTimer, UpdateDebugInfo, Off
    Gui, DebugInfo:Destroy
}

; --- 変数ダンプ関数 ---
DumpVariables() {
    global
    
    output := "=== Variable Dump ===`n"
    output .= FormatTime . "`n`n"
    
    ; 主要な状態変数
    output .= "[State Variables]`n"
    output .= "isRunning: " . isRunning . "`n"
    output .= "tinctureActive: " . tinctureActive . "`n"
    output .= "isCasting: " . isCasting . "`n"
    output .= "manaBurnStacks: " . manaBurnStacks . "`n`n"
    
    ; タイマー関連
    output .= "[Timer Variables]`n"
    output .= "lastAdrenalineTime: " . lastAdrenalineTime . "`n"
    output .= "lastGoldFlaskTime: " . lastGoldFlaskTime . "`n"
    output .= "lastSkillTTime: " . lastSkillTTime . "`n"
    output .= "lastSkillBTime: " . lastSkillBTime . "`n"
    output .= "tinctureLastUsedTime: " . tinctureLastUsedTime . "`n`n"
    
    ; スキルキュー
    output .= "[Skill Queue]`n"
    for key, nextTime in skillNextTime {
        remaining := nextTime - A_TickCount
        output .= key . ": " . (remaining > 0 ? Round(remaining/1000, 1) . "s" : "Ready") . "`n"
    }
    
    FileAppend, %output%`n`n, debug_dump.txt
    MsgBox, 0, Debug, Variables dumped to debug_dump.txt, 2
}

; --- パフォーマンス測定 ---
global perfTimers := {}

StartPerfTimer(name) {
    global perfTimers
    perfTimers[name] := A_TickCount
}

EndPerfTimer(name) {
    global perfTimers, debugMode
    
    if (!debugMode || !perfTimers[name]) {
        return
    }
    
    elapsed := A_TickCount - perfTimers[name]
    DebugLog("Performance: " . name . " took " . elapsed . "ms")
    perfTimers.Delete(name)
}

; --- ホットキー（デバッグモード時のみ有効） ---
#If (debugMode && WinActive("ahk_exe PathOfExileSteam.exe"))

; F11: 変数ダンプ
F11::DumpVariables()

; Ctrl+F11: デバッグオーバーレイ表示切替
^F11::
    if (WinExist("DebugInfo")) {
        DestroyDebugOverlay()
    } else {
        CreateDebugOverlay()
    }
return

#If