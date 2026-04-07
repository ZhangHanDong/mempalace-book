spec: task
name: "第18章：分块的学问"
tags: [book, part6, pipeline]
estimate: 0.5d
---

## Intent

分析 MemPalace 的分块策略差异：项目文件（800 字符 + 100 重叠）vs
对话（按问答对）。为什么对话不能用固定长度切——问答对是最小语义单元。

## Decisions

- 篇幅：3000-4000 字
- 深度：3 层（策略差异 → 设计理由 → 边界情况）
- 必须引用源码：miner.py, convo_miner.py
- 包含分块效果的对比示例

## Boundaries

### Allowed
- book/src/ch18-chunking.md

### Forbidden
- 不要展开向量嵌入的数学原理

## Out of Scope

- 向量存储细节

## Completion Criteria

Scenario: 两种策略对比
  Test: manual_review_strategies
  Given 第 18 章内容
  When 检查分块策略分析
  Then 清楚区分了项目文件和对话的不同策略
  And 解释了每种策略的参数选择（800/100）

Scenario: 问答对论证
  Test: manual_review_qa_pairs
  Given 第 18 章内容
  When 检查问答对分块的论证
  Then 用具体示例说明固定长度切割如何破坏语义
  And 论证问答对为最小语义单元
