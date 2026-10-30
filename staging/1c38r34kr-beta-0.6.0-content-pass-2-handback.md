# 1C38R34KR Beta 0.6.0 — Content Pass 2
## Handback

**Build identity:** `beta-0.6.0`
**Answers to:** `1c38r34kr-beta-0.6.0-content-pass-2-authorization.md`
**Live content fingerprint:** `8dc8bc04-mgi`, legacy `ca95eed5-96w` (unchanged)

---

## 1. Verdict

**Complete against the authorization's §30**, with S25 sign-off recorded in
§21 below.

All three Effects are implemented on the existing seams. The catalogue loads
exactly as authored. All sixteen Hacker × Deck pairings build, fight and
complete a Run. The four Bosses field their authored loadouts beside
unchanged mechanics.

Every inherited path still matches the Alpha on the frozen legacy data: fast
parity is 150/150, and DEEPSCAN is 5,250/5,250.

No balance tuning was done. No workbook value was edited.

Director input taken before the build (it overrides the doc; deviations are in
§1a):

| Q | Ruling |
| --- | --- |
| Q1 | Constructed Quick Match and Boss Attack get Hacker → Deck choosers (CR45H/AGIMA first) |
| Q2 | Random Quick Match rolls the Hacker and Deck too |
| Q3 | Delete the old workbooks; one unsuffixed workbook |
| Q4 | Save schema 5 → 6 alongside metrics schema 2 → 3 |

### 1a. Deviations from the authorization

| Where | Doc | Built | Why |
| --- | --- | --- | --- |
| §6 Quick Match | "Constructed Quick Match … use the chosen Hacker and Deck" (no chooser existed) | Hacker → Deck choosers added to Constructed Quick Match | Q1 |
| §7 / beta 0.4 §10.2 | Boss Attack plays the canonical default pair | Boss → Hacker → Deck, then that pair's default build | Q1 (D-073) |
| §6 random paths | "where the current architecture treats those sheets as pools" (none did) | Random Quick Match rolls Hacker, then Deck, then the alpha draw | Q2 (D-073) |
| §2 | stage the unsuffixed workbook | also deleted `breach datastructures.xlsx` and `breach-datastructures-working.xlsx` from the repo | Q3 (D-074) |
| §16 | bump the save schema only if needed | bumped 5 → 6 | Q4; the battle save carries the metrics accumulator (D-071) |

No other deviation. Nothing in §26 was built.

---

## 2. Final live content counts

4 Hackers · 4 Decks · 4 Bosses · 11 Systems · 10 HOSTs · 10 UPGRADEs ·
24 `PRG_H` · 26 `PRG_S` · 67 Functions · 20 PASSIVEs · 292 `text_content`
rows.

Every count is pinned in `test_content_pass_2.gd`. The 24 player Programs make
exactly 24 placements, each Program in exactly one Hacker or Deck set: 3 per
Hacker and 3 per Deck. The engine's required-ID lists were not grown (D-063).

## 3. Workbook diff and edits

A scripted cell-by-cell diff of `staging/breach-datastructures.xlsx` against
the final 0.5 working workbook found the following:

| Sheet | Delta |
| --- | --- |
| `PRG_H` | +18 rows (H_007–024) |
| `FNC` | +27 rows (041–067) |
| `HAK` | +3 rows |
| `DEK` | +3 rows |
| `BOS` | 4 rows: strong axes and `PRG_SET` |
| `text_content` | +51 rows |
| `param notes` | HEAL / SELF_DAMAGE / CHARGE contracts and the Mine note |
| `dataset notes` | +2 rows |
| `PRG_S`, `SYS`, `PSV`, `HST`, `UPG`, `font_refs`, `text_style`, `gameplay conventions`, `boss passive notes` | **0 cells** |

That is exactly §2. **The coding agent made no workbook edits.** The
exporter now points at the unsuffixed workbook. `export_workbook.py --check`
is clean, and the exported CSV diff contains only the rows above.

D-067 polarity was confirmed before import. All new Bomb rows read
`targeting:dealDamage:gainCharge` as 0 = no / 1 = yes. CHARGEPACK and SPARK
are `0:1:1` (damage and charge); FLARE and LONGFUSE are `0:1:0`.

## 4. HEAL (D-068)

- **Contract:** `magnitude`, integer ≥ 0, no `params`.
- **Resolution:** `Game._cast_heal` calls `Resolve.heal`. It restores the
  owner's LINK or ICE up to `GameState.max_hp_of(side)`, the battle's
  constructed maximum (Deck ADD_LINK, Run escalation and manual settings
  already applied). Excess is wasted.
- **Untouched by:** Shield, Buff, ARENA, ability rate. No board resolution,
  no revive.
- **Side-generic:** a synthetic System-side HEAL is tested.
- **Telemetry:** one `heal` event with before / attempted / applied /
  wasted / after, the source and the Function.

## 5. Function SELF_DAMAGE (D-069)

- **Contract:** `damage`, integer ≥ 0, no `params`.
- **Resolution:** `Game._cast_self_damage` calls `Resolve.pay_health`, a
  direct LINK/ICE write floored at 0, outside `deal_damage`.
- **Bypasses:** Shield and every modifier. It emits no `damage` event, credits
  no opponent, and is not `environment_damage_taken`.
- **Lethal:** the `healthCost` event is followed by `Resolve.end_battle`, the
  transition the damage funnel now shares. The chain stops through the
  existing winner check in `_cast_actor`. The event records `lethal` and
  `aborted_ops`. Charge already spent is not refunded.
- **Unchanged:** PSV_SELF_DAMAGE (D-061) is pinned by test as environmental,
  not a cost.

## 6. CHARGE (D-070)

- **Contract:** `magnitude` ≥ 0, plus one scope in `params` (0 SELF,
  1 OTHER, 2 ALL); any other value is rejected.
- **Targets:** the owner's active units only, so the Deck pool can never be
  hit. The source Program arrives as `actor.unit_idx`. A Deck has none, so
  OTHER from TRANSFUSE charges all four Programs.
- **SELF without a Program:** a **load** error for any Deck active, PASSIVE
  carrier or Boss mechanic Function (`check_charge_self_sources`). At runtime,
  a `push_error` and an unresolved op.
- **Routing:** per target, `add_unit_charge` caps at the Program's pool and
  discards the rest. Never match routing. No `chargeRoute`, `chargeWaste` or
  `deckCharge` event, and no board resolution.
- **Same window:** a Program made ready can fire in the same pre-Sync window.
  Tested headlessly, observed 40 times in the smoke, and done by hand on the
  tablet (TRANSFUSE → OVERDRAW).
- **Telemetry:** a `directCharge` event with a per-target list of before /
  accepted / after / discarded. The aggregates are kept apart from
  `charge_wasted_total`.

## 7. Mine

**`EFFECT_MINE` is untouched** (D-053). SEEDMINE and TRIPWIRE place through
it, with their authored values stamped: owner, countdown 3 / 5, damage
18 / 28, triggers, Program and Function. Countdown adjustment applies at
placement (D-060).

Tests discriminate removal class: SEEDMINE fires on Slice by either side, and
not on Bomb destruction or 4-match collateral; TRIPWIRE is the reverse. In
the smoke, SEEDMINE fired 72 times, all through Slice, and TRIPWIRE 41 times,
all through Destroy. No contradiction was observed.

## 8. Roster

| Hacker | LINK | Programs |
| --- | ---: | --- |
| HAK_01 CR45H | 100 | PRG_H_001 BOMBER, 002 BUFFER, 005 NINJA |
| HAK_02 VITRA | 110 | PRG_H_007 MENDER, 008 AEGIS, 009 SALVE |
| HAK_03 RAZE | 90 | PRG_H_010 OVERDRAW, 011 BLOODSPIKE, 012 FLARE |
| HAK_04 NEEDLE | 100 | PRG_H_013 SEEDMINE, 014 TRIPWIRE, 015 STAIN |

| Deck | ADD_LINK | Programs | Active Function |
| --- | ---: | --- | --- |
| DEK_01 AGIMA | 50 | PRG_H_003, 004, 006 | FNC_010 SCRAMBLE |
| DEK_02 BLEEDLINE | 40 | PRG_H_016 LANCET, 017 CLOT, 018 SURGE | FNC_056 TRANSFUSE |
| DEK_03 BASTION | 60 | PRG_H_019 MENDKIT, 020 BULWARK, 021 DAMPEN | FNC_062 REINFORCE |
| DEK_04 FUSEBOX | 45 | PRG_H_022 CHARGEPACK, 023 LONGFUSE, 024 CUTTER | FNC_065 SPARK |

Every Deck active starts charged through its own row. DAMPEN reuses DRAIN
through the existing player target path. CUTTER reuses DATACUT through the
existing Packet targeting.

## 9. Bosses

| Boss | Strong colours | Strong shapes | `PRG_SET` |
| --- | --- | --- | --- |
| ODANSHAY | BLU:MAG:GRE | CIR:CRO:SQU | DISABLER, SMOGGER, SHIELDER, ATTACKER |
| RAHNDAHL | YEL:RED:BLU | STR:TRI:CIR | SHIELDER, SHELLER, SPAMBOT, DISABLER |
| NEHBOCYET | RED:YEL:GRE | TRI:STR:SQU | SPOTTER, THROWER, E-BOMBER, ENHANCE |
| ECHOFALL | MAG:BLU:YEL | DIA:CIR:CRO | STATIC, SMOGGER, ATTACKER, SHIELDER |

All four come from the workbook IDs and in order. Boss mechanic code is
unchanged.

## 10. Logging and metrics

- **Events:** `heal`, `healthCost` and `directCharge` are new. Each is a
  high-value battle-log record at every level (`HEAL`, `HEALTH_COST`,
  `DIRECT_CHARGE`), carrying the source Function and identity.
- **Aggregates:** each side gains `heal_applied`, `heal_wasted`,
  `health_cost_paid`, `direct_charge_accepted` and `direct_charge_discarded`.
- **Schema:** `METRICS_SCHEMA_VERSION` 2 → 3.
- **Not built:** the results screen does not list the new aggregates yet,
  because it would need three `text_content` rows past the pinned 292
  (AN-034).

## 11. Save schema

**5 → 6** (Q4, D-071). The battle save serializes the metrics accumulator,
whose shape grew.

Continuation tests (JSON round-trip, then play out and compare) cover:

- after TRANSFUSE, with charges, accumulator and health paid;
- after HEAL;
- with live TRIPWIRE Mines;
- each Boss mid-fight on its new loadout, with Boss state.

The 16 Run walks also round-trip the session envelope on every battle and
check the Hacker, Deck and build.

## 12. Fingerprints

Live `8dc8bc04-mgi`, pinned once as `test_content_expansion.LIVE_FINGERPRINT`.
Legacy `ca95eed5-96w`, unchanged. The CHARGE scope enters the hash only when
present, so content without it hashes as before.

## 13. Tests

**4,885 assertions, 0 failed**, across 27 suites. The new suite is
`test_content_pass_2.gd`, covering every §19 item.

The run prints **19** expected `ERROR` lines and no `SCRIPT ERROR`. The 19th
is new and deliberate: CHARGE scope SELF invoked with no Program source.

## 14. Content Pass 1 smoke

**PASS: 242 battles, 189 Hacker wins** (0.5: 244 / 187).

I ran the 0.5 tree and diffed the whole output. Everything before the Run
walks is **byte-identical** to 0.5: the System × HOST matrix, the UPGRADE
battles, Function coverage, HOST PASSIVE counts and Mine causes. Only the
Run walks moved (10 forced wins instead of 12), and they end in Boss battles
whose loadouts this build replaced. With its fixed setup unchanged, the
matrix reproduces 0.5 exactly.

## 15. Player-content smoke (`tools/content_smoke_2.gd`)

**PASS.** It played all 16 pairings × 2 builds × 2 seeds, which put every
candidate in a build. The Hacker policy fires until idle, so same-window
fires are reachable.

- Pairings 16/16; PRG_H_007–024 built 18/18.
- Every new top-level Function executed: MEND 136, AEGIS 109, SALVE 6,
  OVERDRAW 87, BLOODSPIKE 81, FLARE 6, SEEDMINE 126, TRIPWIRE 83, STAIN 14,
  TRANSFUSE 73, LANCET 57, CLOT 55, SURGE 9, REINFORCE 78, MENDKIT 29,
  BULWARK 47, SPARK 81, CHARGEPACK 58, LONGFUSE 45.
- Every chain child resolved.
- HEAL 171 events: applied 170, capped 57.
- Health cost 241 events: 6 lethal, one of them the controlled case.
- Direct charge 72 events: offered 1,152, accepted 1,090, discarded 62.
- **40** Programs fired in the same window after direct charge.
- SEEDMINE fired through Slice 72 times; TRIPWIRE through Destroy 41 times.

## 16. Boss smoke

**PASS.** All 16 authored placements were fielded.

- Under controlled charge, 4/4 Programs fired per Boss.
- Across the 64 natural battles (every pairing against every Boss), all 4
  fired naturally per Boss.
- Mechanics seen beside the new loadouts:
  - ODANSHAY: OVERRIDE_PLACED 163, THRESHOLD 17;
  - RAHNDAHL: CAPACITOR_PLACED 150, CAPACITOR_DISCHARGE 160;
  - NEHBOCYET: LOGIC_BOMB_PLACED 155, LOGIC_BOMB_TRIGGERED 19;
  - ECHOFALL: AXIS_CONCEALED 81, AXIS_REVEALED 74.
- No deadlock, no runaway resolution, no script error.

## 17. Structural Run walks

**16/16 Runs complete**, one per pairing, through `RunSetup` / `Run` /
`Session.create_run_battle`.

- **Natural wins: 48. Forced wins after three losses: 16.** This is
  structural evidence, not balance.
- Every battle carried the selected pair and the acquired UPGRADEs.
- Every Boss battle fielded that Boss's new loadout.
- Every battle's session envelope round-tripped.

## 18. Fast parity

**150/150**, no divergence, legacy data.

## 19. DEEPSCAN

**5,250/5,250, no divergence**, on `tests/fixtures/legacy_data/`, run after
every code change:

| Tier | Battles |
| --- | ---: |
| default seeds 0–199 | 3,000 |
| reinforced | 750 |
| timer | 750 |
| uncapped | 750 |

## 20. Tablet

SM-T580 over USB. Checked:

- Title shows "beta 0.6" and `8dc8bc04-mgi`.
- The Boss, Hacker and Deck choosers each show all four rows, with the new
  Boss axes.
- The Build screen shows six candidates (VITRA + BASTION, RAZE + BASTION)
  with no horizontal overflow. "BLOODSPIKE" clips to "BLOODSPIK" on the
  candidate buttons (AN-035).
- **TRANSFUSE:** LINK 130 → 110, all four Programs +4 at once, and OVERDRAW
  became ready and fired in the same window (110 → 98, 2 Buffs armed).
- **HEAL:** OVERDRAW 150 → 138, then MENDKIT restored 12, capped.
- **BLOODSPIKE:** cost 15, then 40 to ICE.
- **NEEDLE:** 3 SEEDMINE (countdown 3) and 2 TRIPWIRE (countdown 5) with the
  existing Mine art. SPARK detonated immediately and charged.
- Boss Attack fielded the new loadouts for ODANSHAY and NEHBOCYET.
- No MISSING text; the Godot log is clean.

## 21. S25

**Done**, in one announced window at native 1080×2340.

- The title and the Boss, Hacker, System and Deck choosers fit, with no
  safe-area or horizontal overflow.
- **RAZE + BLEEDLINE against ODANSHAY:** TRANSFUSE (130 → 110, four
  Programs +4 at once), then OVERDRAW in the same window (110 → 98, 2 Buffs
  armed). LINK and charge changes read clearly, as they happen.
- **RAZE + FUSEBOX:** CHARGEPACK armed 2 Bombs at countdown 2. SPARK
  resolved at once (7 damage) and its charge reached CHARGEPACK.
- **Build clipping:** at phone width, the candidate buttons clip more than on
  the tablet: "OVERDRA", "BLOODSPI", "CHARGEPA". The slot headers show the
  full names, so the screen stays usable (AN-035).
- The device log is clean.

## 22. For the director's own play

Mechanics are verified; feel is not. §24.3 recommends:

- Three Runs pairing VITRA, RAZE and NEEDLE with BLEEDLINE, BASTION and
  FUSEBOX.
- One Boss Attack against each Boss. Expect them to be very hard (AN-032).
- Look at three things in particular:
  - whether SEEDMINE vs TRIPWIRE is readable at all (AN-029);
  - whether TRANSFUSE's tempo feels worth 20 LINK;
  - whether the Deck active should read as its Function's name (AN-033).

## 23. Load warnings

**34**, all non-fatal and all expected. They are pinned by kind in the
tests.

- **28 duplicate display names:**
  - the 12 pre-0.6 ones;
  - 15 new Function/Program pairs named alike by design (AEGIS … LONGFUSE);
  - **BULWARK**, both `UPG_10` and `PRG_H_020` (AN-030, the one worth
    acting on).
- **6 unreferenced rows:** FNC_007–009 (SHOWCASE) and PSV_018–020, both
  pre-0.6.
- **Zero** placement, missing-content or invalid-content warnings.

## 24. Defects found and fixed

None in shipped behaviour. Harness-side:

- My scripted edits turned LF source files into CRLF; caught and reverted
  before any commit (lessons-learned).
- The new Run walks saved from a phase the game never saves from; fixed to
  mirror `_start_run_battle`.

## 25. Decisions

- **D-068** HEAL.
- **D-069** Function SELF_DAMAGE as a cost.
- **D-070** CHARGE.
- **D-071** Schemas and events.
- **D-072** Fingerprint.
- **D-073** Quick Match / Boss Attack pairs and the Random roll.
- **D-074** One unsuffixed workbook.

## 26. Architect notes

Added:

- **AN-029** SEEDMINE and TRIPWIRE look the same.
- **AN-030** BULWARK name collision.
- **AN-031** Buff credit goes to one Program per side.
- **AN-032** Boss Attack nearly unwinnable for the bot.
- **AN-033** Deck active shows the Deck's name.
- **AN-034** Results screen lacks the new aggregates.
- **AN-035** Build buttons clip long names.

None resolved. AN-020, AN-024, AN-026, AN-027 and AN-028 still stand.

## 27. Lessons learned

Appended:

- the delta-diff habit;
- explaining smoke drift by section;
- Python line endings on Windows;
- harness phase fidelity;
- coverage policy must reach the behaviour.

## 28. Deferred balance observations

These are recorded, not tuned.

- **Boss Attack:** 1 Hacker win in 64 bot battles (AN-032).
- **Player-content matrix:** Boss-free, 64 battles. RAZE lost 2 of 16; CR45H,
  VITRA and NEEDLE lost 3 each. VITRA + BASTION, the most sustain-heavy
  pairing, lost 2 of 4. Too few battles to read as balance.
- **HEAL:** a third of HEALs hit the cap (57 of 171), even with the bot
  skipping pure heals at full LINK.
- **Rare Functions:** SALVE (cost 8), SURGE and FLARE fired rarely (6, 9 and
  6 times). The cause was not investigated.
- **Direct charge:** 5% of the offer was discarded (62 of 1,152), so TRANSFUSE
  is close to full value.

## 29. Commit

Committed and pushed to `main` as one commit; working tree clean afterwards.

---

## Feedback for the architect

1. **The mechanical delta worked.** Phase A took minutes. Keep it, and keep
   naming the comparison file. "Compared against the final Beta 0.5 workbook"
   was just enough to find the right one.
2. **Say what exists before asking for it.** §6 assumed Quick Match had a
   chooser and that some path treated Hackers as a random pool. Neither was
   true. A one-line "current state" per requirement ("Quick Match is pinned
   to CR45H/AGIMA today") turns an ambiguity into a decision before the
   build.
3. **Pin counts that can be computed, not counts that constrain.** The
   292-row `text_content` pin is correct today, but it is also why the new
   aggregates are not on the results screen (AN-034). Saying "292 authored
   rows, plus any UI rows the build adds and logs" would have let the build
   finish the presentation.
4. **Specify presentation where mechanics depend on it.** SEEDMINE and
   TRIPWIRE are tactically opposite and visually identical (AN-029). §22's
   "MINE art already exists and remains canonical" was right for scope, but
   the requirement could flag that a removal-class identity is invisible.
   That would be a director question, not a coder discovery.
5. **The §12 classification table was the most useful page.** Every
   interaction question was answered before the code. Do it again for every
   new Effect.
6. **Name the expected-ERROR budget.** The suite prints known `ERROR` lines,
   and each build adds some. Listing the expected count in the requirements
   (or asking the build to report it, as I have) keeps "any unexplained
   error" a checkable rule.
7. **Smoke gates need a stated Hacker policy.** "A newly ready Program can be
   fired in the same phase" is unobservable under the 0.5 smoke's policy. The
   0.6 smoke had to change policy and keep the old matrix separate so its
   numbers stayed comparable. Requirements that ask for "observed coverage"
   should say what the bot is allowed to do.
