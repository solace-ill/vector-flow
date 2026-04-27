# Systems Index: VectorFlow

> **Status**: Draft
> **Created**: 2026-04-26
> **Last Updated**: 2026-04-26
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

VectorFlow はワイヤーアクションを軸にした 2D アクションプラットフォーマーです。
プレイヤーはワイヤーで縦横無尽に飛び回りながら刀で敵を斬り倒し、エリアを制圧して先へ進みます。
コアシステムは「移動（ワイヤー + プレイヤー）」「戦闘（刀 + 溜め攻撃）」「エリア制エネミークリア」の 3 軸で構成されます。
ステージは複数のエリアに分割され、エリア内の全敵を倒すと次のエリアへのルートが開放されます。タイム計測はおまけ要素として実装されます。

---

## Systems Enumeration

| # | システム名 | カテゴリ | 優先度 | 状態 | 設計書 | 依存先 |
|---|-----------|---------|--------|------|--------|--------|
| 1 | 入力/コントロールマニフェスト | Core | MVP | Designed | design/gdd/input-control-manifest.md | — |
| 2 | レベルシステム | Core | MVP | Not Started | — | — |
| 3 | HP・ダメージシステム | Core | MVP | Not Started | — | — |
| 4 | プレイヤーシステム | Core | MVP | Not Started | — | Input, Level |
| 5 | エネミーシステム | Gameplay | MVP | Not Started | — | HP・ダメージ, Level |
| 6 | ワイヤーシステム | Gameplay | MVP | Not Started | — | Player, Input, Level |
| 7 | 戦闘システム | Gameplay | MVP | Not Started | — | Player, Input, HP・ダメージ |
| 8 | エネミーAIシステム | Gameplay | MVP | Not Started | — | Enemy, Player, Level |
| 9 | カメラシステム | Core | MVP | Not Started | — | Player |
| 10 | デス・リスポーンシステム | Game Flow | MVP | Not Started | — | Player, HP・ダメージ, Level |
| 11 | エリア管理システム | Game Flow | MVP | Not Started | — | Enemy, Player, Level |
| 12 | ゴール・ステージフロー | Game Flow | MVP | Not Started | — | Player, Level, エリア管理 |
| 13 | ワイヤー描画システム | Visual | MVP | Not Started | — | Wire |
| 14 | タイマー・スコアシステム | Game Flow | Vertical Slice | Not Started | — | Stage Flow |
| 15 | HUDシステム | UI | MVP | Not Started | — | Wire, HP・ダメージ, エリア管理 |
| 16 | ステージセレクト・メニュー | UI | Vertical Slice | Not Started | — | Stage Flow, Level |
| 17 | ボスシステム | Gameplay | Post-MVP | Not Started | — | Enemy AI, HP・ダメージ, Stage Flow |
| 18 | ゴーストシステム | Meta | Post-MVP | Not Started | — | Player, Timer, Stage Flow |
| 19 | ステージ進行・解放システム | Meta | Post-MVP | Not Started | — | Stage Flow, エリア管理 |

---

## Categories

| カテゴリ | 説明 |
|---------|------|
| **Core** | 他の全システムが依存する基盤。プレイヤー制御・入力・物理・カメラ |
| **Gameplay** | ゲームを面白くするシステム。ワイヤー・戦闘・敵・AI |
| **Game Flow** | ステージ進行・死亡・タイム計測など、ループを制御するシステム |
| **Visual** | 描画・エフェクト専用システム |
| **UI** | プレイヤー向け情報表示。HUD・メニュー |
| **Meta** | コアループ外のシステム。ゴースト・実績・解放 |

---

## Priority Tiers

| ティア | 定義 | 目標マイルストーン |
|--------|------|-------------------|
| **MVP** | コアループが動作するための最小セット | 最初のプレイアブルビルド |
| **Vertical Slice** | 複数ステージで完成した体験 | デモ / 縦断スライス |
| **Post-MVP** | フルビジョン機能 | ベータ / リリース |

---

## Dependency Map

### Foundation Layer（依存なし）

1. **入力/コントロールマニフェスト** — マウス・キーボード入力の定義。全操作系の起点
2. **レベルシステム** — ステージデータ・フックポイント・地形コリジョン。空間の定義
3. **HP・ダメージシステム** — ダメージ計算・HP管理の純粋な数学層

### Core Layer（Foundation に依存）

4. **プレイヤーシステム** — 依存: Input, Level
5. **エネミーシステム** — 依存: HP・ダメージ, Level

### Feature Layer（Core に依存）

6. **ワイヤーシステム** — 依存: Player, Input, Level
7. **戦闘システム** — 依存: Player, Input, HP・ダメージ
8. **エネミーAIシステム** — 依存: Enemy, Player, Level
9. **カメラシステム** — 依存: Player
10. **デス・リスポーンシステム** — 依存: Player, HP・ダメージ, Level
11. **エリア管理システム** — 依存: Enemy, Player, Level
12. **ゴール・ステージフロー** — 依存: Player, Level, エリア管理

### Presentation Layer（Feature に依存）

13. **ワイヤー描画システム** — 依存: Wire
14. **タイマー・スコアシステム** *(おまけ)* — 依存: Stage Flow
15. **HUDシステム** — 依存: Wire, HP・ダメージ, エリア管理
16. **ステージセレクト・メニュー** — 依存: Stage Flow, Level

### Post-MVP Layer

17. **ボスシステム** — 依存: Enemy AI, HP・ダメージ, Stage Flow
18. **ゴーストシステム** — 依存: Player, Timer, Stage Flow
19. **ステージ進行・解放システム** — 依存: Stage Flow, エリア管理

---

## Recommended Design Order

| 順序 | システム | 優先度 | レイヤー | 担当エージェント | 工数見積 |
|------|---------|--------|---------|----------------|---------|
| 1 | 入力/コントロールマニフェスト | MVP | Foundation | game-designer | S |
| 2 | レベルシステム | MVP | Foundation | game-designer | S |
| 3 | HP・ダメージシステム | MVP | Foundation | systems-designer | S |
| 4 | プレイヤーシステム | MVP | Core | game-designer | M |
| 5 | エネミーシステム | MVP | Core | game-designer | M |
| 6 | ワイヤーシステム | MVP | Feature | game-designer | M |
| 7 | 戦闘システム | MVP | Feature | game-designer | M |
| 8 | エネミーAIシステム | MVP | Feature | ai-programmer | M |
| 9 | カメラシステム | MVP | Feature | game-designer | S |
| 10 | デス・リスポーンシステム | MVP | Feature | game-designer | S |
| 11 | エリア管理システム | MVP | Feature | game-designer | S |
| 12 | ゴール・ステージフロー | MVP | Feature | game-designer | S |
| 13 | ワイヤー描画システム | MVP | Presentation | technical-artist | S |
| 14 | HUDシステム | MVP | Presentation | ux-designer | S |
| 15 | ステージセレクト・メニュー | Vertical Slice | Presentation | ux-designer | M |
| 16 | タイマー・スコアシステム | Vertical Slice | Presentation | game-designer | S |
| 17 | ボスシステム | Post-MVP | Post-MVP | game-designer | L |
| 18 | ゴーストシステム | Post-MVP | Post-MVP | game-designer | M |
| 19 | ステージ進行・解放システム | Post-MVP | Post-MVP | game-designer | M |

> 工数: S = 1セッション / M = 2-3セッション / L = 4セッション以上

---

## Circular Dependencies

循環依存なし ✅

---

## High-Risk Systems

| システム | リスク種別 | 内容 | 対策 |
|---------|-----------|------|------|
| **プレイヤーシステム** | Design | 6システムが依存するボトルネック。設計変更が全体に波及 | 最初期に設計確定・プロトタイプ参照 |
| **戦闘システム** | Technical | 溜め攻撃チャージ判定・ヒットボックス・斬撃飛ばしの同期が複雑 | プロトタイプで早期検証済み（ワイヤー部分） |
| **エネミーAIシステム** | Scope | AIはスコープ膨張しやすい。パターン数が増えると工数急増 | MVP では単純追跡+攻撃パターンのみに限定 |
| **ボスシステム** | Scope | フェーズ管理・演出・固有パターンで工数が膨大になるリスク | Post-MVP に延期済み |

---

## Progress Tracker

| 指標 | 数値 |
|------|------|
| 特定済みシステム総数 | 19 |
| 設計書着手済み | 0 |
| 設計書レビュー済み | 0 |
| 設計書承認済み | 0 |
| MVP システム設計済み | 1 / 14 |
| Vertical Slice 設計済み | 0 / 2 |

---

## Design Decisions Log

- **ゴール条件**: エリア内の全敵を倒すと次エリアへのルートが開放される。敵スルー不可（エリア制）
- **ステージ構造**: ステージを複数エリアに分割。各エリアは敵全滅まで封鎖される
- **タイム計測**: おまけ要素として実装。クリア必須条件ではない
- **入力**: 左クリック = 攻撃（長押しで溜め）、右クリック = ワイヤー射出
- **溜め攻撃**: 0.4s 以上長押しで発動。未満でリリースすると通常攻撃として発動
- **溜め中のワイヤー**: 右クリックで併用可能

---

## Next Steps

- [ ] `/design-system 入力/コントロールマニフェスト` から設計開始（設計順 #1）
- [ ] MVP 14システムの設計書完成後に `/gate-check pre-production` を実行
- [ ] 各GDD完成後に新しいセッションで `/design-review [path]` を実行
