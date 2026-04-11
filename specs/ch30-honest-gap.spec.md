spec: task
name: "第30章：诚实的差距"
tags: [book, part10, mempal, honest]
depends: [ch29-multi-agent-coordination]
estimate: 0.5d
---

## Intent

用数据说话，诚实记录 mempal 还不是什么。与其让读者发现问题，不如自己先说。
包含 benchmark 实测数据（model2vec 256d vs 384d baseline vs MemPalace 发布数字），
以及功能差距、架构限制、和未来方向。

## Decisions

- 篇幅：3000-4000 字
- 必须引用 benchmarks/longmemeval_s_summary.md 中的实测数据
- 必须引用 mempal drawer 中的决策记忆作为 dogfooding 证据
- 诚实第一：不隐藏劣势，不夸大优势
- 以"剩余 gap"结构组织，每个 gap 有数据支撑

## Boundaries

### Allowed
- book-en/src/ch30-honest-gap.md
- book/src/ch30-honest-gap.md

### Forbidden
- 不要做不切实际的路线图承诺
- 不要用"未来会更好"来掩盖当前问题

## Out of Scope

- 详细的性能优化方案
- crates.io 发布流程

## Completion Criteria

Scenario: benchmark 数据有实测来源
  Test: manual_review_benchmark_sourced
  Given 第 30 章内容
  When 检查 benchmark 数据
  Then 每个数字都引用了 benchmarks/longmemeval_s_summary.md
  And 包含 384d vs 256d 的对比

Scenario: 每个 gap 有数据或证据
  Test: manual_review_gaps_evidenced
  Given 第 30 章内容
  When 检查各个 gap
  Then 至少 4 个 gap 有具体的数据或事件支撑
  And 不是泛泛而谈的"需要改进"
