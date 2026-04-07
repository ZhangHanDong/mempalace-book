spec: task
name: "第10章：跨模型通用性"
tags: [book, part3, aaak, compatibility]
estimate: 0.5d
depends: [ch09-aaak-grammar]
---

## Intent

论证 AAAK 为什么能被 Claude、GPT、Gemini、Llama、Mistral 等任何文本模型理解。
这不是偶然——任何能读英文的模型都能读 AAAK，因为 AAAK 没有发明新语法，
只是省略了英语中的冗余。产品含义：记忆系统与模型供应商解耦。
如果讨论整栈离线运行，需要区分"冷启动准备本地依赖/嵌入资产"与"之后的长期离线使用"，不要把首次准备过程写成绝对零网络前提。

## Decisions

- 篇幅：3000-4000 字
- 深度：3 层（兼容性事实 → 语言学解释 → 产品含义）
- 引用 README 中"works with any model that reads text"的声明
- 分析"解耦"对用户的实际价值

## Boundaries

### Allowed
- book/src/ch10-cross-model.md

### Forbidden
- 不要对各模型做性能排名
- 不要暗示某模型"更好理解"AAAK

## Out of Scope

- 各模型的技术差异
- 本地模型部署指南

## Completion Criteria

Scenario: 通用性论证有说服力
  Test: manual_review_universality
  Given 读者使用非 Claude 的 AI 工具
  When 读完第 10 章
  Then 相信 AAAK 在自己使用的模型上也能工作
  And 理解为什么（语言学层面的解释）

Scenario: 产品解耦论述
  Test: manual_review_decoupling
  Given 第 10 章内容
  When 检查产品含义分析
  Then 讨论了"不被模型供应商锁定"的价值
  And 讨论了"整个栈离线运行"的可能性
