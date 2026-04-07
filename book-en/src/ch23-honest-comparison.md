# Chapter 23: An Honest Comparison with Competitors

> **Positioning**: This chapter places MemPalace within the competitive landscape, comparing system by system, dimension by dimension. Where it wins, the results are presented factually. Where it loses, the reasons are analyzed with equal honesty. No marketing language, no belittling of competitors, no hiding of weaknesses.

---

## The Report Card First

Below is a direct comparison of LongMemEval R@5, with all data sourced from each system's public reports or reproducible benchmark runs:

| System | LongMemEval R@5 | API Dependency | Cost |
|--------|----------------|----------------|------|
| MemPalace (hybrid v4 + rerank) | 100% | Optional (Haiku) | Free + ~$0.001/query |
| Supermemory ASMR | ~99% | Yes | Undisclosed |
| MemPalace (raw) | 96.6% | None | Free |
| Mastra | 94.87% | Yes (GPT-5-mini) | API cost |
| Mem0 | ~85% | Yes | $19-249/month |
| Zep | ~85% | Yes | From $25/month |

This table is real. But if you look only at this table and conclude "MemPalace crushes everything," you're missing a lot of important context.

---

## Comparison Across Four Dimensions

A one-dimensional score ranking is dangerous. It hides fundamental architectural differences between systems, forcing products with different design philosophies onto the same ruler. A more honest comparison requires at least four dimensions.

### Dimension One: Accuracy

LongMemEval is the most standard comparison battlefield, and the table above already shows the results. But looking only at LongMemEval is far from enough.

**ConvoMem (75K+ QA pairs) comparison:**

| System | ConvoMem Score | Notes |
|--------|---------------|-------|
| MemPalace | 92.9% | Verbatim storage + semantic search |
| Gemini (long context) | 70-82% | Puts entire history into context window |
| Block extraction | 57-71% | LLM-processed block extraction |
| Mem0 (RAG) | 30-45% | LLM-extracted memories |

MemPalace exceeds Mem0 by more than double on ConvoMem. This isn't a marginal advantage -- it's two-fold. The reason deserves deep analysis: Mem0 uses an LLM to decide "what's worth remembering," then saves only the extracted facts. When the LLM extracts the wrong thing or misses a critical detail, that portion of memory is permanently lost. MemPalace's verbatim storage does no filtering -- it doesn't judge what's important and what isn't -- so the "incorrect extraction" failure mode doesn't exist.

But now let's look at where MemPalace performs poorly.

**LoCoMo (1,986 multi-hop QA pairs): an honest analysis of 60.3%.**

MemPalace's baseline score on LoCoMo is 60.3% R@10 (session granularity, no rerank). This score isn't good. It means that in four out of ten multi-hop reasoning questions, MemPalace couldn't even rank the correct session in the top ten.

Why?

LoCoMo tests a capability that MemPalace's fundamental architecture isn't built for: cross-session information chaining. Consider a typical LoCoMo question: "What field did Caroline find work in?" The answer requires connecting session 5 (she mentioned interest in marine biology) and session 12 (she said she received a research position offer). But MemPalace's semantic search scores each session independently -- it doesn't know sessions 5 and 12 have a causal relationship. The key words "field" and "work" in the question have weak semantic associations with two different sessions, but not enough to rank either into the top-10.

Breaking down performance by category more specifically:

| Category | R@10 (Baseline) | Notes |
|----------|-----------------|-------|
| temporal | 69.2% | Best -- temporal relationships are the most direct retrieval signal |
| adversarial | 61.9% | Severe speaker confusion |
| single-hop | 59.0% | Even single-hop is only 60% -- search space isn't precise enough |
| open-domain | 58.1% | Vocabulary matching is harder for open-ended questions |
| temporal-inference | 46.0% | Worst -- temporal questions requiring reasoning are near random level |

The 46.0% on temporal-inference approaches random guessing. This is MemPalace's most honest weakness: when answers require reasoning across multiple time points, pure vector retrieval essentially doesn't work.

However, it should be noted that competitor comparison data for LoCoMo is limited. Mem0, Zep, and Supermemory have not publicly reported LoCoMo scores. The known reference point is the Memori system's 81.95% (R@10), and MemPalace's hybrid v5 mode (88.9% R@10) exceeds it. But the 60.3% baseline is indeed not competitive.

There's also a structural issue that needs transparent disclosure: each LoCoMo conversation has only 19-32 sessions, and when using top-k=50 for retrieval, the candidate pool already includes all sessions -- at this point, Sonnet rerank is essentially doing reading comprehension, not retrieval. Therefore, the 100% score obtained with top-k=50 + Sonnet rerank has structural guarantees and should not be conflated with honest retrieval scores at top-k=10. The honest LoCoMo score is the result at top-10.

### Dimension Two: Cost

This is one of MemPalace's core advantages and also the easiest dimension to quantify.

| System | Monthly Cost | Annual Cost | Cost Composition |
|--------|-------------|-------------|-----------------|
| MemPalace (raw) | $0 | $0 | No API calls |
| MemPalace (hybrid + rerank) | ~$0.30 | ~$3.60 | ~1000 queries x $0.001/query |
| Mastra | Variable | Variable | GPT-5-mini API cost |
| Mem0 | $19-249 | $228-2,988 | Subscription |
| Zep | $25+ | $300+ | Subscription |
| Letta (MemGPT) | $20-200 | $240-2,400 | Subscription |

MemPalace's raw mode cost is zero. Literally zero. No API calls, no cloud services, no subscription fees. ChromaDB runs locally, the embedding model (all-MiniLM-L6-v2) ships with ChromaDB, requires no separate download and no GPU.

Even with the optional Haiku rerank, each query costs approximately $0.001 -- one dollar per thousand queries. Assuming an active user makes 10 memory searches per day, a month of 300 queries costs $0.30.

This cost differential isn't at the percentage level. Mem0's entry price ($19/month) is infinitely more than MemPalace's raw mode cost -- because the denominator is zero. Even compared to MemPalace's hybrid mode, Mem0's minimum annual cost ($228) is still 63 times that of MemPalace.

But to be fair, Mem0 and Zep's pricing includes things MemPalace doesn't provide: hosted infrastructure, management interfaces, team collaboration features, and SLA guarantees. For enterprise users, $25/month Zep may actually be cheaper than "free but self-managed" MemPalace -- because operational time has cost too.

### Dimension Three: Privacy

| System | Data Location | API Communication | Privacy Model |
|--------|--------------|-------------------|--------------|
| MemPalace (raw) | Fully local | None | Data never leaves your machine |
| MemPalace (hybrid) | Primarily local | Only session fragments sent during rerank | Optional minimal data egress |
| Mem0 | Cloud | Full API | Vendor holds data |
| Zep | Cloud | Full API | SOC 2, HIPAA compliant |
| Supermemory | Cloud | Full API | Vendor holds data |
| Mastra | Depends on deployment | GPT API | OpenAI holds query data |

MemPalace's raw mode is the only mainstream AI memory system on the market that truly achieves "zero data egress." Not "we encrypt the data," not "we're SOC 2 compliant," but physically no network requests go out. ChromaDB runs locally, embedding computation is local, search is local. Your conversation records -- containing technical decisions, internal discussions, code snippets, even personal preferences -- all remain on your disk.

The hybrid mode introduces a privacy trade-off: when LLM rerank is enabled, the first 500 characters of top-K candidate sessions are sent to Anthropic's API for reranking. This means a small amount of conversation content leaves your machine per query. But this is optional and controllable: you can choose not to use rerank and accept 96.6% accuracy, or use rerank to pursue higher accuracy.

Zep deserves special mention: it's the most serious commercial product in this space when it comes to privacy compliance. SOC 2 certification and HIPAA compliance mean it has undergone third-party auditing with legally binding data processing constraints. For users in regulated industries such as healthcare and finance, Zep's compliance may be more practical than MemPalace's "fully local" -- because "fully local" means compliance responsibility falls on the user.

### Dimension Four: API Dependency

| System | Available without API | APIs Required | Offline Operation |
|--------|----------------------|---------------|-------------------|
| MemPalace (raw) | Fully available | None | Fully offline |
| MemPalace (hybrid) | 96.6% available, 100% requires API | Anthropic (optional) | Partially offline |
| Mastra | Unavailable | OpenAI (GPT-5-mini) | Not supported |
| Mem0 | Unavailable | Own API + LLM API | Not supported |
| Zep | Unavailable | Own API + Graph DB | Not supported |
| Supermemory | Unavailable | Own LLM API | Not supported |

The comparison on this dimension is very clear: MemPalace is the only system that delivers competitive scores without any API key at all. 96.6% R@5 -- zero API calls -- already exceeds Mastra (94.87%, requires GPT-5-mini), Mem0 (~85%, requires paid subscription), and Zep (~85%, requires paid subscription).

This isn't a trivial property. API dependency means:

- **Availability risk**: when the API provider goes down, your memory system doesn't work at all. Between 2024-2025, major LLM APIs accumulated enough downtime to make this a real concern.
- **Uncontrollable costs**: API pricing is determined unilaterally by the provider. Your memory system's operating cost depends on a variable you can't control.
- **Geographic restrictions**: some regions can't access certain API providers. A memory system dependent on the OpenAI API is unusable in certain network environments.
- **Data sovereignty**: API calls mean data leaves the country. For compliance requirements of certain organizations and regions, this is a hard constraint.

---

## Competitor-by-Competitor Analysis

### Supermemory ASMR (~99% R@5)

Supermemory is the closest competitor to MemPalace. Its ASMR (Agentic Search with Memory Retrieval) architecture reports approximately 99% on LongMemEval -- but this is the experimental version's number; its production version is around 85%.

**What Supermemory gets right:** ASMR uses an LLM to run multiple search rounds -- when first-round retrieval results aren't satisfactory, the LLM reformulates the query and searches again. This agentic approach is particularly effective on semantically ambiguous queries: when the first search misses, the LLM can understand why it failed and adjust strategy.

**MemPalace's comparative advantage:** No API dependency. Each Supermemory search may trigger multiple LLM calls, with higher cost and latency. MemPalace's raw mode has zero cost and sub-second latency -- a notable gap in high-frequency search scenarios.

**Fair judgment:** If you don't care about cost and latency, Supermemory's agentic approach may be more flexible than MemPalace on certain complex queries. But if you care about privacy and offline capability, Supermemory isn't an option.

### Mastra (94.87% R@5)

Mastra uses GPT-5-mini as an "observer" -- the LLM extracts observations in real-time as conversations happen, then stores these observations rather than the raw conversations.

**What Mastra gets right:** The LLM at the extraction stage can understand conversation structure and make implicit information explicit. If the user says "that Postgres issue last time gave me a headache all day," Mastra's LLM can extract the explicit fact "user encountered difficulty with Postgres."

**Mastra's problem:** Once extraction is complete, the original conversation is discarded. If GPT-5-mini misses a detail during extraction -- say it interprets "headache all day" as an emotional expression rather than recording it as time investment -- that information is permanently lost. MemPalace preserves original text, so this failure mode doesn't exist.

**What the score gap means:** MemPalace raw (96.6%) exceeds Mastra (94.87%) by 1.7 percentage points. This gap is statistically significant -- on 500 questions it means a 9-question difference -- but it's not overwhelming. Considering that Mastra requires API costs while MemPalace doesn't, this 1.7pp advantage carries more weight.

### Mem0 (~85% R@5)

Mem0 is one of the best-known products in this space -- brand recognition far exceeds MemPalace. It uses LLM extraction of "core memories" -- distilling conversations into brief factual snippets.

**What Mem0 gets right:** Its user experience is excellent. Integration is simple, the management interface is intuitive, and memory visualization is better than any competitor. For teams that don't want to self-manage, Mem0's hosted service eliminates all infrastructure concerns.

**Mem0's fundamental problem:** On the ConvoMem benchmark, Mem0 scored only 30-45% -- less than half of MemPalace's 92.9%. The reason is systemic, not accidental: the LLM extraction approach inevitably loses information. When the LLM compresses a 45-minute architecture discussion into "user prefers Postgres," it loses why Postgres was preferred, under what scenarios, what alternatives were compared, and what trade-offs were weighed. When subsequent questions involve this discarded context, the system can't find the answer.

**Fair acknowledgment:** Mem0's $19-249/month pricing includes commercial support, SLAs, and team collaboration features that MemPalace doesn't have. For an enterprise team that needs "out-of-the-box with someone responsible," Mem0's total cost of ownership may be lower than MemPalace's -- because MemPalace's "free" doesn't include operational labor costs.

### Zep (~85% R@5)

Zep uses a graph database (similar to Neo4j) to store entity relationships. Its Graphiti system builds a time-aware knowledge graph -- relationships between entities have effective and expiration dates.

**What Zep gets right:** The knowledge graph approach has a natural advantage on entity relationship queries. "What project is Kai working on now?" -- a graph database can directly traverse edges to answer this without searching through document collections. The time-validity design is also elegant -- when facts change, old relationships are marked as expired rather than deleted.

**MemPalace's comparison:** MemPalace's knowledge graph (knowledge_graph.py) provides similar capabilities -- time validity, entity queries, timeline -- but uses SQLite underneath instead of Neo4j. This means zero additional dependencies and zero operational cost, but also means large-scale graph traversal may be slower than a specialized graph database.

**Fair judgment:** The ~85% score on LongMemEval may not fully represent Zep's capabilities. Zep's design goals go beyond retrieval -- its graph capabilities, entity relationship management, and enterprise compliance (SOC 2, HIPAA) are things MemPalace doesn't formally offer. If your need is "build a compliant enterprise-grade memory system," Zep's ~85% retrieval score may be an acceptable trade-off.

### Hindsight (91.4% R@5)

Hindsight is a newer system, validated by Virginia Tech, using Gemini-3 and time-aware vector retrieval.

**What Hindsight gets right:** Its time-awareness approach is similar to the time enhancement in MemPalace's hybrid v2 -- adding temporal proximity as a signal on top of vector similarity. This direction is correct because many memory queries are fundamentally time-anchored.

**Score positioning:** 91.4% falls between Mem0/Zep (~85%) and Mastra (94.87%). It requires an LLM API (Gemini-3) but hasn't yet reached the level of API-free MemPalace raw (96.6%).

---

## Where MemPalace Wins

From the four-dimensional comparison, MemPalace's competitive advantages can be clearly distilled:

**On the accuracy dimension**, MemPalace's raw mode (96.6%) without API already exceeds all API-requiring competitors except Supermemory ASMR's experimental version. The hybrid v4 + rerank score of 100% is the highest published LongMemEval score to date.

**On the cost dimension**, MemPalace is the only zero-cost option. All other systems require at least API call costs or subscription fees.

**On the privacy dimension**, MemPalace's raw mode is the only truly zero data egress solution.

**On the API dependency dimension**, MemPalace is the only system that remains competitive without any API.

These advantages share a common technical root: MemPalace chose "preserve everything, use structure to organize" instead of "use AI to extract and compress." The direct consequence of this design decision is that no LLM participates in the indexing process, therefore no API is needed, no cost is incurred, and no data leaves the machine.

---

## Where MemPalace Loses

Equally honestly, MemPalace is weaker than competitors in the following scenarios:

**Multi-hop reasoning.** The 60.3% baseline on LoCoMo shows that when answers require cross-session chaining, pure semantic retrieval isn't enough. Systems that use LLM-assisted memory extraction (Mem0, Mastra) can establish cross-session associations at the extraction stage -- "user mentioned interest in marine biology in session 5, found a related job in session 12" can be extracted as a coherent memory. MemPalace stores these two sessions separately and can only score them independently during search.

The hybrid v5 mode raised LoCoMo scores to 88.9% (R@10), primarily through keyword enhancement and person name extraction. Wings v3's speaker attribution design pushed the adversarial category from 34.0% to 92.8%. But the temporal-inference category -- requiring genuine temporal reasoning -- remains the weakest link.

**Enterprise features.** MemPalace has no management console, no team collaboration, no audit logs, no SLA. Zep and Mem0 as commercial products are far ahead on these dimensions. For enterprise customers who need "something IT can manage," MemPalace is currently not a viable option.

**Integration ecosystem.** Mem0 and Zep have rich SDKs (Python, JavaScript, Go), integrations with major frameworks, and detailed API documentation. MemPalace's integration methods are primarily MCP (Model Context Protocol) and CLI -- very convenient for developers already using Claude, but a higher barrier for users in other ecosystems.

**Noisy data handling.** In the MemBench benchmark's noisy category -- deliberately mixing distractor information into questions -- MemPalace scored only 43.4%. This exposes a structural weakness of the verbatim storage approach: when noise is indistinguishable from signal at the embedding level, retrieval quality degrades severely. Systems using LLM extraction can filter noise at the extraction stage, but MemPalace preserves everything -- including noise.

---

## The Honesty Behind 100%

MemPalace scored 100% on LongMemEval -- 500/500, full marks on all six question types. This is a fact. But this fact needs some context.

The improvement path from 96.6% to 99.4% (hybrid v1 to v3) was based on category-level failure mode analysis -- each improvement targeted a class of questions, not specific individual questions. These improvements are generalizable.

But the final 3 questions from 99.4% to 100% were fixed by examining the specific failure reasons of those three particular questions:

- One question required exact phrase matching because it contained a quoted phrase `'sexual compulsions'`
- One question required proper name boosting because it involved the specific name `Rachel`
- One question required nostalgic pattern preference extraction because it involved high school memories

These three fixes are **teaching to the test**. They may generalize to similar query patterns, or they may be effective only on these three specific questions. In rigorous academic review, this is a methodological issue that needs annotation.

The team's approach to this was: establish a 50/450 dev/held-out split. On the 450 held-out questions never used for tuning, hybrid v4 scored 98.4% R@5, 99.8% R@10. These are the honest publishable numbers.

Three numbers tell three different stories:

- **96.6%** -- the baseline capability with zero API, zero tuning, zero human intervention. The most conservative and most reliable claim.
- **98.4%** -- the honest score on the held-out set, including generalizable improvements but excluding test-set tuning.
- **100%** -- the full score on the complete test set, including three fixes targeting specific questions. Brilliant but requires annotation.

---

## What 60.3% Means

If 100% is good news that needs context, 60.3% is bad news that needs analysis.

LoCoMo's 60.3% R@10 baseline means MemPalace's performance on multi-hop reasoning tasks is just "passing." Among five categories, temporal-inference scored only 46.0% -- near random level.

But "passing" doesn't equal "failing." There are three layers of analysis here.

**First layer: this score is without API.** All systems that use LLM assistance perform better on LoCoMo because multi-hop reasoning inherently requires understanding -- not just retrieval. MemPalace's 60.3% is the result of using a pure retrieval system on a reasoning task. Under the same conditions (no LLM), MemPalace's hybrid v5 already reaches 88.9%, exceeding Memori's 81.95%.

**Second layer: optimization space has been validated.** Wings v3's speaker attribution design boosted adversarial from 34.0% to 92.8% -- proving that structural improvements can dramatically boost LoCoMo scores. The bge-large embedding model (replacing the default all-MiniLM) lifted single-hop by 10.6pp. Haiku rerank pushed bge-large's score from 92.4% further to 96.3%. The direction of these improvements is clear.

**Third layer: LoCoMo's structural limitations.** Each conversation has only 19-32 sessions, and when top-k=50, all sessions are in the candidate pool, making rerank equivalent to reading comprehension. This means LoCoMo's 100% rerank score and LongMemEval's 100% rerank score can't be judged by the same standard. The former has structural guarantees; the latter is a genuine retrieval achievement.

---

## The Fundamental Divergence in Design Philosophy

Behind all these comparisons are two fundamentally different design philosophies.

**Route A: "Let AI decide what's worth remembering."** This is the route of Mem0, Mastra, and Supermemory. The LLM reads the conversation, extracts key information, and discards the rest. The advantage is compact storage and small search space. The disadvantage is irreversible loss of original context -- once extraction goes wrong, there's no going back.

**Route B: "Preserve everything, use structure to organize."** This is MemPalace's route. No information filtering, verbatim preservation of original conversations. Palace structure (Wing, Hall, Room, Closet, Drawer) handles organization; semantic search handles retrieval. The advantage is zero information loss and zero API dependency. The disadvantage is a larger search space and harder multi-hop reasoning.

LongMemEval results show: Route B's retrieval precision is not lower than Route A's, and is in fact higher. 96.6% vs 85-95% isn't a fluke -- it reflects a fundamental truth: when you've preserved all original text, the answer is always there waiting to be found. When you let an LLM extract memories, the answer may have already been "extracted" away.

LoCoMo results show: Route B is indeed weaker than Route A's potential on reasoning tasks. Verbatim storage preserves information but doesn't establish connections between information. This is an open engineering problem -- tunnels (cross-wing connections) in the palace structure and temporal validity in the knowledge graph are attempting to address it.

Ultimately, this isn't a question of "which route is better" but "what are you optimizing for." If your primary constraints are privacy and cost, Route B is the only choice. If your primary constraints are reasoning depth and enterprise compliance, Route A's commercial products may be more suitable. MemPalace chose Route B and has walked it to the farthest known point.

---

## What Is Not Claimed

Finally, there are things MemPalace explicitly does not claim:

**Does not claim "best AI memory system."** That depends on what standard you use to define "best." On LongMemEval, yes. On LoCoMo's baseline, no. On enterprise features, far from it.

**Does not claim competitors are bad.** Mem0 does user experience better than MemPalace. Zep does compliance better than MemPalace. Supermemory's agentic search is more flexible than MemPalace in certain scenarios. Each system has made reasonable engineering choices within its own design constraints.

**Does not claim 100% is unconditional.** 100% has context. The 98.4% held-out score is the more honest number. The 96.6% API-free baseline is the most conservative claim. All three numbers are true, but they answer different questions.

**Does not claim free equals zero cost.** MemPalace's software is free, but running it requires your own machine, your own time, and your own operational ability. For enterprises with IT teams, $25/month Zep may have lower actual cost than "free but self-managed" MemPalace.

The most honest way to validate a system isn't to show only where you win, but to simultaneously show where you lose and explain why. This chapter attempts to do exactly that. The next part shifts from validation to the future -- MemPalace's roadmap, known unresolved issues, and the project's open directions.
