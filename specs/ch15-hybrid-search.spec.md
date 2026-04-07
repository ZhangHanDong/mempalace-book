spec: task
name: "第15章：混合检索——从 96.6% 到 100%"
tags: [book, part5, memory-stack, benchmark]
estimate: 0.5d
depends: [ch14-memory-layers]
---

## Intent

分析纯 ChromaDB 语义搜索达到 96.6% 后，加入 Haiku 重排序如何到达 100%。
深入分析 3.4% 的失败案例：语义相似但答案不在 top-5 的情况。
向量距离到语义理解的跃迁。成本分析：500 次 Haiku 调用 ≈ $0.70。

## Decisions

- 篇幅：4000-5000 字
- 深度：3 层（数据 → 失败分析 → 混合方案）
- 必须引用源码：searcher.py
- 引用 benchmarks/BENCHMARKS.md 和 benchmarks/HYBRID_MODE.md
- 包含失败案例的类型分析

## Boundaries

### Allowed
- book/src/ch15-hybrid-search.md

### Forbidden
- 不要将 100% 说成"永远完美"——声明测试范围

## Out of Scope

- 与竞品的完整对比（第 23 章）

## Completion Criteria

Scenario: 失败案例分析
  Test: manual_review_failures
  Given 第 15 章内容
  When 检查 3.4% 失败分析
  Then 对失败案例进行了分类（至少 2 种类型）
  And 解释了为什么纯向量搜索无法解决这些案例

Scenario: 混合方案成本效益
  Test: manual_review_cost_benefit
  Given 第 15 章内容
  When 检查混合方案分析
  Then 包含 Haiku 调用成本的具体计算
  And 分析了 96.6% → 100% 的边际价值

Scenario: 源码引用
  Test: manual_review_source
  Given 第 15 章内容
  When 检查源码引用
  Then 引用 searcher.py 的检索逻辑
  And 引用混合模式的重排序实现
