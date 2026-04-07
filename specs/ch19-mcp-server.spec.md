spec: task
name: "第19章：MCP 服务器——19 个工具的 API 设计"
tags: [book, part7, interface]
estimate: 0.5d
---

## Intent

分析 19 个 MCP 工具的分组逻辑（读 7/写 2/KG 5/导航 3/日记 2）和设计决策。
mempalace_status 为什么是最重要的工具——它同时教会 AI AAAK 语法和记忆协议。

## Decisions

- 篇幅：4000-5000 字
- 深度：3 层（分组逻辑 → 关键工具分析 → 协议设计）
- 必须引用源码：mcp_server.py
- 包含工具分组表格
- 分析 mempalace_status 的响应结构

## Boundaries

### Allowed
- book/src/ch19-mcp-server.md

### Forbidden
- 不要逐个描述 19 个工具（选重点）
- 代码引用不超过 20 行/段

## Out of Scope

- MCP 协议本身的技术规范
- 专家代理系统（第 20 章）

## Completion Criteria

Scenario: 分组逻辑合理
  Test: manual_review_grouping
  Given 第 19 章内容
  When 检查工具分组
  Then 解释了 7/2/5/3/2 分组的设计理由
  And 不是简单列举而是分析为什么这样分

Scenario: status 工具分析深入
  Test: manual_review_status
  Given 第 19 章内容
  When 检查 mempalace_status 分析
  Then 展示了 status 响应的结构
  And 解释了如何通过一次调用完成 AAAK 教学 + 协议传递

Scenario: 源码引用
  Test: manual_review_source
  Given 第 19 章内容
  When 检查源码引用
  Then 引用 mcp_server.py 的工具注册和关键工具实现
