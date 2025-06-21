; ==============================================================================
; フラスコ機能モジュール (Adrenaline, Tincture, 各種フラスコ管理)
; ==============================================================================

; --- 処理1: Adrenaline獲得＋ライフ回復 (R -> E -> 1) ---
ExecuteAdrenalineR() {
    global key_adrenaline_1, key_adrenaline_2, key_lifeFlask
    global interval_adrenaline_min, interval_adrenaline_max
    global lastAdrenalineTime  ; オーバーレイ用に追加
    
    if IfWinActiveAndRunning() {
        Send, % key_adrenaline_1
        Sleep, 50
        Send, % key_adrenaline_2
        Random, delayBefore1, 50, 70
        Sleep, %delayBefore1%
        Send, % key_lifeFlask
        
        ; 実行時間を記録（オーバーレイ用）
        lastAdrenalineTime := A_TickCount
        
        Random, interval, % interval_adrenaline_min, % interval_adrenaline_max
        SetTimer, ExecuteAdrenalineR, % -1 * interval
    }
}

; --- 処理2&3: Tinctureサイクルとマナフラスコループ ---

; Tinctureサイクルを開始する
ExecuteTinctureCycle() {
    global tinctureActive, tinctureLastUsedTime
    global key_manaFlask, key_tincture
    global interval_manaFlask, duration_tincture

    if IfWinActiveAndRunning() {
        ; 最初にマナフラスコを使用
        Send, % key_manaFlask
        Random, delayManaToTincture, 30, 70
        Sleep, %delayManaToTincture%
        
        ; 次にTincture使用
        Send, % key_tincture
        tinctureActive := true
        tinctureLastUsedTime := A_TickCount
        Sleep, 100
        
        ; マナフラスコループを開始（次回は設定時間後から）
        SetTimer, ExecuteManaFlask, % -1 * interval_manaFlask
        
        ; Tinctureの持続時間後に有効期限チェックを開始
        SetTimer, CheckTinctureExpiration, % -1 * duration_tincture
    }
}

; Tinctureの有効期限をチェックし、クールダウンタイマーを開始する
CheckTinctureExpiration() {
    global tinctureActive
    global cooldown_tincture_min, cooldown_tincture_max

    if IfWinActiveAndRunning() {
        SetTimer, ExecuteManaFlask, Off ; マナフラスコループを停止
        tinctureActive := false
        
        ; クールダウン後に次のサイクルを開始
        Random, cooldownDelay, % cooldown_tincture_min, % cooldown_tincture_max
        SetTimer, StartNextTinctureCycle, % -1 * cooldownDelay
    }
}

; 次のTinctureサイクルを呼び出す
StartNextTinctureCycle() {
    if IfWinActiveAndRunning() {
        ExecuteTinctureCycle()
    }
}

; マナフラスコループ（Tincture効果中のみ実行）
ExecuteManaFlask() {
    global tinctureActive, key_manaFlask, interval_manaFlask
    if (IfWinActiveAndRunning() && tinctureActive) {
        Send, % key_manaFlask
        ; 次の実行をスケジュール
        SetTimer, ExecuteManaFlask, % -1 * interval_manaFlask
    } else {
        ; Tinctureがアクティブでない場合はタイマーを停止
        SetTimer, ExecuteManaFlask, Off
    }
}

; --- 処理4: Gold Flask (Wine of the Prophet) ---
ExecuteGoldFlask() {
    global key_goldFlask, interval_goldFlask_min, interval_goldFlask_max
    global lastGoldFlaskTime  ; オーバーレイ用に追加
    
    if IfWinActiveAndRunning() {
        Send, % key_goldFlask
        
        ; 実行時間を記録（オーバーレイ用）
        lastGoldFlaskTime := A_TickCount
        
        Random, interval, % interval_goldFlask_min, % interval_goldFlask_max
        SetTimer, ExecuteGoldFlask, % -1 * interval
    }
}

; --- 処理5: Sulphur Flask (The Overflowing Chalice) ---
ExecuteSulphurFlask() {
    global key_sulphurFlask, interval_sulphur_min, interval_sulphur_max
    if IfWinActiveAndRunning() {
        Send, % key_sulphurFlask
        Random, interval, % interval_sulphur_min, % interval_sulphur_max
        SetTimer, ExecuteSulphurFlask, % -1 * interval
    }
}