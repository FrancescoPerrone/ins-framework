# Project Context

## What this is

A SWI-Prolog implementation of a moral reasoning system grounded in the
Atkinson & Bench-Capon (2006) practical reasoning / argumentation framework.
The system models an ethical dilemma: agent **Hal** must decide whether and
how to help **Carla**, a diabetic who needs insulin.

The formal backbone is an **Action-based Alternating Transition System (AATS)**
where states, actions, values, and arguments are all represented in Prolog.
Arguments are evaluated using **Dung (1995) abstract argumentation semantics**
(conflict-free, admissible, preferred, grounded, stable extensions) and
**Value-Based Argumentation Framework (VAF)** from Bench-Capon (2003), where
different audience orderings over values produce different preferred extensions.

Two argument schemes from Atkinson & Bench-Capon (2006) are implemented:

- **AS1** — In circumstances R, perform A, leading to S, realising G, promoting value V.
- **AS2** — In circumstances R, perform A, to avoid S, which would demote value V.

Key references:
> Atkinson, K., & Bench-Capon, T. (2006). Addressing moral problems through
> practical reasoning. *Deontic Logic and Artificial Normative Systems*, pp. 8–23.

> Bench-Capon, T. (2003). Persuasion in practical argument using value-based
> argumentation frameworks. *Journal of Logic and Computation*, 13(3), 429–448.

---

## Prerequisites

```
SWI-Prolog >= 9.0  (tested on 9.0.4)
```

Install on Debian/Ubuntu:
```bash
sudo apt install swi-prolog
```

---

## How to run

### Test suite

```bash
swipl -l v1.0/dbg.pl
```

Loads all modules, starts PlDoc, runs all test sections, prints to stdout, halts.

### HTTP server

```bash
swipl v1.0/webapp/server.pl
```

Starts automatically on port 8000. Visit http://127.0.0.1:8000/.

### Interactive

```bash
swipl
?- [v1.0/dbg].
?- arg(Acts, Val).                            % Hal's AS1 arguments
?- argument(hal, Acts, Val, Scheme).          % all arguments with scheme tag
?- argument(carla, Acts, Val, Scheme).        % Carla's arguments (joint actions)
?- attacks(A1, A2).
?- vaf_preferred_extension(Ext, altruistic).
?- initial_state(S), trans(S, Acts, Next, 2), eval(hal, S, Next, E).
```

---

## File structure

```
v1.0/
├── dbg.pl          — entry point: loads all modules, runs test sections
├── states.pl       — state representation: agents, attributes, domains
├── actions.pl      — individual action pre/post-conditions (perform/3)
├── jactions.pl     — joint action pre/post-conditions (performj/3)
├── trans.pl        — trans/4 (individual) and transj/4 (joint) transitions
├── values.pl       — sub/2, better/4, worse/4, neut/4, eval/4
├── args.pl         — argument/4 (AS1+AS2), arg/2 (AS1 wrapper), attacks/2
├── extensions.pl   — Dung semantics: preferred, grounded, stable extensions
├── vaf.pl          — Value-Based Argumentation Framework (Bench-Capon 2003)
├── webapp/
│   ├── server.pl   — HTTP server: JSON API + HTML frontend (auto-starts port 8000)
│   ├── test.pl     — legacy server file (kept for reference)
│   └── index.html  — browser frontend
└── docs/solutions/
    ├── arg.sol                 — reference arg/2 output (pre-fix)
    ├── arg2.sol                — same
    ├── res.dbg                 — arg/2 output with full state traces
    └── extensions_baseline.txt — snapshot after Dung extensions added
```

---

## Domain

State is a 6-tuple `[ih, mh, ah, ic, mc, ac]` where each attribute is binary
(1 = has it, 0 = doesn't):

| Position | Attribute | Meaning            |
|----------|-----------|--------------------|
| 1        | ih        | Hal has insulin    |
| 2        | mh        | Hal has money      |
| 3        | ah        | Hal is alive       |
| 4        | ic        | Carla has insulin  |
| 5        | mc        | Carla has money    |
| 6        | ac        | Carla is alive     |

**Initial states** (across 3 active scenarios — freedomH scenario removed with earnH):

| Pattern          | Crisis                | Value targeted |
|------------------|-----------------------|----------------|
| `[0,_,1,1,_,1]` | Hal lacks insulin     | lifeH          |
| `[1,1,1,0,_,1]` | Carla lacks insulin   | lifeC          |
| `[1,1,1,1,0,1]` | Carla lacks money     | freedomC       |

**Hal's individual actions**: `buyH`, `takH`, `comH`, `losH`, `doNH`
(`earnH` was removed — not defined in Atkinson & Bench-Capon 2006)
**Hal's joint actions with Carla**: `buyH-comC`, `comH-takC`, `doNH-losC`, etc.
**Values**: `lifeH`, `lifeC`, `freedomH`, `freedomC`
**Hal** subscribes to all four; **Carla** subscribes to `lifeC` and `freedomC`.

---

## Current output

### AS1 arguments (9 total — `freedomH` has none)

```
arg([buyH,doNH],  lifeH)
arg([takH,comH],  lifeH)
arg([takH,doNH],  lifeH)

arg([comH,doNH],  lifeC)
arg([comH,losH],  lifeC)
arg([doNH,comH],  lifeC)

arg([comH,doNH],  freedomC)
arg([comH,losH],  freedomC)
arg([doNH,comH],  freedomC)
```

`freedomH` produces no arguments because `earnH` (the only action improving `mh`)
was removed as non-canonical. This is an open design question.

### AS2 arguments

Generated via `argument(hal, Acts, Val, as2)`. These argue *against* actions by showing
they would demote a value. Now included in `arg/2` alongside AS1, so they participate
in Dung extensions, the attack relation, and VAF. Total argument set: 35 (up from 9).

### Dung extensions (over AS1+AS2 arguments, 35 total)

- **Grounded**: `[]`
- **Preferred**: 13 extensions
- **Stable**: subset of preferred

### VAF preferred extensions by audience

| Audience       | Value order                         | Preferred extensions |
|----------------|-------------------------------------|----------------------|
| `life_first`   | lifeH > lifeC > freedomH > freedomC | 10                  |
| `selfish`      | lifeH > freedomH > lifeC > freedomC | 10                  |
| `altruistic`   | lifeC > lifeH > freedomC > freedomH | 10                  |
| `freedom_first`| freedomH > freedomC > lifeH > lifeC | 6                   |

`freedom_first` gives 6 (not 10): AS2 `freedomH` arguments now participate and survive
under this audience, partially closing the item 15 gap. See `docs/notes/framing_problem.md`.

---

---

## Implementation notes: extension algorithm

### Problem 1 — Original approach: brute-force powerset (O(2^n))

The first implementation of `preferred_extension/1` in `extensions.pl` used a generate-and-test
strategy over the powerset of all arguments:

```prolog
preferred_extension(Ext) :-
    all_arguments(AllArgs),
    powerset(AllArgs, Ext),
    admissible(Ext),
    \+ (powerset(AllArgs, Bigger),
        is_subset(Ext, Bigger), Ext \= Bigger,
        admissible(Bigger)).
```

This is correct but has exponential time complexity O(2^n) in the number of arguments.
With 9 AS1 arguments it was barely tractable; including AS2 would bring the argument set
to ~35 (AS1 + AS2 for Hal + Carla's joint actions), making the brute-force approach unusable.

### Solution — Caminada (2006) complete-labelling search

The preferred extension algorithm was rewritten to use the *complete labelling* characterisation
from Caminada (2006). A labelling is a function L : Args → {in, out, undec} satisfying:

- L(a) = **in**   ↔  every argument b such that b attacks a has L(b) = out
- L(a) = **out**  ↔  some argument b such that b attacks a has L(b) = in
- L(a) = **undec** ↔  neither condition above holds

A *preferred* labelling is a complete labelling with a maximal in-set. The in-set of any
preferred labelling is exactly a preferred extension.

**Algorithm** (`preferred_ext_raw/3`):

1. Initialise all arguments as `undec`.
2. **Constraint propagation** (`lb_propagate/4`): repeatedly apply forced-label rules until
   fixed point:
   - If all attackers of a are out → force a to `in`
   - If some attacker of a is in → force a to `out`
3. **Branching search** (`lb_extend/5`): for each remaining `undec` argument (in a fixed
   enumeration order), nondeterministically:
   - Option A: force it to `in` and propagate (then continue with the rest)
   - Option B: leave it as `undec` (continue without forcing)
4. **Completeness check** (`lb_is_complete/3`): accept the labelling only if every in-label
   and out-label satisfies its completeness condition. Reject otherwise.
5. **Maximality check** (`lb_can_extend_in/3`): reject if any `undec` argument could be
   moved to `in` without contradiction (i.e., the in-set is not maximal).
6. Collect all accepted in-sets, deduplicate via `sort/2`, and enumerate.

Time complexity is O(2^k) where k is the number of genuinely ambiguous (undec after
propagation) arguments — typically much smaller than n.

### Problem 2 — Duplicate preferred extensions

Two different branching paths can produce the same in-set: path (1) forces A=in then B=in;
path (2) leaves A=undec but later forces B=in, after which propagation forces A=in too.
Both paths yield {A, B} as the in-set.

**Fix**: wrap `preferred_ext_for/3` with `findall(..., preferred_ext_raw(...), Exts0), sort(Exts0, Exts)` to deduplicate before enumerating.

### Problem 3 — VAF: asymmetric defeat and `lb_contradicted`

The original `lb_contradicted/2` only checked one defeat direction:

```prolog
lb_contradicted(AP, L) :-
    member(A-in, L), member(B-in, L), call(AP, B, A), !.
```

This checked "B defeats A" but not "A defeats B". For Dung's symmetric attack relation
this was sufficient, but VAF defeat is *asymmetric*: `defeats(A, B, Aud)` can be true
while `defeats(B, A, Aud)` is false (when A promotes a higher-valued value than B).

`lb_force_one` only updates `undec` arguments, so a previously-`in` argument is not
retroactively set to `out` when a newly-`in` argument defeats it. Without checking both
directions, a labelling could contain two `in` arguments where one defeats the other,
which violates conflict-freeness.

**Fix**: check both directions:
```prolog
lb_contradicted(AP, L) :-
    member(A-in, L), member(B-in, L),
    (call(AP, B, A) ; call(AP, A, B)), !.
```

### Problem 4 — VAF: incomplete labellings accepted as preferred (`lb_is_complete`)

This was the subtlest bug. Under VAF with asymmetric defeat, the algorithm could reach a
labelling such as:

```
lifeH_arg1 = in,  lifeH_arg2 = undec,  lifeC_arg = undec
```

Under the `life_first` audience [lifeH > lifeC > freedomH > freedomC]:
- `defeats(lifeC_arg, lifeH_arg1, life_first)` = false (lifeC cannot defeat lifeH)
- So `lb_some_attacker_in` for `lifeC_arg` fails: there is an `in` attacker of `lifeC_arg`
  (namely `lifeH_arg1`) but it is a *defeater* only if... wait, the issue is the reverse.
  `lifeH_arg1` *defeats* `lifeC_arg`, but `lb_force_one` checks whether any *attacker* of
  an `undec` argument is `in`. Under VAF, `call(AP, lifeH_arg1, lifeC_arg)` =
  `defeats(lifeH_arg1, lifeC_arg, life_first)` = true (lifeH defeats lifeC). So propagation
  SHOULD force `lifeC_arg` to `out`.

In practice the real issue was: the `lb_can_extend_in` check (used to identify non-maximal
labellings) was erroneously passing for labellings where `in`-labelled args still had
`undec` defeaters. These are *not* valid complete labellings, because completeness requires
`in(a) → all defeaters of a are out`. A labelling with `in(A)` and `undec(defeater-of-A)`
violates this and should be rejected.

**Fix**: add `lb_is_complete/3` before the maximality check in `preferred_ext_raw`:

```prolog
lb_is_complete(AP, AllArgs, L) :-
    forall(member(A-in,  L), lb_all_attackers_out(AP, AllArgs, A, L)),
    forall(member(A-out, L), lb_some_attacker_in(AP, AllArgs, A, L)).
```

This ensures every accepted labelling is a genuine complete labelling before testing
for maximality.

### Problem 5 — VAF: module context for the defeat predicate

`preferred_ext_for/3` is defined in `extensions.pl` and accepts a defeat predicate as an
argument (an atom or term callable via `call/3`). When `vaf.pl` first passed `defeats/3`
by name:

```prolog
vaf_preferred_extension(Ext, Aud) :-
    all_arguments(AllArgs),
    preferred_ext_for(AllArgs, vaf_defeat_for(Aud), Ext).
```

the predicate was called from *inside* `extensions.pl` via `call(vaf_defeat_for(Aud), A, B)`.
SWI-Prolog resolves this call in the `extensions` module context, where `vaf_defeat_for/3`
is not visible. The call silently failed, producing no extensions.

**Fix**: use a YALL (Yet Another Lambda Library) lambda closure, which captures the calling
module context at the point of creation (inside `vaf.pl`):

```prolog
vaf_preferred_extension(Ext, Aud) :-
    all_arguments(AllArgs),
    preferred_ext_for(AllArgs, [A,B]>>defeats(A,B,Aud), Ext).
```

The closure `[A,B]>>defeats(A,B,Aud)` is evaluated in `vaf` module context regardless of
where `call/3` is executed, so `defeats/3` is found correctly.

### Correctness of the final VAF results

The corrected algorithm produces these preferred extensions, which agree with the theoretical
expectations of Bench-Capon (2003):

| Audience       | Value order                          | Preferred extensions             | Reasoning |
|----------------|--------------------------------------|----------------------------------|-----------|
| `life_first`   | lifeH > lifeC > freedomH > freedomC  | 3 lifeH singletons               | lifeH args defeat all others; lifeH args defeat each other, so only one can be in |
| `selfish`      | lifeH > freedomH > lifeC > freedomC  | 3 lifeH singletons               | same as life_first for available args (no freedomH args) |
| `altruistic`   | lifeC > lifeH > freedomC > freedomH  | 3 lifeC+freedomC pairs           | lifeC/freedomC defeat lifeH; compatible-action pairs are conflict-free |
| `freedom_first`| freedomH > freedomC > lifeH > lifeC  | 3 lifeC+freedomC pairs           | freedomC > lifeH so freedomC args defeat lifeH args (previously wrong: stated ∅) |

The `freedom_first` result was incorrectly stated as ∅ in an earlier version of this document
(based on the buggy brute-force algorithm). The correct result is lifeC+freedomC pairs:
since no freedomH arguments exist, the freedomC args (next in preference) defeat the lifeH args,
and the three compatible-action pairs form the preferred extensions.

---

## Commit history

| Commit     | Change |
|------------|--------|
| `e938a86`  | Added `TODO.md` |
| `d8b2a2d`  | Fixed `values.pl:neutral/4` syntax error |
| `9f958ca`  | Fixed `arg/2` deduplication via `setof` |
| `d16b2fc`  | Added `CONTEXT.md` |
| `0eb9123`  | Saved `extensions_baseline.txt` |
| `1d94f82`  | Added `extensions.pl`: Dung preferred/grounded/stable |
| `16cdab3`  | Added `vaf.pl`: VAF with 4 audiences |
| `ac73d8b`  | Added lifeC/freedomH/freedomC args; `earnH`; performance fix |
| `66ada53`  | Fixed export warnings; `demotes/4` agent bug; `doNH-losC` duplicate |
| `d554c54`  | Removed non-canonical `earnH`; removed freedomH initial state |
| `dec247f`  | Added AS2 scheme; `argument/4` with `as1`/`as2` tag |
| `0c4e80c`  | Exposed `scheme` field in `/args` API |
| `ffed1c2`  | Clarified `arg_json/4` compatibility clause |
| `279a3eb`  | Scheme-aware connector label in plain-English mode |
| `820e56d`  | Updated `dbg.pl` to use `argument/4` and show AS2 |
| `58d0409`  | Passed scheme to argInline for extensions/VAF panels |
| `fb184dd`  | Restricted `arg/2` to AS1 only (extensions tractability) |
| `b8f44bf`  | Added `initialization` directive to `server.pl` — now auto-starts |
| `(current)`| Replaced powerset with Caminada labelling; fixed VAF correctness bugs |

---

## Open questions / next steps

1. **`freedomH` coverage** — no canonical action promotes `mh`. Is this intentional
   (Hal simply cannot argue for his financial freedom in this domain) or should a new
   action be introduced from the literature?

2. **AS2 in extensions** — AS2 arguments are built but excluded from `arg/2` by design.
   The labelling algorithm (O(2^k) in ambiguous args) is no longer a blocker; including AS2
   is a deliberate scope decision. Change `arg(Acts,Val) :- argument(hal,Acts,Val,as1).`
   to `argument(hal,Acts,Val,_).` to enable this.

3. **Carla's AS2 arguments** — currently only AS1 is checked for Carla
   (`argument(carla, Acts, Val, as1)`). AS2 for joint actions not yet verified.
