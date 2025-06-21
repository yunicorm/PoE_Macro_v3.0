; ==============================================================================
; LegacyAdapter - 既存コードとv3.0の橋渡し
; Path: src/infrastructure/LegacyAdapter.ahk
; ==============================================================================

class LegacyAdapter {
    static container := ""
    static flaskService := ""
    static isInitialized := false
    
    ; ==============================================================================
    ; アダプターの初期化
    ; ==============================================================================
    Initialize(container) {
        if (LegacyAdapter.isInitialized) {
            return
        }
        
        LegacyAdapter.container := container
        LegacyAdapter.flaskService := container.Get("FlaskService")
        
        ; レガシー関数の置き換え
        this.ReplaceFlaskFunctions()
        
        LegacyAdapter.isInitialized := true
    }
    
    ; ==============================================================================
    ; フラスコ関数の置き換え
    ; ==============================================================================
    ReplaceFlaskFunctions() {
        ; グローバル関数として定義（既存のflasks.ahkの関数を上書き）
        ; これにより、既存のコードからの呼び出しが新しいサービスにリダイレクトされる
    }
}

; ==============================================================================
; レガシー関数の再定義（既存のflasks.ahkを置き換え）
; ==============================================================================

; 既存のExecuteAdrenalineR関数を新しいサービスにリダイレクト
ExecuteAdrenalineR() {
    container := GetServiceContainer()
    
    if (!container.Has("FlaskService")) {
        ; フォールバック：元の処理を実行
        LegacyExecuteAdrenalineR()
        return
    }
    
    flaskService := container.Get("FlaskService")
    flaskService.ExecuteAdrenaline()
}

; 既存のExecuteTinctureCycle関数を新しいサービスにリダイレクト
ExecuteTinctureCycle() {
    container := GetServiceContainer()
    
    if (!container.Has("FlaskService")) {
        ; フォールバック：元の処理を実行
        LegacyExecuteTinctureCycle()
        return
    }
    
    flaskService := container.Get("FlaskService")
    flaskService.ExecuteTincture()
}

; 既存のExecuteGoldFlask関数を新しいサービスにリダイレクト
ExecuteGoldFlask() {
    container := GetServiceContainer()
    
    if (!container.Has("FlaskService")) {
        ; フォールバック：元の処理を実行
        LegacyExecuteGoldFlask()
        return
    }
    
    flaskService := container.Get("FlaskService")
    flaskService.ExecuteGoldFlask()
}

; 既存のExecuteSulphurFlask関数を新しいサービスにリダイレクト
ExecuteSulphurFlask() {
    container := GetServiceContainer()
    
    if (!container.Has("FlaskService")) {
        ; フォールバック：元の処理を実行
        LegacyExecuteSulphurFlask()
        return
    }
    
    flaskService := container.Get("FlaskService")
    flaskService.ExecuteSulphurFlask()
}

; 既存のExecuteManaFlask関数を新しいサービスにリダイレクト
ExecuteManaFlask() {
    container := GetServiceContainer()
    
    if (!container.Has("FlaskService")) {
        ; フォールバック：元の処理を実行
        LegacyExecuteManaFlask()
        return
    }
    
    flaskService := container.Get("FlaskService")
    flaskService.ExecuteManaFlask()
}

; ==============================================================================
; ヘルパー関数
; ==============================================================================

; core.ahkの関数と同じ（互換性のため）
IfWinActiveAndRunning() {
    global isRunning
    if (!WinActive("ahk_exe PathOfExileSteam.exe") || !isRunning) {
        return false
    }
    return true
}

; Tincture関連の追加関数
CheckTinctureExpiration() {
    container := GetServiceContainer()
    
    if (!container.Has("FlaskService")) {
        LegacyCheckTinctureExpiration()
        return
    }
    
    ; FlaskServiceが内部で処理するため、ここでは何もしない
}

StartNextTinctureCycle() {
    container := GetServiceContainer()
    
    if (!container.Has("FlaskService")) {
        LegacyStartNextTinctureCycle()
        return
    }
    
    ; FlaskServiceが内部で処理するため、ここでは何もしない
}

; ==============================================================================
; レガシー実装（フォールバック用）
; ==============================================================================

; 元のflasks.ahkの実装をここにコピー（Legacyプレフィックス付き）
LegacyExecuteAdrenalineR() {
    global key_adrenaline_1, key_adrenaline_2, key_lifeFlask
    global interval_adrenaline_min, interval_adrenaline_max
    global lastAdrenalineTime
    
    if IfWinActiveAndRunning() {
        Send, % key_adrenaline_1
        Sleep, 50
        Send, % key_adrenaline_2
        Random, delayBefore1, 50, 70
        Sleep, %delayBefore1%
        Send, % key_lifeFlask
        
        lastAdrenalineTime := A_TickCount
        
        Random, interval, % interval_adrenaline_min, % interval_adrenaline_max
        SetTimer, ExecuteAdrenalineR, % -1 * interval
    }
}

LegacyExecuteTinctureCycle() {
    global tinctureActive, tinctureLastUsedTime
    global key_manaFlask, key_tincture
    global interval_manaFlask, duration_tincture

    if IfWinActiveAndRunning() {
        Send, % key_manaFlask
        Random, delayManaToTincture, 30, 70
        Sleep, %delayManaToTincture%
        
        Send, % key_tincture
        tinctureActive := true
        tinctureLastUsedTime := A_TickCount
        Sleep, 100
        
        SetTimer, ExecuteManaFlask, % -1 * interval_manaFlask
        SetTimer, CheckTinctureExpiration, % -1 * duration_tincture
    }
}

LegacyExecuteGoldFlask() {
    global key_goldFlask, interval_goldFlask_min, interval_goldFlask_max
    global lastGoldFlaskTime
    
    if IfWinActiveAndRunning() {
        Send, % key_goldFlask
        lastGoldFlaskTime := A_TickCount
        
        Random, interval, % interval_goldFlask_min, % interval_goldFlask_max
        SetTimer, ExecuteGoldFlask, % -1 * interval
    }
}

LegacyExecuteSulphurFlask() {
    global key_sulphurFlask, interval_sulphur_min, interval_sulphur_max
    
    if IfWinActiveAndRunning() {
        Send, % key_sulphurFlask
        Random, interval, % interval_sulphur_min, % interval_sulphur_max
        SetTimer, ExecuteSulphurFlask, % -1 * interval
    }
}

LegacyExecuteManaFlask() {
    global tinctureActive, key_manaFlask, interval_manaFlask
    
    if (IfWinActiveAndRunning() && tinctureActive) {
        Send, % key_manaFlask
        SetTimer, ExecuteManaFlask, % -1 * interval_manaFlask
    } else {
        SetTimer, ExecuteManaFlask, Off
    }
}

; ==============================================================================
; グローバル変数の同期
; ==============================================================================

; FlaskServiceの状態を既存のグローバル変数に同期
SyncFlaskServiceState() {
    global tinctureActive, tinctureLastUsedTime
    global lastAdrenalineTime, lastGoldFlaskTime
    
    container := GetServiceContainer()
    
    if (!container.Has("FlaskService")) {
        return
    }
    
    flaskService := container.Get("FlaskService")
    
    ; Tincture状態の同期
    tinctureActive := flaskService.IsTinctureActive()
    
    ; 実行時間の同期
    lastAdrenalineTime := flaskService.GetLastExecutionTime("adrenaline")
    lastGoldFlaskTime := flaskService.GetLastExecutionTime("goldFlask")
    
    ; Mana Burnスタックの計算（オーバーレイ用）
    ; この部分は後でOverlayServiceに移動予定
}

; 定期的に状態を同期（暫定的な解決策）
SetTimer, SyncFlaskServiceState, 100

; ==============================================================================
; 追加のレガシー実装
; ==============================================================================

LegacyCheckTinctureExpiration() {
    global tinctureActive
    global cooldown_tincture_min, cooldown_tincture_max

    if IfWinActiveAndRunning() {
        SetTimer, ExecuteManaFlask, Off
        tinctureActive := false
        
        Random, cooldownDelay, % cooldown_tincture_min, % cooldown_tincture_max
        SetTimer, StartNextTinctureCycle, % -1 * cooldownDelay
    }
}

LegacyStartNextTinctureCycle() {
    if IfWinActiveAndRunning() {
        ExecuteTinctureCycle()
    }
}