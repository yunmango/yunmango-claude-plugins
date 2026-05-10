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

**Description vs Prescription**: A fact found in the codebase ("the project uses JWT") is *description*, not *prescription*. Never extend it into a decision for the new request ("the new feature should also use JWT") without asking the user. Description goes into context; prescription requires explicit user confirmation.

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

**Breadth check**: Every 3–4 questions, scan all 5 axes. If any axis still has no user input, pick the next question from the empty axis rather than drilling deeper into the current one.

**Assumption marker**: When you must record something the user did not explicitly confirm (inference from codebase, common defaults, etc.), tag it with `(assumption)` in your running understanding. Do not let assumptions silently harden into decisions.

## Stop Criteria

Before declaring done, check all 5 axes:

- The goal being pursued
- In-scope and out-of-scope
- Constraints to honor
- Criteria for "done"
- Existing context and blast radius

If any axis is filled only by `(assumption)` and no direct user answer, ask one more direct question to confirm or correct it before stopping.

## Final Output

At the end, output only the sections below — not the full transcript:

```md
## Goal
...

## In-scope
- ...

## Out-of-scope
- ...

## Constraints
- ...

## Done criteria
- ...

## Assumptions
- {items the user did not explicitly confirm — flag for the planning step to verify}

## Open questions
- {anything still unresolved}
```
