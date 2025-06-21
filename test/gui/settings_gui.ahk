; ==============================================================================
; 設定GUI基本モジュール v2.5 - 動的スキル管理対応
; ==============================================================================

; GUI用グローバル変数
global SettingsGUI := ""
global currentProfile := "default"
global unsavedChanges := false

; タブコントロール用
global TabControl := ""
global currentTab := ""

; GUI入力フィールド用変数（グローバル宣言）
global skillCooldown_L, skillCooldown_K, skillCooldown_O, skillCooldown_N
global warcryExert_L, warcryExert_K, warcryExert_O, warcryExert_N

; 動的スキル管理用変数（ListView版）
global WarcryListView, RegularListView

; ==============================================================================
; メイン設定ウィンドウ
; ==============================================================================

ShowSettingsGUI() {
    ; 動的スキル管理の初期化
    InitializeSkillDatabase()
    
    ; GUI変数の初期化（レガシー）
    skillCooldown_L := skillCooldowns.L
    skillCooldown_K := skillCooldowns.K
    skillCooldown_O := skillCooldowns.O
    skillCooldown_N := skillCooldowns.N
    
    warcryExert_L := warcryExertCounts.L
    warcryExert_K := warcryExertCounts.K
    warcryExert_O := warcryExertCounts.O
    warcryExert_N := warcryExertCounts.N
    
    ; 既存のGUIを破棄
    Gui, Settings:Destroy
    
    ; 新しいGUI作成
    Gui, Settings:New, +Resize, PoE Macro Settings v2.5 - %currentProfile%
    Gui, Settings:Font, s10
    
    ; メニューバー
    Menu, FileMenu, Add, &New Profile, MenuNewProfile
    Menu, FileMenu, Add, &Open Profile, MenuOpenProfile
    Menu, FileMenu, Add, &Save Profile, MenuSaveProfile
    Menu, FileMenu, Add, Save Profile &As..., MenuSaveProfileAs
    Menu, FileMenu, Add
    Menu, FileMenu, Add, E&xit, MenuExit
    
    Menu, HelpMenu, Add, &About, MenuAbout
    
    Menu, MenuBar, Add, &File, :FileMenu
    Menu, MenuBar, Add, &Help, :HelpMenu
    Gui, Settings:Menu, MenuBar
    
    ; タブコントロール（高さを調整）
    Gui, Settings:Add, Tab3, x10 y10 w780 h560 vTabControl, Flask Settings|Skill Settings|Chain Builder|Advanced
    
    ; ==================================================
    ; Tab 1: Flask Settings（変更なし）
    ; ==================================================
    Gui, Settings:Tab, 1
    
    ; フラスコ設定ヘッダー
    Gui, Settings:Font, s12 Bold
    Gui, Settings:Add, Text, x30 y50, Flask Configuration
    Gui, Settings:Font, s10 Normal
    
    ; Life Flask
    Gui, Settings:Add, GroupBox, x30 y80 w350 h100, Life Flask (Slot 1)
    Gui, Settings:Add, Text, x40 y105, Key:
    Gui, Settings:Add, Edit, x140 y100 w40 vkey_lifeFlask, %key_lifeFlask%
    Gui, Settings:Add, Text, x40 y135, Usage: Bound to Adrenaline combo
    Gui, Settings:Add, Text, x40 y155, (Triggered with R -> E -> 1)
    
    ; Sulphur Flask
    Gui, Settings:Add, GroupBox, x30 y190 w350 h120, Sulphur Flask (Slot 2)
    Gui, Settings:Add, Text, x40 y215, Key:
    Gui, Settings:Add, Edit, x140 y210 w40 vkey_sulphurFlask, %key_sulphurFlask%
    Gui, Settings:Add, Text, x40 y245, Min Interval (ms):
    Gui, Settings:Add, Edit, x140 y240 w60 vinterval_sulphur_min, %interval_sulphur_min%
    Gui, Settings:Add, Text, x210 y245, Max:
    Gui, Settings:Add, Edit, x240 y240 w60 vinterval_sulphur_max, %interval_sulphur_max%
    sulphurText := "Current: " . interval_sulphur_min . "-" . interval_sulphur_max . "ms"
    Gui, Settings:Add, Text, x40 y275, %sulphurText%
    
    ; Tincture
    Gui, Settings:Add, GroupBox, x400 y80 w350 h150, Tincture (Slot 3)
    Gui, Settings:Add, Text, x410 y105, Key:
    Gui, Settings:Add, Edit, x510 y100 w40 vkey_tincture, %key_tincture%
    Gui, Settings:Add, Text, x410 y135, Duration (ms):
    Gui, Settings:Add, Edit, x510 y130 w80 vduration_tincture, %duration_tincture%
    Gui, Settings:Add, Text, x410 y165, Cooldown Min (ms):
    Gui, Settings:Add, Edit, x510 y160 w60 vcooldown_tincture_min, %cooldown_tincture_min%
    Gui, Settings:Add, Text, x580 y165, Max:
    Gui, Settings:Add, Edit, x610 y160 w60 vcooldown_tincture_max, %cooldown_tincture_max%
    Gui, Settings:Add, Text, x410 y195, Mana Burn Rate:
    Gui, Settings:Add, Edit, x510 y190 w60 vmanaBurnStackRate, %manaBurnStackRate%
    Gui, Settings:Add, Text, x580 y195, ms/stack
    
    ; Gold Flask
    Gui, Settings:Add, GroupBox, x400 y240 w350 h120, Gold Flask (Slot 4)
    Gui, Settings:Add, Text, x410 y265, Key:
    Gui, Settings:Add, Edit, x510 y260 w40 vkey_goldFlask, %key_goldFlask%
    Gui, Settings:Add, Text, x410 y295, Min Interval (ms):
    Gui, Settings:Add, Edit, x510 y290 w60 vinterval_goldFlask_min, %interval_goldFlask_min%
    Gui, Settings:Add, Text, x580 y295, Max:
    Gui, Settings:Add, Edit, x610 y290 w60 vinterval_goldFlask_max, %interval_goldFlask_max%
    Gui, Settings:Add, Text, x410 y325, (Wine of the Prophet)
    
    ; Mana Flask
    Gui, Settings:Add, GroupBox, x30 y320 w350 h100, Mana Flask (Slot 5)
    Gui, Settings:Add, Text, x40 y345, Key:
    Gui, Settings:Add, Edit, x140 y340 w40 vkey_manaFlask, %key_manaFlask%
    Gui, Settings:Add, Text, x40 y375, Interval (ms):
    Gui, Settings:Add, Edit, x140 y370 w60 vinterval_manaFlask, %interval_manaFlask%
    Gui, Settings:Add, Text, x210 y375, (During Tincture)
    
    ; ==================================================
    ; Tab 2: Skill Settings（完全に新しい実装）
    ; ==================================================
    Gui, Settings:Tab, 2
    
    ; スキル設定ヘッダー
    Gui, Settings:Font, s12 Bold
    Gui, Settings:Add, Text, x30 y50, Dynamic Skill Configuration
    Gui, Settings:Font, s10 Normal
    
    ; Adrenaline Skills（既存のまま）
    Gui, Settings:Add, GroupBox, x30 y80 w350 h100, Adrenaline Combo (Fixed)
    Gui, Settings:Add, Text, x40 y105, First Key (Corrupting Fever):
    Gui, Settings:Add, Edit, x220 y100 w40 vkey_adrenaline_1, %key_adrenaline_1%
    Gui, Settings:Add, Text, x40 y135, Second Key (Blood Rage):
    Gui, Settings:Add, Edit, x220 y130 w40 vkey_adrenaline_2, %key_adrenaline_2%
    Gui, Settings:Add, Text, x40 y160, Chain: R -> E -> 1 (Life Flask)
    
    ; Skill T（固定）
    Gui, Settings:Add, GroupBox, x400 y80 w350 h100, Skill T (Fixed)
    Gui, Settings:Add, Text, x410 y105, Key:
    Gui, Settings:Add, Edit, x470 y100 w40 vkey_skill_T, %key_skill_T%
    Gui, Settings:Add, Text, x410 y135, Min Interval:
    Gui, Settings:Add, Edit, x470 y130 w60 vinterval_skill_T_min, %interval_skill_T_min%
    Gui, Settings:Add, Text, x540 y135, Max:
    Gui, Settings:Add, Edit, x600 y130 w60 vinterval_skill_T_max, %interval_skill_T_max%
    
    ; 動的Warcry管理
    CreateWarcryManagementUI(30, 190)
    
    ; 動的Regular Skills管理（Y座標を調整）  
    CreateRegularSkillsManagementUI(30, 370)
    
    ; ==================================================
    ; Tab 3: Chain Builder（変更なし）
    ; ==================================================
    Gui, Settings:Tab, 3
    
    Gui, Settings:Font, s12 Bold
    Gui, Settings:Add, Text, x30 y50, Chain Builder (Coming Soon)
    Gui, Settings:Font, s10 Normal
    
    Gui, Settings:Add, Text, x30 y90, This feature will allow you to create custom skill chains visually.
    Gui, Settings:Add, Text, x30 y110, Currently, the Adrenaline combo (R -> E -> 1) is hardcoded.
    
    ; プレビュー
    Gui, Settings:Add, GroupBox, x30 y150 w720 h300, Current Chains
    Gui, Settings:Add, Text, x40 y180, 1. Adrenaline Combo:
    Gui, Settings:Add, Text, x60 y200, - Press R (Corrupting Fever)
    Gui, Settings:Add, Text, x60 y220, - Wait 50ms
    Gui, Settings:Add, Text, x60 y240, - Press E (Blood Rage)  
    Gui, Settings:Add, Text, x60 y260, - Wait 50-70ms (random)
    Gui, Settings:Add, Text, x60 y280, - Press 1 (Life Flask)
    Gui, Settings:Add, Text, x60 y300, - Repeat every ~28.6 seconds
    
    ; ==================================================
    ; Tab 4: Advanced（変更なし）
    ; ==================================================
    Gui, Settings:Tab, 4
    
    Gui, Settings:Font, s12 Bold
    Gui, Settings:Add, Text, x30 y50, Advanced Settings
    Gui, Settings:Font, s10 Normal
    
    ; GUI Settings
    Gui, Settings:Add, GroupBox, x30 y80 w350 h120, GUI Settings
    Gui, Settings:Add, Text, x40 y105, Notification Duration (ms):
    Gui, Settings:Add, Edit, x200 y100 w80 vnotification_duration, %notification_duration%
    
    ; Overlay Settings
    Gui, Settings:Add, GroupBox, x400 y80 w350 h200, Overlay Settings
    Gui, Settings:Add, Text, x410 y105, Skills/Flask Position:
    Gui, Settings:Add, Text, x410 y125, X Offset:
    Gui, Settings:Add, Edit, x470 y120 w60 voverlayOffsetX, %overlayOffsetX%
    Gui, Settings:Add, Text, x540 y125, Y Offset:
    Gui, Settings:Add, Edit, x600 y120 w60 voverlayOffsetY, %overlayOffsetY%
    Gui, Settings:Add, Text, x410 y155, Spacing:
    Gui, Settings:Add, Edit, x470 y150 w60 voverlaySpacing, %overlaySpacing%
    
    Gui, Settings:Add, Text, x410 y185, Macro Status Position:
    Gui, Settings:Add, Text, x410 y205, X Offset:
    Gui, Settings:Add, Edit, x470 y200 w60 vmacroStatusOffsetX, %macroStatusOffsetX%
    Gui, Settings:Add, Text, x540 y205, Y Offset:
    Gui, Settings:Add, Edit, x600 y200 w60 vmacroStatusOffsetY, %macroStatusOffsetY%
    
    ; Multi-Monitor
    monitorChecked := useSpecificMonitor ? "Checked" : ""
    Gui, Settings:Add, CheckBox, x410 y240 w200 vuseSpecificMonitor %monitorChecked%, Use Specific Monitor
    Gui, Settings:Add, Text, x410 y265, Monitor Number:
    Gui, Settings:Add, Edit, x510 y260 w40 vspecificMonitorNumber, %specificMonitorNumber%
    
    ; Debug
    Gui, Settings:Add, GroupBox, x30 y210 w350 h100, Debug
    debugChecked := debugMode ? "Checked" : ""
    Gui, Settings:Add, CheckBox, x40 y235 w200 vdebugMode %debugChecked%, Enable Debug Mode
    Gui, Settings:Add, Text, x40 y260, When enabled:
    Gui, Settings:Add, Text, x40 y280, - F11: Dump variables
    Gui, Settings:Add, Text, x40 y295, - Ctrl+F11: Show debug overlay
    
    ; ==================================================
    ; Bottom buttons (全タブ共通) - 位置調整
    ; ==================================================
    Gui, Settings:Tab
    
    Gui, Settings:Add, Button, x250 y580 w100 h30 gApplySettings, Apply
    Gui, Settings:Add, Button, x360 y580 w100 h30 gSaveSettings Default, Save
    Gui, Settings:Add, Button, x470 y580 w100 h30 gCancelSettings, Cancel
    
    ; イベントハンドラー設定
    Gui, Settings:+OwnDialogs
    
    ; GUI表示（高さ調整）
    Gui, Settings:Show, w800 h620
    
    ; 変更検出用
    SetTimer, DetectChanges, 100
}

; ==============================================================================
; イベントハンドラー（改善版）
; ==============================================================================

ApplySettings() {
    ; データを収集
    CollectWarcryData()
    CollectRegularSkillData()
    
    ; バリデーション
    if (!ValidateSkillSettings()) {
        return
    }
    
    ; キー重複チェック
    if (!CheckKeyDuplication()) {
        return
    }
    
    ; 現在の設定を適用
    Gui, Settings:Submit, NoHide
    ApplyCurrentSettings()
    ApplyDynamicSkillSettings()
    
    ; 実行中の場合は動的に更新
    if (isRunning) {
        ; スキルキューを更新
        UpdateSkillQueueKeys()
        
        ; Regular Skillsのタイマーを再設定
        StopAllDynamicTimers()
        ExecuteDynamicRegularSkills()
    }
    
    MsgBox, 64, Success, Settings applied successfully!
}

SaveSettings() {
    ; データを収集
    CollectWarcryData()
    CollectRegularSkillData()
    
    ; バリデーション
    if (!ValidateSkillSettings()) {
        return
    }
    
    ; キー重複チェック
    if (!CheckKeyDuplication()) {
        return
    }
    
    ; 設定を適用して保存
    Gui, Settings:Submit, NoHide
    ApplyCurrentSettings()
    ApplyDynamicSkillSettings()
    SaveSettingsToFile()
    unsavedChanges := false
    
    ; 実行中の場合は動的に更新
    if (isRunning) {
        UpdateSkillQueueKeys()
        StopAllDynamicTimers()
        ExecuteDynamicRegularSkills()
    }
    
    MsgBox, 64, Success, Settings saved successfully!
}

CancelSettings() {
    if (unsavedChanges) {
        MsgBox, 52, Confirm, You have unsaved changes. Are you sure you want to close?
        IfMsgBox No
            return
    }
    Gui, Settings:Destroy
    SetTimer, DetectChanges, Off
}

SettingsGuiClose() {
    CancelSettings()
}

; ==============================================================================
; バリデーション関数
; ==============================================================================

ValidateSkillSettings() {
    errors := []
    
    ; Warcryの検証
    for index, skill in CurrentWarcries {
        if (skill.name = "") {
            errors.Push("Warcry " . index . ": Name is required")
        }
        if (skill.key = "") {
            errors.Push("Warcry " . index . ": Key is required")
        }
        
        ; 数値の範囲チェック
        if (skill.cooldown != "" && (skill.cooldown < 1000 || skill.cooldown > 10000)) {
            errors.Push("Warcry " . skill.name . ": Cooldown must be between 1000-10000ms")
        }
        if (skill.exert != "" && (skill.exert < 0 || skill.exert > 20)) {
            errors.Push("Warcry " . skill.name . ": Exert must be between 0-20")
        }
    }
    
    ; Regular Skillsの検証
    for index, skill in CurrentRegularSkills {
        if (skill.name = "") {
            errors.Push("Skill " . index . ": Name is required")
        }
        if (skill.key = "") {
            errors.Push("Skill " . index . ": Key is required")
        }
        
        ; 数値の範囲チェック
        if (skill.intervalMin != "" && (skill.intervalMin < 500 || skill.intervalMin > 60000)) {
            errors.Push("Skill " . skill.name . ": Min interval must be between 500-60000ms")
        }
        if (skill.intervalMax != "" && skill.intervalMin != "" && skill.intervalMax < skill.intervalMin) {
            errors.Push("Skill " . skill.name . ": Max interval must be >= Min interval")
        }
    }
    
    ; エラーがある場合は表示
    if (errors.Length() > 0) {
        msg := "Validation errors found:`n`n"
        for index, err in errors {
            msg .= "- " . err . "`n"
        }
        MsgBox, 48, Validation Error, %msg%
        return false
    }
    
    return true
}

; ==============================================================================
; メニューハンドラー（既存）
; ==============================================================================

MenuNewProfile() {
    InputBox, newProfile, New Profile, Enter profile name:,, 300, 130
    if (ErrorLevel || newProfile = "")
        return
    
    currentProfile := newProfile
    ResetToDefaults()
    Gui, Settings:Destroy
    ShowSettingsGUI()
}

MenuOpenProfile() {
    FileSelectFile, profilePath, 3,, Select Profile, JSON Files (*.json)
    if (ErrorLevel)
        return
    
    LoadProfileFromFile(profilePath)
}

MenuSaveProfile() {
    SaveSettings()
}

MenuSaveProfileAs() {
    FileSelectFile, profilePath, S16,, Save Profile As, JSON Files (*.json)
    if (ErrorLevel)
        return
    
    if (!InStr(profilePath, ".json"))
        profilePath .= ".json"
    
    SaveSettingsToFile(profilePath)
}

MenuExit() {
    CancelSettings()
}

MenuAbout() {
    aboutText := "PoE Macro Settings`nVersion 2.5`n`nDeveloped for Path of Exile`nChampion Build with Dynamic Skills"
    MsgBox, 64, About, %aboutText%
}

; ==============================================================================
; 補助関数（既存）
; ==============================================================================

ApplyCurrentSettings() {
    ; GUIから取得した値を実際の変数に適用
    Gui, Settings:Submit, NoHide
    
    ; レガシースキルキューの更新（互換性のため維持）
    ; これらは動的スキル管理で上書きされる
}

DetectChanges() {
    ; 変更検出（簡易版）
    static lastState := ""
    
    Gui, Settings:Submit, NoHide
    currentState := key_lifeFlask . key_sulphurFlask . key_tincture
    
    if (currentState != lastState && lastState != "") {
        unsavedChanges := true
        WinSetTitle, PoE Macro Settings v2.5 - %currentProfile%, , PoE Macro Settings v2.5 - %currentProfile%*
    }
    
    lastState := currentState
}

ResetToDefaults() {
    ; デフォルト値に戻す
    ; (実装は省略)
}