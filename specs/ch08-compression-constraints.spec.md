spec: task
name: "第8章：压缩的约束空间"
tags: [book, part3, aaak]
estimate: 0.5d
---

## Intent

分析 AAAK 压缩语言的设计约束空间。需求：30x 压缩、零信息损失、任何文本模型可读、
无需解码器。系统性排除不可行方案：二进制编码（模型不可读）、JSON 压缩（冗余高）、
LLM 摘要（有损）。最终得出结论：AAAK 必须是"极度缩写的英语"。

## Decisions

- 篇幅：3000-4000 字
- 深度：3 层（需求 → 排除 → 设计空间）
- 使用约束满足的分析方法
- 不引用源码（本章是设计推理，非实现）

## Boundaries

### Allowed
- book/src/ch08-compression-constraints.md

### Forbidden
- 不要展示 AAAK 的具体语法（留给第 9 章）
- 不要讨论跨模型兼容性（留给第 10 章）

## Out of Scope

- AAAK 语法细节
- 模型兼容性测试

## Completion Criteria

Scenario: 约束空间分析系统化
  Test: manual_review_constraints
  Given 读者读完第 8 章
  When 评估约束分析
  Then 理解 4 个核心约束（压缩比、无损、通用可读、无解码器）
  And 理解为什么每个排除方案不满足某个约束

Scenario: 逻辑推导而非断言
  Test: manual_review_logic
  Given 第 8 章内容
  When 检查论证方式
  Then 每个排除方案有具体理由（非"显然不行"）
  And 最终结论（极度缩写的英语）从约束自然推导出
