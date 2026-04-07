spec: task
name: "第4章：Method of Loci"
tags: [book, part2, palace]
estimate: 0.5d
---

## Intent

从古希腊记忆术 Method of Loci 出发，解释空间结构为什么对信息检索有效。
连接认知科学研究与 AI 记忆系统设计。强调 Ben Sigman 的古典学背景——
记忆宫殿对他不是比喻，是方法论。

## Decisions

- 篇幅：4000-5000 字
- 深度：3 层（历史 → 认知科学 → AI 应用）
- 西蒙尼德斯的故事作为开篇叙事
- 引用认知科学关于空间记忆的研究（可 web search 验证）
- Ben 的 UCLA Classics 背景作为叙事纽带

## Boundaries

### Allowed
- book/src/ch04-method-of-loci.md

### Forbidden
- 不要编造认知科学引用
- 不要过度简化 Method of Loci 为"记忆技巧"

## Out of Scope

- MemPalace 的具体数据结构（第 5 章）
- Benchmark 数据（第 7 章）

## Completion Criteria

Scenario: 历史叙事引人入胜
  Test: manual_review_narrative
  Given 读者没有古典学背景
  When 读完第 4 章开头
  Then 被西蒙尼德斯的故事吸引
  And 理解空间记忆的基本原理

Scenario: 学术支撑
  Test: manual_review_academic
  Given 第 4 章内容
  When 检查认知科学引用
  Then 至少引用 1 项关于空间记忆优势的研究
  And 引用经过 web search 验证

Scenario: 连接到 AI 设计
  Test: manual_review_ai_connection
  Given 读者读完第 4 章
  When 评估从古典到 AI 的过渡
  Then 理解"空间结构 → 检索效率"的逻辑
  And 准备好理解 MemPalace 的 Wing/Room 设计
