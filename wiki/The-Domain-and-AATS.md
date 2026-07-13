# The Domain and AATS

## The moral scenario

Agent **Hal** must decide whether and how to help **Carla**, a diabetic who needs
insulin to survive.  Hal has insulin; Carla does not.  The tension is between Hal's
autonomy (his right to keep his resources) and Carla's need (her right to life).

This scenario is the canonical test case from Atkinson & Bench-Capon (2006) for
practical moral argumentation.  It is used here because it is morally serious,
formally tractable, and has a published literature to position against.

---

## State representation

A state is a 6-tuple of binary attributes:

```prolog
[ih, mh, ah, ic, mc, ac]
```

| Position | Attribute | Meaning           |
|----------|-----------|-------------------|
| 1        | `ih`      | Hal has insulin   |
| 2        | `mh`      | Hal has money     |
| 3        | `ah`      | Hal is alive      |
| 4        | `ic`      | Carla has insulin |
| 5        | `mc`      | Carla has money   |
| 6        | `ac`      | Carla is alive    |

Each attribute is `1` (has it) or `0` (does not).  There are 64 possible states; a
subset are reachable from the initial states via the transition function.

### Initial states

Three initial states cover the morally relevant entry points:

| State             | Situation                               |
|-------------------|-----------------------------------------|
| `[0,1,1,1,1,1]`  | Hal lacks insulin; Carla has everything |
| `[0,1,1,0,1,1]`  | Both lack insulin; Hal has money        |
| `[1,1,1,0,1,1]`  | Carla lacks insulin; Hal has everything |

---

## Agents and actions

### Hal's individual actions (`actions.pl`)

| Action  | Precondition              | Effect                       | Moral reading          |
|---------|---------------------------|------------------------------|------------------------|
| `buyH`  | Hal has money, no insulin | Hal gains insulin, loses money | Self-help via market  |
| `takH`  | Carla has insulin         | Hal takes insulin from Carla | Taking from Carla      |
| `comH`  | Hal has insulin           | Carla gains insulin from Hal | Giving to Carla        |
| `losH`  | Hal has insulin           | Hal loses insulin            | Disposal               |
| `doNH`  | any                       | no change                    | Inaction               |

`doNH` (do nothing) is the counterfactual baseline: it is the action whose
substitution defines the AS3 scheme and Lewis causation.

### Carla's actions (implicit in `jactions.pl`)

`comC`, `takC`, `buyC`, `losC`, `doNC` — symmetric with Hal's individual actions
but defined only as joint-action components.

`takC` is critical: Carla can *take* insulin from Hal unilaterally.  This is the
reason the AS3 layer produces **zero** arguments for `lifeC` — Carla always has
`takC` available regardless of Hal's choice.  See [[Counterfactual and Causal Reasoning]].

### Values

| Value      | Attribute(s) realised | Subscribed by  |
|------------|----------------------|----------------|
| `lifeH`    | `ih`, `ah`           | Hal            |
| `lifeC`    | `ic`, `ac`           | Hal, Carla     |
| `freedomH` | `mh`                 | Hal            |
| `freedomC` | `mc`                 | Hal, Carla     |

Both `ih` and `ah` realise `lifeH` because lacking insulin leads to death — the
causal chain is compressed into a static attribute mapping.

---

## The AATS formal structure

The Action-Based Alternating Transition System (Wooldridge, Hoek & Jennings 2006) is
an **(n + 7)-tuple**:

```
S = ⟨Q, q₀, Ag, Ac₁, …, Acₙ, ρ, τ, φ, π⟩
```

| Component | Definition | Implementation |
|-----------|-----------|----------------|
| **Q** | Finite set of states | `state/1` in `states.pl` (64 states) |
| **q₀** | Initial state(s) | `initial_state/1` in `states.pl` |
| **Ag** | Agents: {hal, carla} | `agent/1` in `states.pl` |
| **Acᵢ** | Action sets per agent | `actions.pl` (Hal); `jactions.pl` (Carla implicit) |
| **ρ** | Precondition function | State patterns in `perform/3`, `performj/3` |
| **τ** | Transition function | `trans/4`, `transj/4` in `trans.pl` |
| **φ** | Atomic propositions | The six attributes `ih,mh,ah,ic,mc,ac` |
| **π** | Interpretation function | `attribute/3` in `states.pl` |

**The AATS tuple is not modified by any extension in this project.**  VAF, counterfactual,
and possible world semantics are additional structures defined *over* the AATS — they
use Q, τ, and π but leave the tuple unchanged.

---

## Two-step horizon

All argumentation and counterfactual reasoning operates over **2-step action sequences**
from initial states.  This is the minimal horizon at which the moral dilemma is fully
expressed: Hal can acquire resources in step 1 and transfer/withhold them in step 2,
or Carla can act to acquire resources independently.

---

*Next: [[Argumentation Layers]]*
