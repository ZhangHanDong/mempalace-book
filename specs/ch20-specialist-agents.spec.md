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

## 版本演化附注（v3.3.0）

章末已追加"版本演化说明"小节，覆盖三个新模块，并对章内预期与实际实现的差异做了诚实标注：

- **fact_checker.py**（335 行）：纯离线事实校验器，返回 `issues` 列表，**未接入任何 ingest 路径**——目前仅能通过 CLI 或直接 import 手动调用。本章原预期的"入库前质量门"在 v3.3.0 尚未实现为自动管道。
- **closet_llm.py**（351 行，PR `#793`）：可选 LLM closet 重生成，bring-your-own endpoint，默认不调用。不破坏章内"no mandatory API key"论点。
- **diary_ingest.py**（209 行）：room 硬编码 `"daily"`（`diary_ingest.py:141,171`），不是"按天建 room"。MCP `diary_write` 工具（`mcp_server.py:902-903`）另走一条路径，room 硬编码 `"diary"`——两条路径 room 名尚未统一。

本章"代理 = wing + diary、成本函数斜率为零"的核心论点不变。
