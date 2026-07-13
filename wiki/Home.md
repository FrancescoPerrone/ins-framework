# INS — Moral Reasoning in Prolog

**INS** is a SWI-Prolog implementation of a formal moral reasoning system grounded in
action theory and value-based argumentation.  It models an ethical dilemma — should
Hal help Carla, a diabetic who needs insulin? — and uses it as a platform to derive
formal results about causal responsibility, argument acceptability, and counterfactual
moral justification.

The system is not a simulation of moral reasoning; it *is* a formal moral reasoner.
Every result it produces follows by logical derivation from the definitions.

---

## Pages

| Page | What it covers |
|------|----------------|
| [[The Domain and AATS]] | The insulin scenario; state encoding; agents; the AATS formal structure |
| [[Argumentation Layers]] | Argument schemes AS1/AS2; Dung extensions; VAF audiences; φ₁-proof |
| [[Counterfactual and Causal Reasoning]] | AS3; Lewis intervention; the `lifeC = 0` finding |
| [[Possible World Semantics]] | Lewis □→ vs. Stalnaker >; audience-relative closeness; divergence |
| [[Getting Started]] | Prerequisites; how to run; interactive queries |
| [[API Reference]] | HTTP server; all JSON endpoints |
| [[Module Reference]] | Quick guide to every `.pl` file |

---

## Quick orientation

The project has two agents (**Hal** and **Carla**), four values (`lifeH`, `lifeC`,
`freedomH`, `freedomC`), and a state space of 64 binary configurations.  From three
morally relevant initial states, two-step action sequences are evaluated by five
formal layers:

```
possible_worlds.pl   ← Lewis/Stalnaker counterfactual conditionals (audience-relative)
counterfactual.pl    ← fixed-antecedent causal reasoning; AS3 substrate
credulous.pl         ← φ₁-proof; credulous and sceptical acceptance
vaf.pl               ← Value-Based Argumentation Framework (Bench-Capon 2003)
extensions.pl        ← Dung (1995) preferred/grounded/stable extensions
args.pl              ← argument construction: AS1, AS2, AS3
values.pl            ← value evaluation: better/4, worse/4, eval/4
trans.pl             ← transition function τ (n-step individual and joint)
actions.pl / jactions.pl  ← action preconditions and effects
states.pl            ← state space Q; propositional vocabulary φ/π
```

Each layer resolves a limitation of the one below it.  See [[Argumentation Layers]]
and [[Counterfactual and Causal Reasoning]] for the progression.

---

## Key results at a glance

| Layer | Result |
|-------|--------|
| Arguments (AS1+AS2) | 35 for Hal; attack graph is dense |
| Dung grounded extension | **empty** — the dilemma is maximally contentious |
| Dung preferred extensions | **13** |
| VAF preferred extensions | 10 (most audiences), 6 (`freedom_first`) |
| Credulous acceptance | **35/35** — every argument is defensible |
| Sceptical acceptance | **0/35** — no argument is unassailable |
| AS3 arguments (lifeH) | **10** — Hal's action was causally necessary for his survival |
| AS3 arguments (lifeC) | **0** — Carla's survival is never counterfactually dependent on Hal |
| Lewis/Stalnaker diverge | `life_first`, `altruistic`, `freedom_first` |
| Lewis/Stalnaker agree | `selfish` (unique closest world) |

---

## License

Source-available under the **INS License v1.0**.  You may view and study the code.
Any other use requires prior written notification to **francescoperr@gmail.com**.
See the `LICENSE` file for full terms.
