# Build loop: resume, focus, land

Updated 2026-11-24. Integration umbrella: [#266](https://github.com/RktRobinhood/wasteland-academy/issues/266). Product target: [charter](PRODUCT-CHARTER.md). Vocabulary: [domain glossary](DOMAIN-GLOSSARY.md). Authority and OPEN choices: [decision register](DECISION-REGISTER.md). Evidence: [current audit](ALIGNMENT-AUDIT-2026-11-24.md).

## Every fresh or interrupted agent

1. Fetch `origin`; inspect `git status`, current branch, `git worktree list`, open PRs and the selected issue's latest comments. Read current `origin/main:AGENTS.md` and this queue before resuming an old prompt. Preserve local work; do not reset or blindly pull over it. The November 21 ZIP and older Paperclip task briefs do not describe current implementation status.
2. If an integration PR is open, finish its review/checks/conflicts or record a concrete blocker before starting another implementation branch. Name one integration owner on the issue. Use `codex/` for new branches unless the host's established branch naming is required. Start from current main; an existing branch is reusable only after checking its scope and newer changes.
3. Pick the first eligible bounded slice below. Post an issue checkpoint: accepted scope/ADR, branch, base SHA, acceptance criteria, checks planned and any owner decision dependency. Link the Paperclip task when known. A task existing on Paperclip is not evidence that its design was accepted.
4. Work to the observable acceptance criteria. Record actual test commands and outcomes, including known failures and human review still missing. A blocked design question does not block independent approved fixes; choose the next eligible slice and record why.
5. Review the final diff; update from main without losing newer work; resolve conflicts and run relevant checks. Merge when ready through normal protections. `Closes` applies only to fully satisfied issues; otherwise use `Refs` and list the remainder. Update this queue and the issue with the main commit. Do not stop at a completed unmerged branch.

## Current queue

Only **one implementation/integration PR at a time**. Design and owner review can wait independently; this is not permission to launch parallel feature agents. Existing correctness defects take precedence when discovered.

| Order | Work / issue | Next bounded deliverable | Dependency / stop condition |
|---|---|---|---|
| 0 — complete | Direction adoption, #266 / #204 | Landed in #270 as `fc357b0`: charter, glossary, seven ADRs, audit, queue and reconciled entry points | All PR checks and main test/deployment workflows subsequently passed. Skip this step; gameplay acceptance remains open |
| 1 | Classroom correctness/accessibility, #193 / #196 / #187 | Finish one recorded defect or keyboard gap; collect real-device evidence using `game/docs/DEVICE-CHECKLIST.md` | #265 is merged and its CI is green. Real devices and complete keyboard acceptance remain; never report those as done from WebKit alone |
| 2 | Exact active run, [#267](https://github.com/RktRobinhood/wasteland-academy/issues/267), ADR-0003 | First PR: versioned snapshot and exact restore with reward/evidence safety; then course Settings/inert scenery if a separate slice is needed | Inspect existing banking and quit/back semantics. Preserve hidden-tab pause. Ask only for unresolved recovery semantics |
| 3 | Mastery calibration, [#268](https://github.com/RktRobinhood/wasteland-academy/issues/268), ADR-0002 | Reviewable formula, deterministic learner trajectories, migration/selection plan | Proposal is authorized; shipping numeric calibration and no-attempt floor needs recorded owner acceptance |
| 4 | Encounter/story audit, [#269](https://github.com/RktRobinhood/wasteland-academy/issues/269), ADR-0005–0007 | Inventory current content/assets/runtime; minimal compatibility proposal; 2–3 story-to-mile options and one recommended region | Audit can proceed while mastery awaits review; story graph, tuning and content choices remain open |
| 5 | Optional learning support, #215 / #218 / #222 / #223 / #224 | Validate the existing interactive exemplar, finish required prototype work, deliver a playable owner review; reuse existing scripts/player | No bulk recording; unapproved $120 cap withdrawn. Owner prototype review and approved budget precede paid production/rollout |
| 6 | Implement accepted follow-ups | Skill evidence/selection then dashboard/bounties; representative encounter/status slice; one permanent regional story victory with finish/continue and PBs | Split into small issues after prerequisite proposals are accepted. Then replicate approved behavior across all five AA SL zones |
| 7 | Complete AA SL release gate, #266 | Review structural maths breadth/signoff, required explainers accessible before failure, five-zone stories, assets/audio, accessibility and classroom play | Character/economy/Thunderdome tuning remains explicit; follow ADRs without inventing numbers. No coverage percentage substitutes for evidence |

The queue is ordered by dependency and integration focus, not a mandate to wait idle for a person. If row 1 needs a real device, row 2 can proceed. If row 3 awaits calibration approval, row 4's audit or an existing approved defect can proceed. Write the reason and selected slice on #266.

## Preserve and defer

- HL/AI modelling and inequality branches: preserve them, but do not restart bulk builders. Assess later against the AA SL milestone and their actual tests. Existing course filters and shared IDs stay supported.
- #134: preserve the existing MathsEngine and study consumer; neutral-context/bank integration remains open, not a separate product to ship now.
- #13: retain Relic research/prototypes; ordinary optional help must not be gated on completing another mode. Existing interactive explainer work under #215 is still approved and should reuse its player.
- #199: PC then Android/iOS remains the later platform sequence. #202 sync and #133 telemetry stay deferred. Keep existing #201/#226 art direction within the owner art workflow.
- The old whole-map voice estimate on `fal-1035-voice-cap` is not spending approval; use #224's interactive-format tiers and #222's prototype gate.

## Interruption checkpoint

Before stopping, put this on the working issue (and the linked Paperclip task if accessible):

```text
Integration owner / issue / Paperclip task:
Branch / base main SHA / latest commit or uncommitted files:
Accepted scope and governing ADR:
Completed acceptance evidence and exact checks:
Remaining work / failing checks / OPEN decision:
Next concrete action:
PR URL / merged main SHA (only if actually merged):
```

A resumed agent reads current main guidance before trusting that checkpoint. If it cannot reach Paperclip, update GitHub and say so; do not invent a task state or claim the scheduler was reconfigured. Repository adoption is sufficient for agents that fetch and read the repository; an already-running agent with stale context must refresh it.
