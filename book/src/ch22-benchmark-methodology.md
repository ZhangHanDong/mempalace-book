# 第22章：Benchmark 方法论

> **定位**：本章解释为什么选择这三个 benchmark、每个 benchmark 测试什么能力维度、各自的盲区在哪里，以及如何让任何人在五分钟内复现全部结果。验证一个系统的最诚实方式不是展示它的成绩单，而是公开考试卷本身。

---

## 为什么需要三个 benchmark

一个 benchmark 只能回答一个问题。一个得了 96.6% 的系统可能只是恰好擅长那一种题型。

这不是假设。LongMemEval 是 AI 记忆领域最标准的测试——500 个问题，跨越 53 个对话 session，覆盖六种题型。MemPalace 在上面拿到了 96.6% 的 R@5。这个分数足够成为标题，但它只回答了一个问题：给你一堆对话历史，你能不能找到答案藏在哪个 session 里？

它没有回答：你能不能跨越多个 session 把线索串起来？它没有回答：当数据规模从 53 个 session 膨胀到数千个 session 时，性能会不会崩溃？它也没有回答：面对不同类型的记忆——事实、偏好、变化、推理——你的表现是否均匀？

所以我们选了三个 benchmark。不是因为三个数字比一个好看，而是因为每个 benchmark 测试的认知能力完全不同。它们的交集覆盖了 AI 记忆系统的三个核心维度：精确检索、多跳推理、大规模泛化。它们的盲区——每个 benchmark 测不到的东西——同样重要，本章会逐一分析。

---

## LongMemEval：大海捞针

### 它是什么

LongMemEval 是一个由学术界设计的标准化记忆评估数据集。500 个问题，每个问题对应一个"大海"——53 个对话 session 组成的历史记录——和一根"针"——问题的正确答案藏在其中一个或多个 session 里。

测试的核心能力是**信息定位**：给定一个自然语言问题，你的系统能不能在 53 个 session 中找到包含答案的那一个？不需要生成答案，不需要理解答案，只需要把正确的 session 排到前面。

### 六种题型

LongMemEval 的 500 个问题覆盖六种题型，每种测试不同的检索难度：

| 题型 | 数量 | 描述 | MemPalace 基线 |
|------|------|------|---------------|
| knowledge-update | 78 | 事实随时间变化——当前答案覆盖了旧答案 | 99.0% |
| multi-session | 133 | 答案分散在多个 session 中 | 98.5% |
| temporal-reasoning | 133 | 包含时间锚点——"上个月"、"两周前" | 96.2% |
| single-session-user | 70 | 答案在用户的某句话里 | 95.7% |
| single-session-preference | 30 | 用户间接表达的偏好 | 93.3% |
| single-session-assistant | 56 | 答案在 AI 助手的回复里 | 92.9% |

最强的两个类别——knowledge-update 和 multi-session——正是 MemPalace 的设计甜区。当事实发生更新时，原始文本保留了新旧两个版本，搜索模型能自然匹配到包含更新的 session。当答案分散在多个 session 中时，逐字存储意味着每个 session 都完整保留了自己的那部分信息，semantic search 能分别命中。

最弱的两个类别揭示了更深的问题。single-session-preference（93.3%）弱在偏好表达的间接性：用户说"我觉得 Postgres 在并发场景下更靠谱"，问题问的是"用户偏好什么数据库"——词汇完全不重叠，embedding 模型看不出两者的关联。single-session-assistant（92.9%）弱在索引缺口：默认只索引了用户发言，问题却问的是"AI 建议了什么"——答案根本不在搜索池里。

这两个弱点后来都被修复了。偏好缺口通过 16 个正则表达式模式提取偏好表达来弥补。助手缺口通过两阶段检索——先用用户发言定位 session，再在目标 session 内搜索助手发言——来解决。修复后分数从 96.6% 推进到了 99.4%，再到 100%。

### 为什么选它

LongMemEval 是目前 AI 记忆领域引用最广的 benchmark。Supermemory、Mastra、Mem0、Hindsight——所有主要竞品都在这个 benchmark 上报告了成绩。这意味着分数之间有直接可比性。如果你在 LongMemEval 上的 R@5 是 96.6%，而 Mastra 是 94.87%，这两个数字用的是同一把尺子。

它的数据是公开的——托管在 HuggingFace 上，任何人都可以下载。它的评估指标是标准化的——Recall@K 和 NDCG@K 有明确的数学定义。这些属性使它成为可复现基准测试的理想选择。

### 盲区

LongMemEval 有三个显著的盲区。

**盲区一：规模太小。** 53 个 session 是一个很小的搜索空间。一个真实用户六个月的 AI 使用会产生数百个对话 session。在 53 个 session 里排名第一和在 500 个 session 里排名第一是完全不同的任务。LongMemEval 的 96.6% 能否在十倍规模下保持？这个问题它回答不了。

**盲区二：不测推理。** LongMemEval 只测检索，不测理解。它的指标是"正确的 session 是否出现在 top-K 结果中"，而不是"系统能否用检索到的内容正确回答问题"。一个把所有 53 个 session 全部返回的系统，理论上可以拿到 100% 的 Recall@53——但它什么也没"理解"。

**盲区三：不测跨 session 推理。** multi-session 类型的问题虽然答案分散在多个 session 中，但评估标准是"任意一个相关 session 出现在 top-K 中"就算正确。它不测"把多个 session 的信息串联起来得出结论"的能力。

---

## LoCoMo：多跳推理

### 它是什么

LoCoMo（Long Conversational Memory）来自 Snap Research，是一个专门为多跳推理设计的 benchmark。10 个长对话，每个对话包含 19-32 个 session、400-600 轮对话，共产生 1986 个 QA 对。

"多跳推理"是什么意思？考虑这个场景：

- Session 5：Caroline 提到她在研究海洋生物学
- Session 12：Caroline 说她找到了一个相关的研究员职位
- Session 19：问题——"Caroline 的职业发展方向是什么？"

要回答这个问题，系统需要把 session 5 和 session 12 的信息串联起来。单独检索到其中任何一个都不够——你需要两者才能拼出完整的图景。这就是"多跳"的含义：答案不在任何一个地方，而是分布在多个位置，需要跨越多个信息节点来推理。

### 五种题型

LoCoMo 的 1986 个问题分为五种类型：

| 题型 | 描述 | MemPalace 基线 (R@10) |
|------|------|---------------------|
| single-hop | 答案在一个 session 里 | 59.0% |
| temporal | 涉及时间关系 | 69.2% |
| temporal-inference | 需要跨 session 做时间推理 | 46.0% |
| open-domain | 开放性问题 | 58.1% |
| adversarial | 故意混淆的问题——问 A 的事，但 B 说的话更多 | 61.9% |

最难的类别是 temporal-inference——需要在多个 session 之间建立时间因果关系。基线只有 46.0%。这意味着超过一半的跨时间推理问题，纯粹的语义检索找不到正确的 session。

adversarial 类别揭示了一个有趣的挑战：当两个人在同一个对话中出现时，embedding 模型分不清"谁说了什么"。如果问题问的是 Caroline 的研究方向，但 Melanie 在同一个 session 里说了更多的话，embedding 模型可能会把 Melanie 主导的 session 排得更高——即使 Caroline 的关键信息在另一个 session 里。

### 为什么选它

LoCoMo 填补了 LongMemEval 的核心盲区：跨 session 推理。LongMemEval 问的是"你能不能找到正确的 session"，LoCoMo 问的是"你能不能理解 session 之间的关系"。

它还有一个重要的设计特点：每个对话的 session 数量（19-32 个）更接近真实用户的数据规模。虽然仍然不算大，但比 LongMemEval 的 53 个 session 共用的设计更贴近"每个项目独立积累对话历史"的真实场景。

### 盲区

**盲区一：对话数量太少。** 只有 10 个对话。这意味着单个对话的异常表现会严重影响总分。如果恰好有一个对话的主题分布特别不利于你的系统，总分可能下降 5-10 个百分点。

**盲区二：对话都是虚构的。** LoCoMo 的对话是人工编写的模拟对话，不是真实用户的 AI 交互记录。虚构对话的语言模式、主题分布、信息密度都可能与真实对话有系统性差异。

**盲区三：每个对话只有两个说话者。** 真实场景中一个对话可能涉及多人——团队 standup、群组讨论、多方决策。LoCoMo 只有两人对话，没有测试多方信息交织的场景。

---

## ConvoMem：大规模覆盖

### 它是什么

ConvoMem 来自 Salesforce Research，是目前规模最大的对话记忆 benchmark——75,336 个 QA 对，覆盖六种不同的记忆类型。它不测深度推理，测的是广度和类型覆盖。

### 六个类别

| 类别 | 描述 | MemPalace R@K |
|------|------|--------------|
| assistant_facts_evidence | AI 助手说过的事实 | 100% |
| user_evidence | 用户陈述的事实 | 98.0% |
| abstention_evidence | 系统应当拒绝回答的问题 | 91.0% |
| implicit_connection_evidence | 需要推理才能建立的隐含联系 | 89.3% |
| preference_evidence | 用户的偏好和习惯 | 86.0% |
| changing_evidence | 随时间变化的事实 | -- |

assistant_facts_evidence 拿到 100% 不意外——ConvoMem 的测试方式是检查检索结果是否包含证据消息，而 MemPalace 逐条存储每一条消息（包括助手的回复），搜索时自然能命中。

preference_evidence 是最弱的类别（86.0%），原因与 LongMemEval 的偏好类别相同：偏好往往用间接语言表达，embedding 模型难以在问题和表达之间建立关联。

### 为什么选它

ConvoMem 填补了另外两个 benchmark 都缺失的维度：**类型覆盖**。LongMemEval 主要测事实检索，LoCoMo 主要测推理能力，ConvoMem 把"记忆"分成了六种不同的类型，分别测试。这很重要，因为一个在事实检索上表现优异的系统，在偏好记忆或隐含推理上可能完全不同。

它的规模（75K+ QA 对）也提供了统计显著性：当你有七万五千个数据点时，一个类别 86% 和另一个类别 100% 之间的差异是真实的，不是噪声。

### 盲区

**盲区一：每个 QA 对的上下文很短。** ConvoMem 的许多测试项只涉及几条消息的上下文，不像 LongMemEval 需要在 53 个 session 中搜索。这意味着它更多测试的是"短程匹配"而不是"长程检索"。

**盲区二：六个类别的权重不均匀。** 某些类别的样本量远大于其他类别。加权平均的 92.9% 可能掩盖了小类别上的弱点。

**盲区三：不测真实的记忆保留。** ConvoMem 假设所有对话内容都已被正确存储，只测检索能力。它不测"在六个月的持续使用中，存储质量是否退化"这样的真实世界问题。

---

## 三个 benchmark 的互补性

把三个 benchmark 放在一起看，它们形成了一个三角测量：

| 维度 | LongMemEval | LoCoMo | ConvoMem |
|------|------------|--------|---------|
| 核心能力 | 精确检索 | 多跳推理 | 类型覆盖 |
| 数据规模 | 500 问题 | 1,986 QA 对 | 75,336 QA 对 |
| Session 规模 | 53 个共用 | 19-32 个/对话 | 短上下文 |
| 推理深度 | 浅（定位） | 深（推理） | 中（分类） |
| 竞品对比 | 充分 | 有限 | 有限 |
| 数据来源 | 学术设计 | 人工模拟 | 学术设计 |
| 可复现性 | 公开数据集 | 公开数据集 | 公开数据集 |

**LongMemEval 是标尺**——所有人都在用，分数有直接可比性，是证明系统基本能力的入场券。

**LoCoMo 是试金石**——它测试 LongMemEval 测不到的推理能力，也是最容易暴露系统弱点的 benchmark。MemPalace 在 LoCoMo 上的基线只有 60.3%，这个分数不是标题材料，但它诚实地反映了纯语义检索在多跳推理任务上的局限。

**ConvoMem 是广角镜**——它不深入任何一种能力，但覆盖面最广，确保系统不是只在某一种题型上特化。

三者的交集覆盖了一个完整的评估空间：如果一个系统在 LongMemEval 上检索精准、在 LoCoMo 上推理能力达标、在 ConvoMem 上各类型表现均衡，那么你有合理的信心认为它在真实场景中也能工作。如果一个系统只在其中一个 benchmark 上得分高，你应当保持怀疑。

---

## 三者都测不到的东西

三角测量覆盖了很多维度，但有些关键能力完全不在测试范围内：

**真实的时间跨度。** 三个 benchmark 都是静态数据集。它们模拟的是"已有的对话历史"，不是"持续六个月逐渐积累的记忆"。在真实使用中，记忆系统面对的数据是渐进式增长的——每天新增几个 session，索引持续膨胀，检索质量是否会随时间退化？这个问题无法用静态 benchmark 回答。

**写入正确性。** 三个 benchmark 都假设数据已经被正确地存储了。它们不测 mining 阶段——分割、去重、分类、元数据提取。如果 MemPalace 的 convo_miner 把两个 session 错误地合并了，或者把同一段对话归到了错误的 wing，benchmark 不会捕捉到这个错误。

**端到端回答质量。** Recall@K 衡量的是"正确的 session 是否在 top-K 中"，不是"系统能否用检索到的内容正确回答问题"。一个检索完美但回答生成失败的系统，在这三个 benchmark 上仍然会拿满分。完整的端到端评估需要引入 LLM 来生成答案并计算 F1 score——这需要 API key，也意味着测的不再只是记忆系统，还包括了 LLM 本身的能力。

**多模态内容。** 三个 benchmark 都是纯文本。真实对话中包含的代码片段、错误堆栈、截图描述、链接——这些内容的检索特性与自然语言不同，但不在任何 benchmark 的测试范围内。

---

## Runner 代码结构：如何复现

所有 benchmark 的 runner 代码都在 `benchmarks/` 目录下，每个 benchmark 一个 Python 文件。设计原则是：clone、install、run——三步完成复现，不需要修改任何配置。

### 目录结构

```
benchmarks/
  longmemeval_bench.py          -- LongMemEval runner，所有模式
  locomo_bench.py               -- LoCoMo runner
  convomem_bench.py             -- ConvoMem runner
  membench_bench.py             -- MemBench runner（额外）
  BENCHMARKS.md                 -- 完整结果和方法论记录
  HYBRID_MODE.md                -- 混合检索模式的技术细节
  README.md                     -- 快速复现指南
  results_*.jsonl               -- 每次运行的原始结果
```

### longmemeval_bench.py 的核心流程

这是最重要的一个 runner，因为 LongMemEval 是竞品对比的主要战场。它的核心循环是这样的：

对于 500 个问题中的每一个：

1. **加载海底**：把该问题对应的 53 个 session 全部加载到一个 fresh 的 ChromaDB collection 中。使用 `EphemeralClient`——内存模式，没有磁盘 IO，没有 SQLite 句柄泄漏。每个问题之间清空并重建 collection。

2. **执行检索**：用问题文本查询 collection。根据 `--mode` 参数选择检索策略——raw（纯语义）、hybrid（关键词增强）、hybrid_v2（加时间增强）、palace（宫殿结构导航）、diary（主题摘要增强）。

3. **评估排名**：把返回的 document 列表与 ground-truth 的正确 session ID 对比。计算 Recall@5、Recall@10、NDCG@10。

4. **记录详情**：每个问题的检索结果——包括返回的每一个 document、对应的距离分数、是否命中——全部写入 JSONL 文件。这意味着你不仅可以复现总分，还可以审查每一个单独的问题。

关键的设计决策是使用 `chromadb.EphemeralClient()` 的全局单例。早期版本使用 `PersistentClient` 加临时目录，到第 388 个问题左右会因为 SQLite 句柄积累而挂起。切换到内存模式解决了这个问题，同时带来了约 2 倍的速度提升——在 Apple Silicon 上完成全部 500 个问题大约需要 5 分钟。

### locomo_bench.py 的核心流程

LoCoMo 的结构略有不同，因为它的数据组织方式是"10 个独立对话，每个对话有自己的 QA 对"：

对于 10 个对话中的每一个：

1. **加载对话**：把该对话的所有 session（19-32 个）加载到 ChromaDB。
2. **逐个提问**：用该对话的 QA 对逐一查询。
3. **评估**：检查检索到的 session 是否包含 ground-truth 的证据对话。
4. **按类型统计**：五种题型分别计算 recall。

一个值得注意的技术细节：LoCoMo 的 ground-truth 标注在 dialog 级别（单轮对话），但 MemPalace 的索引粒度是 session 级别（一个 session 包含多轮对话）。runner 通过 `--granularity` 参数控制评估粒度。session 粒度的成绩（60.3%）高于 dialog 粒度（48.0%），因为 session 是一个更粗的容器——命中包含证据的 session 比命中包含证据的具体那一轮对话更容易。

### convomem_bench.py 的核心流程

ConvoMem 的特殊之处在于它的数据分布在 HuggingFace 上的多个文件中，runner 需要先下载再测试：

1. **发现文件**：通过 HuggingFace API 列出每个类别的可用数据文件。
2. **下载并缓存**：首次运行时从 HuggingFace 下载，缓存到本地避免重复下载。
3. **抽样**：通过 `--limit` 参数控制每个类别采样多少个测试项。默认 50。
4. **测试**：对每个测试项，加载对话历史到 ChromaDB，用问题查询，检查检索结果是否包含证据消息。

### 快速复现

```bash
# 安装
git clone https://github.com/aya-thekeeper/mempal.git
cd mempal && pip install chromadb pyyaml

# LongMemEval（约 5 分钟）
mkdir -p /tmp/longmemeval-data
curl -fsSL -o /tmp/longmemeval-data/longmemeval_s_cleaned.json \
  https://huggingface.co/datasets/xiaowu0162/longmemeval-cleaned/resolve/main/longmemeval_s_cleaned.json
python benchmarks/longmemeval_bench.py /tmp/longmemeval-data/longmemeval_s_cleaned.json

# LoCoMo（约 2 分钟）
git clone https://github.com/snap-research/locomo.git /tmp/locomo
python benchmarks/locomo_bench.py /tmp/locomo/data/locomo10.json --granularity session

# ConvoMem（约 2 分钟）
python benchmarks/convomem_bench.py --category all --limit 50
```

不需要 API key。不需要 GPU。不需要网络连接（数据下载完成后）。不需要任何配置文件。

### 结果的可审计性

每次运行都会生成一个 JSONL 或 JSON 结果文件，包含：

- 每个问题的完整文本
- 每个检索到的 document 及其距离分数
- 每个问题是否命中的判定
- 按题型的分类统计

这意味着当有人质疑某个分数时，你可以打开结果文件，找到那个具体的问题，看到检索返回的每一个 document，逐一验证评估逻辑。这不是一个黑盒——每一层都是透明的。

---

## 指标的含义

Recall@K 和 NDCG@K 是信息检索领域的标准指标，但对非专业读者来说，它们的直觉含义需要解释。

**Recall@K**：在返回的前 K 个结果中，有多少比例的正确答案被找到了？R@5 = 96.6% 意味着：对于 500 个问题中的 483 个，正确的 session 出现在了前 5 个检索结果中。剩下 17 个问题，正确的 session 不在前 5 名。

**NDCG@K**（Normalized Discounted Cumulative Gain）：不仅考虑正确答案是否在 top-K 中，还考虑它的排名位置。正确答案排在第 1 位比排在第 5 位得分更高。NDCG@10 = 0.889 意味着：正确答案不仅经常出现在前 10 名，而且倾向于出现在靠前的位置。

在实际使用中，R@5 是更重要的指标。因为当你的 AI 助手调用 `mempalace_search` 时，它通常只看前 5 个结果。如果正确答案在第 6 名，AI 看不到它——等同于没找到。

---

## 方法论的承诺

本章描述的三个 benchmark、runner 代码、数据源、评估指标，构成了一个完整的可复现评估框架。任何人——无论是想验证 MemPalace 的声明、想在自己的系统上运行同样的测试、还是想理解这些分数到底意味着什么——都可以从这里出发。

但分数本身只是故事的一半。下一章我们会把 MemPalace 的分数放在竞争格局中，和 Supermemory、Mastra、Mem0、Zep 等系统做正面对比。我们会展示赢在哪里、输在哪里，以及为什么有些"输"比表面看起来更有意义。
