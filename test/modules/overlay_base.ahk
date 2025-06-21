; ==============================================================================
; オーバーレイ基本機能モジュール
; ==============================================================================

; --- オーバーレイ用グローバル変数 ---
global overlayGUIs := {}
global overlayUpdateTimer := 50  ; 更新間隔(ms)
global manaBurnStacks := 0
global manaBurnLastUpdate := 0

; --- 既存のGUIを全て破棄する関数（先に定義） ---
DestroyAllGUIs() {
    ; 既知のGUI名を直接破棄
    try {
        Gui, MacroStatus:Destroy
    }
    try {
        Gui, Adrenaline:Destroy
    }
    try {
        Gui, Tincture:Destroy
    }
    try {
        Gui, GoldFlask:Destroy
    }
    try {
        Gui, SkillB:Destroy
    }
    try {
        Gui, SkillL:Destroy
    }
    try {
        Gui, SkillK:Destroy
    }
    try {
        Gui, SkillO:Destroy
    }
    try {
        Gui, SkillN:Destroy
    }
    try {
        Gui, SkillT:Destroy
    }
    
    ; overlayGUIsをクリア
    overlayGUIs := {}
}

; --- オーバーレイの初期化と表示 ---
InitializeOverlay() {
    global overlayOffsetX, overlayOffsetY, overlaySpacing
    global macroStatusOffsetX, macroStatusOffsetY
    global useSpecificMonitor, specificMonitorNumber
    
    ; 既存のGUIを破棄
    DestroyAllGUIs()
    
    ; マルチディスプレイ環境対応
    if (useSpecificMonitor) {
        ; 特定のモニターを使用（マルチディスプレイ環境用）
        SysGet, Mon, Monitor, %specificMonitorNumber%
    } else {
        ; Path of Exileのウィンドウがあるモニターを検出
        WinGetPos, gameX, gameY, gameWidth, gameHeight, ahk_exe PathOfExileSteam.exe
        
        if (gameX != "") {
            ; ゲームウィンドウの中心座標を計算
            gameCenterX := gameX + gameWidth/2
            
            ; どのモニターに表示されているか判定
            SysGet, MonitorCount, MonitorCount
            Loop, %MonitorCount% {
                SysGet, MonTemp, Monitor, %A_Index%
                if (gameCenterX >= MonTempLeft && gameCenterX <= MonTempRight) {
                    SysGet, Mon, Monitor, %A_Index%
                    break
                }
            }
        } else {
            ; ゲームが起動していない場合はプライマリモニターを使用
            SysGet, MonitorPrimary, MonitorPrimary
            SysGet, Mon, Monitor, %MonitorPrimary%
        }
    }
    
    ; モニターサイズを計算
    monitorWidth := MonRight - MonLeft
    monitorHeight := MonBottom - MonTop
    
    ; ①マクロ状態表示（独立した位置）
    macroX := MonLeft + macroStatusOffsetX
    macroY := MonBottom + macroStatusOffsetY
    CreateMacroStatusGUI(macroX, macroY)
    
    ; ②～⑩のオーバーレイを作成（画面左下）
    baseX := MonLeft + overlayOffsetX
    baseY := MonBottom + overlayOffsetY
    
    ; 各オーバーレイを作成
    CreateAdrenalineGUI(baseX, baseY)
    CreateTinctureGUI(baseX + overlaySpacing, baseY)
    CreateGoldFlaskGUI(baseX + overlaySpacing * 2, baseY)
    CreateSkillBGUI(baseX + overlaySpacing * 3, baseY)
    CreateSkillLGUI(baseX + overlaySpacing * 4, baseY)
    CreateSkillKGUI(baseX + overlaySpacing * 5, baseY)
    CreateSkillOGUI(baseX + overlaySpacing * 6, baseY)
    CreateSkillNGUI(baseX + overlaySpacing * 7, baseY)
    CreateSkillTGUI(baseX + overlaySpacing * 8, baseY)
    
    ; 初期状態を赤でOFF表示
    UpdateMacroStatus(false)
    
    ; 更新タイマーを開始
    SetTimer, UpdateOverlay, %overlayUpdateTimer%
}

; --- マクロ状態表示の更新 ---
UpdateMacroStatus(status) {
    try {
        if (status) {
            GuiControl, MacroStatus:+c00FF00, MacroStatus_Text
            GuiControl, MacroStatus:, MacroStatus_Text, マクロON
        } else {
            GuiControl, MacroStatus:+cFF0000, MacroStatus_Text
            GuiControl, MacroStatus:, MacroStatus_Text, マクロOFF
        }
    }
}

; --- オーバーレイの表示/非表示 ---
ShowOverlay() {
    global overlayGUIs
    
    for name, guiName in overlayGUIs {
        if (name != "MacroStatus") {  ; マクロ状態表示以外
            try {
                Gui, %guiName%:Show, NoActivate
            }
        }
    }
}

HideOverlay() {
    global overlayGUIs
    
    for name, guiName in overlayGUIs {
        if (name != "MacroStatus") {  ; マクロ状態表示以外
            try {
                Gui, %guiName%:Hide
            }
        }
    }
}

; --- オーバーレイの破棄 ---
DestroyOverlay() {
    SetTimer, UpdateOverlay, Off
    DestroyAllGUIs()
}