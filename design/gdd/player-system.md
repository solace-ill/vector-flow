# プレイヤーシステム

*Created: 2026-04-27*
*Status: Draft*

---

## 1. Overview

プレイヤーシステムは `CharacterBody2D` を基盤とし、移動・ジャンプ・壁張り付き・しゃがみの4つの基本アクションを管理します。移動は慣性ベースで、地上・空中・壁張り付きの3つの環境ごとに異なる加速/減速特性を持ちます。内部状態は有限ステートマシン（FSM）で管理し、各ステートが入力の受け付け可否と物理挙動を決定します。ワイヤーシステム・戦闘システムはこの FSM のステートを参照・遷移トリガーとして使用します。6つのシステムが依存するプロジェクト最重要の基盤システムです。

---

## 2. Player Fantasy

キャラクターには「重さ」がある。走り出しは少し遅く、止まろうとしても滑る——しかしその慣性こそが気持ちよさの源だ。壁に張り付いた瞬間は重力から解放され、壁蹴りで飛び出すと勢いが乗る。ワイヤーで引き寄せられるときも、空中での慣性が完全にはリセットされない。プレイヤーは物理の流れを「抗う」のではなく「乗りこなす」ことで、エネルギーを連鎖させながら敵へ向かっていく。上達するほど動きが滑らかになり、自分がステージに「なじんでいく」感覚が生まれる。

---

## 3. Detailed Rules

### 3-1. 有限ステートマシン（FSM）

| ステート | 説明 |
|---------|------|
| `IDLE` | 地上、速度ゼロ、移動入力なし |
| `RUN` | 地上、水平移動中 |
| `AIRBORNE` | 空中（上昇・下降を区別しない） |
| `WALL_ATTACHED` | 壁に張り付き中 |
| `CROUCH` | 地上、しゃがみ入力保持中 |
| `WIRE_TRAVEL` | ワイヤー引き寄せ移動中（ワイヤーシステムが遷移を要求） |

**遷移ルール**

```
IDLE        → RUN           : 移動入力あり
IDLE        → AIRBORNE      : ジャンプ入力 または 足場消失（落下）
IDLE        → CROUCH        : しゃがみ入力

RUN         → IDLE          : 移動入力なし かつ 速度≒0
RUN         → AIRBORNE      : ジャンプ入力 または 足場消失
RUN         → CROUCH        : しゃがみ入力

AIRBORNE    → IDLE/RUN      : 着地
AIRBORNE    → WALL_ATTACHED : 壁接触 かつ 壁方向へ入力中

WALL_ATTACHED → AIRBORNE   : ジャンプ入力（壁蹴り）または 壁方向への入力解除
WALL_ATTACHED → IDLE/RUN   : 着地

CROUCH      → IDLE          : しゃがみ解除 かつ 移動入力なし
CROUCH      → RUN           : しゃがみ解除 かつ 移動入力あり

任意ステート → WIRE_TRAVEL  : ワイヤーが着弾点に到達（ワイヤーシステムが発火）
WIRE_TRAVEL → AIRBORNE     : 着弾点に到着
```

---

### 3-2. 移動ルール

| 環境 | 加速 | 減速 | 最大速度 |
|------|------|------|---------|
| 地上（RUN） | `RUN_ACCEL` | `RUN_DECEL` | `MAX_RUN_SPEED` |
| 空中（AIRBORNE） | `AIR_ACCEL`（地上より低い） | `AIR_DECEL`（ほぼなし） | `MAX_AIR_SPEED` |
| しゃがみ（CROUCH） | `RUN_ACCEL` | `RUN_DECEL` | `MAX_CROUCH_SPEED`（RUN の 50%） |
| 壁張り付き（WALL_ATTACHED） | 水平移動なし | — | 重力無効、壁沿いに `WALL_SLIDE_SPEED` で下降 |
| ワイヤー移動（WIRE_TRAVEL） | ワイヤーシステムが速度を上書き | — | ワイヤーシステムが定義 |

---

### 3-3. ジャンプルール

- **通常ジャンプ**: `IDLE` / `RUN` / `CROUCH` から `jump` 入力 → 上方向に `JUMP_FORCE` を付与
- **コヨーテタイム**: 足場から離れた後 `COYOTE_FRAMES` フレーム以内なら地上ジャンプ可
- **壁蹴りジャンプ**: `WALL_ATTACHED` から `jump` 入力 → 壁の反対方向 + 上方向に `WALL_KICK_FORCE` を付与
- **二段ジャンプ**: なし（ワイヤーで代替）

---

### 3-4. しゃがみルール

- 当たり判定を縦方向に 40% 縮小（`CollisionShape2D` を切り替え）
- 最大速度を `MAX_CROUCH_SPEED` に制限
- しゃがみ解除時、天井がある場合は解除しない

---

### 3-5. 衝突レイヤー

| レイヤー | 用途 |
|---------|------|
| `layer_1` | 地形（常時有効） |
| `layer_2` | エネミー当たり判定（`WIRE_TRAVEL` 中は無効） |

---

## 4. Formulas

### F-1: 水平移動（加速）

```
velocity.x += direction * ACCEL * delta
velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)

変数:
  direction : -1（左）/ 0（入力なし）/ 1（右）
  ACCEL     : 環境別加速定数（RUN_ACCEL / AIR_ACCEL）
  MAX_SPEED : 環境別上限（MAX_RUN_SPEED / MAX_AIR_SPEED）
```

### F-2: 水平移動（減速）

```
velocity.x = move_toward(velocity.x, 0, DECEL * delta)

変数:
  DECEL : 環境別減速定数（RUN_DECEL / AIR_DECEL）
  ※ move_toward はゼロを超えて反転しないため符号の心配不要
```

### F-3: 重力

```
velocity.y += GRAVITY * delta
velocity.y = min(velocity.y, MAX_FALL_SPEED)

変数:
  GRAVITY       : 重力加速度（下方向が正）
  MAX_FALL_SPEED: 終端速度の上限
  ※ WALL_ATTACHED / WIRE_TRAVEL 中は適用しない
```

### F-4: 通常ジャンプ

```
velocity.y = -JUMP_FORCE

変数:
  JUMP_FORCE : 上方向への初速（正値。負符号で上方向に変換）

例: JUMP_FORCE = 600 → velocity.y = -600
```

### F-5: 壁蹴りジャンプ

```
velocity.x = wall_normal.x * WALL_KICK_H
velocity.y = -WALL_KICK_V

変数:
  wall_normal  : get_wall_normal() で取得した壁の法線ベクトル
  WALL_KICK_H  : 水平方向の蹴り出し速度
  WALL_KICK_V  : 上方向の蹴り出し速度

例: 右壁から蹴る場合 → wall_normal.x = -1 → velocity.x = -WALL_KICK_H（左方向）
```

### F-6: コヨーテタイム

```
# 着地中は毎フレームリセット
if is_on_floor():
    coyote_timer = COYOTE_FRAMES

# 空中では毎フレームデクリメント
else:
    coyote_timer = max(coyote_timer - 1, 0)

# ジャンプ可否判定
can_jump = (coyote_timer > 0)

変数:
  COYOTE_FRAMES : コヨーテタイムのフレーム数（デフォルト 6）
```

---

## 5. Edge Cases

| # | 状況 | 処理 |
|---|------|------|
| E-1 | 壁蹴り直後に同じ壁へ再接触した場合 | `WALL_KICK_COOLDOWN_FRAMES` の間は `WALL_ATTACHED` 遷移を禁止する |
| E-2 | `CROUCH` 中にジャンプ入力した場合 | 通常ジャンプを発動し `AIRBORNE` へ遷移。しゃがみ当たり判定のまま上昇を開始する |
| E-3 | `WIRE_TRAVEL` 中にジャンプ入力した場合 | 入力を無視する。ワイヤー到達後に `AIRBORNE` へ遷移してから操作可能になる |
| E-4 | `WIRE_TRAVEL` 中に地形と衝突した場合 | ワイヤーをキャンセルし `AIRBORNE` へ遷移。壁面衝突時は速度をゼロにする |
| E-5 | ジャンプ中に天井へ衝突した場合 | `velocity.y = 0` にリセット。その後 `AIRBORNE`（下降）として継続 |
| E-6 | `WALL_ATTACHED` 中にしゃがみ入力した場合 | 壁から離れ `AIRBORNE` へ遷移する。しゃがみは地上専用 |
| E-7 | しゃがみ解除しようとしたが天井がある場合 | `CROUCH` を維持する。天井がなくなるまで解除しない |
| E-8 | コヨーテタイムでジャンプした直後に着地した場合 | `coyote_timer` を消費済みとして扱う。二重ジャンプは発生しない |
| E-9 | 落下速度が `MAX_FALL_SPEED` を超えた状態で着地した場合 | 落下ダメージなし。`velocity.y = 0` にして `IDLE`/`RUN` へ遷移 |

---

## 6. Dependencies

### このシステムが依存するもの

| システム | 依存内容 |
|---------|---------|
| 入力/コントロールマニフェスト (#1) | `move_left` / `move_right` / `jump` / `crouch` の入力読み取り、`INPUT_BUFFER_FRAMES` の参照 |
| レベルシステム (#2) | `is_on_floor()` / `is_on_wall()` / `get_wall_normal()` の地形コリジョン |

### このシステムに依存するシステム

| システム | 依存内容 |
|---------|---------|
| ワイヤーシステム (#6) | プレイヤー位置・現在ステート参照。`WIRE_TRAVEL` 遷移の要求 |
| 戦闘システム (#7) | プレイヤーステート参照（攻撃可否の判定） |
| エネミーAIシステム (#8) | プレイヤーのグローバル位置参照 |
| カメラシステム (#9) | プレイヤー位置を追従対象として参照 |
| デス・リスポーンシステム (#10) | プレイヤーHP・死亡ステートを監視 |
| エリア管理システム (#11) | プレイヤー位置でエリア内判定 |
| ゴール・ステージフロー (#12) | プレイヤー位置でゴール到達判定 |
| HUDシステム (#15) | プレイヤーステート・HP を表示用に参照 |

---

## 7. Tuning Knobs

### 移動

| 定数名 | デフォルト | 安全範囲 | 影響するゲームプレイ |
|--------|-----------|---------|-------------------|
| `MAX_RUN_SPEED` | 300 px/s | 200〜500 | 地上の最高速度感 |
| `MAX_AIR_SPEED` | 280 px/s | 200〜500 | 空中の横移動上限 |
| `MAX_CROUCH_SPEED` | 150 px/s | 50〜250 | しゃがみ移動の遅さ |
| `RUN_ACCEL` | 1200 px/s² | 600〜2400 | 走り出しの鋭さ。大きいほどキビキビ |
| `RUN_DECEL` | 1600 px/s² | 800〜3200 | 地上ブレーキの強さ |
| `AIR_ACCEL` | 600 px/s² | 200〜1200 | 空中での方向転換しやすさ |
| `AIR_DECEL` | 100 px/s² | 0〜400 | 空中慣性の残り方。小さいほど滑る |

### 重力・落下

| 定数名 | デフォルト | 安全範囲 | 影響するゲームプレイ |
|--------|-----------|---------|-------------------|
| `GRAVITY` | 1200 px/s² | 600〜2000 | 全体的な重力の強さ。小さいと浮遊感、大きいとシャープ |
| `MAX_FALL_SPEED` | 800 px/s | 400〜1200 | 落下の最高速度。視認性と難易度に影響 |
| `WALL_SLIDE_SPEED` | 60 px/s | 20〜150 | 壁張り付き中の下降速度 |

### ジャンプ

| 定数名 | デフォルト | 安全範囲 | 影響するゲームプレイ |
|--------|-----------|---------|-------------------|
| `JUMP_FORCE` | 600 px/s | 400〜900 | ジャンプの高さ |
| `WALL_KICK_H` | 350 px/s | 200〜600 | 壁蹴りの水平方向の勢い |
| `WALL_KICK_V` | 550 px/s | 350〜800 | 壁蹴りの上昇力 |
| `COYOTE_FRAMES` | 6 f | 0〜12 | 足場を離れた後のジャンプ猶予。大きいほどカジュアル |
| `WALL_KICK_COOLDOWN_FRAMES` | 10 f | 4〜20 | 壁蹴り後に同じ壁へ再接触するまでの禁止フレーム数 |

---

## 8. Acceptance Criteria

| # | テスト内容 | 合格条件 |
|---|-----------|---------|
| AC-1 | 地上で左右移動入力を保持する | `MAX_RUN_SPEED` に達するまで加速し、上限で一定速度になる |
| AC-2 | 地上で移動中に入力を離す | `RUN_DECEL` で減速し、入力なしの状態でゼロに収束する |
| AC-3 | 地上からジャンプする | 到達最高点の高さが `JUMP_FORCE² / (2 × GRAVITY)` の理論値 ±5% 以内 |
| AC-4 | 空中で壁に接触し壁方向を入力する | ステートが `WALL_ATTACHED` になり、重力による加速が止まる |
| AC-5 | `WALL_ATTACHED` 中にジャンプ入力する | 壁の反対方向へ飛び出し、`AIRBORNE` へ遷移する |
| AC-6 | 足場から歩いて落ちた後 6フレーム以内にジャンプ入力する | ジャンプが発動する（コヨーテタイム） |
| AC-7 | 足場から落ちた後 7フレーム目にジャンプ入力する | ジャンプが発動しない |
| AC-8 | `CROUCH` 中の当たり判定高さを計測する | 通常時の 60% の高さになっている |
| AC-9 | `CROUCH` 中に頭上に天井がある状態で解除入力する | `CROUCH` が維持される |
| AC-10 | 壁蹴りした直後 10フレーム以内に同じ壁へ触れる | `WALL_ATTACHED` に遷移しない |
| AC-11 | `WIRE_TRAVEL` 中にエネミーと重なる | エネミーの当たり判定を無視して通過する |
| AC-12 | `WIRE_TRAVEL` 中に地形と衝突する | ワイヤーがキャンセルされ `AIRBORNE` へ遷移。速度がゼロになる |
