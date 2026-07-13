# Note: Including AS2 Arguments in Dung Extensions and VAF

*Documents the problem, solution, and theoretical significance of item 17.*

---

## The problem

The original implementation restricted `arg/2` — the predicate used by `attacks/2`,
`extensions.pl`, and `vaf.pl` — to AS1 arguments only:

```prolog
arg(Acts, Val) :- argument(hal, Acts, Val, as1).
```

AS2 arguments were generated correctly by `argument/4` and exposed via the `/args` API
endpoint, but they did not participate in the Dung extension computation or the attack
relation. The reason was computational: the original extension algorithm used brute-force
powerset enumeration (O(2^n)). With 9 AS1 arguments this was barely tractable; AS2 adds
roughly 26 more arguments, making the powerset approach entirely unusable.

The consequence was that AS2 arguments were display-only artefacts. The system could
describe them in plain English but could not reason about them: they formed no part of
the attack graph, influenced no extensions, and produced no preferred or stable sets.
This meant the system's conclusions were based solely on positive, forward-looking
arguments (AS1) and ignored the protective, abstention-based arguments (AS2) entirely.

---

## The prerequisite: labelling algorithm (item 16)

Closing this item required item 16 to be done first. The brute-force powerset was replaced
with a Caminada (2006) complete-labelling search (O(2^k) where k is the number of genuinely
ambiguous arguments after constraint propagation). This made the extension computation
robust enough to handle a much larger argument set without an exponential blowup.

---

## The solution

Once the labelling algorithm was in place, enabling AS2 was a single-line change in
`v1.0/args.pl`:

```prolog
% before
arg(Acts, Val) :- argument(hal, Acts, Val, as1).

% after
arg(Acts, Val) :- argument(hal, Acts, Val, _).
```

No changes were needed in `attacks/2`, `extensions.pl`, or `vaf.pl`. The attack relation
is scheme-agnostic (two arguments attack each other if and only if they advocate different
action sequences, regardless of whether they are AS1 or AS2).

---

## Results

| Metric                  | AS1 only | AS1 + AS2 |
|-------------------------|----------|-----------|
| Arguments               | 9        | 35        |
| Attack pairs            | 66       | 1124      |
| Dung preferred exts     | 6        | 13        |
| VAF `life_first`        | 3        | 10        |
| VAF `altruistic`        | 3        | 10        |
| VAF `selfish`           | 3        | 10        |
| VAF `freedom_first`     | 3        | 6         |

Performance remained acceptable: the labelling algorithm returned all results in under
two seconds on a standard machine.

---

## Theoretical significance for the article

### 1. AS2 arguments are not redundant

The jump from 6 to 13 Dung preferred extensions shows that AS2 arguments genuinely
change the structure of the extension lattice. They are not just paraphrases of AS1
arguments — they introduce new conflict-free combinations and new attack relations that
did not exist in the AS1-only graph.

### 2. The AS1/AS2 asymmetry for `freedomH`

The most significant finding is in the `freedom_first` audience result: 6 extensions
rather than 10. Under this audience (freedomH > freedomC > lifeH > lifeC), the AS2
`freedomH` arguments now participate in the defeat relation and survive in some preferred
extensions. This is the first time `freedomH` appears in any extension.

However, `freedom_first` gives fewer extensions than the other audiences precisely
because the AS2 `freedomH` arguments only defend a *negative* position (abstain from
spending money) — they do not provide a positive alternative in the way AS1 arguments
do. There are no AS1 `freedomH` arguments (no canonical action earns money), so the
`freedomH` arguments cannot combine with others to form the same variety of compatible
pairs that lifeC/freedomC arguments can.

This connects directly to the framing problem argument in `docs/notes/framing_problem.md`:
including AS2 partially closes the `freedomH` gap — the value becomes visible — but only
in its protective, defensive form. The asymmetry between AS1-capable values and AS2-only
values is a structural feature of the domain, not a defect of the implementation.

### 3. AS1 and AS2 capture categorically different moral stances

The extension results suggest a distinction worth making in the article:

- **AS1 arguments** are *forward-looking*: they justify action by pointing to a good that
  will be realised. They correspond roughly to positive duties and consequentialist reasoning
  ("do X because it will bring about G").
- **AS2 arguments** are *backward-looking* or *protective*: they justify abstention by
  pointing to a harm that will be avoided. They correspond roughly to negative duties and
  deontological side-constraints ("don't do X because it would violate V").

In the insulin domain, some values are only actionable under one scheme:
- `lifeH`, `lifeC`, `freedomC` — representable under AS1 (actions exist that promote them)
- `freedomH` — representable only under AS2 in the canonical action set (no action earns
  money; some actions lose it)

This is a concrete formal demonstration of the fact that the structure of available actions
shapes which moral stances can be articulated at all — a version of the framing problem
internal to the argument scheme machinery.

### 4. Implications for the credulous/sceptical acceptance query (item 18)

With 35 arguments and 1124 attack pairs, querying by enumerating all preferred extensions
becomes noticeably more expensive. This strengthens the motivation for item 18: the
Cayrol-Doutre-Mengin `credQA` algorithm answers acceptance queries directly, without
computing the full extension set, and returns a dialectical proof as justification. As the
argument set grows, query-based reasoning becomes increasingly preferable to enumeration.

---

## Relevant references

- Atkinson, K., & Bench-Capon, T. (2006). Addressing moral problems through practical
  reasoning. *Deontic Logic and Artificial Normative Systems*, pp. 8–23. Springer.
  [Original AS1/AS2 scheme definitions.]
- Caminada, M. (2006). On the issue of reinstatement in argumentation. *JELIA 2006*,
  LNCS 4160, pp. 111–123. Springer. [Labelling algorithm that made AS2 inclusion feasible.]
- Cayrol, C., Doutre, S., & Mengin, J. (2003). On decision problems related to the
  preferred semantics for argumentation frameworks. *Journal of Logic and Computation*,
  13(3), 377–402. [Query-based alternative to full extension enumeration — item 18.]
