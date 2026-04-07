<div align="center">

# MemPalace：AI 记忆的第一性原理

### First Principles of AI Memory

**当对话成为决策的载体，记忆系统该如何设计**

<br>

基于 [MemPalace](https://github.com/milla-jovovich/mempalace) v3.0.0 源码的设计分析

中英双语 | mdbook | Mermaid 图表 | 源码引用

</div>

---

## About

这不是一本教程，而是一本设计分析。

MemPalace 是一个开源 AI 记忆系统，由 [Ben Sigman](https://x.com/bensig) 和 [Milla Jovovich](https://github.com/milla-jovovich) 与 Claude 共同构建。它在 LongMemEval 基准测试中取得了 96.6% 的零 API 基线分数（最高分 100% 含重排序，held-out 泛化分数 98.4%），完全本地运行，MIT 开源。

本书从第一性原理出发，分析 MemPalace 的每一个设计决策——从古希腊记忆术到向量数据库，从 AAAK 压缩语言到时态知识图谱。每个设计决策都有源码引用、benchmark 数据支撑和权衡分析。

## Read Online

```bash
# 中文版
mdbook serve book
# open http://localhost:3000

# English edition
mdbook serve book-en -p 3001
# open http://localhost:3001
```

## Structure

```
book/src/          中文版（25 章 + 前言 + 第 0 章）
book-en/src/       English edition (translated)
specs/             章节规格（agent-spec format）
docs/              大纲和参考文档
```

## Table of Contents

| Part | Chapters | Topic |
|------|----------|-------|
| **一：问题空间** | 1-3 | 对话即决策、摘要陷阱、逐字存储经济学 |
| **二：记忆宫殿** | 4-7 | Method of Loci、Wing/Hall/Room、隧道、34% 提升 |
| **三：AAAK** | 8-10 | 压缩约束空间、语法设计、跨模型通用性 |
| **四：时间维度** | 11-13 | 时态知识图谱、矛盾检测、时间线叙事 |
| **五：记忆栈** | 14-15 | L0-L3 分层、混合检索 96.6%→100% |
| **六：数据管道** | 16-18 | 格式归一化、实体发现、分块策略 |
| **七：接口设计** | 19-21 | MCP 19 工具、专家代理、本地模型集成 |
| **八：验证** | 22-23 | Benchmark 方法论、竞品诚实对比 |
| **九：哲学** | 24-25 | 本地优先、超越对话 |

## Tech Stack

- **[mdbook](https://rust-lang.github.io/mdBook/)** — Rust 生态的书籍构建工具
- **Mermaid** — 运行时渲染，暗色主题自适应
- **Language Switcher** — 工具栏中英切换按钮
- **agent-spec** — 每章有 BDD 风格的验收标准

## Prerequisites

```bash
cargo install mdbook
```

## Benchmark Transparency

本书在所有提及 benchmark 分数的位置都区分三个口径：

| 口径 | LongMemEval | LoCoMo |
|------|-------------|--------|
| **保守基线** | 96.6% R@5（零 API） | 60.3% R@10（baseline） |
| **诚实泛化** | 98.4% R@5（held-out 450） | 88.9% R@10（hybrid v5, top-10） |
| **竞争成绩** | 100% R@5（full 500 + rerank） | 100%（top-50 + rerank, structural） |

详见第 15 章和第 23 章的完整分析。

## License

Content: [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)

MemPalace source code: [MIT](https://github.com/milla-jovovich/mempalace/blob/main/LICENSE)
