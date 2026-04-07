spec: task
name: "第12章：矛盾检测"
tags: [book, part4, knowledge-graph]
estimate: 0.5d
depends: [ch11-temporal-kg]
---

## Intent

分析 MemPalace 如何动态检测矛盾——错误的归属、过期的任期、不一致的日期。
不是规则引擎，而是对知识图谱的实时查询。分析误报/漏报的权衡。

## Decisions

- 篇幅：3000-4000 字
- 深度：3 层（检测机制 → 实现 → 精度权衡）
- 使用 README 中的 3 个矛盾检测示例
- 引用 knowledge_graph.py 的查询逻辑
- 如果讨论 `source_closet` 溯源，需明确它依赖写入时提供该可选字段

## Boundaries

### Allowed
- book/src/ch12-contradiction.md

### Forbidden
- 不要重复第 11 章的 schema 描述

## Out of Scope

- 时间线叙事生成（第 13 章）

## Completion Criteria

Scenario: 矛盾类型覆盖
  Test: manual_review_types
  Given 第 12 章内容
  When 检查矛盾类型分析
  Then 覆盖归属冲突、任期错误、日期过期三种类型
  And 每种类型有具体示例

Scenario: 精度权衡讨论
  Test: manual_review_precision
  Given 第 12 章内容
  When 检查精度分析
  Then 讨论了误报（false positive）的场景
  And 讨论了漏报（false negative）的场景
  And 分析了当前设计的优先级选择
