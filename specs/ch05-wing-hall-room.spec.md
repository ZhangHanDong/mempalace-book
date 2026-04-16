spec: task
name: "第5章：Wing / Hall / Room / Closet / Drawer"
tags: [book, part2, palace, architecture]
estimate: 1d
---

## Intent

深入分析 MemPalace 五层结构的设计动机。Wing 是语义边界，Hall 是认知分类，
Room 是概念节点，Closet 是压缩索引，Drawer 是不可篡改原文。
每个设计决策背后的权衡。

## Decisions

- 篇幅：5000-6000 字
- 深度：3 层（结构描述 → 设计动机 → 权衡分析）
- 必须引用源码：palace_graph.py, searcher.py, mcp_server.py
- 包含至少 1 个 Mermaid 架构图
- Hall 固定 5 种的设计理由需要从源码中推断

## Boundaries

### Allowed
- book/src/ch05-wing-hall-room.md

### Forbidden
- 不要重复第 4 章的 Method of Loci 内容
- 代码引用不超过 20 行/段

## Out of Scope

- Tunnel 跨 wing 连接（第 6 章）
- 检索性能数据（第 7 章）

## Completion Criteria

Scenario: 五层结构清晰
  Test: manual_review_five_layers
  Given 读者读完第 5 章
  When 评估对结构的理解
  Then 能画出 Wing → Hall → Room → Closet → Drawer 的层次图
  And 理解每层的设计动机（不仅是"是什么"还有"为什么"）

Scenario: 源码引用准确
  Test: manual_review_source_refs
  Given 第 5 章内容
  When 检查源码引用
  Then 至少引用 palace_graph.py 和 searcher.py
  And 每个引用标注 file:line
  And 引用的代码在 v3.0.0 中存在

Scenario: 包含架构图
  Test: manual_review_diagram
  Given 第 5 章内容
  When 检查 Mermaid 图
  Then 至少包含 1 个展示五层关系的架构图

Scenario: 设计权衡讨论
  Test: manual_review_tradeoffs
  Given 第 5 章内容
  When 检查设计决策分析
  Then 讨论了 Hall 为什么是固定 5 种而不是用户自定义
  And 讨论了 Room 用 slug 而不是自由文本的原因

## 版本演化附注（v3.3.0）

- 章末已追加"版本演化说明"小节，记录 Hall 检测从"叙述层"走向"实现层"（PR `#835`，`config.py:74-112` `DEFAULT_HALL_KEYWORDS`）。
- 章内正文保持 v3.0.0 基线，只 clarify 了 `DEFAULT_HALL_KEYWORDS` / `DEFAULT_TOPIC_WINGS` 两个同名不同角色的对象。
- 未动 Chapter 7 的"+Hall: 84.8%"基准数字——在版本演化说明中标注 v3.3.0 下需重跑确认。
