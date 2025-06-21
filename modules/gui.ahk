; ==============================================================================
; GUIモジュール (通知表示のみ)
; ==============================================================================

; --- 実行中インジケーターを表示する（削除） ---
; この関数は互換性のために残しますが、何もしません
ShowStatusIndicator() {
    ; 削除済み - マクロON/OFF表示はoverlay.ahkで管理
}

; --- 実行中インジケーターを非表示にする（削除） ---
; この関数は互換性のために残しますが、何もしません
HideStatusIndicator() {
    ; 削除済み - マクロON/OFF表示はoverlay.ahkで管理
}

; --- 大きな通知を画面中央に表示する ---
; main.ahk のホットキーから呼び出される
ShowBigNotification(mainText, subText, color) {
    global Notification, notification_duration
    Gui, Notification:Destroy
    Gui, Notification:New, +AlwaysOnTop -Caption +ToolWindow +E0x20
    Gui, Notification:Color, 000000
    Gui, Notification:Font, s24 c%color% Bold, Arial
    Gui, Notification:Add, Text, Center, %mainText%
    Gui, Notification:Font, s16 cFFFFFF Normal
    Gui, Notification:Add, Text, Center, %subText%
    Gui, Notification:Show, NoActivate xCenter yCenter
    WinSet, Transparent, 200, ahk_class AutoHotkeyGUI
    
    ; config/settings.ahk で設定した時間後に通知を消す
    SetTimer, RemoveNotification, % -1 * notification_duration
}

; --- 通知を削除する ---
; ShowBigNotification() 内のタイマーによって呼び出される
RemoveNotification() {
    global Notification
    Gui, Notification:Destroy
}

; --- スクリプト終了時に全てのGUIをクリーンアップする ---
; main.ahk の OnExit から呼び出される
CleanupGUI() {
    RemoveNotification()
}