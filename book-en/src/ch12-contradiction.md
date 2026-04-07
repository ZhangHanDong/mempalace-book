# Chapter 12: Contradiction Detection

> **Positioning**: The middle chapter of Part 4, "The Time Dimension." This chapter analyzes how MemPalace uses the temporal knowledge graph to detect attribution conflicts, stale information, and inconsistent dates -- starting from three specific examples in the README, inferring implementation mechanisms, and discussing the engineering tradeoffs between false positives and false negatives.

---

## AI Confidently Gets Things Wrong

Large language models have a well-known characteristic: they make mistakes without hesitation. They do not say "I'm not sure" or "let me check" -- they deliver incorrect answers with exactly the same tone and fluency as correct ones.

When AI serves as your memory system, this characteristic becomes particularly dangerous. If your AI assistant remembers "Soren is responsible for the auth migration" when Maya is actually the responsible party, then every subsequent decision based on this incorrect information is built on sand. Worse yet, you may never discover the error -- because you trust your memory system, just as you trust your own memory.

MemPalace's contradiction detection mechanism is designed precisely to address this problem. It does not try to prevent the AI from making mistakes (currently impossible), but instead sounds the alarm when the AI is about to make one.

---

## Three Concrete Contradiction Scenarios

MemPalace's README demonstrates three different types of contradiction detection (`README.md:262-273`):

```
Input:  "Soren finished the auth migration"
Output: AUTH-MIGRATION: attribution conflict -- Maya was assigned, not Soren

Input:  "Kai has been here 2 years"
Output: KAI: wrong_tenure -- records show 3 years (started 2023-04)

Input:  "The sprint ends Friday"
Output: SPRINT: stale_date -- current sprint ends Thursday (updated 2 days ago)
```

These three examples may seem simple, but they actually represent three completely different detection logics. Let us analyze each one.

### Scenario 1: Attribution Conflict

```
Input:  "Soren finished the auth migration"
Output: AUTH-MIGRATION: attribution conflict -- Maya was assigned, not Soren
```

This statement contains an implicit attribution assertion: the auth migration is Soren's work. To detect this contradiction, the system needs to:

1. Identify the entities involved in the statement: `Soren` (person) and `auth-migration` (project/task).
2. Identify the relationship type in the statement: some kind of "completed" or "responsible for" relationship.
3. Query the knowledge graph: who was auth-migration actually assigned to?

From the `knowledge_graph.py` analyzed in Chapter 11, this query corresponds to querying `auth-migration` as an entity in the incoming direction:

```python
kg.query_entity("auth-migration", direction="incoming")
```

Or directly querying a specific relationship type:

```python
kg.query_relationship("assigned_to")
```

The triple existing in the knowledge graph might be:

```
Maya -> assigned_to -> auth-migration (valid_from: 2026-01-15, valid_to: NULL)
```

When the new statement attempts to establish the relationship `Soren -> completed -> auth-migration`, the system discovers that the `assigned_to` relationship for `auth-migration` points to Maya, not Soren. Two different people being associated with the same task's responsibility -- this is an attribution conflict.

The key insight is: this detection does not require understanding the full semantics of natural language. It only needs to do three things -- extract entities, identify relationship types, and cross-reference against known facts. The knowledge graph provides the baseline for comparison, and temporal information ensures the comparison uses currently valid facts.

### Scenario 2: Tenure Error

```
Input:  "Kai has been here 2 years"
Output: KAI: wrong_tenure -- records show 3 years (started 2023-04)
```

This contradiction involves dynamic calculation. The "2 years" in the statement is not a static value that can be directly stored in the knowledge graph -- it needs to be calculated from Kai's start date and the current date.

The triple stored in the knowledge graph might be:

```
Kai -> started_at -> Company (valid_from: 2023-04, valid_to: NULL)
```

The detection logic works roughly as follows:

1. Extract entity `Kai` and the numerical claim `2 years` from the statement.
2. Query `Kai`'s `started_at` or similar employment relationship.
3. Calculate the actual tenure from `valid_from` (2023-04) to the current date.
4. If the calculated result (~3 years) does not match the stated value (2 years), trigger an alert.

The core capability of this detection comes from the temporal KG's `valid_from` field. If the knowledge graph only stored "Kai works at the company" as a static fact, it could not determine whether a tenure claim is correct. It is precisely because it stores "Kai started working at the company in April 2023" that the system has the foundation data for calculating tenure.

Note the `(started 2023-04)` in the output -- the system not only identifies the contradiction but also provides the basis for its judgment. This allows the user to decide: is the date in the knowledge graph wrong, or is the number in the statement incorrect. Contradiction detection does not make the final ruling; it merely presents the inconsistency to the human.

### Scenario 3: Stale Date

```
Input:  "The sprint ends Friday"
Output: SPRINT: stale_date -- current sprint ends Thursday (updated 2 days ago)
```

This scenario detects a more subtle type of contradiction: the statement may have been correct a few days ago but has since become stale.

The knowledge graph might contain two triples about the sprint end date:

```
Sprint -> ends_on -> Friday   (valid_from: 2026-03-20, valid_to: 2026-03-23)
Sprint -> ends_on -> Thursday (valid_from: 2026-03-23, valid_to: NULL)
```

The first triple has been marked as ended by `invalidate()` (because the sprint end date was updated two days ago), and the second triple is currently valid.

When the statement references "Friday," the system queries the currently valid sprint end date using the `as_of` parameter and discovers the current record shows Thursday, not Friday. The `(updated 2 days ago)` additional information comes from the first triple's `valid_to` date -- it tells you when the information became stale.

This is the value of the `invalidate()` method (`knowledge_graph.py:169-182`) in contradiction detection. It is not deleting incorrect information but recording the lifecycle of information. Old facts become history, new facts take their place, and the system can precisely tell you when this transition occurred.

---

## Implementation Mechanism Inference

From the three scenarios, a generalized contradiction detection process can be extracted:

```
Input statement
    |
    v
Entity extraction -- identify people, projects, times, and values from the statement
    |
    v
Relationship mapping -- infer the relationship type implied in the statement
    |
    v
Knowledge graph query -- use query_entity() or query_relationship() to retrieve known facts
    |
    v
Cross-comparison -- compare assertions in the statement against known facts
    |
    v
Contradiction report -- if inconsistency found, generate a report with contradiction type and evidence
```

The first step (entity extraction) and second step (relationship mapping) are natural language processing tasks. From MemPalace's overall architecture, this work is most likely performed by an LLM -- either the LLM the user is conversing with (via MCP tool calls) or a lightweight language processing module integrated within MemPalace.

The third step (knowledge graph query) directly uses the `KnowledgeGraph` class's query methods. From Chapter 11's analysis, `query_entity()` supports `as_of` time filtering and direction control, and `query_relationship()` supports query by relationship type -- these two interfaces are sufficient to cover the query needs of all three contradiction types above.

The fourth step (cross-comparison) is the core judgment logic. It needs to execute different comparison strategies based on the contradiction type:

- **Attribution conflict**: Check whether the same task/project has been assigned to different people. The comparison condition is the existence of multiple `assigned_to`-type relationships for the same object entity with different subjects.
- **Numerical inconsistency**: Dynamically calculate values (tenure, age, etc.) from timestamps and compare against the stated values.
- **Stale date**: Query currently valid date-type facts and compare against the dates referenced in the statement.

### The Role of Confidence

Every triple in the knowledge graph has a `confidence` field (`knowledge_graph.py:72`), defaulting to 1.0. This field plays an important role in contradiction detection.

When two facts contradict each other, confidence provides a priority judgment: if the knowledge graph's fact has a confidence of 1.0 (fully certain) and the new statement comes from casual conversation (likely lower confidence), the system is inclined to trust the existing fact. Conversely, if the existing fact already has low confidence, the contradiction may indicate that the new statement provides more accurate information.

Confidence is not the decision criterion for contradiction detection -- the system still reports the contradiction -- but it provides context for the contradiction report. "The knowledge graph has a record with confidence 0.6 that contradicts your statement" and "The knowledge graph has a baseline fact with confidence 1.0 that contradicts your statement" represent different levels of severity.

### The Provenance Value of source_closet

When a contradiction is detected, the `source_closet` field (`knowledge_graph.py:74`) provides provenance capability. The system can not only tell you "Maya was assigned to auth migration" but also tell you which closet this information came from -- meaning it can be traced back to the original conversation record or document.

This provenance capability demonstrates the collaboration between MemPalace's palace structure and knowledge graph. The knowledge graph handles fast structured queries ("who was assigned to this task"), while the palace structure handles deep contextual retrieval ("what did the original conversation say"). The two are connected through the `source_closet` field.

---

## Contradiction Classification

From the README's three examples, a contradiction classification system can be extracted. Note the output uses different severity level markers -- attribution conflicts are marked as red (high severity), while tenure errors and stale dates are marked as yellow (moderate severity).

The logic behind this grading:

**High severity (attribution conflict)**: A person is incorrectly attributed as being responsible for something. The consequences of this error can be quite serious -- you might thank the wrong person in a meeting or assign follow-up tasks to the wrong person.

**Moderate severity (numerical inconsistency)**: Tenure, age, or other numerical claims do not match records. This type of error is usually an inadvertent approximation (remembering "2 years" when it is actually "3 years"), with relatively limited consequences, but still worth correcting.

**Moderate severity (stale date)**: A reference to time information that has since been updated. This type of error usually occurs because the speaker did not know the information had changed, not because they misremembered.

A more complete contradiction classification might include:

| Contradiction Type | Severity | Detection Method |
|----------|--------|----------|
| Attribution conflict | High | Cross-referencing different attributees for the same task |
| Numerical inconsistency | Moderate | Dynamic calculation from timestamps, then comparison |
| Stale date | Moderate | Comparing currently valid facts against the statement |
| Status contradiction | High | A concluded fact referenced as ongoing |
| Relationship contradiction | Moderate | Incompatible relationship types existing simultaneously |

---

## False Positives and False Negatives

Any detection system faces the tradeoff between false positives and false negatives. Contradiction detection is no exception.

### False Positive Scenarios

**Same name, different entities.** If the team has two people named "Jordan," one a designer and one a backend engineer. When a statement mentions "Jordan completed the UI design," the system might incorrectly trigger an attribution conflict because the other Jordan is a backend engineer.

From the `_entity_id()` implementation (`knowledge_graph.py:92-93`), entity IDs are generated through simple string normalization -- `"jordan"` is just `"jordan"`, with no disambiguation mechanism. This means same-named entities are merged into a single node, potentially causing false contradictions.

Solutions might include using full names or qualifiers during entity registration (`"Jordan Chen"` vs `"Jordan Kim"`), but this requires upstream entity extraction to be sufficiently precise.

**Semantic interpretation errors.** "Soren helped with the auth migration" and "Soren finished the auth migration" express different relationships -- "helping" does not equal "being responsible." If the system interprets "helping" as an attribution relationship, it produces a false positive.

This type of false positive depends on the precision of the relationship mapping stage. If relationship mapping is too broad (treating all person-task associations as attribution relationships), false positive rates rise; if too strict (only counting explicit "responsible for" and "completed" as attribution), false negative rates rise.

**Time granularity mismatch.** The knowledge graph's `valid_from` uses date strings (`"2026-01-15"`), while statements may use vaguer temporal expressions ("last month," "end of last year"). If the conversion between these is not accurate enough, it can cause false positives.

### False Negative Scenarios

**Incomplete knowledge graph.** If a fact was never entered into the knowledge graph, the system cannot detect contradictions related to it. For example, if the knowledge graph has no record of Maya being assigned to auth migration, then "Soren completed the auth migration" will not trigger any alert -- because the system does not know who was supposed to be responsible.

This is the most fundamental source of false negatives. Contradiction detection can only work within the scope of known facts. The knowledge graph's coverage directly determines contradiction detection's recall rate.

**Implicit contradictions.** Some contradictions are not direct factual conflicts but can only be discovered through logical inference. For example, "Kai was on vacation all last week" and "Kai reviewed 12 PRs last week" -- these two statements share no entity relationships on the surface, but they are logically contradictory (reviewing 12 PRs while on vacation is unlikely). This type of inferential contradiction exceeds the capability of simple triple comparison.

**Gradual contradictions.** Some facts do not suddenly become incorrect but gradually diverge from reality. For example, "our team has 5 people" was correct three months ago, but over those three months people joined and left, and the actual count is now 7. If no one explicitly calls `invalidate()` on the old team size information and enters new data, the knowledge graph continues to believe "5 people" is valid.

### Engineering Strategy

Facing the tradeoff between false positives and false negatives, MemPalace's design choice leans toward **preferring false positives over false negatives**. The reasoning is straightforward: a false positive only costs the user a few seconds of confirmation ("oh, this one is fine"); a false negative might allow an incorrect fact to survive in the system for months, affecting all subsequent answers and decisions.

From the output format in the README, contradiction reports come with complete judgment evidence ("Maya was assigned, not Soren"; "records show 3 years (started 2023-04)"; "current sprint ends Thursday (updated 2 days ago)"). This allows users to quickly assess whether a contradiction report is a genuine contradiction or a false positive, thereby reducing the negative impact of false positives on user experience.

---

## The Closed Loop of Contradiction Detection

Contradiction detection is not an endpoint but the starting point of a closed loop. When a contradiction is detected, there are three possible handling paths:

**Path 1: Correct the statement.** The user acknowledges the statement was wrong. "Oh right, it is indeed Maya doing the auth migration, not Soren." The knowledge graph requires no changes.

**Path 2: Update the knowledge graph.** The user confirms the statement is correct and the knowledge graph needs updating. For example, the auth migration responsibility has indeed changed from Maya to Soren. This requires calling `invalidate()` to end Maya's `assigned_to` relationship, then using `add_triple()` to create Soren's new relationship.

**Path 3: Flag for investigation.** The user is unsure which version is correct. In this case, the contradiction itself is valuable information -- it marks an area of uncertainty in the knowledge graph, reminding the user to verify next time the related topic comes up.

All three paths are better than "letting incorrect information slip through quietly." The core value of contradiction detection is not whether its accuracy rate is 90% or 99%, but that it makes the fact "AI might be making a mistake" go from implicit to explicit.

---

## Deeper Design Considerations

### Coupling Between Contradiction Detection and the Temporal KG

Of the three contradiction types, two (numerical inconsistency, stale date) directly depend on the temporal KG's capabilities. If the knowledge graph had no `valid_from` and `valid_to` fields, tenure could not be dynamically calculated from start dates, and stale dates could not be distinguished from currently valid dates.

Attribution conflict detection could theoretically be implemented on a static KG (as long as attribution relationships are stored), but in practice, the temporal KG makes detection more precise -- it can distinguish "Maya is currently responsible for auth migration" from "Maya was once responsible for auth migration (but has since handed it off)."

This means contradiction detection is not an independent functional module but a natural extension of the temporal knowledge graph. With the time dimension, contradiction detection is almost "free" -- you just need to perform time-aware comparison between new statements and existing facts.

### Scale Boundaries of Contradiction Detection

The current implementation assumes the knowledge graph's scale is manageable -- a few hundred entities, a few thousand triples. At this scale, full scans of `query_relationship()` results are entirely feasible.

But if the knowledge graph grows to millions of triples (e.g., a large organization's complete knowledge base), the per-record comparison strategy would need to evolve. Possible directions include: building dedicated indexes for contradiction detection (such as an entity-pair indexed attribution relationship table), introducing incremental detection (only checking new triples for contradictions rather than full comparisons each time), or using a rule engine to define contradiction patterns rather than hard-coding detection logic.

However, for MemPalace's target scenario -- personal or small team AI memory systems -- the current implementation is sufficient. The knowledge graph's growth rate is bounded by the user's conversation volume and fact extraction rate, making it unlikely to reach the scale requiring detection strategy optimization within a few years.

This is another engineering tradeoff: design for the current scale rather than over-engineering for an imagined future scale. SQLite handles queries on a few thousand triples in milliseconds, and contradiction detection's additional overhead is negligible. When the day comes that optimization is truly needed, it can be addressed then.

---

## Summary

Contradiction detection is one of the most practically valuable applications of MemPalace's temporal knowledge graph. It elevates the AI memory system from "remember everything" to "remember, and tell you when it remembers incorrectly."

Three contradiction types -- attribution conflict, numerical inconsistency, stale date -- each represent different detection logic, but they share the same infrastructure: a knowledge graph with time windows. `valid_from` and `valid_to` not only make historical queries possible but also make staleness detection and dynamic calculation possible.

The next chapter will examine another application of the temporal knowledge graph: timeline narration. When you need to understand the complete history of a project or a person, the `timeline()` method weaves discrete triples into a readable chronicle.
