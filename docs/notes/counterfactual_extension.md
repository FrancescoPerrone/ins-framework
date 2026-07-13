# Counterfactual Conditionals as a Semantic Extension
*Implemented: 2026-05-11 in `v1.0/counterfactual.pl` and `v1.0/args.pl` (AS3 scheme).*

## Overview

The current implementation grounds argument construction in two practical argumentation
schemes from Atkinson & Bench-Capon (2006):

- **AS1** — perform action A to *promote* value V (positive, forward-looking)
- **AS2** — perform action A to *avoid* an outcome that would *demote* value V (negative, preventive)

Both schemes evaluate actions relative to what *does* happen: given state `q`, action `α`
transitions the system to `τ(q, α)`, and we ask whether the resulting state is better or
worse with respect to a value. This is a purely consequentialist, forward-looking assessment.

What the framework does not currently capture is **what would have happened had the agent
acted differently** — the counterfactual dimension of moral reasoning.

---

## The Doing / Allowing Distinction

A classical problem in moral philosophy concerns whether there is a morally relevant
difference between:

- **Doing harm** — performing an action that causes a bad outcome, and
- **Allowing harm** — omitting an action that would have prevented a bad outcome.

In the Hal/Carla scenario, `doNH` (Hal does nothing) is already represented as an
explicit action in the action set. However, within the current AATS semantics, `doNH`
is treated symmetrically with any other action: it has preconditions, a transition
function, and value-promotion properties like any other `α ∈ AcH`.

This creates a philosophical gap. Whether Hal's inaction is *morally equivalent to
active harm* is precisely the kind of question that counterfactual reasoning is designed
to answer. The standard formulation (following Lewis 1973, 2000) is:

> *C caused E* if and only if, had C not occurred, E would not have occurred.

Applied to the Hal/Carla case:

> *Had Hal not performed `doNH` — i.e., had he instead performed some alternative action
> `α'` — would Carla still be alive?*

If yes, then Hal's inaction is causally (and therefore potentially morally) responsible
for Carla's death in a way that the current AS1/AS2 evaluation does not make explicit.

---

## The Framing Problem and AS3-Style Schemes

The framing problem identified in `framing_problem.md` (item 15) notes that `freedomH`
produces no AS1 arguments: no action in the canonical action set positively promotes
Hal's financial freedom in a forward-looking sense. AS2 arguments for `freedomH` exist
defensively, but no proactive argument can be constructed.

A counterfactual argumentation scheme — informally an **AS3** — could partially address
this:

> **AS3 (counterfactual)**: Perform action A because, had A not been performed, value V
> would have been demoted — even if performing A does not itself positively promote V.

This is structurally distinct from AS2. AS2 says: *"do A to prevent demotion of V"* —
it is still forward-looking. AS3 says: *"A is justified because its absence would have
caused a worse outcome"* — it reconstructs the argument retrospectively through the
counterfactual conditional.

For `freedomH`, this would allow the system to represent arguments of the form: *"Hal
buying insulin preserves his financial freedom in a counterfactual sense, because had he
been compelled to give his insulin away without choice, his freedom would have been
violated"*. The distinction between voluntary action and compelled action — central to
autonomy-based ethics — is invisible to AS1/AS2 but becomes representable under AS3.

---

## Causal Responsibility in VAF

Bench-Capon's Value-Based Argumentation Framework (2003) extends Dung's abstract
framework by associating arguments with values and evaluating defeat relative to audience
preference orderings. It captures *what values are at stake* and *whose preferences
determine which arguments prevail*.

What it does not capture is **causal responsibility**: the question of which agent's
action (or inaction) is the proximate cause of an outcome. In multi-agent scenarios —
and Hal/Carla is explicitly a two-agent scenario with joint actions — causal
responsibility is not straightforward. Consider:

- `comH-takC`: Hal complies, Carla takes insulin — both agents act.
- `doNH-losC`: Hal does nothing, Carla loses insulin — who bears responsibility for
  the outcome?

The current VAF layer assigns value promotions to joint action sequences but does not
distinguish *which agent's contribution was causally necessary* for the outcome. A
counterfactual layer would allow this:

> *Hal's contribution to joint action j was causally necessary for outcome P if and only
> if: had Hal performed `doNH` instead, P would not hold in the resulting state.*

This recovers a principled notion of individual causal responsibility within a joint
action framework — a question directly relevant to normative systems, legal reasoning,
and the moral evaluation of collective action.

---

## Formal Sketch

The AATS already provides the machinery needed for a minimal counterfactual extension.
The transition function `τ : Q × JAg → Q` is total over its domain. A counterfactual
predicate could be defined as:

```prolog
%% counterfactual_holds(+Q, +J, +P)
%
%  True if proposition P holds in the state resulting from joint action J in state Q,
%  but would NOT hold had Hal instead performed doNH (all else equal).
%
%  Captures: "P holds in τ(Q,J) and would not hold in τ(Q, J[doNH])"
%  — i.e., Hal's choice of J (rather than doNH) is causally responsible for P.

counterfactual_holds(Q, J, P) :-
    trans(Q, J, Q1),          % actual outcome
    holds(P, Q1),             % P holds in actual outcome
    counterfactual_action(J, J_counter),  % construct counterfactual joint action
    trans(Q, J_counter, Q2),  % counterfactual outcome
    \+ holds(P, Q2).          % P does NOT hold in counterfactual outcome
```

Where `counterfactual_action/2` replaces Hal's component of the joint action with `doNH`
while keeping Carla's action fixed — isolating Hal's causal contribution.

The dual predicate (P holds counterfactually but not actually) would capture cases where
inaction *prevented* a good outcome — directly encoding the doing/allowing distinction
in the AATS.

---

## Relation to Existing Literature

This line of extension connects to several bodies of work that intersect with the
theoretical foundations of this project:

- **Lewis (1973, 2000)** — the closest-possible-worlds semantics for counterfactuals,
  which provides the philosophical grounding for the "what would have happened" question.
- **Halpern & Pearl (2001, 2005)** — structural equation models for actual causation,
  which give a formal account of causal responsibility in multi-variable systems closely
  analogous to the AATS state representation.
- **Sergot (2014) and C+ / action formalisms** — the normative systems tradition that
  directly informs this implementation already addresses omission and indirect effects;
  counterfactual conditionals are a natural complement.
- **Prakken & Sartor (1996)** — argumentation-based accounts of legal reasoning, where
  counterfactual causation is a standard tool for establishing liability.

---

## Implementation Results

The extension has been implemented in `v1.0/counterfactual.pl` and `v1.0/args.pl`.

**Predicates added (`counterfactual.pl`):**
- `holds/2` — propositional interface over state attribute encoding
- `cf_joint_seq/2` — replaces Hal's action component with `doNH`, holding Carla fixed
- `counterfactual_holds/3` — P holds in actual outcome but not in counterfactual
- `causal_responsible/4` — Hal's action was causally necessary for P

**AS3 argument scheme (`args.pl`):**
- `argument(hal, Acts, Val, as3)` — 10 arguments generated for `lifeH`
- AS3 produces **0 arguments for `lifeC`** — a theoretically meaningful finding (see below)
- AS3 produces **0 arguments for `freedomH`/`freedomC`** — as predicted by the
  framing-problem analysis: `doNH` never modifies `mh`/`mc`

**The lifeC = 0 finding:**  
Hal has no causal responsibility for Carla's survival in the counterfactual sense.
In every scenario where Carla lacks insulin, she retains an available `takC` action
that gives her insulin regardless of what Hal does (Hal still has insulin when doing
`doNH`).  The counterfactual — "had Hal done nothing, Carla would have died" — is
never true, because Carla can always take insulin from Hal even without his cooperation.
This precisely captures the moral asymmetry between Hal's self-preservation and his
obligations to Carla: Hal's survival depends causally on his own choices; Carla's
survival depends on *her* choices, not on Hal's.

**Scope:** AS3 arguments are joint action sequences (structurally distinct from AS1/AS2
individual sequences) and are excluded from `arg/2`, leaving the Dung/VAF extension
layer untouched.  Integration into extensions is left as future work.

**API:** `GET /counterfactual` and `GET /counterfactual/causal/:prop` in `webapp/server.pl`.

**The primary contributions:**

1. The doing/allowing distinction for `doNH` — now formally tractable via `counterfactual_holds/3`
2. Causal responsibility attribution in joint actions — `causal_responsible/4`
3. An AS3 argumentation scheme — 10 new arguments for `lifeH`; the zero result for
   `lifeC` is a domain finding, not a gap
4. The `freedomH` gap remains — confirmed unfillable without changing the action model
   (the framing problem cannot be resolved from within the formal system)

---

## References

Bench-Capon, T. (2003). Persuasion in practical argument using value-based argumentation
frameworks. *Journal of Logic and Computation*, 13(3), 429–448.

Halpern, J. Y., & Pearl, J. (2005). Causes and explanations: A structural-model approach.
*The British Journal for the Philosophy of Science*, 56(4), 843–887.

Lewis, D. (1973). *Counterfactuals*. Harvard University Press.

Lewis, D. (2000). Causation as influence. *The Journal of Philosophy*, 97(4), 182–197.

Prakken, H., & Sartor, G. (1996). A dialectical model of assessing conflicting arguments
in legal reasoning. *Artificial Intelligence and Law*, 4(3–4), 331–368.

Sergot, M. (2014). Normative positions. In *Handbook of Deontic Logic and Normative
Systems* (pp. 353–406). College Publications.
