# Figure Captions and Discussion Notes
Draft material for the article's results section and figure captions.

Figures: `output/article/fig1_light.png`, `output/article/fig2_light.png`
(dark-background equivalents in the same folder, for preprint/slides).

---

## Figure 1 — Argument Space: Attribute Structure

### Suggested caption

**Figure 1.** Attribute structure of the INS argument space.
UMAP embedding of the 35 arguments onto two dimensions using a 13-feature
attribute vector (value identity, argumentation scheme, action-set composition,
normalised in/out degree). Node colour encodes value (blue: life-Hal; green:
life-Carla; amber: freedom-Hal; pink: freedom-Carla); shape encodes scheme
(circle: AS1 positive consequentialist; diamond: AS2 defensive consequentialist).
Gold halos mark the convex hull of each preferred extension.
Proximity reflects attribute similarity; no attack edges are drawn.

### Discussion notes

**What the layout shows.**
The embedding reveals four loose regional clusters corresponding to the four
value-audience pairs, but the clusters are not cleanly separated: arguments from
different values occupy overlapping regions of the attribute space. This is
confirmed by the negative silhouette score across all embedding methods tested
(see §Methods): no layout algorithm produces clean value partitions. The overlap
is not an artefact of the embedding — it reflects that the same physical actions
(e.g. `comH`, `doNH`) appear in arguments across multiple value frames, making
attribute vectors of different-value arguments genuinely similar.

**The isolated AS1 cluster.**
The six AS1 arguments (positive consequentialist, scheme 1) form a visually
distinct subgroup at the lower-centre of the figure, separated from the AS2
diamond mass. Their isolation is informative: AS1 arguments share a specific
attribute profile — single-action sets, the positive scheme, and high in-degree
(they are attacked by almost every AS2 argument). Their separation encodes the
structural asymmetry between the two schemes: AS1 arguments justify an action by
its expected outcomes; AS2 arguments defend the same action against objections.
Under the symmetric attack relation of the base framework, every AS1 argument
defends itself in a one-step proof (see §Dialectical Proofs), which is why they
are annotated as "self-defending."

**Extension halos and value.**
The gold halos (preferred extensions) cut across value regions rather than
coinciding with them. A preferred extension is a maximal conflict-free set under
Dung semantics, and conflict-freeness is determined by the attack relation, not
by value. The cross-cluster reach of the halos is therefore expected: extensions
group arguments that are dialectically compatible, not arguments that share a
value label. This is a key diagnostic result — it shows that the base Dung
framework, operating over the full attack relation, produces extensions that are
value-mixed. The normative filtering that produces value-coherent outcomes is
done by the VAF audience preference ordering, not by the Dung semantics.

---

## Figure 2 — Argument Space: Topological Structure

### Suggested caption

**Figure 2.** Topological structure of the INS argument space.
Kamada-Kawai stress-minimisation layout of the 35-argument attack graph
(symmetrised for layout purposes). Node colour and shape as in Figure 1.
Gold halos: convex hull of each preferred extension. Faint red cobweb: all 774
attack edges at low opacity (α = 0.04), showing edge density. Darker gold
arrows: inter-value attacks only (α = 0.14). White-bordered nodes: most central
argument (minimum mean graph-theoretic distance to all others) and peripheral
AS1 arguments (>70th percentile mean distance).

### Discussion notes

**The mandala geometry.**
The Kamada-Kawai algorithm positions nodes to minimise the discrepancy between
Euclidean layout distance and graph-theoretic shortest-path distance. Applied to
the INS attack graph, this produces an emergent sunburst or mandala pattern:
extension halos radiate as concentric golden arcs from a dense central region.
The geometry is not imposed — it arises from the combination of high attack
density (774 edges on 35 nodes, density ≈ 0.65) and the extension structure.
Because preferred extensions are maximal conflict-free sets in a dense graph,
each extension's members are pushed into a narrow angular sector, producing the
radial organisation.

**The cobweb and maximal contentiousness.**
The faint red cobweb from all 774 edges at α = 0.04 is not decorative. It
encodes the most important structural result of the framework: the argument
space is maximally contentious. No pair of arguments at different values is
free of attack relations; the graph is close to complete. This means the base
Dung semantics cannot resolve the scenario by itself — every possible coalition
of arguments is challenged by some argument outside it. The VAF audience
ordering is not a convenience but a necessity: without it, no stable
value-coherent position can be extracted from this space.

**The central argument: `losH-doNH::freedomH`.**
The most central argument by mean graph-theoretic distance (0.674 normalised
units) is the AS2 argument combining actions `losH` (harm to Hal, i.e. Hal's
loss) and `doNH` (duty of non-harm), under the value `freedomH`.
Its centrality is not accidental. This argument:
(i) participates in more preferred extensions than the average;
(ii) attacks and is attacked by arguments from all four value regions;
(iii) combines two of the most-shared actions across value frames.
It is the argument that sits at the dialectical intersection of all four value
clusters — the point where consequentialist and defensive reasoning, and Hal's
and Carla's value frames, all converge. In informal terms: the duty not to harm
(doNH) combined with the acknowledgement of Hal's loss (losH) is the most
contested position in the entire argument space, precisely because it is
relevant to every participant's position.

**Peripheral AS1 nodes.**
The AS1 arguments (circles with white borders on the outer ring) are peripheral
not because they are weakly connected — they are attacked by almost everything —
but because their attack profile is structurally homogeneous: they are targeted
uniformly by all AS2 arguments and attack back symmetrically. In stress
minimisation, homogeneous connectivity produces peripheral positions: a node
equidistant from all others in graph-theoretic terms is pushed to the outer ring,
not the centre. The peripherality of AS1 arguments spatially encodes the same
property that produces their one-step dialectical proofs: they are
self-defending because they are universally attacked and universally
counter-attack, which under a symmetric relation means they always hold their
ground. Their position at the margin of the sunburst is the geometric image of
their argumentative isolation.

**Value interleaving around the ring.**
The four value colours are interleaved around the outer ring rather than
appearing in contiguous sectors. This is a direct visual confirmation of the
negative silhouette result from Figure 1: graph-theoretic distance does not
track value identity. An argument's position in the attack graph is determined
by its action set and scheme, not by whose value it serves. The Kamada-Kawai
layout makes this visible as a pattern: no arc of the mandala is monochromatic.

---

## On the choice of layout method

Seven layout and embedding methods were evaluated (Fruchterman-Reingold,
Kamada-Kawai, spectral, UMAP on attribute features, UMAP on adjacency, UMAP on
extension membership, spectral-graph-embedding + UMAP) using five quantitative
metrics: value cluster separation, silhouette score, extension compactness,
attack-pair proximity, and layout stress. Full results are in
`docs/notes/visualisation_interpretation.md`.

Figure 1 (UMAP on attribute features) was selected because it encodes the
*attribute* dimension — what arguments are, independent of how they attack each
other — and because the isolated AS1 cluster is its most diagnostically useful
feature.

Figure 2 (Kamada-Kawai) was selected because it encodes the *topological*
dimension — how arguments relate through attack and defence — and because the
emergent mandala geometry is both visually striking and structurally meaningful.
The two figures are complementary: Figure 1 answers "what are these arguments?",
Figure 2 answers "how do they fight?".

The spectral layout was excluded (graph not fully connected; layout degenerated).
Fruchterman-Reingold produced the best mean quantitative rank but was visually
undifferentiated — the high edge density produces a roughly circular blob with
no internal structure visible.
