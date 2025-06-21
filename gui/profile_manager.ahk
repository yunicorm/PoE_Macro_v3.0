; ==============================================================================
; プロファイル管理モジュール v2.5 - 動的スキル対応
; ==============================================================================

; プロファイル保存先
global profilesPath := A_ScriptDir . "\profiles"

; プロファイル管理用変数の初期化
if (!IsObject(skillCooldowns)) {
    global skillCooldowns := {}
    skillCooldowns.L := 5260
    skillCooldowns.K := 5260
    skillCooldowns.O := 5260
    skillCooldowns.N := 5260
}
if (!IsObject(warcryExertCounts)) {
    global warcryExertCounts := {}
    warcryExertCounts.L := 3
    warcryExertCounts.K := 7
    warcryExertCounts.O := 0
    warcryExertCounts.N := 6
}

; ==============================================================================
; プロファイルの保存
; ==============================================================================

SaveSettingsToFile(filePath := "") {
    ; ファイルパスが指定されていない場合
    if (filePath = "") {
        filePath := profilesPath . "\" . currentProfile . ".json"
    }
    
    ; profilesフォルダが存在しない場合は作成
    if (!FileExist(profilesPath)) {
        FileCreateDir, %profilesPath%
    }
    
    ; 現在の設定をオブジェクトに格納
    profile := CreateProfileObject()
    
    ; JSONに変換
    jsonStr := JSON.Dump(profile, 4)  ; 4スペースインデント
    
    ; ファイルに保存
    FileDelete, %filePath%
    FileAppend, %jsonStr%, %filePath%, UTF-8
    
    return true
}

; ==============================================================================
; プロファイルの読み込み
; ==============================================================================

LoadProfileFromFile(filePath) {
    ; ファイルが存在しない場合
    if (!FileExist(filePath)) {
        MsgBox, 16, Error, Profile file not found: %filePath%
        return false
    }
    
    ; JSONファイルを読み込み
    FileRead, jsonStr, %filePath%
    
    ; JSONをパース
    try {
        profile := JSON.Load(jsonStr)
    } catch e {
        MsgBox, 16, Error, Failed to parse profile file: %e%
        return false
    }
    
    ; プロファイルを適用
    ApplyProfileObject(profile)
    
    ; プロファイル名を更新
    SplitPath, filePath, fileName, , , nameNoExt
    currentProfile := nameNoExt
    
    ; UIを更新（GUIが開いている場合）
    if (WinExist("PoE Macro Settings")) {
        Gui, Settings:Destroy
        ShowSettingsGUI()
    }
    
    return true
}

; ==============================================================================
; プロファイルオブジェクトの作成 v2.5
; ==============================================================================

CreateProfileObject() {
    profile := {}
    
    ; メタデータ
    profile.metadata := {}
    profile.metadata.profileName := currentProfile
    profile.metadata.version := "2.5"
    FormatTime, currentTime, , yyyy-MM-dd HH:mm:ss
    profile.metadata.modified := currentTime
    profile.metadata.game := "Path of Exile"
    profile.metadata.build := "Champion with Dynamic Skills"
    
    ; フラスコ設定（変更なし）
    profile.flasks := {}
    profile.flasks.lifeFlask := {key: key_lifeFlask}
    profile.flasks.sulphurFlask := {key: key_sulphurFlask
        , intervalMin: interval_sulphur_min
        , intervalMax: interval_sulphur_max}
    profile.flasks.tincture := {key: key_tincture
        , duration: duration_tincture
        , cooldownMin: cooldown_tincture_min
        , cooldownMax: cooldown_tincture_max
        , manaBurnRate: manaBurnStackRate}
    profile.flasks.goldFlask := {key: key_goldFlask
        , intervalMin: interval_goldFlask_min
        , intervalMax: interval_goldFlask_max}
    profile.flasks.manaFlask := {key: key_manaFlask
        , interval: interval_manaFlask}
    
    ; スキル設定 v2.5 - 新形式
    profile.skills := {}
    
    ; 固定スキル
    profile.skills.adrenaline := {}
    profile.skills.adrenaline.key1 := key_adrenaline_1
    profile.skills.adrenaline.key2 := key_adrenaline_2
    profile.skills.adrenaline.intervalMin := interval_adrenaline_min
    profile.skills.adrenaline.intervalMax := interval_adrenaline_max
    
    profile.skills.skillT := {}
    profile.skills.skillT.key := key_skill_T
    profile.skills.skillT.intervalMin := interval_skill_T_min
    profile.skills.skillT.intervalMax := interval_skill_T_max
    
    ; 動的Warcries
    profile.skills.dynamicWarcries := []
    for index, skill in CurrentWarcries {
        warcryData := {}
        warcryData.name := skill.name
        warcryData.key := skill.key
        warcryData.cooldown := skill.cooldown
        warcryData.exert := skill.exert
        profile.skills.dynamicWarcries.Push(warcryData)
    }
    
    ; 動的Regular Skills
    profile.skills.dynamicRegular := []
    for index, skill in CurrentRegularSkills {
        skillData := {}
        skillData.name := skill.name
        skillData.key := skill.key
        skillData.intervalMin := skill.intervalMin
        skillData.intervalMax := skill.intervalMax
        profile.skills.dynamicRegular.Push(skillData)
    }
    
    ; スキルキュー設定（基本設定のみ）
    profile.skillQueue := {}
    profile.skillQueue.castTime := skillQueue_castTime
    profile.skillQueue.checkInterval := skillQueue_checkInterval
    profile.skillQueue.rightClickLock := rightClick_lockDuration
    profile.skillQueue.enableExertCounter := enableExertCounter
    
    ; GUI設定
    profile.gui := {}
    profile.gui.notificationDuration := notification_duration
    
    ; オーバーレイ設定
    profile.overlay := {}
    profile.overlay.offsetX := overlayOffsetX
    profile.overlay.offsetY := overlayOffsetY
    profile.overlay.spacing := overlaySpacing
    profile.overlay.macroStatusX := macroStatusOffsetX
    profile.overlay.macroStatusY := macroStatusOffsetY
    profile.overlay.useSpecificMonitor := useSpecificMonitor
    profile.overlay.monitorNumber := specificMonitorNumber
    
    ; デバッグ設定
    profile.debug := {}
    profile.debug.enabled := debugMode
    
    return profile
}

; ==============================================================================
; プロファイルオブジェクトの適用 v2.5
; ==============================================================================

ApplyProfileObject(profile) {
    ; バージョンチェック
    profileVersion := profile.metadata.version
    
    ; フラスコ設定の適用（変更なし）
    if (profile.flasks) {
        key_lifeFlask := profile.flasks.lifeFlask.key
        key_sulphurFlask := profile.flasks.sulphurFlask.key
        interval_sulphur_min := profile.flasks.sulphurFlask.intervalMin
        interval_sulphur_max := profile.flasks.sulphurFlask.intervalMax
        
        key_tincture := profile.flasks.tincture.key
        duration_tincture := profile.flasks.tincture.duration
        cooldown_tincture_min := profile.flasks.tincture.cooldownMin
        cooldown_tincture_max := profile.flasks.tincture.cooldownMax
        manaBurnStackRate := profile.flasks.tincture.manaBurnRate
        
        key_goldFlask := profile.flasks.goldFlask.key
        interval_goldFlask_min := profile.flasks.goldFlask.intervalMin
        interval_goldFlask_max := profile.flasks.goldFlask.intervalMax
        
        key_manaFlask := profile.flasks.manaFlask.key
        interval_manaFlask := profile.flasks.manaFlask.interval
    }
    
    ; スキル設定の適用
    if (profile.skills) {
        ; 固定スキル
        key_adrenaline_1 := profile.skills.adrenaline.key1
        key_adrenaline_2 := profile.skills.adrenaline.key2
        interval_adrenaline_min := profile.skills.adrenaline.intervalMin
        interval_adrenaline_max := profile.skills.adrenaline.intervalMax
        
        key_skill_T := profile.skills.skillT.key
        interval_skill_T_min := profile.skills.skillT.intervalMin
        interval_skill_T_max := profile.skills.skillT.intervalMax
        
        ; v2.5形式の動的スキル
        if (profile.skills.dynamicWarcries) {
            CurrentWarcries := []
            skillCooldowns := {}
            warcryExertCounts := {}
            
            for index, skill in profile.skills.dynamicWarcries {
                CurrentWarcries.Push(skill)
                skillCooldowns[skill.key] := skill.cooldown
                warcryExertCounts[skill.key] := skill.exert
            }
        }
        
        if (profile.skills.dynamicRegular) {
            CurrentRegularSkills := []
            
            for index, skill in profile.skills.dynamicRegular {
                CurrentRegularSkills.Push(skill)
                
                ; 特定のスキルはグローバル変数にマップ
                if (skill.name = "Blood Rage") {
                    key_bloodRage := skill.key
                    interval_bloodRage_min := skill.intervalMin
                    interval_bloodRage_max := skill.intervalMax
                } else if (InStr(skill.name, "Steel Skin") || InStr(skill.name, "Molten Shell")) {
                    key_skill_B := skill.key
                    interval_skill_B_min := skill.intervalMin
                    interval_skill_B_max := skill.intervalMax
                }
            }
        }
        ; v2.4形式との後方互換性
        else if (profile.skills.bloodRage) {
            CurrentRegularSkills := []
            
            ; Blood Rage
            if (profile.skills.bloodRage) {
                key_bloodRage := profile.skills.bloodRage.key
                interval_bloodRage_min := profile.skills.bloodRage.intervalMin
                interval_bloodRage_max := profile.skills.bloodRage.intervalMax
                skill := {}
                skill.name := "Blood Rage"
                skill.key := key_bloodRage
                skill.intervalMin := interval_bloodRage_min
                skill.intervalMax := interval_bloodRage_max
                CurrentRegularSkills.Push(skill)
            }
            
            ; Skill B
            if (profile.skills.skillB) {
                key_skill_B := profile.skills.skillB.key
                interval_skill_B_min := profile.skills.skillB.intervalMin
                interval_skill_B_max := profile.skills.skillB.intervalMax
                skill := {}
                skill.name := "Steel Skin"
                skill.key := key_skill_B
                skill.intervalMin := interval_skill_B_min
                skill.intervalMax := interval_skill_B_max
                CurrentRegularSkills.Push(skill)
            }
        }
    }
    
    ; スキルキュー設定の適用
    if (profile.skillQueue) {
        skillQueue_castTime := profile.skillQueue.castTime
        skillQueue_checkInterval := profile.skillQueue.checkInterval
        rightClick_lockDuration := profile.skillQueue.rightClickLock
        enableExertCounter := profile.skillQueue.enableExertCounter
        
        ; v2.4形式との後方互換性
        if (profile.skillQueue.skills) {
            for key, data in profile.skillQueue.skills {
                skillCooldowns[key] := data.cooldown
                warcryExertCounts[key] := data.exert
            }
        }
    }
    
    ; GUI設定の適用
    if (profile.gui) {
        notification_duration := profile.gui.notificationDuration
    }
    
    ; オーバーレイ設定の適用
    if (profile.overlay) {
        overlayOffsetX := profile.overlay.offsetX
        overlayOffsetY := profile.overlay.offsetY
        overlaySpacing := profile.overlay.spacing
        macroStatusOffsetX := profile.overlay.macroStatusX
        macroStatusOffsetY := profile.overlay.macroStatusY
        useSpecificMonitor := profile.overlay.useSpecificMonitor
        specificMonitorNumber := profile.overlay.monitorNumber
    }
    
    ; デバッグ設定の適用
    if (profile.debug) {
        debugMode := profile.debug.enabled
    }
    
    ; スキルキューキーを更新
    UpdateSkillQueueKeys()
}

; ==============================================================================
; プロファイルリストの取得
; ==============================================================================

GetProfileList() {
    profiles := []
    
    ; profilesフォルダが存在しない場合
    if (!FileExist(profilesPath)) {
        return profiles
    }
    
    ; .jsonファイルを検索
    Loop, Files, %profilesPath%\*.json
    {
        SplitPath, A_LoopFileName, , , , nameNoExt
        profiles.Push(nameNoExt)
    }
    
    return profiles
}

; ==============================================================================
; デフォルトプロファイルの作成
; ==============================================================================

CreateDefaultProfile() {
    ; 現在の設定をdefault.jsonとして保存
    currentProfileBak := currentProfile
    currentProfile := "default"
    
    ; デフォルトのスキル設定
    CurrentWarcries := []
    
    warcry := {}
    warcry.name := "Intimidating Cry"
    warcry.key := "L"
    warcry.cooldown := 5260
    warcry.exert := 3
    CurrentWarcries.Push(warcry)
    
    warcry := {}
    warcry.name := "Seismic Cry"
    warcry.key := "K"
    warcry.cooldown := 5260
    warcry.exert := 7
    CurrentWarcries.Push(warcry)
    
    warcry := {}
    warcry.name := "Enduring Cry"
    warcry.key := "O"
    warcry.cooldown := 5260
    warcry.exert := 0
    CurrentWarcries.Push(warcry)
    
    warcry := {}
    warcry.name := "Rallying Cry"
    warcry.key := "N"
    warcry.cooldown := 5260
    warcry.exert := 6
    CurrentWarcries.Push(warcry)
    
    CurrentRegularSkills := []
    
    skill := {}
    skill.name := "Blood Rage"
    skill.key := "E"
    skill.intervalMin := 10000
    skill.intervalMax := 10100
    CurrentRegularSkills.Push(skill)
    
    skill := {}
    skill.name := "Steel Skin"
    skill.key := "B"
    skill.intervalMin := 3000
    skill.intervalMax := 3100
    CurrentRegularSkills.Push(skill)
    
    SaveSettingsToFile()
    currentProfile := currentProfileBak
}