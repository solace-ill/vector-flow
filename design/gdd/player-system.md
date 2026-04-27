# プレイヤーシステム

*Created: 2026-04-27*
*Status: Draft*

---

## 1. Overview

プレイヤーシステムは `CharacterBody2D` を基盤とし、移動・ジャンプ・壁張り付き・しゃがみの4つの基本アクションを管理します。移動は慣性ベースで、地上・空中・壁張り付きの3つの環境ごとに異なる加速/減速特性を持ちます。内部状態は有限ステートマシン（FSM）で管理し、各ステートが入力の受け付け可否と物理挙動を決定します。ワイヤーシステム・戦闘システムはこの FSM のステートを参照・遷移トリガーとして使用します。6つのシステムが依存するプロジェクト最重要の基盤システムです。

---

## 2. Player Fantasy

<!-- TODO -->

---

## 3. Detailed Rules

<!-- TODO -->

---

## 4. Formulas

<!-- TODO -->

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
