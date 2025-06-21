# 📋 POE Macro セッション引き継ぎパッケージ
**作成日**: 2025年1月20日  
**現在バージョン**: v2.5（動的スキル管理実装完了）  
**次期バージョン**: v3.0（アーキテクチャ刷新）

---

## 1. 🎮 プロジェクト概要

### 基本情報
- **プロジェクト名**: Path of Exile Universal Macro
- **開発言語**: AutoHotkey v1.1.33+
- **対象ゲーム**: Path of Exile
- **現在のビルド**: Champion Volcanic Fissure（将来的に汎用化予定）
- **開発環境**: Windows 10/11

### プロジェクトの目的
Path of Exileのゲームプレイを自動化・効率化するマクロシステム。フラスコ管理、スキルローテーション、Warcryチェーンなどを自動実行。

---

## 2. 📊 v2.5 現在の実装状況

### ✅ 実装完了機能

#### 1. **動的スキル管理（v2.5の主要機能）**
- Warcryスキル：最大6個まで動的に追加/削除/編集可能
- Regular Skills：最大5個まで動的に追加/削除/編集可能
- ListView UIによる直感的な管理
- リアルタイムでの設定変更と適用

#### 2. **フラスコ自動化**
- Life Flask（Adrenalineコンボに連動）
- Sulphur Flask（ランダム間隔）
- Tincture（Mana Burn管理付き）
- Gold Flask（Wine of the Prophet）
- Mana Flask（Tincture効果中のみ）

#### 3. **スキルキューシステム**
- 4つのWarcryを自動ローテーション
- 右クリック/移動中の実行防止
- Exertカウンター機能

#### 4. **オーバーレイ表示**
- スキル/フラスコのクールダウン表示
- マクロON/OFF状態表示
- Exert残り回数表示

#### 5. **プロファイル管理**
- JSON形式での保存/読み込み
- 複数プロファイル対応
- v2.4との後方互換性

### 📁 現在のファイル構造
```
POE_Macro/
├── main.ahk                    # エントリーポイント（400行）
├── config/
│   └── settings.ahk           # 設定定数（200行）
├── modules/
│   ├── core.ahk              # コア機能
│   ├── flasks.ahk            # フラスコ管理
│   ├── skills.ahk            # スキル実行（300行）
│   ├── gui.ahk               # 通知UI
│   ├── overlay.ahk           # オーバーレイメイン
│   ├── overlay_base.ahk      # オーバーレイ基本
│   ├── overlay_gui.ahk       # オーバーレイGUI
│   ├── overlay_update.ahk    # オーバーレイ更新
│   └── debug_helper.ahk      # デバッグ支援
├── gui/
│   ├── settings_gui.ahk      # 設定画面（500行）
│   ├── profile_manager.ahk   # プロファイル管理（300行）
│   └── dynamic_skill_manager.ahk # スキル管理（400行）
├── lib/
│   └── JSON.ahk              # JSONライブラリ
├── profiles/
│   └── default.json          # デフォルトプロファイル（v2.5形式）
├── test/
│   ├── test_macro.ahk        # 基本テスト
│   └── test_dynamic_skills.ahk # スキル管理テスト
└── icons/                     # アイコンファイル（オプション）
```

### 🔧 主要な技術仕様

#### グローバル変数（主要なもの）
```autohotkey
; 実行状態
global isRunning := false

; スキル管理
global CurrentWarcries := []      ; 動的Warcryリスト
global CurrentRegularSkills := [] ; 動的通常スキルリスト
global skillCooldowns := {}       ; スキルクールダウン
global warcryExertCounts := {}    ; Exertカウント設定
global currentExertCounts := {}   ; 現在のExertカウント

; タイマー関連
global lastAdrenalineTime := 0
global lastGoldFlaskTime := 0
global tinctureActive := false
global isCasting := false
```

#### イベントハンドラー構造
- ラベル形式のイベントハンドラー（AutoHotkey v1制約）
- main.ahkにグローバルラベルを集約
- ラッパー関数経由での関数呼び出し

---

## 3. 🚀 v3.0 移行計画

### アーキテクチャの刷新目標
1. **モジュール化**: 各ファイル200行以内
2. **レイヤー分離**: Presentation/Application/Domain/Infrastructure
3. **依存性注入**: ServiceContainerパターン
4. **イベント駆動**: EventBusによる疎結合
5. **ハイブリッド開発**: AutoHotkey + Python/Node.js

### 新ファイル構造（提案）
```
POE_Macro/
├── src/
│   ├── main.ahk              # 50行以内のエントリーポイント
│   ├── bootstrap.ahk         # 初期化処理
│   ├── core/                 # ドメイン層
│   ├── application/          # ビジネスロジック
│   ├── presentation/         # UI層
│   ├── infrastructure/       # 外部連携
│   └── utils/               # ユーティリティ
├── scripts/                  # Python/Node.js補助
├── tests/                    # テストコード
├── config/                   # 設定ファイル
├── profiles/                 # ユーザープロファイル
└── docs/                     # ドキュメント
```

### 移行スケジュール（6週間）
- **Week 1**: 基盤構築（ServiceContainer, EventBus）
- **Week 2**: コア機能の移行
- **Week 3**: GUI層の再構築（MVP パターン）
- **Week 4**: 高度な機能（Python連携、Web UI）
- **Week 5**: テストとリファクタリング
- **Week 6**: 最終調整とデプロイ

---

## 4. 🔄 引き継ぎ時の作業手順

### 次のセッションで必要なファイル
1. **必須ファイル**（最新版を使用）
   - `main.ahk`（修正版）
   - `gui/dynamic_skill_manager.ahk`（修正版）
   - `profiles/default.json`（v2.5形式）
   - `lib/JSON.ahk`

2. **参照ファイル**
   - `config/settings.ahk`
   - `modules/skills.ahk`
   - `gui/settings_gui.ahk`
   - `gui/profile_manager.ahk`

### セッション開始時の確認事項
```markdown
1. [ ] v2.5が正常に動作することを確認
2. [ ] エラーメッセージが出ていないか確認
3. [ ] 設定画面でスキルの追加/削除ができるか確認
4. [ ] プロファイルの保存/読み込みが動作するか確認
```

---

## 5. 🐛 既知の問題と注意点

### 技術的制約
1. **AutoHotkey v1の制限**
   - 真のOOP非対応（プロトタイプベース）
   - 非同期処理の制限
   - 名前空間の欠如

2. **グローバル変数の多用**
   - 約50個のグローバル変数
   - 相互依存性が高い
   - テストが困難

3. **ファイルサイズ**
   - settings_gui.ahk: 500行超
   - dynamic_skill_manager.ahk: 400行超
   - 可読性と保守性の低下

### 移行時の注意点
1. **後方互換性**
   - v2.4プロファイルの読み込み対応
   - 既存ユーザーへの影響最小化

2. **段階的移行**
   - 一度にすべてを変更しない
   - 機能単位で移行
   - 常に動作する状態を維持

---

## 6. 📝 推奨される次のアクション

### 優先度高
1. **ServiceContainerの実装**
   ```autohotkey
   ; src/infrastructure/ServiceContainer.ahk
   class ServiceContainer {
       Register(name, service)
       Get(name)
       Has(name)
   }
   ```

2. **EventBusの実装**
   ```autohotkey
   ; src/infrastructure/EventBus.ahk
   class EventBus {
       On(event, callback)
       Emit(event, data)
   }
   ```

3. **最初のサービス移行**
   - FlaskServiceから開始（独立性が高い）
   - 既存のflasks.ahkをサービスクラスに変換

### 優先度中
1. **ロギングシステムの実装**
2. **最初のPresenterクラスの作成**
3. **ユニットテストの導入**

### 優先度低
1. **Python連携の検証**
2. **Web UIのプロトタイプ**
3. **ビルドシステムの構築**

---

## 7. 🔗 関連リソース

### ドキュメント
- `POE_MACRO_SPEC_v2.4.md` - 仕様書
- `POE_MACRO_DEVELOPMENT_PLAN_v2.4.md` - 開発計画
- `DYNAMIC_SKILLS_IMPLEMENTATION.md` - v2.5実装ガイド
- `IMPLEMENTATION_SUMMARY_v2.5.md` - v2.5実装まとめ

### 外部リソース
- [AutoHotkey Documentation](https://www.autohotkey.com/docs/)
- [JSON.ahk Library](https://github.com/cocobelgica/AutoHotkey-JSON)
- [Path of Exile Wiki](https://www.poewiki.net/)

### 開発ツール
- VSCode + AutoHotkey拡張
- Git for Windows
- Python 3.9+ (将来の連携用)
- Node.js 16+ (Web UI用)

---

## 8. 💬 申し送り事項

### 成功したこと
- v2.5の動的スキル管理が完全に動作
- ListViewによるUIが直感的
- エラーハンドリングが改善

### 課題
- コードの複雑性が増大
- テストの自動化が未実装
- ドキュメントの更新が必要

### 次のマイルストーン
**v3.0 アーキテクチャ刷新**
- 目標: 保守性とテスト可能性の大幅改善
- 期限: 6週間
- 成功指標: 各ファイル200行以内、テストカバレッジ80%

---

**このドキュメントは次のセッションの開始時に参照してください。**

最終更新: 2025年1月20日
作成者: Development Assistant
バージョン: 1.0