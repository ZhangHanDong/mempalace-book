# Chapter 17: ML-Free Entity Discovery

> **Positioning**: Finding names of people and projects in conversation text -- without spaCy, without transformers, without any trained model. Using only regular expressions, frequency statistics, and a signal scoring system. This chapter explains why MemPalace chose rules over NER, and how this rule-based system works in detail.

---

## Why Not NER

Named Entity Recognition (NER) is a classic task in natural language processing. spaCy, Stanford NER, and various transformer models on Hugging Face can all do it. Give them a piece of text and they tell you which words are person names, place names, or organization names.

For MemPalace, using NER would mean the following.

First, dependencies. spaCy itself is approximately 30MB; add a language model (`en_core_web_sm` is ~12MB, `en_core_web_lg` is ~560MB), and the installation size balloons from MemPalace's few hundred KB to tens or hundreds of MB. And that does not count PyTorch -- if using transformer models, PyTorch starts at 2GB. MemPalace's entire dependency list is just chromadb and pyyaml; introducing NER would increase dependency size by two orders of magnitude.

Second, context. NER models are trained on news, Wikipedia, and academic papers. They are excellent at recognizing entities like "Barack Obama," "Google," and "New York" that appear frequently in training data. But MemPalace processes private conversations -- your daughter is named Riley, your project is called MemPalace, your colleague is named Arjun. These names are not in any training set. NER models' recognition rate for them depends on contextual cues, and the contextual cues in chat conversations are often less rich than in news articles.

Third, precision requirements. MemPalace does not need to find all entities in arbitrary text. What it needs is to find people and projects that appear repeatedly in the user's own conversation history. This is a much more constrained problem -- the number of candidate entities is limited (a person's daily conversations typically mention no more than a few dozen names repeatedly), and there is a strong frequency signal (truly important entities will certainly appear repeatedly).

This is not to say NER is bad. In its appropriate scenarios -- processing large volumes of text from unknown sources, needing to identify arbitrary entity types, handling multilingual mixed content -- NER is an irreplaceable tool. But MemPalace's scenario happens to not be that scenario. It processes the user's own, limited, clearly patterned conversation data. Under these constraints, the rule-based approach is sufficient and brings benefits NER cannot: zero additional dependencies, millisecond-level execution, fully local, fully transparent (you can know exactly why a word was identified as a person name).

In fairness, if MemPalace needs to process Chinese conversations in the future (Chinese lacks the uppercase letter signal that is a natural proper noun indicator) or needs to identify organization names, place names, event names, and other entity types, the limitations of the rule-based approach will become apparent. At that point, introducing NER may be the right choice. But in the current scenario of English conversations plus person/project binary classification, rules suffice.

---

## Two-Pass Scanning Architecture

`entity_detector.py` uses a two-pass scanning architecture (`entity_detector.py:8-9`):

**First pass: Candidate extraction.** Find all capitalized words in the text, count frequencies, and filter out stopwords and low-frequency words.

**Second pass: Signal scoring and classification.** For each candidate word, use a set of regex patterns to detect whether it is "person-like" or "project-like," assign scores, and make the final classification.

This two-pass design has an important benefit: the first pass computation is O(n) -- just one full-text scan and word frequency count. The second pass computation is O(k * n) -- k is the number of candidate words, with one full-text regex match per candidate. Because candidates typically number only a few dozen (the first pass's frequency filter dramatically narrows the scope), the second pass's actual computation is manageable.

---

## First Pass: Candidate Extraction

The `extract_candidates()` function (`entity_detector.py:443`) is responsible for extracting candidate entities from text.

The core logic consists of two regexes:

```python
# Single-word proper nouns: starts with uppercase, 1-19 lowercase letters
raw = re.findall(r"\b([A-Z][a-z]{1,19})\b", text)

# Multi-word proper nouns: consecutive capitalized words (e.g., "Memory Palace")
multi = re.findall(r"\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)\b", text)
```

The first pattern matches individual capitalized words like "Riley," "Claude," or "Python." Length is restricted to 2-20 characters -- words that are too short (like "I") are unlikely to be names, and overly long ones are abnormal as well.

The second pattern matches consecutive capitalized word groups like "Memory Palace" or "Claude Code." This captures multi-word project names or full names.

Extracted candidates go through two layers of filtering:

1. **Stopword filtering.** The `STOPWORDS` set contains approximately 250 common English words (`entity_detector.py:92-396`), covering pronouns, prepositions, conjunctions, common verbs, technical terms (`return`, `import`, `class`), UI action words (`click`, `scroll`), and words that start with a capital letter but are almost never entities (`Monday`, `World`, `Well`). This list is so long because English has many words that can appear capitalized at the start of a sentence -- "Step one is...," "Click the button...," "Well, actually..." -- none of which are entities.

2. **Frequency filtering.** Candidates must appear at least 3 times (`entity_detector.py:463`). A truly important person or project will appear repeatedly in conversation history. A name mentioned only once is probably unimportant and more likely to be a false positive.

---

## Second Pass: Signal Scoring

For each candidate that passes the first-pass filter, the `score_entity()` function (`entity_detector.py:486`) uses a set of patterns to detect whether it resembles a person or a project.

### Person Detection Patterns

MemPalace uses four categories of signals to determine whether a word is a person name:

**Signal 1: Verb patterns.** People perform certain specific actions. `PERSON_VERB_PATTERNS` (`entity_detector.py:27-48`) defines 20 patterns:

| Pattern Type | Example | Weight |
|---------|------|------|
| Speech verbs | `{name} said`, `{name} asked`, `{name} told` | x2 |
| Emotion verbs | `{name} laughed`, `{name} smiled`, `{name} cried` | x2 |
| Cognitive verbs | `{name} thinks`, `{name} knows`, `{name} decided` | x2 |
| Volitional verbs | `{name} wants`, `{name} loves`, `{name} hates` | x2 |
| Address patterns | `hey {name}`, `thanks {name}`, `hi {name}` | x2 |

"Riley said" is essentially saying "Riley is a person." Projects do not say things; systems do not laugh. These verbs are extremely strong person signals.

**Signal 2: Pronoun proximity.** If a name has personal pronouns (`she`, `he`, `they`, `her`, `him`, etc.) nearby (within 3 lines before or after), this is a person signal. The detection logic is at `entity_detector.py:515-525`:

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

The window size is 5 lines (2 before + current + 2 after). Only one pronoun hit is counted per window (`break`), preventing multiple pronouns in one window from inflating the score. Each hit has weight x2.

**Signal 3: Dialogue markers.** `DIALOGUE_PATTERNS` (`entity_detector.py:64-69`) recognizes speaker annotation formats in conversation text:

```python
DIALOGUE_PATTERNS = [
    r"^>\s*{name}[:\s]",  # > Speaker: ...
    r"^{name}:\s",         # Speaker: ...
    r"^\[{name}\]",        # [Speaker]
    r'"{name}\s+said',     # "Riley said..."
]
```

Dialogue markers carry the highest weight: x3 per hit (`entity_detector.py:503`). Because if a name appears in a dialogue marker position -- "Riley:" or "[Riley]" -- it is almost certainly a person name.

**Signal 4: Direct address.** If the text contains "hey Riley," "thanks Riley," or "hi Riley," the weight is x4 (`entity_detector.py:528-531`). This is the highest weight among all person signals, because directly addressing someone by name is almost impossible to confuse with naming a project.

### Project Detection Patterns

`PROJECT_VERB_PATTERNS` (`entity_detector.py:72-89`) defines another set of patterns:

| Pattern Type | Example | Weight |
|---------|------|------|
| Build verbs | `building {name}`, `built {name}` | x2 |
| Release verbs | `shipping {name}`, `launched {name}`, `deployed {name}` | x2 |
| Architecture descriptors | `the {name} architecture`, `the {name} pipeline` | x2 |
| Version identifiers | `{name} v2`, `{name}-core` | x3 |
| Code references | `{name}.py`, `import {name}`, `pip install {name}` | x3 |

Version identifiers and code references carry higher weight (x3), because they are ironclad proof of project status -- people do not have `.py` suffixes, people are not `pip install`-ed.

---

## Classification Decision

The `classify_entity()` function (`entity_detector.py:562`) makes the final classification based on scoring results. The classification logic considers not just scores but also signal diversity.

Core decision tree:

1. **No signals** (total score is 0): Classified as `uncertain`, maximum confidence 0.4. These words made it to the candidate list purely on frequency, with no contextual cues.

2. **Person ratio >= 70%, with two or more different signal types, and person score >= 5**: Classified as `person`. The "two or more different signal types" here is a critical design element (`entity_detector.py:587-601`). Why is this additional condition needed?

    Consider this scenario: the text repeatedly contains "Click said..." (describing some UI framework's log output). "Click" would score highly on verb patterns -- "Click said" matches `{name} said`. But it only scores on one signal type (speech verbs). A genuine person name would typically trigger multiple signals -- "Riley said" (speech verb) plus nearby "she" (pronoun) plus "hey Riley" (direct address). Requiring two or more different signal types filters out words that appear frequently in one specific sentence pattern but are not actually person names.

3. **Person ratio >= 70%, but diversity condition not met**: Downgraded to `uncertain`, confidence 0.4 (`entity_detector.py:605-609`). The code comment explicitly states the reason: "Pronoun-only match -- downgrade to uncertain."

4. **Person ratio <= 30%**: Classified as `project`.

5. **All other cases**: Classified as `uncertain`, marked "mixed signals -- needs review."

---

## The Complete Detection Flow

The `detect_entities()` function (`entity_detector.py:632`) chains all the above steps together:

1. Collect file contents. Each file reads only the first 5000 bytes (`entity_detector.py:652`), with a maximum of 10 files. This is not laziness -- entity detection does not need to read entire files. If a name has not appeared in the first 5KB, it is probably not a core entity.

2. File selection is deliberate. The `scan_for_detection()` function (`entity_detector.py:813`) prioritizes prose files (`.txt`, `.md`, `.rst`, `.csv`), falling back to code files only when fewer than 3 prose files are available. The reason is that code files contain too many capitalized words -- class names, function names, constants -- which would produce numerous false positives. The code comment states this clearly (`entity_detector.py:398-399`): "Code files have too many capitalized names (classes, functions) that aren't entities."

3. Merge text from all files, call `extract_candidates()` to extract candidates.

4. Call `score_entity()` and `classify_entity()` for each candidate.

5. Group by type, sort by confidence, take the top N (maximum 15 people, 10 projects, 8 uncertain).

---

## Entity Registry: Persistence and Disambiguation

Detected entities need persistent storage and must handle some tricky disambiguation problems. This is the job of `entity_registry.py`.

The `EntityRegistry` class (`entity_registry.py:268`) maintains a JSON file (defaulting to `~/.mempalace/entity_registry.json`), storing three categories of information:

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

Entity sources (`source`) have three priority levels:

1. **onboarding**: Explicitly declared by the user during initialization. Confidence 1.0, unchallengeable.
2. **learned**: Inferred by the system from session history. Confidence depends on the detection algorithm's output.
3. **wiki**: Confirmed via Wikipedia API query. Confidence depends on Wikipedia's description content.

### Ambiguous Word Handling

This is the most interesting part of the registry. English has many words that are both common vocabulary and given names -- Ever, Grace, Will, May, Max, Rose, Ivy, Chase, Hunter, Lane...

The `COMMON_ENGLISH_WORDS` set (`entity_registry.py:31-89`) lists approximately 50 such words. When these words appear in the registry, the system adds them to the `ambiguous_flags` list.

Subsequently, each time these words are queried, the `_disambiguate()` method (`entity_registry.py:463`) checks context to determine whether the usage is a person name or a common word:

**Person name context patterns** (`entity_registry.py:92-113`):

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

**Common word context patterns** (`entity_registry.py:116-127`):

```python
CONCEPT_CONTEXT_PATTERNS = [
    r"\bhave\s+you\s+{name}\b",  # "have you ever"
    r"\bif\s+you\s+{name}\b",    # "if you ever"
    r"\b{name}\s+since\b",       # "ever since"
    r"\b{name}\s+again\b",       # "ever again"
    r"\bnot\s+{name}\b",         # "not ever"
]
```

The disambiguation logic is straightforward: count how many times each group of patterns matches. If person name patterns score higher, classify as a person name; if common word patterns score higher, classify as a concept. If tied, return `None` -- letting the caller fall back to default behavior (words already registered as person names are still treated as names on a tie, since the user has already declared them).

This disambiguation mechanism means the system can correctly handle conversations like:

```
> Have you ever tried the new API?        <- "ever" = adverb
> I went to the park with Ever yesterday. <- "Ever" = person name
```

### Wikipedia Lookup

For unfamiliar capitalized words that are neither in the registry nor on the stopword list, the registry provides Wikipedia query functionality (`entity_registry.py:179`).

The query uses Wikipedia's REST API (free, no API key required), and determines the word's type based on the returned summary:

- If the summary contains phrases like "given name," "personal name," or "masculine name" (`entity_registry.py:135-161`), classified as a person name
- If the summary contains phrases like "city in," "municipality," or "capital of," classified as a place name
- If not found on Wikipedia (404), it is actually classified as a person name (`entity_registry.py:249-256`) -- a capitalized word not on Wikipedia is very likely someone's specific name or nickname

Query results are cached in `wiki_cache` to avoid repeated requests.

### Continuous Learning from Sessions

The registry's `learn_from_text()` method (`entity_registry.py:553`) makes entity detection not limited to the initialization stage. Each time new session text is processed, the system can call this method to run candidate extraction and signal scoring on the text. If new high-confidence person candidates are found (default threshold 0.75), they are automatically added to the registry.

This creates a gradual learning loop: initial onboarding provides seed data, and subsequent sessions may supplement newly discovered entities. But the threshold is intentionally set high (0.75), because the cost of an automatic false addition is not just one wrong entry -- it affects all subsequent query results. It is better to miss some than to misjudge.

---

## Interactive Confirmation

Detection results ultimately need human confirmation. The `confirm_entities()` function (`entity_detector.py:717`) provides a concise interactive interface:

```
==========================================================
  MemPalace -- Entity Detection
==========================================================

  Scanned your files. Here's what we found:

  PEOPLE:
     1. Riley                [*****] dialogue marker (5x), pronoun nearby (3x)
     2. Arjun                [***--] 'Arjun ...' action (4x), addressed directly (2x)

  PROJECTS:
     1. MemPalace            [****-] code file reference (3x), versioned (2x)

  UNCERTAIN (need your call):
     1. Claude               [**---] mixed signals -- needs review
```

Confidence is visualized with filled/hollow dots (`entity_detector.py:712`) -- 5 dots corresponding to the 0-1.0 confidence range. Each entity also lists the top two triggered signals, letting users understand "why the system thinks this is a person name."

Users can accept all detection results, manually correct misclassifications, or add entities the system missed. They can also pass `yes=True` to skip interaction and automatically accept all non-uncertain results.

---

## Boundaries of the Rule-Based Approach

The rule-based approach works well in MemPalace's scenario, but understanding its boundaries is equally important:

| Dimension | Rule-Based | ML/NER |
|------|---------|--------|
| Dependencies | Zero (standard library regex) | spaCy/transformers + model files |
| Execution speed | Milliseconds | Seconds (slower on first model load) |
| English name recognition | Relies on capitalization + context | Based on statistical models, more robust |
| Chinese name recognition | Essentially impossible (no capitalization signal) | Specialized models can handle it |
| Uncommon names | Identifiable as long as frequency is high enough | Depends on training data coverage |
| Explainability | Fully transparent (which rule triggered) | Black box or semi-transparent |
| Applicable scale | Personal conversations (tens to hundreds of files) | Unlimited |
| New entity type extension | Requires handwriting new rules | Fine-tune or swap models |

MemPalace's choice is not "rules are better than NER" but "in this specific scenario, rules have a better return on investment." This is an engineering judgment, not a technological belief.

---

## Summary

The entity detection module uses a two-pass scanning + signal scoring architecture to achieve automatic identification of people and projects in English conversations without introducing any ML dependencies.

Key design points:

- **Two-pass scanning**: First use frequency filtering to narrow the candidate range, then use signal scoring for precise classification
- **Four categories of person signals**: Verb patterns, pronoun proximity, dialogue markers, direct address, with weights from x2 to x4
- **Diversity requirement**: Confirmation as a person requires two or more different signal types, preventing single-pattern false positives
- **Persistent registry**: Three-tier source priority (onboarding > learned > wiki), context-based disambiguation for ambiguous words
- **Gradual learning**: Each session may discover new entities, but the threshold for automatic addition is intentionally set high

The next chapter will cover chunking -- cutting normalized text into segments suitable for vector retrieval. Conversation text and project files require entirely different chunking strategies because their minimum semantic units differ.
