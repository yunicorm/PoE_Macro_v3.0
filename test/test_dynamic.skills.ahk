; ==============================================================================
; 動的スキル管理機能テストスクリプト
; ==============================================================================

#NoEnv
SetWorkingDir %A_ScriptDir%\..

; 必要なモジュールを読み込み
#Include %A_ScriptDir%\..\gui\dynamic_skill_manager.ahk

; グローバル変数の初期化（テスト用）
global skillCooldowns := {}
global warcryExertCounts := {}
global CurrentWarcries := []
global CurrentRegularSkills := []

; ==============================================================================
; テスト実行
; ==============================================================================

RunDynamicSkillTests() {
    MsgBox, 0, Test Start, Starting Dynamic Skill Manager Tests, 2
    
    ; Test 1: スキルデータベース初期化
    TestSkillDatabase()
    
    ; Test 2: Warcry追加/削除
    TestWarcryManagement()
    
    ; Test 3: Regular Skill追加/削除
    TestRegularSkillManagement()
    
    ; Test 4: データ収集
    TestDataCollection()
    
    ShowTestSummary()
}

; ==============================================================================
; Test 1: スキルデータベース
; ==============================================================================

TestSkillDatabase() {
    InitializeSkillDatabase()
    
    testResult := "PASS"
    
    ; Warcryスキルの存在確認
    if (!WarcrySkills["Intimidating Cry"]) {
        testResult := "FAIL - Warcry not found"
    }
    
    ; Regular Skillsの存在確認
    if (!RegularSkills["Blood Rage"]) {
        testResult := "FAIL - Regular skill not found"
    }
    
    AddTestResult("Skill Database Initialization", testResult)
}

; ==============================================================================
; Test 2: Warcry管理
; ==============================================================================

TestWarcryManagement() {
    ; 初期状態
    CurrentWarcries := []
    
    ; Warcry追加
    CurrentWarcries.Push({name: "Intimidating Cry", key: "L", cooldown: 5260, exert: 3})
    CurrentWarcries.Push({name: "Seismic Cry", key: "K", cooldown: 5260, exert: 7})
    
    testResult := "PASS"
    
    if (CurrentWarcries.Length() != 2) {
        testResult := "FAIL - Expected 2 warcries, got " . CurrentWarcries.Length()
    }
    
    ; 削除テスト
    CurrentWarcries.RemoveAt(1)
    
    if (CurrentWarcries.Length() != 1) {
        testResult := "FAIL - Remove failed"
    }
    
    AddTestResult("Warcry Management", testResult)
}

; ==============================================================================
; Test 3: Regular Skill管理
; ==============================================================================

TestRegularSkillManagement() {
    ; 初期状態
    CurrentRegularSkills := []
    
    ; スキル追加
    CurrentRegularSkills.Push({name: "Blood Rage", key: "E", intervalMin: 10000, intervalMax: 10100})
    CurrentRegularSkills.Push({name: "Steel Skin", key: "B", intervalMin: 3000, intervalMax: 3100})
    
    testResult := "PASS"
    
    if (CurrentRegularSkills.Length() != 2) {
        testResult := "FAIL - Expected 2 skills, got " . CurrentRegularSkills.Length()
    }
    
    AddTestResult("Regular Skill Management", testResult)
}

; ==============================================================================
; Test 4: データ収集
; ==============================================================================

TestDataCollection() {
    ; ApplyDynamicSkillSettingsのテスト
    ApplyDynamicSkillSettings()
    
    testResult := "PASS"
    
    ; skillCooldownsが更新されているか確認
    if (!skillCooldowns.K) {
        testResult := "FAIL - Skill cooldowns not applied"
    }
    
    AddTestResult("Data Collection & Application", testResult)
}

; ==============================================================================
; テスト結果管理
; ==============================================================================

global testResults := []

AddTestResult(testName, result) {
    global testResults
    testResults.Push({name: testName, result: result})
}

ShowTestSummary() {
    summary := "=== Test Results ===`n`n"
    passCount := 0
    
    for index, test in testResults {
        summary .= test.name . ": " . test.result . "`n"
        if (test.result = "PASS") {
            passCount++
        }
    }
    
    summary .= "`nTotal: " . passCount . "/" . testResults.Length() . " passed"
    
    MsgBox, 0, Test Results, %summary%
}

; ==============================================================================
; 実行
; ==============================================================================

F10::RunDynamicSkillTests()
Esc::ExitApp

MsgBox, 0, Test Mode, Dynamic Skill Manager Test Mode`n`nF10: Run tests`nEsc: Exit