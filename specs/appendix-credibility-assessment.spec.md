spec: task
name: "附录 D：真实性与可信度评估"
tags: [book, appendix, audit]
estimate: 0.5d
---

## Intent

为本书新增一个独立附录，对 MemPalace 当前开源仓库做工程可信度评估。
目标不是评价动机，而是区分三类内容：源码已证实的能力、明显超前于实现的叙事、
以及仅凭当前本地仓库无法确认的 claim。

## Decisions

- 位置：新增独立附录章节，不并入现有 AAAK 附录
- 结构：至少包含"哪些是真的"、"哪些叙事超前"、"总体判断"三部分

## Boundaries

### Allowed Changes
- book/src/SUMMARY.md
- book/src/appendix-credibility-assessment.md
- specs/appendix-credibility-assessment.spec.md

### Forbidden
- 不要把附录写成创始人动机揣测
- 不要把无法由当前本地仓库验证的内容写成确定事实
- 不要把评估写成纯情绪宣泄或道德审判

## Completion Criteria

Scenario: 附录结构清晰
  Test: manual_review_structure
  Given 读者打开新增附录
  When 通读全文
  Then 能看到明确的方法边界
  And 能区分真实实现、超前叙事、无法验证 claim
  And 附录至少包含"哪些是真的"、"哪些叙事超前"、"总体判断"三部分

Scenario: 结论审慎而明确
  Test: manual_review_judgement
  Given 新增附录
  When 检查总体判断
  Then 不会把项目直接定性成纯骗局
  And 也不会回避其宣传口径超前于实现的问题
  And 全文保持工程审计口径，不使用情绪化定性

Scenario: 与全书主线一致
  Test: manual_review_book_fit
  Given 新增附录与现有章节
  When 检查口径一致性
  Then 附录中的判断与前文章节修正后的实现边界一致
  And 不会重新引入已被修正的旧表述

Scenario: 证据边界不越界
  Test: manual_review_scope_guard
  Given 新增附录
  When 检查论证边界
  Then 判断只基于当前本地源码与书中表述
  And 不扩展到外部舆论判断或创始人动机揣测

Scenario: 证据不足时拒绝写成确定事实
  Test: manual_review_negative_path
  Given 某个外部 claim 不能由当前本地仓库验证
  When 附录提到该 claim
  Then 只能标记为无法确认或中等可信
  And 明确拒绝把它写成确定事实

## Out of Scope

- 外部舆情或社交媒体争议
- 创始人个人信誉评估
- 投资、法律或商业建议
