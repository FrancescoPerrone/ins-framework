# Normative Completion and Closure in the INS Framework

This note applies the model-parametric theory of *grounded normative completion*
(Perrone 2026, unpublished) to two versions of the INS system and asks a single
question of each:

> Are the system's endorsed normative contents **closed under normative
> inference** — that is, do the contents obtained by elaborating the endorsed
> ones remain grounded?

The two versions examined are:

- the **non-counterfactual** version — the Atkinson & Bench-Capon forward
  fragment: argument schemes **AS1**/**AS2** (`args.pl`), Dung extensions
  (`extensions.pl`), and the value-based argumentation layer (`vaf.pl`);
- the **complete** version — the above *plus* the counterfactual scheme **AS3**
  (`args.pl`), the intervention semantics (`counterfactual.pl`), and the
  audience-weighted possible-world layer (`possible_worlds.pl`).

The analysis is deductive: no code is executed. Every verdict is
*model-relative* in the sense of Perrone (2026, Caution 1.1) — it holds relative
to the grounding environment INS fixes, and is not a claim of moral correctness
independent of that environment.

---

## 1. The property being checked

Perrone (2026) models any system that "receives a context and returns one or
more endorsed continuations" as a **completion system**, and evaluates it
against an explicit **grounding environment**

$$\mathfrak{G} = \langle \mathcal{C},\ \mathcal{Z},\ \mathrm{Rel},\ \mathrm{Grd},\ \mathrm{Cn}\rangle,$$

where $\mathcal{C}$ is a set of contexts, $\mathcal{Z}$ a set of normatively
typed contents, $\mathrm{Rel}$ a relevance relation, $\mathrm{Grd}$ a
context-indexed grounding predicate, and $\mathrm{Cn}$ a closure operation on
contents (extensive, monotone, idempotent). The **grounded normative domain** at
a context $c$ is

$$\mathsf{N}_\mathfrak{G}(c) = \{\, z : \mathrm{Rel}(c,z) \wedge \mathrm{Grd}(c,z)\,\}.$$

A normatively interpreted completion system $\mathcal{K}$ endorses, at each
context, a set of contents $X_\mathcal{K}(c)$ (the denotations of its outputs).
Three verification conditions matter here (Perrone 2026, §2.3):

| Condition | Definition | Reading |
|---|---|---|
| **Ground-soundness** $\mathsf{GS}$ | $X_\mathcal{K}(c) \subseteq \mathsf{N}_\mathfrak{G}(c)$ | every endorsed content is relevant and grounded |
| **Ground-closure** $\mathsf{GC}$ | $\mathrm{Cn}(c, X_\mathcal{K}(c)) \subseteq \mathsf{N}_\mathfrak{G}(c)$ | the *consequences* of endorsed contents stay grounded |
| **Internal ground-closure** $\mathsf{IC}(\mathfrak{G})$ | $\mathrm{Cn}(c, \mathsf{N}_\mathfrak{G}(c)) \subseteq \mathsf{N}_\mathfrak{G}(c)$ | the grounded domain is stable under its own closure |

"Closed under normative inference" is precisely **ground-closure**. Two results
from the paper do most of the work below:

- **Ground-closure implies ground-soundness** (Perrone 2026, Prop. 2.15), by
  extensivity of $\mathrm{Cn}$.
- **Soundness lifts to closure** (Perrone 2026, Thm. 2.19): if
  $\mathsf{IC}(\mathfrak{G})$ holds, then *every* ground-sound completion system
  over $\mathfrak{G}$ is ground-closed. So the central question reduces to
  (i) is INS ground-sound, and (ii) is its grounding environment internally
  closed under the chosen $\mathrm{Cn}$?

---

## 2. INS as a grounding environment and a completion system

INS instantiates both roles of the framework at once: it *is* a finite
value-based action model of the kind the paper uses as its verification example
(Perrone 2026, §5), and it is also a completion system that must be checked
against that model.

**Grounding environment.** Contexts $\mathcal{C}$ are the admissible initial
states $q \in I$ of the insulin scenario (the six-attribute state vectors).
Contents $\mathcal{Z}$ are well-typed scheme instances $(S, q, J, v)$ with
$S \in \{\mathrm{AS1}, \mathrm{AS2}, \mathrm{AS3}\}$, $J$ an executable action
sequence, and $v$ a value. Relevance $\mathrm{Rel}(c,z)$ is well-typedness of the
instance against $c$. The grounding predicate $\mathrm{Grd}$ is given by the
paper's §5.3 grounding clauses, which INS implements directly:

| Scheme | Paper's grounding clause (Perrone 2026, Def. 5.9) | INS realisation (`args.pl`) |
|---|---|---|
| AS1 | $\mathrm{better}(q,w,v)$ | `better(hal, Init, Next, Val)` |
| AS2 | $\neg\mathrm{worse}(q,w,v)$ ∧ ∃ alt. history $J'$ with $\mathrm{worse}(q,w',v)$ | `\+ worse(...)` ∧ alternative `trans` with `worse(...)` |
| AS3 | $\neg\mathrm{worse}(q,w,v)$ ∧ $\mathrm{worse}(q,w_{\mathrm{cf}},v)$ | `\+ worse(...)` ∧ `cf_joint_seq` intervention with `worse(...)` |

The intervention $\mathrm{cf}_h$ of Perrone (2026, Def. 5.4) — "replace the
distinguished agent's component of every joint action by inaction, holding all
others fixed" — is exactly `cf_joint_seq/2`, and the counterfactual transition
$\mathrm{CFTrans}$ of §7 is exactly `counterfactual_holds/3`.

**Completion system.** The system $\mathcal{K}$ is INS's argument constructor:
$\mathrm{End}(c)$ is the set of arguments produced by `argument/4` at $c$, and
the denotation map sends an argument term to its scheme-instance content
$(S,q,J,v)$.

**Ground-soundness by construction.** This is the pivotal structural fact. INS
does not *generate then filter* arguments; it derives them by `setof` over
exactly the grounding clause. For AS1, `argument(hal, Acts, Val, as1)` succeeds
*iff* `better(hal, Init, Next, Val)` holds — i.e. iff $\mathrm{Grd}(\mathrm{AS1},
q,J,v)$. The same holds for AS2 and AS3. Therefore

$$X_\mathcal{K}(c) = \{\, z \in \mathsf{N}_\mathfrak{G}(c) : z \text{ is an instance of an implemented scheme}\,\} \subseteq \mathsf{N}_\mathfrak{G}(c).$$

So **both versions are ground-sound for the schemes they implement**, and are in
fact *normatively complete* for those schemes (the `setof` enumerates every
grounded instance, giving the exact-coverage variant of Perrone 2026,
Def. 2.11). By Prop. 2.15 the interesting question is not soundness but whether
soundness survives the closure operation.

---

## 3. The two versions, precisely

**Non-counterfactual INS.** Content type: AS1/AS2 only. These are *forward*
schemes — evaluable over the base schema
$\Sigma = \{\mathsf{Init}, \mathsf{Trans}, \mathsf{Better}, \mathsf{Worse}\}$, and
first-order definable over it (Perrone 2026, Prop. 7.2). The Dung layer
(`extensions.pl`) and VAF layer (`vaf.pl`) build an attack/defeat graph over
these arguments and compute conflict-free, admissible, preferred, and grounded
extensions relative to an audience (a strict value ordering).

**Complete INS.** Content type: AS1/AS2/AS3. AS3 is a *difference-making*
content: its grounding is not determined by $\Sigma$ (Perrone 2026, Prop. 7.4)
and requires the intervention extension
$\Sigma^{+} = \Sigma \cup \{\mathsf{CFTrans}\}$. INS supplies exactly this
extra structure through `counterfactual.pl` (the intervention) and
`possible_worlds.pl` (audience-weighted closeness among alternatives).

**The decisive architectural fact.** AS3 arguments are deliberately kept out of
`arg/2`, and therefore out of the Dung/VAF closure. The code is explicit:

> "AS3 argument terms are … NOT included in `arg/2`. The Dung/VAF extension layer
> (`extensions.pl`, `vaf.pl`) is unaffected. … Integration into the extension
> semantics is left as future work." — `args.pl`

In the paper's vocabulary, INS keeps the counterfactual content type *modular*:
the base-schema fragment is closed under argumentation inference, while the
difference-making fragment is materialised but not fed back into that inference.

---

## 4. Closure under the three operators

The closure operator $\mathrm{Cn}$ is a *parameter* of the framework, so "closed
under normative inference" has three natural readings for INS. We report all
three.

| | Identity $\mathrm{Cn}(c,X)=X$ | Scheme-calculus $\mathrm{Cn}$ (Perrone 2026, §6) | Argumentation acceptance (Dung/VAF) |
|---|---|---|---|
| **Non-CF (AS1/AS2)** | $\mathsf{GC}$ ✓ (≡ $\mathsf{GS}$) | $\mathsf{GC}$ ✓ — forward calculus, $\mathsf{IC}$ unconditional | $\mathsf{GC}$ ✓ — acceptance stays in the forward grounded domain |
| **Complete (+AS3)** | $\mathsf{GC}$ ✓ (≡ $\mathsf{GS}$) | $\mathsf{GC}$ ✓ **iff** `CFTrans` adequate — INS satisfies this | $\mathsf{GC}$ ✓ — AS3 modular ⇒ no closure leakage |

**(a) Identity closure.** With $\mathrm{Cn}(c,X)=X$, ground-closure coincides
with ground-soundness. Since both versions are ground-sound by construction (§2),
both are trivially ground-closed. This is the minimal reading: no elaboration is
checked.

**(b) Scheme-calculus closure.** Read $\mathrm{Cn}$ as the closure generated by
the finite scheme calculus $\mathfrak{C}_A$ (Perrone 2026, §6): the derivable
scheme instances. The calculus is sound and complete for the model
(Perrone 2026, Thm. 6.2), so *derivable = grounded*, whence the grounded domain
is stable under $\mathrm{Cn}$ — i.e. $\mathsf{IC}(\mathfrak{G})$ holds — and by
Thm. 2.19 ground-soundness lifts to ground-closure.

- *Non-CF:* the calculus contains only the AS1/AS2 rule families, so
  $\mathrm{Cn}$ generates only forward contents and $\mathsf{IC}$ holds
  *unconditionally*.
- *Complete:* the calculus additionally contains the AS3 rule family, whose
  applicability requires the intervention witness `CFTrans`. $\mathsf{IC}$ holds
  **iff** the environment is *counterfactually adequate* for the AS3 contents it
  is asked to certify (Perrone 2026, Def. 4.10) — i.e. iff the intervention
  outcome is materialised. INS materialises it (`counterfactual_holds/3`), so
  $\mathsf{IC}$, and hence $\mathsf{GC}$, holds. Were the intervention *not*
  materialised — a verifier restricted to the realised trace — AS3 grounding
  would be undetermined (Perrone 2026, Prop. 7.4) and closure would fail. This is
  the paper's reduced-verifier gap (§8) made concrete.

**(c) Argumentation-acceptance closure.** Read $\mathrm{Cn}(c,X)$ as the
practical conclusions licensed by the arguments in $X$ that are *accepted* in the
Dung/VAF extension for the audience — the action-directing contents "history $J$
is justified for value $v$".

- *Non-CF:* the attack/defeat graph ranges over AS1/AS2 arguments only, each of
  which is a grounded forward instance. An accepted argument is a *subset*
  selection of grounded contents, and the recommendation it licenses is
  supported by a grounded promotion/protection. Hence
  $\mathrm{Cn}(c, X_\mathcal{K}(c)) \subseteq \mathsf{N}_\mathfrak{G}(c)$: the
  version is ground-closed under acceptance.
- *Complete:* because AS3 is excluded from `arg/2`, the acceptance closure never
  elaborates AS3 contents. The endorsed AS3 contents remain in $X_\mathcal{K}(c)$
  and are grounded (adequacy, above); the closure operation simply does not
  propagate them. There is therefore *no closure leakage*, and $\mathsf{GC}$
  holds. The modular boundary is doing real work: it is exactly what prevents a
  counterfactual content whose ground the acceptance layer cannot see from being
  promoted into an acceptance-generated recommendation.

---

## 5. Results

**Proposition A (non-counterfactual INS).**
The non-counterfactual version is ground-sound and ground-closed for the forward
fragment under all three closure operators. However:

1. It has a **completeness gap** for difference-making contents. Relative to the
   richer environment $\Sigma^{+}$ whose grounded domain contains AS3
   responsibility/protection contents, the non-CF version is *silent*: it endorses
   no such content because it cannot state one. It is normatively complete only
   for the forward fragment, not for the enriched grounded domain (Perrone 2026,
   §8).
2. It becomes ground-**unsound** under a counterfactual *over-reading* of its
   outputs. AS2 certifies "$J$ avoids a worse *available* alternative for $v$";
   this is **not** the AS3 content "$J$'s agent counterfactually *protects* $v$"
   (Perrone 2026, Prop. 10.4). If a denotation map reads an AS2 output as a
   protection/responsibility claim, the endorsed content leaves the grounded
   domain, since forward data does not determine the counterfactual
   (Prop. 7.4). The version is safe only under a *forward* denotation.

*Why closure holds here is important:* the non-CF version is closed not because
it has ruled out every unsafe consequence, but because it is **expressively
restricted** — it cannot form difference-making contents, so it cannot endorse
ungrounded ones. Closure by restriction buys safety at the cost of coverage.

**Proposition B (complete INS).**
The complete version is ground-sound and ground-closed *including* the AS3
fragment, under all three closure operators, **conditional on counterfactual
adequacy** — the materialisation of the intervention outcome `CFTrans`, which the
implementation supplies. The modular exclusion of AS3 from the acceptance closure
is what keeps the acceptance reading closed; and the analysis makes explicit the
condition any *future* integration of AS3 into the VAF would have to meet: the
integrated closure is ground-closed only while adequacy is preserved for every
AS3 content the extension can reach. The complete version therefore closes the
non-CF version's completeness gap (it can ground responsibility/protection
contents) while retaining closure, precisely because it pays the modelling cost
the paper identifies as mandatory for difference-making contents.

---

## 6. Discussion

**Doing versus allowing.** The forward schemes evaluate histories that may
*contain* inaction, but they cannot distinguish an agent's *causing* an outcome
from its merely *allowing* the outcome to occur (Perrone 2026, §12). AS3 adds the
missing test by asking what would have happened under $\mathrm{cf}_h$ — the
distinguished agent's contribution replaced by inaction, others held fixed. This
is the formal locus of the doing/allowing distinction in INS, and the reason the
complete version can express responsibility where the non-CF version cannot.

**Audiences are a grounding parameter, not decoration.** The VAF audiences of
`vaf.pl` are exactly the audience parameter of Perrone (2026, §12): once
counterfactuals range over more than a single closest alternative, closeness must
be adjudicated, and in a value-based setting closeness itself depends on a value
ordering. `possible_worlds.pl`'s audience-weighted distance instantiates
Def. 12.6, and the grounding verdict for a possible-world counterfactual can vary
with the audience even when the transition structure is fixed (Prop. 12.7). This
is parameterisation, not relativism: once an audience is fixed the verdict is
determinate; *which* audience is legitimate is a substantive question outside the
calculus (Caution 12.8).

**The `freedomH` gap.** No AS3 argument for `freedomH` can be constructed,
because `doNH` never modifies Hal's money attribute, so the intervention cannot
demote `freedomH`. This is a *genuine* completeness gap and it is *correct*: it
reflects a structural limit of the action model, not a defect of the
argumentation layer. In the paper's terms, the environment is simply not adequate
for that content, and "unsupported is not false" (Caution 4.11).

---

## 7. What the results mean beyond INS

INS is a deliberately situated model: two agents, six binary attributes, a single
insulin dilemma. Its closure verdicts are model-relative and carry no moral
authority on their own. What *does* generalise is a method and four transferable
lessons — the reason the situated example is worth stating at all.

1. **Ground-soundness is cheap; grounded *interpretation* is not.** Any system
   that derives its outputs *from* the grounding clauses — rather than emitting
   fluent candidates and filtering them afterwards — is ground-sound by
   construction, as INS is. The risk in real systems is therefore rarely that the
   construction is unsound; it is that a fluent output is *read* as a stronger
   content than the model actually grounds. The dangerous step is the denotation
   map, not the generator.

2. **The forward/counterfactual split is the general fault line.** A system that
   emits only forward-support contents ("this action promotes the objective") can
   be safely closed while being *blind* to prevention, omission, and
   responsibility. The moment a system asserts a difference-making claim — "this
   action prevented harm", "the intervention protected the value", "unless I act,
   the value will be lost" — it needs an explicit intervention structure (a
   `CFTrans`-equivalent), or the claim is ungrounded *regardless of how compelling
   it reads*. This is exactly the agentic-misalignment pattern that motivates the
   paper (Perrone 2026, §9, §11): an agent's "unless I prevent replacement, the
   objective is lost" is ungrounded when a replacement would have preserved the
   objective, because the counterfactual outcome is not what the completion
   assumes. Chain-of-thought that *narrates* such a rationale is not evidence that
   its content is grounded (Chen et al. 2025).

3. **Modularity is a safety property.** INS stays closed under argumentation
   inference in part because it does *not* let the counterfactual layer bleed into
   the acceptance layer before that layer can see the intervention data.
   Generalised: when adding a more demanding content type (causal, counterfactual,
   responsibility-laden) to a system, keeping it modular prevents its potentially
   ungrounded consequences from contaminating everything downstream. Integration
   is safe only *after* the adequacy condition — the intervention or
   difference-making data — is guaranteed for every content the integrated closure
   can reach.

4. **Situatedness is the point, not a limitation.** Because INS is small,
   decidable, and fully inspectable, one can *prove* what a larger, less
   inspectable system (an LLM agent, a decision-support pipeline, a
   normatively-loaded database view) would have to satisfy to make the same
   closure guarantees. The transferable deliverable is a discipline, not a moral
   verdict: fix the environment; classify each emitted normative content as
   forward or difference-making; ensure the difference-making ones carry
   materialised intervention support; and never let acceptance, view-materialisation,
   or consequence machinery silently promote a content the environment does not
   ground.

The practical upshot is auditable. For any deployed system that issues
normatively typed outputs, the same protocol applies (Perrone 2026, §13): specify
the environment, interpret outputs as contents, then check coverage, soundness,
sensitivity, and closure — treating every prevention/responsibility/protection
claim as a content that must be earned with intervention structure, not asserted
with fluency. INS is one worked instance of that protocol carried out to a
definite verdict; the value of the worked instance is that it shows the protocol
terminating.

---

## 8. Model-relativity caution

Every verdict above is conditional on the grounding environment INS fixes — its
state space, transition function, value realisation, intervention semantics, and
audiences. The framework "does not solve the problem of choosing a privileged
moral model" (Perrone 2026, §14); it determines, once a model is specified,
whether a system's normative completions are complete, sound, and closed relative
to that model. The results here should be read in that spirit: they establish
that INS's two versions are ground-closed *relative to their own environment*,
and they make explicit the adequacy condition on which the complete version's
closure depends.

---

## References

Perrone, F. (2026). *Ground-Sound Normative Completion: A Model-Parametric
Operator for Normative Closure with Many-Dimensional Sensitivity.* Unpublished
manuscript.

Atkinson, K., & Bench-Capon, T. (2008). Addressing moral problems through
practical reasoning. *Journal of Applied Logic*, 6(2), 135–151.

Bench-Capon, T. J. M. (2003). Persuasion in practical argument using value-based
argumentation frameworks. *Journal of Logic and Computation*, 13(3), 429–448.

Chen, Y., et al. (2025). Reasoning models don't always say what they think.
*arXiv:2505.05410*.

Dung, P. M. (1995). On the acceptability of arguments and its fundamental role in
nonmonotonic reasoning, logic programming and n-person games. *Artificial
Intelligence*, 77(2), 321–357.

Halpern, J. Y., & Pearl, J. (2005). Causes and explanations: A structural-model
approach. Part I: Causes. *The British Journal for the Philosophy of Science*,
56(4), 843–887.

Horty, J. F. (2001). *Agency and Deontic Logic.* Oxford University Press.

Lewis, D. (1973). *Counterfactuals.* Harvard University Press.

Lynch, A., et al. (2025). Agentic misalignment: how LLMs could be insider
threats. *arXiv:2510.05179*.

Stalnaker, R. (1968). A theory of conditionals. In N. Rescher (Ed.), *Studies in
Logical Theory* (pp. 98–112). Blackwell.
