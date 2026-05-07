---
name: plan-verify
description: Sequential plan-then-verify workflow — Claude Opus drafts an implementation plan by exploring the codebase, then Codex GPT-5.5 (xhigh reasoning) independently verifies the plan against the actual code and returns a verdict (PASS / PASS_WITH_NOTES / NEEDS_REVISION). ALWAYS use this skill when the user wants a plan that is verified, validated, or reviewed by a second model. Trigger on any of these signals — explicit commands like "/plan-verify", Korean phrases like "계획 검증", "검증 계획", "계획 세우고 검증", or English phrases like "verified plan", "plan and verify", "validate the plan". Also trigger when the user asks to "plan something and have Codex/GPT check it", wants a "solid/robust/reliable plan", mentions wanting a plan "reviewed by another model", or says "계획 좀 단단하게". Do NOT trigger for simple planning without verification, cross-plan (parallel dual planning), direct Codex delegation, or code review of existing changes.
---

# Plan-Verify Skill

Claude Code acts as **team lead**. It does not create its own plan. It clarifies requirements, collects the Claude Planner's output, hands it to Codex Verifier for validation, and synthesizes the final plan.

## Arguments

- `/plan-verify <task description>` → Build and verify a plan for the given task
- `/plan-verify` → Prompt user for task description

## Architecture

```
Claude Code (Team Lead)
    │
    ├── Step 0: Analyze requirements & clarify ambiguities
    │
    ├── Step 1: Claude Planner (foreground)
    │     └── Explores codebase → returns structured plan
    │
    ├── Step 2: Codex Verifier (foreground)
    │     └── codex:codex-rescue (gpt-5.5, xhigh)
    │     └── Verifies Claude's plan against actual codebase
    │     └── Returns verification report
    │
    ├── Step 3: Synthesize final plan
    │
    └── Step 4: Save plan & confirm with user
```

## Planning Prompt Template

Prompt sent to the Claude Planner. Replace `<TASK>` with the user's task. If clarifications were gathered in Step 0, append a `## Clarified Requirements` section.

```
You are a software architect. You have full read access to the codebase.

Before writing your plan, explore the project structure, read relevant source files,
and understand the existing architecture. Do NOT skip this step.

## Output Format (MANDATORY)

After exploring the codebase, structure your plan EXACTLY as follows:

### 1. Goal
One-sentence summary of what needs to be done.

### 2. Analysis
Key technical considerations, constraints, and risks. Bullet list.
Reference specific files and patterns you found in the codebase.

### 3. Architecture
High-level design decisions and component relationships.
Show how the new work fits into the existing architecture.

### 4. Implementation Steps
Ordered list of concrete steps. Each step MUST include:
- What to do
- Which file(s) to create or modify (full path from project root)
- Key code changes or patterns to use (based on existing codebase conventions)

### 5. Testing Strategy
How to verify the implementation. Include specific test types and targets.
Follow existing test patterns found in the project.

### 6. Edge Cases & Risks
Potential issues and mitigations. Bullet list.

## Task
<TASK>

IMPORTANT: Explore the codebase thoroughly, then output ONLY the plan. Do NOT make any code changes.
Your FINAL message must contain the complete plan and nothing else.
```

## Verification Prompt Template

Prompt sent to the Codex Verifier. Replace `<CLAUDE_PLAN>` with Claude's plan and `<TASK>` with the original task.

```
You are a critical code reviewer verifying a proposed implementation plan against the actual codebase.

## Original Task
<TASK>

## Plan to Verify
<CLAUDE_PLAN>

## Instructions

Explore the codebase thoroughly to verify every claim in the plan. For each implementation step:
1. Confirm that referenced files, functions, and patterns actually exist
2. Check for missed dependencies, imports, or side effects
3. Identify unstated assumptions about the codebase
4. Flag ordering issues (e.g., step 3 depends on something not created until step 5)
5. Look for existing code that already solves part of the problem

## Output Format (MANDATORY)

### Confirmed
Steps and claims that are correct and well-grounded in the codebase. Reference the specific files you checked.

### Gaps
Missing considerations, incomplete steps, or overlooked files/modules. Be specific about what is missing and why it matters.

### Risks
Potential issues with the proposed approach and suggested mitigations. Include alternative approaches if the risk is high.

### Ordering Issues
Steps that are in the wrong order or have unresolved dependencies.

### Verdict
One of: PASS | PASS_WITH_NOTES | NEEDS_REVISION

If NEEDS_REVISION, list the specific items that must be addressed before implementation.

IMPORTANT: Base your verification ONLY on what you find in the codebase. Do NOT speculate. If you cannot verify a claim, say so explicitly.
```

## Execution Flow

### Step 0: Task Analysis & Clarification

Analyze the requirements and ask the user about any ambiguities.

1. **Analyze the task** for ambiguous requirements, missing context, and design decision points.
2. **If ambiguities exist**, use AskUserQuestion:
   - Number each question and briefly explain why clarification matters
   - Suggest default options where possible
3. **If the task is already clear**, skip directly to Step 1. Do not ask unnecessary questions.
4. **Build enriched prompt**: Incorporate user answers into a `## Clarified Requirements` section in the Planning Prompt:
   ```
   ## Clarified Requirements
   - Q: <question> → A: <answer>
   ```

### Step 1: Claude Planner (Foreground)

Launch the Claude Planner with a single Agent tool call.

- **subagent_type**: `general-purpose`
- **model**: `opus`
- **run_in_background**: `false`
- **prompt**: The Planning Prompt Template (with `<TASK>` replaced). Prepend:
  "You are a software architect. Explore the codebase using Read, Glob, and Grep tools, then produce the plan. Do NOT run any external CLI tools — use only your built-in tools."

Store the result as `<CLAUDE_PLAN>`.

### Step 2: Codex Verifier (Foreground)

After receiving the Claude Planner's result, delegate verification to Codex.

- **subagent_type**: `codex:codex-rescue`
- **run_in_background**: `false`
- **prompt**: Follow this format **exactly**:

```
--model gpt-5.5 --effort xhigh

This is a read-only review task. Do not modify any files.

<Verification Prompt Template with <TASK> and <CLAUDE_PLAN> replaced>
```

CRITICAL:
- Always include `--model gpt-5.5 --effort xhigh` on the first line of the prompt.
- Always include "This is a read-only review task. Do not modify any files." Without this, Codex runs in write mode.
- Do not change the model or effort level.
- Replace `<TASK>` and `<CLAUDE_PLAN>` in the Verification Prompt Template with their actual values.

### Step 3: Synthesize Final Plan

Combine both results into the final plan.

#### If Verdict is PASS

Adopt Claude's original plan as the final plan. Briefly mention the Confirmed section from Codex.

#### If Verdict is PASS_WITH_NOTES

Use Claude's plan as the base, incorporating the Gaps/Risks flagged by Codex. Clearly mark what was changed.

#### If Verdict is NEEDS_REVISION

Revise the plan to address all of Codex's findings. Show changes relative to the original in diff format.

Output format:

```
## Verification Summary

**Verdict**: <PASS | PASS_WITH_NOTES | NEEDS_REVISION>

### Codex Verification Highlights
- Confirmed: <summary of confirmed items>
- Gaps: <gaps found> (if any)
- Risks: <key risks> (if any)

### Final Verified Plan
<complete plan in the 6-heading format>
```

### Step 4: Save Plan & Ask User

Save the final plan to a file.

- **Path**: `.claude/plans/<kebab-case-name>.md`
- **Format**:

```markdown
# Verified Plan: <task summary>

<Final Verified Plan content>

---
*Planned by Claude Opus 4.6 · Verified by GPT-5.5 (xhigh reasoning)*
```

After saving, present to the user:

```
Plan saved to `.claude/plans/<filename>.md`

Proceed with implementation based on this plan?
```

- **Approve** → Enter plan mode and implement following the saved plan
- **Decline or request changes** → End here

## Critical Notes

- **Team lead = clarifier + synthesizer**: The team lead does not create its own plan. It clarifies requirements (Step 0) and synthesizes plan + verification results (Step 3).
- **Sequential execution**: Codex Verifier runs only after Claude Planner completes. Not parallel.
- **Fixed model**: Codex Verifier must use `gpt-5.5` model with `xhigh` effort. Do not change these.
- **Codebase-grounded verification**: Codex verifies based on actual codebase exploration, not speculation.
- **subagent_type**: Claude Planner uses `general-purpose`, Codex Verifier uses `codex:codex-rescue`.
