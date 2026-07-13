# Note: Credulous and Sceptical Acceptance — Implementation and Interpretation

*Documents item 18: dialectical proof via credQA. Article material.*

---

## Background and motivation

Marek Sergot sent `articles/sergot/templates/accepted_arg.pl`, his SWI-Prolog adaptation
of the algorithm in:

> Cayrol, C., Doutre, S., & Mengin, J. (2003). On decision problems related to the
> preferred semantics for argumentation frameworks. *Journal of Logic and Computation*,
> 13(3), 377–402.

The paper addresses two decision problems that are distinct from — and in practice more
useful than — enumerating all preferred extensions:

- **Credulous acceptance**: is argument *a* in *at least one* preferred extension?
- **Sceptical acceptance**: is argument *a* in *every* preferred extension?

The paper proves that credulous acceptance is NP-complete and sceptical acceptance is
Π₂ᵖ-complete under preferred semantics. Rather than answering these by computing all
extensions (which is expensive and more than needed), the paper provides a **φ₁-proof
theory**: a dialectical framework in which the answer is computed as a structured dialogue
between a PROponent and an OPPonent.

---

## The φ₁-proof structure

A φ₁-proof that argument *a* is credulously accepted is a **won dialogue**:

1. PRO opens by putting forward *a*.
2. OPP may attack any argument currently held by PRO (the undefended ones).
3. PRO counters by putting forward a new argument that attacks OPP's last move,
   provided it does not conflict with PRO's existing set and has not been previously
   excluded.
4. The dialogue continues until OPP has no legal reply — PRO wins.

At termination, PRO's argument set is an **admissible set** containing *a*, witnessing
that *a* is in at least one preferred extension.

The proof is returned as a pair **(Seq, Pro)**:
- **Seq** — the chronological dialogue sequence: a list of `pro(Arg)` and `opp(Arg)`
  moves, oldest first.
- **Pro** — PRO's final admissible argument set (contains *a* and all arguments PRO
  introduced during the dialogue).

---

## Implementation

`v1.0/credulous.pl` is a **standalone additive module** — no existing files were modified
except adding `use_module(credulous)` to `dbg.pl` and `server.pl`.

The core innovation over Sergot's template is **abstraction of the defeat predicate**:
rather than hardcoding `attacks/2`, the algorithm is parameterised on a binary predicate
`AP` called as `call(AP, Attacker, Target)`. This allows the same code to handle both:

```prolog
credQA(Arg, Proof) :-           % Dung: uses attacks/2
    cred_qa(attacks, Arg, Proof).

vaf_credQA(Arg, Aud, Proof) :-  % VAF: uses defeats/3 via YALL lambda
    cred_qa([A,B]>>defeats(A,B,Aud), Arg, Proof).
```

This mirrors the same pattern used in `preferred_ext_for/3` (item 16), keeping the
codebase consistent.

Sceptical acceptance is derived directly from the extension enumeration rather than
through the dialogue procedure (the CDM paper addresses the sceptical case separately;
for our purposes the extension-based check is sufficient):

```prolog
sceptically_accepted(Arg) :-
    all_arguments(All), member(Arg, All),
    forall(preferred_extension(Ext), member(Arg, Ext)).
```

**New API endpoints** (additive, existing endpoints unchanged):
- `GET /credulous` — all credulously accepted arguments with their φ₁ proofs
- `GET /credulous/sceptical` — all sceptically accepted arguments
- `GET /credulous/vaf/:audience` — credulously accepted arguments under VAF

**New dbg.pl sections** (16–18) demonstrate all three predicates interactively.

---

## Results

### Dung preferred semantics (AS1 + AS2, 35 arguments, 13 preferred extensions)

| Query | Result |
|---|---|
| Credulously accepted | **35 / 35** — every argument |
| Sceptically accepted | **0 / 35** — no argument |

### Interpretation

**Every argument is credulously accepted.** This means every argument appears in at
least one preferred extension. In terms of the moral scenario: for every action sequence
Hal could take, there is some coherent value ordering under which that action can be
defended. No action is indefensible in every context.

**No argument is sceptically accepted.** This means no argument is in every preferred
extension — equivalently, the grounded extension is empty (the grounded extension is
exactly the set of sceptically accepted arguments under preferred semantics, a known
result from Dung 1995). This is consistent with our independently computed result:
`grounded_extension([])`.

These two results together characterise the framework as **maximally contentious**: every
argument can be challenged (nothing is unassailable) and every argument can also be
defended (nothing is indefensible). The moral landscape of the insulin scenario is one
of genuine, irresolvable conflict between values — not one where any action is obviously
right or obviously wrong.

---

## The one-move proof and its meaning

For arguments like `arg([buyH,doNH], lifeH)` (Hal buys insulin for himself), the
φ₁-proof under Dung semantics is:

```
Seq = [pro(arg([buyH,doNH],lifeH))]
Pro = [arg([buyH,doNH],lifeH)]
```

A single PRO move, with no OPP reply. This means OPP has no legal move after PRO
opens: every argument that attacks `arg([buyH,doNH],lifeH)` is itself attacked by
`arg([buyH,doNH],lifeH)`. PRO's argument is **self-defending** — it defeats every
argument that could challenge it, so the opponent cannot introduce any argument that
PRO has not already countered.

In philosophical terms: Hal buying insulin for himself is a position that fully defends
itself against all moral objections *within this framework*. Any argument against it
(e.g. prioritising Carla's insulin over Hal's) is itself countered by Hal's
self-interest argument. This does not mean the position is *correct* — it is sceptically
accepted by no one — but it is locally coherent and self-sustaining.

This is a precise formal result with a clear philosophical reading, of the kind that
justifies the implementation as more than a technical exercise.

---

## Longer proofs: when the dialogue has multiple moves

Not all arguments produce one-move proofs. An argument A with a multi-step proof
indicates that A's admissible set requires PRO to introduce additional supporting
arguments to counter OPP's challenges. The length and structure of the proof encodes
the *dialectical complexity* of the argument — how much supporting structure it needs
to be defensible.

For the article, showing the contrast between a self-defending argument (one-move proof)
and one that requires a chain of supporting moves would illustrate the expressive power
of the dialogue framework over simple extension membership.

---

## Connection to VAF credulous acceptance

Under VAF, the defeat relation is asymmetric. The `vaf_credQA` predicate uses
`[A,B]>>defeats(A,B,Aud)` as the defeat predicate. The YALL lambda preserves the `vaf`
module context (same fix as in `preferred_ext_for/3`), ensuring `defeats/3` is resolved
correctly regardless of where `call/3` is executed.

Under `altruistic` audience (lifeC > lifeH > freedomC > freedomH), the proof for
`arg([comH,doNH],lifeC)` is again a one-move proof. Under `life_first`, lifeC arguments
will require PRO to fight harder — the audience's preference for lifeH means lifeH
arguments defeat lifeC arguments, forcing PRO to find counter-moves. The structure of
these proofs under different audiences directly captures how the ethical stance of the
audience shapes the difficulty of defending a moral position.

---

## Relationship between results and open theoretical questions

The zero sceptical acceptance result reinforces the item 15 / framing problem point:
in a domain with genuine value conflict and no dominant value ordering, no argument
commands universal assent. The system does not converge on a moral conclusion — it maps
the space of defensible positions. Whether this is a limitation or a feature depends on
the theoretical claims being made:

- As a *decision support tool*: limitation — it does not tell you what to do.
- As a *model of moral pluralism*: feature — it accurately represents the genuine
  disagreement between ethical stances.

The article should make this distinction explicit.

---

## Relevant references

- Cayrol, C., Doutre, S., & Mengin, J. (2003). On decision problems related to the
  preferred semantics for argumentation frameworks. *Journal of Logic and Computation*,
  13(3), 377–402. [Source algorithm.]
- Dung, P.M. (1995). On the acceptability of arguments and its fundamental role in
  nonmonotonic reasoning, logic programming and n-person games. *Artificial Intelligence*,
  77(2), 321–357. [Grounded extension = sceptically accepted arguments.]
- Caminada, M. (2006). On the issue of reinstatement in argumentation. *JELIA 2006*,
  LNCS 4160, pp. 111–123. [Labelling algorithm underlying the extension computation.]
- Bench-Capon, T. (2003). Persuasion in practical argument using value-based
  argumentation frameworks. *Journal of Logic and Computation*, 13(3), 429–448.
  [VAF — defeat relation used in vaf_credQA.]
- Atkinson, K., & Bench-Capon, T. (2006). Addressing moral problems through practical
  reasoning. *Deontic Logic and Artificial Normative Systems*, pp. 8–23. Springer.
  [AS1/AS2 argument schemes — the arguments being queried.]
