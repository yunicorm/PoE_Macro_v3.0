; ==============================================================================
; スキル機能モジュール (定期実行スキル、スキルキューシステム)
; ==============================================================================

; --- スキルキューシステム用のグローバル変数を初期化 ---
global skillNextTime := {}
global isCasting := false

; --- 定期実行スキル ---

; スキルT
ExecuteMacroT() {
    global key_skill_T, interval_skill_T_min, interval_skill_T_max
    if IfWinActiveAndRunning() {
        Send, % key_skill_T
        Random, interval, % interval_skill_T_min, % interval_skill_T_max
        SetTimer, ExecuteMacroT, % -1 * interval
    }
}

; スキルE (Blood Rage)
ExecuteMacroE() {
    global key_bloodRage, interval_bloodRage_min, interval_bloodRage_max
    if IfWinActiveAndRunning() {
        Send, % key_bloodRage
        Random, interval, % interval_bloodRage_min, % interval_bloodRage_max
        SetTimer, ExecuteMacroE, % -1 * interval
    }
}

; スキルB
ExecuteMacroB() {
    global key_skill_B, interval_skill_B_min, interval_skill_B_max
    if IfWinActiveAndRunning() {
        Send, % key_skill_B
        Random, interval, % interval_skill_B_min, % interval_skill_B_max
        SetTimer, ExecuteMacroB, % -1 * interval
    }
}


; --- スキルキューシステム (L,K,O,N) ---

; スキルキューを開始する
StartSkillQueue() {
    global skillNextTime, skillQueue_keys, skillQueue_checkInterval, isCasting
    
    currentTime := A_TickCount
    isCasting := false

    ; 各スキルの初回実行時間を少しずつずらして初期化
    loop, % skillQueue_keys.MaxIndex() {
        key := skillQueue_keys[A_Index]
        skillNextTime[key] := currentTime + (A_Index - 1) * 500
    }
    
    ; スキルキューのメインループを開始
    SetTimer, SkillQueueLoop, % skillQueue_checkInterval
}

; スキルキューのメインループ
SkillQueueLoop() {
    global isCasting, lastRightClickTime, rightClick_lockDuration
    global skillNextTime, skillCooldowns, skillQueue_castTime

    if !IfWinActiveAndRunning() {
        return ; マクロが停止中なら何もしない
    }

    ; キャスト中、左クリック中(移動)、Qキー(移動スキル)押下中は実行しない
    if (isCasting || GetKeyState("LButton", "P") || GetKeyState("Q", "P")) {
        return
    }
    
    currentTime := A_TickCount
    ; 右クリック中、または右クリック後のロック時間内は実行しない
    if (GetKeyState("RButton", "P") || (currentTime - lastRightClickTime < rightClick_lockDuration)) {
        return
    }

    ; 使用すべきスキルを探す (クールダウンが完了していて、待機時間が最も長いもの)
    oldestSkill := ""
    oldestTime := currentTime + 999999
    for key, nextTime in skillNextTime {
        if (nextTime <= currentTime && nextTime < oldestTime) {
            oldestSkill := key
            oldestTime := nextTime
        }
    }

    ; 使用すべきスキルが見つかった場合
    if (oldestSkill != "") {
        isCasting := true
        StringLower, lowerKey, oldestSkill
        Send, % lowerKey
        
        ; 次の実行時間を計算 (基本クールダウン + ランダム遅延)
        Random, randomDelay, 0, 100
        skillNextTime[oldestSkill] := currentTime + skillCooldowns[oldestSkill] + randomDelay
        
        ; キャストロックタイマーを開始
        SetTimer, EndCasting, % -1 * skillQueue_castTime
    }
}

; キャストロックを解除する
EndCasting() {
    global isCasting
    isCasting := false
}

; --- スキルキュー用の右クリック押下時間記録 ---
; このホットキーは#IfWinActiveの外に置くことで、どのモジュールからでも機能します
~RButton::
    global lastRightClickTime
    lastRightClickTime := A_TickCount
return