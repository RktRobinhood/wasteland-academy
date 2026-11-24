# ADR-0006: Event-driven regional stories and recurring villains

- Status: **Accepted narrative principles; exact encounter graphs and content OPEN**
- Decision date: 2026-11-21 (owner grilling session, continued after original audit)
- Depends on: ADR-0001, ADR-0002, ADR-0003, ADR-0005

## Context

The owner wants regional adventures with real narrative payoffs, without turning mathematics into compulsory reading or locking experienced learners behind unnecessary question grind. Some regions may have within-zone prerequisites, but most exploration is flexible. Existing repeating floor/mile boss structure needs reconciliation with a deliberately authored regional story climax.

## Accepted decisions

1. **Narrative progression and mathematical mastery are distinct state tracks.** A strong learner arriving from Thunderdome may progress through mathematical challenges quickly but has not automatically experienced or completed the regional story. Their existing mastery should reduce unnecessary maths grinding; it must not automatically award a narrative victory.
2. **Minimum narrative arc: roughly three beats:** antagonist/challenge introduction, complication/escape/change of stakes, final confrontation/resolution. The owner accepted three beats as a sensible *minimum*, not a requirement to force every region into an identical script or linear sequence. Additional varied encounters occupy the space between them.
3. **Event-driven story eligibility:** track permanent narrative flags (e.g. villain met, trap triggered, escape, rescue, special victory, final showdown). Other encounters may occur out of order if their individual prerequisites are satisfied. The final confrontation requires the necessary narrative milestones and appropriate mathematical progress; the exact gate math/content still needs approval.
4. **Boss villains should be worth defeating.** They are malicious, arrogant, absurdly self-important, cruel, annoying or cheekily antagonistic, with appropriate humorous jabs/taunts. Narrative defeat is satisfying. Do not make every entity a villain: many major encounters are hazards, machines, creatures or accidents and need little/no dialogue.
5. A boss can have **phases and branches** reflecting what happened: e.g. villain turns on robots and escapes, a mech is broken and the pilot continues on foot, or an overpowered player defeats a phase unexpectedly early. Writer-authored conditionals are allowed within approved mechanics; do not require expensive unique engine paths per branch.
6. **Fail-forward:** an unsuccessful encounter can change story state, trigger a setback or a later opportunity; it should not create permanent unwinnable locks. Mathematical failure still has combat/survival cost and evidence implications.
7. **Defeated regional villains can become eligible Thunderdome opponents** as a post-victory roster unlock. Their arena appearance may have different, cheekier lines and altered mechanics; the lore explains a return without erasing permanent regional victory.
8. **Thunderdome baseline roster** should be predominantly robots, creatures and arena brawlers rather than a huge cast of bespoke talkative antagonists. The regional villain additions create crossover flavor. Content can reuse models/rigs within acceptable quality standards.
9. **Voice is selective.** The user values locally generated voice acting for memorable character arcs and conditional dialogue, but does not want every trap, creature, robot or routine encounter to require a large voiced script. Use animation, VFX, sound and environmental storytelling wherever appropriate.
10. Existing map assets are canonical. Reuse the five regional identities; do not reassign mathematics to unrelated scenery or invent cross-zone prerequisite gates.

## Narrative and run lifecycle

- A regional boss **story victory** is permanent, secured immediately when earned. The player chooses to end the run or continue non-narrative practice/high-score pursuit. Later death cannot revoke that victory, secured Scrap or story flags.
- Sufficient prior skill evidence may accelerate mathematical pacing and fulfill specific in-zone skill gates. It does **not** auto-complete story beats.
- Thunderdome remains open independently of overworld narrative progression. Unlocking a defeated villain into its arena pool is an additive reward, **not** an eligibility restriction on Thunderdome itself.
- Raider Attention bosses remain intentionally recurring and can flee after a victory, with attention reset. Do not mistakenly treat a repeatable raider event as the one-time regional story climax unless the owner explicitly decides so.

## Open owner approval questions

1. How do existing miles/stops/floors and their repeating boss encounters map onto **region completion**? Propose 2-3 options after reviewing actual Godot state and content. Do not silently designate every tenth encounter as an adventure ending.
2. For the first regional vertical slice, which named antagonist, intro/escape/climax scenes, supporting noncombat encounters and reward will be used?
3. What minimum mathematical evidence must be present before final confrontation: selected content breadth, specific skill milestones, or an authored readiness check? Preserve freedom to explore and play at current mastery.
4. Which existing villain IDs and assets are used in Thunderdome post-victory, and how do duplicate appearances avoid story contradictions?
5. Which conditional voice lines are truly necessary? The writer can prepare drafts before audio production; do not mass-produce voice assets before content signoff.

## Required acceptance checks

- Event flags survive app closure, character change, course switching and death according to existing save rules.
- High-mastery arrival advances mathematical selection without skipping unplayed narrative flags.
- Alternate encounter ordering never deadlocks the story; event transitions remain deterministic under a seed where applicable.
- First meeting, escape, early overpowered defeat and final victory have coherent, testable outcomes without duplicating question machinery.
- A regional villain defeated in the Overworld can appear in Thunderdome's **eligible pool** without being guaranteed every run; no villain unlocked by mere test-out.
- Humans review boss personality, age appropriateness, tone, art and spoken-line quality; the code passing does not imply a good story.
