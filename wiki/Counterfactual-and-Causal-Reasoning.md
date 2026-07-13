# Counterfactual and Causal Reasoning

## The gap in AS1/AS2

AS1 and AS2 are **consequentialist and forward-looking**: they ask what state an action
produces, and whether that state is better or worse.  They cannot ask what *would have
happened* had the agent acted differently.

This matters in at least two places:

1. **The doing/allowing distinction.** `doNH` (doing nothing) is represented in the
   AATS as an explicit action with a defined transition — identical state in, identical
   state out.  Within AS1/AS2, Hal's inaction is evaluated symmetrically with his
   action.  Whether this symmetry is morally appropriate is precisely what
   counterfactual reasoning is designed to test.

2. **Causal responsibility in joint actions.** A joint action `H-C` produces a state
   resulting from both agents acting simultaneously.  AS1/AS2 assign value
   (de)promotions to the joint outcome without asking which agent's contribution was
   causally necessary.

`counterfactual.pl` resolves both by implementing the **Lewis (1973) criterion**:

> C caused E iff had C not occurred, E would not have occurred.

---

## The intervention operator

`cf_joint_seq/2` replaces Hal's action at every step with `doNH`, holding Carla's
actions exactly as they were:

```prolog
cf_joint_seq([H-C | Rest], [doNH-C | CfRest]) :-
    cf_joint_seq(Rest, CfRest).
```

This is a Halpern & Pearl (2005) style *intervention* on the action variable: Hal's
contribution is set to null while Carla's causal contribution is held fixed.

The result is the unique **counterfactual world** for each actual joint sequence.
The AATS transition function τ is deterministic, so there is exactly one such world.

---

## `counterfactual_holds/3`

```prolog
counterfactual_holds(+Q, +J, +P)
```

True iff:
1. P holds in the actual outcome of J from Q, AND
2. P does *not* hold in the outcome of `cf_joint_seq(J)` from Q.

This is the Lewis criterion applied computationally.

### Example

```prolog
?- counterfactual_holds([0,1,1,1,1,1], [buyH-losC, doNH-buyC], alive(hal)).
true.
```

Hal bought insulin (step 1), then did nothing while Carla bought (step 2).  Had Hal
done nothing instead, he would have remained without insulin and died.  His action was
causally necessary for his survival.

---

## AS3: the counterfactual argument scheme

AS3 translates `counterfactual_holds` into an argument scheme:

> "Perform joint action J rather than doing nothing, because had Hal done `doNH` at
> each step (holding Carla's actions fixed), value Val would have been demoted."

```prolog
argument(hal, Acts, Val, as3) :-
    value(Val),
    setof(Acts-Val, Init^Next^CfActs^CfNext^(
              initial_state(Init),
              transj(Init, Acts, Next, 2),
              \+ worse(hal, Init, Next, Val),
              cf_joint_seq(Acts, CfActs),
              transj(Init, CfActs, CfNext, 2),
              worse(hal, Init, CfNext, Val)
          ), Pairs),
    member(Acts-Val, Pairs).
```

---

## Results

| Value      | AS3 arguments | Interpretation                                           |
|------------|:---:|--------------------------------------------------------------|
| `lifeH`    | **10**  | Hal's action was causally necessary for his own survival |
| `lifeC`    | **0**   | Carla's survival is never counterfactually dependent on Hal |
| `freedomH` | **0**   | `doNH` never modifies `mh` — structural gap              |
| `freedomC` | **0**   | `doNH` never modifies `mc` — structural gap              |

### The `lifeC = 0` finding

This is the central empirical result of the counterfactual layer.

In every initial state where Carla lacks insulin, Carla retains the `takC` action —
she can *take* insulin from Hal directly, regardless of what Hal does.  In the
counterfactual sequence `doNH-takC`, Hal does nothing but Carla takes from him: Hal
still has insulin when doing nothing, so `takC` succeeds.  Carla survives.

Therefore: **there is no initial state from which Hal's choice is causally necessary
for Carla's survival**.

This separates two moral claims:

| Claim | Status |
|-------|--------|
| Hal should help Carla because doing so promotes `lifeC` | **True** (AS1/AS2 arguments exist) |
| Hal caused Carla's situation; she depends on him | **False** (AS3 result) |

Hal has a *positive obligation* toward Carla (grounded in AS1/AS2) but not *causal
responsibility* in the Lewis sense.  Carla's fate is in her own hands.

This result follows from the domain structure, not from a design choice.  A domain
without `takC` in Carla's action set would produce a different result.

### The `freedomH = 0` gap

No action in the canonical set modifies `mh` (Hal's money) in the counterfactual
direction.  `doNH` never changes `mh`, so no AS3 argument for `freedomH` can be
constructed.  This is a structural limit of the action model — see the
[frame problem note](../docs/notes/framing_problem.md).

---

## `causal_responsible/4`

```prolog
causal_responsible(hal, Q, J, P)
```

True iff `counterfactual_holds(Q, J, P)`.  Currently only Hal's causal responsibility
is modelled (the intervention operator replaces Hal's action).  Carla's responsibility
would require a symmetric operator.

---

## Relation to `possible_worlds.pl`

`counterfactual_holds` is a **special case** of `lewis_would/5` from
[[Possible World Semantics]].  The intervention produces exactly one counterfactual
world; with a singleton antecedent-world, there are no ties and no distance calculation
is needed.  `possible_worlds.pl` generalises this to arbitrary antecedents and
audience-relative closeness.

---

*Previous: [[Argumentation Layers]] · Next: [[Possible World Semantics]]*
