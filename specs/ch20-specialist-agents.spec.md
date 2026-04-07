spec: task
name: "第20章：专家代理系统"
tags: [book, part7, interface, agents]
estimate: 0.5d
---

## Intent

分析 MemPalace 的专家代理架构：每个 agent 一个 wing + 一本 AAAK 日记。
reviewer 记住 bug 模式、architect 记住设计决策、ops 记住事故。
50 个 agent 不膨胀的秘密。与 Letta（$20-200/月）对比。

## Decisions

- 篇幅：3000-4000 字
- 深度：3 层（架构 → 日记格式 → 与竞品对比）
- 引用 README 中的 agent 示例
- 引用 mcp_server.py 的 diary_write/diary_read 工具

## Boundaries

### Allowed
- book/src/ch20-specialist-agents.md

### Forbidden
- 不要详细讲 agent 的 AI 推理逻辑（MemPalace 只提供存储层）

## Out of Scope

- 通用 AI agent 框架（LangChain、CrewAI 等）

## Completion Criteria

Scenario: 架构清晰
  Test: manual_review_architecture
  Given 第 20 章内容
  When 检查 agent 架构
  Then 理解每个 agent 的存储结构（wing + diary）
  And 理解为什么 50 个 agent 不增加配置复杂度

Scenario: 日记格式示例
  Test: manual_review_diary
  Given 第 20 章内容
  When 检查 AAAK 日记
  Then 包含具体的日记写入和读取示例
  And 展示 AAAK 格式如何压缩 agent 的专业知识
