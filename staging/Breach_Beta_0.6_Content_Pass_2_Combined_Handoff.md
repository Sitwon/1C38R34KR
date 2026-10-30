# Breach / 1C38R34KR — Beta 0.6 Content Pass 2
## Combined Content-Agent + System-Architect Handoff

### Purpose

This document is a single handoff for two sequential roles:

1. **Content Agent** — update the working datasheet with the new Effect vocabulary and author the next player/boss content cohort.
2. **System Architect** — use the completed workbook as the authoritative content source and roll the required engine/data/logging changes into the **Beta 0.6 Content Pass 2 requirements document**.

Do not silo the work into separate conceptual systems unless implementation requires it. The intent is to extend the existing data-driven architecture and content vocabulary, not redesign it.

The current build already contains the expanded **Systems, HOSTs, and UPGRADEs** from Content Pass 1. This pass focuses on:

- completing the initial Hacker catalogue;
- completing the initial Deck catalogue;
- creating Program identities/loadouts for the four existing Bosses;
- implementing the already-authored Mine mechanic;
- adding three small reusable Effects: **HEAL**, **SELF_DAMAGE**, and direct **CHARGE**.

This is still an initial content pass, not a balance pass.

---

# 1. Current Content Target

The initial catalogue target is:

- **4 Hackers total**
- **4 Decks total**
- **4 Bosses total**
- **3 Hacker Programs per Hacker**
- **3 Deck Programs per Deck**
- **4 Boss Programs per Boss**

Therefore the intended player-side catalogue is:

- 12 Hacker Program placements;
- 12 Deck Program placements;
- 24 Hacker/Deck Program placements total.

The four Bosses each receive a four-Program identity/loadout:

- ODANSHAY
- RAHNDAHL
- NEHBOCYET
- ECHOFALL

Programs may be shared where appropriate. The goal is distinct encounter/build identity, not maximum unique-row count.

The existing Hacker(s), Deck(s), Programs, Functions, and Boss data count toward these totals. Do **not** interpret this as "add four more Hackers and four more Decks."

---

# 2. Content Design Principles

The content agent should author against the mechanics already available before proposing another Effect.

The existing reusable vocabulary already includes, among other implemented mechanics:

- direct damage;
- match-damage buffs;
- bombs and countdown specials;
- shields;
- drain / charge denial;
- transforms;
- line/column slicing and reroll behavior;
- targeted slicing;
- board shake / reroll;
- board shifting;
- special placement;
- PASSIVE modifiers;
- one-level Function chaining.

The current Function architecture already allows Functions to invoke other Functions one level deep. Called Function costs are ignored under the existing chaining convention. Do not expand chaining depth in this pass.

### Distinct-content rule

A new Program or identity should not exist merely because it has a numerically superior version of another Program using the same Function.

Distinct Programs should differ through at least one meaningful tactical dimension such as:

- effect type;
- trigger/timing;
- targeting;
- board interaction;
- setup/payoff relationship;
- resource tradeoff;
- axis relationship;
- interaction with another Program;
- risk/reward;
- defensive versus offensive purpose;
- Function chaining.

Numerical tuning is allowed and expected, but it should not be the sole reason two normal Programs are considered different content.

### Chaining is a primary content tool

Use Function chaining deliberately to create compound Program identities without expanding the Effect engine unnecessarily.

Examples of the kind of design language chaining can express:

- pay a cost, then gain a stronger effect;
- alter the board, then exploit the altered board;
- defend, then attack;
- disrupt charge, then apply pressure;
- self-damage, then buff;
- self-damage, then directly charge Programs;
- heal, then perform another effect;
- create a special, then manipulate the board around it.

Do not create new Effects solely to avoid using the existing Function-composition system.

---

# 3. New / Newly Implemented Effect Vocabulary

Content Pass 2 adds engine support for four Effects.

One, **MINE**, is already represented in the working datasheet but was added after the last implementation build.

Three are new additions for the content agent to formalize in the workbook:

- `EFFECT_HEAL`
- `EFFECT_SELF_DAMAGE`
- `EFFECT_CHARGE`

The Content Agent should add effect definitions/parameter conventions to the workbook before using them in new Functions.

The exact param encoding should follow the conventions of the current datasheet. Keep parameter lists as small as possible.

---

# 4. EFFECT_MINE

## Status

Mine/VOLATILE content already exists in the working datasheet but is **not implemented in the current game build**.

The current workbook is authoritative for its exact Function values and parameter encoding.

## Design intent

A Mine is a countdown special whose danger is associated with how it is removed rather than simply being another Bomb.

The Mine was introduced specifically to create different board decisions from Bombs: a player may not always want to remove an enemy special through the obvious normal Sync/Slice route.

The architect should implement the existing workbook semantics rather than redesigning Mine during requirements formalization.

If the current workbook distinguishes removal causes, preserve those distinctions. Mine telemetry must identify why the Mine resolved, fizzled, expired, or was removed so later balance analysis can determine whether its tactical behavior is actually occurring.

Do not turn Mine into a generic Bomb alias.

---

# 5. EFFECT_HEAL

## Purpose

Add straightforward owner-side health restoration so sustain/attrition identities do not have to be expressed entirely through Shields.

This Effect should work for either side:

- Hacker owner → restores LINK.
- System/Boss owner → restores ICE.

## Minimum semantic definition

`EFFECT_HEAL` takes a numeric heal amount.

Resolution:

1. identify the Effect owner;
2. restore that owner's current LINK/ICE by the configured amount;
3. cap at that combatant's current maximum LINK/ICE;
4. any amount above the cap is wasted;
5. healing does not damage the opponent and does not create board resolution.

The content agent should encode the amount using the workbook's normal Effect-specific parameter convention.

Do not create overheal, temporary health, regeneration-over-time, resurrection, or max-health increase behavior in this pass.

## Logging

Record at least:

- source Function;
- source Program/Deck/Boss identity;
- side healed;
- health before;
- heal attempted;
- heal actually applied;
- amount lost to max-health cap;
- health after.

This distinction matters for later balance work because a Function that nominally heals 20 but regularly restores only 3 is not delivering 20 points of practical value.

---

# 6. EFFECT_SELF_DAMAGE

## Purpose

Allow LINK/ICE to function as a spendable resource.

The intended use is not merely "another way to take damage." It creates Functions that can be cheaper, faster, or stronger because the acting side also pays health.

Example design pattern:

- a low-charge-cost Function pays LINK in addition to charge;
- in return it immediately creates a stronger buff than a safer equivalent.

Exact values are content/balance data and must not be hardcoded from this example.

## Minimum semantic definition

`EFFECT_SELF_DAMAGE` takes a numeric health-loss amount.

Resolution:

1. apply the configured amount to the Effect owner's LINK/ICE;
2. the Effect can reduce the owner to 0;
3. if the owner reaches 0, normal battle-end resolution occurs immediately;
4. if SELF_DAMAGE is an earlier payload in a chained Function and kills the owner, later payloads do not execute.

### Recommended cost semantics

Treat SELF_DAMAGE as a **resource cost**, not hostile incoming damage:

- it should bypass Shield;
- it should bypass ordinary damage reduction;
- it should not be reflected;
- it should not be credited as opponent damage dealt.

The architect should preserve this distinction in requirements and telemetry unless an existing engine constraint makes it impractical.

## Logging

Record at least:

- source Function;
- source Program/Deck/Boss;
- owner side;
- health before;
- configured self-damage;
- health after;
- whether the cost caused defeat;
- whether a chained payload was aborted because the owner died.

Self-damage must remain distinguishable from opponent damage in battle metrics.

---

# 7. EFFECT_CHARGE

## Purpose

Allow a Function to directly add charge to allied charge-bearing units without requiring Packet destruction or Sync generation.

This creates a new resource-conversion tool and supports a planned Deck identity that converts LINK into immediate Program tempo.

This Effect is **charge generation**, not charge stealing or partial Drain.

## Required immediate use case

At least one Deck should be designed around an active Function with the conceptual structure:

`SELF_DAMAGE → CHARGE`

The Deck pays LINK and then adds direct charge to each of its Programs.

Exact LINK cost, charge cost, charge amount, Function cost, Deck identity, and naming are content decisions for the content agent.

## Minimum semantic definition

`EFFECT_CHARGE` requires:

- numeric charge amount;
- target scope.

The parameter model should remain minimal but should support the required `OTHER_PROGRAMS` / team-Program use case.

A reasonable small scope vocabulary is:

- `SELF` — activating Program only, where applicable;
- `OTHER_PROGRAMS` — allied Programs except the source;
- `ALL_PROGRAMS` — all allied Programs;
- `TARGETED_PROGRAM` — one explicitly selected allied Program, only if a content design actually needs this.

Do not implement unused target scopes merely for theoretical completeness. The content agent should only add scopes actually required by authored content.

For the planned Deck active, charge should go to the Deck owner's Programs and not back into the Deck Function itself.

## Direct-charge routing rule

Direct Function-generated charge is not ordinary match-generated charge.

For each target Program:

1. add the configured amount directly;
2. cap at that Program's charge capacity;
3. discard excess for that target;
4. do **not** send excess through normal color/shape match-charge overflow routing.

This avoids surprising secondary routing and makes the Function's value readable.

## Activation timing

Normal Function timing applies.

Because Hacker Functions are used before the Hacker's normal Sync, direct charge may make Programs ready during the pre-Sync Function phase.

The architect must preserve the existing rule governing whether newly ready Programs can be fired in that same Function phase. Do not silently introduce a new restriction or a new extra-action phase.

## Logging

Direct charge needs explicit telemetry because nominal generated charge and usable charge can differ substantially.

Record at least:

- source Function;
- source Deck/Program/Boss;
- owner side;
- target scope;
- charge amount offered per target;
- each target Program ID;
- target charge before;
- charge accepted;
- target charge after;
- charge discarded because of cap.

Do not report attempted charge as though all of it was successfully gained.

Direct Function charge should be distinguishable from Sync/cascade/Effect-destruction charge sources in logs.

---

# 8. Content Agent Work — Hackers

Author enough Hacker content to reach **4 Hackers total**.

Each Hacker contributes **3 Programs** under the existing architecture.

Each Hacker should have a recognizable mechanical identity. The three Programs should feel like parts of that identity rather than three unrelated abilities.

Use the enlarged Effect vocabulary, Function chaining, axes, PASSIVEs, and existing mechanics to differentiate them.

Possible identity dimensions include, but are not limited to:

- direct aggression;
- board manipulation;
- sustain;
- risk/reward;
- health-as-resource;
- charge acceleration;
- special-Packet management;
- setup/payoff;
- defensive control.

Do not require each Hacker to use a new Effect.

Do not make a Hacker's identity simply "same Programs but larger numbers."

The existing Hacker remains part of the four-Hacker catalogue.

---

# 9. Content Agent Work — Decks

Author enough Deck content to reach **4 Decks total**.

Each Deck contributes **3 Programs** and retains its existing Deck-level active Function structure.

Deck identity should complement Hacker identity rather than duplicate it. A Deck should materially change the build possibilities available to the selected Hacker.

At least one newly authored Deck should use the health-for-charge concept:

- Deck active pays LINK via `EFFECT_SELF_DAMAGE`;
- then adds direct charge to its Programs through `EFFECT_CHARGE`;
- exact values are tunable workbook data.

The intent is to create a Deck that converts survivability into tempo.

Because the player selects Hacker and Deck separately, avoid making any Deck useful only with one specific Hacker. Strong synergies are desirable; mandatory pairings are not.

The existing Deck remains part of the four-Deck catalogue.

---

# 10. Content Agent Work — Boss Program Identities

The four Bosses already have bespoke encounter mechanics:

- **ODANSHAY** — Override accumulation / threshold punishment.
- **RAHNDAHL** — Capacitor accumulation with exponential damage.
- **NEHBOCYET** — descending Logic Bomb positional threat.
- **ECHOFALL** — alternating hidden-axis sensory/shell-game mechanic.

Content Pass 2 gives each Boss a four-Program loadout/identity.

The Boss Programs should **reinforce or complicate the existing boss mechanic**, not replace it.

The boss mechanic remains the primary encounter identity.

Examples of appropriate relationships:

- Programs that create pressure while the player manages the boss's special mechanic;
- Programs that alter the board in ways that make the boss mechanic harder to control;
- Programs that provide sustain or defense while the special mechanic matures;
- Programs that exploit axes or board states naturally produced by the boss;
- Programs that introduce an intentional tradeoff between addressing Programs and addressing the boss mechanic.

Programs may be shared between Bosses or with normal Systems when appropriate.

Do not force all four Boss Programs to be unique.

Do not create new bespoke Effects merely to make each Boss Program novel. The bespoke boss mechanics already carry the unique encounter engineering.

---

# 11. Interaction Expectations

Content should be authored against the broader catalogue now present in the build.

The player should encounter meaningful interactions among:

- Hacker;
- Deck;
- active four-Program build;
- System;
- HOST;
- acquired UPGRADEs;
- Boss;
- Boss Programs.

The content agent should prefer designs whose value changes contextually rather than universally.

Examples:

- a heal Program becomes more valuable in a self-damage build;
- direct charge is more valuable with expensive or strategically important Programs;
- direct charge can waste value when Programs are already near cap;
- Mines can change which removal mechanisms the player values;
- HOSTs that affect countdowns can change the value of countdown-based Programs;
- match-damage HOSTs can favor buff-heavy builds;
- board-transform HOSTs can help one Hacker/Deck combination more than another.

The goal is combinatorial interaction, not a flat list of independent abilities.

---

# 12. Balance Policy

Do not attempt final balance in this pass.

Values should be plausible enough to allow normal human play and expose each identity, but the current objective is to get the full initial content catalogue into the game so balance can be assessed against actual combinations.

Do not reject an otherwise useful identity because its first-pass numbers are obviously imperfect.

Do avoid values that make content impossible to exercise in ordinary testing.

This pass should preserve the established design principle:

> content should differ tactically first; numerical balance comes after the catalogue exists.

---

# 13. Content Agent Deliverable

The Content Agent's completed workbook should contain:

1. formal definitions/parameter conventions for:
   - `EFFECT_HEAL`
   - `EFFECT_SELF_DAMAGE`
   - `EFFECT_CHARGE`

2. the existing Mine/VOLATILE data retained and clarified where needed;

3. Functions that use the new Effects where appropriate;

4. enough Hacker rows to reach 4 Hackers total;

5. enough Hacker Program rows to support 3 Programs per Hacker;

6. enough Deck rows to reach 4 Decks total;

7. enough Deck Program rows to support 3 Programs per Deck;

8. at least one Deck active implementing the SELF_DAMAGE → CHARGE concept;

9. four-Program loadouts/identities for:
   - ODANSHAY
   - RAHNDAHL
   - NEHBOCYET
   - ECHOFALL;

10. any new PASSIVE rows genuinely required by those identities;

11. notes sufficient for the architect to understand unusual Function chains or parameter semantics.

The workbook, once returned by the content agent, becomes the authoritative content source for the architect.

---

# 14. System Architect Work

After the content workbook is complete, roll it into the **Beta 0.6 Content Pass 2 requirements document**.

Treat this as a delta against the working Beta build.

The architecture task is primarily:

- implement `EFFECT_MINE` according to the workbook's existing semantics;
- implement `EFFECT_HEAL`;
- implement `EFFECT_SELF_DAMAGE`;
- implement `EFFECT_CHARGE`;
- add/extend validation for their parameters;
- extend logging/metrics attribution;
- load the newly authored Hacker/Deck/Boss/Program/Function/PASSIVE content;
- preserve existing Function chaining;
- preserve existing save/content-fingerprint behavior;
- ensure newly authored content works in the existing selection/build/run/boss flows.

Do not redesign Systems, HOSTs, UPGRADEs, run structure, boss mechanics, or the presentation layer in this pass.

---

# 15. Architect — Validation Requirements

The requirements should define startup validation for the new Effect parameters.

At minimum:

### HEAL
- amount is present;
- amount is numeric/integer according to current Function parameter convention;
- amount is non-negative.

### SELF_DAMAGE
- amount is present;
- amount is numeric/integer;
- amount is non-negative.

### CHARGE
- amount is present;
- amount is numeric/integer;
- amount is non-negative;
- target scope is a supported authored scope;
- unsupported scope values invalidate the row.

### MINE
Use the completed workbook definition as authoritative and validate every required Mine parameter.

Continue rejecting invalid content rows using the project's existing validation policy rather than silently substituting defaults.

---

# 16. Architect — Save / Resume

No new save system is required.

Any persistent combat state introduced by the new content must serialize through the existing battle/run state.

At minimum verify:

- Mine specials survive save/resume with correct state;
- current LINK/ICE after HEAL/SELF_DAMAGE is preserved normally;
- Program charge created by EFFECT_CHARGE is preserved normally;
- newly selected Hacker/Deck IDs and builds survive normal run persistence;
- Boss Program state survives boss-battle resume.

Do not create parallel persistence structures for these Effects.

---

# 17. Architect — Logging / Metrics

Extend the existing event/logging pipeline rather than creating a new one.

Required distinctions:

### HEAL
Track attempted versus actually applied healing.

### SELF_DAMAGE
Track self-inflicted health loss separately from opponent-caused damage.

### CHARGE
Track offered, accepted, and discarded direct charge by target Program and source.

### MINE
Track placement, state changes, removal/trigger cause, damage, expiration/fizzle behavior, and source attribution according to the workbook semantics.

The current telemetry architecture already distinguishes charge sources and damage causes. Extend those concepts rather than flattening the new Effects into generic totals.

The purpose of this logging is later content/balance analysis. It should be possible to answer questions such as:

- How much practical healing did this Program provide?
- How much LINK did a self-damage build spend?
- How much direct charge did a Deck attempt versus successfully deliver?
- Which Programs received that charge?
- How often did Mine hazards actually trigger through their intended removal condition?
- How much damage came from Mines versus ordinary Bombs or attacks?

---

# 18. Architect — Required Functional Tests

The Beta 0.6 Content Pass 2 requirements should include automated or deterministic coverage for at least:

1. HEAL restores owner health.
2. HEAL cannot exceed maximum health.
3. HEAL records attempted and applied values correctly.
4. SELF_DAMAGE reduces owner health.
5. SELF_DAMAGE can defeat the owner.
6. lethal SELF_DAMAGE aborts later chained payloads.
7. SELF_DAMAGE remains separately attributed from opponent damage.
8. CHARGE adds the configured amount directly to valid targets.
9. CHARGE respects per-Program caps.
10. excess direct charge is discarded rather than routed through normal match overflow.
11. Deck health-for-charge active damages LINK then charges the intended Programs.
12. lethal self-damage prevents its subsequent CHARGE payload.
13. direct charge logs target-by-target before/accepted/after/discarded values.
14. MINE behaves according to the authoritative workbook definition.
15. Mine removal/trigger causes are distinguishable in logs.
16. existing one-level Function chaining continues to work.
17. new Hacker content loads and can enter the Build.
18. new Deck content loads and contributes its Programs/active Function correctly.
19. each Boss loads its authored four-Program identity.
20. boss bespoke mechanics continue working with the new Program loadouts.
21. existing Systems/HOSTs/UPGRADEs remain unaffected.
22. save/resume preserves the new Effect states.

---

# 19. Human Verification Target

This pass does not require exhaustive balance testing.

Tier-1 human verification should establish:

- all new Hacker selections can start and complete a Run;
- all new Deck selections can start and complete a Run;
- new Programs visibly perform the authored behavior;
- health-cost Functions clearly reduce LINK;
- HEAL visibly restores the correct side;
- the health-for-charge Deck produces immediately understandable Program-charge changes;
- Mines create the intended board decision rather than behaving like ordinary Bombs;
- each Boss's four-Program loadout feels coherent with its bespoke mechanic;
- no new content breaks normal route/HOST/UPGRADE behavior;
- no showstopper save/resume or logging regression occurs.

Balance anomalies should be recorded but should not trigger broad retuning during implementation unless they prevent meaningful testing.

---

# 20. Explicitly Out of Scope

Do not expand this pass into:

- final balance;
- broad numerical tuning of existing content;
- additional System/HOST/UPGRADE catalogue expansion;
- System escalation / upgraded Program revisions;
- new alternate win conditions;
- new Function-chaining depth;
- generic packet freeze/lock;
- generic reflection/thorns;
- charge stealing/siphoning;
- clone/copy-special mechanics;
- new gravity mechanics;
- art/layout redesign;
- audio implementation;
- content-pipeline migration to JSON/XML;
- in-game editor tooling;
- presentation jig work.

Those remain later work unless implementation reveals a true dependency.

---

# 21. Completion Standard

Beta 0.6 Content Pass 2 is feature-complete when:

- the initial catalogue contains 4 Hackers, 4 Decks, and the existing 4 Bosses;
- each Hacker has its authored 3-Program contribution;
- each Deck has its authored 3-Program contribution and Deck active;
- all four Bosses have authored four-Program identities/loadouts;
- MINE is implemented;
- HEAL is implemented;
- SELF_DAMAGE is implemented;
- direct CHARGE is implemented;
- Function chaining supports the authored combinations without expansion of chain depth;
- new content validates and loads from data;
- new Effects are correctly persisted and logged;
- existing Systems/HOSTs/UPGRADEs and boss mechanics continue to work;
- a normal human Run can exercise the new content without a showstopper.

After this pass, the game should have enough initial content breadth on both player and opponent sides to begin meaningful combination testing and later balance work without requiring another immediate Effect-expansion phase.
