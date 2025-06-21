; ==============================================================================
; スキル機能モジュール (定期実行スキル、スキルキューシステム)
; ==============================================================================

; --- 動的スキル用のタイマー管理変数 ---
global DynamicSkillTimers := {}

; --- 定期実行スキル ---

; スキルT
ExecuteMacroT() {
    global key_skill_T, interval_skill_T_min, interval_skill_T_max
    global lastSkillTTime  ; オーバーレイ用に追加
    
    if IfWinActiveAndRunning() {
        Send, % key_skill_T
        
        ; 実行時間を記録（オーバーレイ用）
        lastSkillTTime := A_TickCount
        
        Random, interval, % interval_skill_T_min, % interval_skill_T_max
        SetTimer, ExecuteMacroT, % -1 * interval
    }
}

; スキルE (Blood Rage) - レガシー互換性のため残す
ExecuteMacroE() {
    global key_bloodRage, interval_bloodRage_min, interval_bloodRage_max
    if IfWinActiveAndRunning() {
        Send, % key_bloodRage
        Random, interval, % interval_bloodRage_min, % interval_bloodRage_max
        SetTimer, ExecuteMacroE, % -1 * interval
    }
}

; スキルB - レガシー互換性のため残す
ExecuteMacroB() {
    global key_skill_B, interval_skill_B_min, interval_skill_B_max
    global lastSkillBTime  ; オーバーレイ用に追加
    
    if IfWinActiveAndRunning() {
        Send, % key_skill_B
        
        ; 実行時間を記録（オーバーレイ用）
        lastSkillBTime := A_TickCount
        
        Random, interval, % interval_skill_B_min, % interval_skill_B_max
        SetTimer, ExecuteMacroB, % -1 * interval
    }
}

; --- 動的Regular Skillsの実行 ---
ExecuteDynamicRegularSkills() {
    global CurrentRegularSkills, isRunning, DynamicSkillTimers
    
    if (!IfWinActiveAndRunning()) {
        return
    }
    
    ; 既存のタイマーをクリア
    DynamicSkillTimers := {}
    
    for index, skill in CurrentRegularSkills {
        if (skill.key != "" && skill.intervalMin > 0) {
            ; 各スキルの初回実行をスケジュール
            Random, delay, 500, 1500
            
            ; タイマー用の一意なラベル名を作成
            timerLabel := "DynamicSkill_" . index
            
            ; タイマー情報を保存
            timerInfo := {}
            timerInfo.skill := skill
            timerInfo.index := index
            DynamicSkillTimers[timerLabel] := timerInfo
            
            ; 動的にタイマーを設定
            fn := Func("ExecuteDynamicSkillByIndex").Bind(index)
            SetTimer, %fn%, % -1 * delay
        }
    }
}

; --- インデックスベースの動的スキル実行 ---
ExecuteDynamicSkillByIndex(skillIndex) {
    global CurrentRegularSkills, isRunning, lastSkillBTime
    
    if (!IfWinActiveAndRunning()) {
        return
    }
    
    ; インデックスの有効性チェック
    if (skillIndex > CurrentRegularSkills.Length()) {
        return
    }
    
    skill := CurrentRegularSkills[skillIndex]
    
    if (skill.key = "") {
        return
    }
    
    ; スキルを実行
    Send, % skill.key
    
    ; Steel Skin系の場合は実行時間を記録
    if (InStr(skill.name, "Steel Skin") || InStr(skill.name, "Molten Shell") || InStr(skill.name, "Immortal Call")) {
        lastSkillBTime := A_TickCount
    }
    
    ; 次回実行をスケジュール
    Random, interval, % skill.intervalMin, % skill.intervalMax
    fn := Func("ExecuteDynamicSkillByIndex").Bind(skillIndex)
    SetTimer, %fn%, % -1 * interval
}

; --- すべての動的タイマーを停止 ---
StopAllDynamicTimers() {
    global CurrentRegularSkills, DynamicSkillTimers
    
    ; インデックスベースのタイマーを停止
    Loop, 10 {
        fn := Func("ExecuteDynamicSkillByIndex").Bind(A_Index)
        SetTimer, %fn%, Off
    }
    
    ; レガシータイマーも停止
    SetTimer, ExecuteMacroE, Off
    SetTimer, ExecuteMacroB, Off
    
    ; タイマー情報をクリア
    DynamicSkillTimers := {}
}

; --- スキルキューシステム (L,K,O,N) ---

; スキルキューを開始する
StartSkillQueue() {
    global skillNextTime, skillQueue_keys, skillQueue_checkInterval, isCasting
    global CurrentWarcries, skillCooldowns
    
    currentTime := A_TickCount
    isCasting := false

    ; skillNextTimeとskillCooldownsを初期化
    skillNextTime := {}
    skillCooldowns := {}
    
    ; CurrentWarcries から動的に設定
    for index, skill in CurrentWarcries {
        if (skill.key != "") {
            skillCooldowns[skill.key] := skill.cooldown
            skillNextTime[skill.key] := currentTime + (index - 1) * 500
        }
    }
    
    ; スキルキューのメインループを開始
    SetTimer, SkillQueueLoop, % skillQueue_checkInterval
}

; スキルキューのメインループ
SkillQueueLoop() {
    global isCasting, lastRightClickTime, rightClick_lockDuration
    global skillNextTime, skillCooldowns, skillQueue_castTime
    global currentExertCounts, warcryExertCounts, enableExertCounter
    global debugMode

    if !IfWinActiveAndRunning() {
        return ; マクロが停止中なら何もしない
    }

    ; キャスト中、左クリック中(移動)、Qキー(移動スキル)押下中は実行しない
    if (isCasting || GetKeyState("LButton", "P") || GetKeyState("Q", "P")) {
        return
    }
    
    currentTime := A_TickCount
    
    ; lastRightClickTimeの初期化チェック
    if (lastRightClickTime = "") {
        lastRightClickTime := 0
    }
    
    ; 右クリック中、または右クリック後のロック時間内は実行しない
    if (GetKeyState("RButton", "P") || (currentTime - lastRightClickTime < rightClick_lockDuration)) {
        return
    }

    ; オブジェクトの存在確認
    if (!IsObject(skillNextTime) || !IsObject(skillCooldowns)) {
        return
    }

    ; 使用すべきスキルを探す (クールダウンが完了していて、待機時間が最も長いもの)
    oldestSkill := ""
    oldestTime := currentTime + 999999
    for key, nextTime in skillNextTime {
        if (nextTime != "" && nextTime <= currentTime && nextTime < oldestTime) {
            oldestSkill := key
            oldestTime := nextTime
        }
    }

    ; 使用すべきスキルが見つかった場合
    if (oldestSkill != "") {
        isCasting := true
        StringLower, lowerKey, oldestSkill
        Send, % lowerKey
        
        ; Warcry使用時にExertカウントをリセット
        if (IsObject(warcryExertCounts) && IsObject(currentExertCounts)) {
            if (enableExertCounter && warcryExertCounts[oldestSkill] > 0) {
                oldCount := currentExertCounts[oldestSkill]
                currentExertCounts[oldestSkill] := warcryExertCounts[oldestSkill]
                
                ; デバッグログ出力
                if (debugMode) {
                    DebugLog("Warcry " . oldestSkill . " used! Reset count from " . oldCount . " to " . currentExertCounts[oldestSkill])
                }
            }
        }
        
        ; 次の実行時間を計算 (基本クールダウン + ランダム遅延)
        Random, randomDelay, 0, 100
        cooldown := skillCooldowns[oldestSkill]
        if (cooldown = "") {
            cooldown := 5000  ; デフォルト値
        }
        skillNextTime[oldestSkill] := currentTime + cooldown + randomDelay
        
        ; キャストロックタイマーを開始
        castTime := skillQueue_castTime
        if (castTime = "") {
            castTime := 270  ; デフォルト値
        }
        SetTimer, EndCasting, % -1 * castTime
    }
}

; キャストロックを解除する
EndCasting() {
    global isCasting
    isCasting := false
}

; --- スキルキューの動的更新 ---
UpdateSkillQueueKeys() {
    global skillQueue_keys, CurrentWarcries, isRunning
    
    ; 既存のキューをクリア
    skillQueue_keys := []
    
    ; 動的に設定されたWarcryキーを追加
    for index, skill in CurrentWarcries {
        if (skill.key != "") {
            skillQueue_keys.Push(skill.key)
        }
    }
    
    ; スキルキューを再初期化（実行中の場合のみ）
    if (isRunning) {
        ; 実行中の場合は、タイマーを一旦停止して再開始
        SetTimer, SkillQueueLoop, Off
        StartSkillQueue()
    }
}