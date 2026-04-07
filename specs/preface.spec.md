spec: task
name: "前言：一个演员、一个比特币工程师、和一个 AI"
tags: [book, preface]
estimate: 0.5d
---

## Intent

书籍前言。以 Ben Sigman 的公开宣言为开场，展开创始人背景、
项目发布反响、写书动机。设定全书基调：技术+产品，非教程。

## Decisions

- 篇幅：2000-3000 字
- Ben 的原始推文作为引用开场
- Milla Jovovich 的身份（GitHub architect + 好莱坞演员）
- Ben 的背景（UCLA Classics + Bitcoin Libre + 系统工程）
- Brian Roemmele 的 79 人部署作为早期验证
- 2200+ GitHub stars 作为社区反响
- 包含至少 2 条推荐阅读路径

## Boundaries

### Allowed
- book/src/preface.md

### Forbidden
- 不要编造创始人语录
- 不要过度渲染名人效应

## Out of Scope

- 技术细节

## Completion Criteria

Scenario: 创始人背景真实
  Test: manual_review_founders
  Given 前言内容
  When 检查创始人描述
  Then Ben 的描述与公开信息一致（UCLA Classics, Bitcoin Libre CEO）
  And Milla 的描述与公开信息一致（GitHub architect, 演员）
  And 不编造未公开的信息

Scenario: 阅读路径
  Test: manual_review_reading_paths
  Given 前言内容
  When 检查阅读指引
  Then 包含至少 2 条推荐路径（如：AI 工具开发者路径、产品经理路径）
  And 路径覆盖不同背景的读者

Scenario: 基调设定
  Test: manual_review_tone
  Given 前言内容
  When 评估写作风格
  Then 既有叙事张力又不失技术严谨
  And 明确声明"这不是教程，是设计分析"
