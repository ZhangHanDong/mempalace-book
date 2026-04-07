spec: task
name: "第1章：对话即决策"
tags: [book, part1, problem-space]
estimate: 0.5d
---

## Intent

论证 2024-2026 年间，真正的技术决策从 Jira/Confluence 迁移到了 AI 对话中。
6 个月的日常 AI 使用产生 1950 万 token 的决策记录，会话结束即蒸发。
这不是技术问题——这是知识管理范式的断裂。

## Decisions

- 篇幅：4000-5000 字
- 深度：3 层（现象 → 原因 → 影响）
- 数据来源：README 中的 token 计算、行业公开数据
- 使用具体场景（虚构但典型）说明决策如何在对话中发生

## Boundaries

### Allowed
- book/src/ch01-conversation-as-decision.md

### Forbidden
- 不要引入 MemPalace 的解决方案（留给后续章节）
- 不要贬低 Jira/Confluence 等工具

## Out of Scope

- MemPalace 的具体实现
- 竞品分析

## Completion Criteria

Scenario: 建立问题意识
  Test: manual_review_problem_statement
  Given 读者是使用 AI 编程工具的开发者
  When 读完第 1 章
  Then 意识到自己每天与 AI 的对话中包含大量不可替代的决策信息
  And 理解这些信息目前没有被系统性保存

Scenario: 包含量化数据
  Test: manual_review_quantitative
  Given 第 1 章内容
  When 检查数据支撑
  Then 包含 token 数量估算（1950 万）
  And 包含时间跨度（6 个月）
  And 数据有计算过程而非仅断言

Scenario: 不提前剧透解决方案
  Test: manual_review_no_solution
  Given 第 1 章内容
  When 搜索 "MemPalace"、"AAAK"、"Wing"、"Room" 关键词
  Then 这些词不出现或仅在章末预告中提及
