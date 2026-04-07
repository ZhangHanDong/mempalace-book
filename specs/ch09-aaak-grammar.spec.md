spec: task
name: "第9章：AAAK 的语法设计"
tags: [book, part3, aaak, implementation]
estimate: 0.5d
depends: [ch08-compression-constraints]
---

## Intent

深入 AAAK 语法设计：3 字母实体编码、管道分隔、箭头因果、星级重要性、情感标记。
分析 dialect.py 的实现。核心洞察：模型第一次看到 spec 就能读写 AAAK，
因为它本质上就是英语的极限压缩形态。
如果引用 `mempalace_status` 注入 spec 的路径，需要注明这依赖 palace 已初始化；未初始化时 `status` 返回的是 `_no_palace()`。
如果讨论 `dialect.py` 的 `generate_layer1()`，需要明确它是 AAAK 工具链里的独立生成功能，不是当前 `layers.py wake_up()` 默认接入的主路径。

## Decisions

- 篇幅：4000-5000 字
- 深度：3 层（语法规则 → 实现 → 设计洞察）
- 必须引用源码：dialect.py
- 包含英文原文 vs AAAK 的对照示例（来自 README）
- 分析 30x 压缩比的计算方法

## Boundaries

### Allowed
- book/src/ch09-aaak-grammar.md

### Forbidden
- 代码引用不超过 15 行/段

## Out of Scope

- 跨模型兼容性（第 10 章）

## Completion Criteria

Scenario: 语法规则清晰
  Test: manual_review_grammar
  Given 读者读完第 9 章
  When 给出一段英文
  Then 读者能尝试将其转换为 AAAK 格式

Scenario: 源码分析
  Test: manual_review_source
  Given 第 9 章内容
  When 检查源码引用
  Then 引用 dialect.py 中的核心函数
  And 解释压缩/解压缩的实现逻辑

Scenario: 30x 压缩比论证
  Test: manual_review_compression
  Given 第 9 章内容
  When 检查压缩比声明
  Then 有具体的 token 计算对比（原文 vs AAAK）
  And 不仅给出比率还给出计算过程
