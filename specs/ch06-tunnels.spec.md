spec: task
name: "第6章：隧道——跨领域发现"
tags: [book, part2, palace, graph]
estimate: 0.5d
depends: [ch05-wing-hall-room]
---

## Intent

分析 Tunnel 跨 wing 连接机制——同一 Room 出现在不同 Wing 中自动形成 Tunnel。
BFS 图遍历如何实现跨领域关联。核心技术亮点：图从 ChromaDB 元数据零成本构建，
没有额外数据库。
需要区分当前产品运行时的最小事实：跨 wing 连接主要由 `room` 元数据驱动；`hall` 在 `palace_graph.py` 中是可选增强信息，不是默认所有写入路径都稳定具备的字段。

## Decisions

- 篇幅：3000-4000 字
- 深度：3 层（概念 → 算法 → 工程实现）
- 必须引用源码：palace_graph.py 的 build_graph(), traverse(), find_tunnels()
- 包含 Mermaid 图展示 tunnel 连接示例

## Boundaries

### Allowed
- book/src/ch06-tunnels.md

### Forbidden
- 不要重复第 5 章的结构定义

## Out of Scope

- 检索性能影响（第 7 章）

## Completion Criteria

Scenario: Tunnel 机制清晰
  Test: manual_review_tunnel
  Given 读者读完第 6 章
  When 评估对 Tunnel 的理解
  Then 理解 Tunnel 是自动形成的（非手动创建）
  And 理解 BFS 遍历如何发现跨领域关联

Scenario: 零成本构建论证
  Test: manual_review_zero_cost
  Given 第 6 章内容
  When 检查"零成本构建"的论证
  Then 解释了图从 ChromaDB 元数据动态生成
  And 解释了为什么不需要额外数据库

Scenario: 源码引用
  Test: manual_review_source
  Given 第 6 章内容
  When 检查源码引用
  Then 引用 palace_graph.py 的至少 2 个函数
  And 代码片段展示 BFS 遍历逻辑
