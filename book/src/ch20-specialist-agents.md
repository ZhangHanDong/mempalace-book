# 第20章：专家代理系统

> **定位**：本章分析 MemPalace 如何用宫殿的空间结构——而非配置文件的膨胀——来承载无限数量的专家代理，以及为什么每个代理的记忆是一本 AAAK 日记而非一个独立数据库。

---

## 专家代理的配置困境

假设你有 50 个 AI 代理，每个负责一个专业领域。一个审查代码质量，一个关注架构决策，一个追踪运维事件，一个记录产品需求，一个监控安全漏洞。在传统的代理框架中，每个代理需要独立的配置——系统提示词、记忆存储、状态管理、权限范围。50 个代理意味着 50 份配置文件，或者一个越来越庞大的中心配置。

Letta（前身 MemGPT）选择了中心化路径：每个代理有独立的记忆块、独立的系统提示、独立的核心记忆和归档记忆。这些都存储在云端，通过 API 管理。这很干净，但成本线性增长——免费版 1 个代理，开发者版 $20/月 10 个代理，商业版 $200/月 100 个代理。代理数量与钱包深度直接挂钩。

MemPalace 选择了一条完全不同的路径：代理不住在配置文件里，代理住在宫殿里。

---

## 一个代理 = 一个 Wing + 一本日记

回到 `mcp_server.py` 中的日记工具。`tool_diary_write`（第 349-392 行）的前三行揭示了整个架构：

```python
def tool_diary_write(agent_name, entry, topic="general"):
    wing = f"wing_{agent_name.lower().replace(' ', '_')}"
    room = "diary"
    col = _get_collection(create=True)
```

当一个名叫 "reviewer" 的代理写日记时，它的条目被存入 `wing_reviewer/diary`。当 "architect" 写日记时，存入 `wing_architect/diary`。代理的身份由它的 wing 名决定，代理的记忆由它的 diary room 承载。不需要额外的配置文件来"注册"一个代理——第一次调用 `diary_write` 时，wing 自动创建。

元数据结构（`mcp_server.py:368-380`）进一步强化了这种自然性：

```python
col.add(
    ids=[entry_id],
    documents=[entry],
    metadatas=[{
        "wing": wing,
        "room": room,
        "hall": "hall_diary",
        "topic": topic,
        "type": "diary_entry",
        "agent": agent_name,
        "filed_at": now.isoformat(),
        "date": now.strftime("%Y-%m-%d"),
    }],
)
```

每条日记条目携带完整的空间坐标——wing（哪个代理）、room（diary）、hall（hall_diary）、topic（主题标签）——加上时间坐标（`filed_at`、`date`）和身份标识（`agent`）。这些元数据使得日记条目可以被宫殿的所有现有基础设施处理：`search` 能搜索它们，`traverse` 能沿隧道从一个代理的 diary 走到另一个代理的相关记忆，`list_rooms` 能展示每个代理的 diary 规模。

代理不是宫殿之外的附加物。代理就是宫殿的居民。

---

## AAAK 日记：压缩的自我意识

代理写入日记的格式是 AAAK——这不是偶然的默认值，而是系统设计的核心。看 `diary_write` 工具的 description（`mcp_server.py:649`）：

```
Write to your personal agent diary in AAAK format. Your observations,
thoughts, what you worked on, what matters. Write in AAAK for
compression — e.g. 'SESSION:2026-04-04|built.palace.graph+diary.tools
|ALC.req:agent.diaries.in.aaak|★★★★'
```

工具描述直接示范了 AAAK 日记的格式。一个典型的代理日记条目是这样的：

```
PR#42|auth.bypass.found|missing.middleware.check|pattern:3rd.time.this.quarter|★★★★
```

这一行压缩了以下信息：在 PR #42 的审查中发现了认证绕过漏洞，原因是缺少中间件检查，这已经是本季度第三次出现同类问题，重要性四星。如果用自然语言写，至少需要三行。用 AAAK 写，一行搞定。

压缩的价值在 `diary_read` 中兑现。当代理在新会话中读取自己的历史（`mcp_server.py:395-436`），它一次加载最近 10 条日记。如果每条都是三行自然语言，10 条就是 30 行，大约 300-400 token。如果每条是一行 AAAK，10 条就是 10 行，大约 50-80 token。

对于一个代码审查代理来说，50 token 就能加载最近 10 次审查的完整摘要——发现了什么问题、在哪些 PR 里、出现了多少次、重要性如何。300 token 也能做到同样的事，但代价是上下文窗口被挤占。在一个已经需要加载代码差异、测试输出、团队规范的工作流中，250 token 的差距意味着能多看一两个文件。

AAAK 日记的管道分隔语法在这里体现出特别的优势。`pattern:3rd.time.this.quarter` 不仅记录了一个事实，还记录了一个趋势。当代理下次审查认证相关的 PR 时，它读取日记，看到这个模式标记，就知道要特别关注中间件检查——因为历史告诉它这是一个反复出现的问题。日记不是日志，日记是学习曲线的压缩编码。

---

## 50 个代理，一行配置

MemPalace 代理系统最反直觉的特性是：无论你有多少个代理，你的 CLAUDE.md（或任何系统配置文件）都不需要改变。README 中展示的配置是：

```
You have MemPalace agents. Run mempalace_list_agents to see them.
```

一行。不是"你有一个叫 reviewer 的代理，它关注代码质量，它的系统提示是..."。而是告诉 AI：你有代理，去宫殿里看看有哪些。

这种设计的底层机制是运行时发现。代理的定义文件存储在 `~/.mempalace/agents/` 目录下：

```
~/.mempalace/agents/
  ├── reviewer.json       # 代码质量、模式识别、bug 追踪
  ├── architect.json      # 设计决策、权衡分析、架构演进
  └── ops.json            # 部署、事件响应、基础设施
```

每个 JSON 文件定义了代理的焦点领域和行为模式。但关键是：这些文件不需要在任何中心配置中被引用。AI 在运行时通过宫殿的 wing 列表发现它们——`list_wings` 返回所有 wing，其中以 `wing_` 加代理名命名的 wing 就是代理的 wing。日记内容通过 `diary_read` 加载。

添加第 51 个代理意味着：创建一个 JSON 文件，然后让代理开始写日记。不需要修改任何全局配置，不需要重启任何服务，不需要更新任何提示词模板。宫殿的空间是无限的——多一个 wing 对系统的影响和多一个房间一样：零配置膨胀。

对比 Letta 的模型：每个代理有独立的 core memory（始终加载的关键事实）、recall memory（可搜索的历史）、archival memory（长期存储）。这些都通过 REST API 管理，存储在云端。添加一个代理意味着创建一个代理实例、配置其记忆块、设置其系统提示、管理其 API 密钥。50 个代理意味着 50 次这样的操作，加上持续的月费。

MemPalace 把所有这些压缩成一个 wing 和一本日记。core memory 是日记的最近 N 条。recall memory 是对 diary room 的语义搜索。archival memory 是 wing 中的其他 room。三层记忆架构隐含在宫殿的空间结构中，不需要显式管理。

---

## 代理间的隧道：共享记忆的自然涌现

宫殿架构带来的一个意外优势是代理间的知识连接。

当 reviewer 代理在 `wing_reviewer/diary` 中记录 `auth.bypass.found|missing.middleware.check`，而 architect 代理在 `wing_architect/diary` 中记录 `auth.migration.decision|clerk>auth0|middleware.layer.critical`——它们各自在自己的 wing 里，互不干扰。但 `mempalace_search("middleware")` 会同时返回两条记录。`mempalace_find_tunnels("wing_reviewer", "wing_architect")` 会发现它们共享了 "diary" room（虽然内容不同）。

更有意思的情况是当代理使用相同的 topic 标签时。如果 reviewer 的日记 topic 是 "auth"，architect 的日记 topic 也是 "auth"，那么对 `hall_diary` 中 `topic=auth` 的过滤搜索会同时命中两个代理的记忆。两个独立的专家对同一个主题的独立观察，被宫殿的结构自动关联起来。

这种关联不需要任何代理间通信协议。没有消息队列，没有共享内存，没有发布-订阅。代理各写各的日记，宫殿的搜索和导航基础设施自动把相关的记忆连接起来。这是涌现式协作——不是被设计出来的，而是从空间结构中自然生长出来的。

---

## 日记的读取：时间排序的自我回顾

`tool_diary_read`（`mcp_server.py:395-436`）的实现揭示了日记系统的最后一个设计细节：

```python
def tool_diary_read(agent_name, last_n=10):
    wing = f"wing_{agent_name.lower().replace(' ', '_')}"
    col = _get_collection()
    results = col.get(
        where={"$and": [{"wing": wing}, {"room": "diary"}]},
        include=["documents", "metadatas"],
    )
    # ... sort by timestamp, return latest N
```

它用 `$and` 条件精确定位代理的日记——wing 匹配代理名，room 固定为 "diary"。然后按时间戳倒序排列，返回最近的 N 条。

默认值 `last_n=10` 是一个经过考量的选择。太少（比如 3 条），代理丢失趋势感——看不到"这个问题反复出现"。太多（比如 50 条），日记的 token 开销超出其价值——50 条 AAAK 日记大约 400 token，已经接近 L1 层的预算。10 条在趋势识别和 token 经济之间取得了平衡。

返回结构中的 `total` 字段告诉代理它的完整日记有多长：

```python
return {
    "agent": agent_name,
    "entries": entries,
    "total": len(results["ids"]),
    "showing": len(entries),
}
```

一个有 200 条历史日记但只展示 10 条的代理，知道自己有丰富的历史但当前只看到了最近的切片。如果需要更早的记忆，它可以通过 `mempalace_search` 在自己的 wing 中做语义搜索。日记是近期回顾的快速通道，搜索是深层回忆的备用路径。

---

## 深度三层：代理架构的意义栈

把代理的三层含义叠放起来看：

**第一层：存储层。** 代理就是一个 wing。Wing 是 ChromaDB 中的一个元数据标签，不是一个独立的数据库。添加一个代理意味着增加一个标签值，系统的复杂度不增加。这是 0 到 N 代理的线性扩展——但成本函数的斜率是零（不算存储本身）。

**第二层：认知层。** 代理的记忆是一本 AAAK 日记。日记不仅记录事实，还记录模式（`pattern:3rd.time`）、重要性评估（星级）、情绪标记（`*fierce*`、`*raw*`）。当代理在新会话中读取日记时，它不是在回忆发生了什么——它是在重建对领域的理解。一个审查过 200 个 PR 的 reviewer 代理，读取 10 条最近的日记后，对代码质量的感知比一个新鲜的、没有历史的 AI 更尖锐。

**第三层：生态层。** 多个代理在同一个宫殿中各自积累专业知识，它们的记忆通过宫殿的搜索和导航基础设施被连接。reviewer 发现的 bug 模式可能与 architect 的设计决策相关；ops 记录的事件可能印证 reviewer 的代码质量担忧。这些关联不需要人工建立——它们通过共享的语义空间和命名空间自然涌现。

这三层合在一起，回答了一个更大的问题：AI 代理的记忆应该放在哪里？

放在 CLAUDE.md 里？那是配置膨胀——每多一个代理，配置文件就多一段。放在独立数据库里？那是基础设施膨胀——每多一个代理，就多一个存储实例要管理。放在云服务里？那是成本膨胀——每多一个代理，月费就多一份。

放在宫殿的一个 wing 里？那是一个标签。宫殿已经有搜索、有导航、有知识图谱、有压缩。代理只是这些已有能力的一个新消费者。它不增加基础设施，不增加配置，不增加月费。它只增加记忆——而记忆正是宫殿存在的意义。
