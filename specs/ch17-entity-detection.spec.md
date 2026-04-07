spec: task
name: "第17章：无 ML 的实体发现"
tags: [book, part6, pipeline]
estimate: 0.5d
---

## Intent

分析 MemPalace 的无 ML 实体检测方案：动词模式、代词共现、对话信号。
候选评分与交互确认。为什么不用 NER 模型——依赖少、本地运行、对话语境下规则够用。

## Decisions

- 篇幅：4000-5000 字
- 深度：3 层（规则设计 → 评分算法 → 与 ML 的比较）
- 必须引用源码：entity_detector.py, entity_registry.py
- 包含人物/项目检测的模式表
- 必须区分当前 CLI `init` 主流程写入的 `entities.json`（主要服务 AAAK / Dialect 配置路径），与 `entity_registry.py` 提供的 onboarding / 消歧 / wiki / learn-from-text 辅助链路

## Boundaries

### Allowed
- book/src/ch17-entity-detection.md

### Forbidden
- 不要批评 NER 模型——只解释为什么在此场景下规则更合适

## Out of Scope

- 分块策略（第 18 章）

## Completion Criteria

Scenario: 检测规则清晰
  Test: manual_review_rules
  Given 第 17 章内容
  When 检查检测规则
  Then 包含人物检测模式表（动词模式、代词信号等）
  And 包含项目检测模式表

Scenario: 与 ML 的对比
  Test: manual_review_ml_comparison
  Given 第 17 章内容
  When 检查与 ML 方案的对比
  Then 公平分析了规则 vs NER 的各自优势
  And 论证了在对话场景下规则足够的理由

Scenario: 源码引用
  Test: manual_review_source
  Given 第 17 章内容
  When 检查源码引用
  Then 引用 entity_detector.py 的检测逻辑
  And 引用 entity_registry.py 的注册/消歧机制
