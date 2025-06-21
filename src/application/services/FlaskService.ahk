; ==============================================================================
; FlaskService - フラスコ管理サービス
; Path: src/application/services/FlaskService.ahk
; ==============================================================================

class FlaskService {
    ; 依存サービス
    container := ""
    eventBus := ""
    config := ""
    
    ; 内部状態
    timers := {}
    tinctureActive := false
    tinctureLastUsedTime := 0
    lastExecutionTimes := {}
    
    ; ==============================================================================
    ; コンストラクタ
    ; ==============================================================================
    __New(container) {
        this.container := container
        this.eventBus := container.Get("EventBus")
        this.config := container.Get("Config")
        
        ; イベントリスナーの登録
        this.RegisterEventListeners()
    }
    
    ; ==============================================================================
    ; サービスの開始
    ; ==============================================================================
    Start() {
        ; タイマーの初期化
        this.ResetTimers()
        
        ; 各フラスコ処理を開始
        this.StartAdrenalineTimer()
        this.StartTinctureTimer()
        this.StartGoldFlaskTimer()
        this.StartSulphurFlaskTimer()
        
        ; 開始イベントを発行
        this.eventBus.Emit("flask.service.started")
        
        return this
    }
    
    ; ==============================================================================
    ; サービスの停止
    ; ==============================================================================
    Stop() {
        ; すべてのタイマーを停止
        this.StopAllTimers()
        
        ; 状態をリセット
        this.ResetState()
        
        ; 停止イベントを発行
        this.eventBus.Emit("flask.service.stopped")
        
        return this
    }
    
    ; ==============================================================================
    ; Adrenaline処理（R -> E -> 1）
    ; ==============================================================================
    ExecuteAdrenaline() {
        config := this.config
        
        if (!this.IsActiveAndRunning()) {
            return
        }
        
        ; キーシーケンスの実行
        Send, % config.key_adrenaline_1
        Sleep, 50
        Send, % config.key_adrenaline_2
        
        Random, delayBefore1, 50, 70
        Sleep, %delayBefore1%
        Send, % config.key_lifeFlask
        
        ; 実行時間を記録
        this.lastExecutionTimes.adrenaline := A_TickCount
        
        ; イベント発行
        eventData := {}
        eventData.timestamp := A_TickCount
        eventData.keys := [config.key_adrenaline_1, config.key_adrenaline_2, config.key_lifeFlask]
        this.eventBus.Emit("flask.adrenaline.executed", eventData)
        
        ; 次回実行をスケジュール
        Random, interval, % config.interval_adrenaline_min, % config.interval_adrenaline_max
        fn := this.CreateTimerFunction("ExecuteAdrenaline")
        SetTimer, %fn%, % -1 * interval
    }
    
    ; ==============================================================================
    ; Tinctureサイクル処理
    ; ==============================================================================
    ExecuteTincture() {
        config := this.config
        
        if (!this.IsActiveAndRunning()) {
            return
        }
        
        ; マナフラスコ → Tincture
        Send, % config.key_manaFlask
        Random, delayManaToTincture, 30, 70
        Sleep, %delayManaToTincture%
        
        Send, % config.key_tincture
        this.tinctureActive := true
        this.tinctureLastUsedTime := A_TickCount
        
        ; イベント発行
        eventData := {}
        eventData.timestamp := A_TickCount
        this.eventBus.Emit("flask.tincture.activated", eventData)
        
        ; マナフラスコループを開始
        this.StartManaFlaskLoop()
        
        ; Tincture終了タイマーを設定
        fn := this.CreateTimerFunction("EndTincture")
        SetTimer, %fn%, % -1 * config.duration_tincture
    }
    
    ; ==============================================================================
    ; Tincture終了処理
    ; ==============================================================================
    EndTincture() {
        config := this.config
        
        this.StopManaFlaskLoop()
        this.tinctureActive := false
        
        ; イベント発行
        eventData := {}
        eventData.timestamp := A_TickCount
        this.eventBus.Emit("flask.tincture.deactivated", eventData)
        
        ; クールダウン後に次のサイクルを開始
        Random, cooldown, % config.cooldown_tincture_min, % config.cooldown_tincture_max
        fn := this.CreateTimerFunction("ExecuteTincture")
        SetTimer, %fn%, % -1 * cooldown
    }
    
    ; ==============================================================================
    ; マナフラスコループ
    ; ==============================================================================
    ExecuteManaFlask() {
        config := this.config
        
        if (!this.IsActiveAndRunning() || !this.tinctureActive) {
            this.StopManaFlaskLoop()
            return
        }
        
        Send, % config.key_manaFlask
        
        ; イベント発行
        eventData := {}
        eventData.timestamp := A_TickCount
        eventData.tinctureActive := this.tinctureActive
        this.eventBus.Emit("flask.mana.used", eventData)
        
        ; 次回実行をスケジュール
        fn := this.CreateTimerFunction("ExecuteManaFlask")
        SetTimer, %fn%, % -1 * config.interval_manaFlask
    }
    
    ; ==============================================================================
    ; Gold Flask処理
    ; ==============================================================================
    ExecuteGoldFlask() {
        config := this.config
        
        if (!this.IsActiveAndRunning()) {
            return
        }
        
        Send, % config.key_goldFlask
        
        ; 実行時間を記録
        this.lastExecutionTimes.goldFlask := A_TickCount
        
        ; イベント発行
        eventData := {}
        eventData.timestamp := A_TickCount
        this.eventBus.Emit("flask.gold.used", eventData)
        
        ; 次回実行をスケジュール
        Random, interval, % config.interval_goldFlask_min, % config.interval_goldFlask_max
        fn := this.CreateTimerFunction("ExecuteGoldFlask")
        SetTimer, %fn%, % -1 * interval
    }
    
    ; ==============================================================================
    ; Sulphur Flask処理
    ; ==============================================================================
    ExecuteSulphurFlask() {
        config := this.config
        
        if (!this.IsActiveAndRunning()) {
            return
        }
        
        Send, % config.key_sulphurFlask
        
        ; イベント発行
        eventData := {}
        eventData.timestamp := A_TickCount
        this.eventBus.Emit("flask.sulphur.used", eventData)
        
        ; 次回実行をスケジュール
        Random, interval, % config.interval_sulphur_min, % config.interval_sulphur_max
        fn := this.CreateTimerFunction("ExecuteSulphurFlask")
        SetTimer, %fn%, % -1 * interval
    }
    
    ; ==============================================================================
    ; ヘルパー関数
    ; ==============================================================================
    
    IsActiveAndRunning() {
        macroService := this.container.Get("MacroService")
        return WinActive("ahk_exe PathOfExileSteam.exe") && macroService.IsRunning()
    }
    
    CreateTimerFunction(methodName) {
        return ObjBindMethod(this, methodName)
    }
    
    StartAdrenalineTimer() {
        fn := this.CreateTimerFunction("ExecuteAdrenaline")
        SetTimer, %fn%, -100
    }
    
    StartTinctureTimer() {
        fn := this.CreateTimerFunction("ExecuteTincture")
        SetTimer, %fn%, -200
    }
    
    StartGoldFlaskTimer() {
        fn := this.CreateTimerFunction("ExecuteGoldFlask")
        SetTimer, %fn%, -300
    }
    
    StartSulphurFlaskTimer() {
        fn := this.CreateTimerFunction("ExecuteSulphurFlask")
        SetTimer, %fn%, -400
    }
    
    StartManaFlaskLoop() {
        config := this.config
        fn := this.CreateTimerFunction("ExecuteManaFlask")
        SetTimer, %fn%, % -1 * config.interval_manaFlask
    }
    
    StopManaFlaskLoop() {
        fn := this.CreateTimerFunction("ExecuteManaFlask")
        SetTimer, %fn%, Off
    }
    
    StopAllTimers() {
        ; 各タイマーを個別に停止
        fnAdrenaline := this.CreateTimerFunction("ExecuteAdrenaline")
        fnTincture := this.CreateTimerFunction("ExecuteTincture")
        fnEndTincture := this.CreateTimerFunction("EndTincture")
        fnManaFlask := this.CreateTimerFunction("ExecuteManaFlask")
        fnGoldFlask := this.CreateTimerFunction("ExecuteGoldFlask")
        fnSulphurFlask := this.CreateTimerFunction("ExecuteSulphurFlask")
        
        SetTimer, %fnAdrenaline%, Off
        SetTimer, %fnTincture%, Off
        SetTimer, %fnEndTincture%, Off
        SetTimer, %fnManaFlask%, Off
        SetTimer, %fnGoldFlask%, Off
        SetTimer, %fnSulphurFlask%, Off
    }
    
    ResetTimers() {
        this.timers := {}
    }
    
    ResetState() {
        this.tinctureActive := false
        this.tinctureLastUsedTime := 0
        this.lastExecutionTimes := {}
    }
    
    RegisterEventListeners() {
        ; 他のサービスからのイベントを監視する場合はここに追加
    }
    
    ; ==============================================================================
    ; 公開API
    ; ==============================================================================
    
    IsTinctureActive() {
        return this.tinctureActive
    }
    
    GetLastExecutionTime(flaskType) {
        return this.lastExecutionTimes.HasKey(flaskType) 
            ? this.lastExecutionTimes[flaskType] 
            : 0
    }
    
    GetManaBurnStacks() {
        if (!this.tinctureActive) {
            return 0
        }
        
        config := this.config
        elapsed := A_TickCount - this.tinctureLastUsedTime
        return Floor(elapsed / config.manaBurnStackRate)
    }
}