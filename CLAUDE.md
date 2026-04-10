# MemPalace Book Project

## What This Is

技术+产品分析书籍《MemPalace：AI 记忆的第一性原理》的中英双语 mdbook 项目。
基于 [MemPalace](https://github.com/milla-jovovich/mempalace) v3.0.0 源码分析。

## Project Structure

```
book/src/          # 中文版章节（权威源）
book-en/src/       # 英文版章节（翻译自中文）
specs/             # agent-spec 章节规格（每章的意图、约束、验收标准）
docs/book-outline.md  # 全书大纲
```

## Key References

- **大纲**: `docs/book-outline.md` — 全书 9 部分 25 章的结构和每章核心论点
- **章节 Specs**: `specs/chNN-*.spec.md` — 每章的 intent、decisions、boundaries、completion criteria
- **MemPalace 源码**: `~/Work/Projects/AI/mempalace/mempalace/` — 书中分析的 Python 源码
- **mempal 源码**: `~/Work/Projects/AI/mempal/` — Part 10 引用的 Rust 重铸版
- **mempal 设计文档**: `~/Work/Projects/AI/mempal/docs/specs/2026-04-08-mempal-design.md`
- **mempal 记忆**: 通过 `mempal_search` MCP 工具查询开发决策（drawer_id 可引用）

## Writing Rules

- 中文版是权威源，英文版从中文翻译
- 技术+产品视角，非教程。每章模式：问题 → 设计决策 → 权衡分析 → 源码实现 → 数据验证
- 源码引用格式：`file.py:line`，引用前必须验证行号准确
- 竞品分析公平对待，不使用营销语言
- 每章至少 1 个 Mermaid 图（技术章节）
- 章节标题格式：`# 第N章：标题`
- 定位锚格式：`> **定位**：`（英文版 `> **Positioning**:`）
- 跨章节引用用 `详见第N章`（英文 `see Chapter N`），不重复完整表格

## Build

```bash
mdbook serve book          # 中文版 localhost:3000
mdbook serve book-en -p 3001  # 英文版 localhost:3001
```

## Before Editing a Chapter

1. 读对应的 spec：`specs/chNN-*.spec.md`
2. 确认修改不违反 spec 的 Boundaries
3. 如果修改涉及源码引用，先验证行号：读 `~/Work/Projects/AI/mempalace/mempalace/` 下对应文件
4. Part 10 章节引用 mempal 源码：读 `~/Work/Projects/AI/mempal/crates/` 下对应文件
5. Part 10 章节引用开发决策：通过 `mempal_search` 查询，引用 drawer_id
6. 修改中文版后同步更新英文版
