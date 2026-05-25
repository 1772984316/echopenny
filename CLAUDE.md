# EchoPenny - AI女友 + 智能记账App

## 项目概况
Flutter App，用户和 AI 女友聊天，AI 自动识别消费并记账。

## 技术栈
- Flutter 3.44+ / Dart 3.12+
- Riverpod (状态管理)
- Drift (SQLite 本地数据库)
- DeepSeek API (Function Calling)

## Flutter 命令
项目使用完整路径调用 Flutter（未加入当前 shell PATH）：
- `D:/flutter/bin/flutter` 代替 `flutter`
- 运行: `D:/flutter/bin/flutter run -d chrome`
- 测试: `D:/flutter/bin/flutter test`
- 代码生成: `D:/flutter/bin/flutter pub run build_runner build`

## 开发规范
- 代码生成文件 (*.g.dart) 不要手动编辑
- 数据库表改了要重新跑 build_runner
- 先写测试再写实现（TDD）
- 中文注释，英文代码

## 文档
- 设计文档: `docs/specs/2026-05-25-echopenny-design.md`
- 实现计划: `docs/plans/2026-05-25-echopenny-phase1-mvp.md`
