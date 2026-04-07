# 第21章：本地模型集成

> **定位**：本章阐释 MemPalace 如何在本地依赖和默认嵌入资产准备完成后长期离线运行——从 ChromaDB 到本地模型到 AAAK 压缩——以及为什么整个栈的设计从第一天起就把"无需持续联网"作为硬约束而非可选特性。

---

## 离线不是降级模式

大多数 AI 记忆系统把离线支持当作一种降级模式：云端是完整功能，本地运行时砍掉一些特性、降低一些性能、免去一些费用作为交换。Mem0 的核心是云端 API，自部署只是企业版的选项。Zep 的知识图谱运行在 Neo4j 之上，虽然可以本地搭建，但推荐配置是云端实例。

MemPalace 的设计方向完全相反：**主路径是本地，云端增强只是旁路。** ChromaDB 是嵌入式向量数据库，数据存储在本地文件系统。知识图谱用 SQLite，同样是本地文件。AAAK 压缩是纯字符串操作，不依赖任何外部服务。MCP 服务器走 stdio 通道，不涉及网络。更准确地说，对已经完成本地依赖和默认嵌入资产准备的环境，你可以在一台断网的笔记本上完成存储、搜索、唤醒和知识图谱查询；只有 benchmark 中那条追求 100% 的 Haiku/Sonnet rerank 路径，才额外引入了云端模型。

这种设计不是技术洁癖。它来自对记忆数据本质的判断：**个人记忆是最敏感的数据类型之一，它不应该需要用户信任任何第三方。** 你的技术决策、团队动态、个人偏好、项目进展——这些信息的集合比任何单个文档都更敏感，因为它描绘的是一个完整的工作画像。把这个画像托管在别人的服务器上，需要一个很强的理由。而"方便"不是一个足够强的理由。

本章的主题不是"如何在本地安装和配置"——那是文档的工作。本章的主题是：当整个栈都在本地时，AI 和记忆之间的集成路径是什么样的？

---

## 路径一：wake-up 命令

看 `cli.py:107-118` 中的 `cmd_wakeup` 实现：

```python
def cmd_wakeup(args):
    """Show L0 (identity) + L1 (essential story)
    — the wake-up context."""
    from .layers import MemoryStack

    palace_path = (os.path.expanduser(args.palace)
                   if args.palace
                   else MempalaceConfig().palace_path)
    stack = MemoryStack(palace_path=palace_path)

    text = stack.wake_up(wing=args.wing)
    tokens = len(text) // 4
    print(f"Wake-up text (~{tokens} tokens):")
    print("=" * 50)
    print(text)
```

它做了一件简单的事：从宫殿中提取 L0（身份）和 L1（关键事实），输出到终端。用户把这段文本复制进本地模型的系统提示中，模型就拥有了宫殿的核心记忆。

命令行的使用方式：

```bash
mempalace wake-up > context.txt
# 把 context.txt 的内容粘贴到本地模型的系统提示

mempalace wake-up --wing driftwood > context.txt
# 项目特定的唤醒上下文
```

`MemoryStack.wake_up()`（`layers.py:380-399`）的内部逻辑分两步。第一步加载 L0：读取 `~/.mempalace/identity.txt`——一个用户手写的纯文本文件，定义 AI 的身份。第二步生成 L1：从 ChromaDB 中拉取最重要的 15 条记忆（按重要性排序），按 room 分组，截断到 3200 字符上限，格式化为紧凑的文本块。

按当前源码口径，这段输出通常是 **~600-900 token**，CLI 还会在打印前用 `len(text) // 4` 做一次粗略估算（`cli.py:114-117`）。README 里出现的 ~170 token，描述的是另一条更激进的目标路径：把 L1 改写成 AAAK 后再用于 wake-up。也就是说，"本地模型可用"和"唤醒只有 170 token"是两个不同命题；前者已经实现，后者还没有接到默认命令上。

为什么用 wake-up 这个名字而不是 "load-context" 或 "get-summary"？因为这个操作的语义不是"获取数据"，而是"唤醒一个有记忆的代理"。当本地模型加载了这段 L0 + L1 文本后，它从一个对用户一无所知的通用模型，变成了一个知道用户是谁、在做什么项目、关心什么事情的专属助手。这是身份的注入，不是数据的传输。

---

## 路径二：Python API

wake-up 命令适合手动工作流——用户在终端和本地模型之间来回切换。但如果你在构建一个自动化的管线——比如一个本地运行的代理框架，或者一个自定义的聊天界面——你需要编程接口。

`searcher.py:87-142` 中的 `search_memories` 函数是这个接口的核心：

```python
from mempalace.searcher import search_memories

results = search_memories(
    "auth decisions",
    palace_path="~/.mempalace/palace",
    wing="driftwood",
)
# results = {
#   "query": "auth decisions",
#   "filters": {"wing": "driftwood", "room": None},
#   "results": [
#     {"text": "...", "wing": "...", "room": "...",
#      "source_file": "...", "similarity": 0.87},
#     ...
#   ]
# }
```

它返回一个字典而非打印到终端。字典中的 `results` 列表包含每条匹配记忆的原文、空间坐标、来源文件和相似度分数。调用者拿到这个字典后，可以把记忆文本注入到发给本地模型的 prompt 中。

一个典型的集成模式：

```python
from mempalace.searcher import search_memories
from mempalace.layers import MemoryStack

# 1. 加载唤醒上下文
stack = MemoryStack()
wakeup = stack.wake_up()

# 2. 按需搜索相关记忆
results = search_memories("auth migration timeline")
memories = "\n".join(r["text"] for r in results["results"])

# 3. 组装 prompt，发送给本地模型
prompt = f"""## 你的记忆
{wakeup}

## 相关记忆
{memories}

## 用户问题
为什么我们选了 Clerk 而不是 Auth0？
"""
# response = local_model.generate(prompt)
```

这段代码不依赖任何网络请求。`MemoryStack` 从本地 ChromaDB 读取数据，`search_memories` 在本地做向量检索，prompt 组装是纯字符串拼接，`local_model.generate` 调用的是本地运行的模型推理。整条链路从头到尾在本机完成。

注意 `search_memories` 和 MCP 服务器中的 `tool_search` 实际上调用的是同一个函数（`mcp_server.py:173-180`）。MCP 路径和 Python API 路径在底层收敛到同一个检索引擎。这意味着通过 MCP 使用 Claude 找到的记忆，和通过 Python API 注入本地模型的记忆，来自完全相同的数据源和检索逻辑。不存在"MCP 版的记忆更好"这种情况。

---

## 完整离线栈的组成

把所有组件放在一起看，一个在冷启动准备完成后可长期离线运行的 MemPalace 栈长什么样：

**存储层：ChromaDB（嵌入式）+ SQLite。** ChromaDB 在本地文件系统中存储向量嵌入和文档，默认位置 `~/.mempalace/palace`。从当前仓库源码本身能直接确认的是：MemPalace 并没有显式配置一个外部 embedding 服务，而是直接依赖 ChromaDB 的默认本地嵌入路径。对已经完成首次资产准备的环境，这条路径之后可以持续离线使用。知识图谱用 SQLite，存储在 `~/.mempalace/knowledge_graph.sqlite3`。两个数据库加起来对磁盘的要求微乎其微——一个有 22,000 条记忆的宫殿，全部数据加索引大约 200-300MB。

**压缩层：AAAK 方言。** 纯规则驱动的文本压缩，不依赖任何模型。实体名替换为三字母代码，结构化为管道分隔格式，情绪标记为星号标记。它已经作为独立能力存在于仓库里，但当前默认 `wake-up` 仍然输出原文式的 L0 + L1，而不是 AAAK 版唤醒文本。换句话说，AAAK 已经是离线栈的一部分，但它还没有完全成为本地模型入口的默认表达层。

**接口层：CLI + Python API。** `mempalace wake-up` 输出唤醒文本，`mempalace search` 输出搜索结果。两个命令的输出都是纯文本，可以通过管道、重定向、或者复制粘贴注入任何模型。Python API 提供编程式访问，返回结构化数据供自动化管线使用。

**推理层：用户选择的本地模型。** MemPalace 不绑定任何特定模型。它的输出是文本——任何能读文本的模型都能消费。这不是一个技术中立的姿态，而是架构约束的自然结果：当你的输出格式是纯文本时，你的消费者可以是任何文本处理器，无论是 70B 参数的 Llama 还是 7B 的 Mistral，无论是本地推理还是 API 调用。

---

## 为什么这样设计：两个关键决策

回看这个离线栈，两个设计决策值得深入分析。

### 决策一：文本作为接口，而非工具调用

MCP 路径下，AI 通过工具调用访问记忆——结构化的输入参数，结构化的 JSON 返回。但本地模型路径下，接口退化为纯文本。wake-up 输出是文本，search 输出是文本，AAAK 是文本。

这看似是降级——从结构化 API 降级到字符串复制粘贴。但实际上，文本是最具通用性的接口格式。JSON API 要求消费者理解 schema。工具调用要求消费者实现 MCP 协议。而文本只要求消费者能读。

这个选择的更深层意义在于：它不要求本地模型有任何"特殊能力"。不需要 function calling 支持，不需要 tool use 训练，不需要 JSON mode。一个只经过基础文本生成训练的 7B 模型，只要能读普通文本，就能消费 `wake-up` 输出。当前这段文本大约是 600-900 token；如果未来切到 AAAK 版 wake-up，这个门槛还会更低。

### 决策二：AAAK 是纯文本协议，不是编码格式

AAAK 的设计中有一个容易被忽略的关键特性：它不需要解码器。

比较一下其他压缩方案。如果你用 gzip 压缩记忆文本，你得到极高的压缩率，但 LLM 无法直接读 gzip 二进制。如果你用自定义 token 编码——比如把 "Alice" 映射为一个特殊 token——你需要修改模型的词表，或者在推理前做一次解码。

AAAK 两者都不需要。`ALC=Alice` 是一个可读的映射。`|` 是一个可见的分隔符。`★★★★` 是一个直觉上可以理解的评分。任何 LLM——无论其训练数据、词表、或推理框架——都可以直接阅读 AAAK 文本并正确理解其含义。

这是让整个本地栈成立的基础假设。如果 AAAK 需要一个解码步骤，那么在本地模型的推理管线中就需要插入一个预处理器。预处理器意味着额外的代码、额外的依赖、额外的故障点。纯文本的 AAAK 消除了这个层次——记忆从存储到消费是端到端的纯文本流，中间没有任何转换步骤。

---

## 两条路径的取舍

wake-up 路径和 Python API 路径不是替代关系，而是互补关系。它们服务不同的使用场景。

**wake-up 路径适合交互式使用。** 用户坐在终端前，开启一个新的对话，先运行 `mempalace wake-up`，把输出粘贴到模型的上下文中，然后开始对话。整个过程需要 10 秒左右，额外 token 消耗通常在 600-900 之间。适合日常的问答、头脑风暴、代码审查。它的优势是零集成成本——不需要写代码，不需要改配置，不需要搭管线。README 中更轻的 ~170 token 口径，则属于这一流程的下一阶段优化目标。

**Python API 路径适合自动化管线。** 开发者构建一个自定义的代理框架——也许是一个基于 LangChain 的工作流，也许是一个自定义的 CLI 工具，也许是一个 IDE 插件——通过 `search_memories` 在每次对话前自动检索相关记忆，注入到 prompt 中。额外 token 消耗取决于搜索结果的数量和长度，通常在 500-2000 token 之间。适合需要深度记忆整合的场景——项目回顾、决策追溯、知识库查询。

两条路径共享同一个宫殿。wake-up 中看到的记忆和 API 中检索到的记忆来自同一个 ChromaDB 实例。切换路径不需要数据迁移、不需要重新索引、不需要格式转换。宫殿是唯一的事实源——访问方式是可替换的。

---

## 离线的代价与回报

诚实地说，完全离线运行有代价。

**嵌入质量的代价。** ChromaDB 默认的 all-MiniLM-L6-v2 是一个小型嵌入模型。它的语义理解能力不如 OpenAI 的 text-embedding-3-large 或 Cohere 的 embed-v3。在极端的语义匹配场景下——比如用"为什么我们放弃了旧的认证系统"搜索一条包含"Auth0 的定价在用户超过一万时变得不可持续"的记忆——小模型可能会漏掉而大模型不会。MemPalace 通过宫殿结构的过滤来弥补这个差距：当你告诉搜索"在 wing_driftwood 的 auth-migration room 里找"时，搜索空间缩小到几十条记忆，小模型在这个范围内的准确率与大模型相当。这也是为什么宫殿结构带来 34% 的检索增益——结构弥补了模型。

**推理能力的代价。** 本地模型的推理能力通常弱于云端大模型。一个 7B 参数的模型可能无法像 Claude 那样精确地理解 AAAK 日记中的模式标记、正确推断时间关系、或者在多条矛盾记忆之间做出判断。但 MemPalace 的设计哲学是：**让存储层做存储的事，让推理层做推理的事。** 如果记忆被正确检索并呈现给模型，即使模型的推理能力有限，它至少在正确的事实基础上推理。这比一个推理能力很强但基于幻觉的回答要好得多。

**回报是确定的。** 隐私保护——你的记忆永远不离开你的机器。零运行成本——除了电费，没有任何月费。无限可用性——不依赖网络连接、不受 API 限流影响、不因服务宕机而失忆。以及一种更深层的回报：自主权。你的记忆系统不受任何第三方的定价决策、隐私政策变更、或服务关停影响。它在你的硬盘上，用你选择的模型运行，输出你控制的文本。

这不是每个用户都需要的权衡。如果你的记忆内容不敏感，云端方案的便利性可能更有价值。但对于那些记忆内容涉及商业决策、团队人事、个人生活的用户来说——而这恰恰是记忆系统最有价值的使用场景——离线能力不是一个可选特性，而是一个前提条件。

MemPalace 的整个技术栈是围绕这个前提条件设计的。ChromaDB 而非 Pinecone，SQLite 而非 Neo4j，AAAK 而非 GPT 摘要，stdio 而非 HTTP。每一个技术选择都指向同一个方向：你的记忆应该完全属于你，无论你是否连接互联网。
