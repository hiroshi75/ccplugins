# プロンプト最適化ガイド

LangGraph ノードのプロンプトを効果的に最適化するための包括的なガイド。

## 📚 目次

このガイドは以下のセクションに分割されています：

### 1. [プロンプト最適化の原則](./prompt_principles.md)
プロンプトを設計する際の基本原則を学びます。

### 2. [プロンプト最適化テクニック](./prompt_techniques.md)
実践的な最適化テクニック集（10のテクニック）を提供します。

### 3. [最適化の優先順位](./prompt_priorities.md)
改善のインパクトが大きい順に最適化テクニックを適用する方法を説明します。

## 🎯 クイックスタート

### 初めて最適化する場合

1. **[原則を理解する](./prompt_principles.md)** - 明確性、構造化、具体性の基本を学ぶ
2. **[高インパクトなテクニックから始める](./prompt_priorities.md)** - Few-Shot Examples、出力フォーマット構造化、パラメータ調整
3. **[テクニックの詳細を確認する](./prompt_techniques.md)** - 各テクニックの実装方法と効果

### 既存プロンプトの改善

1. **ベースラインを測定** - 現在のパフォーマンスを記録
2. **[優先順位ガイド](./prompt_priorities.md)を参照** - 最もインパクトの大きい改善を選択
3. **[テクニックを適用](./prompt_techniques.md)** - 1つずつ実装し、効果を測定
4. **反復的に改善** - 測定、実装、検証のサイクルを繰り返す

## 📖 関連ドキュメント

- **[プロンプト最適化の実例](./examples.md)** - Before/After の比較例とコードテンプレート
- **[SKILL.md](./SKILL.md)** - Fine-tune スキル全体の概要と使い方
- **[evaluation.md](./evaluation.md)** - 評価基準の設計と測定方法

## 💡 ベストプラクティス

効果的なプロンプト最適化のために：

1. ✅ **測定駆動**: すべての変更を定量的に評価
2. ✅ **段階的改善**: 1度に1つの変更、測定、検証
3. ✅ **コスト意識**: モデル選択、キャッシング、max_tokens で最適化
4. ✅ **タスク適合**: タスクの複雑度に応じてテクニックを選択
5. ✅ **反復的アプローチ**: 継続的な改善サイクルを維持

## 🔍 問題解決

### プロンプトの品質が低い
→ [プロンプト最適化の原則](./prompt_principles.md) を確認

### 精度が不十分
→ [Few-Shot Examples](./prompt_techniques.md#テクニック-1-few-shot-examples少数例学習) または [Chain-of-Thought](./prompt_techniques.md#テクニック-2-chain-of-thought思考の連鎖) を適用

### レイテンシが高い
→ [Temperature/Max Tokens 調整](./prompt_techniques.md#テクニック-4-temperature-と-max-tokens-の調整) または [出力フォーマット構造化](./prompt_techniques.md#テクニック-3-出力フォーマットの構造化) を実装

### コストが高い
→ [モデル選択最適化](./prompt_techniques.md#テクニック-10-モデルの選択) または [プロンプトキャッシング](./prompt_techniques.md#テクニック-6-プロンプトキャッシングprompt-caching) を導入

---

**💡 Tip**: 改善前後のプロンプト比較例とコードテンプレートは [examples.md](examples.md#phase-3-反復的改善の例) を参照してください。
