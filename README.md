<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/readme-banner-1200x300.png">
    <img src="assets/readme-banner-1200x300-light.png" alt="INS-framework — Moral reasoning in Prolog: action theory &amp; value-based argumentation" width="100%">
  </picture>
</p>

# INS — Moral Reasoning in Prolog

> *Can the structure of practical moral reasoning be made formally precise?*
> *What can an action-theoretic system tell us — and where does it reach its boundary?*
> *What does counterfactual causation add to what value-based argumentation leaves out?*

---

[The Domain](#the-domain) · [Formal Framework](#formal-framework) · [Prerequisites](#prerequisites) · [How to Run](#how-to-run) · [File Structure](#file-structure) · [Current Output](#current-output) · [License](#license) · [References](#references)

---

This project is a SWI-Prolog implementation of a moral reasoning system grounded in
the practical argumentation framework of Atkinson & Bench-Capon (2006) and the
Value-Based Argumentation Framework (VAF) of Bench-Capon (2003).  It grew out of
work originally started in 2013 in collaboration with
[Marek Sergot](http://www.doc.ic.ac.uk/~mjs/) (Imperial College London), whose work
on normative systems, deontic logic, and action formalisms underpins the formal
structure used here.

The system has since been completed and extended with full
Dung (1995) argumentation semantics, a VAF layer with four named audiences, joint
action reasoning from Carla's perspective, dialectical proof via the φ₁-proof theory
of Cayrol, Doutre & Mengin (2003), a counterfactual layer implementing a Lewis-style
AS3 argument scheme, full possible world semantics with audience-relative value-weighted
similarity (Lewis 1973; Stalnaker 1968), and an HTTP API with an HTML frontend.

---

## The Domain

The scenario models an ethical dilemma: agent **Hal** must decide whether and how
to help **Carla**, a diabetic who needs insulin to survive.  The tension between
Hal's autonomy and Carla's need for help is expressed as a conflict of values:
life vs. freedom, self vs. other.

State is a 6-tuple `[ih, mh, ah, ic, mc, ac]` where each attribute is binary
(1 = has it, 0 = does not):

| Position | Attribute | Meaning           |
|----------|-----------|-------------------|
| 1        | `ih`      | Hal has insulin   |
| 2        | `mh`      | Hal has money     |
| 3        | `ah`      | Hal is alive      |
| 4        | `ic`      | Carla has insulin |
| 5        | `mc`      | Carla has money   |
| 6        | `ac`      | Carla is alive    |

**Hal's individual actions**: `buyH`, `takH`, `comH`, `losH`, `doNH`  
**Joint actions (Hal × Carla)**: `buyH-comC`, `comH-takC`, `doNH-losC`, etc.  
**Values**: `lifeH`, `lifeC`, `freedomH`, `freedomC`  
**Hal** subscribes to all four values; **Carla** subscribes to `lifeC` and `freedomC`.

---

## Formal Framework

### Action-Based Alternating Transition System (AATS)

An AATS is an (n + 7)-tuple:

```
S = ⟨Q, q₀, Ag, Ac₁, …, Acₙ, ρ, τ, φ, π⟩
```

where:

- **Q** is a finite, non-empty set of states
- **q₀ ∈ Q** is the initial state
- **Ag = {1, …, n}** is a finite, non-empty set of agents
- **Acᵢ** is a finite, non-empty set of actions for each i ∈ Ag, with Acᵢ ∩ Acⱼ = ∅ for i ≠ j
- **ρ : AcAg → 2^Q** is an action precondition function — for each action α it defines the states from which α may be executed
- **τ : Q × JAg → Q** is a partial system transition function — `τ(q, j)` is the state resulting from performing joint action j from state q; **JAg** denotes the set of joint actions (tuples ⟨α₁, …, αₙ⟩, one αᵢ per agent), derived from the Acᵢ
- **φ** is a finite, non-empty set of atomic propositions
- **π : Q → 2^φ** is an interpretation function — `π(q)` is the set of propositions satisfied in state q

The AATS tuple is unchanged by the extensions in this project.  The VAF audience ordering, counterfactual layer, and possible world similarity metric are additional structures defined *over* the AATS — they use Q, τ, and π but do not modify the tuple itself.

### Argument Schemes

Three argument schemes are implemented:

- **AS1** — In circumstances R, perform A, leading to S, realising G, promoting value V.
  *(Atkinson & Bench-Capon 2006)*
- **AS2** — In circumstances R, perform A, to avoid S', which would demote value V.
  *(Atkinson & Bench-Capon 2006)*
- **AS3** — Perform joint action J rather than doing nothing, because had Hal done
  nothing at each step (holding Carla's actions fixed), value V would have been demoted.
  *(Counterfactual extension; Lewis 1973)*

AS1 and AS2 use individual action sequences for Hal and joint sequences for Carla.
AS3 uses joint action sequences for Hal, enabling the counterfactual substitution
(replace Hal's action with `doNH`, hold Carla fixed).

### Value-Based Argumentation Framework (VAF)

Following Bench-Capon (2003), a VAF extends Dung's abstract framework by associating
each argument with the value it promotes and evaluating defeat relative to an
*audience*: a strict preference ordering over values.

Argument **A defeats B** under audience P if:
1. A attacks B, and
2. B's value is **not** strictly preferred over A's value in P.

This breaks the symmetry of the attack relation: an argument promoting a
higher-ranked value cannot be defeated by one promoting a lower-ranked value.

Four named audiences are defined:

| Audience       | Value order                              | Ethical stance                     |
|----------------|------------------------------------------|------------------------------------|
| `life_first`   | lifeH > lifeC > freedomH > freedomC     | Life always outweighs freedom       |
| `selfish`      | lifeH > freedomH > lifeC > freedomC     | Hal's values above Carla's          |
| `altruistic`   | lifeC > lifeH > freedomC > freedomH     | Carla's wellbeing prioritised       |
| `freedom_first`| freedomH > freedomC > lifeH > lifeC     | Freedom values dominant             |

### Possible World Semantics

Following Lewis (1973) and Stalnaker (1968), `possible_worlds.pl` provides a full
possible world layer over the AATS state space.  The reachable states of the AATS
serve as the world space; world closeness is measured by a **value-weighted Hamming
distance** that uses the audience's preference ordering as moral weights:

```
d_P(w₁, w₂) = Σ_{a : w₁[a] ≠ w₂[a]} weight_P(a)
```

where `weight_P(a) = N − rank_P(value(a))` — differences in high-ranked attributes
(e.g. life) cost more than differences in low-ranked ones (e.g. money).

Two counterfactual conditionals are implemented:

- **Lewis □→** (`lewis_would/5`): `A □→_P C` is true iff C holds in **all** worlds
  minimising `d_P(actual, w)` among worlds satisfying A.  When ties exist, all must
  satisfy C — the conservative reading.
- **Stalnaker >** (`stalnaker_would/5`): selects a **unique** closest world (ties
  broken by canonical sort order) and requires C only there — the decisive reading.

Both conditionals are **audience-relative**: the closeness ordering depends on P, so
two agents with different value orderings can rationally disagree about the truth of
the same counterfactual.  This parallels audience-relative defeat in the VAF layer.

The fixed-antecedent counterfactual in `counterfactual.pl` (AS3) is a special case of
`lewis_would` in which the antecedent is satisfied by exactly one reachable world (the
`cf_joint_seq` substitution), making the distance calculation vacuous.

See `docs/notes/possible_worlds_semantics.md` for the full theoretical discussion,
including the grounding of AS3 within Lewis semantics, a canonical Lewis/Stalnaker
divergence example, and the opening toward quantum logic in a second paper.

---

## Prerequisites

```
SWI-Prolog >= 9.0
```

Install on Debian/Ubuntu:

```bash
sudo apt install swi-prolog
```

---

## How to Run

### Interactive reasoning

Load everything via the entry point:

```bash
cd v1.0
swipl -l dbg.pl
```

This loads all modules, starts the PlDoc documentation server, and runs 23 test
sections covering states, transitions, value evaluations, arguments (Hal and Carla,
AS1/AS2/AS3), attacks, grounded/preferred/stable Dung extensions, VAF extensions per
audience, dialectical proofs (credulous/sceptical acceptance), AS3 arguments, causal
responsibility, counterfactual holds spot-checks, value weights and distances per
audience, and Lewis/Stalnaker conditional comparisons.

To query interactively:

```prolog
?- arg(Acts, Val).                                       % Hal's AS1+AS2 arguments (35)
?- argument(hal, Acts, Val, as3).                        % Hal's AS3 arguments (10)
?- argument(carla, Acts, Val, Scheme).                   % Carla's arguments (joint actions)
?- attacks(A1, A2).                                      % attack pairs
?- preferred_extension(Ext).                             % Dung preferred extensions (13)
?- vaf_preferred_extension(Ext, altruistic).             % VAF for a specific audience
?- credQA(arg([buyH,doNH], lifeH), (Seq, Pro)).          % φ₁ dialectical proof
?- vaf_credQA(arg([comH,doNH], lifeC), altruistic, Proof). % VAF credulous acceptance
?- sceptically_accepted(Arg).                            % sceptical acceptance (none)
?- counterfactual_holds([0,1,1,1,1,1], [buyH-losC,doNH-buyC], alive(hal)). % AS3 check
?- causal_responsible(hal, [0,1,1,1,1,1], [buyH-losC,doNH-buyC], alive(hal)). % causal
?- value_weight(selfish, lifeH, W).                      % W = 4 (highest under selfish)
?- value_distance([1,1,1,0,1,1], [0,1,1,0,1,1], selfish, D).  % D = 4 (ih diff, weight 4)
?- lewis_would([0,1,1,1,1,1], [buyH-losC,doNH-buyC],          % Lewis □→ conditional
               hal_lacks_insulin, hal_dead, selfish).
?- stalnaker_would([0,0,1,1,1,1], [takH-comC,losH-doNC],      % Stalnaker > (may diverge
                   carla_lacks_insulin, hal_dead, life_first). %  from lewis_would above)
?- closest_worlds([0,1,1,1,1,1], [1,0,1,1,0,1],               % inspect closest worlds
                  hal_lacks_insulin, altruistic, Worlds).
```

### HTTP server with HTML frontend

```bash
swipl v1.0/webapp/server.pl
```

The server starts automatically on port 8000.
Visit **http://127.0.0.1:8000/** for the HTML frontend.

#### API endpoints

| Method | Path                              | Description                                           |
|--------|-----------------------------------|-------------------------------------------------------|
| GET    | `/`                               | HTML frontend                                         |
| GET    | `/args`                           | All arguments (Hal + Carla, all schemes), with `agent` and `scheme` fields |
| GET    | `/attacks`                        | All attack pairs between arguments                    |
| GET    | `/extensions`                     | Dung grounded, preferred, and stable extensions       |
| GET    | `/vaf`                            | List all named audiences and their value orderings    |
| GET    | `/vaf/:audience`                  | VAF preferred extensions for a named audience         |
| GET    | `/vaf/:audience/grounded`         | VAF grounded extension for a named audience           |
| GET    | `/credulous`                      | Credulously accepted arguments with φ₁ proofs         |
| GET    | `/credulous/sceptical`            | Sceptically accepted arguments                        |
| GET    | `/credulous/vaf/:audience`        | VAF credulous acceptance for a named audience         |
| GET    | `/counterfactual`                 | AS3 arguments with actual and counterfactual witness states |
| GET    | `/counterfactual/causal/:prop`    | States where Hal is causally responsible for `prop`   |

`prop` is one of: `alive_hal`, `alive_carla`, `has_insulin_hal`, `has_insulin_carla`,
`has_money_hal`, `has_money_carla`.  All endpoints return JSON.  Unknown audience names
or proposition tokens return HTTP 404.

---

## File Structure

```
v1.0/
├── dbg.pl              — entry point: loads all modules, runs 23 test sections
├── states.pl           — state representation: agents, attributes, domains
├── actions.pl          — individual action pre/post-conditions (perform/3)
├── jactions.pl         — joint action pre/post-conditions (performj/3)
├── trans.pl            — n-step transition functions: trans/4, transj/4
├── values.pl           — value system: sub/2, better/4, worse/4, eval/4
├── counterfactual.pl   — counterfactual semantics: holds/2, cf_joint_seq/2,
│                          counterfactual_holds/3, causal_responsible/4
├── possible_worlds.pl  — possible world semantics: value_distance/4, closest_worlds/5,
│                          lewis_would/5, stalnaker_would/5 (Lewis 1973, Stalnaker 1968)
├── args.pl             — argumentation: arg/2, argument/4 (AS1+AS2+AS3), attacks/2
├── extensions.pl       — Dung semantics: preferred, grounded, stable (Caminada labelling)
├── vaf.pl              — Value-Based Argumentation Framework (Bench-Capon 2003)
├── credulous.pl        — φ₁-proof / credulous & sceptical acceptance (CDM 2003)
├── webapp/
│   ├── server.pl       — HTTP server: JSON API + HTML frontend (auto-starts on port 8000)
│   ├── test.pl         — legacy server file (kept for reference)
│   └── index.html      — browser frontend (fetches from the JSON API)
docs/
├── notes/
│   ├── framing_problem.md              — freedomH gap as case study in the frame problem
│   ├── as2_in_extensions.md            — AS2 inclusion: problem, solution, results
│   ├── credulous_sceptical_acceptance.md — φ₁-proof: implementation and interpretation
│   ├── counterfactual_as3.md           — AS3 scheme: implementation, results, significance
│   ├── counterfactual_extension.md     — original design note (now implemented)
│   └── possible_worlds_semantics.md    — Lewis/Stalnaker semantics, audience-relative
│                                          closeness, relation to AS3, opening to quantum logic
└── specs/
    └── argument_graph_visualisation.md — layout study specification
```

---

## Current Output

### Argument schemes

| Scheme | Agent | Sequences used  | Arguments | Included in extensions |
|--------|-------|-----------------|:---------:|:---:|
| AS1    | Hal   | Individual      | 9         | yes |
| AS2    | Hal   | Individual      | 26        | yes |
| AS3    | Hal   | Joint           | 10        | no  |
| AS1    | Carla | Joint           | —         | no  |
| AS2    | Carla | Joint           | —         | no  |

`arg/2` (used by the extension and VAF layers) contains Hal's AS1 + AS2 arguments: **35
arguments** total.  AS3 arguments are accessible via `argument(hal, Acts, Val, as3)` but
are excluded from `arg/2` so the extension semantics is not affected.

**`freedomH` produces no AS1 or AS3 arguments** — a structural consequence of the
canonical action set.  No action promotes `mh`; `doNH` never modifies `mh`.  AS2
arguments for `freedomH` exist (defensive), but there is no forward-looking or
counterfactual case for financial freedom.  This is kept open as a deliberate case study
in the frame problem — see `docs/notes/framing_problem.md`.

### AS3 results and the `lifeC = 0` finding

| Value      | AS3 arguments | Meaning |
|------------|:---:|---|
| `lifeH`    | 10  | Hal's action was causally necessary for his own survival |
| `lifeC`    |  0  | Carla's survival does not depend counterfactually on Hal |
| `freedomH` |  0  | `doNH` never modifies `mh` — structural limit |
| `freedomC` |  0  | `doNH` never modifies `mc` — structural limit |

The `lifeC = 0` result is a domain finding: in every scenario where Carla lacks
insulin, she retains a `takC` action that gives her insulin regardless of Hal's choice
(Hal still has insulin when doing `doNH`).  Carla's survival is never counterfactually
dependent on Hal.  AS1/AS2 arguments for `lifeC` still exist; the counterfactual result
establishes that the moral pressure on Hal comes from positive obligation, not causal
responsibility.  See `docs/notes/counterfactual_as3.md` for the full analysis.

### Dung extensions (over 35 AS1+AS2 arguments)

- **Grounded**: `[]` — the attack graph is maximally contentious; no argument is unassailable
- **Preferred**: 13 extensions
- **Stable**: subset of preferred

### VAF preferred extensions by audience (AS1+AS2)

| Audience       | Value order                              | Preferred extensions |
|----------------|------------------------------------------|:--------------------:|
| `life_first`   | lifeH > lifeC > freedomH > freedomC     | 10                   |
| `selfish`      | lifeH > freedomH > lifeC > freedomC     | 10                   |
| `altruistic`   | lifeC > lifeH > freedomC > freedomH     | 10                   |
| `freedom_first`| freedomH > freedomC > lifeH > lifeC     | 6                    |

`freedom_first` gives 6 rather than 10: AS2 `freedomH` arguments participate defensively
under this audience, but without AS1 counterparts they cannot form the variety of
compatible pairs that lifeC/freedomC arguments can.

### Possible world semantics

Value weights under two audiences (N = 4 values each):

| Attribute | Value    | selfish | altruistic |
|-----------|----------|:-------:|:----------:|
| `ih`, `ah`| lifeH    | 4       | 3          |
| `ic`, `ac`| lifeC    | 2       | 4          |
| `mh`      | freedomH | 3       | 1          |
| `mc`      | freedomC | 1       | 2          |

The ordering reversal between `selfish` and `altruistic` means the same attribute
difference costs more or less depending on whose values are prioritised.

**Lewis/Stalnaker divergence** — canonical example from the AATS:

From `[0,0,1,1,1,1]`, sequence `[takH-comC, losH-doNC]`, antecedent `carla_lacks_insulin`,
consequent `hal_dead`:

| Audience       | Closest worlds | `lewis_would` | `stalnaker_would` |
|----------------|:--------------:|:-------------:|:-----------------:|
| `life_first`   | 3 (tie)        | false         | **true** [DIVERGE]|
| `altruistic`   | 2 (tie)        | false         | **true** [DIVERGE]|
| `selfish`      | 1              | false         | false             |
| `freedom_first`| 2 (tie)        | false         | **true** [DIVERGE]|

Under `selfish`, the high weight on `mh` (freedomH = 3) isolates a unique closest world;
Lewis and Stalnaker agree.  Under the other audiences, ties arise among worlds that
differ equally in Carla's life attributes — the first sorted world has Hal dead (ah = 0),
the others do not.  Stalnaker's selection function commits to that world; Lewis requires
the consequent to survive all tied worlds and therefore returns false.

### Credulous and sceptical acceptance

| Query                | Result  | Interpretation                                           |
|----------------------|:-------:|----------------------------------------------------------|
| Credulously accepted | 35 / 35 | Every argument appears in at least one preferred extension |
| Sceptically accepted |  0 / 35 | No argument is in every preferred extension              |

The framework is **maximally contentious**: every argument is defensible (nothing is
indefensible) and every argument is challengeable (nothing is unassailable).  This
is consistent with the empty grounded extension — a known result from Dung (1995).

Credulous acceptance is witnessed by a **φ₁-proof**: a structured dialogue in which a
PROponent defends the argument against all OPPonent challenges.  The proof structure
encodes the dialectical complexity of the argument.  See
`docs/notes/credulous_sceptical_acceptance.md` for the full interpretation.

---

## License

This software is released under the **INS Source-Available License, Version 1.0**.
See the `LICENSE` file for the full terms.

In brief: you may view and study the code for personal or educational purposes.  Any
other use — copying, modification, redistribution, or incorporation into other work —
requires prior written notification to the author at **francescoperr@gmail.com**.

---

## References

Atkinson, K., & Bench-Capon, T. (2006). Addressing moral problems through practical
reasoning. In *Deontic Logic and Artificial Normative Systems* (pp. 8–23).
Springer Berlin Heidelberg.

Bench-Capon, T. (2003). Persuasion in practical argument using value-based
argumentation frameworks. *Journal of Logic and Computation*, 13(3), 429–448.

Caminada, M. (2006). On the issue of reinstatement in argumentation. In *Logics in
Artificial Intelligence: JELIA 2006*, LNCS 4160, pp. 111–123. Springer.

Cayrol, C., Doutre, S., & Mengin, J. (2003). On decision problems related to the
preferred semantics for argumentation frameworks. *Journal of Logic and Computation*,
13(3), 377–402.

Dung, P. M. (1995). On the acceptability of arguments and its fundamental role in
nonmonotonic reasoning, logic programming and n-person games. *Artificial
Intelligence*, 77(2), 321–357.

Halpern, J. Y., & Pearl, J. (2005). Causes and explanations: A structural-model
approach. *The British Journal for the Philosophy of Science*, 56(4), 843–887.

Lewis, D. (1973). *Counterfactuals*. Harvard University Press.

Stalnaker, R. (1968). A theory of conditionals. In N. Rescher (Ed.),
*Studies in Logical Theory* (pp. 98–112). Blackwell.
