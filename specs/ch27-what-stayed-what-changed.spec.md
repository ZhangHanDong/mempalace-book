spec: task
name: "第27章：保留了什么、改变了什么"
tags: [book, part10, mempal, architecture]
depends: [ch26-why-rewrite-in-rust]
estimate: 1d
---

## Intent

对照 MemPalace（Python）和 mempal（Rust）的架构差异，逐项说明保留了哪些设计理念、
改变了哪些实现结构、以及每个改变背后的理由。这不是 changelog，而是设计决策的比较分析。

核心张力：MemPalace 的五层结构在理论上优雅（Chapter 5），但实践中 Hall 和 Closet 层
几乎未被利用。mempal 做了务实的简化，需要解释为什么简化不是偷懒。

## Decisions

- 篇幅：5000-6000 字（本章最长，承载最多技术对比）
- 结构：按设计维度组织（空间结构、存储、压缩、时间、接口），每个维度对照 Python→Rust
- 必须引用 MemPalace 源码的具体模块（searcher.py、palace_graph.py、dialect.py）
- 必须引用 mempal 源码的具体 crate（mempal-core、mempal-search、mempal-aaak）
- 必须引用 mempal 设计文档中的决策表
- 引用书稿 Chapter 5（五层结构）和 Chapter 7（34% 改进）的数据来论证简化的合理性

## Boundaries

### Allowed
- book-en/src/ch27-what-stayed-what-changed.md

### Forbidden
- 不要变成 API 文档或使用手册
- 不要对 MemPalace 的设计做事后诸葛亮式的批评——当时的选择在当时是合理的
- 不要深入 Rust 语言层面的实现细节（所有权、生命周期等）

## Out of Scope

- 自描述协议的详细设计（Chapter 28 的内容）
- 多 Agent 协作模式（Chapter 29 的内容）
- Benchmark 对比数据

## Completion Criteria

Scenario: 五个核心理念明确保留
  Test: manual_review_five_preserved
  Given 第 27 章内容
  When 检查"保留"部分
  Then 明确列出至少 5 个从 MemPalace 保留的设计理念
  And 每个理念都引用了书稿中分析该理念的章节

Scenario: 五层变两层有数据支撑
  Test: manual_review_tier_simplification
  Given 第 27 章内容
  When 检查层级简化的论述
  Then 引用 Chapter 7 的检索改进数据说明大部分收益来自 Wing 过滤
  And 解释了 Hall/Closet 在实际使用中未被利用的原因
  And 说明 taxonomy + 可编辑 room 如何替代了静态层级

Scenario: ChromaDB → SQLite 有工程理由
  Test: manual_review_storage_switch
  Given 第 27 章内容
  When 检查存储引擎切换的论述
  Then 给出至少 3 个切换理由
  And 理由基于工程需求（事务、迁移、单文件备份、嵌入式部署）而非性能比较

Scenario: AAAK 重做回应附录 C
  Test: manual_review_aaak_redo
  Given 第 27 章内容
  When 检查 AAAK 改进的论述
  Then 明确引用附录 C 指出的缺陷（无 BNF、无解码器、无往返验证）
  And 说明 mempal-aaak crate 如何逐项修复这些缺陷
  And 提到中文分词从 CJK bigrams 到 jieba 词性标注的改进

Scenario: 时间维度的诚实取舍
  Test: manual_review_temporal_honest
  Given 第 27 章内容
  When 检查时间维度的论述
  Then 承认 triples 表存在但 temporal reasoning 未完全实现
  And 解释了优先级判断（搜索管道可靠性 > temporal features）
