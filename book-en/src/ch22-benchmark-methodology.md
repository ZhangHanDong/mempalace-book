# Chapter 22: Benchmark Methodology

> **Positioning**: This chapter explains why these three benchmarks were chosen, what capability dimension each tests, where their blind spots are, and how anyone can reproduce all results in five minutes. The most honest way to validate a system isn't to show its report card -- it's to publish the exam itself.

---

## Why Three Benchmarks Are Needed

A single benchmark can only answer a single question. A system that scores 96.6% may simply happen to excel at that particular type of question.

This isn't hypothetical. LongMemEval is the most standard test in the AI memory field -- 500 questions spanning 53 conversation sessions, covering six question types. MemPalace scored 96.6% R@5 on it. That score is headline-worthy, but it only answers one question: given a pile of conversation history, can you find which session the answer is hiding in?

It doesn't answer: can you string together clues across multiple sessions? It doesn't answer: when data scale balloons from 53 sessions to thousands of sessions, will performance collapse? It also doesn't answer: across different types of memory -- facts, preferences, changes, reasoning -- is your performance uniform?

So we chose three benchmarks. Not because three numbers look better than one, but because each benchmark tests a completely different cognitive capability. Their intersection covers three core dimensions of AI memory systems: precise retrieval, multi-hop reasoning, and large-scale generalization. Their blind spots -- what each benchmark can't test -- are equally important and are analyzed one by one in this chapter.

---

## LongMemEval: Needle in a Haystack

### What It Is

LongMemEval is a standardized memory evaluation dataset designed by academia. 500 questions, each corresponding to a "haystack" -- the history of 53 conversation sessions -- and a "needle" -- the correct answer hidden in one or more of those sessions.

The core capability tested is **information localization**: given a natural language question, can your system find the session containing the answer among 53 sessions? No need to generate the answer, no need to understand the answer -- just rank the correct session to the top.

### Six Question Types

LongMemEval's 500 questions cover six question types, each testing a different retrieval difficulty:

| Type | Count | Description | MemPalace Baseline |
|------|-------|-------------|-------------------|
| knowledge-update | 78 | Facts change over time -- current answer supersedes old answer | 99.0% |
| multi-session | 133 | Answer scattered across multiple sessions | 98.5% |
| temporal-reasoning | 133 | Contains time anchors -- "last month," "two weeks ago" | 96.2% |
| single-session-user | 70 | Answer is in something the user said | 95.7% |
| single-session-preference | 30 | User's indirectly expressed preferences | 93.3% |
| single-session-assistant | 56 | Answer is in the AI assistant's response | 92.9% |

The strongest two categories -- knowledge-update and multi-session -- are precisely MemPalace's design sweet spots. When facts are updated, the original text retains both old and new versions, and the search model naturally matches sessions containing updates. When answers are scattered across multiple sessions, verbatim storage means each session fully preserves its portion of information, and semantic search can hit each one.

The weakest two categories reveal deeper issues. single-session-preference (93.3%) is weak due to the indirectness of preference expression: the user says "I think Postgres is more reliable in concurrent scenarios," and the question asks "What database does the user prefer?" -- the vocabulary doesn't overlap at all, and the embedding model can't see the connection. single-session-assistant (92.9%) is weak due to an indexing gap: by default only user utterances are indexed, but the question asks "What did the AI recommend?" -- the answer simply isn't in the search pool.

Both weaknesses were later fixed. The preference gap was bridged by extracting preference expressions through 16 regex patterns. The assistant gap was solved through two-stage retrieval -- first using user utterances to locate the session, then searching assistant utterances within the target session. After fixes, the score progressed from 96.6% to 99.4%, then to 100%.

### Why It Was Chosen

LongMemEval is currently the most widely cited benchmark in the AI memory field. Supermemory, Mastra, Mem0, Hindsight -- all major competitors have reported scores on this benchmark. This means scores are directly comparable. If your R@5 on LongMemEval is 96.6% and Mastra's is 94.87%, these two numbers use the same ruler.

Its data is public -- hosted on HuggingFace, downloadable by anyone. Its evaluation metrics are standardized -- Recall@K and NDCG@K have clear mathematical definitions. These properties make it an ideal choice for reproducible benchmarking.

### Blind Spots

LongMemEval has three significant blind spots.

**Blind spot one: too small in scale.** 53 sessions is a very small search space. A real user's six months of AI usage would produce hundreds of conversation sessions. Ranking first among 53 sessions and ranking first among 500 sessions are completely different tasks. Can LongMemEval's 96.6% be maintained at ten times the scale? This question it cannot answer.

**Blind spot two: doesn't test reasoning.** LongMemEval only tests retrieval, not understanding. Its metric is "does the correct session appear in the top-K results," not "can the system correctly answer the question using retrieved content." A system that returns all 53 sessions could theoretically score 100% Recall@53 -- but it hasn't "understood" anything.

**Blind spot three: doesn't test cross-session reasoning.** Although multi-session type questions have answers scattered across multiple sessions, the evaluation criterion is "any one relevant session appearing in top-K" counts as correct. It doesn't test the ability to "connect information from multiple sessions to reach a conclusion."

---

## LoCoMo: Multi-Hop Reasoning

### What It Is

LoCoMo (Long Conversational Memory) comes from Snap Research and is a benchmark specifically designed for multi-hop reasoning. 10 long conversations, each containing 19-32 sessions, 400-600 turns of dialogue, producing a total of 1,986 QA pairs.

What does "multi-hop reasoning" mean? Consider this scenario:

- Session 5: Caroline mentions she's studying marine biology
- Session 12: Caroline says she found a related research position
- Session 19: Question -- "What is Caroline's career direction?"

To answer this question, the system needs to connect information from sessions 5 and 12. Retrieving either one alone isn't enough -- you need both to piece together the complete picture. This is what "multi-hop" means: the answer isn't in any single place but distributed across multiple locations, requiring reasoning across multiple information nodes.

### Five Question Types

LoCoMo's 1,986 questions fall into five types:

| Type | Description | MemPalace Baseline (R@10) |
|------|-------------|--------------------------|
| single-hop | Answer is in one session | 59.0% |
| temporal | Involves time relationships | 69.2% |
| temporal-inference | Requires cross-session temporal reasoning | 46.0% |
| open-domain | Open-ended questions | 58.1% |
| adversarial | Deliberately confusing questions -- asks about A, but B has said more | 61.9% |

The hardest category is temporal-inference -- requiring temporal causal relationships to be established across multiple sessions. The baseline is only 46.0%. This means over half of cross-temporal reasoning questions cannot be answered correctly by pure semantic retrieval.

The adversarial category reveals an interesting challenge: when two people appear in the same conversation, the embedding model can't distinguish "who said what." If the question asks about Caroline's research direction but Melanie said more in the same session, the embedding model might rank Melanie-dominated sessions higher -- even though Caroline's key information is in another session.

### Why It Was Chosen

LoCoMo fills LongMemEval's core blind spot: cross-session reasoning. LongMemEval asks "can you find the correct session," while LoCoMo asks "can you understand relationships between sessions."

It also has an important design feature: the number of sessions per conversation (19-32) is closer to real user data scales. While still not large, it's closer to the real-world scenario of "each project independently accumulating conversation history" than LongMemEval's 53 shared sessions.

### Blind Spots

**Blind spot one: too few conversations.** Only 10 conversations. This means a single conversation's anomalous performance can severely impact the total score. If one conversation's topic distribution happens to be particularly unfavorable for your system, the total score could drop 5-10 percentage points.

**Blind spot two: all conversations are fictional.** LoCoMo's conversations are artificially written simulations, not real users' AI interaction records. Fictional conversations' language patterns, topic distributions, and information density may systematically differ from real conversations.

**Blind spot three: each conversation has only two speakers.** Real-world scenarios may involve multiple people in a conversation -- team standups, group discussions, multi-party decisions. LoCoMo only has two-person conversations and doesn't test multi-party information interweaving.

---

## ConvoMem: Large-Scale Coverage

### What It Is

ConvoMem comes from Salesforce Research and is currently the largest conversational memory benchmark -- 75,336 QA pairs covering six different memory types. It doesn't test deep reasoning -- it tests breadth and type coverage.

### Six Categories

| Category | Description | MemPalace R@K |
|----------|-------------|--------------|
| assistant_facts_evidence | Facts stated by the AI assistant | 100% |
| user_evidence | Facts stated by the user | 98.0% |
| abstention_evidence | Questions the system should refuse to answer | 91.0% |
| implicit_connection_evidence | Implicit connections requiring inference | 89.3% |
| preference_evidence | User preferences and habits | 86.0% |
| changing_evidence | Facts that change over time | -- |

Scoring 100% on assistant_facts_evidence isn't surprising -- ConvoMem's testing method checks whether retrieval results contain the evidence message, and MemPalace stores every message verbatim (including assistant responses), naturally hitting on search.

preference_evidence is the weakest category (86.0%), for the same reason as LongMemEval's preference category: preferences are often expressed in indirect language, and embedding models struggle to establish connections between questions and expressions.

### Why It Was Chosen

ConvoMem fills a dimension missing from both other benchmarks: **type coverage**. LongMemEval mainly tests fact retrieval, LoCoMo mainly tests reasoning ability, and ConvoMem divides "memory" into six distinct types, testing each separately. This is important because a system that excels at fact retrieval may perform completely differently on preference memory or implicit reasoning.

Its scale (75K+ QA pairs) also provides statistical significance: when you have seventy-five thousand data points, the difference between 86% in one category and 100% in another is real, not noise.

### Blind Spots

**Blind spot one: short context per QA pair.** Many of ConvoMem's test items involve only a few messages of context, unlike LongMemEval which requires searching across 53 sessions. This means it tests "short-range matching" more than "long-range retrieval."

**Blind spot two: uneven category weights.** Some categories have far more samples than others. The weighted average of 92.9% may mask weaknesses in small categories.

**Blind spot three: doesn't test real memory retention.** ConvoMem assumes all conversation content has been correctly stored and only tests retrieval capability. It doesn't test real-world problems like "does storage quality degrade over six months of continuous use."

---

## Complementarity of the Three Benchmarks

Looking at all three benchmarks together, they form a triangulation:

| Dimension | LongMemEval | LoCoMo | ConvoMem |
|-----------|------------|--------|---------|
| Core capability | Precise retrieval | Multi-hop reasoning | Type coverage |
| Data scale | 500 questions | 1,986 QA pairs | 75,336 QA pairs |
| Session scale | 53 shared | 19-32 per conversation | Short context |
| Reasoning depth | Shallow (localization) | Deep (reasoning) | Medium (classification) |
| Competitor comparison | Extensive | Limited | Limited |
| Data source | Academic design | Human simulation | Academic design |
| Reproducibility | Public dataset | Public dataset | Public dataset |

**LongMemEval is the yardstick** -- everyone uses it, scores are directly comparable, and it's the entry ticket proving a system's basic capability.

**LoCoMo is the litmus test** -- it tests reasoning capability that LongMemEval cannot, and it's the benchmark most likely to expose system weaknesses. MemPalace's baseline on LoCoMo is only 60.3% -- this score isn't headline material, but it honestly reflects the limitations of pure semantic retrieval on multi-hop reasoning tasks.

**ConvoMem is the wide-angle lens** -- it doesn't go deep on any single capability but has the broadest coverage, ensuring the system isn't overspecialized on just one question type.

The intersection of the three covers a complete evaluation space: if a system has precise retrieval on LongMemEval, adequate reasoning capability on LoCoMo, and balanced performance across types on ConvoMem, then you have reasonable confidence it will work in real-world scenarios. If a system scores high on only one of these benchmarks, you should remain skeptical.

---

## What All Three Miss

Triangulation covers many dimensions, but some critical capabilities are entirely outside the testing scope:

**Real time spans.** All three benchmarks are static datasets. They simulate "existing conversation history," not "memory gradually accumulated over six months." In real use, a memory system faces incrementally growing data -- a few new sessions added each day, continuously expanding indexes -- does retrieval quality degrade over time? This question cannot be answered with static benchmarks.

**Write correctness.** All three benchmarks assume data has been correctly stored. They don't test the mining stage -- splitting, deduplication, classification, metadata extraction. If MemPalace's convo_miner incorrectly merges two sessions or assigns a conversation to the wrong wing, the benchmark won't catch this error.

**End-to-end answer quality.** Recall@K measures "is the correct session in the top-K," not "can the system correctly answer the question using retrieved content." A system with perfect retrieval but failed answer generation would still score full marks on all three benchmarks. Complete end-to-end evaluation requires introducing an LLM to generate answers and computing F1 scores -- this requires an API key and means you're no longer testing just the memory system but also the LLM's own capabilities.

**Multi-modal content.** All three benchmarks are pure text. Code snippets, error stacks, screenshot descriptions, and links that appear in real conversations have different retrieval characteristics from natural language, but none of this falls within any benchmark's test scope.

---

## Runner Code Structure: How to Reproduce

All benchmark runner code is in the `benchmarks/` directory, one Python file per benchmark. The design principle is: clone, install, run -- three steps to reproduce, no configuration changes needed.

### Directory Structure

```
benchmarks/
  longmemeval_bench.py          -- LongMemEval runner, all modes
  locomo_bench.py               -- LoCoMo runner
  convomem_bench.py             -- ConvoMem runner
  membench_bench.py             -- MemBench runner (extra)
  BENCHMARKS.md                 -- Complete results and methodology documentation
  HYBRID_MODE.md                -- Technical details of hybrid retrieval mode
  README.md                     -- Quick reproduction guide
  results_*.jsonl               -- Raw results from each run
```

### Core Flow of longmemeval_bench.py

This is the most important runner because LongMemEval is the primary battlefield for competitor comparison. Its core loop works like this:

For each of the 500 questions:

1. **Load the haystack**: load all 53 sessions corresponding to that question into a fresh ChromaDB collection. Uses `EphemeralClient` -- in-memory mode, no disk IO, no SQLite handle leaks. The collection is cleared and rebuilt between each question.

2. **Execute retrieval**: query the collection with the question text. Select the retrieval strategy based on the `--mode` parameter -- raw (pure semantic), hybrid (keyword-enhanced), hybrid_v2 (with time enhancement), palace (palace structure navigation), diary (topic summary enhancement).

3. **Evaluate ranking**: compare the returned document list against the ground-truth correct session IDs. Compute Recall@5, Recall@10, NDCG@10.

4. **Record details**: retrieval results for every question -- including every returned document, its distance score, and whether it was a hit -- are all written to a JSONL file. This means you can not only reproduce the total score but also audit every individual question.

The key design decision is using a global singleton of `chromadb.EphemeralClient()`. Earlier versions used `PersistentClient` with temporary directories, which would hang around question 388 due to SQLite handle accumulation. Switching to in-memory mode solved this problem while delivering roughly 2x speed improvement -- completing all 500 questions takes about 5 minutes on Apple Silicon.

### Core Flow of locomo_bench.py

LoCoMo's structure is slightly different because its data is organized as "10 independent conversations, each with its own QA pairs":

For each of the 10 conversations:

1. **Load the conversation**: load all sessions (19-32) of that conversation into ChromaDB.
2. **Ask questions one by one**: query with each QA pair of that conversation.
3. **Evaluate**: check whether retrieved sessions contain the ground-truth evidence dialogue.
4. **Statistics by type**: compute recall separately for each of the five question types.

A notable technical detail: LoCoMo's ground-truth annotations are at the dialog level (single turn), but MemPalace's indexing granularity is at the session level (a session contains multiple turns). The runner controls evaluation granularity via the `--granularity` parameter. Session granularity scores (60.3%) are higher than dialog granularity (48.0%) because a session is a coarser container -- hitting a session containing evidence is easier than hitting the specific turn containing evidence.

### Core Flow of convomem_bench.py

ConvoMem's distinguishing feature is that its data is distributed across multiple files on HuggingFace, and the runner needs to download before testing:

1. **Discover files**: list available data files for each category via the HuggingFace API.
2. **Download and cache**: download from HuggingFace on first run, cache locally to avoid repeated downloads.
3. **Sample**: control how many test items are sampled per category via the `--limit` parameter. Default is 50.
4. **Test**: for each test item, load the conversation history into ChromaDB, query with the question, and check whether retrieval results contain the evidence message.

### Quick Reproduction

```bash
# Install
git clone https://github.com/aya-thekeeper/mempal.git
cd mempal && pip install chromadb pyyaml

# LongMemEval (~5 minutes)
mkdir -p /tmp/longmemeval-data
curl -fsSL -o /tmp/longmemeval-data/longmemeval_s_cleaned.json \
  https://huggingface.co/datasets/xiaowu0162/longmemeval-cleaned/resolve/main/longmemeval_s_cleaned.json
python benchmarks/longmemeval_bench.py /tmp/longmemeval-data/longmemeval_s_cleaned.json

# LoCoMo (~2 minutes)
git clone https://github.com/snap-research/locomo.git /tmp/locomo
python benchmarks/locomo_bench.py /tmp/locomo/data/locomo10.json --granularity session

# ConvoMem (~2 minutes)
python benchmarks/convomem_bench.py --category all --limit 50
```

No API key needed. No GPU needed. No network connection needed (after data download). No configuration files needed.

### Auditability of Results

Every run generates a JSONL or JSON result file containing:

- The complete text of each question
- Every retrieved document and its distance score
- The hit/miss determination for each question
- Statistics broken down by question type

This means when someone questions a particular score, you can open the result file, find that specific question, see every document retrieval returned, and verify the evaluation logic one by one. This isn't a black box -- every layer is transparent.

---

## What the Metrics Mean

Recall@K and NDCG@K are standard metrics in the information retrieval field, but for non-specialist readers, their intuitive meanings need explanation.

**Recall@K**: among the top K results returned, what proportion of correct answers were found? R@5 = 96.6% means: for 483 of the 500 questions, the correct session appeared in the top 5 retrieval results. For the remaining 17 questions, the correct session was not in the top 5.

**NDCG@K** (Normalized Discounted Cumulative Gain): considers not just whether the correct answer is in the top-K but also its rank position. A correct answer ranked 1st scores higher than one ranked 5th. NDCG@10 = 0.889 means: correct answers not only frequently appear in the top 10 but tend to appear in earlier positions.

In practical use, R@5 is the more important metric. Because when your AI assistant calls `mempalace_search`, it typically only looks at the top 5 results. If the correct answer is in 6th place, the AI can't see it -- equivalent to not finding it.

---

## The Methodology's Promise

The three benchmarks, runner code, data sources, and evaluation metrics described in this chapter constitute a complete reproducible evaluation framework. Anyone -- whether they want to verify MemPalace's claims, run the same tests on their own system, or understand what these scores actually mean -- can start from here.

But the scores are only half the story. The next chapter places MemPalace's scores in the competitive landscape, making head-to-head comparisons with Supermemory, Mastra, Mem0, Zep, and other systems. We'll show where it wins, where it loses, and why some "losses" are more meaningful than they appear on the surface.
