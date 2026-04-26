# Technical Preferences

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Rendering**: Forward Plus (D3D12 on Windows)
- **Physics**: Jolt Physics (default in 4.6)

## Input & Platform

- **Target Platforms**: PC (Windows primary)
- **Input Methods**: Keyboard/Mouse + Gamepad
- **Primary Input**: Keyboard/Mouse
- **Gamepad Support**: Full
- **Touch Support**: None
- **Platform Notes**: Action platformer — precise input latency matters; use `_physics_process` for movement, `_input` for immediate response

## Game Concept

- **Genre**: Wire Action Platformer
- **Core Mechanic**: ワイヤーアクション（ワイヤーを射出・グラップリング・スウィング）
- **Movement**: 慣性ベースの物理移動 + ワイヤーによるスウィング
- **Camera**: 2Dまたは2.5D（要決定）

## Naming Conventions

- **Classes**: `PascalCase` (例: `PlayerController`, `WireHook`)
- **Variables**: `snake_case` (例: `wire_length`, `swing_velocity`)
- **Signals**: `snake_case` 動詞過去形 (例: `wire_attached`, `player_died`)
- **Files**: `snake_case.gd` (例: `player_controller.gd`, `wire_hook.gd`)
- **Scenes**: `snake_case.tscn` (例: `player.tscn`, `level_01.tscn`)
- **Constants**: `SCREAMING_SNAKE_CASE` (例: `MAX_WIRE_LENGTH`, `GRAVITY_SCALE`)

## Performance Budgets

- **Target Framerate**: 60 FPS
- **Frame Budget**: 16.67ms
- **Draw Calls**: < 200 per frame
- **Memory Ceiling**: 512MB

## Testing

- **Framework**: GUT (Godot Unit Testing) — `res://addons/gut/`
- **Minimum Coverage**: Core gameplay systems (wire physics, player movement)
- **Required Tests**: ワイヤー張力計算、スウィング軌道、衝突判定

## Forbidden Patterns

- `_process` でのワイヤー物理計算（必ず `_physics_process` を使用）
- `await` を物理ループ内で使用（デッドロックリスク）
- グローバルシングルトン多用（Autoloadは最小限に）

## Allowed Libraries / Addons

- GUT (Godot Unit Testing Framework)

## Architecture Decisions Log

- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

- **Primary**: `godot-specialist`
- **Language/Code Specialist**: `godot-gdscript-specialist`
- **Shader Specialist**: `godot-shader-specialist`
- **UI Specialist**: `godot-gdscript-specialist`（UI Toolkit使用）
- **Additional Specialists**: `godot-gdextension-specialist`（ネイティブモジュール必要時）
- **Routing Notes**: ワイヤー物理はJolt Physicsの`PhysicsBody2D`/`RigidBody2D`を活用

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| `.gd` (GDScript) | `godot-gdscript-specialist` |
| `.gdshader` / `.shader` | `godot-shader-specialist` |
| `.tscn` (Scene) | `godot-specialist` |
| `.tres` (Resource) | `godot-specialist` |
| UI / Control nodes | `godot-gdscript-specialist` |
| `.gdextension` / C++ | `godot-gdextension-specialist` |
| General architecture review | `godot-specialist` |
