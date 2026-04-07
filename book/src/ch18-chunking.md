# 第18章：分块的学问

> **定位**：向量数据库的检索质量，有一半取决于分块策略。切太大，搜索结果充满无关内容；切太小，语义被割裂。本章讲 MemPalace 的两种分块策略——项目文件用固定窗口，对话用问答对——以及为什么对话文本不能用固定窗口。

---

## 为什么分块是个问题

向量检索的工作原理是：把文本片段转成向量，存进数据库；查询时把问题也转成向量，找最近的几个。

如果不做分块，把整个文件作为一个向量存进去呢？问题有两个。一是嵌入模型有长度限制——大多数模型只能处理 512 或 8192 个 token，超过就截断。二是即使模型能处理长文本，长文本的嵌入向量会成为所有主题的"平均值"——一个同时讨论了数据库设计、部署策略和团队管理的文档，它的向量会落在这三个主题的中间位置，结果是搜任何一个主题都搜不太到它。

所以必须切。问题是怎么切。

MemPalace 对这个问题的回答是：**项目文件和对话文件需要不同的分块策略，因为它们的最小语义单元不同。**

---

## 项目文件分块：固定窗口 + 段落感知

`miner.py` 中的 `chunk_text()` 函数（`miner.py:135`）负责项目文件的分块。它的参数定义在文件开头（`miner.py:56-58`）：

```python
CHUNK_SIZE = 800    # chars per drawer
CHUNK_OVERLAP = 100  # overlap between chunks
MIN_CHUNK_SIZE = 50  # skip tiny chunks
```

800 字符大约是 150-200 个英文词，相当于一个中等段落。选 800 而不是更大的值（比如 2000），是因为项目文件的内容通常是紧凑的——一个 Python 函数、一段 README 说明、一个配置块。800 字符足以容纳一个完整的逻辑单元，同时又小到让检索结果足够精确。

100 字符的重叠是为了处理恰好被切断的句子。如果一个重要的句子横跨两个分块的边界，重叠确保了前一个分块的最后 100 个字符和后一个分块的开头是一样的。这意味着这个句子至少在一个分块中是完整的。

但 `chunk_text()` 不是机械地每 800 字符切一刀。它有段落感知逻辑（`miner.py:153-161`）：

```python
if end < len(content):
    # 优先在双换行（段落边界）处切割
    newline_pos = content.rfind("\n\n", start, end)
    if newline_pos > start + CHUNK_SIZE // 2:
        end = newline_pos
    else:
        # 退而求其次，在单换行处切割
        newline_pos = content.rfind("\n", start, end)
        if newline_pos > start + CHUNK_SIZE // 2:
            end = newline_pos
```

它先尝试在双换行处（段落边界）切割。如果在 `[start + 400, start + 800]` 范围内找到了双换行，就在那里切。如果找不到双换行，就找单换行。如果连单换行都找不到（比如一段极长的无换行文本），才在 800 字符处硬切。

`start + CHUNK_SIZE // 2` 这个下界（即 400 字符）防止了一个问题：如果段落边界出现在分块的最开头（比如第 10 个字符处），在那里切割会产生一个极小的分块，浪费存储空间和检索资源。要求切割点至少在分块的后半段，保证了每个分块都有足够的内容量。

最后，太短的分块（小于 50 字符）会被跳过（`miner.py:164`）。空行、单行注释这些不值得单独作为一个检索单元。

---

## 对话分块：问答对是最小语义单元

现在来看对话文件的分块。`convo_miner.py` 中的 `chunk_exchanges()` 函数（`convo_miner.py:52`）走了一条完全不同的路。

### 为什么对话不能用固定窗口

假设你有这样一段对话：

```
> 我们的数据库选型应该考虑哪些因素？
考虑三个维度：一是查询模式，你们主要是 OLTP 还是 OLAP；
二是数据规模，预计未来一年的数据量；三是团队熟悉度。

> 那 PostgreSQL 和 MySQL 相比呢？
PostgreSQL 在复杂查询和 JSON 支持上更强，MySQL 在简单读写
和运维生态上更成熟。考虑到你们有 JSON 数据需求，我建议 PostgreSQL。
```

如果用 800 字符固定窗口切割，可能的切割结果是：

```
【分块 1】
> 我们的数据库选型应该考虑哪些因素？
考虑三个维度：一是查询模式，你们主要是 OLTP 还是 OLAP；
二是数据规模，预计未来一年的数据量；三是团队熟悉度。
> 那 PostgreSQL 和 MySQL 相比呢？

【分块 2】
PostgreSQL 在复杂查询和 JSON 支持上更强，MySQL 在简单读写
和运维生态上更成熟。考虑到你们有 JSON 数据需求，我建议 PostgreSQL。
```

问题出在分块 1 的最后一行：问题 "那 PostgreSQL 和 MySQL 相比呢？" 被归入了分块 1，但它的答案在分块 2 里。如果用户后来搜索 "PostgreSQL vs MySQL"，分块 1 会匹配到问题但不包含答案，分块 2 包含答案但缺少问题的上下文。两个分块都不完整。

这就是为什么对话需要以问答对为单位来分块。一个问题和它的回答是不可分割的语义单元——问题定义了上下文，回答提供了信息。拆开它们，两边都失去了意义。

### 问答对分块的实现

`_chunk_by_exchange()` 函数（`convo_miner.py:66`）的逻辑是：

```python
def _chunk_by_exchange(lines: list) -> list:
    chunks = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.strip().startswith(">"):
            # 找到一个用户发言
            user_turn = line.strip()
            i += 1
            # 收集紧跟其后的 AI 回复
            ai_lines = []
            while i < len(lines):
                next_line = lines[i]
                if next_line.strip().startswith(">") or next_line.strip().startswith("---"):
                    break
                if next_line.strip():
                    ai_lines.append(next_line.strip())
                i += 1
            # 合并为一个分块
            ai_response = " ".join(ai_lines[:8])
            content = f"{user_turn}\n{ai_response}" if ai_response else user_turn
            if len(content.strip()) > MIN_CHUNK_SIZE:
                chunks.append({"content": content, "chunk_index": len(chunks)})
        else:
            i += 1
    return chunks
```

几个细节值得注意：

**分块边界由 `>` 标记驱动。** 遇到一个 `>` 行，开始收集一个问答对。继续向下读，直到遇到下一个 `>` 行（下一个问题）或 `---` 分隔符。中间的所有非空行都是 AI 的回复。

**AI 回复被截断为前 8 行**（`convo_miner.py:86`）。这是一个有意的限制——`" ".join(ai_lines[:8])`。为什么？因为 AI 的回复可能非常长（几十行甚至上百行的代码、详细的步骤说明），但对于向量检索来说，前几行通常就包含了核心答案。把整个长回复塞进一个分块，会稀释向量的语义焦点。

**空行被跳过**（`convo_miner.py:81`）。只收集 `next_line.strip()` 非空的行。这确保了分块内容紧凑，没有无意义的空白。

**`---` 分隔符作为硬边界**（`convo_miner.py:80`）。如果对话中有 `---` 分隔线（常见于 Markdown 格式的对话日志），即使后面的内容不以 `>` 开头，也会终止当前问答对的收集。这是因为 `---` 通常表示话题切换或对话分段。

### Fallback：段落分块

如果文本中没有足够的 `>` 标记（少于 3 个），`chunk_exchanges()` 会 fallback 到 `_chunk_by_paragraph()`（`convo_miner.py:102`）：

```python
def _chunk_by_paragraph(content: str) -> list:
    chunks = []
    paragraphs = [p.strip() for p in content.split("\n\n") if p.strip()]
    if len(paragraphs) <= 1 and content.count("\n") > 20:
        lines = content.split("\n")
        for i in range(0, len(lines), 25):
            group = "\n".join(lines[i : i + 25]).strip()
            if len(group) > MIN_CHUNK_SIZE:
                chunks.append({"content": group, "chunk_index": len(chunks)})
        return chunks
    for para in paragraphs:
        if len(para) > MIN_CHUNK_SIZE:
            chunks.append({"content": para, "chunk_index": len(chunks)})
    return chunks
```

这个 fallback 处理两种情况：

1. **有段落分隔的文本**（双换行分隔）：每个段落作为一个分块。
2. **没有段落分隔但很长的文本**（超过 20 行但没有双换行）：每 25 行作为一个分块。

25 行这个数字不是随便选的——它大致对应 800 字符（假设每行 30-35 个字符），和项目文件的分块大小保持一致。

---

## 两种策略的参数对比

| 参数 | 项目文件 (miner.py) | 对话文件 (convo_miner.py) |
|------|--------------------|-----------------------|
| 分块单元 | 固定窗口（800 字符） | 问答对（大小不固定） |
| 重叠 | 100 字符 | 无（问答对之间无重叠） |
| 边界感知 | 段落边界（双换行 > 单换行） | `>` 标记 + `---` 分隔符 |
| 最小分块 | 50 字符 | 30 字符 |
| AI 回复截断 | 不适用 | 前 8 行 |
| Fallback | 无（硬切） | 段落分块 / 25 行分组 |

对话分块不需要重叠，因为问答对之间是天然分离的——问题 A 的答案和问题 B 的答案之间不存在"横跨边界的句子"这个问题。每个问答对都是自包含的。

对话分块的最小阈值（30 字符）比项目文件（50 字符）更低，因为一个简短但有意义的问答对——比如 "> 用什么语言？\nPython。"——只有 20 多个字符，但它携带了有价值的信息。

---

## 房间路由：分块之后的分类

项目文件分块后，每个分块需要被路由到对应的"房间"。`detect_room()` 函数（`miner.py:89`）用三级优先策略：

1. **文件路径匹配**：如果文件在 `docs/` 目录下，而且有一个房间叫 "docs"，直接路由到那个房间
2. **文件名匹配**：如果文件名包含某个房间名
3. **内容关键词评分**：用房间的关键词列表对内容的前 2000 字符做关键词计数

对话文件的房间路由不同。`detect_convo_room()` 函数（`convo_miner.py:194`）用五个预定义的话题分类：

```python
TOPIC_KEYWORDS = {
    "technical":    ["code", "python", "function", "bug", ...],
    "architecture": ["architecture", "design", "pattern", ...],
    "planning":     ["plan", "roadmap", "milestone", ...],
    "decisions":    ["decided", "chose", "switched", ...],
    "problems":     ["problem", "issue", "broken", ...],
}
```

这五个分类不是随意选的——它们对应了开发者在对话中最常讨论的五类话题。如果没有任何关键词匹配，fallback 到 "general"。

---

## 归一化与分块的衔接

对话文件的处理流程是一个清晰的管道（`convo_miner.py:302-317`）：

```
原始文件 → normalize() → chunk_exchanges() → 存入 ChromaDB
```

`normalize()` 确保进入分块器的内容格式统一（第 16 章），`chunk_exchanges()` 确保每个分块是一个完整的语义单元。每个分块作为一个"抽屉"（drawer）存入 ChromaDB，带上 wing、room、source_file 等元数据。

值得注意的是，对话矿工支持两种提取模式（`convo_miner.py:259`）：`"exchange"`（默认的问答对分块）和 `"general"`（通用提取器，提取决策、偏好、里程碑等特定类型的记忆）。通用提取模式的分块结果自带 `memory_type` 字段，直接作为房间名使用，绕过了 `detect_convo_room()` 的话题分类。

---

## 小结

分块看起来是一个简单的"切文本"操作，但切在哪里、切多大、切的单元是什么，直接决定了下游检索的质量。

MemPalace 的两种分块策略反映了一个基本洞察：**不同类型的文本有不同的最小语义单元。** 项目文件的最小语义单元是段落——一段代码、一段说明、一个配置块。对话的最小语义单元是问答对——问题定义上下文，回答提供信息，拆开它们两边都失去意义。

关键设计点：

- **项目文件**：800 字符窗口 + 100 字符重叠 + 段落边界感知
- **对话文件**：以 `>` 标记为分界的问答对分块，AI 回复截断为前 8 行
- **两种策略共享一个原则**：尽量在自然边界处切割，避免割裂语义
- **Fallback 策略**：对话没有 `>` 标记时降级为段落分块，保证任何输入都能处理
