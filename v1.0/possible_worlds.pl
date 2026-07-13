/*  Copyright (c) 2026 Francesco Perrone. All Rights Reserved.
 *  SPDX-License-Identifier: LicenseRef-INS-1.0
 *  See the LICENSE file in the repository root for the full terms.
 */

:- module(possible_worlds, [
    value_weight/3,
    attr_weight/3,
    value_distance/4,
    closest_worlds/5,
    lewis_would/5,
    stalnaker_would/5,
    % Standard antecedents
    hal_lacks_insulin/1,
    carla_lacks_insulin/1,
    hal_dead/1,
    carla_dead/1,
    hal_lacks_money/1,
    carla_lacks_money/1
]).

:- use_module(library(apply)).   % foldl/4
:- use_module(library(lists)).   % min_list/2
:- use_module(library(pairs)).   % pairs_keys/2

:- use_module(states).
:- use_module(values).
:- use_module(vaf,  [audience/2]).
:- use_module(trans).
:- use_module(counterfactual, [holds/2]).

/** <module> Possible world semantics for counterfactual conditionals

Implements Lewis-style (1973) and Stalnaker-style (1968) possible world
semantics over the AATS state space, with a *value-weighted* similarity
metric derived from the VAF audience ordering.

== Background ==

The counterfactual layer in counterfactual.pl implements a *fixed-antecedent*
Lewisian intervention: the counterfactual world is always the state reached by
substituting doNH for Hal's actions (cf_joint_seq/2).  This is a degenerate
case of Lewis semantics in which the antecedent picks out exactly one world and
no closeness ordering is needed.

This module provides the full machinery:

  1. A *world space* — all states reachable from a given initial state Q in
     N joint-action steps.  These are the worlds that are *possible* within
     the AATS: not arbitrary bit-vectors, but states the transition function
     τ can actually reach.

  2. A *value-weighted similarity ordering* — audience-relative weighted
     Hamming distance over state attributes.  Each attribute difference is
     weighted by the rank of the value it realises in the audience's preference
     ordering.  A difference in a high-ranked value (e.g. life) counts for
     more distance than a difference in a low-ranked value (e.g. money), so
     worlds that preserve more morally important attributes are judged closer
     to actuality.

  3. The *Lewis conditional* (□→) — lewis_would/5: in ALL closest worlds
     satisfying the antecedent, the consequent holds.  When multiple worlds
     tie for minimum distance, all of them must satisfy the consequent.

  4. The *Stalnaker conditional* — stalnaker_would/5: a unique closest world
     is selected (Stalnaker's uniqueness assumption).  In a finite discrete
     space ties are possible; they are broken by the canonical sort order of
     state lists.  This is the most conservative reading: the consequent must
     hold in the single "most similar" world.

== Audience-relativity ==

The closeness ordering is parameterised by an audience, making the
counterfactuals audience-sensitive in exactly the same way that argument
defeat is in the VAF layer.  Under `selfish` (lifeH > freedomH > ...), a
world that preserves Hal's life but changes his money is judged closer to
actuality than one that kills Hal.  Under `altruistic` (lifeC > lifeH > ...)
the ordering shifts: Carla's life attribute is weighted most heavily.

This means two agents with different value orderings can rationally disagree
about which counterfactual world is "closest" — and therefore disagree about
the truth of a counterfactual conditional — without either being in logical
error.  This is the intended result.

== Relation to cf_joint_seq / AS3 ==

The fixed-antecedent approach in counterfactual.pl is a special case of
lewis_would/5: when the antecedent is precisely "Hal does doNH" and τ
determines a unique counterfactual outcome, the closest-world computation
reduces to a single state lookup with no distance calculation needed.

  counterfactual_holds(Q, J, P)  ≡
    lewis_would(Q, J, [W]>>\+ holds(P,W), [W]>>holds(P,W), _Aud)
    where the antecedent is satisfied by exactly one reachable world
    (the doNH-substituted outcome) and that world is the unique closest one.

This module therefore *grounds* the AS3 scheme within full possible world
semantics and opens the door to general-antecedent counterfactuals not
expressible through action substitution alone.

== Lewis vs Stalnaker ==

Lewis (1973) allows ties: multiple worlds can share the minimum distance.
The conditional `A □→ C` is true iff C holds in *all* minimally close A-worlds.

Stalnaker (1968) posits a *selection function* f(A, w) that picks a unique
closest A-world from actual world w.  `A > C` is true iff C holds in f(A, w).
Stalnaker's uniqueness assumption (no ties) is not guaranteed in a finite
discrete state space; when ties occur, the implementation selects the first
element of the sorted closest-worlds list.  This gives a deterministic and
reproducible result.

The two conditionals coincide when there is exactly one closest world.  When
there are ties they can diverge: lewis_would requires the consequent in ALL
closest worlds; stalnaker_would only in the first.

@see counterfactual.pl — fixed-antecedent counterfactuals (AS3 substrate)
@see docs/notes/possible_worlds_semantics.md — full theoretical discussion
@author Francesco Perrone
@license LicenseRef-INS-1.0
*/


% =========================================================
% Value-weighted similarity metric
% =========================================================

%% value_weight(+Aud:atom, +Val:atom, -W:integer) is semidet
%
%  The moral weight of value Val under audience Aud.
%  Defined as (N - Position), where N is the number of values in Aud's
%  ordering and Position is the 0-based index of Val in that list.
%  The most-preferred value (position 0) receives the highest weight N.
%
%  Interpretation: a difference in a high-weight value contributes more
%  to world distance — worlds that agree on more important values are closer.
%
%  Example (selfish: [lifeH, freedomH, lifeC, freedomC], N=4):
%    value_weight(selfish, lifeH,    4)  % most preferred, highest weight
%    value_weight(selfish, freedomH, 3)
%    value_weight(selfish, lifeC,    2)
%    value_weight(selfish, freedomC, 1)  % least preferred, lowest weight
%
%  @arg Aud  named audience atom
%  @arg Val  value atom
%  @arg W    non-negative integer weight
%
value_weight(Aud, Val, W) :-
    audience(Aud, Order),
    length(Order, N),
    nth0(Pos, Order, Val),
    W is N - Pos.


%% attr_weight(+Aud:atom, +Attr:atom, -W:integer) is semidet
%
%  The weight of state attribute Attr under Aud, derived via affects/2.
%  If no value is associated with Attr (unexpected), weight defaults to 0.
%
%  @arg Aud   named audience atom
%  @arg Attr  state attribute atom (ih, mh, ah, ic, mc, ac)
%  @arg W     weight (same as value_weight for the realised value)
%
attr_weight(Aud, Attr, W) :-
    (   affects(Attr, Val), value_weight(Aud, Val, W)
    ->  true
    ;   W = 0
    ).


%% value_distance(+S1:list, +S2:list, +Aud:atom, -D:integer) is det
%
%  Audience-relative weighted Hamming distance between states S1 and S2.
%  For each attribute that differs between S1 and S2, the weight of the
%  value it realises under Aud is added to the total distance.
%
%  D = sum_{Attr : S1[Attr] ≠ S2[Attr]} attr_weight(Aud, Attr)
%
%  When S1 = S2, D = 0 (identical worlds have zero distance).
%
%  @arg S1   state list
%  @arg S2   state list
%  @arg Aud  named audience atom
%  @arg D    non-negative integer distance
%
value_distance(S1, S2, Aud, D) :-
    attributes(Attrs),
    foldl([A, Acc, NAcc]>>(
              attribute(A, S1, V1),
              attribute(A, S2, V2),
              (V1 \= V2 -> attr_weight(Aud, A, W) ; W = 0),
              NAcc is Acc + W
          ), Attrs, 0, D).


% =========================================================
% Possible world selection
% =========================================================

%% closest_worlds(+Q:list, +Actual:list, :Ant, +Aud:atom, -Closest:list) is semidet
%
%  Closest is the set of all states W such that:
%    (a) W is reachable from Q in exactly 2 joint-action steps,
%    (b) call(Ant, W) holds (W satisfies the antecedent), and
%    (c) value_distance(Actual, W, Aud, D) is minimal among all such W.
%
%  Fails if no reachable state satisfies the antecedent (impossible antecedent
%  within the model — the counterfactual is undefined, not vacuously true).
%
%  Ties are preserved: Closest may contain more than one world.
%  The list is sorted for deterministic enumeration.
%
%  @arg Q       initial state (the departure point for reachability)
%  @arg Actual  the actual outcome state (centre of the similarity sphere)
%  @arg Ant     antecedent predicate, called as call(Ant, W)
%  @arg Aud     named audience atom (determines the distance metric)
%  @arg Closest sorted list of minimum-distance antecedent-satisfying worlds
%
closest_worlds(Q, Actual, Ant, Aud, Closest) :-
    findall(D-W,
            (   transj(Q, _, W, 2),
                call(Ant, W),
                value_distance(Actual, W, Aud, D)
            ),
            Pairs),
    Pairs \= [],
    pairs_keys(Pairs, Ds),
    min_list(Ds, MinD),
    findall(W, member(MinD-W, Pairs), Closest0),
    sort(Closest0, Closest).


% =========================================================
% Counterfactual conditionals
% =========================================================

%% lewis_would(+Q:list, +J:list, :Ant, :Con, +Aud:atom) is semidet
%
%  The Lewis counterfactual conditional (□→) under audience Aud:
%
%    "If it had been the case that Ant, then Con would have held."
%
%  True iff Con holds in ALL worlds in closest_worlds(Q, Actual, Ant, Aud),
%  where Actual is the state reached by executing J from Q.
%
%  When the closest-worlds set is a singleton, Lewis and Stalnaker coincide.
%  When it contains multiple worlds (ties), lewis_would requires Con to hold
%  in all of them — the stronger reading.
%
%  Fails if the antecedent has no reachable witness (impossible antecedent).
%
%  Example:
%  ==
%  % "Had Hal lacked insulin (under selfish audience), he would have died."
%  ?- lewis_would([0,1,1,1,1,1], [buyH-losC,doNH-buyC],
%                 hal_lacks_insulin, hal_dead, selfish).
%  ==
%
%  @arg Q    initial state
%  @arg J    actual joint action sequence (list of H-C terms, length 2)
%  @arg Ant  antecedent predicate on outcome states
%  @arg Con  consequent predicate on outcome states
%  @arg Aud  named audience atom
%
lewis_would(Q, J, Ant, Con, Aud) :-
    length(J, N),
    transj(Q, J, Actual, N),
    closest_worlds(Q, Actual, Ant, Aud, Closest),
    forall(member(W, Closest), call(Con, W)).


%% stalnaker_would(+Q:list, +J:list, :Ant, :Con, +Aud:atom) is semidet
%
%  The Stalnaker counterfactual conditional (>) under audience Aud:
%
%    "If it had been the case that Ant, then Con would have held."
%
%  Selects a SINGLE closest world (Stalnaker's uniqueness assumption).
%  When ties exist, the first element of the sorted closest-worlds list is
%  used as the selection function value — deterministic but arbitrary.
%
%  Weaker than lewis_would when ties exist: only the selected world must
%  satisfy Con, not all tied worlds.
%
%  @arg Q    initial state
%  @arg J    actual joint action sequence (list of H-C terms, length 2)
%  @arg Ant  antecedent predicate on outcome states
%  @arg Con  consequent predicate on outcome states
%  @arg Aud  named audience atom
%
stalnaker_would(Q, J, Ant, Con, Aud) :-
    length(J, N),
    transj(Q, J, Actual, N),
    closest_worlds(Q, Actual, Ant, Aud, [Selected | _]),
    call(Con, Selected).


% =========================================================
% Standard antecedents
% =========================================================

%  These are ready-made antecedent predicates for common moral queries.
%  Each takes a single state argument and can be passed directly to
%  lewis_would/5 and stalnaker_would/5.

%% hal_lacks_insulin(+S:list) is semidet
hal_lacks_insulin(S)   :- \+ holds(has_insulin(hal),   S).

%% carla_lacks_insulin(+S:list) is semidet
carla_lacks_insulin(S) :- \+ holds(has_insulin(carla), S).

%% hal_dead(+S:list) is semidet
hal_dead(S)            :- \+ holds(alive(hal),         S).

%% carla_dead(+S:list) is semidet
carla_dead(S)          :- \+ holds(alive(carla),       S).

%% hal_lacks_money(+S:list) is semidet
hal_lacks_money(S)     :- \+ holds(has_money(hal),     S).

%% carla_lacks_money(+S:list) is semidet
carla_lacks_money(S)   :- \+ holds(has_money(carla),   S).
