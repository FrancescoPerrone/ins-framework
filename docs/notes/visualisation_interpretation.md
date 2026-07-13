# Visualisation Interpretation: Argument Graph Layout Comparison

Material for the article section on topological and attribute structure of the argument space.

---

## Methods evaluated

Seven layout and embedding methods were compared across five quantitative metrics
(value cluster separation, silhouette score, extension compactness, attack-pair
proximity, layout stress). The methods are:

| Code | Method | Library |
|------|--------|---------|
| FR | Fruchterman-Reingold (force-directed) | NetworkX `spring_layout` |
| KK | Kamada-Kawai (stress minimisation) | NetworkX `kamada_kawai_layout` |
| SP | Spectral (graph Laplacian eigenvectors) | NetworkX `spectral_layout` |
| UF | UMAP on attribute feature matrix | umap-learn |
| UA | UMAP on symmetrised adjacency profile | umap-learn |
| UE | UMAP on extension-membership matrix | umap-learn |
| US | Spectral graph embedding → UMAP | sklearn + umap-learn |

### The hairball problem

With 774 attack edges on 35 nodes the graph is near-complete (density ≈ 0.65).
Rendering all edges at any opacity produces an unreadable hairball. Two strategies
were tested: (a) drop all edges and rely on node position alone; (b) show only
inter-value edges (attacks between arguments of different values), which reduces
clutter while preserving the cross-value conflict signal that matters most for
the article.

---

## Quantitative findings

All silhouette scores are negative across all seven methods. This is not a
rendering failure — it is a structural result. The four value clusters (lifeH,
lifeC, freedomH, freedomC) overlap in every embedding space tested, meaning no
single argument is unambiguously far from arguments of a different value. The
framework is maximally contentious not merely formally (by construction of the
attack relation) but topologically: attribute similarity and graph-theoretic
distance do not align with value boundaries.

This finding supports the article's claim that VAF filtering, rather than the
base Dung framework, is doing the normative work. Without an audience preference
ordering, the argument space has no natural value partitioning.

---

## Figure 1 — UMAP Attribute Clusters (`fig1_umap_attribute_clusters.png`)

**Method:** UMAP applied to the 13-dimensional attribute feature vector of each
argument (value identity one-hot encoded, scheme bit, action-presence bits,
normalised in/out degree). Parameters: `n_neighbors=11`, `min_dist=0.30`.

**What is shown:** Node position encodes attribute similarity — arguments close
together share value, scheme, and action-set composition. No attack edges are
drawn; extension membership is shown as convex-hull halos.

**Interpretation:**

- Four genuine regional clusters are visible, loosely tracking value: orange
  (freedomH / Hal) in the upper left, green (lifeC / Carla) in the centre and
  upper right, blue (lifeH / Hal) in the lower centre and lower right, pink
  (freedomC / Carla) in the centre-right.

- The clusters overlap rather than separate cleanly. This is the negative
  silhouette result made visible: arguments from different values share enough
  attribute structure (especially action sets) to land near one another. The
  overlap is structurally informative — it shows that the same physical actions
  appear across value frames, which is precisely what makes the framework
  contentious.

- The isolated AS1 circle cluster (upper right, annotated) is the most
  theoretically significant spatial feature. The six AS1 arguments (positive,
  consequentialist) are pulled away from the AS2 diamond mass. AS1 arguments
  share: (i) the circle scheme, (ii) single-action sets, (iii) high in-degree
  (they are attacked by almost everything). Their isolation in UMAP space
  confirms they are attributionally distinct from the defensive AS2 majority.
  It also reflects their self-defending property: under a symmetric attack
  relation every AS1 argument defends itself against all attackers in a
  one-move proof.

- Extension halos (dark gold convex hulls) cut across value regions rather than
  coinciding with them. Preferred extensions group arguments that are mutually
  compatible under Dung semantics, and that compatibility is determined by the
  attack relation, not by value. The halos' cross-cluster reach is another visual
  encoding of the same result: value agreement is neither necessary nor sufficient
  for argumentative compatibility.

**Appropriate use in the article:** This figure is best for the section explaining
*attribute structure* — how the 35 arguments relate to one another as objects
described by their features, prior to any graph-theoretic or dialectical analysis.
It motivates the VAF step by showing that the base attribute space has no natural
value partition.

---

## Figure 2 — Kamada-Kawai Mandala (`fig2_kk_mandala.png`)

**Method:** Kamada-Kawai stress minimisation on the symmetrised attack graph
(undirected). Node positions minimise the difference between Euclidean layout
distance and graph-theoretic shortest-path distance.

**What is shown:** The layout preserves graph topology. All 774 edges are drawn
at very low opacity (α = 0.04) to give a faint red cobweb texture without
obscuring nodes. Inter-value edges are additionally drawn at α = 0.13 with
curved arrows. Extension halos as convex hulls.

**Interpretation:**

- The dominant visual feature is the mandala / sunburst pattern: extension halos
  radiate outward from the dense central region as dark gold bands. This geometry
  is *emergent* — it was not imposed — and it encodes the attack density directly.
  Because extensions are maximal conflict-free sets and attacks are dense, each
  extension's members are pushed to a narrow angular sector by the stress
  minimisation, producing the radial banding.

- The most central argument is `losH-doNH::freedomH` (minimum mean distance to
  all others, 0.711 normalised units), annotated in the figure. This argument
  combines the actions `losH` (harm to oneself, Hal's loss) and `doNH` (duty of
  non-harm) under the value `freedomH`. Its centrality is geometrically meaningful:
  it participates in more extensions than average and attacks/is attacked by
  arguments across all four value regions, making it the node that is
  equidistant from the widest range of others under stress minimisation. It is the
  argument that sits at the dialectical intersection of all four value frames.

- Peripheral nodes (high mean distance, > 70th percentile) are predominantly AS1
  circles. They are pushed to the outer ring of the sunburst — not because they
  are weakly connected (they are attacked densely) but because their attack
  profile is relatively homogeneous: they are attacked by everyone and attack back
  symmetrically, so they occupy a structurally equivalent outer position rather
  than a bridging central one.

- The faint red cobweb from the full edge set at α = 0.04 visually confirms the
  near-complete density of the attack relation. The graph is not sparse with a few
  dominant edges; it is uniformly saturated. This is the "maximally contentious"
  result spatially: no argument is at peace with most others.

- The four value colours are interleaved around the ring rather than clustered in
  sectors, confirming the topological finding: graph-theoretic distance does not
  track value identity. An argument's position in the attack graph is determined
  by its action set and scheme, not its value label.

**Appropriate use in the article:** This figure is best for the section on
*topological structure* and the discussion of preferred extensions as radial
organisation. The mandala geometry is an unexpected and striking consequence of
stress minimisation on a dense attack graph with extension structure — worth
remarking on explicitly. The identification of `losH-doNH::freedomH` as the
central argument can anchor a discussion of which arguments are most dialectically
exposed (attacked across value lines, participating in many extensions).

---

## Other methods — why they were not selected for the article

**Fruchterman-Reingold (FR):** Best mean rank in quantitative metrics (3.20) but
visually noisy. Force-directed layout spreads nodes by repulsion and edge
attraction; with 774 edges every node is pulled towards every other, resulting in
a roughly circular blob with little internal differentiation. Useful as a baseline
but not distinctive enough for publication.

**Spectral:** Degenerate. The attack graph is not fully connected (NetworkX warning
confirmed), causing the spectral layout to collapse most nodes to identical
positions. Compactness and attack-proximity metrics both read 0.000 for this
reason. Excluded from all article figures.

**UMAP on adjacency (UA):** Each argument is embedded by its full 35-dimensional
attack and counter-attack vector. Captures structural equivalence (arguments with
similar attack profiles cluster together) rather than attribute similarity. Produces
reasonable separation but less interpretable than UF because the input is the
graph relation itself, creating circularity in the discussion.

**UMAP on extension membership (UE):** Most semantically meaningful embedding —
proximity encodes argumentative compatibility (shared membership in preferred
extensions). Produces visible clusters of mutually compatible arguments. Useful
as a companion figure but less visually dramatic than KK; not selected as a
primary figure.

**UMAP on spectral graph embedding (US):** Two-stage pipeline (SpectralEmbedding
k=8 then UMAP to 2D). Theoretically appealing but adds pipeline complexity and
does not improve over UF or KK on any metric that matters for the article's claims.

---

## Design notes (for Methods / Figure caption sections)

All figures: dark background (#0b0d13), monospace typeface, 300 DPI.
Node encoding: colour = value (lifeH blue #60a5fa, lifeC green #34d399,
freedomH amber #fbbf24, freedomC pink #f472b6); shape = scheme (circle = AS1
positive, diamond = AS2 defensive); white border = highlighted nodes (AS1
isolated cluster in Fig 1; most central + peripheral AS1 in Fig 2).
Extension halos: convex hull of extension members, filled in accent gold
(#c9a94a, α = 0.10–0.13). Gold rule at top = gold accent bar.

The implementation is in `docs/visualisation/` (Python 3, matplotlib, umap-learn,
networkx, scipy, sklearn). Reproducible with a running instance of the Prolog
server (`swipl v1.0/webapp/server.pl`) via `python3 article_figures.py`.
