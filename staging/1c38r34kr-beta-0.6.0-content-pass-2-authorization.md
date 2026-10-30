# 1C38R34KR Beta 0.6.0 — Content Pass 2
## Build Authorization

**Build identity:** `beta-0.6.0`  
**Purpose:** complete the initial player-side Hacker/Deck catalogue, replace placeholder Boss Program loadouts with authored identities, and implement the three newly authored reusable Effects required by that content: HEAL, SELF_DAMAGE, and direct CHARGE.  
**Engine:** Godot 4.7.2, standard/non-Mono  
**Language:** GDScript  
**Primary platform:** Android portrait  
**Status:** authorized for implementation. No separate design or architecture approval gate is required unless inspection reveals a material contradiction in authored behavior.

---

## 0. Source precedence and one important correction

Use sources in this order:

1. **This authorization** for Beta 0.6 implementation scope and clarified runtime semantics.
2. **`staging/breach-datastructures.xlsx`** — the supplied unsuffixed workbook — for exact authored content values, IDs, Program sets, Function tuples, names, and parameter encodings.
3. The shipped **Beta 0.5.0 runtime** and current `decisions.md`, especially D-053 through D-067.
4. The Beta 0.6 combined designer/content handoff for design intent where it does not conflict with the current runtime or workbook.
5. Current architect notes and lessons learned.
6. The frozen Alpha/legacy dataset only for inherited-behavior differential verification.

### Correction to the designer handoff

The designer handoff says MINE/VOLATILE is authored but not yet implemented. That statement is stale relative to Beta 0.5.0.

**MINE is already implemented and canonical under D-053.** Beta 0.6 must **not** redesign or reimplement the Mine mechanic. This build adds new authored Mine content (`SEEDMINE`, `TRIPWIRE`) and must prove that it works through the existing Mine implementation.

The same rule applies generally: do not reopen mechanics already resolved in D-053–D-067 merely because the content handoff predates the final Beta 0.5 implementation state.

---

## 1. Build objective

Beta 0.6.0 completes the first broad player catalogue and removes the temporary common Boss Program loadouts.

The build should:

1. ingest the authored workbook as the single content authority;
2. implement `EFFECT_HEAL`;
3. implement Function-level `EFFECT_SELF_DAMAGE` as a health resource cost;
4. implement direct `EFFECT_CHARGE`;
5. preserve the existing `EFFECT_MINE` implementation and integrate the two new Mine Functions;
6. load 4 total Hackers and 4 total Decks;
7. load all 24 player Program rows and their Functions;
8. apply the four authored Boss Program identities and authored Boss strong axes;
9. extend validation, logging, metrics, persistence proof, and content-smoke coverage;
10. preserve existing System/HOST/UPGRADE/Boss mechanics and the legacy differential oracle.

This is still a **content breadth pass, not a balance pass**.

---

## 2. Mechanical workbook delta — intended changes

The coding-agent feedback from Beta 0.5 asked future requirements to ship a mechanical workbook delta rather than force the implementer to discover unexplained edits. The supplied workbook was compared against the final Beta 0.5 workbook.

These changes are **intended**:

| Sheet | Beta 0.6 delta | Classification |
| --- | --- | --- |
| `HAK` | +3 rows: `HAK_02`–`HAK_04` | intended content |
| `DEK` | +3 rows: `DEK_02`–`DEK_04` | intended content |
| `PRG_H` | +18 rows: `PRG_H_007`–`PRG_H_024` | intended content |
| `FNC` | +27 rows: `FNC_041`–`FNC_067` | intended content |
| `BOS` | all 4 Boss rows change strong axes and `PRG_SET` | intended content |
| `text_content` | +51 rows: 3 Hacker names, 3 Deck names, 18 Program names, 27 Function names | intended presentation content |
| `param notes` | + HEAL, SELF_DAMAGE, CHARGE contracts and Mine confirmation | intended schema documentation |
| `dataset notes` | +2 Content Pass 2 change-log rows | intended documentation |

No authored changes were found in:

- `PRG_S`
- `SYS`
- `PSV`
- `HST`
- `UPG`
- `font_refs`
- `text_style`
- gameplay conventions
- Boss passive rules

Do not make unrelated changes to those sheets in this build.

### Workbook authority transition

D-066 explicitly said the next build returns to a single unsuffixed workbook. Do that now:

- stage/use `staging/breach-datastructures.xlsx`;
- repoint `tools/export_workbook.py` from the temporary `...-working.xlsx` source to the unsuffixed workbook;
- export `data/*.csv` from it;
- run `export_workbook.py --check` before closeout;
- do not hand-edit exported CSVs as the durable source.

If the coding agent must repair a workbook defect, make the edit in the workbook, preferably by script, and record an explicit workbook change log in the handback. Do not silently alter authored balance or identity decisions.

---

## 3. Expected live content counts after import

Pin live-content counts in tests rather than expanding the engine's required-ID lists, preserving D-063.

Expected live catalogue:

- 4 Hackers
- 4 Decks
- 4 Bosses
- 11 Systems
- 10 HOSTs
- 10 UPGRADEs
- 24 Hacker/Deck Programs (`PRG_H`)
- 26 System/Boss Programs (`PRG_S`)
- 67 Functions
- 20 PASSIVEs
- 292 `text_content` data rows, excluding the header

The 24 `PRG_H` rows should form exactly 24 placements across the 4 Hackers and 4 Decks:

- 3 Programs per Hacker × 4 = 12;
- 3 Programs per Deck × 4 = 12.

Every `PRG_H` row should belong to exactly one Hacker or Deck Program set in the authored catalogue unless the workbook is deliberately changed later.

---

## 4. Authored Hacker catalogue

Load exactly as authored:

| ID | Hacker | BASE_LINK | Strong colors | Strong shapes | Programs |
| --- | --- | ---: | --- | --- | --- |
| `HAK_01` | CR45H | 100 | RED:GRE:YEL | TRI:SQU:STR | BOMBER, BUFFER, NINJA |
| `HAK_02` | VITRA | 110 | GRE:BLU:MAG | SQU:CIR:DIA | MENDER, AEGIS, SALVE |
| `HAK_03` | RAZE | 90 | RED:MAG:YEL | TRI:CRO:STR | OVERDRAW, BLOODSPIKE, FLARE |
| `HAK_04` | NEEDLE | 100 | GRE:YEL:BLU | STR:CIR:TRI | SEEDMINE, TRIPWIRE, STAIN |

Do not tune these values during implementation merely because one identity appears stronger or weaker in smoke/human play.

### Identity intent

- **VITRA:** sustain/defense — healing, shielding, heal+buff chain.
- **RAZE:** LINK-as-resource aggression — self-damage in exchange for immediate power.
- **NEEDLE:** special/removal-condition manipulation — two Mine trigger profiles plus board painting.
- **CR45H:** existing baseline Hacker; unchanged.

---

## 5. Authored Deck catalogue

Load exactly as authored:

| ID | Deck | ADD_LINK | Programs | Deck active |
| --- | --- | ---: | --- | --- |
| `DEK_01` | AGIMA | 50 | ATTACKER, DISABLER, WEASEL | SCRAMBLE |
| `DEK_02` | BLEEDLINE | 40 | LANCET, CLOT, SURGE | TRANSFUSE |
| `DEK_03` | BASTION | 60 | MENDKIT, BULWARK, DAMPEN | REINFORCE |
| `DEK_04` | FUSEBOX | 45 | CHARGEPACK, LONGFUSE, CUTTER | SPARK |

The Deck active remains separate from the active four-Program battle build.

All four Deck actives use the existing authored `startCharged` behavior from their Function rows. Do not create a second Deck-specific startup-charge mechanism.

### Identity intent

- **BLEEDLINE:** converts LINK into immediate Program tempo through TRANSFUSE.
- **BASTION:** sustain/control through healing, shields, and DRAIN reuse.
- **FUSEBOX:** Bomb/countdown/charge interaction.
- **AGIMA:** existing baseline Deck; unchanged.

---

## 6. Player Build integration

A Hacker contributes 3 candidate Programs and a Deck contributes 3 candidate Programs. The existing Build step therefore receives **6 candidate Programs** and the player selects the existing active four-Program battle build.

Do not alter the active Program-slot count in this pass.

Requirements:

- Hacker and Deck chooser screens enumerate all four authored rows from content.
- Constructed Quick Match and Run setup use the chosen Hacker and Deck.
- Random selection paths include all four Hackers/Decks where the current architecture treats those sheets as pools.
- Build shows exactly the combined Hacker+Deck candidates for the selected pair.
- No candidate is silently omitted because it uses a newly implemented Effect.
- Save/resume preserves selected Hacker ID, Deck ID, and active build through the existing session structures.

Do not introduce Hacker-specific Deck restrictions. All 16 Hacker × Deck pairings must be mechanically constructible.

---

## 7. Boss Program identities — replace placeholders

The four Bosses keep their existing bespoke Boss mechanics. Beta 0.6 changes their authored strong axes and Program loadouts only.

| Boss | Strong colors | Strong shapes | PRG_SET |
| --- | --- | --- | --- |
| ODANSHAY | BLU:MAG:GRE | CIR:CRO:SQU | DISABLER, SMOGGER, SHIELDER, ATTACKER |
| RAHNDAHL | YEL:RED:BLU | STR:TRI:CIR | SHIELDER, SHELLER, SPAMBOT, DISABLER |
| NEHBOCYET | RED:YEL:GRE | TRI:STR:SQU | SPOTTER, THROWER, E-BOMBER, ENHANCE |
| ECHOFALL | MAG:BLU:YEL | DIA:CIR:CRO | STATIC, SMOGGER, ATTACKER, SHIELDER |

Use the exact workbook IDs/order, not display-name reconstruction.

### Boss behavior remains unchanged

Do not redesign:

- ODANSHAY Override accumulation/threshold behavior;
- RAHNDAHL Capacitor behavior;
- NEHBOCYET Logic Bomb behavior;
- ECHOFALL concealment/BRAINSCRAMBLE behavior.

The new loadouts are intended to coexist with those mechanics. Interactions that arise from existing rules — for example SMOG stripping overlays when it creates NEU, or SPOTTER opening movement that can affect Logic Bombs — should follow the existing canonical mechanics rather than receive Boss-specific exceptions.

Boss Attack mode should instantiate the new authored `PRG_SET` and strong axes immediately and remains the primary direct Boss test path.

---

## 8. D-067 flag convention is load-bearing

Do not regress the Beta 0.5 polarity cleanup.

Canonical convention:

> **Boolean and random/targeted flags use 0 = no/random and 1 = yes/targeted. Other integer parameters are option lists whose values are defined per column.**

Examples relevant to this build:

- Bomb `dealDamage=1` means damage is enabled.
- Bomb `gainCharge=1` means charge is enabled.
- LineSlice follows the same convention.
- Mine trigger flags use `1 = fires`.
- CHARGE scope is **not a boolean**; `0`, `1`, and `2` are option values.

The new Bomb rows in the workbook are already authored under D-067. Do not translate them back to Alpha polarity.

---

# 9. EFFECT_HEAL

## 9.1 Authored encoding

The workbook defines:

- Effect: `EFFECT_HEAL`
- heal amount: `magnitude`
- `params`: blank
- amount: integer, `>= 0`

Current authored uses:

- `FNC_041 MEND`: 25
- `FNC_044 SALVEHEAL`: 12
- `FNC_063 MENDKIT`: 18

The workbook remains authoritative if those numbers change before implementation.

## 9.2 Resolution semantics

HEAL is owner-side restoration, not negative damage.

1. Identify the Effect owner.
2. Read that side's current health:
   - Hacker side → LINK;
   - System/Boss side → ICE.
3. Determine that combatant's **battle maximum**, not merely the raw base-sheet value:
   - Hacker maximum includes Deck `ADD_LINK` and any already-established battle construction modifiers;
   - System/Boss maximum includes the actual battle ICE after Run escalation or other existing construction rules.
4. Attempt to restore `magnitude`.
5. Clamp current health to the battle maximum.
6. Excess is wasted.
7. Emit/collect telemetry for attempted/applied/wasted healing.
8. No board resolution occurs.

HEAL must not:

- damage the opponent;
- interact with Shield;
- interact with Buff;
- interact with ARENA/function-damage bonuses;
- interact with `PSV_ABILITY_DAMAGE_RATE`;
- create overheal/temp HP;
- increase maximum LINK/ICE;
- revive a defeated actor.

If a previous payload already ended the battle, HEAL never executes.

## 9.3 Side-generic requirement

Although current authored content uses HEAL on the Hacker side, implement the Effect owner-generically so the same Effect correctly restores System/Boss ICE if later invoked there.

Add a synthetic System-side HEAL test so this does not become an unproven assumption.

---

# 10. EFFECT_SELF_DAMAGE

## 10.1 Distinguish it from the existing PASSIVE

The project already has `PSV_SELF_DAMAGE` under D-061. That is **environmental start-of-turn damage** and goes through the ordinary damage funnel, including Shield.

The new `EFFECT_SELF_DAMAGE` is intentionally different:

> **Function SELF_DAMAGE is a health resource cost paid by the Effect owner.**

Do not unify these two semantics merely because the names are similar.

## 10.2 Authored encoding

The workbook defines:

- Effect: `EFFECT_SELF_DAMAGE`
- cost amount: `damage`
- `params`: blank
- amount: integer, `>= 0`

Current authored uses:

- `FNC_047 OVERDRAWCOST`: 12
- `FNC_050 SPIKECOST`: 15
- `FNC_057 TRANSFUSECOST`: 20

## 10.3 Resolution semantics

1. Identify the Effect owner.
2. Subtract the configured amount directly from the owner's current LINK/ICE.
3. Clamp at zero; never produce negative health.
4. The cost **bypasses Shield**.
5. The cost bypasses ordinary damage reduction/modification.
6. Buff, ARENA and ability-damage-rate modifiers do not affect it.
7. It is not reflected and does not count as opponent damage dealt.
8. If the owner reaches zero, normal defeat/battle-end resolution occurs immediately.
9. If the Effect occurs before later payloads in the same Function chain, lethal SELF_DAMAGE aborts those later payloads.
10. Activation charge already spent is not refunded.

Prefer a dedicated health-cost/health-change seam over abusing `deal_damage` with exceptions if that keeps the distinction clearer. Do not create a second general combat pipeline.

## 10.4 Authored chain consequences

The following must execute in order:

- `OVERDRAW`: SELF_DAMAGE 12 → BUFF payload;
- `BLOODSPIKE`: SELF_DAMAGE 15 → ATTACK payload;
- `TRANSFUSE`: SELF_DAMAGE 20 → CHARGE payload.

For each, if the health cost is lethal, the second child Function does not execute.

Existing one-level Function-chaining depth remains unchanged. Child Function costs remain ignored under the established chaining rule.

---

# 11. EFFECT_CHARGE

## 11.1 Authored encoding

The workbook defines:

- Effect: `EFFECT_CHARGE`
- charge amount per target: `magnitude`
- target scope: one integer in `params`

Scope option list:

- `0 = SELF`
- `1 = OTHER_PROGRAMS`
- `2 = ALL_PROGRAMS`

`TARGETED_PROGRAM` is **not** authored and is out of scope.

Current live content uses only:

- `FNC_058 TRANSFUSECHARGE`
- magnitude `4`
- scope `1` (`OTHER_PROGRAMS`)

## 11.2 Target population

CHARGE operates on the owner's **active battle Program slots**, not every Program available in the Hacker/Deck catalogue and not the Deck active Function itself.

Scope semantics:

### SELF (`0`)

- target the activating Program only;
- valid when the Effect has a source Program;
- if invoked from a context with no source Program, this is an invalid runtime/content use and must fail loudly rather than guessing a target.

### OTHER_PROGRAMS (`1`)

- target every active allied Program except the source Program, if there is one;
- when invoked by a Deck active, there is no source Program, so **all active allied Programs are targets**;
- this is the authored TRANSFUSE behavior.

### ALL_PROGRAMS (`2`)

- target all active allied Programs, including the source Program if the source is itself a Program.

The Deck Function's own charge pool is never a target for any Program scope.

## 11.3 Direct-charge routing

For each target independently:

1. read charge before;
2. offer the configured `magnitude`;
3. accept only enough to reach the Program's normal charge cap;
4. discard excess for that target;
5. write charge after;
6. emit target-level telemetry.

Do **not** route excess through color/shape match-charge overflow behavior.

Do not create board resolution or synthetic Sync events.

## 11.4 Same-phase usability

Existing Hacker turn timing remains authoritative:

- Hacker may fire charged Programs/Deck Function before committing the normal Sync;
- Function activations do not themselves end that pre-Sync phase.

Therefore charge produced by TRANSFUSE can make Programs ready and those newly ready Programs **may be fired during the same pre-Sync Function phase**, exactly as any other Program that is ready at that point.

The UI must refresh charge/readiness immediately after CHARGE resolves.

Do not create a new action phase or an automatic fire.

## 11.5 System-side scheduling

Implement the Effect side-generically, but no current System/Boss Function uses it.

If a future enemy Effect changes Program charge during a System phase, CHARGE itself must not rewrite the System cast scheduler. Existing scheduling rules decide whether a newly ready Program is considered in that phase.

Do not speculatively add recursive firing behavior in Beta 0.6.

---

## 12. New Effect interaction/classification table

The Beta 0.5 coder specifically requested that new modifiers/triggers classify existing mechanics up front rather than leave edge cases to implementation-time rulings.

| Existing mechanic / modifier | HEAL | Function SELF_DAMAGE | direct CHARGE | MINE damage |
| --- | --- | --- | --- | --- |
| Shield | no interaction | bypasses | no interaction | applies normally, D-053 |
| Buff damage bonus | no | no | no | applies normally, D-053 |
| ARENA / Function damage increase | no | no | no | applies normally, D-053 |
| Ability-damage-rate PASSIVE | no | no | no | applies normally, D-054 |
| Match charge overflow routing | n/a | n/a | **never used; excess discarded** | existing Mine/removal behavior only |
| Damage-dealt metrics | no | not opponent damage | no | Mine bucket |
| Environmental-damage metric | no | **not** `environment_damage_taken` | no | no |
| Battle defeat check | cannot revive | immediate after cost | no direct health effect | existing lethal ordering |
| Board resolution | none | none | none | existing D-053 behavior |
| Countdown adjustment | none | none | none | Mine countdown adjusted at placement under D-060 |

Do not use this build to resolve AN-020's existing ARENA-versus-cascade classification inconsistency. None of the new Effects requires changing that rule.

---

## 13. Existing Mine implementation + new Mine content

Do not rewrite `EFFECT_MINE`.

Canonical Mine rules remain D-053, including:

- six trigger flags;
- `1 = fires`;
- classification once at removal;
- direct Slice vs Destroy vs HOST-direct-footprint distinction;
- 4-in-line collateral is **Destroy**, not Slice;
- removing action damage resolves before Mine damage;
- oldest Mine fires first;
- Mine damage uses the existing Mine damage source and ordinary modifiers;
- expiry damages only when the `expires` flag is set;
- save state carries Mine damage and triggers.

### New authored Mine Functions

`FNC_053 SEEDMINE`

- quantity 3;
- countdown 3;
- damage 18;
- triggers `1:1:0:0:0:0`;
- fires when sliced by owner or opponent;
- does not fire from Destroy/HOST/expiry.

`FNC_054 TRIPWIRE`

- quantity 2;
- countdown 5;
- damage 28;
- triggers `0:0:1:1:0:0`;
- fires when destroyed by owner or opponent;
- does not fire from Slice/HOST/expiry.

These two Functions are deliberately different tactical content. Tests must discriminate their removal-condition behavior rather than merely confirm that both can deal damage.

Existing VOLATILE (`FNC_023`) remains unchanged.

---

## 14. High-risk authored Function chains and interactions

Most new rows are ordinary data using existing Effects. These cases deserve explicit integration coverage because they cross engine seams.

### SALVE

`FNC_043` → `FNC_044 HEAL` → `FNC_045 BUFF`

- heal resolves first;
- then buff placement;
- parent cost paid once;
- child costs ignored.

### OVERDRAW

`FNC_046` → `FNC_047 SELF_DAMAGE` → `FNC_048 BUFF`

- health cost first;
- lethal cost aborts buff.

### BLOODSPIKE

`FNC_049` → `FNC_050 SELF_DAMAGE` → `FNC_051 ATTACK`

- health cost first;
- lethal cost aborts attack.

### TRANSFUSE

`FNC_056` → `FNC_057 SELF_DAMAGE` → `FNC_058 CHARGE`

- health cost first;
- lethal cost aborts all charge;
- surviving activation charges the active allied Programs under scope 1;
- newly ready player Programs can be fired immediately in the same pre-Sync phase.

### SPARK

`FNC_065 EFFECT_BOMB`

- authored countdown `0`;
- authored Bomb flags `0:1:1` under D-067;
- therefore it resolves as an immediate targeted/random-as-authored Bomb that deals damage and grants charge;
- D-060 remains canonical: countdown adjustment does **not** turn an authored instant Bomb into a countdown special.

Add a regression test with HAIRTRIGGER/FLOORIT-style countdown adjustment proving SPARK remains immediate.

### DAMPEN

`PRG_H_021` reuses `FNC_004 DRAIN`.

Manual player targeting of UNIT/DRAIN remains deferred under AN-001. Do not fold that UX/design change into this content pass. DAMPEN behaves through the current DRAIN targeting path.

### CUTTER

`PRG_H_024` reuses targeted DATACUT. Use the existing Packet-targeting UX and resolver path; do not create a FUSEBOX-specific target mode.

---

## 15. Validation requirements

Extend the current loader/validator rather than creating a parallel content parser.

### HEAL

Require:

- `magnitude` present;
- integer;
- `>= 0`;
- no params required.

### SELF_DAMAGE

Require:

- `damage` present;
- integer;
- `>= 0`;
- no params required.

### CHARGE

Require:

- `magnitude` present;
- integer;
- `>= 0`;
- exactly one scope option in params;
- scope in `{0,1,2}`;
- reject unsupported values.

### MINE

Retain the complete Beta 0.5 validation contract. Do not weaken it to accommodate new rows.

### Multi-Function composition

Retain existing one-level Function chaining and D-057 multi-Effect ownership rules.

The new rows must not require:

- deeper Function nesting;
- multiple Effects claiming the same data column;
- hidden defaults;
- silent repair of malformed tuples.

### Referential validation

Prove:

- every HAK `PRG_SET` ID exists in `PRG_H`;
- every DEK `PRG_SET` ID exists in `PRG_H`;
- every DEK active Function exists;
- every PRG_H Function exists;
- every BOS `PRG_SET` ID exists in `PRG_S`;
- all new display-name text rows exist;
- every player Program appears in exactly one Hacker or Deck authored Program set.

Invalid rows follow the existing load-error policy. Do not silently substitute defaults.

---

## 16. Logging and metrics

Extend the existing event funnel/collector architecture from D-025. Do not create a second telemetry path.

The event stream must retain stable IDs and presentation must resolve display names outside the logic layer under D-041.

### HEAL event/log data

Record at least:

- source Function ID;
- source Program/Deck/Boss identity where available;
- owner/healed side;
- health before;
- attempted heal;
- actually applied heal;
- wasted/capped heal;
- health after.

### SELF_DAMAGE event/log data

Record at least:

- source Function ID;
- source Program/Deck/Boss identity where available;
- owner side;
- health before;
- configured health cost;
- health after;
- lethal yes/no;
- whether later chain payloads were aborted.

Do not attribute this to opponent damage or to D-061's environmental-damage bucket.

### CHARGE event/log data

For the activation and each target, preserve enough information to answer:

- source Function/source identity;
- owner side;
- scope;
- charge offered per target;
- target Program ID;
- charge before;
- charge accepted;
- charge after;
- discarded amount.

Direct Function charge must be distinguishable from Sync/cascade/destruction charge sources.

### MINE

Preserve existing D-053 telemetry and ensure the new Mine Functions carry their own source Function/Program IDs through it.

### Metrics aggregates

Add aggregate fields sufficient to report, per side:

- healing actually applied;
- healing wasted to cap;
- Function SELF_DAMAGE health paid;
- direct charge accepted;
- direct charge discarded.

Source-level analysis can remain event/log based; do not explode the battle metrics schema into one field per Program.

Because the persisted/logged metrics shape changes, advance `BattleLog.METRICS_SCHEMA_VERSION` from 2 to 3.

If the battle save serializes the expanded metrics object in a shape that cannot be restored correctly from schema 5, advance the battle save schema rather than silently repairing an older beta save. D-030 still applies: no cross-version migration work is required.

---

## 17. Save/resume and content fingerprint

No parallel persistence structure is authorized.

### Existing state paths

Verify that ordinary state already preserves:

- LINK/ICE after HEAL/SELF_DAMAGE;
- Program charge after direct CHARGE;
- active Mines and their existing D-053 fields;
- selected Hacker ID;
- selected Deck ID;
- active four-Program build;
- Boss Program charge state and bespoke Boss state.

### Continuation tests

Add at least:

1. save after TRANSFUSE successfully charges Programs → resume → exact same charges/readiness;
2. save after HEAL or SELF_DAMAGE → resume → exact same LINK/ICE;
3. save with a NEEDLE Mine on board → resume → same countdown/trigger semantics;
4. save in a Boss battle using the new authored Program loadout → resume → same Program charge/loadout and Boss mechanic continuation.

### Fingerprint

The live content fingerprint must change because the workbook changed.

- compute it from the exported Beta 0.6 live data;
- pin the resulting value once in the existing canonical location;
- do not hand-author a value from this requirements document.

The frozen legacy dataset/fingerprint remains separate and should not be regenerated from live content.

---

## 18. Legacy oracle / parity policy

Beta 0.6 changes shared Function/effect-resolution code, so the old proof must be re-earned on the frozen legacy dataset.

Do **not** modify Alpha to add HEAL, Function SELF_DAMAGE, or CHARGE.

Required:

- fast legacy parity: 150/150;
- **DEEPSCAN: 5,250/5,250** on `tests/fixtures/legacy_data/`;
- no event-stream divergence on legacy content.

This proves the new Effect cases did not perturb inherited damage, charge, countdown, board, Function, or turn behavior when the new content is absent.

New Beta 0.6 Effects and content are proven by Beta tests and smoke matrices, not by Alpha.

Keep the D-058 rule: retire the oracle's content, not the oracle.

---

## 19. Automated functional coverage

The agent may refine fixture structure, but the following properties must be mechanically covered.

### 19.1 Workbook/content

- exact expected live counts from §3;
- all 4 Hacker rows load;
- all 4 Deck rows load;
- all 4 Boss rows load with the authored strong axes and Program sets;
- all 24 player Programs resolve to valid Functions;
- all 27 new Functions load;
- all 51 new text rows are available;
- no new PSV or PRG_S row is expected from Content Pass 2;
- all 16 Hacker × Deck combinations can construct a legal six-candidate Build pool.

### 19.2 HEAL

Prove:

- owner LINK increases by amount;
- heal caps at maximum;
- attempted/applied/wasted values are correct;
- heal at full health applies zero and wastes the full amount;
- System/Boss-side synthetic HEAL restores ICE;
- Shield and ability-damage modifiers do not alter HEAL;
- no board events are created.

### 19.3 Function SELF_DAMAGE

Prove:

- owner LINK/ICE decreases by exact amount;
- Shield does not reduce it;
- ability-damage rate/ARENA/Buff do not modify it;
- it is not counted as opponent damage;
- it is not counted as environmental PASSIVE damage;
- lethal self-damage ends battle;
- lethal cost aborts later chain payload;
- nonlethal OVERDRAW reaches BUFF;
- nonlethal BLOODSPIKE reaches ATTACK;
- nonlethal TRANSFUSE reaches CHARGE.

### 19.4 CHARGE

Prove:

- scope 1 from Deck active targets all active allied Programs and not Deck active;
- each target receives up to configured amount;
- caps are respected independently;
- excess is discarded per target;
- discarded charge never enters normal match overflow routing;
- per-target telemetry is exact;
- a newly ready Hacker Program can be fired in the same pre-Sync phase;
- scope 0/2 behave according to the workbook contract if supported as authored options;
- scope 0 without a Program source fails loudly rather than silently choosing another target.

### 19.5 Mine integration

Do not duplicate the entire D-053 suite unnecessarily; retain it and add discriminating content tests:

- SEEDMINE fires on Slice and not Destroy;
- TRIPWIRE fires on Destroy and not Slice;
- 4-match collateral remains Destroy;
- both respect countdown adjustment at placement;
- both save/resume through existing Mine state;
- source IDs/log attribution identify the correct new Function/Program.

### 19.6 Authored chains/content

- SALVE resolves heal then buff;
- OVERDRAW resolves cost then buff;
- BLOODSPIKE resolves cost then attack;
- TRANSFUSE resolves cost then charge;
- child costs remain ignored;
- one-level chain depth remains enforced;
- SPARK remains immediate at countdown 0 even under countdown-adjust effects;
- CHARGEPACK's Bomb damage+charge flags use D-067 polarity;
- LONGFUSE remains long-fuse damage-only;
- DAMPEN and CUTTER correctly reuse existing DRAIN/DATACUT semantics.

### 19.7 Bosses

For each Boss:

- exact authored `PRG_SET` loads in order;
- exact authored strong axes load;
- all four Programs can charge/fire under deterministic tests;
- the bespoke Boss mechanic still triggers correctly while those Programs operate;
- Boss Attack instantiates the authored loadout, not the Beta 0.5 placeholder set.

### 19.8 Existing content regression

- existing System/HOST/UPGRADE tests remain green;
- Beta 0.5 Mine baseline remains green;
- existing 244-battle Content Pass 1 smoke matrix remains mechanically stable; if its fixed setup is unchanged, record whether it reproduces the prior 187 Hacker wins rather than silently accepting drift;
- existing Run/session/Boss tests remain green after fixture expectations are updated for intentionally changed Boss loadouts.

Treat any `SCRIPT ERROR`, resource/import error, or unexplained error line during an otherwise green suite as failure until explained.

---

## 20. Content-smoke gates

The Beta 0.5 smoke matrix found a real integration defect that unit tests missed. Keep that style of gate.

### 20.1 Existing Content Pass 1 smoke

Retain the current System × HOST / UPGRADE coverage matrix and its counters.

### 20.2 Player-content smoke

Add a deterministic Beta 0.6 player-content smoke layer with coverage counters.

It must prove at minimum:

- all 16 Hacker × Deck pairings construct successfully;
- every `PRG_H_007`–`PRG_H_024` can enter a battle build;
- every newly authored top-level player Function executes at least once;
- child Functions in authored chains resolve at least once;
- HEAL applies at least once and caps at least once;
- Function SELF_DAMAGE applies at least once and is lethal in a synthetic/controlled case;
- direct CHARGE is offered, accepted, and discarded at cap in observed coverage;
- SEEDMINE and TRIPWIRE each trigger through their intended removal class.

The gate's job is primarily **coverage occurrence**, not balance outcomes.

### 20.3 Boss-content smoke

Using Boss Attack or a headless equivalent:

- instantiate each of the four Bosses;
- verify all 16 authored Boss Program placements are present;
- force/observe every distinct Boss Program firing at least once across deterministic seeds or controlled charge;
- observe each bespoke Boss mechanic at least once in the same loadout context;
- no deadlock/resolution loop/script error.

Do not inflate the smoke matrix merely to create a large number. Stop when the authored surface is actually covered.

---

## 21. Structural Run walks

Add/extend deterministic Run walks so the expanded player catalogue is exercised through the real session layer.

At minimum:

- one structural Run for each of the 16 Hacker × Deck pairings;
- force-win remains acceptable where useful because this is a structural gate, not balance evidence;
- each Run reaches later Build/Battle/Boss states without selection/persistence failures;
- acquired HOST/UPGRADE behavior remains ordinary;
- Boss battle uses the selected Boss's new loadout.

Report forced wins separately from natural wins. Do not present these walks as balance results.

---

## 22. Presentation and text integration

This is not an art/layout build.

No new graphics-pack key is required by HEAL, Function SELF_DAMAGE, or CHARGE.

MINE art already exists and remains canonical.

Requirements:

- new Hacker names resolve from `text_content`;
- new Deck names resolve from `text_content`;
- all new Program/Function names resolve;
- no MISSING text in chooser/build/battle/result flows;
- Hacker and Deck chooser lists fit the existing portrait layout with four rows;
- Build remains usable with six candidates;
- charge bars/readouts update immediately after TRANSFUSE;
- LINK/ICE bars update immediately after HEAL/SELF_DAMAGE;
- current skins remain complete; no pack regeneration should be needed unless implementation unexpectedly touches assets.

Do not address AN-026/AN-028 art-legibility items here unless a new regression makes the UI unusable.

---

## 23. Load warnings and naming

Do not rename authored Programs/Functions merely to suppress duplicate display-name warnings.

The catalogue intentionally contains Program names that match their Function names, and the new content may increase those warnings. AN-024 remains a separate validator/noise question.

For this build:

- no duplicate-name warning may become a fatal content error;
- report the final expected warning count/types in the handback;
- distinguish expected duplicate-name warnings from genuine missing/invalid-content warnings.

Do not broaden this content pass into a validation-policy redesign unless a warning masks a real failure.

---

## 24. Device verification split

Follow the existing two-device policy and the Beta 0.5 feedback that device-dependent completion must have a fallback.

### 24.1 Agent-owned mechanical/device checks — blocking

Use the permanently connected tablet for routine checks when available.

Verify on device or faithful phone-viewport emulation:

- title shows `beta-0.6.0`;
- Hacker chooser shows all four Hackers;
- Deck chooser shows all four Decks;
- Build displays six candidates without horizontal overflow;
- VITRA HEAL visibly increases LINK;
- RAZE SELF_DAMAGE visibly reduces LINK before the payoff;
- TRANSFUSE visibly changes Program charge immediately;
- NEEDLE's two Mine types retain the existing Mine visual and countdown behavior;
- Boss Attack shows/fights each Boss with the new Program loadout;
- no MISSING text;
- no script/resource errors.

If the tablet is unavailable, use the S25 rather than blocking the build.

### 24.2 S25 target sign-off

Use one batched announced S25 window near closeout where available.

Check:

- chooser/build fit at native 1080×2340;
- Program names/charge states remain legible;
- health/charge changes are immediately understandable;
- no safe-area or overflow regression;
- clean device log.

If the S25 is unavailable, run the headless gates plus tablet phone-geometry emulation and mark physical-phone sign-off as pending rather than pretending it ran.

### 24.3 Human judgement — separate from agent verification

The coding agent can verify that mechanics occur; it cannot sign off whether identities are fun, coherent, or well balanced.

Recommended director play after mechanical closeout:

- three normal Runs can pair the three new Hackers with the three new Decks so every new identity is experienced at least once;
- one Boss Attack against each Boss to judge whether the new Program loadout reinforces the bespoke mechanic;
- record balance/feel anomalies without broad retuning unless something prevents meaningful play.

Human feel is not to be simulated by `adb` taps and should be reported separately from the build's mechanical verdict.

---

## 25. Boundary/tooling checks

Run the established checks that protect environment boundaries:

- `export_workbook.py --check` against **the unsuffixed workbook**;
- scene/script parse/load gate;
- asset-bundle checks for installed packs even though no new art is expected;
- `fix_imports.py --check`;
- graphics-pack completeness/structural check at the currently established breadth;
- Android export;
- confirm CSVs remain packed with `importer="keep"`;
- confirm legacy fixture remains excluded from the APK;
- report whether the pre-existing general test fixtures still ship (AN-027); do not silently change export filtering unless separately authorized or obviously necessary to complete this build.

The working tree should end clean.

---

## 26. Explicitly out of scope

Do not expand Beta 0.6 into:

- final balance;
- broad retuning of existing values;
- more Systems/HOSTs/UPGRADEs;
- more PASSIVEs unless a true implementation dependency is discovered and approved;
- more System Program rows;
- new Boss bespoke mechanics;
- deeper Function chaining;
- targeted direct-CHARGE UI;
- manual DRAIN/DISABLER targeting (AN-001);
- resolution of AN-020's ARENA/cascade inconsistency;
- generic freeze/lock;
- reflection/thorns;
- charge stealing/siphoning;
- clone/copy-special mechanics;
- alternate gravity;
- save migration across beta versions;
- desktop/web target work;
- graphics/presentation jig;
- art/layout redesign;
- audio/VFX;
- final typography.

---

## 27. Implementation sequence

### Phase A — preflight and workbook audit

- read current lessons learned first;
- stage `breach-datastructures.xlsx` as the authoring source;
- reproduce the workbook delta in §2 mechanically;
- confirm no unexplained sheet changes;
- confirm D-067 polarity in the workbook/loader before touching new content;
- repoint exporter to the unsuffixed workbook;
- export/check data.

If an unexplained workbook difference would alter gameplay semantics, stop for director ruling rather than infer intent.

### Phase B — new Effect primitives

Implement and unit-test:

1. HEAL;
2. Function SELF_DAMAGE;
3. direct CHARGE.

Do not touch MINE except where integration/tests require use of the existing implementation.

Run the relevant logic suite and fast legacy parity after shared-core changes stabilize.

### Phase C — content import

Load:

- HAK_02–04;
- DEK_02–04;
- PRG_H_007–024;
- FNC_041–067;
- 51 new text rows;
- the four revised Boss rows.

Update live-content count/fingerprint fixtures.

### Phase D — logging/metrics/save proof

- add new event payloads and aggregates;
- bump metrics schema;
- update save schema only if the serialized metrics/state shape requires it;
- add continuation tests.

### Phase E — smoke/integration

Run:

- full maintained test suite;
- Content Pass 1 smoke;
- new player-content smoke;
- Boss-content smoke;
- 16 structural Hacker × Deck Run walks;
- fast legacy parity.

Fix any SCRIPT ERROR even when assertion totals are green.

### Phase F — full legacy proof

Run DEEPSCAN 5,250/5,250 on the frozen legacy dataset.

### Phase G — device verification

Use tablet routinely, then one S25 window where available, under §24.

### Phase H — closeout

Update:

- README;
- decision log for genuinely new engine semantics;
- architect notes for deferred design/balance issues;
- lessons learned;
- workbook change log if the coding agent edited authored data;
- handback.

Commit, push, and leave a clean working tree.

---

## 28. Decisions expected from implementation

Use the next available D-numbers. At minimum the implementation should record durable decisions for:

1. HEAL owner/max/cap semantics and telemetry;
2. Function SELF_DAMAGE as a resource cost distinct from D-061 environmental self-damage;
3. direct CHARGE scope/routing/cap/discard semantics;
4. any save/metrics schema change;
5. the Beta 0.6 live-content fingerprint;
6. any implementation-level clarification necessary for source identity or chain short-circuiting.

Do not create decision entries merely to restate every workbook row.

---

## 29. Required handback

Produce:

`1c38r34kr-beta-0.6.0-content-pass-2-handback.md`

Include:

1. verdict against this authorization;
2. exact final live content counts;
3. mechanical workbook diff and whether any coding-agent edits were made;
4. HEAL final semantics/implementation seam;
5. Function SELF_DAMAGE final semantics/implementation seam;
6. CHARGE final scopes/routing behavior;
7. confirmation that Mine remained D-053 behavior;
8. final Hacker/Deck roster and active Function IDs;
9. final Boss loadouts/strong axes;
10. logging/metrics fields and schema version;
11. save schema version and why it did/did not change;
12. live and legacy content fingerprints;
13. test assertion count/suites;
14. Content Pass 1 smoke result;
15. player-content smoke result and coverage counters;
16. Boss smoke result and coverage counters;
17. 16 Hacker × Deck structural Run-walk result;
18. fast parity result;
19. DEEPSCAN result;
20. tablet/device result;
21. S25 result or explicit fallback/pending state;
22. human-play items that remain for the director;
23. expected load warnings;
24. defects found/fixed;
25. decisions added;
26. architect notes added/resolved;
27. lessons learned appended;
28. deferred balance observations;
29. commit/push/clean-tree status.

---

## 30. Completion standard

Beta 0.6.0 is complete when:

1. the unsuffixed workbook is the active authoring source;
2. workbook round-trip/export check is clean;
3. live content contains 4 Hackers;
4. live content contains 4 Decks;
5. live content contains 4 Bosses;
6. all 24 player Programs load;
7. all 67 Functions load;
8. every Hacker has exactly 3 authored Program placements;
9. every Deck has exactly 3 authored Program placements plus its active Function;
10. all 16 Hacker × Deck combinations can construct a valid Build;
11. the active battle build remains four Programs;
12. all four Bosses use the authored Beta 0.6 Program loadouts;
13. all four Bosses use the authored Beta 0.6 strong axes;
14. bespoke Boss mechanics remain correct;
15. HEAL is implemented owner-generically;
16. HEAL caps at battle maximum health;
17. HEAL logs attempted/applied/wasted values;
18. Function SELF_DAMAGE is implemented as a health cost;
19. Function SELF_DAMAGE bypasses Shield and damage modifiers;
20. Function SELF_DAMAGE is not opponent or environmental damage;
21. lethal Function SELF_DAMAGE ends the battle;
22. lethal Function SELF_DAMAGE aborts later chain payloads;
23. CHARGE is implemented with workbook scopes 0/1/2;
24. TRANSFUSE scope 1 charges all active allied Programs and not the Deck Function;
25. CHARGE caps each target independently;
26. CHARGE discards excess rather than using match overflow routing;
27. direct charge can make a Program usable in the same Hacker pre-Sync phase;
28. direct-charge telemetry records offered/accepted/discarded per target;
29. MINE remains D-053 behavior;
30. SEEDMINE and TRIPWIRE are mechanically distinguishable by trigger class;
31. SPARK countdown 0 remains immediate under countdown-adjust effects;
32. authored Function chains execute in order and remain one level deep;
33. no new PASSIVE or System Program rows were invented unnecessarily;
34. new text rows resolve with no MISSING labels in normal flows;
35. metrics include healing, health-cost, and direct-charge aggregates;
36. metrics schema is advanced appropriately;
37. same-build save/resume preserves new-content state;
38. live content fingerprint is updated and pinned;
39. frozen legacy dataset remains separate and unchanged except for no authorized change;
40. full maintained suite is green with no unexplained SCRIPT ERROR;
41. Content Pass 1 smoke remains green;
42. player-content smoke covers every new authored player surface;
43. Boss-content smoke covers every authored Boss loadout surface;
44. all 16 structural Hacker × Deck Run walks complete;
45. fast legacy parity is 150/150;
46. DEEPSCAN is 5,250/5,250;
47. chooser/build/battle presentation remains usable on the routine Android device;
48. S25 target verification is complete or explicitly recorded as pending under the authorized fallback;
49. no broad balance pass was folded into implementation;
50. no graphics jig/art/audio work was added;
51. project records and lessons learned are updated;
52. intended changes are committed and pushed;
53. working tree is clean.

---

## 31. Post-build position

After Beta 0.6, the game should have the intended initial breadth on both sides:

- four Hacker identities;
- four Deck identities;
- a six-candidate / four-active player Program build space;
- the existing broad System/HOST/UPGRADE catalogue;
- four Bosses with both bespoke mechanics and authored Program identities.

That is the point where combination testing and balance work become substantially more informative than adding another immediate Effect tranche. Presentation work can remain on the live-skin workflow until content and initial art direction justify the later jig/VFX/audio phase.
