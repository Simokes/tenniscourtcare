# AI_RULES.md

## 1. AI Roles & Responsibilities

### 1.1 Claude (Anthropic)

**Primary role:** Architecture, analysis, code review, strategic planning

**Strengths:**
- Long context windows (200K tokens)
- Complex architectural analysis
- Cross-layer dependency validation
- Refactoring strategy design
- Security & performance analysis
- Documentation synthesis

**Assigned tasks:**
- Architecture design & validation
- Code review (compliance with ARCHITECTURE.md)
- Design refactoring strategies
- Security analysis & threat modeling
- Error handling pattern validation
- Documentation (PROJECT_SUMMARY, ARCHITECTURE, CODING_RULES)
- Dependency violation detection
- Workflow design & optimization

**Forbidden tasks:**
- Real-time code execution
- Firestore rules testing (needs Firebase Emulator)
- Performance benchmarking (needs metrics)
- UI pixel-perfect design
- Dependency version resolution
- Debugging production crashes
- Code implementation (use Gemini)
- Test implementation (use Gemini)

---

### 1.2 Gemini (Google)

**Primary role:** Code generation, implementation, testing

**Strengths:**
- Fast token processing
- Boilerplate code generation
- Widget & screen implementation
- Provider setup
- Test generation (unit & widget)
- Migration script generation

**Assigned tasks:**
- Entity implementation (from spec)
- Repository implementation (from interface)
- Provider setup & boilerplate
- Widget implementation (given design)
- Screen implementation (given spec)
- Mapper generation
- Unit test generation
- Widget test generation
- Migration scripts
- Error handling wrappers
- Null safety fixes

**Forbidden tasks:**
- Architecture decisions
- Design choices
- Code review
- Security analysis
- Refactoring strategy
- Dependency decisions
- Documentation writing
- Performance optimization
- Complex logic design

---

### 1.3 Jules (Perplexity)

**Primary role:** Research, best practices, dependency analysis

**Strengths:**
- Real-time information access
- Package compatibility research
- Current best practices
- Dependency version research
- Error message interpretation
- Migration guide research
- API documentation lookup

**Assigned tasks:**
- Dependency version research
- Package compatibility checks
- Flutter/Dart best practices (latest)
- Error message interpretation
- Implementation pattern research
- Migration guides
- API documentation lookup
- Performance benchmark references
- Rate limit & quota research

**Forbidden tasks:**
- Code generation
- Architecture decisions
- Code review
- Security analysis
- Refactoring
- Test implementation
- Writing project-specific code

---

## 2. Task Authorization Matrix

### 2.1 Architecture & Design

| Task | Claude | Gemini | Jules | Human |
|------|--------|--------|-------|-------|
| Architecture pattern decision | ✅ | ❌ | ❌ | ✅ Approve |
| Layer definition | ✅ | ❌ | ❌ | ✅ Approve |
| Data flow design | ✅ | ❌ | ✅ Research | ✅ Approve |
| Schema design | ✅ | ❌ | ❌ | ✅ Approve |
| Provider hierarchy | ✅ | ❌ | ❌ | ✅ Approve |
| Error handling strategy | ✅ | ❌ | ✅ Research | ✅ Approve |
| Sync strategy | ✅ | ❌ | ❌ | ✅ Approve |
| Routing design | ✅ | ❌ | ❌ | ✅ Approve |

---

### 2.2 Implementation

| Task | Claude | Gemini | Jules | Human |
|------|--------|--------|-------|-------|
| Entity generation | ❌ | ✅ | ❌ | ✅ Review |
| Repository impl | ❌ | ✅ | ❌ | ✅ Review |
| Provider creation | ❌ | ✅ | ❌ | ✅ Review |
| Widget implementation | ❌ | ✅ | ❌ | ✅ Review |
| Screen implementation | ❌ | ✅ | ❌ | ✅ Review |
| Mapper creation | ❌ | ✅ | ❌ | ✅ Review |
| Drift table definition | ❌ | ✅ | ❌ | ✅ Review |
| Migration scripts | ❌ | ✅ | ❌ | ✅ Review |
| Service implementation | ❌ | ✅ | ❌ | ✅ Review |

---

### 2.3 Testing

| Task | Claude | Gemini | Jules | Human |
|------|--------|--------|-------|-------|
| Test strategy definition | ✅ | ❌ | ✅ Research | ✅ Approve |
| Unit test generation | ❌ | ✅ | ❌ | ✅ Review |
| Widget test generation | ❌ | ✅ | ❌ | ✅ Review |
| Integration test design | ✅ | ❌ | ❌ | ✅ Approve |
| Test coverage analysis | ✅ | ❌ | ❌ | ✅ Approve |
| Firebase Emulator setup | ❌ | ❌ | ✅ Research | ✅ Implement |

---

### 2.4 Code Review

| Task | Claude | Gemini | Jules | Human |
|------|--------|--------|-------|-------|
| Architecture compliance | ✅ | ❌ | ❌ | ✅ Final |
| CODING_RULES compliance | ✅ | ❌ | ❌ | ✅ Final |
| Naming convention check | ✅ | ❌ | ❌ | ✅ Final |
| Dependency violations | ✅ | ❌ | ❌ | ✅ Final |
| Error handling review | ✅ | ❌ | ❌ | ✅ Final |
| Performance concerns | ✅ | ❌ | ✅ Research | ✅ Final |
| Security review | ✅ | ❌ | ❌ | ✅ Final |
| Async/await patterns | ✅ | ❌ | ❌ | ✅ Final |

---

### 2.5 Documentation

| Task | Claude | Gemini | Jules | Human |
|------|--------|--------|-------|-------|
| Project summary | ✅ | ❌ | ✅ Research | ✅ Approve |
| Architecture doc | ✅ | ❌ | ❌ | ✅ Approve |
| Coding rules | ✅ | ❌ | ❌ | ✅ Approve |
| API documentation | ✅ | ❌ | ✅ Research | ✅ Approve |
| Runbooks | ✅ | ❌ | ✅ Research | ✅ Approve |
| Setup guides | ✅ | ❌ | ✅ Research | ✅ Approve |
| Troubleshooting guides | ✅ | ❌ | ✅ Research | ✅ Approve |
| Code comments | ❌ | ✅ | ❌ | ✅ Review |

---

## 3. Task Prohibitions

### 3.1 Claude Forbidden

```
❌ Real-time code execution (no environment)
❌ Firebase Emulator testing (needs setup)
❌ Performance benchmarking (no metrics)
❌ UI pixel-perfect feedback (subjective)
❌ Dependency version resolution (needs testing)
❌ Debugging production crashes (no logs)
❌ Code implementation (wrong tool)
❌ Test code writing (Gemini role)
```

---

### 3.2 Gemini Forbidden

```
❌ Architecture decisions (not qualified)
❌ Code review (shallow analysis)
❌ Security analysis (no threat modeling)
❌ Refactoring strategy (needs context)
❌ Writing documentation (Claude role)
❌ Complex logic design (needs design input)
❌ Dependency decisions (research needed)
❌ Performance optimization (needs analysis)
```

---

### 3.3 Jules Forbidden

```
❌ Architecture design (not qualified)
❌ Code generation (not its role)
❌ Security analysis (needs deep expertise)
❌ Refactoring guidance (needs code context)
❌ Writing code (no project context)
❌ Code review (shallow analysis)
❌ Test implementation (not its role)
❌ Design decisions (needs architecture input)
```

---

### 3.4 ALL AIs Forbidden

```
❌ Commit to version control (human only)
❌ Merge pull requests (human only)
❌ Deploy to production (human only)
❌ Create database migrations without human review
❌ Modify Firestore security rules without testing
❌ Change sync strategy without architecture approval
❌ Approve architectural decisions (human only)
❌ Make business decisions
❌ Approve code for production
❌ Delete or modify existing code without explicit request
```

---

## 4. Mandatory Workflow

### 4.1 Feature Implementation Workflow

```
┌─────────────────────────────────────────────────────────┐
│ STEP 1: ANALYSIS (Claude)                               │
├─────────────────────────────────────────────────────────┤
│ Tasks:                                                  │
│ • Review existing architecture                          │
│ • Identify affected layers                              │
│ • Check ARCHITECTURE.md compliance                      │
│ • Check CODING_RULES.md compliance                      │
│ • List all dependencies                                 │
│ • Validate layer boundaries                             │
│ • Propose implementation approach (ordered steps)       │
│ • Identify risks & mitigations                          │
│                                                         │
│ Output:                                                 │
│ • Implementation plan (numbered steps)                  │
│ • Files to create/modify (with paths)                   │
│ • Architecture rules to follow                          │
│ • Coding rules to apply                                 │
│ • Risk assessment                                       │
│ • Questions for human (if unclear)                      │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 2: RESEARCH (Jules) - IF NEEDED                    │
├─────────────────────────────────────────────────────────┤
│ Tasks (if architecture requires external packages):     │
│ • Package compatibility checks                          │
│ • Version requirements                                  │
│ • Known issues in dependencies                          │
│ • Migration guides (if upgrading)                       │
│ • API documentation (if integrating external service)   │
│ • Best practices for technology choice                  │
│                                                         │
│ Output:                                                 │
│ • Dependency compatibility matrix                       │
│ • Version recommendations                               │
│ • Known workarounds (if applicable)                     │
│ • Setup instructions (if needed)                        │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 3: HUMAN VALIDATION & APPROVAL                     │
├─────────────────────────────────────────────────────────┤
│ Human validates:                                        │
│ ☐ Implementation approach aligns with requirements      │
│ ☐ Architecture changes acceptable                       │
│ ☐ Scope clearly defined                                │
│ ☐ Dependencies identified correctly                     │
│ ☐ Risk assessment realistic                             │
│ ☐ Timeline feasible                                     │
│ ☐ No business conflicts                                 │
│                                                         │
│ Decision: PROCEED | REVISE | REJECT                     │
└─────────────────────────────────────────────────────────┘
                            ↓
                    (If PROCEED)
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 4: IMPLEMENTATION (Gemini)                         │
├─────────────────────────────────────────────────────────┤
│ Tasks:                                                  │
│ • Generate all code files per implementation plan       │
│ • Follow CODING_RULES.md strictly                       │
│ • Follow ARCHITECTURE.md strictly                       │
│ • Include error handling (try/catch + rethrow)         │
│ • Add doc comments (///) for public APIs               │
│ • Add inline comments (WHY, not WHAT)                  │
│ • Ensure immutability (@immutable, copyWith, final)    │
│ • Ensure null safety                                    │
│ • No magic numbers (use const)                          │
│ • Named parameters required (no positional)            │
│                                                         │
│ Output:                                                 │
│ • All implementation files (ready to paste)             │
│ • File paths specified                                  │
│ • Imports included & correct                            │
│ • No syntax errors                                      │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 5: STATIC REVIEW (Claude)                          │
├─────────────────────────────────────────────────────────┤
│ Tasks:                                                  │
│ • Verify ARCHITECTURE.md compliance                     │
│ • Verify CODING_RULES.md compliance                     │
│ • Check layer boundaries (no circular deps)             │
│ • Check dependency directions (unidirectional)         │
│ • Review error handling patterns                        │
│ • Check naming conventions                              │
│ • Validate imports (no forbidden imports)              │
│ • Check async/await patterns                           │
│ • Verify provider usage                                │
│ • Check test coverage adequacy                         │
│ • Suggest fixes if violations found                     │
│                                                         │
│ Decision: APPROVED | NEEDS_REVISION (→ Step 4)          │
└─────────────────────────────────────────────────────────┘
                            ↓
              (If NEEDS_REVISION)
                   (Loop to Step 4)
                            ↓
                    (If APPROVED)
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 6: TEST GENERATION (Gemini) - IF REQUIRED          │
├─────────────────────────────────────────────────────────┤
│ Tasks (for business logic only):                        │
│ • Generate unit tests (Arrange/Act/Assert)              │
│ • Generate widget tests (critical screens only)         │
│ • Follow test patterns                                  │
│ • Mock external dependencies                            │
│ • Test 3 states (loading, error, success)               │
│                                                         │
│ Output:                                                 │
│ • Unit test files (if business logic)                   │
│ • Widget test files (if critical screen)                │
│ • Mock implementations (if needed)                      │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 7: TEST REVIEW (Claude)                            │
├─────────────────────────────────────────────────────────┤
│ Tasks:                                                  │
│ • Verify test coverage                                  │
│ • Check test patterns (Arrange/Act/Assert)              │
│ • Validate mock strategy                                │
│ • Verify assertions are meaningful                      │
│ • Check test names describe behavior                    │
│                                                         │
│ Decision: APPROVED | NEEDS_REVISION (→ Step 6)          │
└─────────────────────────────────────────────────────────┘
                            ↓
              (If NEEDS_REVISION)
                   (Loop to Step 6)
                            ↓
                    (If APPROVED)
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 8: HUMAN FINAL REVIEW & TEST                       │
├─────────────────────────────────────────────────────────┤
│ Human validates:                                        │
│ ☐ Code compiles without errors                         │
│ ☐ Code compiles without warnings                       │
│ ☐ Tests pass locally                                    │
│ ☐ Functionality works as expected                       │
│ ☐ Edge cases handled                                    │
│ ☐ Integration with existing code works                 │
│ ☐ No performance regression                            │
│ ☐ No new bugs introduced                               │
│ ☐ Meets original requirements                          │
│                                                         │
│ Decision: APPROVE_FOR_MERGE | REJECT (rework)           │
└─────────────────────────────────────────────────────────┘
                            ↓
              (If REJECT)
                (Return to Step 4 or 6)
                            ↓
                   (If APPROVE)
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 9: COMMIT & DEPLOY (Human)                         │
├─────────────────────────────────────────────────────────┤
│ Human tasks:                                            │
│ • Commit code with descriptive message                  │
│ • Push to version control                               │
│ • Deploy (if applicable)                                │
│ • Monitor for issues                                    │
└─────────────────────────────────────────────────────────┘
```

**Rules:**
- ALL steps required (no skipping)
- Each step produces explicit output
- Human approval required at step 3 & 8
- AI output must be complete (no "pseudo-code")
- Any revision loops back to previous step
- Blocked at step 9 until all AI approvals obtained

---

### 4.2 Bug Fix Workflow

```
┌─────────────────────────────────────────────────────────┐
│ STEP 1: ANALYSIS (Claude)                               │
├─────────────────────────────────────────────────────────┤
│ • Review bug report                                     │
│ • Identify root cause (code analysis, no execution)     │
│ • Propose fix approach                                  │
│ • Check architecture impact                             │
│ • Identify related bugs (if any)                        │
│                                                         │
│ Output:                                                 │
│ • Bug analysis (why it happens)                         │
│ • Proposed fix approach                                 │
│ • Scope of fix (what files)                             │
│ • Risk assessment                                       │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 2: HUMAN VALIDATION                                │
├─────────────────────────────────────────────────────────┤
│ • Confirm bug reproduction                              │
│ • Approve fix approach                                  │
│ • Confirm scope acceptable                              │
│                                                         │
│ Decision: PROCEED | REVISE_ANALYSIS (→ Step 1)          │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 3: IMPLEMENTATION (Gemini)                         │
├─────────────────────────────────────────────────────────┤
│ • Generate fix code                                     │
│ • Minimal scope (no refactoring)                        │
│ • Include unit test (reproduction case)                 │
│ • Include regression test (if known)                    │
│                                                         │
│ Output:                                                 │
│ • Fixed code files                                      │
│ • Reproduction test                                     │
│ • Regression test                                       │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 4: CODE REVIEW (Claude)                            │
├─────────────────────────────────────────────────────────┤
│ • Verify fix correctness                                │
│ • Check for side effects                                │
│ • Validate test coverage                                │
│ • Check for regressions                                 │
│                                                         │
│ Decision: APPROVED | NEEDS_FIX (→ Step 3)               │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 5: HUMAN TEST & DEPLOY                             │
├─────────────────────────────────────────────────────────┤
│ • Run tests locally                                     │
│ • Verify bug fix                                        │
│ • Check for regressions                                 │
│ • Commit & deploy                                       │
└─────────────────────────────────────────────────────────┘
```

---

### 4.3 Code Review Workflow (Existing Code)

```
┌─────────────────────────────────────────────────────────┐
│ STEP 1: STATIC ANALYSIS (Claude)                        │
├─────────────────────────────────────────────────────────┤
│ • Check ARCHITECTURE.md compliance                      │
│ • Check CODING_RULES.md compliance                      │
│ • Identify anti-patterns                                │
│ • Check dependency violations                           │
│ • Review error handling                                 │
│ • Check async/await patterns                            │
│ • Identify code smells                                  │
│                                                         │
│ Output:                                                 │
│ • Issues found (categorized by severity)                │
│ • Affected files                                        │
│ • Suggested fixes                                       │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 2: HUMAN DECISION                                  │
├─────────────────────────────────────────────────────────┤
│ • Prioritize issues                                     │
│ • Decide which to fix immediately                       │
│ • Schedule tech debt                                    │
│                                                         │
│ Decision: FIX_NOW | SCHEDULE_LATER | WONT_FIX           │
└─────────────────────────────────────────────────────────┘
                            ↓
          (If FIX_NOW, continue to Step 3)
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 3: REFACTORING PLAN (Claude)                       │
├─────────────────────────────────────────────────────────┤
│ • Design refactoring approach                           │
│ • Ensure architecture compliance                        │
│ • Minimize scope                                        │
│ • Identify tests needed                                 │
│                                                         │
│ Output:                                                 │
│ • Refactoring plan (ordered steps)                      │
│ • Files to modify                                       │
│ • Tests to add                                          │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 4: HUMAN APPROVAL                                  │
├─────────────────────────────────────────────────────────┤
│ • Approve refactoring plan                              │
│                                                         │
│ Decision: PROCEED | REVISE (→ Step 3)                   │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 5: IMPLEMENTATION (Gemini)                         │
├─────────────────────────────────────────────────────────┤
│ • Generate refactored code                              │
│ • Maintain functionality                                │
│ • Add tests if needed                                   │
│                                                         │
│ Output:                                                 │
│ • Refactored code files                                 │
│ • New/updated tests                                     │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 6: REVIEW (Claude)                                 │
├─────────────────────────────────────────────────────────┤
│ • Verify refactoring correctness                        │
│ • Check architecture compliance                         │
│ • Validate tests                                        │
│                                                         │
│ Decision: APPROVED | NEEDS_REVISION (→ Step 5)          │
└─────────────────────────────────────────────────────────┘
```

---

## 5. Request Format Specification

### 5.1 Feature Request to Claude

```markdown
## Feature: [Feature Name]

### Context
- **Current state:** [Current implementation, if any]
- **Goal:** [What should be achieved]
- **User story:** [Who, what, why]

### Architecture Reference
- **Affected layers:** [domain | data | presentation | features]
- **Related entities:** [List entities impacted]
- **Related providers:** [List providers impacted]
- **Existing patterns:** [Link to similar features]

### Requirements
- **Functional:** [Requirement 1, Requirement 2, ...]
- **Non-functional:** [Performance, security, offline, ...]
- **Constraints:** [Platform, dependency, timeline, ...]

### Context to Review
- [Include relevant ARCHITECTURE.md section]
- [Include relevant CODING_RULES.md section]
- [Include similar existing code]
- [Include related entities/providers]

### Expected Output
1. Implementation plan (ordered steps)
2. Files to create/modify (with paths)
3. Architecture validation
4. Risk assessment
5. Open questions
```

**Rules:**
- Include full context sections
- Be specific about requirements
- Provide code samples (related features)
- Ask specific questions
- Validate against existing architecture

---

### 5.2 Implementation Request to Gemini

```markdown
## Task: [Entity/Provider/Widget/Screen] Implementation

### Specification
```dart
// From Claude analysis:
class StockItem {
  final int? id;
  final String name;
  final int quantity;
  final int minThreshold;
  // ... (complete spec)
}
```

### Requirements
- **Functional:** [What it must do]
- **Architecture:** [Layer, pattern, dependencies]
- **Constraints:** [Naming, no magic numbers, doc comments, ...]

### Rules to Apply
- **Architecture:** [Reference ARCHITECTURE.md section]
- **Coding:** [Reference CODING_RULES.md section]
- **Error handling:** [Specific strategy]
- **Testing:** [What to test]

### Context Files
```dart
// Related entity (reference)
[Similar existing code]

// Repository interface
[Abstract interface to implement]

// Provider pattern example
[Similar provider]
```

### Output Specification
- File 1: [Entity file path]
- File 2: [Repository impl path]
- File 3: [Provider path]
- File 4: [Widget path]
- File 5: [Test file path]
```

**Rules:**
- Include exact specification (no ambiguity)
- List all constraints
- Provide reference code (working examples)
- Specify file locations exactly
- Clarify test expectations

---

### 5.3 Code Review Request to Claude

```markdown
## Code Review: [File or Feature]

### Context
- **Feature:** [What this implements]
- **Branch:** [PR/branch identifier]
- **Scope:** [What changed]

### Code to Review
[Full file content or code snippet]

### Rules to Validate
- **Architecture:** [Specific rules from ARCHITECTURE.md]
- **Coding:** [Specific rules from CODING_RULES.md]
- **Patterns:** [Error handling, async/await, providers, ...]

### Focus Areas
- [Focus 1: e.g., "Layer boundaries"]
- [Focus 2: e.g., "Provider dependencies"]
- [Focus 3: e.g., "Error handling"]

### Questions
1. [Question 1]
2. [Question 2]
```

**Rules:**
- Include full file context
- Reference architecture rules to check
- Specify focus areas explicitly
- Include reference code

---

### 5.4 Research Request to Jules

```markdown
## Research: [Topic]

### Context
- **Goal:** [What we're trying to achieve]
- **Current state:** [What we have now]
- **Problem:** [What's missing]

### Specific Questions
1. [Question 1]
2. [Question 2]
3. [Question 3]

### Information Needed
- [Type 1: e.g., "Version compatibility matrix"]
- [Type 2: e.g., "Known issues"]
- [Type 3: e.g., "Setup guide"]

### Timeline
- **Deadline:** [When needed]
- **Priority:** [critical | high | medium | low]
```

**Rules:**
- Be specific about information needed
- Include current state + goal
- Provide context (what this feeds into)
- Set clear priority/deadline

---

## 6. Human Validation Rules

### 6.1 Validation Checkpoints

**CHECKPOINT 1: After Claude Analysis (Step 3)**

Human must validate implementation plan:
```
VALIDATION CHECKLIST:
☐ Plan aligns with business requirements
☐ Architecture changes are acceptable
☐ Scope is clearly defined
☐ All dependencies identified
☐ Risk assessment is realistic
☐ Timeline is feasible
☐ No conflicts with other features
☐ No security concerns
☐ No performance concerns

DECISION OPTIONS:
• PROCEED → Go to Gemini implementation
• REVISE → Send back to Claude for analysis update
• REJECT → Move to backlog
```

**Approval required from:** Feature owner or tech lead

---

**CHECKPOINT 2: After All AI Work (Step 8)**

Human must validate code before merge:
```
VALIDATION CHECKLIST:
☐ Code compiles without errors
☐ Code compiles without warnings
☐ Tests pass locally
☐ All tests pass
☐ Functionality correct
☐ Edge cases handled
☐ Integration with existing code works
☐ No performance regression
☐ No new bugs introduced
☐ Meets original requirements
☐ Follows all rules (ARCHITECTURE, CODING_RULES)
☐ Documentation complete

DECISION OPTIONS:
• APPROVE_FOR_MERGE → Proceed to Step 9
• REJECT → Return for fixes (specify which AI)
• REQUEST_CHANGES → Return with specific feedback
```

**Approval required from:** Tech lead or code reviewer

---

### 6.2 Sign-Off Template

```markdown
## Code Review Sign-Off

**Date:** [Date]
**Feature:** [Feature name]
**Reviewer:** [Name]
**Status:** [APPROVED | APPROVED_WITH_CONDITIONS | REJECTED]

### Review Summary
- **Architecture compliance:** [✅ Pass | ⚠️ Issues | ❌ Critical]
- **CODING_RULES compliance:** [✅ Pass | ⚠️ Issues | ❌ Critical]
- **Test coverage:** [✅ Adequate | ⚠️ Partial | ❌ Insufficient]
- **Performance:** [✅ Acceptable | ⚠️ Concern | ❌ Regression]
- **Security:** [✅ Safe | ⚠️ Review | ❌ Risk]

### Issues Found (if any)
- [Issue 1 - Severity: CRITICAL | HIGH | MEDIUM | LOW]
  - File: [path]
  - Description: [what's wrong]
  - Fix: [how to fix it]
- [Issue 2]

### Approval
```
Name: _______________________
Date: _______________________
Title: _______________________
```

**Rules:**
- Sign-off required for all features
- Keep historical records
- Include issue severity & fix guidance
- Date all approvals

---

## 7. Prompt Versioning Rules

### 7.1 Prompt Repository Structure

```
docs/ai-prompts/
├── 

README.md

                    # Prompt usage guide
├── VERSION.txt                  # Current versions
├── CHANGELOG.md                 # All prompt changes
│
├── claude/
│   ├── feature_analysis.md      # Feature analysis prompt (v2.1)
│   ├── code_review.md           # Code review prompt (v1.5)
│   ├── bug_analysis.md          # Bug analysis prompt (v1.2)
│   ├── refactor_plan.md         # Refactoring planning (v1.0)
│   └── security_review.md       # Security analysis (v1.1)
│
├── gemini/
│   ├── entity_generation.md     # Entity generation (v2.3)
│   ├── provider_generation.md   # Provider setup (v1.8)
│   ├── widget_generation.md     # Widget implementation (v2.1)
│   ├── screen_generation.md     # Screen implementation (v1.4)
│   ├── test_generation.md       # Test generation (v1.6)
│   └── migration_generation.md  # Migration scripts (v1.2)
│
└── jules/
    ├── dependency_research.md   # Dependency research (v1.0)
    ├── package_research.md      # Package compatibility (v1.0)
    ├── error_research.md        # Error message research (v1.0)
    └── api_research.md          # API documentation lookup (v1.0)
```

---

### 7.2 Prompt Versioning Format

```markdown
# [Prompt Name]

**Version:** 2.1
**Last Updated:** 2024-01-15
**AI Model:** Claude 3.5 Sonnet (200K context)
**Purpose:** [One-sentence description]

## Changelog
- **v2.1** (2024-01-15): Added CODING_RULES validation, improved error handling analysis
- **v2.0** (2024-01-10): Added architecture compliance check
- **v1.0** (2024-01-01): Initial version

## Usage
```
**Include when requesting:** [When to use this prompt]

## Prompt Content
[Full prompt text]
```

---

### 7.3 Prompt Update Rules

**BEFORE using a prompt:**
1. Check VERSION.txt for latest version
2. Use prompt from docs/ai-prompts/
3. Include prompt version in your request
4. Include relevant architecture/coding sections

**WHEN updating a prompt:**
1. Increment version (major.minor semantic versioning)
2. Update CHANGELOG.md with reason & date
3. Update VERSION.txt
4. Commit with: `chore: update [prompt-name] v[version]`
5. If MAJOR change: notify team

**Version increment rules:**
- **MAJOR (x.0):** Changes output format, requires different validation, different AI model needed
- **MINOR (0.x):** Improves output quality, adds optional sections, bug fixes

**Rules:**
- Keep all historical versions (never delete)
- Git commit every prompt update
- Document breaking changes clearly
- Test new prompts before team use (on sample task)

---

### 7.4 Prompt Testing Before Deployment

```markdown
## Prompt Test Report

**Date:** [Date]
**Prompt:** [Name]
**Version:** [x.y]
**Tester:** [Name]

### Test Task
[Describe sample task used to test]

### Test Results
- **Completeness:** [Rate 1-5] (Does it answer all questions?)
- **Accuracy:** [Rate 1-5] (Is output correct?)
- **Rule compliance:** [Rate 1-5] (Follows ARCHITECTURE/CODING_RULES?)
- **Clarity:** [Rate 1-5] (Clear, actionable output?)
- **Format:** [Rate 1-5] (Well-structured, easy to use?)

### Issues Found
- [Issue 1 - Impact: Critical | High | Medium | Low]
- [Issue 2]

### Recommendation
☐ **DEPLOY** - Ready for production use
☐ **REVISE & RETEST** - Fix issues, then retest
☐ **REJECT** - Doesn't meet standards

### Sign-Off
- Tester: _______________________
- Date: _______________________
```

---

## 8. AI Handoff Rules

### 8.1 Between AI Models

**Claude → Gemini (Implementation):**

Claude output must include:
```
✅ Complete specification (no ambiguity)
✅ Implementation plan (ordered steps)
✅ File structure (what to create/modify)
✅ Code patterns to follow (from CODING_RULES)
✅ Error handling strategy (specific)
✅ Doc comment template
✅ Architecture rules (specific sections)
✅ Related code examples
```

Gemini receives:
```
✅ Clear specification
✅ Architecture constraints
✅ Coding rule constraints
✅ Reference code (working examples)
✅ File locations (exact paths)
✅ Test expectations
```

---

**Gemini → Claude (Review):**

Gemini output must include:
```
✅ All implementation files (complete, no stubs)
✅ All imports specified
✅ Error handling implemented (try/catch + rethrow)
✅ Doc comments added (///)
✅ No syntax errors
✅ File paths included
✅ Tests implemented (if applicable)
```

Claude receives:
```
✅ Complete code to review
✅ Original specification (what was asked)
✅ Architecture rules to verify
✅ Coding rules to verify
✅ Test patterns to check
```

---

**Claude → Jules (Research):**

Claude identifies:
```
✅ What information is needed
✅ Dependency versions to research
✅ Compatibility concerns
✅ Migration paths needed
✅ API documentation needed
✅ Best practices to verify
```

Jules receives:
```
✅ Clear research questions
✅ Context (why needed)
✅ Expected output format
✅ Deadline/priority
```

---

### 8.2 Context Passing

**Required context at each handoff:**

**FROM Claude to Gemini:**
```
• Analysis summary (1-2 paragraphs)
• Implementation approach (ordered steps)
• File list (what to create/modify)
• Constraints & rules
• Reference code (working examples)
• Architecture sections (to follow)
• Coding rules sections (to follow)
```

**FROM Gemini to Claude:**
```
• Generated code (all files)
• What was implemented
• Known limitations (if any)
• Architecture decisions made
• Test files (if applicable)
```

**FROM Claude to Jules:**
```
• Specific research questions
• Technology/package names
• Context (what this feeds into)
• Preferred format for answers
• Deadline/priority
```

---

## 9. Error & Escalation Handling

### 9.1 AI Output Rejection

**If Claude output rejected:**
```
Rejection Reason: [Be specific]

Issues Found:
- Does not follow ARCHITECTURE.md (which rule?)
- Violates CODING_RULES.md (which rule?)
- Incomplete analysis (what's missing?)
- Contradicts existing design (which decision?)

Action Plan:
1. Provide specific feedback to Claude
2. Claude revises analysis
3. Return to Checkpoint 1 (validation)
```

---

**If Gemini output rejected:**
```
Rejection Reason: [Be specific]

Issues Found:
- Code doesn't compile (what error?)
- Violates CODING_RULES.md (which rule?)
- Missing error handling (where?)
- Wrong architecture (which pattern?)
- Doesn't match specification (what's different?)

Action Plan:
1. Provide specific feedback to Gemini
2. Gemini revises implementation
3. Return to Claude for re-review
```

---

**If Jules research insufficient:**
```
Rejection Reason: [Be specific]

Information Gap:
- Incomplete answers (which questions?)
- Outdated data (from when?)
- Wrong package (specify)
- Missing context (what's missing?)

Action Plan:
1. Provide clarifying questions
2. Jules researches again
3. Human validates new findings
```

---

### 9.2 Escalation Criteria

**Escalate to tech lead if:**

```
❌ AI models give conflicting approaches
❌ Output contradicts project decisions
❌ Unclear business requirements
❌ Architecture change needed
❌ Security concern identified
❌ Performance impact unknown
❌ Multiple revision cycles fail (> 3 loops)
❌ Scope creep detected
❌ AI cannot complete task
```

**Escalation format:**
```markdown
## AI Escalation Report

**Date:** [Date]
**Feature:** [Feature name]
**Issue:** [Describe problem]

### AI Models Involved
- Claude: [Role in escalation]
- Gemini: [Role in escalation]
- Jules: [Role in escalation]

### Context
- [Relevant information]
- [What was attempted]
- [Why it failed]

### Timeline
- **When needed:** [Date]
- **Current status:** [Blocked since when]

### Recommendation
[What human decision is needed]

### Blocked By
[Specific decision required to proceed]
```

**Escalation routing:**
- Feature scope: Product owner
- Architecture: Tech lead
- Security: Security reviewer
- Performance: DevOps lead
- Timeline: Project manager

---

## 10. Quality Metrics

### 10.1 AI Output Quality Checklist

**Claude output quality:**
```
✅ Complete analysis (all layers addressed)
✅ ARCHITECTURE.md referenced (specific sections)
✅ CODING_RULES.md referenced (specific sections)
✅ Risk assessment included (severity + mitigation)
✅ Timeline estimated (realistic)
✅ Clear recommendations (actionable)
✅ Answers original questions (all of them)
✅ Identifies missing information
✅ Suggests validation points
```

---

**Gemini output quality:**
```
✅ All files generated (no incomplete code)
✅ Code compiles (no syntax errors)
✅ ARCHITECTURE.md rules followed (specific)
✅ CODING_RULES.md rules followed (specific)
✅ Error handling present (try/catch + rethrow)
✅ Doc comments included (/// for public APIs)
✅ Null safety verified
✅ No unused imports
✅ Naming conventions followed
✅ Tests generated (if applicable)
```

---

**Jules output quality:**
```
✅ Questions answered clearly
✅ Sources cited (if web sources)
✅ Version numbers included
✅ Compatibility noted
✅ Timeline provided
✅ Actionable recommendations
✅ Known workarounds included
✅ Migration paths documented
```

---

### 10.2 Tracking AI Performance

**Track monthly:**
```
Metrics:
- % of AI output approved on first pass
- % requiring 1 revision
- % requiring 2+ revisions
- % requiring human escalation
- Average revision cycles per task
- Type of issues found in AI output
- Time saved vs manual coding

Track in: docs/ai-metrics.md (updated monthly)
```

---

## 11. Confidentiality & Security

### 11.1 What NOT to Share with AI

```
❌ Production API keys / credentials
❌ Firebase authentication tokens
❌ Real user data (PII, email addresses)
❌ Sensitive business logic (proprietary algorithms)
❌ Client confidential information
❌ Internal security documentation
❌ Database credentials

✅ Architecture decisions (no secrets)
✅ Code patterns (no hardcoded credentials)
✅ Project structure (anonymized)
✅ Error messages (sanitized, no stack traces with paths)
✅ Public library/API documentation
```

---

### 11.2 Before Sending Code to AI

```
SECURITY CHECKLIST:
☐ No API keys in code
☐ No Firebase credentials in code
☐ No real user data in examples
☐ No passwords or tokens
☐ No sensitive comments
☐ Configuration extracted (no hardcoded URLs)
☐ File paths anonymized (if needed)
☐ Package names anonymized (if needed)
☐ Company names removed (if confidential)
☐ Client names removed (if confidential)
```

---

## 12. AI Decision Log

### When AI is used for significant decision:

```markdown
## AI Decision Log

**Date:** [Date]
**Feature:** [Feature name]
**Decision:** [What was decided]

### AI Models Involved
- **Claude:** [Role, what it analyzed]
- **Gemini:** [Role, what it implemented]
- **Jules:** [Role, what it researched]

### Decision Process
1. [Analysis by Claude]
2. [Research by Jules (if applicable)]
3. [Human validation]
4. [Implementation by Gemini]
5. [Review by Claude]
6. [Human approval]

### Alternatives Considered
- [Option 1 - Why rejected]
- [Option 2 - Why rejected]
- [Selected option - Why chosen]

### Impact Assessment
- **Architecture:** [How it affects architecture]
- **Performance:** [Performance implications]
- **Security:** [Security considerations]
- **Timeline:** [Time investment]
- **Scope:** [Scope impact]

### Approval
- **Approved by:** [Name, date]
- **Related files:** [Links to implementation]
- **Related decisions:** [Links to related decisions]

### Review Schedule
- **Next review:** [When to revisit this decision]
- **Success metrics:** [How to measure if decision was good]
```

---

## 13. Compliance Checklist

### Before deploying ANY AI-generated code:

```
ARCHITECTURE COMPLIANCE:
☐ Follows Clean Architecture (domain → data ← presentation)
☐ Layer dependencies unidirectional (no circular)
☐ Domain has NO framework imports
☐ Data layer properly isolated
☐ Presentation uses Riverpod providers only
☐ Features self-contained (imports correct layers)
☐ No business logic in widgets
☐ Proper use of entities vs models vs DTOs

CODING RULES COMPLIANCE:
☐ File names: snake_case
☐ Class names: PascalCase
☐ Variables: camelCase
☐ Constants: camelCase (not SCREAMING)
☐ All parameters: named + required/optional explicit
☐ NO positional parameters in public APIs
☐ NO print() (use debugPrint())
☐ NO .then() chains (use async/await)
☐ Entities: @immutable, copyWith, ==, hashCode, toString
☐ Doc comments: /// on public APIs
☐ Inline comments: WHY, not WHAT
☐ Error handling: try/catch + rethrow (no silent failures)
☐ Async/await: all async functions have try/catch
☐ Provider invalidation: after mutations
☐ AsyncValue.when: used for all async data
☐ No God Providers (watching too many things)
☐ No magic numbers (use const)

TESTING:
☐ Unit tests for business logic (domain)
☐ Repository tests for queries
☐ Provider tests for state changes
☐ Widget tests for critical screens (loading/error/success)
☐ Test names describe behavior
☐ Arrange/Act/Assert pattern
☐ Single assertion per test (when possible)
☐ Mocks used correctly

SECURITY:
☐ NO secrets hardcoded
☐ Error messages don't leak information
☐ Permission checks present (PermissionResolver)
☐ Data validation present
☐ Rate limiting enforced (LoginAttempts)
☐ Audit logs created (AuditLog)

PERFORMANCE:
☐ No unnecessary rebuilds (ConsumerWidget)
☐ Efficient Drift queries (indexed, .where)
☐ autoDispose used correctly
☐ Listeners disposed properly
☐ Large lists use .map() not for-loop
☐ Provider invalidation strategic (not every frame)

DOCUMENTATION:
☐ Doc comments on public APIs (///)
☐ Complex logic has WHY comments (//)
☐ TODO comments include context
☐ Commit message descriptive
☐ Architecture decision documented
☐ No obvious code without explanation

SYNC & OFFLINE:
☐ SyncQueue entries created for mutations
☐ ref.invalidate() called after mutations
☐ Error handling for sync failures
☐ Offline behavior tested
☐ Retry logic present (if applicable)

SIGN-OFF:
Reviewer: _______________________
Date: _______________________
Title: _______________________
```

---

## 14. Quick Reference

### AI Assignment by Task Type

| Task | Primary | Secondary | Review |
|------|---------|-----------|--------|
| Feature analysis | Claude | Jules | Human |
| Implementation | Gemini | - | Claude |
| Code review | Claude | - | Human |
| Bug fix analysis | Claude | - | Human |
| Bug fix implementation | Gemini | - | Claude |
| Research | Jules | Claude | Human |
| Test generation | Gemini | - | Claude |
| Refactoring plan | Claude | - | Human |
| Refactoring impl | Gemini | - | Claude |
| Documentation | Claude | Jules | Human |

### Typical Workflow Duration

| Phase | Owner | Duration | Status |
|-------|-------|----------|--------|
| Analysis | Claude | 15-30 min | ⏳ |
| Research | Jules | 10-20 min | ⏳ (optional) |
| Human validation | Human | 10-30 min | ✅ |
| Implementation | Gemini | 15-45 min | ⏳ |
| Code review | Claude | 10-30 min | ⏳ |
| Test generation | Gemini | 10-20 min | ⏳ (if needed) |
| Test review | Claude | 5-15 min | ⏳ |
| Human final review | Human | 15-60 min | ✅ |
| Commit | Human | 5 min | ✅ |

**Total:** 1.5 - 4 hours per feature (depending on complexity)

---

**Last Updated:** 2024
**Valid for:** Claude 3.5+, Gemini 2.0+, Perplexity (current)
**Review cycle:** Every major project phase or quarterly