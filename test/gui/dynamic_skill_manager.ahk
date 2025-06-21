; ==============================================================================
; 動的スキル管理モジュール（修正版）
; ==============================================================================

; スキルデータベース
global SkillDatabase := {}
global WarcrySkills := {}
global RegularSkills := {}
global CurrentWarcries := []
global CurrentRegularSkills := []

; ListView用グローバル変数
global WarcryListView := ""
global RegularListView := ""

; ダイアログ編集用インデックス
global editingIndex := 0

; ==============================================================================
; スキルデータベースの初期化
; ==============================================================================

InitializeSkillDatabase() {
    ; Warcryスキル
    WarcrySkills := {}
    
    skill := {}
    skill.name := "Intimidating Cry"
    skill.defaultKey := "L"
    skill.defaultCooldown := 5260
    skill.defaultExert := 3
    WarcrySkills["Intimidating Cry"] := skill
    
    skill := {}
    skill.name := "Seismic Cry"
    skill.defaultKey := "K"
    skill.defaultCooldown := 5260
    skill.defaultExert := 7
    WarcrySkills["Seismic Cry"] := skill
    
    skill := {}
    skill.name := "Enduring Cry"
    skill.defaultKey := "O"
    skill.defaultCooldown := 5260
    skill.defaultExert := 0
    WarcrySkills["Enduring Cry"] := skill
    
    skill := {}
    skill.name := "Rallying Cry"
    skill.defaultKey := "N"
    skill.defaultCooldown := 5260
    skill.defaultExert := 6
    WarcrySkills["Rallying Cry"] := skill
    
    skill := {}
    skill.name := "Ancestral Cry"
    skill.defaultKey := ""
    skill.defaultCooldown := 5260
    skill.defaultExert := 4
    WarcrySkills["Ancestral Cry"] := skill
    
    skill := {}
    skill.name := "General's Cry"
    skill.defaultKey := ""
    skill.defaultCooldown := 5260
    skill.defaultExert := 0
    WarcrySkills["General's Cry"] := skill
    
    skill := {}
    skill.name := "Infernal Cry"
    skill.defaultKey := ""
    skill.defaultCooldown := 5260
    skill.defaultExert := 0
    WarcrySkills["Infernal Cry"] := skill
    
    ; Regular Skills
    RegularSkills := {}
    
    skill := {}
    skill.name := "Blood Rage"
    skill.defaultKey := "E"
    skill.defaultInterval := 10000
    RegularSkills["Blood Rage"] := skill
    
    skill := {}
    skill.name := "Steel Skin"
    skill.defaultKey := "B"
    skill.defaultInterval := 3000
    RegularSkills["Steel Skin"] := skill
    
    skill := {}
    skill.name := "Molten Shell"
    skill.defaultKey := ""
    skill.defaultInterval := 3000
    RegularSkills["Molten Shell"] := skill
    
    skill := {}
    skill.name := "Immortal Call"
    skill.defaultKey := ""
    skill.defaultInterval := 3000
    RegularSkills["Immortal Call"] := skill
    
    skill := {}
    skill.name := "Vaal Molten Shell"
    skill.defaultKey := ""
    skill.defaultInterval := 4000
    RegularSkills["Vaal Molten Shell"] := skill
    
    skill := {}
    skill.name := "Berserk"
    skill.defaultKey := ""
    skill.defaultInterval := 5000
    RegularSkills["Berserk"] := skill
    
    skill := {}
    skill.name := "Phase Run"
    skill.defaultKey := ""
    skill.defaultInterval := 4000
    RegularSkills["Phase Run"] := skill
    
    ; 現在の設定を読み込み
    LoadCurrentSkills()
}

; ==============================================================================
; 現在のスキル設定を読み込み
; ==============================================================================

LoadCurrentSkills() {
    ; Warcries - 既存の設定から読み込み
    CurrentWarcries := []
    for key, data in skillCooldowns {
        warcryName := GetWarcryNameByKey(key)
        if (warcryName != "") {
            skill := {}
            skill.name := warcryName
            skill.key := key
            skill.cooldown := data
            skill.exert := warcryExertCounts[key]
            CurrentWarcries.Push(skill)
        }
    }
    
    ; Regular Skills - ハードコードされた既存スキルを読み込み
    CurrentRegularSkills := []
    
    ; Blood Rage
    if (key_bloodRage != "") {
        skill := {}
        skill.name := "Blood Rage"
        skill.key := key_bloodRage
        skill.intervalMin := interval_bloodRage_min
        skill.intervalMax := interval_bloodRage_max
        CurrentRegularSkills.Push(skill)
    }
    
    ; Skill B (Steel Skin)
    if (key_skill_B != "") {
        skill := {}
        skill.name := "Steel Skin"
        skill.key := key_skill_B
        skill.intervalMin := interval_skill_B_min
        skill.intervalMax := interval_skill_B_max
        CurrentRegularSkills.Push(skill)
    }
}

; ==============================================================================
; Warcryスキル管理UI（ListView版）
; ==============================================================================

CreateWarcryManagementUI(parentX, parentY) {
    ; グループボックス
    Gui, Settings:Add, GroupBox, x%parentX% y%parentY% w720 h170, Warcry Skills Management
    
    ; ListView作成
    listY := parentY + 20
    Gui, Settings:Add, ListView, x40 y%listY% w660 h120 vWarcryListView gWarcryListViewEvent, Name|Key|Cooldown|Exert
    
    ; ListViewの列幅を設定
    LV_ModifyCol(1, 300)  ; Name
    LV_ModifyCol(2, 80)   ; Key
    LV_ModifyCol(3, 120)  ; Cooldown
    LV_ModifyCol(4, 80)   ; Exert
    
    ; ボタン
    buttonY := parentY + 145
    Gui, Settings:Add, Button, x40 y%buttonY% w100 h25 gAddNewWarcryDialog, Add Warcry
    Gui, Settings:Add, Button, x150 y%buttonY% w100 h25 gEditWarcry, Edit Selected
    Gui, Settings:Add, Button, x260 y%buttonY% w100 h25 gRemoveWarcryFromList, Remove Selected
    
    ; 既存のデータをListViewに反映
    UpdateWarcryListView()
}

; ==============================================================================
; Regular Skills管理UI（ListView版）
; ==============================================================================

CreateRegularSkillsManagementUI(parentX, parentY) {
    ; グループボックス
    Gui, Settings:Add, GroupBox, x%parentX% y%parentY% w720 h170, Regular Skills Management
    
    ; ListView作成
    listY := parentY + 20
    Gui, Settings:Add, ListView, x40 y%listY% w660 h120 vRegularListView gRegularListViewEvent, Name|Key|Min Interval|Max Interval
    
    ; ListViewの列幅を設定
    LV_ModifyCol(1, 300)  ; Name
    LV_ModifyCol(2, 80)   ; Key
    LV_ModifyCol(3, 140)  ; Min Interval
    LV_ModifyCol(4, 140)  ; Max Interval
    
    ; ボタン
    buttonY := parentY + 145
    Gui, Settings:Add, Button, x40 y%buttonY% w100 h25 gAddNewRegularDialog, Add Skill
    Gui, Settings:Add, Button, x150 y%buttonY% w100 h25 gEditRegular, Edit Selected
    Gui, Settings:Add, Button, x260 y%buttonY% w100 h25 gRemoveRegularFromList, Remove Selected
    
    ; 既存のデータをListViewに反映
    UpdateRegularListView()
}

; ==============================================================================
; ListView更新関数
; ==============================================================================

UpdateWarcryListView() {
    Gui, Settings:Default
    Gui, ListView, WarcryListView
    LV_Delete()
    
    for index, skill in CurrentWarcries {
        LV_Add("", skill.name, skill.key, skill.cooldown, skill.exert)
    }
}

UpdateRegularListView() {
    Gui, Settings:Default
    Gui, ListView, RegularListView
    LV_Delete()
    
    for index, skill in CurrentRegularSkills {
        LV_Add("", skill.name, skill.key, skill.intervalMin, skill.intervalMax)
    }
}

; ==============================================================================
; ヘルパー関数
; ==============================================================================

GetWarcryList() {
    list := ""
    for name, data in WarcrySkills {
        list .= name . "|"
    }
    return RTrim(list, "|")
}

GetRegularSkillList() {
    list := ""
    for name, data in RegularSkills {
        list .= name . "|"
    }
    return RTrim(list, "|")
}

GetWarcryNameByKey(key) {
    warcryMap := {}
    warcryMap.L := "Intimidating Cry"
    warcryMap.K := "Seismic Cry"
    warcryMap.O := "Enduring Cry"
    warcryMap.N := "Rallying Cry"
    return warcryMap[key]
}

; ==============================================================================
; ダイアログ関数（修正版）
; ==============================================================================

ShowWarcryEditDialog(editIdx := 0) {
    global DialogWarcryName, DialogWarcryKey, DialogWarcryCooldown, DialogWarcryExert
    global editingIndex
    
    ; 編集インデックスを保存
    editingIndex := editIdx
    
    ; 編集モードの場合は既存の値を設定
    if (editingIndex > 0 && editingIndex <= CurrentWarcries.Length()) {
        skill := CurrentWarcries[editingIndex]
        defaultName := skill.name
        defaultKey := skill.key
        defaultCooldown := skill.cooldown
        defaultExert := skill.exert
    } else {
        defaultName := ""
        defaultKey := ""
        defaultCooldown := 5260
        defaultExert := 0
    }
    
    ; ダイアログ作成
    Gui, WarcryDialog:New, +OwnerSettings, % (editingIndex > 0 ? "Edit" : "Add") . " Warcry Skill"
    Gui, WarcryDialog:Add, Text, x10 y10, Name:
    Gui, WarcryDialog:Add, ComboBox, x100 y10 w200 vDialogWarcryName, % GetWarcryList()
    GuiControl, WarcryDialog:ChooseString, DialogWarcryName, %defaultName%
    
    Gui, WarcryDialog:Add, Text, x10 y40, Key:
    Gui, WarcryDialog:Add, Edit, x100 y40 w50 vDialogWarcryKey Limit1, %defaultKey%
    
    Gui, WarcryDialog:Add, Text, x10 y70, Cooldown:
    Gui, WarcryDialog:Add, Edit, x100 y70 w100 vDialogWarcryCooldown Number, %defaultCooldown%
    
    Gui, WarcryDialog:Add, Text, x10 y100, Exert:
    Gui, WarcryDialog:Add, Edit, x100 y100 w50 vDialogWarcryExert Number, %defaultExert%
    
    Gui, WarcryDialog:Add, Button, x60 y140 w80 gWarcryDialogOK, OK
    Gui, WarcryDialog:Add, Button, x160 y140 w80 gWarcryDialogCancel, Cancel
    
    Gui, WarcryDialog:Show, w310 h180
}

ShowRegularEditDialog(editIdx := 0) {
    global DialogRegularName, DialogRegularKey, DialogRegularMin, DialogRegularMax
    global editingIndex
    
    ; 編集インデックスを保存
    editingIndex := editIdx
    
    ; 編集モードの場合は既存の値を設定
    if (editingIndex > 0 && editingIndex <= CurrentRegularSkills.Length()) {
        skill := CurrentRegularSkills[editingIndex]
        defaultName := skill.name
        defaultKey := skill.key
        defaultMin := skill.intervalMin
        defaultMax := skill.intervalMax
    } else {
        defaultName := ""
        defaultKey := ""
        defaultMin := 3000
        defaultMax := 3100
    }
    
    ; ダイアログ作成
    Gui, RegularDialog:New, +OwnerSettings, % (editingIndex > 0 ? "Edit" : "Add") . " Regular Skill"
    Gui, RegularDialog:Add, Text, x10 y10, Name:
    Gui, RegularDialog:Add, ComboBox, x100 y10 w200 vDialogRegularName, % GetRegularSkillList()
    GuiControl, RegularDialog:ChooseString, DialogRegularName, %defaultName%
    
    Gui, RegularDialog:Add, Text, x10 y40, Key:
    Gui, RegularDialog:Add, Edit, x100 y40 w50 vDialogRegularKey Limit1, %defaultKey%
    
    Gui, RegularDialog:Add, Text, x10 y70, Min Interval:
    Gui, RegularDialog:Add, Edit, x100 y70 w100 vDialogRegularMin Number, %defaultMin%
    
    Gui, RegularDialog:Add, Text, x10 y100, Max Interval:
    Gui, RegularDialog:Add, Edit, x100 y100 w100 vDialogRegularMax Number, %defaultMax%
    
    Gui, RegularDialog:Add, Button, x60 y140 w80 gRegularDialogOK, OK
    Gui, RegularDialog:Add, Button, x160 y140 w80 gRegularDialogCancel, Cancel
    
    Gui, RegularDialog:Show, w310 h180
}

; ==============================================================================
; イベントハンドラー
; ==============================================================================

RemoveWarcryAtIndex(index) {
    if (index <= CurrentWarcries.Length()) {
        CurrentWarcries.RemoveAt(index)
        UpdateWarcryListView()
    }
}

RemoveRegularAtIndex(index) {
    if (index <= CurrentRegularSkills.Length()) {
        CurrentRegularSkills.RemoveAt(index)
        UpdateRegularListView()
    }
}

; ==============================================================================
; データ収集関数
; ==============================================================================

CollectWarcryData() {
    ; ListViewから現在の設定を収集（既にCurrentWarcries配列に保存されている）
    ; 追加の処理は不要
}

CollectRegularSkillData() {
    ; ListViewから現在の設定を収集（既にCurrentRegularSkills配列に保存されている）
    ; 追加の処理は不要
}

; ==============================================================================
; 設定適用関数
; ==============================================================================

ApplyDynamicSkillSettings() {
    ; Warcryデータを収集
    CollectWarcryData()
    CollectRegularSkillData()
    
    ; グローバル変数をクリア
    skillCooldowns := {}
    warcryExertCounts := {}
    
    ; Warcry設定を適用
    for index, skill in CurrentWarcries {
        skillCooldowns[skill.key] := skill.cooldown
        warcryExertCounts[skill.key] := skill.exert
    }
    
    ; Regular Skills設定を適用
    for index, skill in CurrentRegularSkills {
        if (skill.name = "Blood Rage") {
            key_bloodRage := skill.key
            interval_bloodRage_min := skill.intervalMin
            interval_bloodRage_max := skill.intervalMax
        } else if (InStr(skill.name, "Steel Skin") || InStr(skill.name, "Molten Shell") || InStr(skill.name, "Immortal Call")) {
            key_skill_B := skill.key
            interval_skill_B_min := skill.intervalMin
            interval_skill_B_max := skill.intervalMax
        }
    }
    
    ; スキルキューを更新
    UpdateSkillQueueKeys()
}

; ==============================================================================
; キー重複チェック関数
; ==============================================================================

CheckKeyDuplication() {
    ; すべてのキーを収集
    usedKeys := {}
    duplicates := []
    
    ; Warcryキーをチェック
    for index, skill in CurrentWarcries {
        if (skill.key != "") {
            if (usedKeys.HasKey(skill.key)) {
                duplicates.Push(skill.key . " is used by both " . usedKeys[skill.key] . " and " . skill.name)
            } else {
                usedKeys[skill.key] := skill.name
            }
        }
    }
    
    ; Regular Skillキーをチェック
    for index, skill in CurrentRegularSkills {
        if (skill.key != "") {
            if (usedKeys.HasKey(skill.key)) {
                duplicates.Push(skill.key . " is used by both " . usedKeys[skill.key] . " and " . skill.name)
            } else {
                usedKeys[skill.key] := skill.name
            }
        }
    }
    
    ; 固定スキルもチェック
    if (key_adrenaline_1 != "") {
        if (usedKeys.HasKey(key_adrenaline_1)) {
            duplicates.Push(key_adrenaline_1 . " is used by both " . usedKeys[key_adrenaline_1] . " and Adrenaline 1")
        }
    }
    
    if (key_adrenaline_2 != "") {
        if (usedKeys.HasKey(key_adrenaline_2)) {
            duplicates.Push(key_adrenaline_2 . " is used by both " . usedKeys[key_adrenaline_2] . " and Adrenaline 2")
        }
    }
    
    if (key_skill_T != "") {
        if (usedKeys.HasKey(key_skill_T)) {
            duplicates.Push(key_skill_T . " is used by both " . usedKeys[key_skill_T] . " and Skill T")
        }
    }
    
    ; 重複があった場合は警告
    if (duplicates.Length() > 0) {
        msg := "Key duplication detected:`n`n"
        for index, dup in duplicates {
            msg .= "- " . dup . "`n"
        }
        msg .= "`nPlease fix before saving."
        MsgBox, 48, Warning, %msg%
        return false
    }
    
    return true
}