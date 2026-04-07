spec: task
name: "第7章：34% 的检索提升不是巧合"
tags: [book, part2, palace, benchmark]
estimate: 0.5d
depends: [ch05-wing-hall-room, ch06-tunnels]
---

## Intent

用控制实验数据证明：仅靠宫殿结构就能产生 34% 的检索提升（60.9% → 94.8%）。
在相同向量数据库、相同嵌入模型上，元数据过滤产生的差距。分析原因：
语义相似性在大规模语料中退化，结构约束充当先验知识。

## Decisions

- 篇幅：4000-5000 字
- 深度：3 层（数据呈现 → 原因分析 → 理论解释）
- 必须包含 4 级检索对比表格
- 引用 benchmarks/BENCHMARKS.md 的原始数据
- 解释向量搜索的局限性（高维空间中语义退化）

## Boundaries

### Allowed
- book/src/ch07-34-percent.md

### Forbidden
- 不要引入新的未验证假设
- 不要将 34% 归因于单一因素

## Out of Scope

- 与竞品的完整对比（第 23 章）

## Completion Criteria

Scenario: 数据呈现完整
  Test: manual_review_data
  Given 第 7 章内容
  When 检查实验数据
  Then 包含 4 级检索对比（全量/wing/wing+hall/wing+room）
  And 每级包含 R@10 数值和提升百分比

Scenario: 因果分析有深度
  Test: manual_review_causation
  Given 读者读完第 7 章
  When 评估分析深度
  Then 不仅呈现"结构提升 34%"
  And 解释了 *为什么* 结构能提升检索（向量空间退化、先验约束）

Scenario: 可复现性声明
  Test: manual_review_reproducibility
  Given 第 7 章内容
  When 检查可复现性
  Then 指向 benchmarks/ 目录的 runner 代码
  And 说明读者可以自行验证
