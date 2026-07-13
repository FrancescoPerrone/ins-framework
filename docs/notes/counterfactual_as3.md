# Note: Counterfactual Semantics and the AS3 Argument Scheme

*Documents item 20: counterfactual extension. Article material.*
*Implemented 2026-05-11 in `v1.0/counterfactual.pl` and `v1.0/args.pl`.*

---

## Background and motivation

AS1 and AS2, as defined by Atkinson & Bench-Capon (2006), are both
**consequentialist and forward-looking**: they evaluate an action by asking what state
it produces and whether that state is better or worse with respect to a value.

  - **AS1**: In circumstances R, perform A — it leads to state S, promoting value V.
  - **AS2**: In circumstances R, perform A — to avoid state S', which would demote V.

Neither scheme can represent *what would have happened had the agent acted differently*.
This matters in at least three places in the insulin scenario:

1. **The doing/allowing distinction.** `doNH` — Hal doing nothing — is represented in
   the AATS as an explicit action with preconditions and a transition function, like any
   other action.  Within AS1/AS2 semantics, Hal's inaction is treated symmetrically with
   Hal's intervention.  Whether this is morally appropriate is precisely the question that
   counterfactual reasoning is designed to answer.  The standard Lewisian formulation
   (Lewis 1973) says: *C caused E* if and only if, had C not occurred, E would not have
   occurred.  This criterion distinguishes doing from allowing in a way AS1/AS2 cannot.

2. **Causal responsibility in joint actions.** A joint action `j = H-C` produces a state
   that results from both agents acting simultaneously.  The current VAF layer assigns
   value promotions to joint outcomes without distinguishing which agent's contribution
   was causally necessary.  For `doNH-losC` (Hal does nothing, Carla loses insulin), the
   outcome is unambiguously attributable to Carla — but the framework treats it as a
   joint cause.  A counterfactual layer allows the question to be asked precisely: *would
   the outcome have been different had Hal acted instead of doing nothing?*

3. **The `freedomH` gap.** No action in the canonical action set positively promotes `mh`
   (Hal's financial freedom), so `freedomH` produces no AS1 argument.  A counterfactual
   scheme — **AS3** — offers a principled path toward representing the *preservation* of
   `freedomH` through the counterfactual: the argument would be "had Hal been compelled to
   give away his resources, `freedomH` would have been demoted."

---

## The AS3 scheme

**AS3 (counterfactual)**: Perform joint action J in circumstances Q, because had Hal
instead done nothing (`doNH`) at each step — holding Carla's actions fixed — value V
would have been demoted.

Formally, Acts is an AS3 argument for Val if there exists an initial state Q such that:

1. `transj(Q, Acts, Next, 2)` — the actual sequence is executable from Q
2. `¬ worse(hal, Q, Next, Val)` — the actual outcome does not demote Val
3. `transj(Q, CfActs, CfNext, 2)` — the counterfactual sequence (Hal does doNH) is
   executable from Q (where CfActs replaces each H in Acts with doNH)
4. `worse(hal, Q, CfNext, Val)` — the counterfactual outcome *does* demote Val

AS3 is structurally distinct from AS2.  AS2 says: *perform A to prevent demotion of V*
— it is still forward-looking.  AS3 says: *A was the right choice because its absence
would have caused demotion of V* — the justification is retrospective, grounded in the
counterfactual conditional.

---

## Implementation

`v1.0/counterfactual.pl` is a **standalone additive module**.  Existing files are
unchanged except for `use_module(counterfactual)` in `args.pl`, `dbg.pl`, and `server.pl`.

The module provides four predicates:

```prolog
holds(+Prop, +State)          % proposition-level interface over attribute encoding
cf_joint_seq(+Jacs, -CfJacs)  % replace Hal's action with doNH, hold Carla fixed
counterfactual_holds(+Q, +J, +P)  % P holds in actual but not counterfactual outcome
causal_responsible(+Ag, +Q, +J, +P)  % Ag's choice was causally necessary for P
```

`holds/2` maps readable proposition terms (`alive(hal)`, `has_insulin(carla)`, etc.)
to the underlying binary attribute encoding.

`cf_joint_seq/2` implements the Lewisian intervention: Hal's component of every step
is replaced with `doNH`, holding Carla's actions exactly as they were.  This isolates
Hal's individual causal contribution from the joint outcome.

The AS3 clause in `args.pl` uses `setof` with full existential quantification to
deduplicate across initial states, matching the pattern of AS1 and AS2:

```prolog
argument(hal, Acts, Val, as3) :-
    value(Val),
    setof(Acts-Val,
          Init^Next^CfActs^CfNext^(
              initial_state(Init),
              transj(Init, Acts, Next, 2),
              \+ worse(hal, Init, Next, Val),
              cf_joint_seq(Acts, CfActs),
              transj(Init, CfActs, CfNext, 2),
              worse(hal, Init, CfNext, Val)
          ),
          Pairs),
    member(Acts-Val, Pairs).
```

AS3 arguments use **joint action sequences** (`transj/4`) and are deliberately excluded
from `arg/2`, so the Dung/VAF extension layer (extensions.pl, vaf.pl) is unaffected.
They are accessible via `argument(hal, Acts, Val, as3)` and the `/counterfactual` API
endpoint.

**New API endpoints** (additive, existing endpoints unchanged):
- `GET /counterfactual` — all AS3 arguments with actual and counterfactual witness states
- `GET /counterfactual/causal/:prop` — all (state, sequence) pairs where Hal is causally
  responsible for a proposition (`alive_hal`, `alive_carla`, `has_insulin_hal`, etc.)

**New dbg.pl sections** (19–21) cover AS3 enumeration, causal responsibility examples,
and `counterfactual_holds` spot-checks.

---

## Results

| Value      | AS3 arguments | Interpretation                                       |
|------------|:---:|--------------------------------------------------------------|
| `lifeH`    | 10  | Hal's action was causally necessary for his own survival     |
| `lifeC`    |  0  | Carla's survival does not depend counterfactually on Hal     |
| `freedomH` |  0  | `doNH` never modifies `mh` — gap is structural, not fixable  |
| `freedomC` |  0  | `doNH` never modifies `mc` — same structural reason          |

### The ten AS3 arguments for `lifeH`

All ten arguments share the same structure: Hal acquires insulin in step 1
(`buyH` or `takH`) while Carla's action in the counterfactual step 2 changes the
insulin distribution but cannot undo Hal's death.  The counterfactual — Hal doing
`doNH` in both steps — results in Hal dying (`ah`: 1→0) because he has no insulin.

Representative examples:

```
[buyH-losC, doNH-buyC]   — Hal buys (step 1), Carla buys later; cf: Hal dies
[takH-losC, comH-takC]   — Hal takes (step 1), Carla cooperates; cf: Hal dies
[takH-comC, doNH-losC]   — Hal takes (step 1), Hal compensates (step 2); cf: Hal dies
```

Each argument says: *this joint action sequence kept Hal alive, and had Hal done
nothing instead, he would have died.*

### `lifeC = 0`: a domain finding

The counterfactual layer produces **no AS3 arguments for Carla's survival**, and this
result is theoretically significant.

In the initial state `[1,1,1,0,M,1]` (Hal has insulin, Carla does not), Hal can give
Carla insulin via `comH`.  But the counterfactual holds Carla's action fixed.  If
Carla's action is `takC`, the counterfactual joint action `doNH-takC` still gives Carla
insulin — because `takC` takes from Hal, who still has insulin when doing `doNH`.
Carla survives regardless of what Hal does, because she retains the ability to take
insulin from him.

In every reachable scenario where Carla lacks insulin, an inspection of the
joint-action table confirms this: **there is no initial state from which Hal's choice
is causally necessary for Carla's survival**.  Carla always has an action (`takC`) that
gives her insulin independently of Hal's cooperation.

This is a precise formal result with a direct philosophical reading:

> Hal has causal responsibility for his own survival; he has no causal responsibility —
> in the Lewisian sense — for Carla's survival.  Carla's fate is in her own hands.

This does not mean Hal has no *moral* responsibility toward Carla.  AS1 and AS2 arguments
for `lifeC` still exist and are accepted in various preferred extensions.  What the
counterfactual result establishes is that Carla retains full agency: whatever Hal does,
she can choose to take insulin from him.  The moral pressure on Hal to act comes from
his *positive* obligations (AS1/AS2), not from counterfactual causal responsibility.

This distinction — between causal responsibility and moral obligation — is precisely what
the AS3 layer adds to the system.  The result for `lifeC` is not a gap; it is a
contribution.

### `freedomH = 0`: confirming the framing-problem analysis

As predicted in `docs/notes/framing_problem.md`, `doNH` never modifies `mh`.  No
sequence of `doNH` steps can demote Hal's financial freedom, so no AS3 argument for
`freedomH` can be constructed.  The gap is structural: it reflects the design of the
action model, not a deficiency in the argumentation layer.  The counterfactual layer
makes this explicit — `freedomH` is not a value that can be addressed through causal
responsibility reasoning within this action set.

---

## Theoretical connections

### Relation to Lewis (1973)

The predicate `counterfactual_holds/3` implements the Lewis criterion directly: P holds
in the actual outcome and would not hold in the closest possible world where Hal does
nothing.  "Closest possible world" is operationalised as the unique state reached by
`transj(Q, CfActs, CfNext, N)` — the AATS transition function is deterministic, so
there is exactly one counterfactual world for each intervention.

### Relation to Halpern & Pearl (2005)

The structural-equation approach of Halpern & Pearl defines actual causation via
interventions on variables.  `cf_joint_seq/2` performs exactly this kind of intervention:
Hal's action variable is set to `doNH` while Carla's action variable is held at its
actual value.  The AATS state encoding — a fixed-length list of binary attributes — is
analogous to a structural equation model over binary variables.

### Relation to AS1/AS2

The three schemes are not redundant:

| Scheme | Direction | Question answered |
|---|---|---|
| AS1 | Forward | Does this action promote Val? |
| AS2 | Forward | Does this action prevent demotion of Val? |
| AS3 | Retrospective | Would Val have been demoted without this action? |

AS1 and AS3 can overlap in value coverage (both generate arguments for `lifeH`), but
they express different modal claims.  An AS1 argument for `lifeH` says Hal's action
*positively improves* his situation.  An AS3 argument says Hal's action was *causally
necessary* for him to remain alive.  These are logically independent: AS1 requires
`better/4`; AS3 requires `worse/4` under the counterfactual.

### Relation to the extension layer

AS3 arguments are not integrated into `arg/2` and therefore do not participate in the
Dung/VAF extension computation.  This is a deliberate design choice: AS3 arguments use
joint action sequences, whereas the current `arg/2`/`attacks/2` layer operates over
individual sequences.  Integrating AS3 into extensions would require a unified argument
vocabulary and a revised attack relation — a well-defined but non-trivial extension that
is left as future work.

---

## Relevant references

Lewis, D. (1973). *Counterfactuals*. Harvard University Press.
[Closest-possible-worlds semantics; philosophical foundation for `counterfactual_holds/3`.]

Lewis, D. (2000). Causation as influence. *The Journal of Philosophy*, 97(4), 182–197.
[Refined account of counterfactual causation.]

Halpern, J. Y., & Pearl, J. (2005). Causes and explanations: A structural-model approach.
*The British Journal for the Philosophy of Science*, 56(4), 843–887.
[Structural-equation formalisation of actual causation; closest formal analogue to
`cf_joint_seq/2` as an intervention operator.]

Atkinson, K., & Bench-Capon, T. (2006). Addressing moral problems through practical
reasoning. *Deontic Logic and Artificial Normative Systems*, pp. 8–23. Springer.
[AS1/AS2 — the schemes AS3 extends.]

Prakken, H., & Sartor, G. (1996). A dialectical model of assessing conflicting arguments
in legal reasoning. *Artificial Intelligence and Law*, 4(3–4), 331–368.
[Counterfactual causation as a standard tool in legal argumentation — broader context.]

Sergot, M. (2014). Normative positions. In *Handbook of Deontic Logic and Normative
Systems* (pp. 353–406). College Publications.
[Omission and indirect effects in action formalisms — theoretical context for the
doing/allowing distinction.]
