; Path of Exile用AutoHotkeyマクロ (v3.0移行版)
; メインスクリプト (エントリーポイント)
; Version 3.0-alpha - 段階的アーキテクチャ移行

#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%

; DPIスケーリング対応（マルチディスプレイ環境用）
DllCall("SetProcessDPIAware")

; ==============================================================================
; v3.0アーキテクチャの初期化（新規追加）
; ==============================================================================
#Include %A_ScriptDir%\src\bootstrap.ahk
#Include %A_ScriptDir%\src\infrastructure\LegacyAdapter.ahk

; v3.0システムの初期化
global appContainer := Bootstrap.Initialize()
LegacyAdapter.Initialize(appContainer)

; ==============================================================================
; モジュールの読み込み（一部をコメントアウトして段階的に移行）
; ==============================================================================
#Include %A_ScriptDir%\config\settings.ahk
#Include %A_ScriptDir%\modules\core.ahk
#Include %A_ScriptDir%\modules\gui.ahk
; #Include %A_ScriptDir%\modules\flasks.ahk  ; v3.0のFlaskServiceに置き換え
#Include %A_ScriptDir%\modules\skills.ahk
#Include %A_ScriptDir%\modules\overlay.ahk

; JSON ライブラリ
#Include %A_ScriptDir%\lib\JSON.ahk

; GUI モジュール
#Include %A_ScriptDir%\gui\settings_gui.ahk
#Include %A_ScriptDir%\gui\profile_manager.ahk
#Include %A_ScriptDir%\gui\dynamic_skill_manager.ahk

; ==============================================================================
; グローバル変数の初期化
; ==============================================================================
global isRunning := false

; ==============================================================================
; 初期化処理
; ==============================================================================
; オーバーレイを初期化（最初は非表示）
InitializeOverlay()

; デフォルトプロファイルの確認
CheckDefaultProfile()

; 動的スキル管理の初期化
InitializeSkillDatabase()

; ==============================================================================
; 補助関数
; ==============================================================================
CheckDefaultProfile() {
    defaultPath := profilesPath . "\default.json"
    if (!FileExist(defaultPath)) {
        CreateDefaultProfile()
        MsgBox, 64, First Run, Default profile created.`nPress Ctrl+Shift+S to open settings.
    }
}

; ==============================================================================
; GUI用ホットキー (PoEウィンドウ外でも使用可能)
; ==============================================================================

; Ctrl+Shift+S で設定画面を開く
^+s::ShowSettingsGUI()

; ==============================================================================
; ホットキー定義 (PoEウィンドウがアクティブな時のみ有効)
; ==============================================================================
#IfWinActive ahk_exe PathOfExileSteam.exe

; F12キーでマクロの開始/停止（修正版）
F12::
    isRunning := !isRunning
    if (isRunning) {
        ; v2.5: 動的スキル設定を適用
        ApplyDynamicSkillSettings()
        
        ShowBigNotification("マクロ開始", "フラスコループ実行中", "00FF00")
        
        ; v3.0: 新しいサービスを使用
        StartAllTimersV3()
        
        ShowStatusIndicator()
        ShowOverlay()
        UpdateMacroStatus(true)
    } else {
        ShowBigNotification("マクロ停止", "全処理を停止しました", "FF0000")
        
        ; v3.0: 新しいサービスを使用
        StopAllTimersV3()
        
        HideOverlay()
        UpdateMacroStatus(false)
    }
return

; Ctrl+Shift+F12で緊急停止
^+F12::
    EmergencyStopV3()
    ShowBigNotification("緊急停止", "マクロを強制終了しました", "FF0000")
    HideOverlay()
    UpdateMacroStatus(false)
return

#IfWinActive

; ==============================================================================
; v3.0用の新しい制御関数
; ==============================================================================

StartAllTimersV3() {
    ; 状態変数のリセット
    ResetStateVariables()
    
    ; v3.0: FlaskServiceを開始
    flaskService := appContainer.Get("FlaskService")
    flaskService.Start()
    
    ; レガシーサービスも開始（まだ移行していない部分）
    ExecuteMacroT()
    ExecuteDynamicRegularSkills()
    StartSkillQueue()
}

StopAllTimersV3() {
    ; v3.0: FlaskServiceを停止
    flaskService := appContainer.Get("FlaskService")
    flaskService.Stop()
    
    ; レガシータイマーも停止
    SetTimer, ExecuteMacroT, Off
    StopAllDynamicTimers()
    SetTimer, SkillQueueLoop, Off
    SetTimer, EndCasting, Off
    
    ; GUIを非表示にする
    HideStatusIndicator()
    
    ; 状態管理変数をリセット
    ResetStateVariables()
}

EmergencyStopV3() {
    global isRunning := false
    StopAllTimersV3()
}

; ==============================================================================
; 右クリック検出（スキルキュー用 + Exertカウント減少）
; ==============================================================================
~RButton::
    global lastRightClickTime, enableExertCounter, isRunning, currentExertCounts
    lastRightClickTime := A_TickCount
    
    ; Exertカウントを減少
    if (enableExertCounter && isRunning) {
        DecrementExertCounts()
    }
return

; ==============================================================================
; Exertカウント減少関数
; ==============================================================================
DecrementExertCounts() {
    global currentExertCounts
    
    ; 全てのWarcryのExertカウントを確認
    for key, count in currentExertCounts {
        if (count > 0) {
            currentExertCounts[key] := count - 1
            
            ; デバッグモードがONの場合のみログ出力
            if (debugMode) {
                DebugLog("Exert " . key . ": " . currentExertCounts[key])
            }
        }
    }
}

; ==============================================================================
; スクリプト終了時の処理
; ==============================================================================
OnExit:
    CleanupGUI()
    DestroyOverlay()
ExitApp

; ==============================================================================
; 動的スキル管理用のグローバルラベル定義（既存のまま）
; ==============================================================================

; ListView用イベントハンドラー
WarcryListViewEvent:
    if (A_GuiEvent = "DoubleClick") {
        EditWarcryFromListView()
    }
return

RegularListViewEvent:
    if (A_GuiEvent = "DoubleClick") {
        EditRegularFromListView()
    }
return

AddNewWarcryDialog:
    global CurrentWarcries
    if (CurrentWarcries.Length() >= 6) {
        MsgBox, 48, Warning, Maximum 6 Warcries allowed
        return
    }
    editIndex := 0
    ShowWarcryEditDialogWrapper(editIndex)
return

AddNewRegularDialog:
    global CurrentRegularSkills
    if (CurrentRegularSkills.Length() >= 5) {
        MsgBox, 48, Warning, Maximum 5 Regular Skills allowed
        return
    }
    editIndex := 0
    ShowRegularEditDialogWrapper(editIndex)
return

EditWarcry:
    EditWarcryFromListView()
return

EditRegular:
    EditRegularFromListView()
return

; ラベルから呼び出すためのラッパー関数（既存のまま）
EditWarcryFromListView() {
    Gui, Settings:Default
    Gui, ListView, WarcryListView
    selectedRow := LV_GetNext()
    if (selectedRow > 0) {
        ShowWarcryEditDialogWrapper(selectedRow)
    }
}

EditRegularFromListView() {
    Gui, Settings:Default
    Gui, ListView, RegularListView
    selectedRow := LV_GetNext()
    if (selectedRow > 0) {
        ShowRegularEditDialogWrapper(selectedRow)
    }
}

ShowWarcryEditDialogWrapper(editIndex) {
    ShowWarcryEditDialog(editIndex)
}

ShowRegularEditDialogWrapper(editIndex) {
    ShowRegularEditDialog(editIndex)
}

RemoveWarcryFromList:
    Gui, Settings:Default
    Gui, ListView, WarcryListView
    selectedRow := LV_GetNext()
    if (selectedRow > 0) {
        MsgBox, 52, Confirm, Remove this Warcry?
        IfMsgBox Yes
        {
            RemoveWarcryAtIndex(selectedRow)
        }
    }
return

RemoveRegularFromList:
    Gui, Settings:Default
    Gui, ListView, RegularListView
    selectedRow := LV_GetNext()
    if (selectedRow > 0) {
        MsgBox, 52, Confirm, Remove this skill?
        IfMsgBox Yes
        {
            RemoveRegularAtIndex(selectedRow)
        }
    }
return

WarcryDialogOK:
    ProcessWarcryDialogOK()
return

ProcessWarcryDialogOK() {
    global DialogWarcryName, DialogWarcryKey, DialogWarcryCooldown, DialogWarcryExert
    global CurrentWarcries, WarcrySkills, editingIndex
    
    Gui, WarcryDialog:Submit
    
    skill := {}
    skill.name := DialogWarcryName
    skill.key := DialogWarcryKey
    skill.cooldown := DialogWarcryCooldown
    skill.exert := DialogWarcryExert
    
    if (skill.name = "" || skill.key = "") {
        MsgBox, 48, Error, Name and Key are required
        return
    }
    
    if (WarcrySkills.HasKey(skill.name)) {
        defaults := WarcrySkills[skill.name]
        if (skill.cooldown = "") {
            skill.cooldown := defaults.defaultCooldown
        }
        if (skill.exert = "") {
            skill.exert := defaults.defaultExert
        }
    }
    
    if (editingIndex > 0) {
        CurrentWarcries[editingIndex] := skill
    } else {
        CurrentWarcries.Push(skill)
    }
    
    UpdateWarcryListView()
    Gui, WarcryDialog:Destroy
}

WarcryDialogCancel:
    Gui, WarcryDialog:Destroy
return

RegularDialogOK:
    ProcessRegularDialogOK()
return

ProcessRegularDialogOK() {
    global DialogRegularName, DialogRegularKey, DialogRegularMin, DialogRegularMax
    global CurrentRegularSkills, RegularSkills, editingIndex
    
    Gui, RegularDialog:Submit
    
    skill := {}
    skill.name := DialogRegularName
    skill.key := DialogRegularKey
    skill.intervalMin := DialogRegularMin
    skill.intervalMax := DialogRegularMax
    
    if (skill.name = "" || skill.key = "") {
        MsgBox, 48, Error, Name and Key are required
        return
    }
    
    if (skill.intervalMax < skill.intervalMin) {
        MsgBox, 48, Error, Max interval must be >= Min interval
        return
    }
    
    if (RegularSkills.HasKey(skill.name)) {
        defaults := RegularSkills[skill.name]
        if (skill.intervalMin = "") {
            skill.intervalMin := defaults.defaultInterval
        }
        if (skill.intervalMax = "") {
            skill.intervalMax := defaults.defaultInterval + 100
        }
    }
    
    if (editingIndex > 0) {
        CurrentRegularSkills[editingIndex] := skill
    } else {
        CurrentRegularSkills.Push(skill)
    }
    
    UpdateRegularListView()
    Gui, RegularDialog:Destroy
}

RegularDialogCancel:
    Gui, RegularDialog:Destroy
return