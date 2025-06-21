; ==============================================================================
; コア機能モジュール (マクロの起動/停止管理、共通関数)
; v3.0移行版 - フラスコ機能はFlaskServiceに移行
; ==============================================================================

; --- 状態管理用グローバル変数の宣言 ---
global tinctureActive := false
global tinctureLastUsedTime := 0
global lastRightClickTime := 0
global isCasting := false

; オーバーレイ用の実行時間記録変数
global lastAdrenalineTime := 0
global lastGoldFlaskTime := 0
global lastSkillTTime := 0
global lastSkillBTime := 0

; スキルキュー関連（初期化しておく）
global skillNextTime := {}
global currentExertCounts := {}

; --- 全てのタイマーを開始する（動的スキル対応版） ---
; main.ahk の F12 (開始時) から呼び出される
StartAllTimers() {
    ResetStateVariables()
    
    ; 各モジュールで定義されるタイマー処理を一度実行し、ループを開始させる
    ; フラスコ・バフ関連 (v3.0でFlaskServiceに移行済み)
    ; ExecuteAdrenalineR()      ; FlaskServiceが処理
    ; ExecuteTinctureCycle()    ; FlaskServiceが処理
    ; ExecuteGoldFlask()        ; FlaskServiceが処理
    ; ExecuteSulphurFlask()     ; FlaskServiceが処理

    ; 固定スキル (skills.ahkで定義)
    ExecuteMacroT()
    
    ; 動的スキルの実行（v2.5新規追加）
    ExecuteDynamicRegularSkills()
    
    ; スキルキューの開始
    StartSkillQueue()
}

; --- 全てのタイマーを停止する（動的スキル対応版） ---
; main.ahk の F12 (停止時) から呼び出される
StopAllTimers() {
    ; 全てのSetTimerをOffにする
    ; フラスコ関連 (v3.0でFlaskServiceが処理)
    ; SetTimer, ExecuteAdrenalineR, Off      ; FlaskServiceが処理
    ; SetTimer, ExecuteTinctureCycle, Off    ; FlaskServiceが処理
    ; SetTimer, CheckTinctureExpiration, Off ; FlaskServiceが処理
    ; SetTimer, StartNextTinctureCycle, Off  ; FlaskServiceが処理
    ; SetTimer, ExecuteManaFlask, Off        ; FlaskServiceが処理
    ; SetTimer, ExecuteGoldFlask, Off        ; FlaskServiceが処理
    ; SetTimer, ExecuteSulphurFlask, Off     ; FlaskServiceが処理
    
    ; 固定スキル関連
    SetTimer, ExecuteMacroT, Off
    
    ; 動的スキルの停止（v2.5新規追加）
    StopAllDynamicTimers()
    
    ; スキルキュー
    SetTimer, SkillQueueLoop, Off
    SetTimer, EndCasting, Off

    ; GUIを非表示にする (gui.ahkの関数を呼び出す)
    HideStatusIndicator()

    ; 状態管理変数をリセットする
    ResetStateVariables()
}

; --- 緊急停止処理 ---
; main.ahk の Ctrl+Shift+F12 から呼び出される
EmergencyStop() {
    global isRunning := false ; 実行フラグを強制的に下ろす
    StopAllTimers()
}

; --- 状態管理変数のリセット（動的スキル対応版） ---
ResetStateVariables() {
    global
    tinctureActive := false
    tinctureLastUsedTime := 0
    lastRightClickTime := 0
    isCasting := false
    
    ; オーバーレイ用の実行時間記録変数をリセット
    lastAdrenalineTime := 0
    lastGoldFlaskTime := 0
    lastSkillTTime := 0
    lastSkillBTime := 0
    
    ; Mana Burnスタック関連
    manaBurnStacks := 0
    manaBurnLastUpdate := 0
    
    ; スキルキューの初期化
    if (!IsObject(skillNextTime)) {
        skillNextTime := {}
    }
    
    ; Exertカウントのリセット（動的対応）
    if (IsObject(currentExertCounts)) {
        currentExertCounts := {}
        
        ; CurrentWarcries から動的に設定
        if (IsObject(CurrentWarcries)) {
            for index, skill in CurrentWarcries {
                if (skill.key != "") {
                    currentExertCounts[skill.key] := 0
                }
            }
        }
    }
}

; --- 共通ユーティリティ関数 ---
; PoEがアクティブかつマクロ実行中かチェックする
IfWinActiveAndRunning() {
    global isRunning
    if (!WinActive("ahk_exe PathOfExileSteam.exe") || !isRunning) {
        return false
    }
    return true
}

; --- 実行時の動的スキル再読み込み（v2.5新規追加） ---
ReloadDynamicSkills() {
    global isRunning
    
    if (!isRunning) {
        return
    }
    
    ; 一旦停止
    StopAllDynamicTimers()
    SetTimer, SkillQueueLoop, Off
    
    ; 設定を再適用
    ApplyDynamicSkillSettings()
    
    ; 再開始
    ExecuteDynamicRegularSkills()
    StartSkillQueue()
    
    ShowBigNotification("Skills Reloaded", "Dynamic skills updated", "00FF00")
}