; Path of Exile用AutoHotkeyマクロ - デバッグテスト版
#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%

; ==============================================================================
; 設定を先に読み込む（重要）
; ==============================================================================
#Include %A_ScriptDir%\config\settings.ahk

; デバッグ出力
MsgBox, Debug 1: settings.ahk loaded`nkey_lifeFlask = %key_lifeFlask%

; ==============================================================================
; v3.0アーキテクチャの初期化
; ==============================================================================
#Include %A_ScriptDir%\src\bootstrap.ahk
#Include %A_ScriptDir%\src\infrastructure\LegacyAdapter.ahk

; デバッグ出力
MsgBox, Debug 2: Bootstrap loaded, initializing...

; v3.0システムの初期化
try {
    global appContainer := Bootstrap.Initialize()
    MsgBox, Debug 3: Bootstrap initialized successfully
} catch e {
    MsgBox, 16, Error, Bootstrap initialization failed:`n%e%
    ExitApp
}

; サービスの確認
try {
    config := appContainer.Get("Config")
    MsgBox, Debug 4: Config service retrieved`nkey_lifeFlask from config = %config.key_lifeFlask%
} catch e {
    MsgBox, 16, Error, Config service retrieval failed:`n%e%
}

; FlaskServiceの確認
try {
    flaskService := appContainer.Get("FlaskService")
    MsgBox, Debug 5: FlaskService retrieved successfully
} catch e {
    MsgBox, 16, Error, FlaskService retrieval failed:`n%e%
}

MsgBox, Debug complete. The script will now exit.
ExitApp