# 🚀 POE Macro 次回セッション クイックスタートガイド

## 1. 📋 セッション開始チェックリスト

```markdown
### 環境確認
- [ ] AutoHotkey v1.1.33+ がインストール済み
- [ ] VSCode または任意のエディタが準備済み
- [ ] Path of Exile がインストール済み（テスト用）

### ファイル確認
- [ ] POE_Macroフォルダが存在
- [ ] lib/JSON.ahk が配置済み
- [ ] profiles/default.json が存在（v2.5形式）

### 動作確認
- [ ] main.ahkを実行してエラーが出ない
- [ ] Ctrl+Shift+Sで設定画面が開く
- [ ] Skill Settingsタブでスキル管理ができる
```

## 2. 🎯 現在の状態サマリー

### 完了済み
- ✅ v2.5 動的スキル管理機能
- ✅ ListView UIの実装
- ✅ エラー修正（ラベル→関数呼び出し問題）
- ✅ プロファイルのv2.5形式対応

### 次の作業
- 🔄 v3.0 アーキテクチャ移行の開始
- 📁 新しいフォルダ構造の作成
- 🏗️ ServiceContainerの実装

## 3. 💻 即座に実行できるコマンド

### 現バージョンのテスト
```powershell
# PowerShellで実行
cd "C:\path\to\POE_Macro"
.\main.ahk
```

### 新構造の作成
```powershell
# 新しいフォルダ構造を作成
@"
src
src/core/models
src/core/constants
src/application/services
src/presentation/gui
src/infrastructure
src/utils
scripts
tests/unit
docs/architecture
"@ -split "`n" | ForEach-Object { 
    New-Item -ItemType Directory -Path $_.Trim() -Force 
}
```

### 最初のファイル作成
```powershell
# ServiceContainer.ahkの作成
New-Item -Path "src/infrastructure/ServiceContainer.ahk" -ItemType File
```

## 4. 🔨 v3.0 移行の最初のステップ

### Step 1: ServiceContainerの実装（1-2時間）
```autohotkey
; src/infrastructure/ServiceContainer.ahk
class ServiceContainer {
    __New() {
        this.services := {}
    }
    
    Register(name, service) {
        this.services[name] := service
    }
    
    Get(name) {
        return this.services[name]
    }
}
```

### Step 2: 最初のモデルクラス（30分）
```autohotkey
; src/core/models/Skill.ahk
class Skill {
    __New(name, key, cooldown) {
        this.name := name
        this.key := key
        this.cooldown := cooldown
    }
}
```

### Step 3: 最初のサービス移行（2-3時間）
既存の `modules/flasks.ahk` を `src/application/services/FlaskService.ahk` に移行

## 5. 📝 重要な注意事項

### やってはいけないこと
- ❌ すべてを一度に変更しない
- ❌ 既存の動作を壊さない
- ❌ テストなしでリファクタリングしない

### 必ずやること
- ✅ 小さな変更を積み重ねる
- ✅ 常に動作確認を行う
- ✅ コミットを細かく行う

## 6. 🔗 必要なリンク集

### ドキュメント
- [SESSION_HANDOVER_PACKAGE_v2.5_to_v3.0.md](#) - メイン引き継ぎ文書
- [TECHNICAL_DETAILS_v2.5.md](#) - 技術詳細
- [新しいファイル構造提案](#) - アーキテクチャ設計

### 外部リソース
- [AutoHotkey v1 Documentation](https://www.autohotkey.com/docs/v1/)
- [AutoHotkey Community Forum](https://www.autohotkey.com/boards/)

## 7. 🎬 セッション開始時の最初の質問例

```
「POE Macroのv3.0移行を開始したいと思います。
現在v2.5が完成し、ServiceContainerから実装を始める予定です。
SESSION_HANDOVER_PACKAGE_v2.5_to_v3.0.mdを確認しました。
最初のステップをサポートしてください。」
```

---

**このガイドで次回のセッションをスムーズに開始できます！**

作成日: 2025年1月20日  
Good luck with v3.0! 🚀