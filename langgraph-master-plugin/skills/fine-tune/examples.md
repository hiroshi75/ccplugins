# ファインチューニング実践例集

LangGraph アプリケーションのファインチューニングで使用する具体的なコード例とマークダウンテンプレート集。

## 📋 目次

このガイドは Phase 別に分割されています：

### [Phase 1: 準備と分析の例](./examples_phase1.md)
最適化の準備段階で使用するテンプレートとコード例：
- **Example 1.1**: fine-tune.md の構造例
- **Example 1.2**: 最適化箇所リストの例
- **Example 1.3**: Serena MCP でのコード検索例

**所要時間**: 30分-1時間

### [Phase 2: ベースライン評価の例](./examples_phase2.md)
現状のパフォーマンス測定で使用するスクリプトとレポート例：
- **Example 2.1**: 評価スクリプト（evaluator.py）
- **Example 2.2**: ベースライン測定スクリプト（baseline_evaluation.sh）
- **Example 2.3**: ベースライン結果レポート

**所要時間**: 1-2時間

### [Phase 3: 反復的改善の例](./examples_phase3.md)
プロンプト最適化と結果比較の実例：
- **Example 3.1**: 改善前後のプロンプト比較（Before/After）
- **Example 3.2**: 優先順位付けマトリックス
- **Example 3.3**: Iteration 結果レポート

**所要時間**: 各 iteration 1-2時間 × iterations 数

### [Phase 4: 完了と文書化の例](./examples_phase4.md)
最終成果の記録とバージョン管理の例：
- **Example 4.1**: 最終評価レポート（完全版）
- **Example 4.2**: Git コミットメッセージ例

**所要時間**: 30分-1時間

## 🎯 使い方

### 初めて実践する場合

1. **[Phase 1 の例](./examples_phase1.md)から開始** - テンプレートをコピーして使用
2. **[Phase 2 の評価スクリプト](./examples_phase2.md)をセットアップ** - 環境に合わせてカスタマイズ
3. **[Phase 3 の比較例](./examples_phase3.md)を参考にイテレーション** - Before/After を記録
4. **[Phase 4 のレポート](./examples_phase4.md)で文書化** - 最終成果をまとめる

### コピー&ペーストで使える

各例は完全なコードとテンプレートを含んでいます：
- Python スクリプト → そのまま実行可能
- Bash スクリプト → 環境変数を設定して実行
- Markdown テンプレート → 内容を埋めて使用
- JSON 構造 → テストケースやレポートの雛形

## 📊 例の種類

### コードスクリプト
- **評価スクリプト** (Phase 2): evaluator.py, aggregate_results.py
- **測定スクリプト** (Phase 2): baseline_evaluation.sh
- **分析スクリプト** (Phase 1): Serena MCP 検索例

### Markdown テンプレート
- **fine-tune.md** (Phase 1): 目標設定
- **最適化箇所リスト** (Phase 1): 改善対象の整理
- **ベースライン結果レポート** (Phase 2): 現状分析
- **Iteration 結果レポート** (Phase 3): 改善効果測定
- **最終評価レポート** (Phase 4): 総まとめ

### 比較例
- **Before/After プロンプト** (Phase 3): 改善の具体例
- **優先順位マトリックス** (Phase 3): 意思決定の記録

## 🔍 例を探す

### 目的別

| 目的 | Phase | Example |
|-----|------|---------|
| 目標を設定したい | Phase 1 | [Example 1.1](./examples_phase1.md#example-11-fine-tunemd-の構造例) |
| 最適化対象を見つけたい | Phase 1 | [Example 1.3](./examples_phase1.md#example-13-serena-mcp-でのコード検索例) |
| 評価スクリプトを作りたい | Phase 2 | [Example 2.1](./examples_phase2.md#example-21-評価スクリプト) |
| ベースラインを測定したい | Phase 2 | [Example 2.2](./examples_phase2.md#example-22-ベースライン測定スクリプト) |
| プロンプトを改善したい | Phase 3 | [Example 3.1](./examples_phase3.md#example-31-改善前後のプロンプト比較) |
| 優先順位を決めたい | Phase 3 | [Example 3.2](./examples_phase3.md#example-32-優先順位付けマトリックス) |
| 最終レポートを書きたい | Phase 4 | [Example 4.1](./examples_phase4.md#example-41-最終評価レポート) |
| Git コミットしたい | Phase 4 | [Example 4.2](./examples_phase4.md#example-42-git-コミットメッセージ例) |

## 🔗 関連ドキュメント

- **[ワークフロー](./workflow.md)** - 各 Phase の詳細な手順
- **[評価方法](./evaluation.md)** - 評価指標と統計分析
- **[プロンプト最適化](./prompt_optimization.md)** - 最適化テクニックの詳細
- **[SKILL.md](./SKILL.md)** - Fine-tune スキル全体の概要

## 💡 Tips

### カスタマイズポイント

1. **テストケース数**: 例では 20 ケースだが、プロジェクトに応じて調整
2. **実行回数**: ベースライン測定は 3-5 回が推奨だが、時間制約に応じて調整
3. **目標値**: Accuracy, Latency, Cost の目標はプロジェクト要件に合わせて設定
4. **モデル**: Claude 3.5 Sonnet 以外のモデルを使う場合は料金を調整

### よくある質問

**Q: 例のコードをそのまま使える？**
A: はい、環境変数（API キーなど）を設定すれば実行可能です。

**Q: テンプレートを編集していい？**
A: はい、プロジェクトに合わせて自由にカスタマイズしてください。

**Q: Phase を飛ばしてもいい？**
A: 初回は全 Phase を実施することを推奨します。2回目以降は Phase 2 から開始可能です。

---

**💡 Tip**: 各 Phase の詳細な手順は [ワークフロー](./workflow.md) を参照してください。
