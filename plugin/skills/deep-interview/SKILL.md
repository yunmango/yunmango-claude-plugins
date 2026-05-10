---
name: deep-interview
description: Interview an ambiguous request with Socratic questions to crystallize it into actionable requirements. Invoked only via the explicit "/deep-interview" slash command — automatic model invocation is disabled.
disable-model-invocation: true
argument-hint: "<rough request>"
---

# Deep Interview

Don't jump straight into execution on an ambiguous request — first crystallize it into clear requirements.

The point is not to ask many questions, but to pick the single largest uncertainty and resolve it, one at a time.

Ask in the Socratic style. Rather than deciding the answer on the user's behalf, frame questions that surface their implicit assumptions, options, and decision criteria.

## Question Axes

In the following order, pick the single most unclear axis:

- Goal
- Scope and out-of-scope
- Constraints
- Done criteria
- Existing context and blast radius

If a question can be answered by reading the codebase, do not ask the user — check it yourself.

## Process

Ask only one question at a time. With each question, briefly state the current understanding, the stuck decision, and a recommended answer.

Question format:

```md
Current understanding: {one-sentence summary of the request}
Stuck decision: {the most important uncertainty}
Recommended answer: {if any}
Question: {a single question}
```

Once you receive an answer, briefly update what is now decided, and only ask another question if a meaningful uncertainty still remains.

If options help, offer just 2–3 of them, and always allow free-form input.

## Stop Criteria

Stop when the following are settled:

- The goal being pursued
- In-scope and out-of-scope
- Constraints to honor
- Criteria for "done"
- Any remaining open questions

At the end, summarize only the decisions and the open questions — not the full transcript.
