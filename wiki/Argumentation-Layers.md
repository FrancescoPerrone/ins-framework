# Argumentation Layers

The argumentation stack has four layers, each resolving a limitation of the one below.

---

## 1. Argument schemes (AS1, AS2, AS3)

Argument schemes translate AATS transitions into structured moral arguments.
An argument is a triple `(agent, action_sequence, value)`.

### AS1 — Forward positive promotion

> "In circumstances Q, perform Acts: it leads to a state that promotes value Val."

`argument(Ag, Acts, Val, as1)` holds when there exists an initial state from which
Acts reaches a state that is *better* with respect to Val for Ag.

AS1 arguments express positive promotion: the agent's action improves the situation.

### AS2 — Forward protective

> "In circumstances Q, perform Acts: it avoids a state that would demote value Val."

`argument(Ag, Acts, Val, as2)` holds when Acts avoids an alternative reachable state
that would have been *worse* with respect to Val.

AS2 arguments are defensive: the action prevents a bad outcome.  Including AS2 in the
extension layer raises the preferred extension count from 3 to 13 and the argument set
from 9 to 35.

### AS3 — Retrospective counterfactual

> "Perform joint action J rather than doing nothing, because had Hal done `doNH` at
> each step (holding Carla's actions fixed), value Val would have been demoted."

AS3 is structurally distinct from AS2.  AS2 is still forward-looking; AS3 is
retrospective — the action was *causally necessary* for the value to hold.
See [[Counterfactual and Causal Reasoning]] for full details and results.

### `arg/2` and the extension boundary

`arg/2` returns only AS1 + AS2 arguments (35 total).  AS3 arguments are excluded
because they use joint action sequences while the attack relation is defined over
individual sequences — mixing them without a unified vocabulary would produce incorrect
results.  AS3 arguments are accessible via `argument(hal, Acts, Val, as3)`.

### The attack relation

`attacks(A, B)` holds when B's recommended action conflicts with A's, or B undermines
A's value claim.  Attacks are symmetric in the Dung sense; asymmetry enters only at
the VAF level.

---

## 2. Dung extensions (`extensions.pl`)

Dung (1995) abstract argumentation computes the *jointly acceptable* sets of arguments
from the attack graph, with no reference to the content of arguments.

| Semantics | Definition | Result |
|-----------|-----------|--------|
| **Grounded** | Least fixed point of F(S) — cautious consensus | **empty** |
| **Preferred** | Maximal admissible sets | **13 extensions** |
| **Stable** | Preferred sets that defeat all non-members | subset of preferred |

**The empty grounded extension is significant**: it means the attack graph is
*maximally contentious* — no argument survives purely structural reasoning.  This is
the formal signature of a genuine moral dilemma: every position is contested.

The algorithm is a Caminada (2006) complete-labelling search (not brute-force powerset
enumeration).  Each argument receives a label `in`, `out`, or `undec`; constraint
propagation and backtracking find all maximal labellings.  The parameterised predicate
`preferred_ext_for/3` is reused by the VAF layer with the VAF defeat relation
substituted for Dung's attack.

---

## 3. Value-Based Argumentation Framework (`vaf.pl`)

Bench-Capon (2003) VAF extends Dung by associating each argument with the value it
promotes and evaluating defeat relative to an *audience* — a strict preference ordering
over values.

**VAF defeat rule**: A defeats B under audience P iff:
1. A attacks B, AND
2. B's value is **not** strictly preferred over A's value in P.

An argument for a higher-ranked value cannot be defeated by an argument for a
lower-ranked value.  This breaks attack symmetry in a normatively motivated way.

### The four audiences

| Audience       | Value order                            | Ethical stance                  |
|----------------|----------------------------------------|---------------------------------|
| `life_first`   | lifeH > lifeC > freedomH > freedomC   | Life always outweighs freedom   |
| `selfish`      | lifeH > freedomH > lifeC > freedomC   | Hal's interests first           |
| `altruistic`   | lifeC > lifeH > freedomC > freedomH   | Carla's wellbeing prioritised   |
| `freedom_first`| freedomH > freedomC > lifeH > lifeC   | Freedom values dominant         |

### VAF preferred extension counts

| Audience       | Extensions |
|----------------|:----------:|
| `life_first`   | 10         |
| `selfish`      | 10         |
| `altruistic`   | 10         |
| `freedom_first`| **6**      |

`freedom_first` gives 6 rather than 10 because no AS1 argument for `freedomH` exists
(the `freedomH` gap — see [[Module Reference]]).  Freedom arguments can only defend,
not advance.

### Audience-relativity as formal value pluralism

Different audiences yield different extension sets — different sets of arguments are
jointly acceptable.  Two agents reasoning under `selfish` and `altruistic` reach
incompatible conclusions while both reasoning correctly.  Neither is in logical error.
The system formally models moral pluralism: value disagreement does not require logical
error.

---

## 4. Dialectical proof and acceptance (`credulous.pl`)

Rather than asking "what are all the extensions?", acceptance queries ask about a
*specific* argument: is it in at least one preferred extension (credulous) or in every
preferred extension (sceptical)?

The φ₁-proof theory of Cayrol, Doutre & Mengin (2003) answers these queries via
**structured dialogues** between a PROponent and an OPPonent.  A φ₁-proof
`(Seq, Pro)` consists of:

- `Seq`: the chronological move sequence `[pro(A), opp(B), pro(C), …]`
- `Pro`: PRO's admissible defence set

PRO wins iff the dialogue terminates with PRO playing last (OPP's last challenge is
answered).  This is more efficient for single-argument queries than computing all
extensions, and it returns a *justification*, not just a yes/no answer.

### Results

| Query                | Result  | Interpretation                                          |
|----------------------|---------|---------------------------------------------------------|
| Credulously accepted | 35 / 35 | Every argument can be defended in a complete dialogue   |
| Sceptically accepted | 0 / 35  | No argument is forced on every rational agent           |

The 0/35 sceptical result is consistent with the empty grounded extension.  No moral
conclusion is universally compelling regardless of value ordering.

VAF variants (`vaf_credQA/3`, `vaf_sceptically_accepted/2`) run the same algorithm
with the audience-relative defeat relation substituted for Dung's attack.

---

*Previous: [[The Domain and AATS]] · Next: [[Counterfactual and Causal Reasoning]]*
