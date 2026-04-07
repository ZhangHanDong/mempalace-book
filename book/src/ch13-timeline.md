# 第13章：时间线叙事

> **定位**：第四部分"时间维度"的收束章。从 `timeline()` 方法的实现出发，展示如何将离散的时态三元组转化为可读的编年史，并探讨其在新人 onboarding 等场景中的应用价值。

---

## 从三元组到故事

知识图谱擅长回答结构化的查询："Kai 现在在做什么项目？""auth migration 是谁负责的？""这条事实什么时候失效的？" 但当你需要了解一个实体的完整历史时——比如一个新加入团队的工程师想要快速了解某个项目的来龙去脉——单独的三元组查询就不够了。你需要的不是一条一条独立的事实，而是一个按时间排列的叙事。

这就是 `timeline()` 方法的设计目的：把离散的三元组按时间排序，形成一个可读的编年史。

---

## timeline() 的实现

`timeline()` 方法位于 `knowledge_graph.py:274-311`。它的接口非常简洁：

```python
def timeline(self, entity_name: str = None):
    """Get all facts in chronological order, optionally filtered by entity."""
```

一个参数，一个选择：你可以查看特定实体的时间线，也可以查看整个知识图谱的时间线。

### 实体时间线

当提供 `entity_name` 参数时（`knowledge_graph.py:277-289`）：

```python
if entity_name:
    eid = self._entity_id(entity_name)
    rows = conn.execute(
        """
        SELECT t.*, s.name as sub_name, o.name as obj_name
        FROM triples t
        JOIN entities s ON t.subject = s.id
        JOIN entities o ON t.object = o.id
        WHERE (t.subject = ? OR t.object = ?)
        ORDER BY t.valid_from ASC NULLS LAST
    """,
        (eid, eid),
    ).fetchall()
```

有三个设计要点值得注意。

**双向匹配。** `WHERE (t.subject = ? OR t.object = ?)` —— 实体可能出现在三元组的任意一端。当查询 "Kai" 的时间线时，既会包含 `Kai -> works_on -> Orion` 这样 Kai 作为主语的记录，也会包含 `Priya -> manages -> Kai` 这样 Kai 作为宾语的记录。这保证了时间线是完整的——一个人的故事不仅包括他做了什么，还包括什么发生在他身上。

**时间排序。** `ORDER BY t.valid_from ASC` —— 按生效时间升序排列，最早的事实排在最前面。这是编年体的天然顺序：从过去走向现在。

**NULL 排最后。** `NULLS LAST` —— 没有明确生效时间的事实被放到时间线的末尾。这些是"不知道什么时候开始的"事实。把它们排在最后而不是最前面是一个合理的选择：在一条编年史中，有确切日期的事件比没有日期的事实更有参考价值，应该优先展示。

### 全局时间线

当不提供 `entity_name` 时（`knowledge_graph.py:291-298`）：

```python
else:
    rows = conn.execute("""
        SELECT t.*, s.name as sub_name, o.name as obj_name
        FROM triples t
        JOIN entities s ON t.subject = s.id
        JOIN entities o ON t.object = o.id
        ORDER BY t.valid_from ASC NULLS LAST
        LIMIT 100
    """).fetchall()
```

全局时间线查询所有三元组，同样按时间排序，但增加了 `LIMIT 100` 的限制。这是一个务实的安全阀：如果知识图谱中有上万条三元组，一次性全部返回既浪费内存又让调用方无法处理。100 条是一个合理的默认值——足以展示知识图谱的概貌，又不会过载。

### 返回结构

两种查询共享同一个返回格式（`knowledge_graph.py:300-311`）：

```python
return [
    {
        "subject": r[10],
        "predicate": r[2],
        "object": r[11],
        "valid_from": r[4],
        "valid_to": r[5],
        "current": r[5] is None,
    }
    for r in rows
]
```

每条记录是一个字典，包含六个字段。`subject`、`predicate`、`object` 构成事实本身，`valid_from`、`valid_to` 标记时间窗口，`current` 标记是否仍然有效。

注意，这里的 `subject` 和 `object` 使用的是 `r[10]` 和 `r[11]`——这是 SQL JOIN 结果中的 `sub_name` 和 `obj_name`，也就是实体的原始显示名称而不是标准化后的 ID。这对时间线叙事至关重要：用户看到的应该是 "Kai" 而不是 "kai"，是 "auth-migration" 而不是 "auth-migration" 的内部 ID。

---

## 一个完整的示例

假设我们为 Driftwood 项目建立了以下知识图谱：

```python
kg = KnowledgeGraph()

# 项目成立
kg.add_triple("Priya", "created", "Driftwood", valid_from="2024-09-01")
kg.add_triple("Priya", "manages", "Driftwood", valid_from="2024-09-01")

# 团队组建
kg.add_triple("Kai", "joined", "Driftwood", valid_from="2024-10-01")
kg.add_triple("Soren", "joined", "Driftwood", valid_from="2024-10-15")
kg.add_triple("Maya", "joined", "Driftwood", valid_from="2024-11-01")

# 技术决策
kg.add_triple("Driftwood", "uses", "PostgreSQL", valid_from="2024-10-10")
kg.add_triple("Kai", "recommended", "Clerk", valid_from="2026-01-01")
kg.add_triple("Driftwood", "uses", "Clerk", valid_from="2026-01-15")

# 任务分配
kg.add_triple("Maya", "assigned_to", "auth-migration", valid_from="2026-01-15")
kg.add_triple("Maya", "completed", "auth-migration", valid_from="2026-02-01")

# 人员变动
kg.add_triple("Leo", "joined", "Driftwood", valid_from="2026-03-01")
```

调用 `kg.timeline("Driftwood")`，返回结果如下：

```python
[
    {"subject": "Priya",     "predicate": "created",     "object": "Driftwood",   "valid_from": "2024-09-01", "valid_to": None,  "current": True},
    {"subject": "Priya",     "predicate": "manages",     "object": "Driftwood",   "valid_from": "2024-09-01", "valid_to": None,  "current": True},
    {"subject": "Kai",       "predicate": "joined",      "object": "Driftwood",   "valid_from": "2024-10-01", "valid_to": None,  "current": True},
    {"subject": "Driftwood", "predicate": "uses",         "object": "PostgreSQL",  "valid_from": "2024-10-10", "valid_to": None,  "current": True},
    {"subject": "Soren",     "predicate": "joined",      "object": "Driftwood",   "valid_from": "2024-10-15", "valid_to": None,  "current": True},
    {"subject": "Maya",      "predicate": "joined",      "object": "Driftwood",   "valid_from": "2024-11-01", "valid_to": None,  "current": True},
    {"subject": "Kai",       "predicate": "recommended", "object": "Clerk",       "valid_from": "2026-01-01", "valid_to": None,  "current": True},
    {"subject": "Driftwood", "predicate": "uses",         "object": "Clerk",       "valid_from": "2026-01-15", "valid_to": None,  "current": True},
    {"subject": "Maya",      "predicate": "assigned_to", "object": "auth-migration", "valid_from": "2026-01-15", "valid_to": None,  "current": True},
    {"subject": "Maya",      "predicate": "completed",   "object": "auth-migration", "valid_from": "2026-02-01", "valid_to": None,  "current": True},
    {"subject": "Leo",       "predicate": "joined",      "object": "Driftwood",   "valid_from": "2026-03-01", "valid_to": None,  "current": True},
]
```

从这组结果中，一个人类读者或者一个 LLM 可以重建出 Driftwood 项目的完整故事：

> 2024 年 9 月，Priya 创建了 Driftwood 项目并担任管理者。10 月，Kai 加入团队，团队选择了 PostgreSQL 作为数据库。随后 Soren 在 10 月中旬加入，Maya 在 11 月加入。
>
> 进入 2026 年，Kai 在 1 月推荐了 Clerk 作为认证方案，团队在 1 月 15 日正式采纳。Maya 同时被分配了 auth migration 任务，并在 2 月 1 日完成。3 月，新成员 Leo 加入了团队。

这就是"从三元组到故事"的过程。原始数据是一组离散的、结构化的事实记录；经过时间排序后，它们自然地排列成一条叙事线，因果关系浮现出来——Kai 推荐 Clerk 在前，团队采纳 Clerk 在后；Maya 被分配任务在前，完成任务在后。

---

## 排序、聚合与格式化

`timeline()` 方法本身只完成了第一步：排序。它把三元组按 `valid_from` 升序排列，返回一个按时间排列的列表。但从原始列表到可读叙事之间，还有两个步骤通常由调用方完成。

### 聚合

原始时间线中，每条记录都是独立的三元组。但在叙事中，某些三元组应该被聚合展示。比如，Kai 和 Soren 都在 2024 年 10 月加入 Driftwood，在叙事中可以合并为"10 月，Kai 和 Soren 先后加入团队"。

聚合的策略可以很简单：按 `valid_from` 的月份（或周、日）分组，把同一时间段内的同类事件合并。具体的分组粒度取决于时间线的跨度——如果项目历史跨越数年，按月分组比较合理；如果只有几周，按日分组更清晰。

### 格式化

时间线数据可以被格式化为多种形式：

**纯文本编年史**——就像上面那段重建的叙事，适合在对话中直接呈现给用户。

**结构化时间轴**——按时间段分组的项目符号列表，适合快速扫描：

```
2024-09  Priya 创建了 Driftwood 项目
2024-10  Kai 加入 | 选择 PostgreSQL | Soren 加入
2024-11  Maya 加入
2026-01  Kai 推荐 Clerk | 团队采纳 Clerk | Maya 开始 auth migration
2026-02  Maya 完成 auth migration
2026-03  Leo 加入
```

**AAAK 压缩格式**——利用 MemPalace 的 AAAK 方言进一步压缩，适合作为 AI 上下文的一部分：

```
TL:DRIFTWOOD|PRI.create(24-09)|KAI.join(24-10)|PG.adopt(24-10)|SOR.join(24-10)|MAY.join(24-11)|CLK.rec:KAI(26-01)|CLK.adopt(26-01)|MAY.auth-mig(26-01>26-02)|LEO.join(26-03)
```

`timeline()` 方法返回的是结构化数据而非格式化文本，这给了调用方最大的灵活性。MCP 服务器可以把它格式化为对话中的自然语言回复，CLI 可以把它格式化为终端输出的表格，AAAK 压缩器可以把它转换为超紧凑的时间线摘要。

---

## 应用场景：新人 Onboarding

时间线叙事最直接的应用场景是新人 onboarding。当一个新的团队成员加入时，他们面对的不是一个新建的、空白的项目——他们面对的是一个有历史的系统，背后有无数次讨论、决策、推翻和重来。

传统的 onboarding 依赖于两种信息来源：文档和口头传授。文档往往是过时的（上次更新是六个月前），口头传授则是碎片化的（取决于你问了谁、问了什么问题）。

时间线叙事提供了第三种途径：从知识图谱自动生成的、按时间排列的项目历史。

### 一个 onboarding 场景

Leo 是 Driftwood 团队的新成员，2026 年 3 月加入。他对项目一无所知。他的 AI 助手通过 MCP 调用 `mempalace_kg_timeline`：

```
> 告诉我 Driftwood 项目的历史

调用 mempalace_kg_timeline("Driftwood")

Driftwood 项目时间线：

2024 年 9 月 - Priya 创建了项目并担任管理者
2024 年 10 月 - Kai 加入（后端），团队选择了 PostgreSQL
2024 年 10 月中 - Soren 加入（前端）
2024 年 11 月 - Maya 加入（基础设施）
2026 年 1 月 - Kai 推荐 Clerk 替代 Auth0（理由：定价和开发者体验）
2026 年 1 月 15 日 - 团队采纳 Clerk，Maya 负责 auth migration
2026 年 2 月 1 日 - Maya 完成 auth migration
2026 年 3 月 - 你（Leo）加入团队
```

这段回复让 Leo 在几秒钟内了解了项目的完整脉络。他知道了谁创建了项目，团队是怎么组建的，做了哪些关键技术决策，以及为什么做了这些决策。

更重要的是，他可以继续追问细节。时间线是入口，不是终点：

```
> Kai 为什么推荐 Clerk 而不是 Auth0？

调用 mempalace_search("Clerk Auth0 decision")

来自 2026 年 1 月的对话记录：
"Kai 比较了 Clerk 和 Auth0 的定价模型，发现 Clerk 在我们预期的
用户规模下便宜 40%。此外，Clerk 的 SDK 文档更好，集成测试更
容易写。团队 1 月 15 日会议上一致同意采用 Clerk。"
```

时间线提供了概貌，知识图谱中的 `source_closet` 链接可以追溯到原始的对话记录，宫殿结构的语义搜索可以提供完整的上下文。三个系统协同工作，形成了从"全景"到"特写"的信息检索链条。

### 与传统 onboarding 的对比

| 维度 | 传统 onboarding | 时间线叙事 |
|------|-----------------|-----------|
| 信息来源 | 文档 + 口头传授 | 知识图谱自动生成 |
| 时效性 | 依赖人工更新 | 随知识图谱实时更新 |
| 完整性 | 取决于文档维护者的勤奋程度 | 覆盖所有录入的事实 |
| 交互性 | 静态文档 | 可以追问细节 |
| 个性化 | 通用文档，不区分读者 | 可以针对特定角色或关注点过滤 |

时间线叙事不能完全替代传统的 onboarding。有些知识——团队文化、沟通风格、非正式的工作规范——不适合被编码为三元组。但对于"项目的技术决策历史"这个特定维度，时间线叙事提供了一种比文档和口头传授都更可靠的方式。

---

## 时间线的局限

`timeline()` 方法的设计是有意识地简约的，这种简约带来了一些局限。

**没有因果关系。** 时间线只是按时间排序的事实列表。它不能告诉你事实之间的因果关系——"Kai 推荐了 Clerk" 和 "团队采纳了 Clerk" 在时间上相邻，人类读者可以推断前者导致了后者，但时间线数据本身不编码这种关系。

因果关系需要更复杂的知识表示——比如事件之间的 `caused_by` 或 `led_to` 关系。这超出了当前时态三元组模型的范围。但从另一个角度看，让 LLM 从时间排列的事实中推断因果关系，正是 LLM 擅长的事情。时间线提供了素材，LLM 负责叙事。

**没有重要度排序。** 所有事实被平等对待。"Priya 创建了 Driftwood"和"Driftwood 使用 PostgreSQL"在时间线中占据同样的位置，但前者显然比后者对项目叙事更重要。

一种可能的改进是引入重要度标记（可以利用 `confidence` 字段或新增一个 `importance` 字段），让时间线可以按重要度过滤。但这又引入了"谁来判断重要度"的问题——与 MemPalace"不让 AI 决定什么重要"的核心理念存在张力。

**全局时间线的 100 条限制。** `LIMIT 100` 是一个硬编码的安全阀。对于小规模知识图谱来说这足够了，但如果知识图谱增长到数千条三元组，100 条可能只覆盖了很早期的历史。一种改进是支持分页查询（提供 `offset` 和 `limit` 参数），或者支持按时间范围过滤（只查看最近 6 个月的时间线）。

这些局限都是有意识的设计取舍。MemPalace 的时间线功能定位是"够用"——提供足够的结构让 LLM 可以生成可读的叙事，但不试图自己成为一个完整的时间线分析工具。复杂的因果推理、重要度判断、跨时间段的趋势分析——这些更适合在 LLM 层面完成，时间线只需要提供干净的、按时间排序的结构化数据作为输入。

---

## 时间线与宫殿结构的关系

时间线叙事是 MemPalace 三大子系统协作的一个缩影。

**知识图谱**提供结构化的事实和时间信息。`timeline()` 方法从这里获取排序后的三元组列表。

**宫殿结构**提供上下文和原始记忆。通过 `source_closet` 字段，时间线中的每条事实都可以追溯到宫殿中的一个 closet，从 closet 又可以追溯到 drawer 中的原始逐字内容。

**AAAK 方言**提供压缩能力。当时间线需要作为 AI 上下文的一部分加载时，AAAK 可以将一段完整的项目编年史压缩到极少的 token 中。

这种协作是自然的、无缝的。三个子系统各自做好自己的事情——知识图谱管理事实，宫殿结构管理记忆，AAAK 管理压缩——然后通过简单的接口协同工作。没有哪个子系统依赖另一个子系统的内部实现细节。

这种低耦合、高协作的架构风格，正是 MemPalace 能在只有两个外部依赖的情况下实现丰富功能的原因之一。

---

## 小结

`timeline()` 方法用不到 40 行代码（`knowledge_graph.py:274-311`）实现了从离散三元组到编年史的转换。它的设计遵循了 MemPalace 一贯的哲学：简单的数据结构，清晰的查询接口，把复杂的呈现和推理工作留给 LLM。

时间排序是最基本的叙事结构。`ORDER BY t.valid_from ASC` 这一行 SQL 把一堆无序的事实变成了一条故事线。双向匹配（`subject = ? OR object = ?`）保证了故事的完整性。`NULLS LAST` 把缺少时间信息的事实放到最后，避免它们干扰编年体的主线。

这不是一个复杂的功能。但它不需要是。它只需要提供足够好的原材料，让 LLM 来完成"讲故事"的最后一公里。这种"基础设施做简单的事，智能层做复杂的事"的分工，是 MemPalace 架构设计中反复出现的模式。

至此，第四部分"时间维度"结束。我们看到了时态知识图谱如何给事实赋予生命周期（第 11 章），如何利用时间信息检测矛盾（第 12 章），以及如何将离散的时态事实编织成可读的叙事（第 13 章）。这三章共同展示了一个核心洞见：在 AI 记忆系统中，**时间不是元数据，时间是数据本身**。
