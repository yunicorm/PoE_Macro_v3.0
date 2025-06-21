; ==============================================================================
; オーバーレイGUI作成モジュール
; ==============================================================================

; --- GUI変数のグローバル宣言（すべてのGUI変数を事前に宣言） ---
global MacroStatus_Text
global Adrenaline_Text, Adrenaline_Progress
global Tincture_Text, Tincture_Progress
global GoldFlask_Text, GoldFlask_Progress
global SkillB_Text, SkillB_Progress, SkillB_Exert
global SkillL_Text, SkillL_Progress, SkillL_Exert
global SkillK_Text, SkillK_Progress, SkillK_Exert
global SkillO_Text, SkillO_Progress, SkillO_Exert
global SkillN_Text, SkillN_Progress, SkillN_Exert
global SkillT_Text, SkillT_Progress, SkillT_Exert

; --- ①マクロ状態表示GUI ---
CreateMacroStatusGUI(x, y) {
    global overlayGUIs
    
    ; 既存のGUIを破棄（個別の破棄のみ）
    Gui, MacroStatus:Destroy
    
    Gui, MacroStatus:+AlwaysOnTop -Caption +ToolWindow +E0x20
    Gui, MacroStatus:Color, 000000
    Gui, MacroStatus:Font, s14 cFF0000 Bold, Arial  ; 初期状態は赤
    Gui, MacroStatus:Add, Text, x10 y5 w100 h25 Center vMacroStatus_Text, マクロOFF
    
    Gui, MacroStatus:Show, NoActivate x%x% y%y% w120 h35
    
    ; 透明度設定
    WinSet, TransColor, 000000, MacroStatus
    WinSet, Transparent, 240, MacroStatus
    
    overlayGUIs["MacroStatus"] := "MacroStatus"
}

; --- ②アドレナリンGUI ---
CreateAdrenalineGUI(x, y) {
    global overlayGUIs
    
    ; 既存のGUIを破棄（個別の破棄のみ）
    Gui, Adrenaline:Destroy
    
    Gui, Adrenaline:+AlwaysOnTop -Caption +ToolWindow +E0x20
    Gui, Adrenaline:Color, 000000
    
    ; アイコン
    iconPath := A_ScriptDir . "\icons\adrenaline.png"
    if (FileExist(iconPath)) {
        Gui, Adrenaline:Add, Picture, x5 y5 w64 h64, %iconPath%
    } else {
        Gui, Adrenaline:Font, s20 cFFFFFF Bold, Arial
        Gui, Adrenaline:Add, Text, x5 y5 w64 h64 Center, A
    }
    
    ; テキスト
    Gui, Adrenaline:Font, s10 cFFFFFF Bold, Arial
    Gui, Adrenaline:Add, Text, x5 y72 w74 h20 Center vAdrenaline_Text, Ready
    
    ; プログレスバー
    Gui, Adrenaline:Add, Progress, x5 y95 w74 h8 c00FF00 Background333333 vAdrenaline_Progress, 100
    
    Gui, Adrenaline:Show, NoActivate x%x% y%y% w84 h108 Hide
    
    ; 透明度設定
    WinSet, TransColor, 000000, Adrenaline
    WinSet, Transparent, 240, Adrenaline
    
    overlayGUIs["Adrenaline"] := "Adrenaline"
}

; --- ③Tincture GUI ---
CreateTinctureGUI(x, y) {
    global overlayGUIs
    
    ; 既存のGUIを破棄（個別の破棄のみ）
    Gui, Tincture:Destroy
    
    Gui, Tincture:+AlwaysOnTop -Caption +ToolWindow +E0x20
    Gui, Tincture:Color, 000000
    
    ; アイコン
    iconPath := A_ScriptDir . "\icons\tincture.png"
    if (FileExist(iconPath)) {
        Gui, Tincture:Add, Picture, x5 y5 w64 h64, %iconPath%
    } else {
        Gui, Tincture:Font, s20 cFFFFFF Bold, Arial
        Gui, Tincture:Add, Text, x5 y5 w64 h64 Center, T
    }
    
    ; テキスト
    Gui, Tincture:Font, s10 cFFFFFF Bold, Arial
    Gui, Tincture:Add, Text, x5 y72 w74 h20 Center vTincture_Text, Deactive
    
    ; プログレスバー
    Gui, Tincture:Add, Progress, x5 y95 w74 h8 c00FF00 Background333333 vTincture_Progress, 0
    
    Gui, Tincture:Show, NoActivate x%x% y%y% w84 h108 Hide
    
    ; 透明度設定
    WinSet, TransColor, 000000, Tincture
    WinSet, Transparent, 240, Tincture
    
    overlayGUIs["Tincture"] := "Tincture"
}

; --- ④Gold Flask GUI ---
CreateGoldFlaskGUI(x, y) {
    global overlayGUIs
    
    ; 既存のGUIを破棄（個別の破棄のみ）
    Gui, GoldFlask:Destroy
    
    Gui, GoldFlask:+AlwaysOnTop -Caption +ToolWindow +E0x20
    Gui, GoldFlask:Color, 000000
    
    ; アイコン
    iconPath := A_ScriptDir . "\icons\gold_flask.png"
    if (FileExist(iconPath)) {
        Gui, GoldFlask:Add, Picture, x5 y5 w64 h64, %iconPath%
    } else {
        Gui, GoldFlask:Font, s20 cFFFFFF Bold, Arial
        Gui, GoldFlask:Add, Text, x5 y5 w64 h64 Center, G
    }
    
    ; テキスト
    Gui, GoldFlask:Font, s10 cFFFFFF Bold, Arial
    Gui, GoldFlask:Add, Text, x5 y72 w74 h20 Center vGoldFlask_Text, Ready
    
    ; プログレスバー
    Gui, GoldFlask:Add, Progress, x5 y95 w74 h8 c00FF00 Background333333 vGoldFlask_Progress, 100
    
    Gui, GoldFlask:Show, NoActivate x%x% y%y% w84 h108 Hide
    
    ; 透明度設定
    WinSet, TransColor, 000000, GoldFlask
    WinSet, Transparent, 240, GoldFlask
    
    overlayGUIs["GoldFlask"] := "GoldFlask"
}

; --- スキルGUI作成の補助関数 ---
CreateSkillGUIBase(name, x, y, iconFile, skillKey) {
    global overlayGUIs, enableExertCounter, warcryExertCounts
    global exertCountFontSize, exertCountOffsetX, exertCountOffsetY
    
    ; 既存のGUIを破棄（個別の破棄のみ）
    Gui, %name%:Destroy
    
    Gui, %name%:+AlwaysOnTop -Caption +ToolWindow +E0x20
    Gui, %name%:Color, 000000
    
    ; アイコン
    iconPath := A_ScriptDir . "\icons\" . iconFile
    if (FileExist(iconPath)) {
        Gui, %name%:Add, Picture, x5 y5 w64 h64, %iconPath%
    } else {
        Gui, %name%:Font, s20 cFFFFFF Bold, Arial
        Gui, %name%:Add, Text, x5 y5 w64 h64 Center, %skillKey%
    }
    
    ; Exertカウント表示（Warcryスキルのみ）
    if (IsObject(warcryExertCounts) && enableExertCounter && warcryExertCounts[skillKey] > 0) {
        ; 背景となる黒い円
        Gui, %name%:Font, s24 c000000 Bold, Arial
        xPos := 5 + exertCountOffsetX - 2
        yPos := 5 + exertCountOffsetY - 2
        Gui, %name%:Add, Text, x%xPos% y%yPos% w34 h34 Center, ●
        
        ; Exertカウント数字
        Gui, %name%:Font, s%exertCountFontSize% cFFFF00 Bold, Arial
        xPos := 5 + exertCountOffsetX
        yPos := 5 + exertCountOffsetY
        Gui, %name%:Add, Text, x%xPos% y%yPos% w30 h30 Center BackgroundTrans v%name%_Exert, 0
    }
    
    ; テキスト
    Gui, %name%:Font, s10 cFFFFFF Bold, Arial
    defaultText := (skillKey = "O") ? "Guard" : "Ready"
    Gui, %name%:Add, Text, x5 y72 w74 h20 Center v%name%_Text, %defaultText%
    
    ; プログレスバー
    Gui, %name%:Add, Progress, x5 y95 w74 h8 c00FF00 Background333333 v%name%_Progress, 100
    
    Gui, %name%:Show, NoActivate x%x% y%y% w84 h108 Hide
    
    ; 透明度設定
    WinSet, TransColor, 000000, %name%
    WinSet, Transparent, 240, %name%
    
    overlayGUIs[name] := name
}

; --- 各スキルのGUI作成関数 ---
CreateSkillBGUI(x, y) {
    CreateSkillGUIBase("SkillB", x, y, "steel_skin.png", "B")
}

CreateSkillLGUI(x, y) {
    CreateSkillGUIBase("SkillL", x, y, "intimidating_cry.png", "L")
}

CreateSkillKGUI(x, y) {
    CreateSkillGUIBase("SkillK", x, y, "seismic_cry.png", "K")
}

CreateSkillOGUI(x, y) {
    CreateSkillGUIBase("SkillO", x, y, "enduring_cry.png", "O")
}

CreateSkillNGUI(x, y) {
    CreateSkillGUIBase("SkillN", x, y, "rallying_cry.png", "N")
}

CreateSkillTGUI(x, y) {
    CreateSkillGUIBase("SkillT", x, y, "order_to_me.png", "T")
}