---
name: plan-verify
description: Sequential plan-then-verify workflow — Claude Opus drafts an implementation plan by exploring the codebase, then Codex (gpt-5.5, xhigh reasoning, fast mode) independently verifies the plan against the actual code and returns a verdict (PASS / PASS_WITH_NOTES / NEEDS_REVISION). Invoked only via the explicit "/plan-verify" slash command — automatic model invocation is disabled.
disable-model-invocation: true
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
    │     └── runs codex exec -s read-only (gpt-5.5, xhigh, fast mode)
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
Your FINAL message must contain the complete verification report and nothing else. Do NOT end with a tool call, follow-up question, or summary — output the full report as your last message.
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

After receiving the Claude Planner's result, delegate verification to a Codex subagent that runs the bundled script. The script has the model, reasoning effort, sandbox, and fast mode hardcoded — the agent must NOT modify the script or run codex directly.

- **subagent_type**: `general-purpose`
- **run_in_background**: `false`
- **name**: `codex-verifier`
- **prompt**: Instruct the agent to run the bundled script:

```
You are a Codex agent coordinator. Your ONLY job is to run a shell script and return its output.

CRITICAL: Do NOT run codex directly. Do NOT change the model name or flags. Use ONLY the bundled script below.

1. Create a temp directory and write the verification prompt to a file:
   WORK_DIR="/tmp/codex-verifier-$(date +%s)"
   mkdir -p "$WORK_DIR"
   Write the full verification prompt to "$WORK_DIR/prompt.txt" using the Write tool.

   The verification prompt is the Verification Prompt Template with `<TASK>` and `<CLAUDE_PLAN>` replaced with the actual values.

   IMPORTANT: The verification prompt MUST end with the following instruction:
   "Your FINAL message must contain the complete verification report and nothing else. Do NOT end with a tool call, follow-up question, or summary — output the full report as your last message."
   This is required because the `-o` flag captures only the last message from the agent.

2. Run the bundled script (DO NOT MODIFY THIS COMMAND):
   bash <SKILL_DIR>/scripts/run_codex_verifier.sh "$WORK_DIR/prompt.txt" "$WORK_DIR/report.md" "<project_root>"

   Where <SKILL_DIR> is the directory containing SKILL.md (use the path from which you read this skill).
   Where <project_root> is the project root directory.

3. Read "$WORK_DIR/report.md" and return the FULL content.
   If the script failed, read "$WORK_DIR/report.stderr.log" and return the error.

4. Clean up: rm -rf "$WORK_DIR"

IMPORTANT: Do NOT generate a verification report yourself. Do NOT run codex CLI directly. Only run the script and return its output verbatim.
```

CRITICAL:
- The script hardcodes `--model gpt-5.5`, `model_reasoning_effort=xhigh`, `--enable fast_mode`, and `-s read-only`. Do not change them.
- Replace `<TASK>` and `<CLAUDE_PLAN>` in the Verification Prompt Template with their actual values before writing the prompt file.
- The script runs `codex exec` directly (not the codex-rescue subagent), so progress UX is silent until completion.

### Step 3: Synthesize Final Plan

The team lead does not blanket-accept Codex's findings — a final pass of judgment is required. Run Step 3a (triage) before Step 3b (build).

#### If Verdict is PASS

Adopt Claude's original plan as the final plan. Briefly mention the Confirmed section from Codex. Step 3a/3b not required (no findings to triage).

#### If Verdict is PASS_WITH_NOTES or NEEDS_REVISION

Run Step 3a, then Step 3b.

##### Step 3a: Triage Codex Findings

For each item listed under Gaps, Risks, and Ordering Issues, classify as one of:

- **ACCEPT** — incorporate into the revised plan. Default disposition for codebase-grounded factual corrections (file paths, counts, function signatures, regex feasibility, ordering errors, etc.).
- **ACCEPT_WITH_MODIFICATION** — incorporate but rephrase, narrow the scope, or split across plan steps. Use when the underlying concern is valid but the suggested mitigation is heavier than needed.
- **REJECT** — do not incorporate. Permitted only when the finding is one of:
  1. **Empirically wrong** — Codex misread the codebase. Spot-verify by reading the referenced file before classifying as REJECT on this ground.
  2. **Out of scope** — contradicts the clarified requirements established in Step 0.
  3. **Speculative** — Codex itself flagged the claim as unverified, or the finding is not grounded in concrete codebase evidence.
  4. **Stylistic / taste** — diverges from established project conventions without functional impact.

  Each REJECT must include a one-line justification.

When unsure between ACCEPT and REJECT, read the relevant codebase file(s) to verify Codex's claim before classifying. Trust-but-verify is the default for high-impact items (architectural changes, regex correctness, ordering issues, missing dependencies).

##### Step 3b: Build Revised Plan

Apply ACCEPT and ACCEPT_WITH_MODIFICATION items into the 6-heading plan structure. REJECT items are surfaced separately in the output (see below) so the reviewer can see what was deliberately skipped and why.

For NEEDS_REVISION, additionally show what changed relative to Claude's original plan (a brief change list, not a full diff).

Output format:

```
## Verification Summary

**Verdict**: <PASS | PASS_WITH_NOTES | NEEDS_REVISION>

### Codex Verification Highlights
- Confirmed: <summary of confirmed items>
- Gaps: <gaps found> (if any)
- Risks: <key risks> (if any)

### Findings Triage  (omit when Verdict is PASS)
- ACCEPT: <bullet list>
- ACCEPT_WITH_MODIFICATION: <bullet list, each with a note on the modification>
- REJECT: <bullet list, each with a one-line justification>

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
*Planned by Claude Opus · Verified by Codex gpt-5.5 (xhigh reasoning, fast mode)*
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
- **Fixed model & flags**: Codex Verifier uses the bundled script which hardcodes `gpt-5.5`, `xhigh` reasoning, `read-only` sandbox, and `--enable fast_mode`. Do not modify the script or run codex directly.
- **Codebase-grounded verification**: Codex verifies based on actual codebase exploration, not speculation.
- **subagent_type**: Both Claude Planner and Codex Verifier use `general-purpose`. Codex Verifier runs the bundled `scripts/run_codex_verifier.sh`.
