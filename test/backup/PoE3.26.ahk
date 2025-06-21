; Path of Exile用AutoHotkeyマクロ (Tincture対応版)
;
; === 重要な注意事項 ===
; Tinctureの仕様：
; - 持続時間：33.48秒（Mana Burn 62スタック × 0.54秒）
; - クールダウン：5.96秒
; - 合計サイクル：約39.44秒 (33.48秒持続 + 5.96秒クールダウン)
; マナフラスコの持続時間：
; - 5秒固定（フラスコ効果時間増加やRunegraftの影響を受けない）
; - Tincture効果中のみ4.5秒間隔で使用
; アドレナリンバフ：
; - 元の持続時間：20秒 → Runegraft効果(30% slower)で28.57秒に延長
; - 28.6秒間隔で使用して効果を維持
; Wine of the Prophet Gold Flask：
; - 最大チャージ140、使用に72チャージ必要
; - 20秒バフ → Runegraftで28.6秒に延長
; - 28.6秒間隔で使用して効果を維持
; The Overflowing Chalice Sulphur Flask:
; - 持続時間8秒
; - チャージがたまり次第、間隔を空けて連打し使用
;
; === 操作方法 ===
; F12: マクロを開始/停止
; Ctrl+Shift+F12: 緊急停止
;
; === フラスコ配置 ===
; 1: Life Flask
; 2: The Overflowing Chalice Sulphur Flask
; 3: Sap of The seasons Prismatic Tincture (33.48秒持続、5.96秒クールダウン)
; 4: Wine of the Prophet Gold Flask (20秒バフ、Runegraftで28.6秒に延長)
; 5: Divine Mana Flask (持続時間5秒固定、66% reduced recovery, Effect not removed when full, No queue)
;
; === 自動実行される処理 ===
; 1: R→E→1 (Adrenaline獲得＋ライフ回復、28.6秒間隔)
; 2: 5→3キー (マナフラスコ→Tincture、39.44秒サイクルで使用：33.48秒持続＋5.96秒クールダウン)
; 3: 5キー (Mana Flask、Tincture効果中のみ4.5秒間隔で使用)
; 4: 4キー (Gold Flask、28.6秒間隔 - 20秒バフがRunegraftで延長)
; 5: 2キー (Sulphur Flask、チャージがたまり次第連打)
; 6: Skill T
; 7: Blood Rage (Eキー)
; 8: Skill B
; 9: スキルキュー (L,K,O,N)

#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%

; === グローバル変数 ===
isRunning := false

; スキルキュー用
skillNextTime := {}, skillCooldowns := {}, isCasting := false, castTime := 270
skillCooldowns.L := 5260, skillCooldowns.K := 5260, skillCooldowns.O := 5260, skillCooldowns.N := 5260

; 右クリック攻撃管理用 (スキルキューの発動条件に使用)
lastRightClickTime := 0, rightClickAttackMinDuration := 620

; Tincture状態管理
tinctureActive := false
tinctureLastUsedTime := 0

; === ウィンドウ指定 ===
#IfWinActive ahk_exe PathOfExileSteam.exe

; === ホットキー定義 ===

; 右クリックの押下時間を記録
~RButton::
    lastRightClickTime := A_TickCount
return

; F12キーでマクロの開始/停止
F12::
    isRunning := !isRunning
    if (isRunning) {
        ShowBigNotification("マクロ開始", "Tincture対応フラスコループ実行中", "00FF00")
        GoSub, StartAllTimers
        ShowStatusIndicator()
    } else {
        ShowBigNotification("マクロ停止", "全処理を停止しました", "FF0000")
        StopAllTimers()
    }
return

; Ctrl+Shift+F12で緊急停止
^+F12::
    StopAllTimers()
    isRunning := false
    tinctureActive := false
    tinctureLastUsedTime := 0
    lastRightClickTime := 0
    ShowBigNotification("緊急停止", "マクロを強制終了しました", "FF0000")
return

; === タイマー開始処理 ===

StartAllTimers:
    ; 各タイマーを初期化し、即座に一度実行する
    GoSub, ExecuteAdrenalineR
    GoSub, ExecuteTinctureCycle  ; 初回のTinctureサイクルを開始
    GoSub, ExecuteGoldFlask
    GoSub, ExecuteSulphurFlask
    GoSub, ExecuteMacroT
    GoSub, ExecuteMacroE
    GoSub, ExecuteMacroB
    GoSub, StartSkillQueue
return

; === 全タイマー停止処理 ===
StopAllTimers() {
    global tinctureActive, tinctureLastUsedTime, lastRightClickTime
    Gui, StatusIndicator:Destroy
    
    ; 変数リセット
    tinctureActive := false
    tinctureLastUsedTime := 0
    lastRightClickTime := 0

    ; 全てのSetTimerをOffにする
    SetTimer, ExecuteAdrenalineR, Off
    SetTimer, ExecuteManaFlask, Off
    SetTimer, CheckTinctureExpiration, Off
    SetTimer, StartNextTinctureCycle, Off
    SetTimer, ExecuteGoldFlask, Off
    SetTimer, ExecuteSulphurFlask, Off
    SetTimer, ExecuteMacroT, Off
    SetTimer, ExecuteMacroE, Off
    SetTimer, ExecuteMacroB, Off
    SetTimer, SkillQueueLoop, Off
    SetTimer, EndCasting, Off
}

; === フラスコ・バフ管理 ===

; 処理1: R→E→1 (Adrenaline獲得＋ライフ回復、28.6秒間隔)
ExecuteAdrenalineR:
    if IfWinActiveAndRunning() {
        Send, r
        Sleep, 50
        Send, e
        Random, delayBefore1, 50, 70
        Sleep, %delayBefore1%
        Send, 1
        Random, interval, 28600, 28800
        SetTimer, ExecuteAdrenalineR, %interval%
    }
return

; 処理2&3: マナフラスコ先行のTincture使用とマナフラスコループ管理
ExecuteTinctureCycle:
    global tinctureActive, tinctureLastUsedTime
    if IfWinActiveAndRunning() {
        ; 最初にマナフラスコを使用
        Send, 5
        Random, delayManaToTincture, 30, 70
        Sleep, %delayManaToTincture%
        
        ; 次にTincture使用
        Send, 3
        tinctureActive := true
        tinctureLastUsedTime := A_TickCount
        Sleep, 100
        
        ; マナフラスコループを開始（次回は4.5秒後から）
        SetTimer, ExecuteManaFlask, Off
        SetTimer, ExecuteManaFlask, 4500
        
        ; Tinctureの持続時間後にマナフラスコを停止
        SetTimer, CheckTinctureExpiration, Off
        SetTimer, CheckTinctureExpiration, 33480
    }
return

; Tinctureの有効期限チェックとマナフラスコ停止
CheckTinctureExpiration:
    global tinctureActive
    if IfWinActiveAndRunning() {
        SetTimer, ExecuteManaFlask, Off
        tinctureActive := false
        
        ; クールダウン後に次のサイクルを開始
        Random, cooldownDelay, 5960, 6160
        SetTimer, StartNextTinctureCycle, %cooldownDelay%
    }
return

; 次のTinctureサイクルを開始
StartNextTinctureCycle:
    SetTimer, StartNextTinctureCycle, Off
    if IfWinActiveAndRunning() {
        GoSub, ExecuteTinctureCycle
    }
return

; マナフラスコループ（Tincture効果中のみ）
ExecuteManaFlask:
    global tinctureActive
    if (IfWinActiveAndRunning() && tinctureActive) {
        Send, 5
    } else {
        SetTimer, ExecuteManaFlask, Off
    }
return

; 処理4: 4キー (Wine of the Prophet Gold Flask、28.6秒間隔)
ExecuteGoldFlask:
    if IfWinActiveAndRunning() {
        Send, 4
        Random, interval, 28600, 28700
        SetTimer, ExecuteGoldFlask, %interval%
    }
return

; 処理5: 2キー (The Overflowing Chalice Sulphur Flask、チャージがたまり次第連打)
ExecuteSulphurFlask:
    if IfWinActiveAndRunning() {
        Send, 2
        Random, interval, 300, 1000
        SetTimer, ExecuteSulphurFlask, %interval%
    }
return

; === スキル実行 ===

; Tキー
ExecuteMacroT:
    if IfWinActiveAndRunning() {
        Send, t
        Random, interval, 4010, 4100
        SetTimer, ExecuteMacroT, %interval%
    }
return

; Eキー (Blood Rage)
ExecuteMacroE:
    if IfWinActiveAndRunning() {
        Send, e
        Random, interval, 10000, 10100
        SetTimer, ExecuteMacroE, %interval%
    }
return

; Bキー
ExecuteMacroB:
    if IfWinActiveAndRunning() {
        Send, b
        Random, interval, 3000, 3100
        SetTimer, ExecuteMacroB, %interval%
    }
return

; === スキルキューシステム (L,K,O,N) ===
StartSkillQueue:
    currentTime := A_TickCount
    isCasting := false
    skillNextTime.L := currentTime, skillNextTime.K := currentTime + 500, skillNextTime.O := currentTime + 1000, skillNextTime.N := currentTime + 1500
    SetTimer, SkillQueueLoop, 100
return

SkillQueueLoop:
    if IfWinActiveAndRunning() {
        if isCasting || GetKeyState("LButton", "P") || GetKeyState("Q", "P")
            return
            
        currentTime := A_TickCount
        if (GetKeyState("RButton", "P") || (currentTime - lastRightClickTime < rightClickAttackMinDuration))
            return

        oldestSkill := "", oldestTime := currentTime + 999999
        for key, nextTime in skillNextTime {
            if (nextTime <= currentTime && nextTime < oldestTime) {
                oldestSkill := key, oldestTime := nextTime
            }
        }

        if (oldestSkill != "") {
            isCasting := true
            StringLower, lowerKey, oldestSkill
            Send, %lowerKey%
            
            Random, randomDelay, 0, 100
            skillNextTime[oldestSkill] := currentTime + skillCooldowns[oldestSkill] + randomDelay
            
            SetTimer, EndCasting, %castTime%
        }
    }
return

EndCasting:
    isCasting := false
    SetTimer, EndCasting, Off
return

; === ユーティリティ関数 ===

; PoEがアクティブかつマクロ実行中かチェック
IfWinActiveAndRunning() {
    global isRunning
    if (!WinActive("ahk_exe PathOfExileSteam.exe") || !isRunning) {
        return false
    }
    return true
}

; GUI: 状態インジケーター
ShowStatusIndicator() {
    Gui, StatusIndicator:Destroy
    Gui, StatusIndicator:New, +AlwaysOnTop -Caption +ToolWindow +E0x20
    Gui, StatusIndicator:Color, 000000
    Gui, StatusIndicator:Font, s18 c00FF00 Bold, Arial
    Gui, StatusIndicator:Add, Text, Center, ● 実行中
    
    SysGet, MonitorWorkArea, MonitorWorkArea
    xPos := MonitorWorkAreaRight - 200
    yPos := MonitorWorkAreaBottom - 120
    Gui, StatusIndicator:Show, NoActivate x%xPos% y%yPos% w180 h50
    WinSet, Transparent, 180, ahk_id %StatusIndicator%
    Gui, StatusIndicator:+Border
}

; GUI: 大きな通知
ShowBigNotification(mainText, subText, color) {
    Gui, Notification:Destroy
    Gui, Notification:New, +AlwaysOnTop -Caption +ToolWindow +E0x20
    Gui, Notification:Color, 000000
    Gui, Notification:Font, s24 c%color% Bold, Arial
    Gui, Notification:Add, Text, Center, %mainText%
    Gui, Notification:Font, s16 cFFFFFF Normal
    Gui, Notification:Add, Text, Center, %subText%
    Gui, Notification:Show, NoActivate xCenter yCenter
    WinSet, Transparent, 200, ahk_class AutoHotkeyGUI
    SetTimer, RemoveNotification, 1500
}

RemoveNotification:
    Gui, Notification:Destroy
    SetTimer, RemoveNotification, Off
return

#IfWinActive

; スクリプト終了時のクリーンアップ
OnExit:
    Gui, Notification:Destroy
    Gui, StatusIndicator:Destroy
ExitApp