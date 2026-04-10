spec: task
name: "第28章：自描述协议"
tags: [book, part10, mempal, protocol, mcp]
depends: [ch27-what-stayed-what-changed]
estimate: 1d
---

## Intent

论述 mempal 最重要的设计创新：不在存储或搜索，而在"让工具教会 AI 怎么用自己"。
MEMORY_PROTOCOL 嵌入在代码中，通过 MCP ServerInfo.instructions 自动注入，
任何 agent 连接后立刻知道行为规范。每条规则都来自一个真实的失败案例。

与 Chapter 19（MemPalace 的 19 个 MCP 工具）形成对照：mempal 用 5 个工具 + 
自描述协议替代了 19 个工具 + 外部文档。

## Decisions

- 篇幅：4000-5000 字
- 必须引用 mempal 源码 `crates/mempal-core/src/protocol.rs` 中的 MEMORY_PROTOCOL 全文
- 必须引用 `crates/mempal-mcp/src/server.rs` 中的 `with_instructions()` 调用
- 必须引用 `crates/mempal-mcp/src/tools.rs` 中 SearchRequest 的 doc comment
- 每条协议规则必须对应一个真实失败案例（来自 mempal drawer 中的决策记录）
- 与 Chapter 19 的 19 工具对比：从数量、认知负担、agent 决策空间三个维度

## Boundaries

### Allowed
- book-en/src/ch28-self-describing-protocol.md

### Forbidden
- 不要变成 MCP 协议教程
- 不要列举所有 MCP 工具的参数细节（这是文档不是书）
- 不要暗示"5 个工具总是比 19 个好"——要说明上下文依赖

## Out of Scope

- MCP 协议本身的设计（Model Context Protocol spec）
- mempal REST API 的设计
- 其他 MCP 服务器的实现对比

## Completion Criteria

Scenario: 协议文本来自源码
  Test: manual_review_protocol_source
  Given 第 28 章内容
  When 检查 MEMORY_PROTOCOL 的引用
  Then 协议规则直接引用自 protocol.rs
  And 不是作者自己编写的"类似"版本

Scenario: 每条规则有失败案例
  Test: manual_review_rules_grounded
  Given 第 28 章内容
  When 检查 6 条协议规则
  Then 至少 4 条规则附带了导致该规则产生的真实失败案例
  And 失败案例来自 mempal 的开发历史（可引用 drawer_id 或 commit hash）

Scenario: 工具数量对比有认知分析
  Test: manual_review_tool_comparison
  Given 第 28 章内容
  When 检查 19 工具 vs 5 工具的对比
  Then 从 agent 决策空间的角度分析了工具数量的影响
  And 承认 MemPalace 19 工具覆盖了 mempal 尚未实现的功能（如 KG 工具）

Scenario: SearchRequest doc comment 作为设计模式
  Test: manual_review_field_docs
  Given 第 28 章内容
  When 检查 SearchRequest 字段文档的讨论
  Then 解释了 doc comment → JSON Schema → MCP tool description 的传播链
  And 引用了 Codex wing 猜错事件作为动机
