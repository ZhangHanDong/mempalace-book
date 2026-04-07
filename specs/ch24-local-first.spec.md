spec: task
name: "第24章：本地优先不是妥协"
tags: [book, part9, philosophy]
estimate: 0.5d
---

## Intent

论证 local-first 不是省钱手段，而是架构约束。隐私是最私密的数据——记忆。
连接 Ben Sigman 的去中心化背景（Bitcoin Libre）。MIT 开源的意义。

## Decisions

- 篇幅：3000-4000 字
- 深度：3 层（隐私论证 → 创始人背景 → 开源价值）
- 引用 Ben 的 Bitcoin Libre 经历（去中心化价值观）
- 不说教，用事实论证

## Boundaries

### Allowed
- book/src/ch24-local-first.md

### Forbidden
- 不要变成隐私政策宣言
- 不要批评使用云服务的竞品的隐私立场

## Out of Scope

- 自建部署指南

## Completion Criteria

Scenario: 隐私论证有力
  Test: manual_review_privacy
  Given 第 24 章内容
  When 检查隐私论证
  Then 论证了"记忆是最私密的数据"
  And 用具体例子说明而非抽象宣言

Scenario: 创始人背景连接
  Test: manual_review_founder
  Given 第 24 章内容
  When 检查 Ben 的背景部分
  Then 将 Bitcoin Libre 的去中心化理念与 local-first 连接
  And 这个连接是自然的叙事而非强行关联
