# 第17章：无 ML 的实体发现

> **定位**：在对话文本中找到人物和项目的名字——不用 spaCy，不用 transformers，不用任何训练好的模型。只用正则表达式、频率统计和一套信号评分系统。本章讲 MemPalace 为什么选择规则而非 NER，以及这套规则系统的具体工作方式。

---

## 为什么不用 NER

命名实体识别（Named Entity Recognition, NER）是自然语言处理中的经典任务。spaCy、Stanford NER、Hugging Face 上的各种 transformer 模型都能做。给它一段文本，它告诉你哪些词是人名、地名、组织名。

对于 MemPalace 来说，用 NER 意味着什么？

首先是依赖。spaCy 本身约 30MB，加上语言模型（`en_core_web_sm` 约 12MB，`en_core_web_lg` 约 560MB），安装体积从 MemPalace 的几百 KB 膨胀到几十上百 MB。这还不算 PyTorch——如果要用 transformer 模型，PyTorch 起步就是 2GB。MemPalace 的整个依赖列表只有 chromadb 和 pyyaml，引入 NER 会让依赖体积增长两个数量级。

其次是上下文。NER 模型是在新闻、维基百科、学术论文上训练的。它们非常擅长识别"Barack Obama"、"Google"、"New York"这类在训练数据中高频出现的实体。但 MemPalace 处理的是私人对话——你女儿叫 Riley，你的项目叫 MemPalace，你的同事叫 Arjun。这些名字不在任何训练集里。NER 模型对它们的识别率取决于上下文线索，而聊天对话中的上下文线索往往不如新闻报道丰富。

再次是精度需求。MemPalace 不需要在任意文本中找出所有实体。它需要的是在用户自己的对话历史中找出反复出现的人物和项目。这是一个受限得多的问题——候选实体的数量有限（一个人的日常对话中反复提到的名字通常不超过几十个），而且有强频率信号（真正重要的实体一定会反复出现）。

这不是说 NER 不好。NER 在它的适用场景中——处理大量未知来源的文本、需要识别任意实体类型、处理多语言混合内容——是不可替代的工具。但 MemPalace 的场景恰好不是这种场景。它处理的是用户自己的、有限的、重复模式明显的对话数据。在这个约束条件下，规则方法够用，而且带来了 NER 给不了的好处：零额外依赖、毫秒级运行、完全本地、完全透明（你可以精确地知道为什么某个词被识别为人名）。

公平地说，如果 MemPalace 未来需要处理中文对话（中文没有大写字母这个天然的专有名词信号），或者需要识别组织名、地名、事件名等更多实体类型，规则方法的局限性就会显现。那时候引入 NER 可能是正确的选择。但在当前的英文对话 + 人物/项目二分类的场景下，规则足够了。

---

## 两遍扫描架构

`entity_detector.py` 使用两遍扫描的架构（`entity_detector.py:8-9`）：

**第一遍：候选提取。** 从文本中找出所有大写开头的词，统计频率，过滤掉停用词和低频词。

**第二遍：信号评分和分类。** 对每个候选词，用一组正则模式检测它是"像人"还是"像项目"，给出分数，最终分类。

这个两遍设计有一个重要好处：第一遍的计算量是 O(n)——只做一次全文扫描和词频统计。第二遍的计算量是 O(k * n)——k 是候选词数量，对每个候选词做一次全文正则匹配。因为候选词通常只有几十个（第一遍的频率过滤极大地缩小了范围），第二遍的实际计算量是可控的。

---

## 第一遍：候选提取

`extract_candidates()` 函数（`entity_detector.py:443`）负责从文本中提取候选实体。

核心逻辑是两条正则：

```python
# 单词专有名词：大写开头，1-19个小写字母
raw = re.findall(r"\b([A-Z][a-z]{1,19})\b", text)

# 多词专有名词：连续的大写开头词（如 "Memory Palace"）
multi = re.findall(r"\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)\b", text)
```

第一条匹配单个大写开头的词，比如 "Riley"、"Claude"、"Python"。长度限制在 2-20 个字符——太短的（如 "I"）不太可能是名字，太长的也不正常。

第二条匹配连续的大写开头词组，比如 "Memory Palace"、"Claude Code"。这能捕捉到多词的项目名或全名。

提取出来的候选词经过两层过滤：

1. **停用词过滤**。`STOPWORDS` 集合包含约 250 个常见英文词（`entity_detector.py:92-396`），覆盖了代词、介词、连词、常见动词、技术术语（`return`、`import`、`class`）、UI 动作词（`click`、`scroll`）、以及那些大写开头但几乎不可能是实体的词（`Monday`、`World`、`Well`）。这个列表之所以这么长，是因为英文中有大量词可以在句首出现时大写——"Step one is..."、"Click the button..."、"Well, actually..."——而这些都不是实体。

2. **频率过滤**。候选词必须出现至少 3 次（`entity_detector.py:463`）。一个真正重要的人物或项目，在对话历史中一定会反复出现。偶尔提一次的名字大概率不重要，也更容易是误判。

---

## 第二遍：信号评分

对于每个通过第一遍筛选的候选词，`score_entity()` 函数（`entity_detector.py:486`）会用一组模式去检测它更像人还是更像项目。

### 人物检测模式

MemPalace 用四类信号来判断一个词是不是人名：

**信号一：动词模式。** 人会做某些特定的动作。`PERSON_VERB_PATTERNS`（`entity_detector.py:27-48`）定义了 20 个模式：

| 模式类型 | 示例 | 权重 |
|---------|------|------|
| 言语动词 | `{name} said`, `{name} asked`, `{name} told` | x2 |
| 情感动词 | `{name} laughed`, `{name} smiled`, `{name} cried` | x2 |
| 认知动词 | `{name} thinks`, `{name} knows`, `{name} decided` | x2 |
| 意愿动词 | `{name} wants`, `{name} loves`, `{name} hates` | x2 |
| 称呼模式 | `hey {name}`, `thanks {name}`, `hi {name}` | x2 |

"Riley said" 基本上等于在说"Riley 是一个人"。项目不会 say，系统不会 laugh。这些动词是极强的人物信号。

**信号二：代词近邻。** 如果一个名字附近（前后 3 行内）出现了人称代词（`she`、`he`、`they`、`her`、`him` 等），这是一个人物信号。检测逻辑在 `entity_detector.py:515-525`：

```python
name_line_indices = [i for i, line in enumerate(lines) if name_lower in line.lower()]
pronoun_hits = 0
for idx in name_line_indices:
    window_text = " ".join(lines[max(0, idx - 2) : idx + 3]).lower()
    for pronoun_pattern in PRONOUN_PATTERNS:
        if re.search(pronoun_pattern, window_text):
            pronoun_hits += 1
            break
```

窗口大小是 5 行（前 2 行 + 当前行 + 后 2 行）。在每个窗口中只计一次代词命中（`break`），避免一个窗口中出现多个代词导致分数虚高。每次命中权重 x2。

**信号三：对话标记。** `DIALOGUE_PATTERNS`（`entity_detector.py:64-69`）识别对话文本中的说话人标注格式：

```python
DIALOGUE_PATTERNS = [
    r"^>\s*{name}[:\s]",  # > Speaker: ...
    r"^{name}:\s",         # Speaker: ...
    r"^\[{name}\]",        # [Speaker]
    r'"{name}\s+said',     # "Riley said..."
]
```

对话标记的权重最高：每次命中 x3（`entity_detector.py:503`）。因为如果一个名字出现在对话标记的位置——"Riley:" 或 "[Riley]"——它几乎一定是人名。

**信号四：直接称呼。** 如果文本中出现 "hey Riley"、"thanks Riley"、"hi Riley"，权重 x4（`entity_detector.py:528-531`）。这是所有人物信号中权重最高的，因为直接称呼某人的名字，几乎不可能是在说一个项目。

### 项目检测模式

`PROJECT_VERB_PATTERNS`（`entity_detector.py:72-89`）定义了另一组模式：

| 模式类型 | 示例 | 权重 |
|---------|------|------|
| 构建动词 | `building {name}`, `built {name}` | x2 |
| 发布动词 | `shipping {name}`, `launched {name}`, `deployed {name}` | x2 |
| 架构描述 | `the {name} architecture`, `the {name} pipeline` | x2 |
| 版本标识 | `{name} v2`, `{name}-core` | x3 |
| 代码引用 | `{name}.py`, `import {name}`, `pip install {name}` | x3 |

版本标识和代码引用的权重更高（x3），因为它们是项目的铁证——人不会有 `.py` 后缀，人不会被 `pip install`。

---

## 分类决策

`classify_entity()` 函数（`entity_detector.py:562`）根据评分结果进行最终分类。分类逻辑不仅看分数，还看信号的多样性。

核心决策树：

1. **无信号**（总分为 0）：标记为 `uncertain`，置信度最高 0.4。这些词只凭频率进入候选名单，没有任何上下文线索。

2. **人物比例 >= 70%，且有两种以上不同信号类型，且人物分 >= 5**：分类为 `person`。这里的"两种以上不同信号类型"是一个关键设计（`entity_detector.py:587-601`）。为什么需要这个额外条件？

    考虑这个场景：文本中反复出现 "Click said..."（描述某个 UI 框架的日志输出）。"Click" 会在动词模式上得到高分——"Click said" 匹配 `{name} said`。但它只在一种信号类型（言语动词）上得分。一个真正的人名通常会触发多种信号——既有 "Riley said"（言语动词），又有附近出现的 "she"（代词），还有 "hey Riley"（直接称呼）。要求两种以上不同信号类型，就过滤掉了那些只在某个特定句式中频繁出现但实际上不是人名的词。

3. **人物比例 >= 70%，但不满足多样性条件**：降级为 `uncertain`，置信度 0.4（`entity_detector.py:605-609`）。代码注释明确说明了原因："Pronoun-only match — downgrade to uncertain"。

4. **人物比例 <= 30%**：分类为 `project`。

5. **其他情况**：分类为 `uncertain`，标记 "mixed signals — needs review"。

---

## 检测流程的完整串联

`detect_entities()` 函数（`entity_detector.py:632`）把以上所有步骤串联起来：

1. 收集文件内容。每个文件只读前 5000 字节（`entity_detector.py:652`），最多读 10 个文件。这不是因为懒——是因为实体检测不需要读完整个文件。如果一个名字在前 5KB 里都没出现，它大概率不是核心实体。

2. 文件选择有讲究。`scan_for_detection()` 函数（`entity_detector.py:813`）优先选择散文文件（`.txt`、`.md`、`.rst`、`.csv`），只有散文文件不足 3 个时才 fallback 到代码文件。原因是代码文件中有太多大写开头的词——类名、函数名、常量——它们会产生大量误报。代码注释说得很清楚（`entity_detector.py:398-399`）："Code files have too many capitalized names (classes, functions) that aren't entities"。

3. 合并所有文件的文本，调 `extract_candidates()` 提取候选。

4. 对每个候选调 `score_entity()` 和 `classify_entity()`。

5. 按类型分组，按置信度排序，截取前 N 个（人物最多 15 个，项目最多 10 个，不确定最多 8 个）。

---

## 实体注册表：持久化和消歧

检测到的实体需要持久化存储，而且需要处理一些棘手的消歧问题。这是 `entity_registry.py` 的工作。

`EntityRegistry` 类（`entity_registry.py:268`）维护一个 JSON 文件（默认位于 `~/.mempalace/entity_registry.json`），存储三类信息：

```json
{
  "version": 1,
  "mode": "personal",
  "people": {
    "Riley": {
      "source": "onboarding",
      "contexts": ["personal"],
      "aliases": [],
      "relationship": "daughter",
      "confidence": 1.0
    }
  },
  "projects": ["MemPalace", "Acme"],
  "ambiguous_flags": ["ever", "max"],
  "wiki_cache": {}
}
```

实体的来源（`source`）有三个优先级：

1. **onboarding**：用户在初始化时明确告诉系统的。置信度 1.0，不可挑战。
2. **learned**：系统从会话历史中推断出来的。置信度取决于检测算法的输出。
3. **wiki**：通过 Wikipedia API 查询确认的。置信度取决于 Wikipedia 的描述内容。

### 歧义词处理

这是注册表中最有趣的部分。英文中有大量既是普通词汇又是人名的词——Ever、Grace、Will、May、Max、Rose、Ivy、Chase、Hunter、Lane......

`COMMON_ENGLISH_WORDS` 集合（`entity_registry.py:31-89`）列举了约 50 个这样的词。当这些词出现在注册表中时，系统会把它们加入 `ambiguous_flags` 列表。

之后每次查询这些词，`_disambiguate()` 方法（`entity_registry.py:463`）会检查上下文来判断是人名还是普通词汇：

**人名上下文模式**（`entity_registry.py:92-113`）：

```python
PERSON_CONTEXT_PATTERNS = [
    r"\b{name}\s+said\b",      # "Ever said..."
    r"\bwith\s+{name}\b",      # "...with Ever"
    r"\bsaw\s+{name}\b",       # "I saw Ever"
    r"\b{name}(?:'s|s')\b",   # "Ever's birthday"
    r"\bhey\s+{name}\b",       # "hey Ever"
    r"^{name}[:\s]",           # "Ever: let's go"
]
```

**普通词汇上下文模式**（`entity_registry.py:116-127`）：

```python
CONCEPT_CONTEXT_PATTERNS = [
    r"\bhave\s+you\s+{name}\b",  # "have you ever"
    r"\bif\s+you\s+{name}\b",    # "if you ever"
    r"\b{name}\s+since\b",       # "ever since"
    r"\b{name}\s+again\b",       # "ever again"
    r"\bnot\s+{name}\b",         # "not ever"
]
```

消歧逻辑简单直接：计算两组模式各匹配了多少次。如果人名模式得分高，判定为人名；如果普通词汇模式得分高，判定为概念。如果打平，返回 `None`——让调用方 fallback 到默认行为（已注册为人名的词，平局时仍当人名处理，因为用户已经声明过了）。

这套消歧机制意味着系统能正确处理这样的对话：

```
> Have you ever tried the new API?        ← "ever" = 副词
> I went to the park with Ever yesterday. ← "Ever" = 人名
```

### Wikipedia 查询

对于既不在注册表中、也不在停用词列表中的陌生大写词，注册表提供了 Wikipedia 查询功能（`entity_registry.py:179`）。

查询使用 Wikipedia 的 REST API（免费，无需 API key），根据返回的摘要内容判断词的类型：

- 如果摘要包含 "given name"、"personal name"、"masculine name" 等短语（`entity_registry.py:135-161`），判定为人名
- 如果摘要包含 "city in"、"municipality"、"capital of" 等短语，判定为地名
- 如果在 Wikipedia 上找不到（404），反而判定为人名（`entity_registry.py:249-256`）——一个不在 Wikipedia 上的大写词，很可能是某个具体的人的名字或昵称

查询结果会被缓存在 `wiki_cache` 中，避免重复请求。

### 从会话中持续学习

注册表的 `learn_from_text()` 方法（`entity_registry.py:553`）使人物检测不仅限于初始化阶段。每次处理新的会话文本时，系统可以调用这个方法，对文本运行候选提取和信号评分。如果发现新的高置信度人物候选（默认阈值 0.75），就自动加入注册表。

这形成了一个渐进式学习的循环：初始的 onboarding 提供了种子数据，之后每次会话都可能补充新发现的实体。但门槛有意设得较高（0.75），因为自动添加的成本不仅是一个错误的条目——它会影响后续所有查询的结果。宁可漏掉一些，也不要误判。

---

## 交互式确认

检测结果最终需要人类确认。`confirm_entities()` 函数（`entity_detector.py:717`）提供了一个简洁的交互界面：

```
==========================================================
  MemPalace — Entity Detection
==========================================================

  Scanned your files. Here's what we found:

  PEOPLE:
     1. Riley                [●●●●○] dialogue marker (5x), pronoun nearby (3x)
     2. Arjun                [●●●○○] 'Arjun ...' action (4x), addressed directly (2x)

  PROJECTS:
     1. MemPalace            [●●●●○] code file reference (3x), versioned (2x)

  UNCERTAIN (need your call):
     1. Claude               [●●○○○] mixed signals — needs review
```

置信度用实心/空心圆点可视化（`entity_detector.py:712`）——5 个圆点对应 0-1.0 的置信度范围。每个实体旁边还列出了触发的前两个信号，让用户能理解"为什么系统认为这是一个人名"。

用户可以接受全部检测结果、手动修正错误分类、或添加系统遗漏的实体。也可以传入 `yes=True` 跳过交互，自动接受所有非 uncertain 的结果。

---

## 规则方法的边界

规则方法在 MemPalace 的场景下工作得很好，但清楚它的边界同样重要：

| 维度 | 规则方法 | ML/NER |
|------|---------|--------|
| 依赖 | 零（标准库正则） | spaCy/transformers + 模型文件 |
| 运行速度 | 毫秒级 | 秒级（首次加载模型更慢） |
| 英文人名识别 | 依赖大写信号 + 上下文 | 基于统计模型，更鲁棒 |
| 中文人名识别 | 基本不可能（无大写信号） | 专门模型可以做 |
| 罕见名字 | 只要频率够高就能识别 | 取决于训练数据覆盖度 |
| 可解释性 | 完全透明（哪条规则触发了） | 黑箱或半透明 |
| 适用规模 | 个人对话（十到几百个文件） | 无限制 |
| 新实体类型扩展 | 需要手写新规则 | 微调或换模型 |

MemPalace 的选择不是"规则比 NER 好"，而是"在这个特定场景下，规则的投入产出比更高"。这是一个工程判断，不是一个技术信仰。

---

## 小结

实体检测模块用两遍扫描 + 信号评分的架构，在不引入任何 ML 依赖的前提下，实现了对英文对话中人物和项目的自动识别。

关键设计点：

- **两遍扫描**：先用频率过滤缩小候选范围，再用信号评分精确分类
- **四类人物信号**：动词模式、代词近邻、对话标记、直接称呼，权重从 x2 到 x4
- **多样性要求**：必须有两种以上不同信号类型才能确认为人物，防止单一模式的误判
- **持久化注册表**：三级来源优先级（onboarding > learned > wiki），歧义词上下文消歧
- **渐进式学习**：每次会话都可能发现新实体，但自动添加的门槛有意设高

下一章将讲分块——把归一化后的文本切成适合向量检索的片段。对话文本和项目文件需要完全不同的分块策略，因为它们的最小语义单元不同。
