; ==============================================================================
; Bootstrap - v3.0アーキテクチャの初期化
; Path: src/bootstrap.ahk
; ==============================================================================

; 基盤システムの読み込み
#Include %A_ScriptDir%\src\infrastructure\ServiceContainer.ahk
#Include %A_ScriptDir%\src\infrastructure\EventBus.ahk

; サービスの読み込み
#Include %A_ScriptDir%\src\application\services\FlaskService.ahk

; ==============================================================================
; アプリケーションの初期化
; ==============================================================================
class Bootstrap {
    static container := ""
    static isInitialized := false
    
    ; ==============================================================================
    ; 初期化
    ; ==============================================================================
    Initialize() {
        if (Bootstrap.isInitialized) {
            return Bootstrap.container
        }
        
        ; サービスコンテナの取得
        Bootstrap.container := GetServiceContainer()
        
        ; 基盤サービスの登録
        Bootstrap.RegisterInfrastructure()
        
        ; アプリケーションサービスの登録
        Bootstrap.RegisterServices()
        
        ; イベントリスナーの設定
        Bootstrap.RegisterEventListeners()
        
        Bootstrap.isInitialized := true
        
        return Bootstrap.container
    }
    
    ; ==============================================================================
    ; 基盤サービスの登録
    ; ==============================================================================
    RegisterInfrastructure() {
        container := Bootstrap.container
        
        ; EventBusの登録
        container.RegisterSingleton("EventBus", Func("CreateEventBus"))
        
        ; 設定オブジェクトの登録（既存の変数をラップ）
        container.RegisterSingleton("Config", Func("CreateConfigWrapper"))
        
        ; MacroServiceの登録（既存のisRunning変数をラップ）
        container.RegisterSingleton("MacroService", Func("CreateMacroServiceWrapper"))
    }
    
    ; ==============================================================================
    ; アプリケーションサービスの登録
    ; ==============================================================================
    RegisterServices() {
        container := Bootstrap.container
        
        ; FlaskServiceの登録
        container.RegisterSingleton("FlaskService", Func("CreateFlaskService"))
        
        ; 今後追加するサービス
        ; container.RegisterSingleton("SkillService", Func("CreateSkillService"))
        ; container.RegisterSingleton("OverlayService", Func("CreateOverlayService"))
    }
    
    ; ==============================================================================
    ; イベントリスナーの設定
    ; ==============================================================================
    RegisterEventListeners() {
        global debugMode ; グローバル変数にアクセス
        eventBus := Bootstrap.container.Get("EventBus")
        
        ; エラーハンドリング
        eventBus.On("error", Func("HandleGlobalError"))
        
        ; フラスコイベントの監視（デバッグ用）
        if (debugMode) {
            eventBus.On("flask.adrenaline.executed", Func("LogFlaskEvent"))
            eventBus.On("flask.tincture.activated", Func("LogFlaskEvent"))
            eventBus.On("flask.tincture.deactivated", Func("LogFlaskEvent"))
            eventBus.On("flask.gold.used", Func("LogFlaskEvent"))
            eventBus.On("flask.sulphur.used", Func("LogFlaskEvent"))
            eventBus.On("flask.mana.used", Func("LogFlaskEvent"))
        }
    }
}

; ==============================================================================
; ファクトリー関数
; ==============================================================================

CreateEventBus(container) {
    return EventBus.GetInstance()
}

CreateConfigWrapper(container) {
    ; ConfigWrapperクラスを作成
    return new ConfigWrapper()
}

; ==============================================================================
; ConfigWrapperクラス - 設定へのアクセスを提供
; ==============================================================================
class ConfigWrapper {
    __New() {
        ; 何もしない - プロパティで動的にアクセス
    }
    
    ; プロパティゲッターで動的にグローバル変数にアクセス
    __Get(key) {
        global
        if (key = "key_lifeFlask")
            return key_lifeFlask
        else if (key = "key_sulphurFlask")
            return key_sulphurFlask
        else if (key = "key_tincture")
            return key_tincture
        else if (key = "key_goldFlask")
            return key_goldFlask
        else if (key = "key_manaFlask")
            return key_manaFlask
        else if (key = "key_adrenaline_1")
            return key_adrenaline_1
        else if (key = "key_adrenaline_2")
            return key_adrenaline_2
        else if (key = "interval_adrenaline_min")
            return interval_adrenaline_min
        else if (key = "interval_adrenaline_max")
            return interval_adrenaline_max
        else if (key = "duration_tincture")
            return duration_tincture
        else if (key = "cooldown_tincture_min")
            return cooldown_tincture_min
        else if (key = "cooldown_tincture_max")
            return cooldown_tincture_max
        else if (key = "interval_manaFlask")
            return interval_manaFlask
        else if (key = "interval_goldFlask_min")
            return interval_goldFlask_min
        else if (key = "interval_goldFlask_max")
            return interval_goldFlask_max
        else if (key = "interval_sulphur_min")
            return interval_sulphur_min
        else if (key = "interval_sulphur_max")
            return interval_sulphur_max
        else if (key = "manaBurnStackRate")
            return manaBurnStackRate
        else
            throw Exception("Unknown config key: " . key)
    }
}

CreateMacroServiceWrapper(container) {
    ; MacroServiceWrapperクラスを作成
    return new MacroServiceWrapper()
}

; ==============================================================================
; MacroServiceWrapperクラス
; ==============================================================================
class MacroServiceWrapper {
    IsRunning() {
        global isRunning
        return isRunning
    }
    
    Start() {
        global isRunning
        isRunning := true
    }
    
    Stop() {
        global isRunning
        isRunning := false
    }
}

CreateFlaskService(container) {
    return new FlaskService(container)
}

; ==============================================================================
; イベントハンドラー
; ==============================================================================

HandleGlobalError(event) {
    global debugMode ; グローバル変数にアクセス
    errorData := event.data
    msg := "Error in event: " . errorData.originalEvent
    msg .= "`nMessage: " . errorData.message
    
    DebugLog("ERROR: " . msg)
    
    if (debugMode) {
        MsgBox, 16, Error, %msg%
    }
}

LogFlaskEvent(event) {
    DebugLog("Flask Event: " . event.name . " at " . event.timestamp)
}