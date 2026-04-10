spec: task
name: "第29章：多 Agent 协作"
tags: [book, part10, mempal, agents, coordination]
depends: [ch28-self-describing-protocol]
estimate: 1d
---

## Intent

展示 mempal 作为多 AI agent 之间异步协调层的实践。这不是设想，而是 mempal 开发过程中
实际发生的 Claude↔Codex 接力模式。记忆系统不仅帮人记住决策，还帮不同 agent session 
之间传递上下文、发现反模式、做跨 session 代码审查。

这是全书最"meta"的一章：用 mempal 记录 mempal 的开发，然后在书里分析这个过程。

## Decisions

- 篇幅：4000-5000 字
- 必须引用至少 3 个具体的 mempal drawer（drawer_id）作为 agent 协作的证据
- 必须引用的关键 drawer：
  - Codex 状态快照（drawer_mempal_default_a295458d）
  - Claude CI commit 决策（drawer_mempal_default_b103b147）
  - Codex skip-repo-docs 反模式观察（drawer_mempal_default_cb58c7f3）
- 对比 git log 和 mempal drawer 的信息密度：diff 告诉你"改了什么"，drawer 告诉你"为什么改"
- 语气：叙事性最强的一章，可以讲故事，但每个故事都必须有 drawer 引用

## Boundaries

### Allowed
- book-en/src/ch29-multi-agent-coordination.md

### Forbidden
- 不要变成 Claude Code / Codex 的使用教程
- 不要泛化为"AI agent 协作的未来"——聚焦于已经发生的事实
- 不要美化失败——数据丢失事件、wing 猜错事件都要如实记录

## Out of Scope

- AI agent 框架的通用设计（LangGraph、CrewAI 等）
- mempal 的 REST API 或其他接口
- 未来的多用户/多 agent 架构设想

## Completion Criteria

Scenario: Claude↔Codex 接力有完整时间线
  Test: manual_review_relay_timeline
  Given 第 29 章内容
  When 检查 agent 接力的叙述
  Then 给出了至少一个完整的接力周期（Codex 写 → Claude 读 → Claude 做 → Claude 写）
  And 每个步骤都引用了具体的 drawer_id 或 commit hash

Scenario: 反模式发现不是炫耀
  Test: manual_review_antipattern_honest
  Given 第 29 章内容
  When 检查 skip-repo-docs 反模式的叙述
  Then 客观描述了 Codex 发现 Claude 的问题
  And 同时也提到了 Codex 自己的失败（如 wing 猜错）
  And 结论是"互相发现问题"而非"一方优于另一方"

Scenario: 决策记忆 vs git diff 有具体对比
  Test: manual_review_memory_vs_diff
  Given 第 29 章内容
  When 检查记忆与 git 的对比
  Then 用同一个 commit 展示了 git log 和 mempal drawer 的信息差异
  And 说明两者互补而非替代

Scenario: Dogfooding 评估诚实
  Test: manual_review_dogfood_honest
  Given 第 29 章内容
  When 检查 dogfooding 评估
  Then 列出了至少 2 个有效的方面和 2 个需要改进的方面
  And 需要改进的方面引用了具体的失败案例（如非英文搜索退化）
