; ==============================================================================
; ServiceContainer - 依存性注入コンテナ
; Path: src/infrastructure/ServiceContainer.ahk
; ==============================================================================

class ServiceContainer {
    static instance := ""
    
    ; サービス登録用の内部ストレージ
    services := {}
    factories := {}
    singletons := {}
    
    ; ==============================================================================
    ; シングルトンインスタンスの取得
    ; ==============================================================================
    GetInstance() {
        if (ServiceContainer.instance = "") {
            ServiceContainer.instance := new ServiceContainer()
        }
        return ServiceContainer.instance
    }
    
    ; ==============================================================================
    ; サービスの登録
    ; ==============================================================================
    Register(name, service, options := "") {
        if (options = "singleton") {
            this.RegisterSingleton(name, service)
        } else if (IsFunc(service) || IsObject(service)) {
            this.RegisterFactory(name, service)
        } else {
            this.services[name] := service
        }
        return this
    }
    
    ; ==============================================================================
    ; シングルトンサービスの登録
    ; ==============================================================================
    RegisterSingleton(name, factoryOrInstance) {
        if (IsFunc(factoryOrInstance) || (IsObject(factoryOrInstance) && factoryOrInstance.HasKey("Call"))) {
            ; ファクトリー関数の場合
            this.factories[name] := factoryOrInstance
            this.singletons[name] := ""  ; 遅延初期化マーカー
        } else {
            ; インスタンスの場合
            this.singletons[name] := factoryOrInstance
        }
        return this
    }
    
    ; ==============================================================================
    ; ファクトリー関数の登録
    ; ==============================================================================
    RegisterFactory(name, factory) {
        this.factories[name] := factory
        return this
    }
    
    ; ==============================================================================
    ; サービスの取得
    ; ==============================================================================
    Get(name) {
        ; シングルトンチェック
        if (this.singletons.HasKey(name)) {
            if (this.singletons[name] = "") {
                ; 遅延初期化
                factory := this.factories[name]
                this.singletons[name] := this.CreateInstance(factory)
            }
            return this.singletons[name]
        }
        
        ; ファクトリーチェック
        if (this.factories.HasKey(name)) {
            factory := this.factories[name]
            return this.CreateInstance(factory)
        }
        
        ; 通常サービスチェック
        if (this.services.HasKey(name)) {
            return this.services[name]
        }
        
        throw Exception("Service not found: " . name)
    }
    
    ; ==============================================================================
    ; サービスの存在確認
    ; ==============================================================================
    Has(name) {
        return this.services.HasKey(name) 
            || this.factories.HasKey(name) 
            || this.singletons.HasKey(name)
    }
    
    ; ==============================================================================
    ; インスタンスの作成
    ; ==============================================================================
    CreateInstance(factory) {
        if (IsFunc(factory)) {
            ; 関数の場合
            return factory.Call(this)
        } else if (IsObject(factory) && factory.HasKey("Call")) {
            ; Functorオブジェクトの場合
            return factory.Call(this)
        } else if (IsObject(factory) && factory.HasKey("__Class")) {
            ; クラスの場合
            return new factory(this)
        }
        return factory
    }
    
    ; ==============================================================================
    ; すべてのサービスをクリア
    ; ==============================================================================
    Clear() {
        this.services := {}
        this.factories := {}
        this.singletons := {}
        return this
    }
    
    ; ==============================================================================
    ; デバッグ用：登録されているサービスのリスト
    ; ==============================================================================
    ListServices() {
        services := []
        
        for name, _ in this.services {
            services.Push({name: name, type: "Service"})
        }
        
        for name, _ in this.factories {
            services.Push({name: name, type: "Factory"})
        }
        
        for name, _ in this.singletons {
            services.Push({name: name, type: "Singleton"})
        }
        
        return services
    }
}

; ==============================================================================
; グローバルヘルパー関数
; ==============================================================================

; サービスコンテナのシングルトンインスタンスを取得
GetServiceContainer() {
    return ServiceContainer.GetInstance()
}

; サービスを簡単に取得するためのヘルパー
GetService(name) {
    return GetServiceContainer().Get(name)
}