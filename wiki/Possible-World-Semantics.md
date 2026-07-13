# Possible World Semantics

## Motivation: three residual gaps in AS3

The fixed-antecedent counterfactual in `counterfactual.pl` leaves three gaps:

1. **Hard-coded antecedent** — AS3 can only ask "what if Hal had done nothing?"
   General questions ("what if Carla had lacked insulin?") are inexpressible.

2. **No world closeness** — the intervention picks one counterfactual world
   mechanically.  Lewis's insight — that a counterfactual's truth depends on *which*
   world is *most similar* to actuality — is unused.

3. **Not audience-relative** — `counterfactual_holds/3` returns the same answer under
   every value ordering, even though values determine what counts as morally important.

`possible_worlds.pl` resolves all three.

---

## The world space

The **world space** relative to an initial state Q is the set of all states reachable
from Q in exactly 2 joint-action steps:

```
W(Q) = { W | transj(Q, _, W, 2) }
```

Every element of W(Q) is a *possible world* in the Lewis sense: a complete, determinate
assignment of all state attributes.  Only AATS-reachable states are included — worlds
that the causal structure can actually produce.

---

## Value-weighted Hamming distance

The similarity metric `d_P(w₁, w₂)` between two worlds, under audience P:

```
d_P(w₁, w₂) = Σ_{a : w₁[a] ≠ w₂[a]} weight_P(a)
```

where `weight_P(a) = N − rank_P(value(a))`.  The most-preferred value (rank 0)
receives weight N; the least-preferred receives weight 1.

**Moral interpretation**: world distance is *moral* distance.  A world that preserves
the most important values is judged closest to actuality.

### Weights under two audiences (N = 4)

| Attribute | Value    | `selfish` | `altruistic` |
|-----------|----------|:---------:|:------------:|
| `ih`, `ah`| lifeH    | **4**     | 3            |
| `ic`, `ac`| lifeC    | 2         | **4**        |
| `mh`      | freedomH | 3         | 1            |
| `mc`      | freedomC | 1         | 2            |

Under `selfish`, differences in Hal's life attributes cost more; under `altruistic`,
differences in Carla's life attributes cost more.  The same physical difference has a
different moral cost depending on whose values the reasoner holds.

### Distance examples (actual state `[1,1,1,0,1,1]`)

| World W           | `selfish` | `altruistic` | Attribute differing |
|-------------------|:---------:|:------------:|---------------------|
| `[0,1,1,0,1,1]`  | 4         | 3            | `ih` (lifeH)        |
| `[1,0,1,0,1,1]`  | 3         | 1            | `mh` (freedomH)     |
| `[1,1,0,0,1,1]`  | 4         | 3            | `ah` (lifeH)        |
| `[1,1,1,0,1,0]`  | 2         | 4            | `ac` (lifeC)        |

---

## Lewis □→ and Stalnaker >

### Lewis (1973)

```
A □→_P C   iff   |A| ≠ ∅  ∧  ∀w ∈ min_{d_P}(|A|) . C(w)
```

The conditional is true iff C holds in **all** worlds minimising `d_P(actual, w)`
among worlds satisfying A.  When ties exist, all must satisfy C — the conservative
reading.

```prolog
lewis_would(+Q, +J, :Ant, :Con, +Aud)
```

### Stalnaker (1968)

```
A >_P C    iff   |A| ≠ ∅  ∧  C(f_P(A, actual))
```

A unique closest world is selected; C must hold only there.  Stalnaker's *uniqueness
assumption* does not hold in a finite discrete state space — ties arise naturally.
Ties are broken by canonical sort order (deterministic, but philosophically arbitrary).

```prolog
stalnaker_would(+Q, +J, :Ant, :Con, +Aud)
```

### When they agree and diverge

The two conditionals **agree** when the closest-worlds set is a singleton.
They **diverge** when ties occur and the consequent does not hold in all tied worlds
but does hold in the first sorted one (Stalnaker true, Lewis false) — or vice versa.

---

## Canonical divergence example

**From state `[0,0,1,1,1,1]`, sequence `[takH-comC, losH-doNC]`, antecedent
`carla_lacks_insulin`, consequent `hal_dead`:**

Under `life_first` (N=4, lifeH=4, lifeC=3), three worlds tie for minimum distance
from the actual outcome.  The first sorted world has Hal dead (`ah=0`); the other two
do not.

| Audience       | Closest worlds | `lewis_would` | `stalnaker_would` |
|----------------|:--------------:|:-------------:|:-----------------:|
| `life_first`   | 3 (tie)        | false         | **true**          |
| `altruistic`   | 2 (tie)        | false         | **true**          |
| `selfish`      | 1              | false         | false             |
| `freedom_first`| 2 (tie)        | false         | **true**          |

Under `selfish`, the high weight on `mh` (freedomH = 3) breaks the tie by making the
world differing only in money further away than worlds differing in life attributes,
isolating a unique closest world.  Under other audiences, weights on Carla's life
attributes create ties.

The choice between Lewis and Stalnaker is not merely technical: it depends on the
audience's value ordering.  Under `selfish`, the two conditionals agree; under the
others, they diverge.

---

## Audience-relativity: the novel contribution

The same audience ordering that governs **VAF argument defeat** also governs
**world closeness**:

| VAF layer | Possible worlds layer |
|-----------|----------------------|
| `defeats(A, B, Aud)` | `lewis_would(Q, J, Ant, Con, Aud)` |
| Defeat depends on value ordering | Conditional truth depends on value ordering |
| Same attack → different defeat verdict | Same antecedent → different closest worlds |

Two agents with different value orderings can **rationally disagree** about the truth
of the same counterfactual — not because one is reasoning incorrectly, but because
they weight morally important differences differently.  This is the formal expression
of value pluralism extended from the defeat relation to the modal semantics.

---

## AS3 as a degenerate case

`counterfactual_holds(Q, J, P)` is equivalent to `lewis_would` when the antecedent is
satisfied by exactly one world — the unique `cf_joint_seq` substitution.  With a
singleton antecedent-world, there are no ties, no distance calculation is needed, and
`lewis_would` reduces to `\+ holds(P, CfWorld)`.

`possible_worlds.pl` therefore *grounds* AS3 within full Lewis semantics and opens the
system to general-antecedent counterfactuals not expressible through action substitution.

---

## Standard antecedent predicates

For convenience, six ready-made antecedent predicates are exported:

```prolog
hal_lacks_insulin(S)   :- \+ holds(has_insulin(hal),   S).
carla_lacks_insulin(S) :- \+ holds(has_insulin(carla), S).
hal_dead(S)            :- \+ holds(alive(hal),          S).
carla_dead(S)          :- \+ holds(alive(carla),        S).
hal_lacks_money(S)     :- \+ holds(has_money(hal),      S).
carla_lacks_money(S)   :- \+ holds(has_money(carla),    S).
```

Any predicate `P` of arity 1 can be passed as an antecedent or consequent to
`lewis_would/5` and `stalnaker_would/5`.

---

*Previous: [[Counterfactual and Causal Reasoning]] · Next: [[Getting Started]]*
