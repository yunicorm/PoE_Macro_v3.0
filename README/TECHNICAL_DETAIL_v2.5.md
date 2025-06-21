# 📐 POE Macro v2.5 技術詳細ドキュメント

## 1. 🔑 重要な実装詳細

### イベントハンドラーの実装パターン
```autohotkey
; ❌ 動作しないパターン（ラベルから関数を直接呼び出し）
LabelName:
    FunctionName(param)  ; エラー: Target label does not exist
return

; ✅ 正しいパターン（ラッパー関数を使用）
LabelName:
    WrapperFunction()
return

WrapperFunction() {
    FunctionName(param)
}
```

### 動的スキル管理のデータフロー
```
GUI (ListView) 
    ↓ [User Input]
Dialog (Add/Edit)
    ↓ [Submit]
CurrentWarcries/CurrentRegularSkills (Array)
    ↓ [Apply]
skillCooldowns/warcryExertCounts (Object)
    ↓ [Save]
JSON File (Profile)
```

### グローバル変数の依存関係
```
isRunning
├── IfWinActiveAndRunning()
├── StartAllTimers()
├── StopAllTimers()
└── オーバーレイ表示制御

skillCooldowns
├── skillQueue_keys
├── StartSkillQueue()
└── SkillQueueLoop()

CurrentWarcries/CurrentRegularSkills
├── dynamic_skill_manager.ahk
├── profile_manager.ahk
└── skills.ahk
```

## 2. 🔧 キーとなる関数・クラス

### 初期化チェーン
```autohotkey
main.ahk起動
├── InitializeOverlay()
├── CheckDefaultProfile()
│   └── CreateDefaultProfile()
└── InitializeSkillDatabase()
    ├── WarcrySkills初期化
    ├── RegularSkills初期化
    └── LoadCurrentSkills()
```

### タイマー管理
```autohotkey
StartAllTimers()
├── ExecuteAdrenalineR()      ; 28.6秒間隔
├── ExecuteTinctureCycle()    ; 複雑なサイクル
├── ExecuteGoldFlask()        ; 28.6秒間隔
├── ExecuteSulphurFlask()     ; 0.3-1秒間隔
├── ExecuteMacroT()           ; 4秒間隔
├── ExecuteDynamicRegularSkills() ; 動的
└── StartSkillQueue()         ; 100ms間隔チェック
```

### プロファイル形式の変遷
```json
// v2.4形式
"skills": {
    "bloodRage": { "key": "e", "intervalMin": 10000 }
}

// v2.5形式
"skills": {
    "dynamicWarcries": [
        { "name": "Intimidating Cry", "key": "L", "cooldown": 5260, "exert": 3 }
    ],
    "dynamicRegular": [
        { "name": "Blood Rage", "key": "E", "intervalMin": 10000, "intervalMax": 10100 }
    ]
}
```

## 3. 🐛 トラブルシューティングガイド

### よくあるエラーと対処法

#### 1. "Target label does not exist"
**原因**: ラベルから関数を直接呼び出している
**解決**: ラッパー関数を作成するか、Gotoを使用

#### 2. "Variable not initialized"
**原因**: グローバル変数の初期化漏れ
**解決**: profile_manager.ahkで初期化を追加

#### 3. ListView更新されない
**原因**: Gui, Settings:Default が抜けている
**解決**: ListView操作前に必ず設定

#### 4. JSONパースエラー
**原因**: 文字エンコーディングの問題
**解決**: UTF-8 BOMなしで保存

### デバッグ手法
```autohotkey
; 1. 簡易デバッグ出力
MsgBox, % "Variable value: " . myVar

; 2. ファイルログ
FileAppend, % A_Now . " - Event: " . eventName . "`n", debug.log

; 3. ListVars コマンド
ListVars  ; すべての変数を表示

; 4. デバッグモード有効化
debugMode := true  ; settings.ahkで設定
```

## 4. 🎯 パフォーマンス最適化のポイント

### 現在のボトルネック
1. **GUI更新**: ListView更新が重い
2. **タイマー競合**: 多数のSetTimerが競合
3. **グローバル変数アクセス**: 頻繁なアクセスでオーバーヘッド

### 最適化の方向性
```autohotkey
; ❌ 非効率な例
Loop, 100 {
    GuiControl,, MyControl, %A_Index%
}

; ✅ 効率的な例
GuiControl, -Redraw, MyListView
Loop, 100 {
    ; 処理
}
GuiControl, +Redraw, MyListView
```

## 5. 🔍 コードレビューチェックリスト

### 新機能追加時
- [ ] グローバル変数は最小限か
- [ ] エラーハンドリングは適切か
- [ ] 既存機能への影響はないか
- [ ] プロファイル保存/読み込みは正常か
- [ ] メモリリークの可能性はないか

### リファクタリング時
- [ ] 後方互換性は保たれているか
- [ ] テストは通るか
- [ ] パフォーマンスは劣化していないか
- [ ] ドキュメントは更新したか

## 6. 🚦 v3.0移行時の技術的課題

### 解決すべき問題
1. **循環参照**: モジュール間の依存関係整理
2. **グローバル状態**: ServiceContainerへの移行
3. **イベント処理**: 同期→非同期への対応
4. **テスト**: モック/スタブの実装

### 移行戦略
```autohotkey
; Step 1: インターフェース定義
class ISkillService {
    AddSkill(skill)
    RemoveSkill(id)
    GetSkill(id)
}

; Step 2: 実装
class SkillService extends ISkillService {
    ; 実装
}

; Step 3: 既存コードをアダプター経由で接続
class LegacyAdapter {
    __New(skillService) {
        this.service := skillService
    }
}
```

## 7. 📚 参考実装パターン

### Observerパターン
```autohotkey
class Observable {
    __New() {
        this.observers := []
    }
    
    Attach(observer) {
        this.observers.Push(observer)
    }
    
    Notify(event) {
        for index, observer in this.observers {
            observer.Update(event)
        }
    }
}
```

### Repositoryパターン
```autohotkey
class Repository {
    Find(id)
    FindAll()
    Save(entity)
    Delete(id)
}
```

### Commandパターン
```autohotkey
class Command {
    Execute()
    Undo()
    CanExecute()
}
```

---

**このドキュメントはv2.5の技術的詳細を記録したものです。v3.0への移行時に参照してください。**