spec: task
name: "第11章：时态知识图谱"
tags: [book, part4, knowledge-graph]
estimate: 0.5d
---

## Intent

分析 MemPalace 的时态知识图谱设计——事实有 valid_from/valid_to 生命周期。
与传统静态 KG 和 Zep Graphiti 对比。解释为什么选 SQLite 而不是 Neo4j：
本地优先、零运维、足够用。

## Decisions

- 篇幅：4000-5000 字
- 深度：3 层（静态 vs 时态 → schema 设计 → 技术选型权衡）
- 必须引用源码：knowledge_graph.py
- 包含 schema 表结构
- 包含与 Zep Graphiti 的对比表（来自 README）
- 如果讨论 `source_closet`，需要说明它在当前实现里是可选字段，不是默认自动填充链路

## Boundaries

### Allowed
- book/src/ch11-temporal-kg.md

### Forbidden
- 不要深入 SQLite 教程
- 代码引用不超过 20 行/段

## Out of Scope

- 矛盾检测算法（第 12 章）
- 时间线叙事（第 13 章）

## Completion Criteria

Scenario: 时态设计动机清晰
  Test: manual_review_temporal
  Given 读者读完第 11 章
  When 评估对时态 KG 的理解
  Then 理解为什么传统 KG 不够（事实会过期）
  And 能解释 valid_from/valid_to 的语义

Scenario: 技术选型有论据
  Test: manual_review_tech_choice
  Given 第 11 章内容
  When 检查 SQLite vs Neo4j 分析
  Then 列出了选择 SQLite 的具体原因（本地、零运维、够用）
  And 承认 Neo4j 在某些场景下的优势

Scenario: 源码对应
  Test: manual_review_source
  Given 第 11 章内容
  When 检查源码引用
  Then 引用 knowledge_graph.py 的 schema 定义
  And 引用 add_triple 和 query_entity 的实现
