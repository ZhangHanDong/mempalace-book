spec: task
name: "第25章：超越对话"
tags: [book, part9, future]
estimate: 0.5d
---

## Intent

展望 MemPalace 的扩展方向。宫殿结构可适配任何数据——代码库、文档、邮件、笔记。
AAAK 进入 Closet 层的技术路线。开源社区的探索方向。
必须明确：当前公开源码里 Closet 仍主要是概念/README 层，而不是已经独立落地的运行时存储层。
也必须明确：当前 `searcher.py` 只支持显式 `wing` / `room` 过滤；知识图谱当前提供的是显式写入/查询层；README 里的 reviewer/architect/ops 属于示例化 specialist 方向，不是内建运行时体系。

## Decisions

- 篇幅：3000-4000 字
- 深度：2 层（当前适配性 → 未来方向）
- 引用 README 中"can be adapted for different types of datastores"
- 基于现有架构分析扩展可能性，不做空洞预测

## Boundaries

### Allowed
- book/src/ch25-beyond-conversations.md

### Forbidden
- 不要做不切实际的路线图承诺
- 不要暗示 MemPalace 能解决所有记忆问题

## Out of Scope

- 竞品未来路线图

## Completion Criteria

Scenario: 扩展方向基于现有架构
  Test: manual_review_grounded
  Given 第 25 章内容
  When 检查扩展讨论
  Then 每个扩展方向都基于现有架构的具体能力
  And 不是"如果重新设计"而是"当前架构如何适配"

Scenario: AAAK Closet 路线
  Test: manual_review_aaak_closet
  Given 第 25 章内容
  When 检查 AAAK Closet 讨论
  Then 解释了 AAAK 进入 Closet 层后的预期效果
  And 基于当前 dialect.py 的能力分析可行性
  And 区分了当前 drawer-only 运行时与未来 explicit closet 路线
