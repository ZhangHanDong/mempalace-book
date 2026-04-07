spec: task
name: "第16章：格式归一化"
tags: [book, part6, pipeline]
estimate: 0.5d
---

## Intent

分析 5 种聊天导出格式（Claude Code JSONL、Claude.ai JSON、ChatGPT、Slack、纯文本）
的结构差异与自动检测策略。normalize.py 的设计决策：
"先统一格式再处理"优于"每种格式单独处理"。

## Decisions

- 篇幅：4000-5000 字
- 深度：3 层（格式差异 → 检测算法 → 架构选择）
- 必须引用源码：normalize.py
- 包含每种格式的 JSON 结构示例
- 包含 Mermaid 流程图展示检测分支

## Boundaries

### Allowed
- book/src/ch16-normalization.md

### Forbidden
- 代码引用不超过 15 行/段

## Out of Scope

- 实体检测（第 17 章）
- 分块策略（第 18 章）

## Completion Criteria

Scenario: 格式差异分析
  Test: manual_review_formats
  Given 第 16 章内容
  When 检查格式分析
  Then 每种格式有结构示例（JSON/JSONL 片段）
  And 标注了每种格式的关键差异点

Scenario: 检测算法
  Test: manual_review_detection
  Given 第 16 章内容
  When 检查自动检测逻辑
  Then 解释了检测优先级和 fallback 机制
  And 包含 Mermaid 流程图

Scenario: 源码引用
  Test: manual_review_source
  Given 第 16 章内容
  When 检查源码引用
  Then 引用 normalize.py 的核心检测函数
  And 不把 Slack 3+ 人对话的真实说话人身份保留写成完全无损
