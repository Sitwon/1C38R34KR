# 1C38R34KR Beta 0.5.0 — Initial Content Expansion
## Build Authorization

**Build identity:** `beta-0.5.0`  
**Purpose:** ingest the first broad authored content tranche after the Boss pass, expand the ordinary System/HOST/UPGRADE pools to their initial intended breadth, implement the new VOLATILE/MINE special and new PASSIVE behaviors required by that content, and prove the existing gameplay/presentation architecture can carry the larger content set without another foundational rewrite.  
**Engine:** Godot 4.7.2, standard/non-Mono  
**Language:** GDScript  
**Primary platform:** Android portrait  
**Status:** authorized for implementation. No separate design-document gate is required.

---

## 0. Intent

Beta 0.4 concentrated on Bosses because they were the most mechanically involved content and therefore the most likely to expose missing gameplay primitives.

Beta 0.5 is the first broad **ordinary-content pass**.

The supplied workbook expands the current game to:

- **10 ordinary Systems in the random pool, plus DOORMAN** as the fixed introductory System;
- **10 HOSTs total**, with THRESHOLD remaining the fixed/non-random introductory HOST;
- **10 UPGRADEs**;
- 26 System Programs total;
- 40 Functions total;
- 20 PASSIVE definitions total.

Most of the new Programs are new compositions of mechanics the engine already has. The build should therefore remain primarily a content-ingestion pass, not an excuse for broad refactoring.

The notable implementation work is concentrated in:

1. `EFFECT_MINE`, used by `FNC_023 VOLATILE`;
2. new PASSIVE effect types and one extension to an existing PASSIVE;
3. `EFFECT_TRANSFORM` producing `NEU` as a result;
4. sequential direct-Effect payloads such as `EFFECT_ATTACK:EFFECT_BOMB`;
5. the larger content pools, text registry, logging/metrics, save state, and validation consequences.

**Do not balance by intuition during implementation.** The workbook values are authored content. This build proves that the content works; broad balance tuning comes later from play/log data.

---

# 1. Authority and precedence

Use sources in this order:

1. **This authorization** for mechanics and implementation semantics introduced or clarified here.
2. The supplied workbook `breach-datastructures-working(2).xlsx` for current authored content values and references.
3. The shipped/current Beta 0.4 repository and runtime behavior.
4. `decisions.md`, `architect-notes.md`, `lessons-learned.md`, and current handbacks.
5. Alpha only as a reference for inherited mechanics where current Beta content has not deliberately diverged.

Within the workbook:

- structured gameplay columns are authoritative for values;
- `param notes`, `dataset notes`, and `gameplay conventions` define the authored data contract;
- per-row `notes` are explanatory/non-normative unless this authorization explicitly adopts the behavior they describe.

If a prose note and structured fields disagree, **do not silently edit the structured data to make the note true**. Implement the structured fields, report the contradiction in the handback, and leave balance/content correction to the director unless the row is impossible to execute.

The workbook is the authoring source. Do not leave durable content fixes only in `data/*.csv`.

Run the workbook export/check path after workbook-affecting changes.

---

# 2. Content delta from the previous ordinary-content baseline

The previous ordinary-content baseline contained:

- `SYS_01` BOUNCER
- `SYS_02` MIDNIGHT
- `SYS_03` DOORMAN
- HST_01–HST_05
- UPG_01–UPG_04
- PRG_S_001–PRG_S_008
- FNC_001–FNC_022 after the Boss-support additions
- PSV_001–PSV_009

The supplied workbook now adds:

### Systems

- `SYS_04 SAPPER`
- `SYS_05 MAMMOTH`
- `SYS_06 ARCHON`
- `SYS_07 HARRIER`
- `SYS_08 GNAT`
- `SYS_09 LEECH`
- `SYS_10 STATICIAN`
- `SYS_11 ORCHID`

It also intentionally changes the authored strong color/shape sets of `SYS_01`, `SYS_02`, and `SYS_03`. The current workbook wins. Do not restore the older strong sets to preserve Alpha parity.

### System Programs

Add `PRG_S_009` through `PRG_S_026` exactly as authored.

### Functions

Add `FNC_023` through `FNC_040` exactly as authored.

### HOSTs

Add:

- `HST_06 FLOORIT`
- `HST_07 MEGATON`
- `HST_08 REDSHIFT`
- `HST_09 ACID`
- `HST_10 FURNACE`

### UPGRADEs

Add:

- `UPG_05 EDGE`
- `UPG_06 DYNAMO`
- `UPG_07 CERULEAN`
- `UPG_08 GOLDRUSH`
- `UPG_09 HAIRTRIGGER`
- `UPG_10 BULWARK`

### PASSIVEs

Add `PSV_010` through `PSV_020`.

Three of those rows are currently authored but unreferenced by HST/UPG content:

- `PSV_018 PSV_COUNTDOWN_ADJUST 1 ENEMY`
- `PSV_019 PSV_EXTRA_MATCH_CHARGE GRE:1 OWNER`
- `PSV_020 PSV_STRONG_SLICE_BONUS 1 OWNER`

They are still part of the authoritative PSV dataset and must parse/validate/resolve correctly. Do not invent current content references merely to exercise them.

---

# 3. Pool composition and Run rules

## 3.1 Systems

`in_pool` blank/default remains **yes**.

`SYS_03 DOORMAN` remains `in_pool=n`.

Therefore the random ordinary-System pool must contain exactly **10** Systems:

- BOUNCER
- MIDNIGHT
- SAPPER
- MAMMOTH
- ARCHON
- HARRIER
- GNAT
- LEECH
- STATICIAN
- ORCHID

DOORMAN remains outside that random pool.

## 3.2 HOSTs

`HST_01 THRESHOLD` remains `in_pool=n`.

The other nine HOSTs are available to the ordinary pool.

## 3.3 UPGRADEs

All ten current UPGRADE rows are valid Run rewards.

Preserve the existing rules:

- an acquired UPGRADE cannot be acquired again;
- offers within one choice are unique when the remaining pool is large enough;
- when remaining eligible UPGRADEs are fewer than the number of route choices, duplicate offers across choices are allowed under the existing exhaustion rule;
- the acquired list remains ordered/persisted as currently defined.

## 3.4 First battle convention

Preserve the current Run convention:

- an UPGRADE choice occurs before Battle 1;
- Battle 1 uses `SYS_03 DOORMAN`;
- Battle 1 uses `HST_01 THRESHOLD`.

The enlarged pools must not accidentally make DOORMAN or THRESHOLD random Battle-1 selections.

---

# 4. Current System roster

The runtime should consume these loadouts from the workbook rather than duplicating them in code.

| ID | Name | Programs |
| --- | --- | --- |
| SYS_01 | BOUNCER | PRG_S_003, PRG_S_005, PRG_S_006, PRG_S_001 |
| SYS_02 | MIDNIGHT | PRG_S_007, PRG_S_008, PRG_S_001, PRG_S_002 |
| SYS_03 | DOORMAN | PRG_S_001, PRG_S_002, PRG_S_003, PRG_S_004 |
| SYS_04 | SAPPER | PRG_S_009, PRG_S_004, PRG_S_001, PRG_S_002 |
| SYS_05 | MAMMOTH | PRG_S_010, PRG_S_011, PRG_S_012, PRG_S_013 |
| SYS_06 | ARCHON | PRG_S_014, PRG_S_015, PRG_S_016, PRG_S_017 |
| SYS_07 | HARRIER | PRG_S_018, PRG_S_019, PRG_S_006, PRG_S_001 |
| SYS_08 | GNAT | PRG_S_020, PRG_S_007, PRG_S_008, PRG_S_002 |
| SYS_09 | LEECH | PRG_S_021, PRG_S_009, PRG_S_002, PRG_S_004 |
| SYS_10 | STATICIAN | PRG_S_022, PRG_S_026, PRG_S_025, PRG_S_004 |
| SYS_11 | ORCHID | PRG_S_023, PRG_S_024, PRG_S_006, PRG_S_002 |

All `BASE_ICE` values remain the workbook values; current ordinary Systems are 100 before Run escalation.

Do not redesign the System AI for these loadouts. They use the existing deterministic System Function phase and targeting rules.

---

# 5. New Function content

All new Function rows must use the existing Program → Function → Effect architecture.

Do not hardcode behavior by Program/System name when an authored Function/Effect already represents it.

The new Function tranche is:

| ID | Name | Payload |
| --- | --- | --- |
| FNC_023 | VOLATILE | EFFECT_MINE |
| FNC_024 | TUSK | EFFECT_ATTACK |
| FNC_025 | STOMP | EFFECT_ATTACK:EFFECT_BOMB |
| FNC_026 | THICKHIDE | EFFECT_SHIELD |
| FNC_027 | FORAGE | FNC_028:FNC_029 |
| FNC_028 | FORAGECOLOR | EFFECT_TRANSFORM |
| FNC_029 | FORAGESHAPE | EFFECT_TRANSFORM |
| FNC_030 | SHELL | EFFECT_BOMB |
| FNC_031 | SIGHT | EFFECT_TRANSFORM |
| FNC_032 | SPOTTER | EFFECT_LINESLICE |
| FNC_033 | RAGE | EFFECT_ATTACK |
| FNC_034 | FRENZY | EFFECT_BUFF |
| FNC_035 | PEPPER | EFFECT_BOMB |
| FNC_036 | DRIP | EFFECT_ATTACK |
| FNC_037 | SMOG | EFFECT_TRANSFORM |
| FNC_038 | STATIC | EFFECT_SHAKE |
| FNC_039 | BLOOM | EFFECT_TRANSFORM |
| FNC_040 | NECTAR | EFFECT_BOMB |

All costs, quantities, countdowns, areas, magnitudes, damage values, axis fields, and param tuples come from the workbook exactly.

## 5.1 Sequential direct Effects

`FNC_025 STOMP` is the first current content row that directly authors multiple Effects in one Function payload:

`EFFECT_ATTACK:EFFECT_BOMB`

The Function executor must support the existing dataset contract that payload entries execute **sequentially in authored order**.

For STOMP:

1. execute the authored `EFFECT_ATTACK` step;
2. if battle flow permits continuation, execute the authored `EFFECT_BOMB` step;
3. pay the Function cost only once;
4. preserve one parent Function activation identity with distinct child Effect events.

Do not create a STOMP-specific implementation.

Existing Function chaining behavior (`FNC_027 -> FNC_028:FNC_029`) remains unchanged: called Function costs are not paid, and recursive Function-to-Function chains remain invalid under the existing anti-loop contract.

---

# 6. New Effect: `EFFECT_MINE`

`FNC_023 VOLATILE` introduces the new Effect token:

`EFFECT_MINE`

A MINE is a controller-owned countdown special attached to an ordinary Packet.

It is a trap: depending on its authored trigger flags, removing/slicing the carrier or allowing the countdown to expire can deal damage to the **non-controller combatant**.

Current VOLATILE content places four Mines with:

- quantity: `4`
- countdown: `4`
- damage: `20`
- params: `1:1:0:0:0:0`

Therefore current VOLATILE Mines trigger when sliced by either side, do **not** trigger from the currently defined destruction categories, and expire harmlessly if they survive their full countdown.

## 6.1 Required `EFFECT_MINE` data contract

Required/used fields:

- `quantity`: positive integer;
- `countdown`: non-negative integer;
- `damage`: non-negative integer;
- `params`: exactly six `0|1` trigger flags.

Unused fields for this Effect should remain blank unless later content defines semantics.

The six param positions are, in order:

1. sliced by controller/owner;
2. sliced by opponent;
3. destroyed by controller/owner through a non-slice destruction source;
4. destroyed by opponent through a non-slice destruction source;
5. destroyed by HOST/environment source;
6. countdown expires.

Reject malformed tuple length or non-boolean values.

Per the workbook note, if all six flags are `0`, load may continue but emit a clear content warning because the Mine has no authored activation path.

## 6.2 Placement

Use the established random special-placement contract unless current runtime inspection reveals a single shared helper that already expresses it:

- choose randomly among non-neutral Packets;
- candidate may not already carry a special overlay;
- preserve the carrier Packet's color and shape;
- use deterministic battle RNG;
- each placement in a multi-quantity Effect uses a distinct currently valid target;
- if fewer valid targets exist than `quantity`, place as many as possible and waste the remaining placements without looping or crashing;
- the Function still pays its normal activation cost.

Do not create a special SAPPER-only placement path.

## 6.3 State carried by a Mine

A Mine must preserve enough explicit state to resolve without recovering rules from display names:

- special kind = MINE;
- controller side;
- source Program/Function identity;
- current countdown;
- authored damage;
- authored trigger flags;
- normal carrier Packet color/shape data.

Reuse the existing special-state architecture rather than adding a parallel Mine object model if the current overlay structure can represent it cleanly.

## 6.4 Countdown timing

Mines participate in the existing owner-countdown ordering:

- countdowns tick at the start of their controller's turn;
- retain the established oldest-first, one-at-a-time resolution order;
- a countdown resolution fully completes before the next countdown ticks.

`PSV_COUNTDOWN_ADJUST` modifies the Mine's initial countdown at placement time as defined later in this document.

## 6.5 Expiry behavior

When a Mine countdown reaches zero:

1. test param 6 (`expires`);
2. if enabled, deal the authored Mine damage to the non-controller combatant;
3. remove the **Mine overlay**;
4. leave the carrier Packet itself on the board;
5. continue ordinary turn-start flow if the battle is not over.

If expiry triggering is disabled, the overlay simply disappears with no Mine damage.

Current VOLATILE uses `expires=0`, so a surviving VOLATILE Mine disappears harmlessly after its fuse.

Do not leave a Mine with stored countdown `0` on the board.

## 6.6 Slice/removal triggering

A Mine trigger is tied to the event that removes the special/carrier, not to a later scan of the board.

For a qualifying slice/removal:

1. classify the removal source and responsible side;
2. select the matching authored trigger flag;
3. if enabled, emit exactly one Mine damage instance;
4. remove the Mine as part of the carrier/special removal already occurring;
5. do not trigger it twice because one operation has more than one descriptive label.

A normal match/cascade slice and an `EFFECT_LINESLICE` removal are both **slice** causes for Mine purposes.

Non-slice destruction includes existing explosive/special destruction paths that remove the carrier/special without treating it as a Sync slice. Use the current engine's actual removal-source model; do not infer the actor from screen state after the fact.

HOST-owned/environmental destruction maps to param 5.

If an existing operation explicitly discards an overlay while preserving the carrier Packet, it still counts as special removal if the engine can identify the responsible source. Classify it once under the six authored categories; do not invent an implicit seventh trigger category.

## 6.7 Damage semantics

Mine damage is Function/Effect-origin **ability damage**.

Therefore it:

- damages the non-controller combatant regardless of which side caused the Mine to trigger;
- passes through the ordinary damage funnel;
- is affected by applicable ability-damage modifiers;
- is affected by Buff/Shield processing under the existing damage order;
- does not generate charge merely because the Mine fired;
- is attributed to the placing Program/Function and Mine Effect;
- must be distinguishable from Bomb, direct ATTACK, match, and PASSIVE damage in logs/metrics.

If the carrier is sliced normally, the ordinary slice's own damage/charge behavior still occurs under existing rules. Mine damage is the additional trap consequence.

## 6.8 Lethal ordering

Mine damage resolves before the board proceeds to the next unrelated resolution step/fall.

Preserve the engine's established lethal-damage short-circuit semantics. Do not invent a new simultaneous-death rule solely for Mine.

If implementation exposes an unresolved simultaneous-lethal ambiguity, record the chosen existing-engine outcome in `decisions.md`; do not alter the rest of the combat model to create a new tie system.

---

# 7. Mine presentation and graphics-pack contract

A Mine is mechanically distinct from a Bomb and must be visually distinguishable while its countdown is visible.

Use the existing graphics/text framework.

Requirements:

- add explicit semantic MINE special identity;
- add the minimum v0 graphic asset(s) needed to identify MINE;
- use the existing sprite countdown digits, not a font;
- preserve controller ownership indication;
- preserve the underlying Packet color/shape information as much as the current overlay contract permits;
- do not present a VOLATILE Mine as an ordinary Bomb merely because both have countdown digits.

If the current overlay composition only has one center slot and cannot show both type and countdown distinctly, make the smallest presentation-contract extension required for clear play. Do not reopen a broad overlay redesign.

Any new semantic graphics key must be added to:

- every installed skin/pack;
- the authoring-bundle `SPEC`/README contract;
- pack completeness tests.

Use the existing pack/build/import tooling. Do not hand-wire one pack.

The Mine art is provisional and should be easy to replace during later art direction.

---

# 8. New PASSIVE mechanics

Existing PASSIVE ownership rules remain authoritative:

- HAK/SYS/UPG PASSIVEs are agent-owned;
- UPGRADEs are Hacker-owned;
- `OWNER` and `ENEMY` scope apply normally for agent-owned sources;
- HOST-owned PASSIVEs ignore `agent_scope` by design;
- HOST continual global modifiers apply to both agents/shared battle rules;
- HOST turn-specific modifiers apply to the active combatant as appropriate;
- HOST START_OF_TURN PASSIVEs resolve at the start of **each** agent's turn;
- START_OF_TURN PASSIVEs resolve before countdown objects tick;
- duplicate PASSIVE instances from different sources stack; do not deduplicate by PASSIVE_ID.

## 8.1 `PSV_COUNTDOWN_ADJUST`

Current rows:

- `PSV_010` = `-1`, OWNER
- `PSV_018` = `+1`, ENEMY

Semantics:

- applies to countdown specials when they are **placed**;
- applies once to the newly authored/base countdown;
- all applicable instances sum additively before placement;
- `final_countdown = max(0, base_countdown + sum(adjustments))`;
- never store a negative countdown;
- if final countdown is `0`, resolve the special's zero/expiry behavior immediately instead of leaving a zero-count object on the board.

This applies generically to countdown-capable Bomb/Buff/Mine content rather than checking Function names.

For HOST `FLOORIT`, HOST ownership makes the `-1` modifier apply symmetrically to countdown specials placed by either combatant.

For Hacker-owned `HAIRTRIGGER`, the modifier applies to Hacker-owned countdown specials only.

If multiple sources stack, e.g. FLOORIT + HAIRTRIGGER, the Hacker's specials receive both applicable adjustments while System specials receive only the HOST contribution.

Log base countdown, each applicable adjustment, and final countdown at VERBOSE/diagnostic level where the existing event model supports it.

## 8.2 `PSV_ABILITY_DAMAGE_RATE`

Current rows:

- `PSV_011` = `+50%`, OWNER
- `PSV_017` = `-25%`, ENEMY

Semantics:

- modifies qualifying Function/Effect-origin ability damage;
- does not modify ordinary Sync/match damage;
- does not modify `PSV_SELF_DAMAGE` or other pure PASSIVE/environmental damage;
- applies to Program Functions, Deck Functions, PASSIVE-triggered Functions, Boss support Functions, Bomb/Mine/LineSlice damage generated by Functions, and other Function-origin damage using the common damage funnel;
- does not convert non-damaging Effects into damaging ones.

Damage order:

1. calculate the Effect's ordinary base damage;
2. apply existing additive Function/passive/buff contributions that form pre-shield ability damage;
3. sum all applicable `PSV_ABILITY_DAMAGE_RATE` percentage modifiers;
4. apply the aggregate percentage once;
5. convert to integer using the engine's existing deterministic damage-number convention; if no percentage precedent exists, truncate toward zero;
6. clamp at minimum 0;
7. apply Shield/prevention through the existing defensive pipeline.

Do not compound several rate modifiers sequentially; summing rates avoids source-order dependence.

Examples under this rule:

- HOST MEGATON gives both sides +50% qualifying ability damage;
- Hacker UPG BULWARK applies -25% to the System's qualifying ability damage;
- if both affect the same System damage instance, the aggregate rate is +25%, not `1.5 × 0.75`.

Preserve contribution/source attribution in logs and metrics.

## 8.3 `PSV_PACKET_DROP_RATE`

Current rows:

- `PSV_012` = `15:RED`
- `PSV_016` = `15:YEL`

This PASSIVE modifies the **shared board's new-Packet generation distribution**.

Current semantics:

- first param: integer percentage increase;
- second param: one valid color or shape characteristic token;
- neutral probability/rate is unchanged;
- color and shape selections remain independent;
- transforms of already-existing Packets are not "drops" and are unaffected.

Use **relative weighting**, not percentage-point addition.

For an otherwise uniform six-value axis, one `15:RED` modifier means:

- RED weight = `1.15`
- each other color weight = `1.00`
- normalize across the six weights for the draw.

Multiple active modifiers add to the target's relative weight before normalization. Example: two +15% RED modifiers produce RED weight `1.30`, not `1.15 × 1.15`.

Different targeted characteristics may be active simultaneously.

Because Packet generation is shared-board state rather than agent-owned state, a valid active `PSV_PACKET_DROP_RATE` instance contributes to the board's generation weights whenever it is active. Current agent-owned authored content uses `OWNER`; do not invent `ENEMY` semantics for an agent-owned drop-rate PASSIVE until content actually needs it.

HOST REDSHIFT is global by existing HOST semantics. Hacker UPG GOLDRUSH contributes its YEL weighting for as long as the UPGRADE is active.

### Determinism constraint

Use the existing deterministic battle RNG.

When **no drop-rate modifier applies**, preserve the existing exact packet-generation path and RNG consumption so ordinary regression behavior does not change merely because weighted generation support exists.

When modifiers do apply, use a deterministic weighted selection with no unbounded rejection loop.

Initial board generation and later refill should both use the common generation policy once battle PASSIVEs are active. Preserve the existing no-initial-match invariant.

## 8.4 `PSV_SELF_DAMAGE`

Current row:

- `PSV_013` = `10`, START_OF_TURN

Semantics:

- at the relevant START_OF_TURN PASSIVE phase, deal the authored damage to the targeted/current combatant;
- for HOST ACID, this means **each combatant takes 10 damage at the start of their own turn**;
- resolve before countdowns tick, per existing HOST ordering;
- check for battle end immediately after the damage;
- if lethal, do not continue that combatant's countdowns/actions.

This is PASSIVE/environmental damage, not ability damage.

Route it through the ordinary incoming-damage/prevention funnel so existing Shield semantics apply, but do not apply `PSV_ABILITY_DAMAGE_RATE`.

It grants no charge and changes no board state.

Logs/metrics should attribute it to the supplying PASSIVE/HOST rather than to the opposing combatant.

## 8.5 `PSV_STRONG_SLICE_BONUS`

Current row:

- `PSV_020` = `1`, OWNER

No current HST/UPG references this row, but it must be implemented because it is valid authored PSV content.

Semantics:

- when the existing slice-damage calculation marks a sliced Packet as strong for the affected combatant under the current strong-color/strong-shape rule, add the PASSIVE amount once for that Packet;
- this stacks on top of the established strong value of 2;
- a Packet does not receive the bonus twice merely because both of its axes happen to be strong;
- applies anywhere the engine intentionally uses the normal color/shape slice-damage profile, including a Function line-slice that explicitly deals damage according to that profile;
- does not apply to Bomb destruction, direct ATTACK, Mine damage, or other non-slice ability damage.

Multiple applicable instances stack additively.

Add synthetic coverage even though current live content does not reference it.

---

# 9. Extension to existing PASSIVE: `PSV_EXTRA_MATCH_DAMAGE` with `ALL`

`HST_10 FURNACE` uses:

`PSV_EXTRA_MATCH_DAMAGE | ALL:1`

Existing content previously used explicit color tokens such as `RED` or `BLU`.

Extend the existing parser/resolver so the first param accepts `ALL` as a wildcard.

Semantics:

- every qualifying normal Sync slice for the affected side receives +1 per sliced Packet under the established extra-match-damage rule;
- under HOST ownership, FURNACE applies symmetrically to both combatants;
- it affects Sync/slice damage, not direct ability damage;
- it stacks additively with axis-specific extra-match-damage PASSIVEs.

Do not create a separate FURNACE rule.

---

# 10. Existing Effect extension: Transform to `NEU`

`FNC_037 SMOG` authors:

- `payload = EFFECT_TRANSFORM`
- `axisTarget = ALL`
- `axisResult = NEU`

The Transform Effect must therefore support `NEU` as a valid result.

Transforming a standard Packet to `NEU` means:

- clear its color axis;
- clear its shape axis;
- it becomes a normal neutral Packet under existing neutral matching/rendering rules;
- apply the authored Transform special-retention param exactly as with other Transform operations.

Do not special-case SMOG by name.

If the authored retention mode preserves a special overlay, a neutral Packet carrying that preserved special is valid unless an existing invariant explicitly forbids it. The renderer must continue to communicate neutral + overlay state legibly.

Transforming to NEU must not award damage or charge merely because axes were removed.

---

# 11. New HOST content

HOST is the battlefield/environment source. Preserve the established rule that HOST PASSIVE `agent_scope` is ignored and HOST effects apply globally/symmetrically according to PASSIVE type.

| HOST | PASSIVE | Required behavior |
| --- | --- | --- |
| THRESHOLD | none | fixed introductory HOST |
| BITMIRE | PSV_003 | existing charge dampen |
| ARENA | PSV_004 | existing Function damage increase |
| VERDUN | PSV_007 | existing bigger Bomb |
| WEEDS | PSV_008 | existing START_OF_TURN carrier |
| FLOORIT | PSV_010 | all countdown specials placed by either side start 1 turn shorter |
| MEGATON | PSV_011 | both sides' qualifying ability damage +50% |
| REDSHIFT | PSV_012 | shared board RED generation relative weight +15% |
| ACID | PSV_013 | active combatant takes 10 PASSIVE damage at start of own turn |
| FURNACE | PSV_014 | all ordinary Sync slice damage +1 for both sides |

Human playtesting should deliberately exercise each new HOST with a System/Program combination that makes its behavior visible.

---

# 12. New UPGRADE content

UPGRADEs are Hacker-owned and persist through the Run under current rules.

| UPGRADE | PASSIVE | Intended effect |
| --- | --- | --- |
| EDGE | PSV_001 | +1 RED Sync slice damage |
| DYNAMO | PSV_002 | +1 RED Sync charge |
| CERULEAN | PSV_015 | +1 BLU Sync slice damage |
| GOLDRUSH | PSV_016 | +15% relative YEL Packet generation weight |
| HAIRTRIGGER | PSV_010 | Hacker-owned countdown specials start 1 turn shorter |
| BULWARK | PSV_017 | System qualifying ability damage -25% |

The first three reuse established PASSIVE behavior.

The latter three exercise the new PASSIVE implementations from this build.

Do not invent rarity, tiers, pricing, anti-stacking, or replacement rules.

---

# 13. Text-content migration for the new content

Beta 0.3.2 made `text_content.csv` authoritative for player-facing names. The supplied working workbook has gameplay rows for the new content but does not yet contain all corresponding text rows.

Populate the text sheet in the workbook/export path so player-facing surfaces do not fall back to gameplay-row `name` fields.

At minimum add missing rows for:

- `SYSTEM_NAME`: SYS_04–SYS_11;
- `HOST_NAME`: HST_06–HST_10;
- `UPGRADE_NAME`: UPG_05–UPG_10;
- `PROGRAM_NAME`: PRG_S_009–PRG_S_026;
- `FUNCTION_NAME`: FNC_023–FNC_040;
- `PASSIVE_TEXT`: all currently displayed PASSIVEs lacking a text row, including the new PSV rows and existing carrier rows if their current presentation still needs one.

The gameplay-sheet `name` fields remain as required by current data/logging compatibility, with the existing agreement test between gameplay names and text-content names.

For PASSIVE_TEXT, generate functional v0 wording from the actual semantic contract, not from speculative flavor copy. Keep parameter placeholders reusable where appropriate.

Do not add localization behavior; preserve the current `EN` column model.

Run the workbook round-trip checker and ensure no leading-whitespace-dependent copy is introduced.

---

# 14. Validation requirements

Extend startup/content validation so malformed new content fails early and loudly.

At minimum validate:

## EFFECT_MINE

- `quantity >= 1`;
- countdown present and `>= 0`;
- damage present and `>= 0`;
- params exactly six binary values;
- warning if all trigger flags are zero;
- source/controller is a supported combatant when instantiated;
- required MINE graphics semantic exists.

## PASSIVEs

- `PSV_COUNTDOWN_ADJUST`: exactly one signed integer;
- `PSV_ABILITY_DAMAGE_RATE`: exactly one signed integer percent;
- `PSV_PACKET_DROP_RATE`: exactly `percent:characteristic`, characteristic is valid color/shape token; reject unsupported agent-scope combinations if they cannot have coherent meaning;
- `PSV_SELF_DAMAGE`: exactly one non-negative integer damage value and START_OF_TURN activation;
- `PSV_STRONG_SLICE_BONUS`: exactly one integer bonus;
- `PSV_EXTRA_MATCH_DAMAGE`: first token accepts canonical color/shape selector or `ALL` as authorized here.

## Functions

- direct multi-Effect payloads are valid under the existing payload list contract;
- Function-to-Function anti-recursion validation remains intact;
- `axisResult=NEU` is valid for EFFECT_TRANSFORM;
- all new Program Function references resolve.

## Pool/content integrity

- 11 ordinary System rows total;
- exactly 10 ordinary Systems in the random pool, DOORMAN excluded;
- 10 HOST rows total;
- exactly 9 HOSTs in the random pool, THRESHOLD excluded;
- 10 UPGRADE rows;
- all UPGRADE PASSIVE refs valid;
- all System Program sets resolve to exactly four valid Programs under the current contract;
- all Program Function refs resolve;
- every player-facing content ID that requires a name resolves through text_content.

---

# 15. Logging and metrics

The existing event-sourced funnel remains authoritative. Do not create a second telemetry path for the new mechanics.

## 15.1 Mine

Logs/metrics must make it possible to determine:

- placing Program/Function;
- Mine controller;
- placement cell/carrier identity as currently represented;
- base and adjusted countdown;
- trigger cause (`slice_owner`, `slice_enemy`, `destroy_owner`, `destroy_enemy`, `destroy_host`, `expire` or equivalent stable enum);
- whether the cause was enabled by the Mine's flags;
- authored Mine damage;
- applicable ability-damage modifiers;
- Shield/prevention;
- final damage.

Add a distinct Mine damage category/source identity rather than mislabeling it Bomb or direct ATTACK damage.

## 15.2 New PASSIVEs

Preserve per-source contribution attribution:

- countdown adjustment by source;
- ability-rate modifier by source;
- packet-drop weight modifier by source at diagnostic/VERBOSE level where practical;
- self-damage source;
- strong-slice bonus source;
- wildcard ALL match-damage contribution.

Do not turn BASIC logs into per-Packet noise solely for this build.

## 15.3 Metrics identity

If the metrics schema uses disjoint damage buckets, extend the bucket identity so Mine damage is represented exactly once and total damage remains equal to the sum of disjoint categories.

If this changes serialized accounting state, a save-schema bump is allowed. Per standing beta policy, no cross-version migration is required.

---

# 16. Save/resume and fingerprint

The content fingerprint must change for gameplay-relevant additions/edits.

Do not preserve compatibility with previous beta saves.

Same-build save/resume must preserve:

- placed Mines;
- Mine controller/source;
- Mine countdown;
- Mine trigger configuration if stored per-instance;
- acquired UPGRADEs;
- selected HOST/System;
- RNG state;
- all existing countdown/special state.

Add a continuation test with at least one live Mine and at least one new PASSIVE active.

Resume must produce the same subsequent result as uninterrupted play for the same state/inputs.

---

# 17. Alpha parity / regression policy

This build deliberately moves current authored ordinary content beyond Alpha in a way that makes **live-content Alpha parity no longer a valid release criterion**:

- new Systems/Programs/Functions/HOSTs/UPGRADEs do not exist in Alpha;
- existing SYS_01–SYS_03 strong-axis content has changed;
- new PASSIVE and Mine mechanics do not exist in Alpha.

Do not modify Alpha to make the new content comparable.

## 17.1 Preserve the useful part of the differential

The old differential harness remains useful as a diagnostic for inherited mechanics if it can be run against a frozen/shared legacy fixture without substantial new infrastructure.

Where practical:

- retain a small legacy-parity profile using content/config that still matches Alpha;
- use it after changes to shared damage, charge, board, countdown, Bomb, Transform, Shake, or Function execution paths;
- do not compare current authored live content byte-for-byte against Alpha.

If maintaining a frozen parity fixture becomes more expensive than its value, record the retirement decision rather than warping current content around the oracle.

## 17.2 DEEPSCAN

Do **not** run the historical live-content DEEPSCAN and then interpret expected content divergence as a failure.

If the existing harness can run DEEPSCAN against a frozen Alpha-equivalent fixture with little work, it remains valid optional evidence after shared-core changes.

Otherwise replace it for this build with:

- focused legacy regression tests;
- strong property tests around the changed shared seams;
- the content smoke matrix below;
- human/device verification.

Record the new oracle boundary in `decisions.md`.

---

# 18. Automated coverage

The coding agent should inspect current tests and add the smallest discriminating set that proves these properties.

A green suite containing `SCRIPT ERROR`, importer errors, or resource errors is not green.

## 18.1 Content/pools

Prove:

1. all workbook gameplay sheets load;
2. all new IDs/references resolve;
3. current content counts match this authorization;
4. random System pool contains 10 and excludes DOORMAN;
5. random HOST pool contains 9 and excludes THRESHOLD;
6. all 10 UPGRADEs are eligible under existing Run rules;
7. first Run battle still uses DOORMAN + THRESHOLD;
8. SYS_01–SYS_03 strong sets match the new workbook rather than stale fixtures;
9. all new text names resolve with no MISSING fallback;
10. new graphics semantic(s) are complete in every installed skin.

## 18.2 Function composition

Prove:

- STOMP executes ATTACK then BOMB in authored order;
- Function cost is paid once;
- lethal first Effect obeys existing sequence-short-circuit rules;
- FORAGE chained Functions still execute in authored order without child costs;
- no invalid recursive Function chaining is introduced.

## 18.3 EFFECT_MINE

Prove at least:

- FNC_023 places up to four distinct legal Mines;
- Mines preserve carrier color/shape;
- placement never selects neutral or already-special targets under the ordinary placement contract;
- insufficient target count fails gracefully;
- Mine countdown ticks only on controller turn and in established countdown order;
- VOLATILE current flags trigger when sliced by controller;
- VOLATILE current flags trigger when sliced by opponent;
- current flags do not trigger on each of the disabled destruction categories;
- current flags do not trigger damage on expiry;
- expiry removes overlay but preserves carrier Packet;
- a synthetic Mine with expiry flag enabled deals damage on expiry;
- one removal produces at most one Mine trigger;
- Mine damage targets the non-controller combatant even when the controller itself caused the slice;
- ability-rate modifiers affect Mine damage;
- Shield applies through ordinary damage handling;
- save/resume preserves live Mine continuation;
- all-zero trigger tuple emits the required warning.

Also add direct synthetic coverage for any destruction trigger categories implemented by the six-flag contract even though current VOLATILE leaves them disabled.

## 18.4 Countdown adjustment

Prove:

- one `-1` modifier shortens countdown by one;
- multiple applicable modifiers add;
- HOST FLOORIT applies to both sides;
- UPG HAIRTRIGGER applies only to Hacker-owned countdown specials;
- FLOORIT + HAIRTRIGGER gives Hacker specials `-2` and System specials `-1`;
- final countdown never goes below zero;
- zero resolves immediately under each affected special type's existing zero behavior;
- no zero-count special remains parked on the board.

## 18.5 Ability damage rate

Prove:

- MEGATON +50% applies symmetrically as HOST content;
- BULWARK -25% applies to System ability damage as Hacker UPG content;
- rates aggregate additively rather than multiplying sequentially;
- current rounding convention is deterministic and asserted with an odd/non-even value;
- Shield occurs after the rate modification;
- match damage is unaffected;
- PASSIVE SELF_DAMAGE is unaffected;
- Function-origin Bomb, Mine, ATTACK, and other qualifying damage all use the common modifier seam.

## 18.6 Packet drop rate

Prove:

- no-modifier generation follows the old exact path;
- REDSHIFT changes only RED relative weighting, not neutral rate;
- GOLDRUSH changes only YEL relative weighting, not neutral rate;
- both can coexist;
- same-target modifiers add in weight space if synthetic fixtures stack them;
- fixed-seed weighted draws are deterministic;
- no rejection loop can hang;
- initial board remains match-free;
- refill/cascade generation uses the same weighted policy when active.

Prefer testing the weight construction and fixed RNG draws directly rather than relying on a flaky statistical-frequency assertion.

## 18.7 SELF_DAMAGE

Prove:

- ACID damages Hacker at start of Hacker turn;
- ACID damages System at start of System turn;
- damage occurs before countdown tick;
- Shield/prevention is applied through the ordinary damage funnel;
- ability-damage-rate PASSIVEs do not modify it;
- lethal self-damage ends the battle before countdowns/actions continue.

## 18.8 Wildcard match damage / strong bonus

Prove:

- FURNACE `ALL:1` affects qualifying Sync damage for both sides;
- axis-specific bonuses such as EDGE/CERULEAN still work;
- wildcard + axis-specific instances stack additively;
- FURNACE does not modify direct ability damage;
- `PSV_STRONG_SLICE_BONUS` adds once per qualifying strong sliced Packet;
- a dual-axis-strong Packet does not receive the new bonus twice;
- line-slice operations using the ordinary strong damage profile pick up the strong-slice bonus;
- Bomb/Mine destruction does not.

## 18.9 Transform to neutral

Prove:

- SMOG can transform a standard Packet to NEU;
- both color and shape are cleared;
- special-retention param is honored;
- retained overlay on a neutral carrier remains valid/renderable;
- no damage/charge is generated by the transform itself;
- ordinary neutral matching rules remain unchanged.

---

# 19. Content smoke matrix

The expanded roster needs a mechanical "does every authored combination run?" gate distinct from balance testing.

At minimum run headlessly:

1. every ordinary System once through a complete battle with THRESHOLD;
2. every HOST once with a representative System that exercises its mechanic;
3. every UPGRADE in a battle fixture where its PASSIVE can actually fire;
4. every new Function at least once;
5. a deterministic System × HOST smoke matrix sufficient to exercise all 10 pooled Systems against all 10 HOST definitions at least once, or an equivalent coverage-driven matrix if the harness exposes direct coverage counters;
6. multiple complete Run walks using the expanded System/HOST/UPGRADE pools.

The pass criterion is structural/mechanical:

- no crashes;
- no script/resource/import errors;
- no infinite resolution loops;
- no impossible targeting deadlock;
- no unresolved text/graphics fallback;
- valid battle completion;
- valid Run progression.

Do not turn this into a balance ladder or require every matchup to have a particular win rate.

---

# 20. Human/device verification

Use the tablet for routine testing and the live skin switcher only as needed to ensure the new Mine presentation survives installed skins.

Human verification should deliberately play at least:

- **SAPPER** — observe VOLATILE placement, slicing consequence, and harmless expiry;
- **MAMMOTH** — verify multi-Effect/chained Function presentation does not look like skipped events;
- **ARCHON** — verify long countdown/board-pressure Functions remain legible;
- **STATICIAN** — verify Shake + SMOG/NEU state remains understandable;
- one Run with **FLOORIT** and/or **HAIRTRIGGER** to feel shortened countdowns;
- one battle with **MEGATON** and one with **BULWARK** to confirm damage differences are visibly plausible;
- one battle with **ACID** to confirm turn-start self-damage ordering is readable;
- one battle with **FURNACE** to confirm both sides' Sync pressure changes;
- at least one Run that acquires multiple new UPGRADEs and reaches later battles.

Specific visual checks:

- Mine must not be confused with Bomb;
- countdown digit remains legible;
- ownership remains legible;
- neutral-with-special rendering is understandable if SMOG creates one;
- expanded chooser lists scroll and fit;
- no MISSING text rows;
- no horizontal overflow on representative phone geometry.

Use the S25 in one batched closeout window if the Mine overlay/layout or enlarged selection lists introduce phone-specific presentation changes that tablet geometry emulation cannot settle.

---

# 21. Workbook and boundary checks

This build touches exactly the environment boundaries that produced defects in Beta 0.3.2.

Required closeout checks:

- `export_workbook.py --check` or current equivalent;
- scene-script load/parse check;
- asset-bundle validation;
- graphics-pack structural validation;
- `fix_imports.py --check` or current equivalent;
- actual Android export/install/launch, not desktop-only validation;
- clean device log.

Any new CSV added/changed must retain the existing `importer="keep"`/export behavior.

Any resource path in an exported build must be validated through Godot's resource system rather than source-tree-only filesystem assumptions.

---

# 22. Presentation scope

This remains a content-mechanics build.

Use the existing graphics/text frameworks and live skin switcher.

In scope:

- a provisional Mine special graphic/contract;
- text-content rows needed to display new content;
- small presentation work necessary to make new mechanics legible.

Out of scope:

- choosing final art direction;
- broad skin redesign;
- graphics jig;
- animation/VFX system;
- audio;
- final iconography;
- large layout redesign.

---

# 23. Explicitly out of scope

Do not add unless required to make authored rows executable:

- new Hacker content;
- new Deck content;
- additional Boss mechanics/content;
- System build editing;
- UPGRADE rarity/economy;
- new Run length/progression rules;
- UPGRADE selection in Constructed Quick Match;
- passive scripting/DSL;
- generalized arbitrary trigger language for Mine;
- manual DISABLER targeting (AN-001) unless separately authorized;
- save migration across beta versions;
- broad balance changes;
- final presentation/audio work.

---

# 24. Implementation sequence

A reasonable sequence is:

## Phase A — inspect and diff

- read `lessons-learned.md` first;
- import the supplied workbook through the real export path;
- mechanically diff current runtime content against the workbook;
- confirm exact current Beta 0.4 baseline rather than assuming the old workbook is still identical;
- identify shared code seams affected by Mine/passives.

No formal approval gate is required unless inspection reveals a genuine rules ambiguity not resolved here.

## Phase B — content/text ingest

- update workbook/exported datasets;
- add missing text-content rows;
- update fingerprint expectations;
- validate all references/pools;
- keep gameplay names/text names in sync under the existing agreement test.

## Phase C — Effect/Function capability

- implement `EFFECT_MINE`;
- support direct sequential multi-Effect payloads if not already supported;
- support Transform result `NEU`;
- add Mine graphics contract across installed packs.

## Phase D — PASSIVE capability

Implement/extend:

- `PSV_COUNTDOWN_ADJUST`;
- `PSV_ABILITY_DAMAGE_RATE`;
- `PSV_PACKET_DROP_RATE`;
- `PSV_SELF_DAMAGE`;
- `PSV_STRONG_SLICE_BONUS`;
- `PSV_EXTRA_MATCH_DAMAGE` wildcard `ALL`.

Use common calculation seams. Do not implement by HOST/UPGRADE name.

## Phase E — System/HOST/UPGRADE integration

- load all new Systems/Programs/Functions;
- load all new HOSTs;
- load all new UPGRADEs;
- exercise System AI and route pools;
- fix only genuine implementation blockers, not balance preferences.

## Phase F — automated regression/content sweep

- full maintained headless suite;
- focused new mechanic tests;
- legacy regression/parity where still meaningful;
- content smoke matrix;
- Run walks;
- boundary checks.

## Phase G — device/play verification

- tablet targeted play;
- phone geometry/hardware gate as warranted;
- clean logs.

## Phase H — closeout

Update:

- README/content counts;
- decisions;
- architect notes;
- lessons learned;
- any data-contract documentation affected by Mine/passive changes.

Commit, push, clean working tree.

---

# 25. Required decisions/log entries

At minimum record durable decisions for:

1. `EFFECT_MINE` trigger tuple and expiry behavior;
2. ability-damage percentage aggregation/rounding order;
3. packet-drop relative-weight semantics;
4. Transform-to-NEU semantics if this was not already explicit;
5. retirement/narrowing of current-live-content Alpha parity as a release gate.

If implementation discovers an already-existing decision covering one exactly, reference/supersede rather than duplicating it.

---

# 26. Required handback

Produce:

`1c38r34kr-beta-0.5.0-initial-content-expansion-handback.md`

Include:

1. verdict against this authorization;
2. final content counts and pool counts;
3. imported System/HOST/UPGRADE roster;
4. exact new Effect/PASSIVE runtime semantics implemented;
5. Mine representation and presentation solution;
6. any existing-effect extensions required by authored content;
7. text-content additions;
8. fingerprint/save-schema changes;
9. test count and focused mechanic coverage;
10. content smoke-matrix result;
11. Run-walk result;
12. legacy parity/differential status and new oracle boundary;
13. tablet result;
14. S25 result or explicit carry-forward rationale;
15. importer/workbook/asset boundary-check results;
16. defects found;
17. decisions added;
18. architect notes added/resolved;
19. lessons learned appended;
20. content contradictions or suspected balance issues left deliberately unchanged.

---

# 27. Completion standard

Beta 0.5.0 is complete when:

1. the supplied workbook is the implemented content authority;
2. all 11 ordinary System rows load;
3. exactly 10 ordinary Systems are in the random pool;
4. DOORMAN remains excluded from the random pool and fixed for Battle 1;
5. all 10 HOST rows load;
6. exactly 9 HOSTs are in the random pool;
7. THRESHOLD remains excluded from the random pool and fixed for Battle 1;
8. all 10 UPGRADEs load and participate in existing Run reward rules;
9. PRG_S_009–PRG_S_026 load and resolve;
10. FNC_023–FNC_040 load and resolve;
11. SYS_01–SYS_03 use the newly authored strong-axis values;
12. direct sequential Effect payloads execute in authored order;
13. FNC chaining remains correct;
14. `EFFECT_MINE` is implemented and validated;
15. VOLATILE places the authored four 4-countdown 20-damage Mines;
16. current VOLATILE Mines trigger on owner/opponent slice and not on disabled trigger categories;
17. current VOLATILE expiry removes the Mine harmlessly;
18. synthetic expiry-enabled Mine behavior works;
19. Mine damage uses the ordinary ability-damage/shield pipeline;
20. Mine is visually distinct from Bomb while showing countdown and ownership;
21. Mine graphics contract is complete in every installed skin;
22. Mine save/resume continuation is correct;
23. `PSV_COUNTDOWN_ADJUST` is implemented and stacks correctly;
24. `PSV_ABILITY_DAMAGE_RATE` is implemented with deterministic aggregate percentage semantics;
25. `PSV_PACKET_DROP_RATE` is implemented with deterministic relative weighting and unchanged neutral rate;
26. `PSV_SELF_DAMAGE` is implemented at the correct START_OF_TURN point;
27. `PSV_STRONG_SLICE_BONUS` is implemented and directly tested even though currently unreferenced;
28. `PSV_EXTRA_MATCH_DAMAGE` accepts `ALL` and FURNACE works symmetrically;
29. `EFFECT_TRANSFORM` supports `axisResult=NEU` and SMOG works;
30. FLOORIT works for both sides as HOST content;
31. MEGATON works for both sides as HOST content;
32. REDSHIFT changes RED generation weighting;
33. ACID damages each active combatant before countdowns;
34. FURNACE increases Sync damage for both sides;
35. EDGE, DYNAMO, CERULEAN, GOLDRUSH, HAIRTRIGGER, and BULWARK work as authored;
36. unused PSV_018–PSV_020 parse/resolve and have direct synthetic coverage where needed;
37. all new player-facing names resolve through text_content;
38. PASSIVE summaries needed by current UI resolve without MISSING fallback;
39. workbook round-trip/check is clean;
40. scene parse/load check is clean;
41. graphics/import boundary checks are clean;
42. full maintained test suite is green with no unexplained errors;
43. expanded content smoke matrix completes without mechanical failure;
44. multiple complete Run walks succeed with the larger pools;
45. live-current-content Alpha parity is not falsely treated as authoritative where content intentionally diverges;
46. useful inherited-regression proof is retained where proportional;
47. SAPPER/VOLATILE is manually exercised on device;
48. representative new Systems/HOSTs/UPGRADEs are manually exercised;
49. chooser/scroll presentation remains usable with enlarged lists;
50. Android export/install/launch is verified with a clean log;
51. no broad balance tuning was introduced beyond authored workbook values;
52. no unnecessary generalized scripting/passive DSL was introduced;
53. project records and lessons learned are updated;
54. intended changes are committed and pushed;
55. working tree is clean.
