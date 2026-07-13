# Note: The Framing Problem as a Theoretical Limit of Logic-Based Moral Reasoning

*Draft note for article. Arose from the `freedomH` coverage gap (TODO item 15).*

---

## The observation

In the current implementation, `freedomH` (Hal's financial freedom) produces no AS1
arguments. The proximate cause is that `earnH` — the only action that would improve `mh`
(Hal has money) — was removed as non-canonical: it does not appear in the action set
defined by Atkinson & Bench-Capon (2006). `freedomH` does produce AS2 arguments ("avoid
actions that cost money") but cannot ground a positive AS1 argument of the form "perform
action A to promote your financial freedom".

The tempting fix is to add a new action: `chargeH` (charge Carla for the insulin),
`borrowH`, `earnH`. But this immediately raises a question with no principled answer
inside the formal system: *which actions should be in the model?* Hal could borrow money,
sell something, ask for help, call his bank, work overtime. Each addition would generate
new arguments, new attack pairs, new preferred extensions. The gap is not a defect — it
is a symptom of a structural limit of the approach.

---

## The core argument

The `freedomH` gap reveals that the outputs of the AATS + VAF system are not derived
solely from the moral situation — they are derived from the moral situation *as filtered
through three prior choices that lie entirely outside the formal system*:

1. **Which actions are included** — determines which arguments can be formed at all.
2. **Which values are recognised** — determines what the arguments are for.
3. **Which audiences are defined** — determines which arguments defeat which.

A value that has no corresponding action in the model is effectively invisible to the
reasoning system, regardless of its moral importance. In the insulin scenario, Hal's
financial freedom is a legitimate moral consideration, but the system cannot represent it
as actionable because the action set was defined without it in mind. The model's silence
on `freedomH` is not a moral conclusion — it is an artifact of the model's construction.

The AS2 case makes this sharper. AS2 arguments for `freedomH` say "don't spend your
money". But which actions count as threats to `mh` depends entirely on which actions are
in the model. Change the action set and the AS2 arguments change. The system's conclusions
are always relative to a designer's prior choices, not to the moral situation itself.

---

## The framing problem connection

This is the frame problem in its moral dimension. In classical AI, the frame problem asks:
when an agent acts, what can be assumed to stay the same? In an AATS, this is resolved by
the closed-world assumption embedded in the transition function τ: everything not
explicitly changed by an action is assumed unchanged. This closure is what makes the logic
tractable — and it is also what makes it unrealistic.

Real moral agents reason in open worlds. New actions, new consequences, new values can
always become relevant as a situation develops. The insulin scenario looks well-defined
only because we have artificially closed it: we chose six state variables, five individual
actions, four values, and declared the model complete. The `freedomH` gap exposes the
seam where that closure breaks.

McCarthy's original frame problem (McCarthy & Hayes 1969) was about the difficulty of
specifying what does *not* change. The moral analogue is the difficulty of specifying which
actions and values are *relevant* to a given situation. In normative systems, this has been
discussed as the problem of *action individuation* (how do we carve up behaviour into
discrete actions?) and of *value completeness* (how do we know we have identified all the
morally relevant values?). Neither has a formal solution — both require judgement that
precedes and grounds the formal model.

Sergot's work on normative systems (e.g. Sergot et al. 1986 on the British Nationality Act;
Sergot 2008 on the architecture of normative systems) is directly relevant here: a recurring
theme is the gap between what a formal normative system can represent and the full richness
of the normative situation it is meant to capture.

---

## What the approach does give you

This argument should not be read as dismissing the AATS + VAF approach. The framework is
rigorous, inspectable, and produces well-defined outputs relative to its inputs. What it
gives you is:

- A precise, formal representation of a *subset* of moral deliberation.
- The ability to show exactly how different value orderings (audiences) produce different
  conclusions — which is itself philosophically significant.
- A computational model of the *structure* of practical reasoning (AS1/AS2 schemes,
  attack, defence, extension) that is grounded in published theory.
- With the addition of dialectical proofs (item 18): transparent, step-by-step
  justifications for why a specific conclusion is reached.

The contribution of the implementation is to make the limits of logic-only approaches
visible and precise. This is a philosophical result in its own right.

---

## The AS1/AS2 asymmetry as a domain finding

Within the limits above, there is a smaller but still interesting finding specific to
the insulin domain: values are not uniform in the role they play relative to argument
schemes.

- **AS1-capable values** (lifeH, lifeC, freedomC): there exists at least one action in
  the model that *promotes* the value. Positive arguments can be formed.
- **AS2-only values** (freedomH in this domain): no action promotes the value, but some
  actions demote it. Only defensive/protective arguments can be formed.

This asymmetry suggests a distinction between *forward-looking* values (you act to
realise them) and *backward-looking* or *protective* values (you abstain to preserve
them). This maps loosely onto the deontological distinction between positive and negative
duties — a duty to promote a good vs. a duty to refrain from causing harm. The formal
system captures this distinction, but only relative to the action set provided.

---

## Thesis for the article

> The AATS + VAF approach provides a rigorous formal tool for modelling structured moral
> deliberation, but its outputs are necessarily relative to prior modelling choices —
> which actions, values, and audiences are included — that lie outside the formal system
> itself. A value without a corresponding action is invisible; an action not in the model
> does not exist. This is the frame problem in its moral dimension: not "what changes when
> I act?" but "what can I even conceive of doing, and which values does that conception
> exclude?" The Prolog implementation makes this limit concrete and inspectable, which is
> itself a contribution: not a claim that logic solves moral reasoning, but a precise
> demonstration of where and why it reaches its boundary.

---

## Relevant references

**Core formal framework**
- Atkinson, K., & Bench-Capon, T. (2006). Addressing moral problems through practical
  reasoning. *Deontic Logic and Artificial Normative Systems*, pp. 8–23. Springer.
- Bench-Capon, T. (2003). Persuasion in practical argument using value-based argumentation
  frameworks. *Journal of Logic and Computation*, 13(3), 429–448.
- Dung, P.M. (1995). On the acceptability of arguments and its fundamental role in
  nonmonotonic reasoning, logic programming and n-person games. *Artificial Intelligence*,
  77(2), 321–357.

**Dialectical proofs / decision problems**
- Cayrol, C., Doutre, S., & Mengin, J. (2003). On decision problems related to the
  preferred semantics for argumentation frameworks. *Journal of Logic and Computation*,
  13(3), 377–402.
- Caminada, M. (2006). On the issue of reinstatement in argumentation. In *Proceedings of
  JELIA 2006*, LNCS 4160, pp. 111–123. Springer.

**Frame problem and normative systems**
- McCarthy, J., & Hayes, P.J. (1969). Some philosophical problems from the standpoint of
  artificial intelligence. *Machine Intelligence*, 4, 463–502.
- Sergot, M.J., Sadri, F., Kowalski, R.A., Kriwaczek, F., Hammond, P., & Cory, H.T.
  (1986). The British Nationality Act as a logic program. *Communications of the ACM*,
  29(5), 370–386.
- Sergot, M. (2008). The architecture of normative systems. *Norms, Agents, and Dialogue*,
  LNCS 5247. Springer.

**Action individuation and moral relevance**
- Goldman, A.I. (1970). *A Theory of Human Action*. Prentice-Hall.
  [On the problem of carving behaviour into discrete actions.]
- Richardson, H.S. (1990). Specifying norms as a way to resolve concrete ethical problems.
  *Philosophy & Public Affairs*, 19(4), 279–310.
  [On the impossibility of a complete prior specification of moral rules.]

**AI and moral reasoning (broader context)**
- Bringsjord, S., & Govindarajulu, N.S. (2018). Artificial intelligence. In *Stanford
  Encyclopedia of Philosophy*. [Section on AI and ethics.]
- Wallach, W., & Allen, C. (2009). *Moral Machines: Teaching Robots Right from Wrong*.
  Oxford University Press.
