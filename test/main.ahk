; Path of Exile用AutoHotkeyマクロ (モジュール分割版)
; メインスクリプト (エントリーポイント)
; Version 2.5 - 動的スキル管理対応（修正版）

#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%

; DPIスケーリング対応（マルチディスプレイ環境用）
DllCall("SetProcessDPIAware")

; ==============================================================================
; モジュールの読み込み
; ==============================================================================
#Include %A_ScriptDir%\config\settings.ahk
#Include %A_ScriptDir%\modules\core.ahk
#Include %A_ScriptDir%\modules\gui.ahk
#Include %A_ScriptDir%\modules\flasks.ahk
#Include %A_ScriptDir%\modules\skills.ahk
#Include %A_ScriptDir%\modules\overlay.ahk

; JSON ライブラリ
#Include %A_ScriptDir%\lib\JSON.ahk

; GUI モジュール
#Include %A_ScriptDir%\gui\settings_gui.ahk
#Include %A_ScriptDir%\gui\profile_manager.ahk
#Include %A_ScriptDir%\gui\dynamic_skill_manager.ahk  ; v2.5 新規追加

; ==============================================================================
; グローバル変数の初期化
; ==============================================================================
; マクロ全体の実行状態を管理
global isRunning := false

; ==============================================================================
; 初期化処理
; ==============================================================================
; オーバーレイを初期化（最初は非表示）
InitializeOverlay()

; デフォルトプロファイルの確認
CheckDefaultProfile()

; 動的スキル管理の初期化（v2.5）
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

; F12キーでマクロの開始/停止
F12::
    isRunning := !isRunning
    if (isRunning) {
        ; v2.5: 動的スキル設定を適用
        ApplyDynamicSkillSettings()
        
        ShowBigNotification("マクロ開始", "フラスコループ実行中", "00FF00")
        StartAllTimers() ; core.ahkの関数を呼び出す
        ShowStatusIndicator() ; gui.ahkの関数を呼び出す
        ShowOverlay() ; overlay.ahkの関数を呼び出す
        UpdateMacroStatus(true) ; マクロON表示
    } else {
        ShowBigNotification("マクロ停止", "全処理を停止しました", "FF0000")
        StopAllTimers() ; core.ahkの関数を呼び出す
        HideOverlay() ; overlay.ahkの関数を呼び出す（マクロ状態表示以外を非表示）
        UpdateMacroStatus(false) ; マクロOFF表示
    }
return

; Ctrl+Shift+F12で緊急停止
^+F12::
    EmergencyStop() ; core.ahkの関数を呼び出す
    ShowBigNotification("緊急停止", "マクロを強制終了しました", "FF0000")
    HideOverlay() ; オーバーレイを非表示
    UpdateMacroStatus(false) ; マクロOFF表示
return

#IfWinActive

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
    CleanupGUI() ; gui.ahkの関数を呼び出す
    DestroyOverlay() ; overlay.ahkの関数を呼び出す
ExitApp

; ==============================================================================
; 動的スキル管理用のグローバルラベル定義（main.ahkの最後に追加）
; ==============================================================================

; ListView用イベントハンドラー
WarcryListViewEvent:
    ; ダブルクリックで編集
    if (A_GuiEvent = "DoubleClick") {
        EditWarcryFromListView()
    }
return

; Regular ListView イベント
RegularListViewEvent:
    ; ダブルクリックで編集
    if (A_GuiEvent = "DoubleClick") {
        EditRegularFromListView()
    }
return

; Warcry追加ダイアログ（修正版）
AddNewWarcryDialog:
    global CurrentWarcries
    if (CurrentWarcries.Length() >= 6) {
        MsgBox, 48, Warning, Maximum 6 Warcries allowed
        return
    }
    ; 関数呼び出しを別の処理として実行
    editIndex := 0
    ShowWarcryEditDialogWrapper(editIndex)
return

; Regular追加ダイアログ（修正版）
AddNewRegularDialog:
    global CurrentRegularSkills
    if (CurrentRegularSkills.Length() >= 5) {
        MsgBox, 48, Warning, Maximum 5 Regular Skills allowed
        return
    }
    ; 関数呼び出しを別の処理として実行
    editIndex := 0
    ShowRegularEditDialogWrapper(editIndex)
return

; Warcry編集
EditWarcry:
    EditWarcryFromListView()
return

; Regular編集
EditRegular:
    EditRegularFromListView()
return

; ラベルから呼び出すためのラッパー関数
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

; ダイアログ表示のラッパー関数
ShowWarcryEditDialogWrapper(editIndex) {
    ShowWarcryEditDialog(editIndex)
}

ShowRegularEditDialogWrapper(editIndex) {
    ShowRegularEditDialog(editIndex)
}

; Warcry削除
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

; Regular削除
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

; Warcryダイアログ - OK
WarcryDialogOK:
    ProcessWarcryDialogOK()
return

; Warcryダイアログ処理関数
ProcessWarcryDialogOK() {
    global DialogWarcryName, DialogWarcryKey, DialogWarcryCooldown, DialogWarcryExert
    global CurrentWarcries, WarcrySkills, editingIndex
    
    Gui, WarcryDialog:Submit
    
    ; 新規追加または編集
    skill := {}
    skill.name := DialogWarcryName
    skill.key := DialogWarcryKey
    skill.cooldown := DialogWarcryCooldown
    skill.exert := DialogWarcryExert
    
    ; 検証
    if (skill.name = "" || skill.key = "") {
        MsgBox, 48, Error, Name and Key are required
        return
    }
    
    ; デフォルト値設定
    if (WarcrySkills.HasKey(skill.name)) {
        defaults := WarcrySkills[skill.name]
        if (skill.cooldown = "") {
            skill.cooldown := defaults.defaultCooldown
        }
        if (skill.exert = "") {
            skill.exert := defaults.defaultExert
        }
    }
    
    ; 編集インデックスを取得
    if (editingIndex > 0) {
        ; 編集
        CurrentWarcries[editingIndex] := skill
    } else {
        ; 新規追加
        CurrentWarcries.Push(skill)
    }
    
    UpdateWarcryListView()
    Gui, WarcryDialog:Destroy
}

; Warcryダイアログ - Cancel
WarcryDialogCancel:
    Gui, WarcryDialog:Destroy
return

; Regularダイアログ - OK
RegularDialogOK:
    ProcessRegularDialogOK()
return

; Regularダイアログ処理関数
ProcessRegularDialogOK() {
    global DialogRegularName, DialogRegularKey, DialogRegularMin, DialogRegularMax
    global CurrentRegularSkills, RegularSkills, editingIndex
    
    Gui, RegularDialog:Submit
    
    ; 新規追加または編集
    skill := {}
    skill.name := DialogRegularName
    skill.key := DialogRegularKey
    skill.intervalMin := DialogRegularMin
    skill.intervalMax := DialogRegularMax
    
    ; 検証
    if (skill.name = "" || skill.key = "") {
        MsgBox, 48, Error, Name and Key are required
        return
    }
    
    if (skill.intervalMax < skill.intervalMin) {
        MsgBox, 48, Error, Max interval must be >= Min interval
        return
    }
    
    ; デフォルト値設定
    if (RegularSkills.HasKey(skill.name)) {
        defaults := RegularSkills[skill.name]
        if (skill.intervalMin = "") {
            skill.intervalMin := defaults.defaultInterval
        }
        if (skill.intervalMax = "") {
            skill.intervalMax := defaults.defaultInterval + 100
        }
    }
    
    ; 編集インデックスを取得
    if (editingIndex > 0) {
        ; 編集
        CurrentRegularSkills[editingIndex] := skill
    } else {
        ; 新規追加
        CurrentRegularSkills.Push(skill)
    }
    
    UpdateRegularListView()
    Gui, RegularDialog:Destroy
}

; Regularダイアログ - Cancel
RegularDialogCancel:
    Gui, RegularDialog:Destroy
return