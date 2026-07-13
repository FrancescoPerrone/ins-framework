# TODO — Implementation Gaps (Priority Order)

---

## ~~1. Fix `arg/2` duplicate results (args.pl)~~ — DONE

Fixed via `setof/3` deduplication. Each `(Acts, Val)` pair is now produced exactly once.

---

## ~~2. Fix `doNH-losC` duplicate clauses (jactions.pl)~~ — DONE

Removed duplicate clause at line 52 (was identical to line 47).

---

## ~~3. Fix `demotes/4` hardcoded agent (values.pl)~~ — DONE

Changed `worse(hal, ...)` to `worse(Ag, ...)` so `eval/4` works correctly for any agent.

---

## ~~4. Extend argumentation to cover all values (args.pl)~~ — DONE

Added 3 new initial state patterns to `trans.pl` (for lifeC, freedomH, freedomC scenarios)
and a new `earnH` action to `actions.pl`. All 4 values now produce arguments.

---

## ~~5. Implement argument defeat and extensions (args.pl)~~ — DONE

`extensions.pl` implements full Dung (1995) semantics: conflict-free, admissible,
preferred, grounded, and stable extensions.
`vaf.pl` implements the Value-Based Argumentation Framework with 4 audiences.

---

## ~~6. Fix export warnings (extensions.pl)~~ — DONE

Exported `powerset/2` and `is_subset/2` so `vaf.pl` can import them without warnings.

---

## ~~7. Wire joint actions into `trans.pl`~~ — DONE

Added `transj/4` to `trans.pl` (mirrors `trans/4` using `performj/3`). Exported via
module declaration; `jactions` loaded via `use_module`. `dbg.pl` test section 12
confirms joint transitions fire correctly from all initial states.

---

## ~~8. Add Carla's value subscription (values.pl)~~ — DONE

Added `sub([lifeC, freedomC], carla).` to `values.pl`. `dbg.pl` test section 13
confirms `eval(carla, ...)` produces correct `[+lifeC]`/`[-freedomC]` evaluations
over joint transitions.

---

## ~~9. Include `neut` in `eval/4` (values.pl)~~ — DONE

Added `neutral(Ag, S1, S2, Val)` as a third disjunct in `eval/4`'s `setof`. Neutral
values appear as `@(Val)` in the result, visually distinct from `+Val`/`-Val`.
Comment above `eval/4` documents why they were originally omitted (no role in
argument construction or the Dung attack relation) and why they are now included
(completeness).

---

## ~~10. Write test queries in `dbg.pl`~~ — DONE

`dbg.pl` now has 11 test sections covering states, transitions, value evaluations,
arguments, attacks, grounded/preferred/stable Dung extensions, and VAF extensions
per audience.

---

## ~~11. Fix typo in `webapp/test.pl`~~ — DONE

Fixed `contais(fridge)` → `contains(fridge)` as part of the webapp rewrite.

---

## ~~12. Connect webapp to the reasoning system~~ — DONE

`webapp/server.pl` loads all AATS modules and exposes JSON endpoints:
- `GET /args` — all arguments with `agent`, `actions`, `value`, `scheme` fields
- `GET /attacks` — all attack pairs
- `GET /extensions` — Dung grounded/preferred/stable extensions
- `GET /vaf` — list all named audiences
- `GET /vaf/:audience` — VAF preferred extensions for a named audience (404 if unknown)
- `GET /vaf/:audience/grounded` — VAF grounded extension

---

## ~~13. Implement AS2 argument scheme (args.pl)~~ — DONE

Added `argument/4` with `as1`/`as2` scheme tags. AS2 argues against actions that
would demote a value. `arg/2` restricted to AS1 to keep extensions tractable.

---

## ~~14. Add `initialization` directive to `server.pl`~~ — DONE

Added `:- initialization(server(8000), main).` so `swipl v1.0/webapp/server.pl`
starts the HTTP server automatically without needing a manual `?- server(8000).` call.

---

## 15. `freedomH` coverage gap — OPEN (kept open by design)

`freedomH` produces no AS1 arguments because no canonical action promotes `mh`. Adding
one (e.g. `earnH`) would be non-canonical and raise the frame problem: which actions
belong in the model is a prior modelling choice outside the formal system. This gap is
kept open deliberately as a case study in the limits of logic-only moral reasoning —
see `docs/notes/framing_problem.md` for the full argument and article material.

---

## ~~16. Integrate AS2 into extensions/VAF~~ — DONE

Replaced brute-force powerset enumeration (O(2^n)) with Caminada (2006) complete-labelling
search in `extensions.pl`. The algorithm:
1. Initialises all arguments as `undec`.
2. Propagates forced labels (no-attacker → in; in-attacker → out) to fixed point.
3. For each remaining `undec` arg, tries `in` (+ propagate) or keeps `undec` (search tree).
4. Accepts a labelling as preferred iff it is complete (all completeness conditions satisfied)
   and no `undec` arg can be moved to `in` without contradiction.

Key correctness fix: `lb_is_complete/3` check rejects incomplete labellings where an `in`-labelled
argument's defeaters are `undec` rather than `out`. Required for VAF asymmetric defeat (e.g.
under `life_first`, lifeH args have no defeaters so they must be `in`, forcing lifeC args to `out`).

`preferred_ext_for/3` is exported so `vaf.pl` can reuse the algorithm with the VAF defeat
relation via a YALL lambda: `[A,B]>>defeats(A,B,Aud)` (preserves vaf module context).

VAF preferred extensions (correct):

| Audience       | Preferred extensions         |
|----------------|------------------------------|
| `life_first`   | 3 lifeH singletons           |
| `selfish`      | 3 lifeH singletons           |
| `altruistic`   | 3 lifeC+freedomC pairs       |
| `freedom_first`| 3 lifeC+freedomC pairs       |

Note: `freedom_first` now correctly gives lifeC+freedomC pairs (not ∅ as previously stated).
Under this audience, freedomC > lifeH, so the freedomC args defeat the lifeH args; the
lifeC+freedomC compatible-action pairs become the preferred extensions.

AS2 remains excluded from `arg/2` (and thus extensions/VAF) by design choice: including AS2
would roughly triple the argument set and the attack/defeat graph without additional theoretical
motivation. AS2 is still generated and displayed by `argument/4` and the `/args` API endpoint.

---

## ~~17. Enable AS2 in extensions~~ — DONE

One-line change in `args.pl`: `argument(hal, Acts, Val, _)` (was `as1` only). Prerequisite
was item 16 (labelling algorithm). Results: 9→35 args, 6→13 Dung preferred exts, VAF
extensions roughly tripled. `freedom_first` gives 6 (not 10): AS2 `freedomH` args now
participate but only defensively — no AS1 `freedomH` args exist (framing problem, item 15).

Full problem description, results table, and theoretical significance for the article:
→ `docs/notes/as2_in_extensions.md`

---

## ~~18. Add dialectical proof / credulous acceptance query (credQA)~~ — DONE

### Why we want this

Marek Sergot sent us two files:

- `articles/sergot/CayrolDoutreMengin.pdf` — Cayrol, Doutre & Mengin (2003), "On Decision
  Problems Related to the Preferred Semantics for Argumentation Frameworks", *J. Logic
  Computat.* 13(3):377–402. Same journal and year as Bench-Capon's VAF paper.
- `articles/sergot/templates/accepted_arg.pl` — his own SWI-Prolog implementation of the
  `credQA` algorithm from that paper, with `articles/sergot/templates/test_arg.pl` as the
  test harness (the exact framework AF₁ from the paper's Example 2.2).

This is not background reading. It is a design suggestion.

The paper addresses a fundamentally different question from the one our current implementation
answers. Where we enumerate *all* preferred extensions, it asks:

- **Credulous acceptance**: is argument *a* in *at least one* preferred extension? (NP-complete)
- **Sceptical acceptance**: is argument *a* in *every* preferred extension? (Π₂ᵖ-complete)

And rather than computing extension sets, it answers these questions through **dialectical
proofs** — formalised as a two-player dialogue between a PROponent and an OPPonent. PRO tries
to defend the argument; OPP tries to refute it. A φ₁-proof is a winning dialogue for PRO: it
terminates, PRO plays last, and PRO's argument set is admissible. The algorithm returns not
just yes/no but the full dialogue sequence as a justification.

There are three specific reasons to add this to the INS system:

1. **More efficient for querying.** You do not need to enumerate all extensions to answer
   a single acceptance query. For practical use ("should Hal do X?") this is faster and
   more direct than computing the whole extension lattice.

2. **Directly maps onto the moral reasoning scenario.** Hal's deliberation *is* a dialogue.
   Hal (PRO) argues for an action; the opponent raises the value-conflict objections. The
   φ₁-proof structure captures exactly how a moral agent defends a practical conclusion
   against challenge. The proof is not just a computational artefact — it is a model of
   the deliberative process itself.

3. **Natural and significant article contribution.** The current system computes *what* is
   acceptable. Adding credQA shows *why* a specific argument is acceptable, in the form of a
   structured dialogue readable as a practical moral argument. Combining AATS + VAF +
   dialectical justification in a single Prolog system, grounded in a concrete ethical
   dilemma, would be a strong contribution.

### What is needed for implementation

The `accepted_arg.pl` template uses a flat interface: `argument(a)` (unary) and
`attacks(k,b)` (binary with atom arguments). Our system uses structured terms:
`arg([buyH,doNH], lifeH)` as arguments and `attacks(arg(...), arg(...))`. The algorithm
itself does not need to change. A small adapter module (e.g. `credulous.pl`) would:

- expose `credQA(+Arg, -Proof)` using our `arg/2` and `attacks/2` directly (since
  `attacks/2` already has the right arity and our arg terms can be passed through as-is)
- extend to `vaf_credQA(+Arg, +Audience, -Proof)` using `defeats/3` in place of `attacks/2`
  so that the dialogue respects the audience's value ordering

The proof term `(Seq, Pro)` returned by `credQA` should also be exposed via the HTTP API
(e.g. `GET /credulous/:arg` and `GET /vaf/:audience/credulous/:arg`) so the frontend can
display the dialogue visually.

Implementation: `v1.0/credulous.pl` — additive module, nothing existing changed.
Exports: `credQA/2`, `vaf_credQA/3`, `cred_qa/3` (generic), `sceptically_accepted/1`,
`vaf_sceptically_accepted/2`. The defeat predicate is abstracted so one algorithm
handles both Dung and VAF. Proof = (Seq, Pro): Seq is the chronological dialogue
(list of pro/opp moves), Pro is PRO's final admissible set.
New API endpoints: `GET /credulous`, `GET /credulous/sceptical`,
`GET /credulous/vaf/:audience`. New dbg.pl sections 16–18 demonstrate all three.

---

## ~~20. Counterfactual extension (AS3 scheme)~~ — DONE

Implemented in `v1.0/counterfactual.pl` (new module) and `v1.0/args.pl` (AS3 clause).

Exports: `holds/2`, `cf_joint_seq/2`, `counterfactual_holds/3`, `causal_responsible/4`.
New API endpoints: `GET /counterfactual`, `GET /counterfactual/causal/:prop`.
New dbg.pl sections 19–21.

Results: 10 AS3 arguments for `lifeH`; 0 for `lifeC` (theoretically meaningful — Carla
retains `takC` agency regardless of Hal's action); 0 for `freedomH`/`freedomC`
(framing-problem gap, unfixable without changing the action model).

Full findings and theoretical discussion: `docs/notes/counterfactual_extension.md`.

---

## 19. Argument graph visualisation — OPEN

Comparative study of layout and embedding methods for the 35-node attack graph.
Methods to implement and compare: Fruchterman-Reingold, Kamada-Kawai, spectral layout,
UMAP on feature matrix, UMAP on graph embedding (Node2Vec / adjacency eigenvectors),
UMAP on extension-membership matrix. Select the most informative representation for
the article. Full specification: `docs/specs/argument_graph_visualisation.md`.
