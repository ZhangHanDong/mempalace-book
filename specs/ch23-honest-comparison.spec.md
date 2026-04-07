spec: task
name: "第23章：竞品对比的诚实分析"
tags: [book, part8, validation]
estimate: 0.5d
depends: [ch22-benchmark-methodology]
---

## Intent

诚实对比 MemPalace 与 Mem0、Zep、Letta、Supermemory。
从成本、准确率、隐私、API 依赖四个维度。
赢在哪里（LongMemEval 100%、零成本）。
输在哪里（LoCoMo 60.3%）。

## Decisions

- 篇幅：4000-5000 字
- 深度：3 层（数据对比 → 优势分析 → 劣势坦承）
- 使用 README 中的对比表格
- LoCoMo 60.3% 需要分析原因而非回避
- 公平对待所有竞品

## Boundaries

### Allowed
- book/src/ch23-honest-comparison.md

### Forbidden
- 不要使用营销语言
- 不要编造竞品数据

## Out of Scope

- 竞品的内部架构分析

## Completion Criteria

Scenario: 公平对比
  Test: manual_review_fairness
  Given 第 23 章内容
  When 检查竞品描述
  Then 每个竞品都有公正的能力描述
  And 不使用贬义词或营销话术

Scenario: 劣势坦承
  Test: manual_review_honest_weaknesses
  Given 第 23 章内容
  When 检查 LoCoMo 60.3% 分析
  Then 坦承这个分数不占优
  And 分析了原因（多跳推理的结构性挑战）
  And 不试图用其他分数转移注意力

Scenario: 多维对比
  Test: manual_review_dimensions
  Given 第 23 章内容
  When 检查对比维度
  Then 包含成本、准确率、隐私、API 依赖四个维度
  And 每个维度有清晰结论
