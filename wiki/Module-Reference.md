# Module Reference

Quick reference for every `.pl` file in `v1.0/`.  For detailed theoretical discussion
see the per-module summaries in `article/summary/`.

---

## AATS core

These files implement the AATS tuple directly.  They contain no domain value judgements.

### `states.pl`
**AATS components: Q, φ, π**

Defines the 6-tuple state encoding, enumerates all 64 binary states (`state/1`),
provides attribute accessors (`attribute/3`), and specifies the three initial states.
Root of the dependency graph — no project imports.

Key exports: `agent/1`, `attributes/1`, `state/1`, `initial_state/1`, `attribute/3`.

---

### `actions.pl`
**AATS components: Ac₁ (Hal's actions), ρ (preconditions)**

Defines Hal's five individual actions as `perform(Pre, Post, Action)` clauses.
`doNH` is the identity action — the counterfactual baseline.

Key export: `perform/3`.

---

### `jactions.pl`
**AATS component: JAg (joint action set, Carla's Ac₂ implicit)**

Defines joint actions `H-C` as `performj(Pre, Post, H-C)` clauses.  Carla's action
set is defined implicitly through the right-hand components.  `takC` is the action
that makes `lifeC = 0` in the AS3 layer — Carla can always take insulin from Hal.

Key export: `performj/3`.

---

### `trans.pl`
**AATS component: τ (transition function)**

Extends single-step transitions to n-step sequences:
- `trans/4` — individual sequences for Hal (used by AS1/AS2)
- `transj/4` — joint sequences for Hal × Carla (used by AS3, counterfactual, possible worlds)

The most widely imported module after `states.pl`.

Key exports: `trans/4`, `transj/4`.

---

## Normative layer

### `values.pl`
**Extension layer — above the AATS tuple**

Defines the four values, agent subscriptions, and the `affects/2` mapping from state
attributes to values.  Provides `better/4`, `worse/4`, and `eval/4` for evaluating
transitions normatively.

The `freedomH` gap originates here: no action promotes `mh`, so `better(hal, _, _, freedomH)`
is always false.  See `docs/notes/framing_problem.md`.

Key exports: `value/1`, `sub/2`, `affects/2`, `better/4`, `worse/4`, `eval/4`.

---

## Argumentation layer

### `args.pl`
**Extension layer — Atkinson & Bench-Capon (2006)**

Constructs AS1, AS2, and AS3 arguments and the attack relation.  `arg/2` returns the
35 AS1+AS2 arguments used by the extension layer.  `argument/4` returns all arguments
for any agent and scheme.  AS3 arguments are excluded from `arg/2` (joint vs.
individual sequence incompatibility).

Key exports: `arg/2`, `argument/4`, `attacks/2`.

---

### `extensions.pl`
**Extension layer — Dung (1995)**

Computes preferred, grounded, and stable extensions using the Caminada (2006)
complete-labelling algorithm.  The parameterised `preferred_ext_for/3` is reused by
`vaf.pl`.

**Key result**: grounded extension is empty (maximally contentious framework); 13
preferred extensions.

Key exports: `preferred_extension/1`, `grounded_extension/1`, `stable_extension/1`,
`preferred_ext_for/3`, `all_arguments/1`.

---

### `vaf.pl`
**Extension layer — Bench-Capon (2003)**

Implements audience-relative defeat: argument A defeats B under audience P iff A
attacks B and B's value is not strictly preferred over A's in P.  Defines the four
named audiences.  Computes VAF preferred and grounded extensions.

**Key result**: 10 preferred extensions under `life_first`, `selfish`, `altruistic`;
6 under `freedom_first`.

Key exports: `audience/2`, `defeats/3`, `vaf_preferred_extension/2`,
`vaf_grounded_extension/2`.

---

### `credulous.pl`
**Extension layer — Cayrol, Doutre & Mengin (2003)**

Implements the φ₁-proof algorithm for credulous and sceptical acceptance.  Returns a
structured dialogue proof, not just a Boolean.  Provides both Dung and VAF variants.

**Key result**: 35/35 credulously accepted; 0/35 sceptically accepted.

Key exports: `credQA/2`, `vaf_credQA/3`, `sceptically_accepted/1`,
`vaf_sceptically_accepted/2`.

---

## Counterfactual and modal layer

### `counterfactual.pl`
**Extension layer — Lewis (1973), Halpern & Pearl (2005)**

Implements the Lewis intervention operator (`cf_joint_seq/2`), a proposition-level
interface to state attributes (`holds/2`), and the causal criterion
(`counterfactual_holds/3`).  Substrate for AS3 and a special case of `lewis_would`.

**Key result**: `counterfactual_holds` for `alive(hal)` in 10 state-sequence pairs;
never for `alive(carla)`.

Key exports: `holds/2`, `cf_joint_seq/2`, `counterfactual_holds/3`,
`causal_responsible/4`.

---

### `possible_worlds.pl`
**Extension layer — Lewis (1973), Stalnaker (1968)**

Full possible world semantics over the AATS state space.  Value-weighted Hamming
distance parameterised by VAF audience.  General-antecedent Lewis □→ and Stalnaker >
conditionals.  Both conditionals are audience-relative.

**Key result**: Lewis/Stalnaker diverge under `life_first`, `altruistic`,
`freedom_first`; agree under `selfish`.

Top of the theoretical module stack — no other project module depends on it.

Key exports: `value_weight/3`, `attr_weight/3`, `value_distance/4`,
`closest_worlds/5`, `lewis_would/5`, `stalnaker_would/5`, plus six standard antecedent
predicates.

---

## Infrastructure

### `dbg.pl`
Entry point.  Loads all modules, starts PlDoc, runs 23 test sections in order.
Run with `swipl dbg.pl` from `v1.0/`.

### `webapp/server.pl`
HTTP server.  Exposes all results as JSON via the endpoints in [[API Reference]].
Auto-starts on port 8000 when loaded.

### `webapp/test.pl`
Legacy prototype.  Not loaded by any current module; kept for historical reference.

---

## Dependency graph

```
possible_worlds ──→ vaf ──→ args ──→ counterfactual ──→ values ──→ trans ──→ states
                     │               │                                  └──→ jactions
                     └──→ extensions └──→ states                       └──→ actions
                           │
                     credulous ──→ vaf
```

`states` is the root (no dependencies).  `possible_worlds` is the leaf (nothing
depends on it).  `dbg.pl` and `webapp/server.pl` import everything.

---

*Previous: [[API Reference]]*
