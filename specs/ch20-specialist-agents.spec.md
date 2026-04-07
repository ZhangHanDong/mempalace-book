spec: task
name: "第20章：专家代理系统"
tags: [book, part7, interface, agents]
estimate: 0.5d
---

## Intent

分析 MemPalace 的专家代理方向：当前实现是每个 agent 一个 wing + 一本 diary 的最小存储层，
README 进一步展示了 AAAK 日记和多 agent 扩展的目标路径。reviewer 记住 bug 模式、architect 记住设计决策、ops 记住事故。
重点解释为什么这种结构有扩展潜力，以及当前实现与 README 愿景之间的边界。与 Letta（$20-200/月）对比。

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
  Then 理解当前代码已经实现的存储结构（wing + diary）
  And 理解 README 中的多 agent 扩展方向与当前实现的差异

Scenario: 日记格式示例
  Test: manual_review_diary
  Given 第 20 章内容
  When 检查 AAAK 日记
  Then 包含具体的日记写入和读取示例
  And 展示 AAAK 格式如何压缩 agent 的专业知识
  And 明确 diary_write 当前不会强制校验 AAAK
