spec: task
name: "第3章：逐字存储的经济学"
tags: [book, part1, problem-space]
estimate: 0.5d
depends: [ch02-summary-trap]
---

## Intent

从经济学角度论证"存储是廉价的，检索才是难题"。对比三种方案的成本：
全量粘贴（不可能）、LLM 摘要（$507/年）、MemPalace 唤醒（$0.70/年）。
建立全书核心论点：问题不是"存不存"，而是"怎么组织让它可检索"。

## Decisions

- 篇幅：3000-4000 字
- 深度：3 层（成本对比 → 为什么检索难 → 什么使检索可行）
- 成本数据来源：README 中的计算表格
- 包含一个 token 成本计算的完整推导过程

## Boundaries

### Allowed
- book/src/ch03-economics-of-verbatim.md

### Forbidden
- 不要深入 MemPalace 的实现细节
- 不要假设读者了解 ChromaDB 或向量数据库

## Out of Scope

- 向量数据库技术细节
- AAAK 压缩方案

## Completion Criteria

Scenario: 经济学论证清晰
  Test: manual_review_economics
  Given 第 3 章内容
  When 检查成本对比
  Then 包含三种方案的成本表格
  And 每个数字有推导过程（token 数 × 单价 × 频率）

Scenario: 建立核心论点
  Test: manual_review_thesis
  Given 读者读完前三章
  When 评估问题空间是否完整
  Then 读者接受"逐字存储 + 结构化检索"是合理方向
  And 准备好了解 MemPalace 的具体设计
