spec: task
name: "第21章：本地模型集成"
tags: [book, part7, interface, local]
estimate: 0.5d
---

## Intent

分析 MemPalace 如何与本地模型（Llama、Mistral 等）集成。
wake-up 输出 ~170 token 上下文。Python API 按需查询。
整个栈离线运行的完整路径。

## Decisions

- 篇幅：3000-4000 字
- 深度：2 层（集成方式 → 离线完整性论证）
- 引用 cli.py 的 wake-up 命令实现
- 引用 searcher.py 的 Python API

## Boundaries

### Allowed
- book/src/ch21-local-models.md

### Forbidden
- 不要成为本地模型安装教程
- 不要推荐特定模型

## Out of Scope

- 各本地模型的性能对比

## Completion Criteria

Scenario: 集成路径完整
  Test: manual_review_integration
  Given 第 21 章内容
  When 检查集成描述
  Then 覆盖 wake-up 命令和 Python API 两种方式
  And 展示完整的离线工作流

Scenario: 不是教程
  Test: manual_review_not_tutorial
  Given 第 21 章内容
  When 检查内容风格
  Then 重点是"为什么这样设计"而非"如何安装配置"
