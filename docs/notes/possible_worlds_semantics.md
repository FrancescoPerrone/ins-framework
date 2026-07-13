# Note: Possible World Semantics for Counterfactual Conditionals

*Documents the possible_worlds.pl module. Article material.*
*Implemented 2026-05-11 in `v1.0/possible_worlds.pl`.*

---

## 1. Motivation: the residual gap in AS3

The counterfactual layer introduced in `counterfactual.pl` (see
`docs/notes/counterfactual_as3.md`) implements a **fixed-antecedent** intervention:
the counterfactual world is always and only the state reached by substituting `doNH`
for Hal's action at every step, holding Carla's actions fixed.  This captures exactly
one counterfactual world per action sequence, which is sufficient for the AS3 argument
scheme.

Three limitations remain, all rooted in the same structural choice:

1. **The antecedent is hard-coded.**  AS3 can only ask "what if Hal had done nothing?"
   It cannot ask general questions such as "what if Carla had lacked insulin all along?"
   or "what if neither agent had had money?"  These are legitimate moral questions — they
   arise whenever we want to understand the causal structure of the scenario beyond Hal's
   individual contribution.

2. **No notion of world closeness.**  The fixed-antecedent approach picks a unique
   counterfactual world by construction: there is nothing to compare because only one
   world is generated.  Lewis's insight — that the truth of a counterfactual depends
   on *which* world closest to actuality satisfies the antecedent — is unused.

3. **The conditional is not audience-relative.**  The VAF layer makes argument defeat
   relative to an audience's preference ordering over values.  The counterfactual layer
   does not: `counterfactual_holds/3` returns the same answer under every value ordering.
   Yet value orderings express what matters morally, and what matters morally should
   determine which world counts as "most similar" to the actual one.  A world that
   preserves Hal's life but changes his money should be judged closer to actuality under
   the `selfish` audience than one that kills Hal but preserves his money — because life
   outranks money in that ordering.

`possible_worlds.pl` resolves all three limitations:

- Antecedents are arbitrary predicates on outcome states.
- World closeness is computed via a value-weighted Hamming metric over the AATS state
  space.
- The metric is parameterised by the audience, making the closeness ordering, and
  therefore the counterfactual conditional itself, audience-relative in exactly the
  same way argument defeat is.

---

## 2. Background: Lewis and Stalnaker on counterfactuals

### 2.1 Lewis (1973)

Lewis's *Counterfactuals* defines the possible-world semantics for the conditional
`A □→ C` ("if it had been the case that A, then C would have been the case"):

> `A □→ C` is **true** at world *w* if and only if either (a) no A-world is accessible
> from *w* (vacuous truth), or (b) some A-world accessible from *w* is closer to *w*
> than any ¬A-world, and C holds in all A-worlds at least as close to *w* as that
> closest A-world.

In other words: look at the *closest* worlds where the antecedent is true; the
conditional holds iff the consequent holds in all of them.  The ordering of worlds by
similarity to the actual world is a *primitive* of the theory — Lewis provides no
universal recipe for it, but stipulates that it must satisfy certain formal conditions
(reflexivity, transitivity, totality within each sphere of accessibility).

The key feature of Lewis's account — and the one that makes it philosophically powerful
— is that **ties are allowed**.  Multiple worlds may share the minimum distance.  The
conditional is true only if the consequent holds in every minimally close world
satisfying the antecedent, not merely in one chosen representative.  This is the
*strong* reading: the conditional must survive all ways of making the antecedent true
at minimum cost.

### 2.2 Stalnaker (1968)

Stalnaker's account, developed five years before Lewis's book, posits a *selection
function* `f(A, w)` that picks a *unique* world — the closest A-world to *w*.  The
conditional `A > C` is true at *w* iff C holds in `f(A, w)`.

Stalnaker's *uniqueness assumption* — that there is always exactly one closest world —
is philosophically motivated: he argues that vagueness in the similarity ordering is
not a feature of the logic but of our incomplete specification of the selection
function.  Given a fully specified selection function, ties do not arise.

In a **finite discrete state space** such as the AATS, ties are not eliminable by
appeal to vagueness.  Two distinct states can genuinely share the same distance from
actuality under any reasonable metric.  `possible_worlds.pl` therefore handles ties
explicitly:

- `lewis_would/5` requires the consequent in **all** tied worlds — the universal
  reading.
- `stalnaker_would/5` selects the **first** element of the sorted closest-worlds list
  — a deterministic selection function that breaks ties by the canonical sort order of
  state lists.  This is not philosophically motivated but it is reproducible.

The two conditionals coincide when there is exactly one closest world, which is the
common case when the similarity metric assigns distinct weights to attributes and the
antecedent is specific enough to isolate a single world.

### 2.3 Formal notation

Let `W` be the set of all states reachable from initial state Q in exactly N
joint-action steps (the *world space* of the AATS).  Let `d_P(w₁, w₂)` denote the
value-weighted Hamming distance between worlds `w₁` and `w₂` under audience P (see
Section 3 below).  Let `|A|` denote the set of A-worlds: `{w ∈ W | A(w)}`.

The **Lewis conditional** is:

```
A □→_P C   iff   |A| ≠ ∅  ∧  ∀w ∈ min_{d_P}(|A|) . C(w)
```

where `min_{d_P}(|A|)` is the set of worlds in `|A|` minimising `d_P(actual, w)`.

The **Stalnaker conditional** is:

```
A >_P C    iff   |A| ≠ ∅  ∧  C(f_P(A, actual))
```

where `f_P(A, actual) = first(sort(min_{d_P}(|A|)))` — the canonical minimum.

Both conditionals are indexed by audience P, making them **audience-relative**: two
agents with different value orderings may reach different verdicts about the same
counterfactual.

---

## 3. The world space and the similarity metric

### 3.1 The AATS world space

The AATS defines a finite set of states Q and a transition function τ.  The *world
space* relative to a departure state q₀ and a horizon N is:

```
W(q₀, N) = { τ(q₀, j) | j ∈ JAg, τ(q₀, j) defined in N steps }
```

In `possible_worlds.pl` the horizon is fixed at N = 2, matching the AS1/AS2/AS3
layer: two joint-action steps from an initial state.  Every element of W(q₀, 2) is
a possible world in the Lewis sense: a complete, determinate assignment of all state
attributes.  The transition function τ (implemented as `transj/4`) constrains which
worlds are *possible* — not all 64 binary 6-tuples are reachable.  This is the right
restriction: only worlds that the AATS can reach are relevant to the conditional,
because the counterfactual posits an alternative course of events *within the same
causal structure*.

### 3.2 Value-weighted Hamming distance

The similarity metric `d_P(w₁, w₂)` is the **value-weighted Hamming distance** under
audience P:

```
d_P(w₁, w₂) = Σ_{a ∈ Attrs, w₁[a] ≠ w₂[a]} weight_P(a)
```

where `weight_P(a)` is the moral weight of attribute `a` under P.

The weight of an attribute is derived from the value it *realises* (via the `affects/2`
relation) and the rank of that value in P's preference ordering.  Formally:

```
weight_P(a) = N - rank_P(V(a))
```

where N is the number of values in P's ordering and `rank_P(V(a))` is the 0-based
position of the value associated with `a`.  The most-preferred value receives the
highest weight N; the least-preferred receives weight 1.

**Example** (audience `selfish`: lifeH > freedomH > lifeC > freedomC, N = 4):

| Attribute | Value    | Weight |
|-----------|----------|--------|
| `ih`      | lifeH    | 4      |
| `ah`      | lifeH    | 4      |
| `mh`      | freedomH | 3      |
| `ic`      | lifeC    | 2      |
| `ac`      | lifeC    | 2      |
| `mc`      | freedomC | 1      |

**Example** (audience `altruistic`: lifeC > lifeH > freedomC > freedomH, N = 4):

| Attribute | Value    | Weight |
|-----------|----------|--------|
| `ic`      | lifeC    | 4      |
| `ac`      | lifeC    | 4      |
| `ih`      | lifeH    | 3      |
| `ah`      | lifeH    | 3      |
| `mc`      | freedomC | 2      |
| `mh`      | freedomH | 1      |

The two orderings agree that life outranks money; they disagree on whose life is more
important.  Under `selfish`, a world that kills Hal incurs a distance penalty of 4 per
life-relevant attribute; under `altruistic`, a world that kills Carla incurs the same
penalty 4.  This is the formal content of audience-relativity in the closeness metric.

### 3.3 Interpretation

The distance `d_P(actual, w)` measures *how much the world w differs from actuality,
weighted by what P values*.  A world that agrees with actuality on all high-ranked
values but differs on a low-ranked value is judged close.  A world that disagrees on a
high-ranked value (e.g. Hal's survival) is judged far — even if it agrees on many
low-ranked attributes.

This gives the Lewis apparatus a moral interpretation: *world similarity is moral
similarity*.  Worlds that preserve what matters most under the audience's ordering are
the reference point for counterfactual reasoning.  The consequent must hold in the
world that is most morally continuous with actuality.

---

## 4. Relation to AS3 and the fixed-antecedent case

The AS3 argument scheme in `args.pl` / `counterfactual.pl` is a **special case** of
`lewis_would/5`.  Specifically:

```
counterfactual_holds(Q, J, P)
  ≡  lewis_would(Q, J, Ant_J, Con_P, any_audience)
```

where `Ant_J` is the antecedent "the actual state was not reached by J" — satisfied
by exactly the state reached via `cf_joint_seq(J)` — and `Con_P` is the negation of P.

More precisely: in `counterfactual.pl`, `cf_joint_seq/2` replaces Hal's component of
every joint action with `doNH`, producing a unique counterfactual world `Q_cf`.  The
transition function τ is deterministic, so `|Ant_J|` is a singleton `{Q_cf}`.  There
are no ties.  The distance calculation is vacuous: the unique antecedent-world is
automatically the closest (and only) one.

Under these conditions `lewis_would` reduces to:

```
∀w ∈ {Q_cf} . Con_P(w)   ≡   Con_P(Q_cf)
```

which is exactly `\+ holds(P, Q_cf)` — the condition checked by `counterfactual_holds`.

`possible_worlds.pl` therefore *grounds* the AS3 scheme within full Lewis semantics and
opens the door to general-antecedent counterfactuals not expressible through action
substitution alone.  AS3 is not superseded — it retains its role in argument
construction — but it is now understood as a degenerate, singleton case of a more
general theory.

---

## 5. Audience-relativity of the conditional

The most significant theoretical contribution of `possible_worlds.pl` is that
**counterfactual truth is audience-relative**.  This parallels the audience-relativity
of argument defeat in the VAF layer:

| VAF layer                          | Possible worlds layer                        |
|------------------------------------|----------------------------------------------|
| `defeats(A, B, Aud)`               | `lewis_would(Q, J, Ant, Con, Aud)`           |
| Defeat depends on value ordering   | Conditional truth depends on value ordering  |
| Same attack, different verdict     | Same antecedent, different closest worlds    |

Under `selfish`, the closest world where Carla lacks insulin is judged relative to
how much Hal's attributes change; under `altruistic`, it is judged relative to how
much Carla's attributes change.  Two agents with different values will, in general,
disagree about which world is the relevant reference point — and therefore about the
truth of the conditional.

This is not a relativism that undermines logic.  Both agents are reasoning correctly
under their own value system; neither is making an error.  The disagreement is
*structural*, not epistemic.  It is analogous to the way two scientists can rationally
disagree about which prior is appropriate for a Bayesian update: neither is wrong, but
their posteriors differ.

The implication for moral argumentation is significant:

> The same counterfactual — "had Carla lacked insulin, Hal's intervention would have
> been causally necessary for her survival" — can be true under `altruistic` (where
> Carla's survival is weighted most heavily) and false under `selfish` (where a world
> where Carla survives but Hal's money changes is judged equally close).

This is a precise, computable expression of the idea that moral reasoning is not
neutral: the background values of the reasoner shape what counts as causally relevant.

---

## 6. Lewis vs. Stalnaker in practice

### 6.1 When they agree

When the closest-worlds set is a singleton, `lewis_would` and `stalnaker_would` are
equivalent.  In the AATS, this is the common case: the value-weighted metric assigns
distinct weights to each attribute, and specific antecedents (e.g. "Hal lacks insulin")
typically select a unique minimally distant world.

### 6.2 When they diverge

Divergence occurs when two worlds are equidistant from actuality under the given metric
and both satisfy the antecedent.  This can happen when:

- The antecedent is satisfied by states that differ only in attributes of **equal
  weight** under the audience (e.g. `ih` and `ah` have the same weight under `selfish`
  because both realise `lifeH`).
- The antecedent is broad enough to admit multiple reachable worlds at the same
  distance.

In such cases `lewis_would` is **conservative**: the conditional fails unless the
consequent holds in all tied worlds.  `stalnaker_would` is **decisive**: it picks one
winner (the first in sorted order) and evaluates the consequent only there.

The practical difference: `stalnaker_would` can succeed where `lewis_would` fails.
The philosophical difference: `lewis_would` is appropriate when we want the conditional
to be robust — true regardless of which of the tied worlds is "really" the closest one.
`stalnaker_would` is appropriate when we are willing to commit to a selection function
that resolves ties by fiat.

For the purposes of the INS system, `lewis_would` is the more appropriate foundation
for moral argumentation: moral conclusions should not depend on arbitrary tie-breaking.

### 6.3 The uniqueness assumption in finite spaces

Stalnaker's uniqueness assumption is untenable as a general claim about finite discrete
state spaces.  The value-weighted Hamming distance is a sum of integers; many pairs of
states will share the same total distance from a given actual state.  This is not a
deficiency of the metric — it reflects genuine ties in moral weight.

The resolution in `possible_worlds.pl` is pragmatic: `sort/2` imposes a canonical
total order on states (by term ordering in SWI-Prolog), and the first element of the
sorted closest-worlds list serves as the Stalnaker selection.  This gives a
deterministic, reproducible system, but the philosophical status of the selection is
weak: it is an artefact of the implementation, not a morally principled choice.

This is another reason to prefer `lewis_would` as the primary conditional: it does not
require a selection function.

---

## 7. Problems in the original paper that possible world semantics addresses

The original Atkinson & Bench-Capon (2006) paper presents AS1 and AS2 as the complete
vocabulary for practical moral argumentation.  Three problems are made explicit by the
INS implementation:

**Problem 1 — No causal criterion.** AS1 and AS2 evaluate states, not causal
contributions.  Two arguments for the same action can have the same AS1/AS2 structure
while differing in whether the agent's action was causally necessary for the outcome.
The Lewis criterion for actual causation — "C causes E iff had C not occurred, E would
not have occurred" — is not expressible in AS1 or AS2.  `possible_worlds.pl` provides
it in full generality.

**Problem 2 — The doing/allowing gap.** In AS1/AS2 semantics, Hal's doing `doNH`
(doing nothing) is evaluated symmetrically with his doing `comH` (giving Carla insulin).
Both lead to some state, and both are evaluated by whether that state promotes or
demotes a value.  There is no formal distinction between an agent causing an outcome
and an agent failing to prevent it.  The possible world conditional provides this
distinction: `Hal intervenes □→_P Carla survives` is a different claim from `Carla
survives regardless` — and the difference is computed, not assumed.

**Problem 3 — Value asymmetry is not reflected in closeness.** AS1/AS2 treat all value
comparisons as binary (better/worse/neutral).  The VAF layer adds a ranking of values
within an audience, but this ranking affects only defeat, not the construction of
arguments.  The value-weighted closeness metric in `possible_worlds.pl` incorporates
the audience ordering into the semantics of the conditional itself, not merely into
the defeat relation.  Counterfactual worlds are now evaluated with the full moral
weight of the audience's preference structure.

---

## 8. Opening toward possible world semantics and quantum logic

The possible worlds module establishes the AATS state space as a Kripke frame: a set
of worlds (reachable states) together with an accessibility relation (the transition
function τ) and a valuation (the interpretation π mapping states to proposition sets).
Lewis's similarity spheres become computable objects — sets of worlds at distance ≤ r
from the actual world — indexed by the audience's value ordering.

This opens two directions for a second paper:

**Direction 1 — Full modal logic over the AATS.** The accessibility relation induced
by `transj/4` supports not just counterfactual conditionals but also alethic modalities
(`□φ`, `◇φ`), deontic operators (obligation, permission, prohibition), and dynamic
logic operators (action programs, post-conditions).  The value-weighted metric provides
a natural distance measure for graded modalities (e.g. "it is very likely that…" can
be interpreted as "in all worlds within distance r…").

**Direction 2 — Quantum logic and orthomodularity.** The lattice of propositions over
the AATS state space is a Boolean algebra — classical logic.  A natural generalisation
replaces it with an orthomodular lattice, the algebraic structure underlying quantum
logic (Birkhoff & von Neumann 1936; Dalla Chiara & Giuntini 2002).  In an
orthomodular lattice, the distributive law `A ∧ (B ∨ C) = (A ∧ B) ∨ (A ∧ C)` fails in
general.  This failure corresponds, in the quantum context, to incompatible
observables — facts that cannot be simultaneously determined.

The analogy to moral reasoning is this: two values may be *incompatible* in the sense
that their simultaneous satisfaction is not achievable in any reachable state —
analogous to quantum incompatible observables.  The formal machinery of orthomodular
lattices provides a logic for reasoning about such value incompatibilities beyond what
Boolean logic can express.  The audience-relative similarity metric in
`possible_worlds.pl` would play the role of the inner product in a quantum state
space: it determines which worlds are "close" to which, encoding the agent's value
structure as a geometric object rather than a linear order.

This is speculative at the level of the first paper, but the structural analogy is
precise and the formal tools are available.  The INS system establishes the
computational substrate — reachable states, value-weighted distances, audience-relative
conditionals — on which a quantum-logical extension can be built.

---

## 9. Implementation summary

`v1.0/possible_worlds.pl` exports:

| Predicate              | Arity | Purpose                                             |
|------------------------|-------|-----------------------------------------------------|
| `value_weight/3`       | 3     | Moral weight of a value under an audience           |
| `attr_weight/3`        | 3     | Moral weight of a state attribute under an audience |
| `value_distance/4`     | 4     | Value-weighted Hamming distance between two states  |
| `closest_worlds/5`     | 5     | Minimum-distance antecedent-satisfying worlds       |
| `lewis_would/5`        | 5     | Lewis □→ conditional (all closest worlds)           |
| `stalnaker_would/5`    | 5     | Stalnaker > conditional (unique selection)          |
| `hal_lacks_insulin/1`  | 1     | Standard antecedent: Hal has no insulin             |
| `carla_lacks_insulin/1`| 1     | Standard antecedent: Carla has no insulin           |
| `hal_dead/1`           | 1     | Standard antecedent: Hal is dead                   |
| `carla_dead/1`         | 1     | Standard antecedent: Carla is dead                 |
| `hal_lacks_money/1`    | 1     | Standard antecedent: Hal has no money              |
| `carla_lacks_money/1`  | 1     | Standard antecedent: Carla has no money            |

Dependencies: `states`, `values`, `vaf` (for `audience/2`), `trans`, `counterfactual`
(for `holds/2`).  No existing module is modified.

---

## 10. Relevant references

Lewis, D. (1973). *Counterfactuals*. Harvard University Press.
[Foundation of the possible-worlds semantics for conditionals. Direct source for
`lewis_would/5`.]

Lewis, D. (2000). Causation as influence. *The Journal of Philosophy*, 97(4), 182–197.
[Refined account of counterfactual causation; strengthens the connection between the
Lewis conditional and actual causation.]

Stalnaker, R. (1968). A theory of conditionals. *Studies in Logical Theory*, 2, 98–112.
American Philosophical Quarterly Monograph Series. Blackwell.
[The uniqueness-based selection-function semantics. Direct source for
`stalnaker_would/5`.]

Birkhoff, G., & von Neumann, J. (1936). The logic of quantum mechanics.
*Annals of Mathematics*, 37(4), 823–843.
[Founding paper for quantum logic; defines the orthomodular lattice structure.]

Dalla Chiara, M. L., & Giuntini, R. (2002). Quantum logics. In D. Gabbay & F. Guenthner
(Eds.), *Handbook of Philosophical Logic* (2nd ed., vol. 6, pp. 129–228). Springer.
[Survey of quantum logic formalisms; bridges to the second-paper direction.]

Halpern, J. Y., & Pearl, J. (2005). Causes and explanations: A structural-model
approach. *The British Journal for the Philosophy of Science*, 56(4), 843–887.
[Structural equations as interventions; `cf_joint_seq/2` as an intervention operator.]

Kripke, S. A. (1963). Semantic considerations on modal logic. *Acta Philosophica
Fennica*, 16, 83–94.
[Kripke semantics for modal logic; the AATS as a Kripke frame.]

Atkinson, K., & Bench-Capon, T. (2006). Addressing moral problems through practical
reasoning. *Deontic Logic and Artificial Normative Systems*, pp. 8–23. Springer.
[AS1/AS2 — the schemes AS3 extends, and the problems the possible worlds layer
addresses.]
