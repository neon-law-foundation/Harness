# Roadmap: Convert question_type to Postgres Enum

## Goal

Convert the `question_type` column in the `questions` table from a plain
`string` to a Postgres native enum type, and update the `Question` model to
use `@Enum` instead of `@Field`.

## Prior Art

`respondent_type` (notations table) and `state` (assigned_notations table)
already use this pattern — `database.enum(...)` in migrations and `@Enum` in
the model. SQLite tests pass because Fluent's enum abstraction maps to text on
SQLite.

## Current State

- `question_type` column: `.string` (plain text)
- `Question.questionType`: `@Field(key: "question_type") var questionType: QuestionType`

## Steps

### Step 1 — Migration: create enum type and convert column

Create `Sources/HarnessDAL/Migrations/<timestamp>_ConvertQuestionTypeToEnum.swift`.

- Define the Fluent enum with all 18 current `QuestionType` cases using
  `database.enum("question_type").case(...).create()`
- Drop the existing string column
- Re-add the column using the new enum type

Dropping and re-adding is safe because:

- The column stores raw values identical to Swift raw values (e.g. `"yes_no"`)
- No data loss risk when the table is populated only by seeds (re-runnable)

Revert: delete the column, then delete the enum type.

### Step 2 — Update `Question` model

In `Sources/HarnessDAL/Models/Question.swift`:

- Change `@Field(key: "question_type")` → `@Enum(key: "question_type")`

### Step 3 — Register migration

In `Sources/HarnessDAL/DatabaseConfiguration.swift`, append
`ConvertQuestionTypeToEnum()` to the `migrations` array (after
`CreateQuestions()`).

### Step 4 — Verify

```bash
cd ~/Trifecta/NLF/Harness
swift build
swift test
```

## Out of Scope

- Dali (`Sagebrush/Apple`) has its own `questions` table and `Question` model —
  that is a separate session
- Adding new `QuestionType` cases (the NotationEngine absorption plan) is a
  separate PR; new cases require an additional `ALTER TYPE question_type ADD VALUE`
  migration at that time
