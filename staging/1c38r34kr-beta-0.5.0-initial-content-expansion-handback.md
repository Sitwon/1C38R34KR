# 1C38R34KR Beta 0.5.0 — Initial Content Expansion

## Handback

Answers `1c38r34kr-beta-0.5.0-initial-content-expansion-authorization.md` item
by item (§26), then lists every deviation from the doc and gives feedback for
the next requirement doc.

---

## 1. Verdict

**Complete against the authorization.** The tablet's battery was flat at
closeout, so at the director's direction the §20 device pass ran on the S25
instead (§13–§14).

Every headless gate is green:

- 4,096 tests, 0 failed;
- the content smoke matrix;
- 20/20 Run walks;
- the workbook round-trip;
- the asset, import and parse checks;
- the Android export;
- DEEPSCAN on the legacy oracle: 5,250/5,250.

Ten questions were resolved with the director before the build. Their rulings
override the doc where they differ, and are listed in §21.

---

## 2. Content and pool counts

| | Rows | Pool |
| --- | ---: | --- |
| Systems | 11 (+8) | 10 random; DOORMAN excluded and fixed for Battle 1 |
| HOSTs | 10 (+5) | 9 random; THRESHOLD excluded and fixed for Battle 1 |
| UPGRADEs | 10 (+6) | all 10 in the existing reward rules |
| System Programs | 26 (+18) | PRG_S_009–026 |
| Functions | 40 (+18) | FNC_023–040 |
| PASSIVEs | 20 (+11) | PSV_018–020 authored and unreferenced |
| `text_content` | 241 (+66) | |

The pool counts are pinned in `test_run_state.gd` and
`test_content_expansion.gd`.

## 3. Imported roster

**Systems:**

| System | Strong colours | Strong shapes | Programs (new in bold) |
| --- | --- | --- | --- |
| SAPPER | RED:GRE:BLU | TRI:STR:CIR | **PROXMINE**, DISABLER, … |
| MAMMOTH | RED:GRE:YEL | TRI:SQU:STR | **TUSK, STOMP, THICKHIDE, FORAGE** |
| ARCHON | RED:YEL:BLU | TRI:STR:CIR | **SHELLER, SIGHT, JAMMER, SPOTTER** |
| HARRIER | RED:MAG | TRI:CRO | **RAGER, FRENZY**, … |
| GNAT | GRE:YEL:BLU | SQU:STR:CIR | **PEPPER**, … |
| LEECH | GRE:BLU | SQU:STR:CIR | **DRIPPER**, PROXMINE, … |
| STATICIAN | BLU:MAG | STR:CIR:DIA | **STATIC, RESEED, SMOGGER**, DISABLER |
| ORCHID | GRE:MAG | TRI:SQU:CRO | **BLOOMER, NECTAR**, … |

SYS_01–03 take the newly authored strong sets.

**HOSTs:** FLOORIT (countdown −1), MEGATON (ability damage +50%), REDSHIFT (RED
drop +15%), ACID (10 self-damage at turn start), FURNACE (`ALL:1` match
damage).

**UPGRADEs:**

| UPGRADE | Effect | PASSIVE |
| --- | --- | --- |
| EDGE | RED +1 Sync damage | reuses PSV_001 |
| DYNAMO | RED +1 Sync charge | reuses PSV_002 |
| CERULEAN | BLU +1 Sync damage | |
| GOLDRUSH | YEL drop +15% | |
| HAIRTRIGGER | own countdowns −1 | reuses PSV_010 |
| BULWARK | enemy ability damage −25% | |

## 4. New runtime semantics

The full rules are in `decisions.md`. In brief:

- **`EFFECT_MINE`** (D-053).
  - **Tuple:** six flags, `1` = fires: sliced by owner, sliced by opponent,
    destroyed by owner, destroyed by opponent, destroyed by HOST, expires.
  - **Classification:** once, when the Mine is removed.
  - **Damage:** after the removing action's own damage, oldest Mine first.
    Nothing fires if that action was lethal.
  - **Pipeline:** the ordinary `deal_damage` path (source `MINE`): Buff, then
    ARENA, then the rate, then Shield.
  - **Expiry:** harmless unless `expires` is set.
- **`PSV_COUNTDOWN_ADJUST`** (D-060): summed and applied at placement, floored
  at 0. A special adjusted to 0 is delivered at once. Instant Bombs are never
  adjusted.
- **`PSV_ABILITY_DAMAGE_RATE`** (D-054): rates are summed, applied once with
  truncating integer division, and applied before Shield. It covers direct
  Function hits only. It never touches Sync damage, SELF_DAMAGE, or cascade
  waves that follow a Function.
- **`PSV_PACKET_DROP_RATE`** (D-055): integer weights start at 100 and each
  instance adds to its target. There is one RNG draw per axis. With nothing
  active, the exact original path runs. The neutral rate is unchanged.
- **`PSV_SELF_DAMAGE`** (D-061): applied at the start of the active side's
  turn, before countdowns, through the ordinary funnel. It is environmental, so
  no rate applies and it is credited to the target.
- **`PSV_STRONG_SLICE_BONUS`** (D-062): applied once per sliced Packet that is
  strong on the slicing axis. It covers Sync and LineSlice, not Bomb or Mine.
- **`PSV_EXTRA_MATCH_DAMAGE` `ALL`** (D-062): the first param is now a selector
  (colour, shape or `ALL`). The bonus is still once per Sync.

## 5. Mine presentation

The Mine is an open ring with eight outward spikes; a Bomb is a filled body.
The art (`mark_mine`, `ring_mine`) is generated deterministically by
`gen_boss_marks.py` into all six packs, through the full pack pipeline. The
Mine uses its own `OVERLAY_TINT`, countdown digits as for other armed overlays,
and ownership through the existing badge (D-065).

Checked on desktop in all six skins at phone layout with the new
`tools/shot_battle.gd`. The battle debug bar's `ovl` row now also stamps an
armed Hacker Mine and an armed System Mine, for checking on the device.

## 6. Extensions to existing Effects and machinery

- **Multi-Effect leaf payloads** (STOMP), D-057.
- **Transform to `NEU`** (SMOG), D-056. Both axes are cleared and the overlay
  is stripped.
- **System auto-targeting** for Packet-targeted Functions with no algorithm
  (SPOTTER), D-059.
- **`check_unreferenced_functions`** now counts the children of a *referenced*
  composite as referenced. This fixes a defect that predates 0.5: FORAGE's
  children would have warned.

## 7. Text-content additions

There are 66 new rows, all added by script into the working workbook and
exported:

- display names for SYS_04–11, HST_06–10, UPG_05–10, PRG_S_009–026 and
  FNC_023–040 (55 rows);
- `PASSIVE_TEXT` for PSV_010–020 (11 rows):

| PASSIVE | Text |
| --- | --- |
| PSV_010 | New countdowns adjusted by %0 |
| PSV_011 | Ability damage %0 |
| PSV_012, PSV_016 | %1 packets drop %0 more often |
| PSV_013 | Take %0 damage at the start of each turn |
| PSV_014 | Deal %1 extra damage on every sync |
| PSV_015 | Deal %1 extra damage on a %0 sync |
| PSV_017 | Enemy ability damage %0 |
| PSV_018 | Enemy countdowns adjusted by %0 |
| PSV_019 | Gain %1 extra charge on a %0 sync |
| PSV_020 | Deal %0 extra damage per strong packet sliced |

Signed values and percent signs are rendered into the token (`+50%`, `−1`),
not written into the template. The text framework's `%N` placeholder check
rejects a bare `%` in a template.

**This wording is v0 and mine. It is the director's to revise.**

## 8. Fingerprint and save schema

| Item | Change | Decision |
| --- | --- | --- |
| Content fingerprint | `ce01939e-fwf` (legacy dataset `ca95eed5-96w`) | D-064, D-067 |
| Battle save | schema 3 → 4 (Mine `damage`/`triggers`) → 5 (flag polarity); old saves rejected | D-030, D-067 |
| Session envelope | unchanged at 3 | |
| Battle-log metrics | schema 1 → 2 (`mine` bucket, `environment_damage_taken`) | |

Mine save/resume continuation is tested.

## 9. Tests

The suite has **4,096 assertions across 26 suites, 0 failed.** It prints 18
`ERROR` lines, which are the deliberate negative-path cases, identical to the
pre-build baseline.

The new `tests/test_content_expansion.gd` covers every §18 item:

- pools and counts;
- multi-Effect order and lethal stop;
- composite chaining;
- Mine placement, each of the six trigger classes, expiry on and off, ordering,
  Shield, lethal ordering, and save/resume;
- countdown-adjust stacking and floor;
- rate aggregation, with odd-value rounding;
- exact weighted draw replay;
- ACID ordering and lethality;
- FURNACE with stacking;
- the strong-slice bonus, including the dual-axis case;
- SMOG to NEU;
- the HOST-cascade Mine regression.

## 10. Content smoke matrix

**PASS.** `tools/content_smoke.gd` ran 244 battles:

- an 11×10 System × HOST grid;
- UPGRADE battles in which each PASSIVE can fire;
- coverage counters for every new Function, every HOST's PASSIVE events, and
  every Mine trigger cause.

Results:

- No crash, SCRIPT ERROR, resolution loop or targeting deadlock.
- Every new Function executed (SHELL and NECTAR least often, twice each).
- Every HOST and UPGRADE produced its effect. REDSHIFT and GOLDRUSH weight the
  RNG draws, which logs nothing, so the matrix verifies them by replaying the
  weighted draws instead.

## 11. Run walks

**20/20 complete.**

- 11/11 Systems met, DOORMAN included.
- 10/10 HOSTs met.
- 10/10 UPGRADEs acquired.
- In 12 battles the walk forced a win after three losses so the Run could
  progress. That is by design for a structural walk.

## 12. Legacy parity and the new oracle boundary (D-058)

Live content no longer matches the Alpha, by design. The differential now runs
on `tests/fixtures/legacy_data/`, the frozen pre-0.5 CSVs:

- **fast tier: 150/150**;
- **DEEPSCAN: 5,250/5,250, no divergence** (default, reinforced, timer,
  uncapped).

**What it proves:** every shared path this build changed (damage, cascades,
refill, countdown delivery, placement) still behaves bit-identically to the
Alpha on shared content.

**What it does not cover:** Mine, the new PASSIVEs and the new rows. Those are
proven by §9 and §10 above. The loader, CSV, validation and route-fixture
suites also run on the legacy fixture.

## 13. Tablet result

**Not run: the tablet's battery was flat.** At the director's direction, the
device pass moved to the S25 (§14).

## 14. S25 result

**Pass, with two defects found and fixed.** The run used
`build/1c38r34kr.apk` on an SM-S938U at its native 1080×2340, so no geometry
emulation was needed.

- **Install, launch, log.** Clean. No `ERROR`, `SCRIPT ERROR` or `FATAL` in
  the Godot log or the full logcat.
- **Choosers.**
  - The System list (11), HOST list (10) and Boss list all fit at phone
    width with no horizontal overflow.
  - Long Weak lines (HARRIER, LEECH, STATICIAN, ORCHID) wrap cleanly.
  - The lists scroll by the scrollbar. The two-finger gesture is by design
    (AN-002); `adb input` cannot produce it.
  - No MISSING text. All new HOST and UPGRADE PASSIVE text renders, including
    `+50%`, `-1`, `15%` and `-25%`.
- **Run route screen.** The new UPGRADEs (BULWARK, CERULEAN) are offered with
  readable text.
- **SAPPER on FLOORIT, played six turns by hand.**
  - PROXMINE charged and cast VOLATILE: four System Mines, each with countdown
    **3** (4, then FLOORIT −1).
  - My Sync through a Mine fired it for **20 to the Hacker**, *after* my own
    match damage.
  - The System's own Sync through another Mine fired it for 20 (`slice_owner`).
  - All of this matches D-053.
- **Mine presentation.**
  - A spiked ring with a black centre (System) or white centre (Hacker),
    clearly distinct from the round Bomb badge.
  - Countdown digits are legible.
  - Checked live in all six skins on the phone. bzone's digits are small but
    readable (AN-026).
- **The device pass replayed headlessly.** The battle (seed 315250118, six
  recorded swaps) was replayed with `Game` directly. It reproduced the device
  exactly (LINK 135 → 132 → 126 → 111 → 94 → 43), which is how the first defect
  below was diagnosed.

**Defects found on the device:**

1. **The debug `ovl` stamp reused placement numbers.** It numbered its
   overlays from 0 and never advanced `state.next_seq`. VOLATILE's Mines then
   received numbers already held by stamped overlays still on the board.
   `_tick_countdowns` finds an overlay by number, so it ticked a stamped
   DISABLER overlay instead of a Mine, which stayed at 3.

   Debug-only: real placements always take `next_seq`. Fixed so the stamp now
   draws from and advances the battle's counter. The replay confirms every Mine
   ticks.
2. **The title still read "beta 0.4".** `Content.GAME_VERSION` is bumped to
   `beta-0.5.0`. It identifies the build only, not the content fingerprint.

Not covered on the device, beyond the automated matrix: MAMMOTH, ARCHON and
STATICIAN; MEGATON, BULWARK, ACID and FURNACE in live play; and a full Run
through later battles. These need a human playing at length, which `adb` taps
cannot reasonably substitute for. They are recommended for the director's own
play on the next device session.

## 15. Boundary checks

| Check | Result |
| --- | --- |
| `export_workbook.py --check` | clean, 13/13 sheets |
| Scene/script parse and load (every `.gd`/`.tscn` through `ResourceLoader`) | 87 loaded, 0 failed |
| `asset_bundle.py check`, all six packs | 61 assets + palette each |
| `gen_pack_resource`, all six packs | `pack.tres` regenerated, complete |
| `check_assets.gd` (v0) | clean, including `mark_mine` |
| `fix_imports.py --check` | 372/372 |
| Android export | 0 errors; CSVs (`importer="keep"`) and Mine art confirmed inside the APK; `legacy_data` excluded |
| Install, launch, device log | ✅ S25, clean |

## 16. Defects found

1. **Mines sliced in a HOST-started cascade were classified `destroy_host`**
   and never fired. Found by the smoke matrix and fixed with the `direct`
   argument. A regression test covers it.
2. **`check_unreferenced_functions` ignored composite children.** This predates
   0.5. Fixed.
3. **Workbook data:**
   - five Bomb/LineSlice rows had their flags reversed (AN-021);
   - PSV_010's activation was misspelled `CONTNUAL`;
   - SMOG's retention flag could not be honoured.

   All three were corrected in the workbook by script.
4. **On the S25: the debug `ovl` stamp reused placement numbers**, so one
   Mine never ticked; and the **title still read "beta 0.4"**. Both are fixed
   (§14).
5. **The first Mine mark's spikes were invisible in the pixel packs.**
   Enlarged.
6. **Test-only problems:**
   - fixture actors lacked `kind`, which raised a silent SCRIPT ERROR;
   - an accidental 4-match in a fixture;
   - a vacuous frequency assertion;
   - a wrong "paid once" assumption about FORAGE.

   All four were caught before commit.

## 17. Decisions added

D-053 through D-067:

| Decision | Topic |
| --- | --- |
| D-053 | Mine |
| D-054 | Ability rate |
| D-055 | Drop weights |
| D-056 | Transform to NEU |
| D-057 | Multi-Effect payloads |
| D-058 | Legacy oracle |
| D-059 | System auto-target |
| D-060 | Countdown adjust |
| D-061 | Self-damage |
| D-062 | FURNACE and strong-slice bonus |
| D-063 | Required-ID lists |
| D-064 | Schemas |
| D-065 | Mine art |
| D-066 | Working workbook |
| D-067 | One flag polarity: 0 = no, 1 = yes |

The §25 requirements map as follows:

1. Mine trigger and expiry: D-053.
2. Rate aggregation and rounding: D-054.
3. Drop weights: D-055.
4. Transform to NEU: D-056.
5. Oracle narrowing: D-058, which extends D-045 and D-051.

## 18. Architect notes

AN-020 through AN-028 were added. AN-021 is resolved by D-067.

| Note | Topic |
| --- | --- |
| AN-020 | ARENA and the rate disagree on cascade waves |
| AN-021 | Flag polarity and mixed vocabularies |
| AN-022 | Q5 and Q6 to make explicit |
| AN-023 | Boss loadouts are placeholders and identical |
| AN-024 | Load warnings |
| AN-025 | Balance observations |
| AN-026 | bzone digit legibility |
| AN-027 | Test fixtures ship in the APK |
| AN-028 | An armed Bomb on a star Packet reads as spiked; colour tokens render as `Blu` |

## 19. Lessons learned

Appended under "Beta 0.5.0":

- the matrix found what unit tests were built not to see, through a
  dynamic-scope flag leak;
- retire the oracle's content, not the oracle;
- fixture shape drifted from real shape again;
- cross-check the notes against the structure;
- desktop first for presentation.

## 20. Left deliberately unchanged

- **Hacker win rate ≈77% in the smoke matrix.** No baseline was compared, so
  this is recorded as a number to track (AN-025).
- **SHELL and NECTAR rarely resolve** before a battle ends.
- **Boss Program loadouts are placeholders and now identical** (AN-023).
- **Ten Function/Program duplicate-name warnings** (AN-024).
- **ARENA applies to Function cascade waves and the rate does not** (AN-020).
- **bzone countdown digits are low-contrast** (AN-026).
- **Test JSON ships in the APK** (AN-027).

---

## 21. Deviations from the authorization

**Director rulings** (these override the doc):

| Q | Doc | Built |
| --- | --- | --- |
| 1 | §23: Boss content out of scope | Changed BOS strong sets accepted as correct |
| 2 | Workbook as supplied | Flags flipped on STOMP, SHELL, PEPPER (`0:0:1`), NECTAR (`0:0:0`) and SPOTTER (`0:1:0:0:1`), in the old polarity. Under D-067 these read `0:1:0`, `0:1:1` and `0:1:0:1:0` |
| 3 | No System targeting rule | General random-valid-target rule (D-059); no load error |
| 4 | PSV_010 `CONTNUAL` | Corrected in the workbook |
| 5 | §9: "+1 per sliced Packet" | Once per Sync (D-062) |
| 6 | Collateral classification unstated | 4-line collateral counts as destroyed (D-053) |
| 7 | Lethal ordering | Action damage first, then Mines oldest first |
| 8 | §8.2 rate scope | Direct hits only, not following cascade waves (D-054) |
| 9 | §10/§18.9: retained overlay on NEU | Rule "neutral carries no overlay" kept; SMOG changed to `0:0`. The §18.9 retention assertion is replaced by a stripping assertion |
| — | Bomb/LineSlice flags read 0 = yes | After closeout, by director instruction: every yes/no flag reads 0 = no, 1 = yes; workbook, param notes, engine and legacy dataset flipped together (D-067) |
| 10 | `…-working(2).xlsx` | `breach-datastructures-working.xlsx` is the source for this build; exporter repointed (D-066) |

**My own interpretations:**

- **The required-ID lists were not extended** (D-063). The counts are pinned in
  tests instead, because extending the lists broke the legacy-oracle load.
- **`PSV_EXTRA_MATCH_DAMAGE` accepts shape tokens as well as `ALL`**, reading
  §14's "selector" literally.
- **Mine art went to all six installed packs**, not the four named in my
  pre-build assumptions. That is what §7 requires.
- **Countdown adjustment never touches instant (countdown 0) Bombs or Buffs**,
  and a result of 0 is delivered immediately.
- **The DEEPSCAN, loader, CSV and route suites now run on a frozen legacy
  dataset** rather than live data (§17 allowed this; the mechanism is mine).
- **New tools not requested:** `tools/shot_battle.gd` (desktop screenshots) and
  `--data` on `trace.gd`/`parity.mjs`.

---

## 22. Feedback for the architect

1. **Name the input file exactly.** The doc named `…-working(2).xlsx`; the
   file was `…-working.xlsx`. It was harmless here, but a wrong filename is the
   first question a coder has to ask.
2. **Ship a mechanical workbook diff with the doc, and classify each change as
   intended.** The Boss strong sets changed with no mention, and they were the
   first question asked. A generated "what changed" table, with an
   intended/unintended column, turns that question into a glance.
3. **State flag polarity next to every flag column**, and avoid mixed `0`/`1`
   vocabularies in new contracts (AN-021). The single largest data correction
   in this build was a polarity inversion that every validator accepted.
4. **When citing "the established rule", quote it.** §9's "+1 per sliced Packet
   under the established rule" contradicted the rule it cited. Quoting the
   existing behaviour, or a D-number, would have exposed the conflict while the
   doc was being written.
5. **Check new requirements against `decisions.md`.** §10/§18.9 asked for a
   retained overlay on a neutral Packet, which an existing rule forbids. A
   pass that greps decisions for each touched mechanic would catch these.
6. **For every new trigger or modifier, give the classification of each
   existing source.** Mine needed "is 4-line collateral a slice?" and the rate
   needed "is a Function-started cascade ability damage?". Both were answered
   by ruling, and the second contradicts ARENA (AN-020). A table of existing
   sources × new rule is short to write and settles these up front.
7. **Say how the System uses a targeted Function** whenever System content
   authors one. SPOTTER would have been a silent no-op.
8. **Keep §19's smoke matrix in every content doc.** It found the build's only
   real mechanic defect, which the unit tests could not see by construction.
   Asking for coverage *counters* ("every Function fired at least once") rather
   than outcomes was exactly right.
9. **Give device-dependent completion items a fallback.** The 55-item standard
   is thorough. Separating the headless gate from the device gate, and saying
   what to do when the device is unavailable, would let a build close cleanly
   and record the device pass as its own step. This build's tablet was flat
   at closeout, and the director redirected the pass to the S25.
11. **Say which play checks need a human.** "Play SAPPER, MAMMOTH, ARCHON…"
    reads as one task. Placement and visual checks are self-serve through
    `adb`. Feel and longer play are not, and listing them separately would
    keep a device window short.
10. **For agent-edited workbooks, ask for a change log from the editor agent.**
    The notes-versus-tuple cross-check found the flag errors. A log of what the
    editor changed and why would let the coder check intent rather than infer
    it.
