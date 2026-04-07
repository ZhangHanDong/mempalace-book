# Preface

> "My friend Milla Jovovich and I spent months creating an AI memory system with Claude. It just posted a perfect score on the standard benchmark --- beating every product in the space, free or paid.
>
> It's called MemPalace, and it works nothing like anything else out there."
>
> --- Ben Sigman (@bensig)

In early 2026, this tweet sent a modest shockwave through the tech community. The shock was not that yet another AI memory product had appeared --- the market has never lacked those --- but rather two unusual facts: first, it achieved the first-ever perfect score on the LongMemEval benchmark (500/500, R@5 = 100%); second, the pairing of its two founders was genuinely unexpected.

Ben Sigman, a UCLA Classics degree, over twenty years of systems engineering experience, CEO of Bitcoin Libre, a tech entrepreneur who had spent years deep in decentralized lending markets, and also the author of *Bitcoin One Million*. Milla Jovovich --- yes, that Milla Jovovich, the Hollywood actress with five million Instagram followers, whose GitHub bio reads "architect of the MemPalace."

A classically trained systems engineer, a Hollywood actress, and a system they spent months building with Claude, beating every commercial product and academic system.

This fact alone warrants serious examination.

---

## Why This Book Was Written

MemPalace accumulated over two thousand GitHub stars in a short period, fully open-sourced under the MIT license. Brian Roemmele --- founder of The Zero-Human Company --- said after testing: "We have been testing MemPalace... absolutely blown away! It is a freaking masterpiece and we have deployed it to 79 employees." Wayne Sutton put it more bluntly: "Milla Jovovich launching an AI memory system with Claude was not on my 2026 list." LLMJunky summarized: "She's co-developed the highest-scoring AI memory system ever benchmarked. Totally free and OSS. What a boss."

Yet the discussion around MemPalace has largely remained on two levels: surprise at the founders' identities, and amplification of the benchmark scores. Very few have analyzed in depth why its design works, what choices it made that fundamentally differ from mainstream AI memory systems, and the engineering trade-offs behind those choices.

This book attempts to fill that gap.

**This is not a tutorial --- it is a design analysis.** You will not find "step one: install, step two: configure" instructions here --- MemPalace's README and documentation already do that well enough. This book is concerned with deeper questions: Why can ancient Greek memory techniques be effective again in the era of large language models? Why can a zero-API-call local system achieve 96.6% retrieval precision, reaching 100% with a single lightweight reranking step? Why can a compression dialect designed for AI achieve 30x compression with zero information loss? Why does abandoning "let the AI decide what's worth remembering" actually produce better results?

Behind every design decision lies a concrete engineering problem. This book's job is to make the relationship between those problems and decisions clear.

---

## What This Book Is Not

Several things need to be stated upfront.

First, this is not MemPalace's official documentation. This book is an independent, third-party technical analysis based on publicly available source code, benchmark data, and design documents. The analysis represents the author's understanding, not the project founders' intentions.

Second, this is not a survey of AI memory systems. While we will compare with other approaches where necessary to illustrate the uniqueness of design choices, the book's focus remains on MemPalace's own architectural logic.

Third, this is not a hands-on guide for building a similar system from scratch. The intended audience is technical practitioners and researchers who already have some AI engineering experience and are interested in memory system design. If you are designing your own AI memory solution, this book can help you understand an approach that has been proven effective; but it will not walk you through writing code.

---

## What MemPalace Does Differently

Before entering the main text, it is worth sketching MemPalace's core design choices in a few paragraphs so readers can build an initial mental model.

Mainstream AI memory systems follow a common paradigm: have the model extract "important information" during conversations, store it in a vector database, and retrieve via semantic similarity matching. The problem with this paradigm is that it introduces irreversible information loss at the storage stage --- the model extracts "user prefers PostgreSQL" but loses all the context from that two-hour conversation where you explained why you migrated away from MongoDB.

MemPalace's core stance is: **Store everything, then let structure make it retrievable.**

This stance gave rise to three key designs:

**The Memory Palace Structure.** Borrowing from the ancient Greek orators' memory technique --- remembering an entire speech by placing ideas in different rooms of an imaginary building --- MemPalace organizes your memories as Wings (people and projects), Halls (memory types), and Rooms (specific concepts). This spatial metaphor is not decoration; it is a real retrieval acceleration mechanism: structural organization alone produced a 34% retrieval precision improvement.

**The AAAK Compression Dialect.** This is a lossless shorthand language designed specifically for AI agents. It is not meant for humans to read --- it is meant for your AI to read, and it reads fast. 30x compression, zero information loss. Your AI loads months of context in roughly 120 tokens. Because AAAK is essentially structured text with universal grammar, it works with any model that can read text --- Claude, GPT, Gemini, Llama, Mistral --- no decoder needed, no fine-tuning, no cloud API.

**The Four-Layer Memory Stack.** From temporary working memory to long-term persistence, MemPalace simulates the memory hierarchy from cognitive science. Different layers have different lifespans, different compression strategies, and different retrieval paths. This is not a flat key-value store --- it is a time-aware knowledge graph.

These three designs are interwoven, collectively explaining the seemingly incredible benchmark numbers: LongMemEval R@5 perfect score, 96.6% with zero API calls, ConvoMem 92.9%, LoCoMo 100% (with reranking; baseline 60.3%, see Chapter 23 for the honest analysis).

---

## Recommended Reading Paths

This book is divided into nine parts and twenty-five chapters. Based on your background and interests, here are several different reading paths.

### Path One: Systems Architect

If you are an engineer currently designing AI memory systems or knowledge management systems, the recommended reading order is:

- **Part 1 (Chapters 1--3): Problem Space** --- Understand the core problem MemPalace aims to solve, and why existing approaches fall short. This is the motivation for all subsequent design decisions.
- **Part 2 (Chapters 4--7): Memory Palace Structure** --- How the spatial metaphor translates into engineering structure, and how the Wing-Hall-Room three-tier system achieves retrieval acceleration.
- **Part 4 (Chapters 11--13): Temporal Knowledge Graph** --- How MemPalace encodes time dimensions in graph structures, making "the discussion about X from last year" a computable query.
- **Part 5 (Chapters 14--15): Four-Layer Memory Stack** --- The layered strategy from working memory to long-term storage.
- **Part 8 (Chapters 22--23): Validation** --- Benchmark design and results analysis.

This path covers the system's skeleton, giving you an understanding of the overall architecture, after which you can trace back to other chapters for details as needed.

### Path Two: AI Application Developer

If you are more interested in how to integrate similar memory capabilities into your own AI applications, start with these chapters:

- **Part 1 (Chapters 1--3): Problem Space** --- Start with the problem, as before.
- **Part 3 (Chapters 8--10): AAAK Compression Language** --- Understand how this AI-oriented lossless compression dialect was designed and why it works on any model. This may be MemPalace's most original contribution.
- **Part 6 (Chapters 16--18): Data Ingestion Pipeline** --- The complete flow from raw conversation data to structured memory.
- **Part 7 (Chapters 19--21): Interface Design** --- MCP toolset, command-line interface, and local model integration.
- **Part 9 (Chapters 24--25): Design Philosophy and the Future** --- Broader implications of MemPalace's design philosophy for AI application development.

This path emphasizes transferable design patterns and integration approaches.

### Path Three: Quick Overview

If your time is limited and you just want to understand why MemPalace works, you can read only Chapter 1 (problem definition), Chapter 4 (palace structure overview), Chapter 8 (AAAK core principles), and Chapter 22 (benchmark results). Four chapters, roughly two hours, sufficient for a complete high-level understanding.

Of course, you can also read straight through from beginning to end. The book's structure is arranged in logical progression: from problem to solution, from solution to implementation, from implementation to validation, from validation to reflection.

---

## A Footnote on Background

Ben Sigman's Classics degree is not an irrelevant biographical detail. MemPalace's core metaphor --- the memory palace, also known as the Method of Loci --- is a central technique of the ancient Greek and Roman rhetorical tradition. Cicero described this method in detail in *De Oratore*: an orator walks through an imaginary building, recalling one argument at each location passed. Over two thousand years later, the same spatial metaphor has proven equally effective for large language model memory retrieval.

This is not a coincidence. Spatial structure works in both human memory and AI memory because it provides an organizational dimension orthogonal to the content itself. When you no longer need to remember "where the information is" (because structure already tells you), you can devote all cognitive resources to understanding the information itself. This principle does not depend on whether the memory substrate is a brain or a language model.

A systems engineer who studied Classics recognized this. A Hollywood actress --- who is also a serious technical contributor --- helped turn that insight into working code. Then Claude helped them build it.

This combination looks impossible, but the results speak for themselves: a perfect score.

---

## Acknowledgments and Disclosures

This book is based on analysis of MemPalace's public source code (github.com/milla-jovovich/mempalace, MIT license), official documentation, and public benchmark data. All cited tweets and comments come from publicly posted social media content.

Thanks to Ben Sigman and Milla Jovovich for open-sourcing this system, making this kind of deep analysis possible. Thanks to the contributors in the MemPalace community who have shared their usage experiences and test data.

Let us begin.
