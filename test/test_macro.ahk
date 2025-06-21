; ==============================================================================
; マクロ動作テストスクリプト
; ==============================================================================

#NoEnv
#SingleInstance Force
SendMode Input

; テスト用にPath of Exileのウィンドウチェックを無効化
global testMode := true

; メインスクリプトのディレクトリを設定
mainDir := A_ScriptDir . "\.."
SetWorkingDir %mainDir%

; モジュールを読み込み
#Include %mainDir%\config\settings.ahk
#Include %mainDir%\modules\core.ahk
#Include %mainDir%\modules\gui.ahk
#Include %mainDir%\modules\flasks.ahk
#Include %mainDir%\modules\skills.ahk

; テスト用のウィンドウチェック関数を上書き
IfWinActiveAndRunning() {
    global isRunning, testMode
    if (testMode && isRunning) {
        return true
    }
    return false
}

; グローバル変数の初期化
global isRunning := false
global testResults := []

; ==============================================================================
; テストケース
; ==============================================================================

RunTests() {
    MsgBox, 0, テスト開始, マクロのテストを開始します。`n各機能を順番にテストします。, 3
    
    ; テスト1: 変数初期化
    TestVariableInitialization()
    
    ; テスト2: タイマー起動
    TestTimerStartup()
    
    ; テスト3: Tinctureサイクル
    TestTinctureCycle()
    
    ; テスト4: スキルキュー
    TestSkillQueue()
    
    ; テスト結果表示
    ShowTestResults()
}

; --- テスト1: 変数初期化 ---
TestVariableInitialization() {
    testName := "変数初期化テスト"
    
    ResetStateVariables()
    
    success := true
    if (tinctureActive != false) {
        success := false
    }
    if (isCasting != false) {
        success := false
    }
    if (!IsObject(skillNextTime)) {
        success := false
    }
    
    AddTestResult(testName, success)
}

; --- テスト2: タイマー起動 ---
TestTimerStartup() {
    testName := "タイマー起動テスト"
    
    isRunning := true
    oldAdrenalineTime := lastAdrenalineTime
    
    ; Adrenalineタイマーをテスト
    ExecuteAdrenalineR()
    Sleep, 100
    
    success := (lastAdrenalineTime > oldAdrenalineTime)
    
    ; タイマーを停止
    SetTimer, ExecuteAdrenalineR, Off
    isRunning := false
    
    AddTestResult(testName, success)
}

; --- テスト3: Tinctureサイクル ---
TestTinctureCycle() {
    testName := "Tinctureサイクルテスト"
    
    isRunning := true
    oldTinctureTime := tinctureLastUsedTime
    
    ; Tinctureサイクル開始
    ExecuteTinctureCycle()
    Sleep, 200
    
    success := (tinctureActive == true && tinctureLastUsedTime > oldTinctureTime)
    
    ; クリーンアップ
    SetTimer, ExecuteManaFlask, Off
    SetTimer, CheckTinctureExpiration, Off
    tinctureActive := false
    isRunning := false
    
    AddTestResult(testName, success)
}

; --- テスト4: スキルキュー ---
TestSkillQueue() {
    testName := "スキルキューテスト"
    
    isRunning := true
    
    ; スキルキュー開始
    StartSkillQueue()
    Sleep, 100
    
    success := IsObject(skillNextTime) && skillNextTime.HasKey("L")
    
    ; クリーンアップ
    SetTimer, SkillQueueLoop, Off
    isRunning := false
    
    AddTestResult(testName, success)
}

; --- テスト結果管理 ---
AddTestResult(name, success) {
    global testResults
    result := {name: name, success: success}
    testResults.Push(result)
}

ShowTestResults() {
    global testResults
    
    totalTests := testResults.Length()
    passedTests := 0
    failedTests := []
    
    for index, result in testResults {
        if (result.success) {
            passedTests++
        } else {
            failedTests.Push(result.name)
        }
    }
    
    resultText := "=== テスト結果 ===`n`n"
    resultText .= "総テスト数: " . totalTests . "`n"
    resultText .= "成功: " . passedTests . "`n"
    resultText .= "失敗: " . (totalTests - passedTests) . "`n`n"
    
    if (failedTests.Length() > 0) {
        resultText .= "失敗したテスト:`n"
        for index, name in failedTests {
            resultText .= "  - " . name . "`n"
        }
    } else {
        resultText .= "すべてのテストが成功しました！"
    }
    
    MsgBox, 0, テスト完了, %resultText%
}

; ==============================================================================
; 実行
; ==============================================================================

; F9キーでテスト実行
F9::RunTests()

; Escキーで終了
Esc::ExitApp

MsgBox, 0, テストモード, PoEマクロのテストモードです。`n`nF9: テスト実行`nEsc: 終了
