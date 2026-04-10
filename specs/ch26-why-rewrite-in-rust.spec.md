spec: task
name: "第26章：为什么用 Rust 重铸"
tags: [book, part10, mempal, rust]
depends: [ch25-beyond-conversations]
estimate: 1d
---

## Intent

讲述从分析 MemPalace（Python）到决定用 Rust 重铸的过程。不是"Rust 好"的布道文，
而是诚实记录：写书分析到一半发现了哪些结构性缺陷，为什么判断 patch 不如重建，
以及"单二进制、零依赖"这个产品形态如何倒逼了语言选择。

本章是 Part 10 的入口，需要让读者理解：前 25 章的分析不是纸上谈兵，
分析结论直接驱动了一个新实现。

## Decisions

- 篇幅：4000-5000 字
- 深度：3 层（触发点 → 判断逻辑 → 语言选择）
- 必须引用书稿前文具体章节（附录 C AAAK 评估、Chapter 9 语法设计、Chapter 19 MCP 工具）作为"发现缺陷"的证据
- 必须引用 mempal 源码中的具体文件/模块作为"解决方案"的证据
- mempal 设计文档：`/Users/zhangalex/Work/Projects/AI/mempal/docs/specs/2026-04-08-mempal-design.md`
- 语气：第一人称复数（我们），技术叙事而非营销文案

## Boundaries

### Allowed
- book-en/src/ch26-why-rewrite-in-rust.md

### Forbidden
- 不要写成 Rust vs Python 语言战争
- 不要贬低 MemPalace Python 版——它的设计理念是对的
- 不要列举 Rust 语言特性清单（所有权、借用检查等）除非直接相关于 mempal 的设计决策

## Out of Scope

- mempal 的具体实现细节（Chapter 27 的内容）
- Benchmark 对比数据（Chapter 30 的内容，已推迟）
- Rust 语言教程

## Completion Criteria

Scenario: 触发点有据可查
  Test: manual_review_trigger_evidence
  Given 第 26 章内容
  When 检查"为什么重写"的论据
  Then 每个触发点都引用了书稿前文的具体章节编号或附录编号
  And 至少引用附录 C（AAAK 评估）的具体发现

Scenario: 重写判断有逻辑链
  Test: manual_review_judgment_chain
  Given 第 26 章内容
  When 检查重写 vs 重构的判断
  Then 给出了至少 2 个"patch 不够"的结构性理由
  And 理由基于代码层面的分析而非主观偏好

Scenario: 语言选择不是语言战争
  Test: manual_review_no_language_war
  Given 第 26 章内容
  When 检查 Rust 选择的论述
  Then 理由聚焦于产品需求（单二进制、MCP 长连接、crates.io 分发）
  And 没有出现"Rust 比 Python 快 N 倍"之类的泛化比较

Scenario: 与前文形成闭环
  Test: manual_review_narrative_loop
  Given 第 26 章内容
  When 检查叙事结构
  Then 明确建立了"前 25 章分析 → 发现问题 → 自己动手"的叙事弧线
  And 读者理解 Part 10 是分析的实践验证而非独立的 Rust 项目介绍
