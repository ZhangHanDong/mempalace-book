spec: task
name: "第13章：时间线叙事"
tags: [book, part4, knowledge-graph]
estimate: 0.5d
depends: [ch11-temporal-kg]
---

## Intent

分析 kg.timeline() 如何将离散三元组编织成项目的编年史。
从数据库记录到可读叙事的转换逻辑。产品价值：新人 onboarding。

## Decisions

- 篇幅：3000-4000 字
- 深度：2 层（转换逻辑 → 应用场景）
- 引用 knowledge_graph.py 的 timeline() 方法
- 包含一个完整的 timeline 输出示例
- 如果讨论溯源，需区分 schema 支持的 `source_closet/source_file` 与当前是否实际填充

## Boundaries

### Allowed
- book/src/ch13-timeline.md

### Forbidden
- 不要重复第 11-12 章内容

## Out of Scope

- 知识图谱的其他查询模式

## Completion Criteria

Scenario: 转换逻辑清晰
  Test: manual_review_conversion
  Given 第 13 章内容
  When 检查从三元组到叙事的转换
  Then 包含输入（三元组列表）和输出（叙事文本）的完整示例
  And 解释了排序、聚合、格式化的步骤

Scenario: 应用场景具体
  Test: manual_review_use_case
  Given 第 13 章内容
  When 检查应用场景
  Then 包含至少一个具体的 onboarding 场景
