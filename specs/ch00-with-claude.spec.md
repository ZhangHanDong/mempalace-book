spec: task
name: "第0章：与 Claude 一起造东西"
tags: [book, preface, collaboration]
estimate: 0.5d
---

## Intent

讲述 MemPalace 的开发过程——两个人和一个 AI 花了几个月共同构建的经历。
这不是"AI 生成代码、人审核"的模式，而是真正的协作。本章为全书设定情感基调，
并为后续讨论 MCP 集成、agent 系统提供第一手经验背景。

## Decisions

- 视角：第三人称叙事，基于 Ben Sigman 公开发言和项目 git 历史
- 不虚构对话，只基于公开信息和代码提交记录推断协作模式
- 篇幅：3000-4000 字
- 深度：2 层（What happened → Why it matters）

## Boundaries

### Allowed
- book/src/ch00-with-claude.md

### Forbidden
- 不要编造 Ben 或 Milla 的私人对话
- 不要对 Claude 的能力做夸张宣传

## Out of Scope

- 技术细节（留给后续章节）
- 竞品对比

## Completion Criteria

Scenario: 章节覆盖开发背景
  Test: manual_review_dev_background
  Given 读者是 AI 工具开发者
  When 读完第 0 章
  Then 理解 MemPalace 是人机协作产物而非纯 AI 生成
  And 理解项目的创始人背景（Milla 演员身份、Ben 古典学+工程背景）

Scenario: 不含技术实现细节
  Test: manual_review_no_tech_detail
  Given 第 0 章内容
  When 检查是否包含源码引用或架构图
  Then 不包含任何源码片段
  And 不包含架构图或 Mermaid 图

Scenario: 为后续章节建立情感连接
  Test: manual_review_emotional_hook
  Given 读者读完第 0 章
  When 评估是否有继续阅读的动力
  Then 章节以一个引人入胜的叙事结束，指向"这个系统到底是什么"
