spec: task
name: "第14章：L0-L3 的分层设计"
tags: [book, part5, memory-stack]
estimate: 0.5d
---

## Intent

分析四层记忆栈的设计：L0 身份（当前实现 ~100 token）、L1 关键故事（当前实现 ~500-800 token），
L2 房间回忆（按需）、L3 深度搜索（按需）。每层的 token 预算如何确定，以及 README 中更轻的 AAAK 目标口径与当前实现有何差异。
为什么是 4 层而不是 2 层或 8 层。
需要明确：当前 L2 已实现为显式 `recall()/retrieve()` 过滤接口，而不是已经接入默认对话流程的自动话题触发层；它返回的是一批过滤命中的 drawer，不保证按时间排序。

## Decisions

- 篇幅：4000-5000 字
- 深度：3 层（结构描述 → 设计理由 → 预算推导）
- 必须引用源码：layers.py
- 包含各层的 token 成本表

## Boundaries

### Allowed
- book/src/ch14-memory-layers.md

### Forbidden
- 不要重复第 3 章的成本对比

## Out of Scope

- 混合检索（第 15 章）

## Completion Criteria

Scenario: 分层逻辑合理
  Test: manual_review_layers
  Given 读者读完第 14 章
  When 评估分层设计
  Then 理解每层存在的理由（不仅是"有什么"还有"为什么"）
  And 理解为什么 L0+L1 始终加载而 L2/L3 按需

Scenario: 预算推导过程
  Test: manual_review_budget
  Given 第 14 章内容
  When 检查 token 预算
  Then L0 (~100 token) 和 L1 (~500-800 token) 有具体内容示例
  And 总唤醒成本 (~600-900 token) 的经济含义有说明
  And 区分了当前实现与 README 中更轻的 AAAK 目标口径

Scenario: 源码引用
  Test: manual_review_source
  Given 第 14 章内容
  When 检查源码引用
  Then 引用 layers.py 的核心逻辑
  And 解释每层的加载机制
