---
name: jules-architect
description: Use this skill whenever the user asks for code modifications, bug fixes, new features, or architectural changes. This skill handles the "Architect" role by preparing precise instructions for Jules (the implementer) and sending them via API. Trigger this for any intent related to implementing or changing code.
---

# Jules Architect Skill (v1.4 API)

## Workflow
1. **Analyse (Context Pruning)**: Read only the files to be modified. For dependencies, read only headers/signatures.
2. **Doc Injection**: If logic changes, redact the exact `AVANT/APRES` block for `ARCHITECTURE.md`.
3. **Prompt Construction**: Create a structured prompt for Jules (No backticks `).
4. **Execution**: 
   - If the task is clear: Send via `jules_bridge.py` immediately.
   - If ambiguous: Show the prompt to the user for validation first.

## Output Format
Always report the `sessionId` returned by the API and notify the user that they should signal when the PR is ready for review.