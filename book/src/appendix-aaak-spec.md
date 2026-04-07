# 附录 C：AAAK 方言完整参考

> 本附录整合了 `mcp_server.py` 中的 `AAAK_SPEC` 常量和 `dialect.py` 中的完整编码表，
> 提供 AAAK 方言的可查阅参考。源码基线：MemPalace v3.0.0。

---

## 概述

AAAK 是一种面向 AI 智能体的压缩速记格式。它不是给人类读的——它是给 LLM 读的。
任何能读英文的模型（Claude、GPT、Gemini、Llama、Mistral）都能直接理解 AAAK，
无需解码器或微调。

---

## 格式结构

### 行类型

| 前缀 | 含义 | 格式 |
|------|------|------|
| `0:` | 头部行 | `FILE_NUM\|PRIMARY_ENTITY\|DATE\|TITLE` |
| `Z` + 数字 | Zettel 条目 | `ZID:ENTITIES\|topic_keywords\|"key_quote"\|WEIGHT\|EMOTIONS\|FLAGS` |
| `T:` | 隧道（跨条目关联） | `T:ZID<->ZID\|label` |
| `ARC:` | 情感弧线 | `ARC:emotion->emotion->emotion` |

### 字段分隔

- **管道** `|` 分隔同一行内的不同字段
- **箭头** `→` 表示因果或转变关系
- **星级** `★` 到 `★★★★★` 表示重要性（1-5 级）

---

## 实体编码

实体名取前三个字母的大写形式：

| 原名 | 编码 | 规则 |
|------|------|------|
| Alice | ALC | `name[:3].upper()` |
| Jordan | JOR | |
| Riley | RIL | |
| Max | MAX | |
| Ben | BEN | |
| Priya | PRI | |
| Kai | KAI | |
| Soren | SOR | |

源码位置：`dialect.py:367-379`（`encode_entity` 方法）

---

## 情感编码表

AAAK 使用标准化的短编码表示情感状态。

### 核心情感编码

| 英文 | 编码 | 含义 |
|------|------|------|
| vulnerability | `vul` | 脆弱 |
| joy | `joy` | 喜悦 |
| fear | `fear` | 恐惧 |
| trust | `trust` | 信任 |
| grief | `grief` | 悲伤 |
| wonder | `wonder` | 惊奇 |
| rage | `rage` | 愤怒 |
| love | `love` | 爱 |
| hope | `hope` | 希望 |
| despair | `despair` | 绝望 |
| peace | `peace` | 平静 |
| humor | `humor` | 幽默 |
| tenderness | `tender` | 温柔 |
| raw_honesty | `raw` | 坦诚 |
| self_doubt | `doubt` | 自我怀疑 |
| relief | `relief` | 释然 |
| anxiety | `anx` | 焦虑 |
| exhaustion | `exhaust` | 疲惫 |
| conviction | `convict` | 确信 |
| quiet_passion | `passion` | 沉静的热情 |
| warmth | `warmth` | 温暖 |
| curiosity | `curious` | 好奇 |
| gratitude | `grat` | 感恩 |
| frustration | `frust` | 挫折感 |
| confusion | `confuse` | 困惑 |
| satisfaction | `satis` | 满足 |
| excitement | `excite` | 兴奋 |
| determination | `determ` | 决心 |
| surprise | `surprise` | 惊讶 |

源码位置：`dialect.py:47-88`（`EMOTION_CODES` 字典）

### MCP 服务器中的简写标记

`mcp_server.py` 的 `AAAK_SPEC` 使用 `*marker*` 格式标注情感语境：

| 标记 | 含义 |
|------|------|
| `*warm*` | 温暖/喜悦 |
| `*fierce*` | 坚定/决心 |
| `*raw*` | 脆弱/坦诚 |
| `*bloom*` | 温柔/绽放 |

---

## 情感信号检测

`dialect.py` 通过关键词匹配自动检测文本中的情感：

| 关键词 | 映射编码 |
|--------|---------|
| decided | `determ` |
| prefer | `convict` |
| worried | `anx` |
| excited | `excite` |
| frustrated | `frust` |
| confused | `confuse` |
| love | `love` |
| hate | `rage` |
| hope | `hope` |
| fear | `fear` |
| happy | `joy` |
| sad | `grief` |
| surprised | `surprise` |
| grateful | `grat` |
| curious | `curious` |
| anxious | `anx` |
| relieved | `relief` |
| concern | `anx` |

源码位置：`dialect.py:91-114`（`_EMOTION_SIGNALS` 字典）

---

## 语义标志（Flags）

标志标记事实断言的类型，辅助检索和分类。

| 标志 | 含义 | 触发关键词 |
|------|------|-----------|
| `DECISION` | 显式决策或选择 | decided, chose, switched, migrated, replaced, instead of, because |
| `ORIGIN` | 起源时刻 | founded, created, started, born, launched, first time |
| `CORE` | 核心信念或身份支柱 | core, fundamental, essential, principle, belief, always, never forget |
| `PIVOT` | 情感转折点 | turning point, changed everything, realized, breakthrough, epiphany |
| `TECHNICAL` | 技术架构或实现细节 | api, database, architecture, deploy, infrastructure, algorithm, framework, server, config |
| `SENSITIVE` | 需要谨慎处理的内容 | （由人工标注） |
| `GENESIS` | 直接导致了现存事物的产生 | （由上下文推断） |

源码位置：`dialect.py:117-152`（`_FLAG_SIGNALS` 字典）

---

## 宫殿结构标识

| 元素 | 格式 | 示例 |
|------|------|------|
| Wing | `wing_` + 名称 | `wing_user`, `wing_code`, `wing_myproject` |
| Hall | `hall_` + 类型 | `hall_facts`, `hall_events`, `hall_discoveries`, `hall_preferences`, `hall_advice` |
| Room | 连字符 slug | `chromadb-setup`, `gpu-pricing`, `auth-migration` |

---

## 完整示例

### 原始英文（~70 token）

```
Priya manages the Driftwood team: Kai (backend, 3 years), Soren (frontend),
Maya (infrastructure), and Leo (junior, started last month). They're building
a SaaS analytics platform. Current sprint: auth migration to Clerk.
Kai recommended Clerk over Auth0 based on pricing and DX.
```

### AAAK 编码（~35 token）

```
TEAM: PRI(lead) | KAI(backend,3yr) SOR(frontend) MAY(infra) LEO(junior,new)
PROJ: DRIFTWOOD(saas.analytics) | SPRINT: auth.migration→clerk
DECISION: KAI.rec:clerk>auth0(pricing+dx) | ★★★★
```

### 事实断言验证

| # | 断言 | AAAK 中的对应 | 保留 |
|---|------|-------------|------|
| 1 | Priya 是团队领导 | `PRI(lead)` | Yes |
| 2 | Kai 做后端 | `KAI(backend,3yr)` | Yes |
| 3 | Kai 有 3 年经验 | `KAI(backend,3yr)` | Yes |
| 4 | Soren 做前端 | `SOR(frontend)` | Yes |
| 5 | Maya 做基础设施 | `MAY(infra)` | Yes |
| 6 | Leo 是初级工程师 | `LEO(junior,new)` | Yes |
| 7 | Leo 上个月入职 | `LEO(junior,new)` | Yes |
| 8 | 项目叫 Driftwood | `DRIFTWOOD` | Yes |
| 9 | 是 SaaS 分析平台 | `saas.analytics` | Yes |
| 10 | 当前 sprint 是 auth 迁移 | `SPRINT: auth.migration→clerk` | Yes |
| 11 | 迁移目标是 Clerk | `→clerk` | Yes |
| 12 | Kai 推荐 Clerk | `KAI.rec:clerk` | Yes |
| 13 | 理由是定价和开发体验 | `pricing+dx` | Yes |

13/13 事实断言全部保留。压缩比 ~2x（此示例较短且信息密集）。

---

## MCP 服务器中的 AAAK_SPEC

以下是 `mcp_server.py:102-119` 中通过 `mempalace_status` 工具传递给 AI 的完整规范：

```
AAAK is a compressed memory dialect that MemPalace uses for efficient storage.
It is designed to be readable by both humans and LLMs without decoding.

FORMAT:
  ENTITIES: 3-letter uppercase codes. ALC=Alice, JOR=Jordan, RIL=Riley, MAX=Max, BEN=Ben.
  EMOTIONS: *action markers* before/during text. *warm*=joy, *fierce*=determined,
            *raw*=vulnerable, *bloom*=tenderness.
  STRUCTURE: Pipe-separated fields. FAM: family | PROJ: projects | ⚠: warnings/reminders.
  DATES: ISO format (2026-03-31). COUNTS: Nx = N mentions (e.g., 570x).
  IMPORTANCE: ★ to ★★★★★ (1-5 scale).
  HALLS: hall_facts, hall_events, hall_discoveries, hall_preferences, hall_advice.
  WINGS: wing_user, wing_agent, wing_team, wing_code, wing_myproject,
         wing_hardware, wing_ue5, wing_ai_research.
  ROOMS: Hyphenated slugs representing named ideas (e.g., chromadb-setup, gpu-pricing).

EXAMPLE:
  FAM: ALC→♡JOR | 2D(kids): RIL(18,sports) MAX(11,chess+swimming) | BEN(contributor)

Read AAAK naturally — expand codes mentally, treat *markers* as emotional context.
When WRITING AAAK: use entity codes, mark emotions, keep structure tight.
```

AI 在首次调用 `mempalace_status` 时自动接收此规范，无需手动配置。

---

## 压缩流水线

`dialect.py` 的 `compress()` 方法执行五阶段处理：

```mermaid
graph TD
    A[原始文本] --> B["1. 实体检测<br/>name[:3].upper()"]
    B --> C["2. 主题提取<br/>去停用词 + 频率排序"]
    C --> D["3. 关键语句筛选<br/>_extract_key_sentence()"]
    D --> E["4. 情感/标志检测<br/>关键词 → 编码映射"]
    E --> F["5. AAAK 组装<br/>管道分隔 + 头部行"]
```

阶段 1-2 和 4-5 是**格式压缩**（无损，保留全部事实断言）。
阶段 3 是**内容筛选**（有损，选择"关键"句子，未选中的内容仍保存在 Drawer 中）。

源码位置：`dialect.py:539-602`（`compress` 方法）
