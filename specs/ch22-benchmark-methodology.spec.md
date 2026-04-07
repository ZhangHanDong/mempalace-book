spec: task
name: "第22章：Benchmark 方法论"
tags: [book, part8, validation]
estimate: 0.5d
---

## Intent

分析为什么选择 LongMemEval、LoCoMo、ConvoMem 三个 benchmark。
每个 benchmark 测什么能力、有什么盲区。可复现性设计。

## Decisions

- 篇幅：4000-5000 字
- 深度：3 层（选择理由 → 能力/盲区分析 → 可复现性）
- 引用 benchmarks/ 目录的 runner 代码结构
- 引用 benchmarks/BENCHMARKS.md 的方法论部分
- 包含每个 benchmark 的特征对比表

## Boundaries

### Allowed
- book/src/ch22-benchmark-methodology.md

### Forbidden
- 不要深入每个 benchmark 的学术论文细节

## Out of Scope

- 与竞品的具体分数对比（第 23 章）

## Completion Criteria

Scenario: 选择理由充分
  Test: manual_review_selection
  Given 第 22 章内容
  When 检查 benchmark 选择理由
  Then 每个 benchmark 有选择理由
  And 分析了测试维度的互补性

Scenario: 盲区坦诚
  Test: manual_review_blind_spots
  Given 第 22 章内容
  When 检查盲区分析
  Then 每个 benchmark 都标注了局限性
  And 不回避 MemPalace 在某些维度可能不占优的事实

Scenario: 可复现性
  Test: manual_review_reproducibility
  Given 第 22 章内容
  When 检查可复现性描述
  Then 指明了 runner 代码的位置和运行方式
