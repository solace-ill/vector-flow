# 入力/コントロールマニフェスト

*Created: 2026-04-27*
*Status: Draft*

---

## 1. Overview

入力/コントロールマニフェストは、VectorFlow における全プレイヤー操作の定義書です。キーボード/マウスをプライマリとし、ゲームパッドをセカンダリとする2系統の入力を管理します。アクションは「コアアクション（移動・ジャンプ・しゃがみ・ワイヤー・攻撃）」「スキルスロット（将来拡張）」「アルティメットスロット（将来拡張）」の3カテゴリに分類します。新アクションはスロットにバインドを追加するだけで既存定義を変更せず拡張できる設計とします。全操作系システムはこのマニフェストを入力の唯一の参照源として扱います。

---

## 2. Player Fantasy

プレイヤーは「考えるより先に体が動く」感覚を目指す。マウスで狙った瞬間にワイヤーが飛び、右クリックを離せばそこへ引き寄せられ、左クリックを握り込むほど刃に力がこもる——入力と結果の間に遅延や曖昧さはない。スキルとアルティメットは既存の操作リズムを壊さず「いつものボタン配置の延長」として手に馴染み、習得後は意識せず使えるようになる。

---

## 3. Detailed Rules

### アクションカテゴリ

| カテゴリ | 説明 | 拡張性 |
|---------|------|--------|
| **Core** | 常時使用するコアアクション | 固定 |
| **Skill** | スキルスロット（現在は空、将来追加） | スロット追加で拡張 |
| **Ultimate** | アルティメットスロット（現在は空、将来追加） | スロット追加で拡張 |

---

### Core アクション定義

| アクション名 | 入力タイプ | KB/M | ゲームパッド | 備考 |
|-------------|-----------|------|------------|------|
| `move_left` | Hold | A | 左スティック左 | |
| `move_right` | Hold | D | 左スティック右 | |
| `jump` | Pressed | Space | A（Cross） | 壁蹴りジャンプも同キー |
| `crouch` | Hold | S | B（Circle） | 押下中だけ有効 |
| `wire_shoot` | Pressed | 右クリック | 右トリガー（RT） | 照準はマウス座標 / 右スティック方向 |
| `attack` | Released | 左クリック | X（Square） | 長押し時間で通常/溜めを判定 |

---

### Skill / Ultimate スロット（将来拡張用）

| スロット | KB/M | ゲームパッド | 現在の割り当て |
|---------|------|------------|-------------|
| `skill_1` | Q | LB（L1） | 未割り当て |
| `skill_2` | E | RB（R1） | 未割り当て |
| `ultimate` | R | LT+RT（L2+R2） | 未割り当て |

---

### 入力タイプ定義

| タイプ | Godot 対応メソッド | 説明 |
|--------|-------------------|------|
| Pressed | `Input.is_action_just_pressed()` | 押した瞬間の1フレームのみ |
| Hold | `Input.is_action_pressed()` | 押し続けている間ずっと |
| Released | `Input.is_action_just_released()` | 離した瞬間の1フレームのみ |

---

### 攻撃入力の判定フロー

```
左クリック押下開始 → charge_timer カウント開始
  ├─ リリース時 charge_timer < 0.4s  → 通常攻撃を発動
  └─ リリース時 charge_timer >= 0.4s → 溜め攻撃を発動
```

溜め中も他アクション（`wire_shoot` 等）は独立して受け付ける。

---

## 4. Formulas

### F-1: 溜め攻撃判定

```
is_charge = (charge_timer >= CHARGE_THRESHOLD)

変数:
  charge_timer     : 左クリック押下からの経過秒数 [s]
  CHARGE_THRESHOLD : 溜め判定の閾値（デフォルト 0.4s）

例:
  charge_timer = 0.39s → is_charge = false → 通常攻撃
  charge_timer = 0.40s → is_charge = true  → 溜め攻撃
```

### F-2: マウス照準ベクトル（KB/M）

```
wire_direction = (mouse_world_pos - player_pos).normalized()

変数:
  mouse_world_pos : get_global_mouse_position() で取得したワールド座標
  player_pos      : プレイヤーのグローバル座標

結果: 長さ1の単位ベクトル。ワイヤーシステムに渡す。
```

### F-3: スティック照準ベクトル（ゲームパッド）

```
stick_raw = Input.get_vector("move_left", "move_right", "move_up", "move_down")
※ 照準専用スティックは右スティック（将来実装）

if stick_raw.length() >= STICK_DEADZONE:
    wire_direction = stick_raw.normalized()
else:
    wire_direction = last_wire_direction  # 前回の方向を維持

変数:
  STICK_DEADZONE       : スティックの無効帯（デフォルト 0.2）
  last_wire_direction  : 直前に確定した照準方向（初期値: Vector2.RIGHT）
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
