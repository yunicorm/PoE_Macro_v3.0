; ==============================================================================
; EventBus - イベント駆動システム
; Path: src/infrastructure/EventBus.ahk
; ==============================================================================

class EventBus {
    static instance := ""
    
    ; イベントリスナーの保存
    listeners := {}
    
    ; ==============================================================================
    ; シングルトンインスタンスの取得
    ; ==============================================================================
    GetInstance() {
        if (EventBus.instance = "") {
            EventBus.instance := new EventBus()
        }
        return EventBus.instance
    }
    
    ; ==============================================================================
    ; イベントリスナーの登録
    ; ==============================================================================
    On(eventName, callback, priority := 0) {
        if (!this.listeners.HasKey(eventName)) {
            this.listeners[eventName] := []
        }
        
        ; リスナー情報を作成
        listener := {}
        listener.callback := callback
        listener.priority := priority
        listener.id := this.GenerateListenerId()
        
        ; 優先度順に挿入
        listeners := this.listeners[eventName]
        inserted := false
        
        Loop, % listeners.Length() {
            if (listeners[A_Index].priority < priority) {
                listeners.InsertAt(A_Index, listener)
                inserted := true
                break
            }
        }
        
        if (!inserted) {
            listeners.Push(listener)
        }
        
        return listener.id
    }
    
    ; ==============================================================================
    ; イベントリスナーの削除
    ; ==============================================================================
    Off(eventName, listenerId := "") {
        if (!this.listeners.HasKey(eventName)) {
            return false
        }
        
        if (listenerId = "") {
            ; すべてのリスナーを削除
            this.listeners[eventName] := []
            return true
        }
        
        ; 特定のリスナーを削除
        listeners := this.listeners[eventName]
        Loop, % listeners.Length() {
            if (listeners[A_Index].id = listenerId) {
                listeners.RemoveAt(A_Index)
                return true
            }
        }
        
        return false
    }
    
    ; ==============================================================================
    ; イベントの発行
    ; ==============================================================================
    Emit(eventName, data := "") {
        if (!this.listeners.HasKey(eventName)) {
            return 0
        }
        
        ; イベントデータの作成
        event := {}
        event.name := eventName
        event.data := data
        event.timestamp := A_TickCount
        event.cancelled := false
        
        ; リスナーの実行
        listeners := this.listeners[eventName]
        count := 0
        
        for index, listener in listeners {
            if (event.cancelled) {
                break
            }
            
            try {
                if (IsFunc(listener.callback)) {
                    listener.callback.Call(event)
                } else if (IsObject(listener.callback)) {
                    listener.callback.Call(event)
                }
                count++
            } catch e {
                ; エラーイベントを発行（無限ループ防止）
                if (eventName != "error") {
                    this.EmitError(eventName, listener, e)
                }
            }
        }
        
        return count
    }
    
    ; ==============================================================================
    ; 非同期イベントの発行（タイマーを使用）
    ; ==============================================================================
    EmitAsync(eventName, data := "", delay := 0) {
        fn := this.CreateAsyncEmitter(eventName, data)
        SetTimer, %fn%, % -1 * delay
    }
    
    ; ==============================================================================
    ; エラーイベントの発行
    ; ==============================================================================
    EmitError(originalEvent, listener, error) {
        errorData := {}
        errorData.originalEvent := originalEvent
        errorData.listener := listener
        errorData.error := error
        errorData.message := error.Message
        
        this.Emit("error", errorData)
    }
    
    ; ==============================================================================
    ; 一度だけ実行されるリスナーの登録
    ; ==============================================================================
    Once(eventName, callback, priority := 0) {
        ; ラッパー関数を作成
        wrapper := this.CreateOnceWrapper(eventName, callback)
        return this.On(eventName, wrapper, priority)
    }
    
    ; ==============================================================================
    ; イベントリスナーの存在確認
    ; ==============================================================================
    HasListeners(eventName) {
        return this.listeners.HasKey(eventName) && this.listeners[eventName].Length() > 0
    }
    
    ; ==============================================================================
    ; すべてのイベントリスナーをクリア
    ; ==============================================================================
    Clear(eventName := "") {
        if (eventName = "") {
            this.listeners := {}
        } else if (this.listeners.HasKey(eventName)) {
            this.listeners[eventName] := []
        }
    }
    
    ; ==============================================================================
    ; ヘルパー関数
    ; ==============================================================================
    
    GenerateListenerId() {
        static id := 0
        return ++id
    }
    
    CreateOnceWrapper(eventName, callback) {
        bus := this
        wrapper := Func("EventBusOnceWrapper").Bind(bus, eventName, callback)
        return wrapper
    }
    
    CreateAsyncEmitter(eventName, data) {
        bus := this
        return Func("EventBusAsyncEmitter").Bind(bus, eventName, data)
    }
}

; ==============================================================================
; グローバルヘルパー関数
; ==============================================================================

; EventBusのシングルトンインスタンスを取得
GetEventBus() {
    return EventBus.GetInstance()
}

; Onceラッパー関数
EventBusOnceWrapper(bus, eventName, callback, event) {
    ; コールバックを実行
    if (IsFunc(callback)) {
        callback.Call(event)
    } else if (IsObject(callback)) {
        callback.Call(event)
    }
    
    ; 自身を削除（実装簡略化のため、すべてクリアして再登録）
    listeners := bus.listeners[eventName]
    newListeners := []
    
    for index, listener in listeners {
        if (listener.callback != A_ThisFunc) {
            newListeners.Push(listener)
        }
    }
    
    bus.listeners[eventName] := newListeners
}

; 非同期エミッター関数
EventBusAsyncEmitter(bus, eventName, data) {
    bus.Emit(eventName, data)
}