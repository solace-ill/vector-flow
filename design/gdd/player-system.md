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

<!-- TODO -->

---

## 6. Dependencies

<!-- TODO -->

---

## 7. Tuning Knobs

<!-- TODO -->

---

## 8. Acceptance Criteria

<!-- TODO -->
