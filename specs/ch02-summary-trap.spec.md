spec: task
name: "第2章：摘要陷阱"
tags: [book, part1, problem-space]
estimate: 0.5d
depends: [ch01-conversation-as-decision]
---

## Intent

分析 Mem0、Zep、Letta 等现有 AI 记忆系统的核心假设——让 LLM 决定什么值得记住。
论证这是根本性错误：LLM 提取 "user prefers Postgres" 时，丢掉了解释 *为什么* 的对话。
一旦提取错误，记忆永久丢失。用 benchmark 数据量化这个损失。

## Decisions

- 篇幅：4000-5000 字
- 深度：3 层（现象 → 机制 → 后果）
- 公平对待竞品：描述它们的设计意图，再分析局限
- 使用 MemPalace benchmark 中 Mem0 ~85% vs MemPalace 96.6% 的数据
- 不使用贬义词描述竞品

## Boundaries

### Allowed
- book/src/ch02-summary-trap.md

### Forbidden
- 不要嘲讽竞品团队
- 不要编造竞品的内部实现细节

## Out of Scope

- MemPalace 的解决方案细节（第二部分展开）
- 竞品的定价模型比较（第 23 章）

## Completion Criteria

Scenario: 公平分析竞品
  Test: manual_review_fairness
  Given 第 2 章内容
  When 检查对 Mem0/Zep/Letta 的描述
  Then 每个竞品都有其设计意图的正面描述
  And 局限性分析基于公开 benchmark 数据而非主观评价

Scenario: 核心论证完整
  Test: manual_review_argument
  Given 读者读完第 2 章
  When 评估论证链
  Then 理解 "LLM 提取 → 信息损失 → 不可逆" 的因果链
  And 理解为什么这比"不记忆"更危险（错误记忆 vs 无记忆）

Scenario: 数据支撑
  Test: manual_review_data
  Given 第 2 章内容
  When 检查 benchmark 引用
  Then 包含至少一组对比数据（MemPalace vs 竞品）
  And 数据来源标注清楚（来自 benchmarks/BENCHMARKS.md）
