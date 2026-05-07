---
name: cross-plan
description: Cross-verification planning skill that spawns Claude and Codex planner agents in parallel, then the team lead synthesizes a verified plan. Use this when the user asks for cross-verification, dual planning, or wants to compare plans from multiple AI agents. Trigger on "cross plan", "cross verify", "교차검증", "dual plan", or "/cross-plan".
invokable: true
---

# Cross-Plan Skill

Claude Code acts as **team lead**, first clarifying ambiguities with the user, then spawning two independent planner agents — Claude Planner and Codex Planner — and finally cross-verifying and synthesizing the final plan.

The team lead does NOT create its own plan. It clarifies requirements, collects planner outputs, compares, and synthesizes.

## Arguments

- `/cross-plan <task description>` → Generate and cross-verify plans for the given task
- `/cross-plan` → Prompt user for task description

## Architecture

```
Claude Code (Team Lead)
    │
    ├── Step 0: Analyze task & ask clarifying questions
    │     └── identifies ambiguities, missing context, decision points
    │     └── asks user → collects answers
    │     └── builds enriched planning prompt
    │
    ├── Step 1: Spawn claude-planner (background)
    │     └── explores codebase with Read/Glob/Grep
    │     └── returns Claude plan
    │
    ├── Step 1: Spawn codex-planner (background)
    │     └── runs codex exec -s read-only
    │     └── returns Codex plan
    │
    ├── Wait for both teammates
    │
    └── Cross-verify & synthesize final plan
```

## Planning Prompt Template

Both agents receive the same prompt. Replace `<TASK>` with the user's task description. If clarifications were gathered in Step 0, append them after the Task section as `## Clarified Requirements`.

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
Your FINAL message must contain the complete plan and nothing else. Do NOT end with a tool call, follow-up question, or summary — output the full plan as your last message.
```

## Execution Flow

### Step 0: Task Analysis & Clarification

Before spawning any planner agents, the team lead analyzes the task and identifies areas that need clarification.

1. **Analyze the task description** for:
   - Ambiguous requirements (multiple valid interpretations)
   - Missing context (scope, constraints, preferences not specified)
   - Design decisions that could go either way (e.g., library choice, architecture pattern)
   - Assumptions that should be confirmed

2. **If ambiguities or decision points exist**, present them to the user using AskUserQuestion:
   - List each question concisely with numbered items
   - For each question, briefly explain why clarification matters (what divergent outcomes could result)
   - If relevant, suggest default options the user can accept quickly

3. **If the task is already clear** (no meaningful ambiguities), skip questioning and proceed directly to Step 1. Do NOT ask unnecessary questions just for the sake of it.

4. **Build the enriched prompt**: Incorporate the user's answers into the `<CLARIFICATIONS>` section of the Planning Prompt Template. Format as:
   ```
   The following requirements were clarified with the user:
   - Q: <question> → A: <user's answer>
   - Q: <question> → A: <user's answer>
   ```

### Step 1: Spawn Both Planners (Background)

Launch **both agents simultaneously** using two Agent tool calls in a single message.

#### Claude Planner

- **subagent_type**: `general-purpose`
- **model**: `opus`
- **run_in_background**: `true`
- **name**: `claude-planner`
- **prompt**: The planning prompt template above (with `<TASK>` replaced).
  Prepend: "You are a software architect. Explore the codebase using Read, Glob, and Grep tools, then produce the plan. Do NOT run any external CLI tools — use only your built-in tools."

#### Codex Planner

- **subagent_type**: `general-purpose`
- **run_in_background**: `true`
- **name**: `codex-planner`
- **prompt**: Instruct the agent to run the bundled script. The script has the model (`gpt-5.5`) and reasoning effort (`xhigh`) hardcoded — the agent must NOT modify the script or run codex directly.

```
You are a Codex agent coordinator. Your ONLY job is to run a shell script and return its output.

CRITICAL: Do NOT run codex directly. Do NOT change the model name. Use ONLY the bundled script below.

1. Create a temp directory and write the planning prompt to a file:
   WORK_DIR="/tmp/codex-planner-$(date +%s)"
   mkdir -p "$WORK_DIR"
   Write the full planning prompt to "$WORK_DIR/prompt.txt" using the Write tool.

   IMPORTANT: The planning prompt MUST end with the following instruction:
   "Your FINAL message must contain the complete plan and nothing else. Do NOT end with a tool call, follow-up question, or summary — output the full plan as your last message."
   This is required because the `-o` flag captures only the last message from the agent.

2. Run the bundled script (DO NOT MODIFY THIS COMMAND):
   bash <SKILL_DIR>/scripts/run_codex_planner.sh "$WORK_DIR/prompt.txt" "$WORK_DIR/plan.md" "<project_root>"

   Where <SKILL_DIR> is the directory containing SKILL.md (use the path from which you read this skill).
   Where <project_root> is the project root directory.

3. Read "$WORK_DIR/plan.md" and return the FULL content.
   If the script failed, read "$WORK_DIR/plan.stderr.log" and return the error.

4. Clean up: rm -rf "$WORK_DIR"

IMPORTANT: Do NOT generate a plan yourself. Do NOT run codex CLI directly. Only run the script and return its output verbatim.
```

### Step 2: Wait for Both Results

Simply wait for both background agents to return their results.

While waiting, you may briefly inform the user that both agents are working.

### Step 3: Handle Failures

| Claude Planner | Codex Planner | Action |
|----------------|---------------|--------|
| OK | OK | Full cross-verification (normal flow) |
| OK | FAIL | Present Claude's plan only, label as "Single-source plan (unverified)" |
| FAIL | OK | Present Codex's plan only, label as "Single-source plan (unverified)" |
| FAIL | FAIL | Report both errors. Suggest user retry |

### Step 4: Cross-Verify and Synthesize

*Only when both plans are available.*

Compare both plans section-by-section (using the 6 mandatory headings) and present:

```
## Cross-Verification Result

### Consensus (High Confidence)
Items both agents agree on — highest reliability.

### Divergence (Review Required)
| Item | Claude Planner | Codex Planner | Recommendation |
|------|----------------|---------------|----------------|
| ...  | ...            | ...           | ...            |

### Unique Insights
Valuable points raised by only one agent. Evaluate and incorporate if valid.

### Final Integrated Plan
The cross-verified, synthesized plan using the same 6-heading format.
```

### Step 5: Save Plan to File

Save the **Final Integrated Plan** section as a markdown file in the plans directory:

- **Path**: `.claude/plans/<auto-generated-name>.md`
- **Format**: The Final Integrated Plan content (6-heading format), prefixed with a title line:

```markdown
# Cross-Verified Plan: <task summary>

<Final Integrated Plan content>

---
*Cross-verified by Claude Opus 4.6 + GPT-5.5 (xhigh reasoning)*
```

Use the Write tool to save the file. The filename should follow the existing naming convention in `.claude/plans/` (kebab-case descriptive name).

### Step 6: Ask User to Proceed

After saving, present the user with:

```
Plan saved to `.claude/plans/<filename>.md`

Proceed with implementation based on this plan?
```

- **User approves** → Enter plan mode and implement following the saved plan
- **User declines or wants changes** → End here. User can revisit the plan later.

## Critical Notes

- **Team lead = clarifier + synthesizer**: The team lead clarifies requirements with the user (Step 0), then cross-verifies and synthesizes the two planner outputs. It does NOT create its own plan.
- **Clarify only when needed**: Do NOT ask unnecessary questions. If the task is already clear and specific, skip Step 0 and go straight to Step 1.
- **Two independent planners**: Claude Planner uses built-in tools (Read/Glob/Grep). Codex Planner runs `codex exec -s read-only`.
- **Spawn both simultaneously**: Use two Agent tool calls in a single message for maximum parallelism.
- **subagent_type**: Both must use `general-purpose` (custom agent types are not supported).
- **Same prompt**: Both planners receive the identical planning prompt (including clarifications) for fair comparison.
- **No code changes**: Neither agent writes or modifies any code. Plan only.
