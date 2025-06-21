; ==============================================================================
; 設定ファイル (キー割り当て、タイミング、その他)
; ==============================================================================

; --- フラスコキー設定 ---
global key_lifeFlask         := "1"
global key_sulphurFlask      := "2"
global key_tincture          := "3"
global key_goldFlask         := "4"
global key_manaFlask         := "5"

; --- スキルキー設定 ---
global key_adrenaline_1      := "r"
global key_adrenaline_2      := "e"
global key_bloodRage         := "e" ; Adrenalineとキーが重複するが、処理系が異なる
global key_skill_T           := "t"
global key_skill_B           := "b"

; --- フラスコ・バフのタイミング設定 (ミリ秒) ---
; Adrenaline (R->E->1)
global interval_adrenaline_min := 28600
global interval_adrenaline_max := 28800

; Tinctureサイクル
global duration_tincture     := 33480 ; Tincture持続時間
global cooldown_tincture_min := 5960  ; Tinctureクールダウン
global cooldown_tincture_max := 6160

; Mana Flask (Tincture効果中)
global interval_manaFlask    := 4500

; Gold Flask (Wine of the Prophet)
global interval_goldFlask_min  := 28600
global interval_goldFlask_max  := 28700

; Sulphur Flask (The Overflowing Chalice)
global interval_sulphur_min  := 300
global interval_sulphur_max  := 1000

; --- 定期実行スキルのタイミング設定 (ミリ秒) ---
global interval_skill_T_min    := 4010
global interval_skill_T_max    := 4100

global interval_bloodRage_min  := 10000
global interval_bloodRage_max  := 10100

global interval_skill_B_min    := 3000
global interval_skill_B_max    := 3100

; --- スキルキューシステムの設定 ---
global skillQueue_castTime     := 270 ; キャストロック時間(ms)
global skillQueue_checkInterval:= 100   ; 次のスキルをチェックする間隔(ms)
global rightClick_lockDuration := 620   ; 右クリック後、スキルキューをロックする時間(ms)

; スキルキュー対象のキーとクールダウン(ms)
global skillQueue_keys := ["L", "K", "O", "N"]
global skillCooldowns := { L: 5260, K: 5260, O: 5260, N: 5260 }

; --- Warcry Exert設定 ---
global enableExertCounter := true    ; Exertカウンター機能のON/OFF

; 各WarcryのExert回数設定
global warcryExertCounts := { L: 3    ; Intimidating Cry - 3回
                           , K: 7    ; Seismic Cry - 7回
                           , O: 0    ; Enduring Cry - Exertなし（防御系）
                           , N: 6 }  ; Rallying Cry - 6回

; 現在のExert残り回数（実行時に動的に変更される）
global currentExertCounts := { L: 0, K: 0, O: 0, N: 0 }

; Exertカウント表示設定
global exertCountFontSize := 20     ; カウント数字のフォントサイズ
global exertCountOffsetX := 44      ; アイコンからの水平オフセット
global exertCountOffsetY := 2       ; アイコンからの垂直オフセット

; --- GUI設定 ---
global notification_duration := 1500 ; 通知の表示時間(ms)

; --- オーバーレイ設定 ---
global manaBurnStackRate := 520  ; Mana Burnスタックが増加する間隔(ms) - 0.52秒

; オーバーレイ位置調整（スキル・フラスコ表示）
global overlayOffsetX := 740     ; 水平方向のオフセット（画面左端からの距離）
global overlayOffsetY := -140    ; 垂直方向のオフセット（画面下部）
global overlaySpacing := 90      ; 各要素間の間隔（ピクセル）

; マクロON/OFF表示位置
global macroStatusOffsetX := 580    ; マクロ状態表示の水平位置
global macroStatusOffsetY := -200   ; マクロ状態表示の垂直位置

; マルチモニター設定
global useSpecificMonitor := true   ; true: 特定のモニターに固定、false: ゲームウィンドウのあるモニターを自動検出
global specificMonitorNumber := 1   ; 使用するモニター番号（1=中央のプライマリモニター）

; --- 実行時間記録用変数（オーバーレイ用） ---
global lastAdrenalineTime := 0
global lastGoldFlaskTime := 0
global lastSkillTTime := 0
global lastSkillBTime := 0

; --- デバッグ設定 ---
global debugMode := false  ; true にするとデバッグログが有効化される

; ==============================================================================
; ユーティリティ関数
; ==============================================================================

; デバッグログ出力関数
DebugLog(message) {
    global debugMode
    if (debugMode) {
        FormatTime, timeStamp, , yyyy-MM-dd HH:mm:ss
        FileAppend, %timeStamp% - %message%`n, debug_log.txt
    }
}