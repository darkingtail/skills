# gh-star-list Redesign

## Context

The original `gh-star-list` skill focused on classifying GitHub starred repositories into GitHub Lists. That solved organization, but not the user's real problem: many starred projects were only briefly inspected at star time and never revisited. A pure classifier can make the list tidier while still leaving the collection as a passive archive.

## Design Goal

Turn GitHub stars into a reviewable personal backlog. The skill should help decide what is useful, what deserves a trial, what is stale, and what can be removed from attention.

## Core Model

The redesigned workflow treats every repo as one of four states:

| State | Meaning | Typical list |
| --- | --- | --- |
| Inbox | recently starred or never reviewed | `Inbox` or uncategorized |
| Keep | known useful and worth keeping visible | purpose-based list |
| Trial | interesting but not yet understood | `To Try` |
| Freeze | stale, replaced, weak signal, or low relevance | `Cold Storage` |

This changes the agent's job from "find a category" to "make a practical judgment."

## Workflow

1. Choose the smallest useful working set.
2. Fetch stars and existing lists with the bundled scripts.
3. Score each repo by purpose, personal relevance, actionability, quality, freshness, and redundancy.
4. Present a batch triage table with `Keep`, `Trial`, `Freeze`, or `Unstar candidate`.
5. Map approved repos to purpose-based GitHub Lists.
6. For freeze or unstar candidates, optionally search for active alternatives.

## Important Decisions

- Default vague requests to latest 20 stars, not a full audit. Full audits are expensive and tend to stall.
- Classify by purpose instead of programming language unless the user explicitly asks for language lists.
- Preserve confirmation gates before moving, freezing, or unstarring anything.
- Keep GitHub Lists under the 32-list platform limit.
- Use `Cold Storage` instead of immediate unstar as the safe default for uncertain cases.

## Non-Goals

- Do not auto-unstar repositories.
- Do not auto-star alternatives.
- Do not judge staleness only by last push date. Fonts, specs, books, tutorials, and mature tools can be quiet but still valuable.

## Follow-Ups

- Add a local review ledger if GitHub Lists are not enough to track "reviewed at" and "why kept."
- Add a script mode that exports a full review report without mutating GitHub Lists.
- Consider a `Trial` follow-up workflow that reminds the user to actually inspect selected repos later.

