# Chapter 0: Building Things with Claude

At some point in 2025, a Hollywood actress and the CEO of a Bitcoin company started writing software with an AI.

That sentence sounds like the opening of a Silicon Valley parable, but it actually happened. The project was called MemPalace, an AI memory system. A few months later, it achieved the highest score ever recorded on academic benchmarks. And the most interesting part of the entire story is not the final result, but how the thing was built.

---

## Two Unlikely Partners

Ben Sigman's career follows an uncommon trajectory. He studied Classics at UCLA --- ancient Greek, Latin, Cicero, and rhetoric. Then he spent twenty years in systems engineering. Then he founded Bitcoin Libre and became CEO.

These three chapters of his career seem entirely unrelated, yet they converge in MemPalace. Classics gave him a key concept: the Method of Loci, also known as the "memory palace" technique. This was a memory technology used by ancient Greek and Roman orators --- placing information to be remembered in different rooms of an imaginary building, then mentally walking through that building to extract information room by room when recall was needed. Cicero used this method to memorize long speeches. Medieval monks used it to memorize entire volumes of scripture. The method works because the human brain is inherently skilled at spatial memory --- our ability to remember "where things are" far exceeds our ability to remember "what things are."

Twenty years of systems engineering gave him a different kind of intuition: how to turn an elegant concept into runnable software. Not the "proof of concept" kind found in academic papers, but something that actually runs in production. He knew what complexity was acceptable, what dependencies should be avoided, and what architecture would still be maintainable three years later.

Milla Jovovich is another name unlikely to appear in this story. She is better known as Leeloo in *The Fifth Element* and Alice in the *Resident Evil* series. But her GitHub bio reads "architect of the MemPalace." The project is hosted under her GitHub account.

This is not a celebrity lending their name. From the project's commit history and version iterations, MemPalace went through multiple major refactors before stabilizing at v3.0.0. That depth of iteration does not come from lending a name. It means repeated discussion, reversal, and rebuilding.

---

## The Third Collaborator

Then there is Claude.

When Ben discussed this project on social media, his choice of words is worth noting. He said "spent months creating an AI memory system with Claude" --- not "written using Claude" (Claude as tool), not "had Claude write it" (Claude as executor), but "created with Claude" --- Claude as collaborator.

This subtle distinction in wording points to a new mode of work that, as of 2025, has not yet been well named.

Over the past two years, human-AI code collaboration has coalesced into two mainstream patterns. The first is "AI generates, human reviews" --- the human describes requirements, the AI generates code, the human inspects, modifies, and merges. This is the typical GitHub Copilot workflow. The second is "human leads, AI assists" --- the human writes the core logic, asks the AI when uncertain, and the AI offers suggestions or code snippets.

The MemPalace development process appears to belong to neither.

The codebase's structure offers some clues. The project is written in Python, containing roughly 30 modules, each with a single responsibility and clear boundaries. This structure itself tells a story: someone was making holistic architectural decisions --- which features should be independent modules, how modules should communicate, what should be exposed as public interfaces. These decisions require a global understanding of the entire system and a personal judgment about "what software should look like." This is not a result that line-by-line code generation can produce.

At the same time, the project's dependency list is remarkably short: chromadb and pyyaml, nothing else. A system involving vector search, semantic retrieval, knowledge graphs, data compression, and multi-format parsing uses only two external dependencies. This indicates that a large amount of functionality was implemented from scratch rather than assembled from third-party libraries. This inclination toward "build it yourself if you can" typically comes from an experienced engineer's deep understanding of dependency management --- every additional dependency is one more thing that might wake you at 3 AM someday.

Yet simultaneously, implementing 30 modules is a substantial workload for two people, especially within a "few months" timeframe. A reasonable inference is that Claude handled a large portion of the implementation work, while the human collaborators were responsible for architectural decisions, domain knowledge injection, and quality control.

The "domain knowledge" here is not programming knowledge in the general sense. What Ben brought was the wisdom of ancient Greeks from two thousand years ago about memory, and the intuition accumulated over twenty years of systems engineering about "what can survive in production." These things do not exist in any AI's training data --- at least not in a form that can be directly applied. They require a person to translate classical concepts into the language of software architecture, then let the AI implement them.

---

## Traces of Iteration

The version number 3.0.0 is itself a story.

A software project reaching 3.0 means it has undergone at least two major refactors. Not minor patch-level upgrades, but "this direction isn't working, tear it down and start over" level changes. Each major version iteration typically means the developers' understanding of the problem underwent a fundamental shift --- not "this function should be written differently," but "we have been solving the wrong problem."

From the project's git history, the development process was iterative. The commit log shows a gradual evolution, not a finished product that suddenly appeared from nothing one day. This is consistent with the statement about "working with an AI for several months." It was not a weekend hackathon project, nor a product "generated in one shot" by an AI. It was the result of repeated experimentation and correction.

One can imagine the outline of this process (though specific details cannot be confirmed from public information): early versions may have tried a simpler memory approach and found the results inadequate; then the spatial structure concept of the "palace" was introduced, and retrieval accuracy improved significantly; later, performance issues may have arisen when handling large-scale data, leading to the development of the AAAK compression dialect to address context window limitations. Each step was not planned in advance but emerged from discovering, understanding, and solving problems in practice.

During this iterative process, the human-AI collaboration most likely was not static. In the early exploratory phase, human intuition and judgment probably dominated --- an insight like "we should organize data using the memory palace approach" would not come from an AI. In the middle implementation phase, the AI's code generation capability was likely fully utilized --- turning concepts into runnable modules. In the late optimization phase, it probably returned to intensive human-AI dialogue --- "why won't this benchmark score go up? Is it the retrieval logic or the data organization?"

---

## Why This Matters

In 2025, "writing code with AI" is no longer news. Every day, thousands of developers use Copilot, Cursor, and Claude to accelerate their programming work. Most of the time, these tools are used as smarter auto-complete --- the human writes one line of comment, and the AI fills in five lines of code.

The MemPalace case is interesting because it hints at a different possibility.

When a person with a Classics background, a person with a Hollywood background, and an AI sit down together for months and produce a work that beats all existing systems on academic benchmarks --- the significance is not "AI is amazing" or "these two people are amazing," but in the combination itself.

If Ben had not been trained in Classics, he would not have thought to use a two-thousand-year-old memory technique to organize AI data. The Method of Loci is not in any standard "AI memory system" technology stack. It came from an entirely different knowledge domain, brought into this project by someone who happened to understand both domains.

Without twenty years of systems engineering experience, the "two dependencies" decision would not have happened. A less experienced team facing the same requirements would likely have pulled in a dozen libraries to "ship quickly," then been buried by dependency hell six months later. A minimal dependency strategy is not conservatism; it is judgment born from experience.

Without Claude's participation, completing the development, testing, and iteration to v3.0 of 30 modules within a few months would have been extremely difficult for two people. The AI here is not a nice-to-have assistive tool; it is the key factor that made this project possible within the given time and staffing constraints.

All three are indispensable. Classics provided the core insight, engineering experience provided architectural judgment, and AI provided implementation bandwidth. This is not a story about "AI replacing programmers" --- quite the opposite. It is a story about "human cross-domain knowledge becoming more valuable in the AI era." Because AI can write code, but it will not on its own go read Cicero's *De Oratore* and then have a flash of inspiration: "hey, a two-thousand-year-old memory technique can solve the 2025 AI context management problem."

That kind of connection --- spanning time, spanning disciplines --- remains a uniquely human capability. And the role of AI is to ensure that once these connections are made, they can be turned into working systems at unprecedented speed.

---

## So What Did They Build?

Months of collaboration produced a memory system. It scored 96.6% on the LongMemEval benchmark raw --- no external API calls, no cloud service dependencies, running entirely locally. With a lightweight reranking step, the score reached 100% --- all 500 questions answered correctly.

Among all publicly available AI memory systems, free or paid, there is no higher score.

The result itself is impressive. But the more important question is: how did they do it? How did a system that depends on only two Python packages, runs entirely locally, and requires no API keys surpass commercial products backed by ample engineering resources and cloud computing budgets?

The answer lies in a concept from two thousand years ago.

The core principle of the memory palace technique is not "remember more" but "make information findable." Ancient Greek orators did not memorize long speeches by rote --- they placed each argument at a specific location in an imaginary building, and when needed, they walked along the route and naturally extracted each point in order. The key insight is that spatial structure itself is an index.

MemPalace applies the same principle to AI memory. Every conversation with an AI, every decision, every debugging session --- this information is not dumped into one giant unstructured text heap but placed in a "palace" with Wings, corridors, and Rooms. When you ask "why did we abandon GraphQL three months ago," the system does not need to scan all memories --- it knows which Wing and which Room to look in.

This single structural improvement alone raised retrieval accuracy by 34%.

But this is only the beginning of the story. How is the palace structure defined? By what rules are Rooms divided? What happens when the same topic appears in multiple different contexts? How do you fit months of memory into a limited context window? How do you detect when memories contradict each other?

The answers to these questions form the entire content of the rest of this book. Starting from the next chapter, we will disassemble every component of this palace --- not as user documentation for an open-source project, but as a complete record of design decisions: what problem was faced, what alternatives were considered, why the final approach was chosen, and the engineering trade-offs behind those choices.

This palace is worth walking into and examining closely.
