/*  Copyright (c) 2026 Francesco Perrone. All Rights Reserved.
 *  SPDX-License-Identifier: LicenseRef-INS-1.0
 *  See the LICENSE file in the repository root for the full terms.
 */

:- module(vaf, [
    audience/2,
    val/2,
    prefers/3,
    defeats/3,
    vaf_conflict_free/2,
    vaf_defends/3,
    vaf_admissible/2,
    vaf_preferred_extension/2,
    vaf_grounded_extension/2
]).

:- use_module(args).
:- use_module(extensions, [all_arguments/1, preferred_ext_for/3,
                            powerset/2, is_subset/2]).

/** <module> Value-Based Argumentation Framework (VAF)

Implements the Value-Based Argumentation Framework of Bench-Capon (2003).
Extends Dung's abstract framework by associating each argument with the
value it promotes and evaluating the framework relative to an *audience*,
which is a strict preference ordering over values.

Under VAF semantics, argument A *defeats* argument B (for audience P) if:
  1. A attacks B, AND
  2. B's value is NOT strictly preferred over A's value in P.

This breaks the symmetry of the attack relation: if A promotes a
higher-ranked value than B, A can defeat B but B cannot defeat A.

Defined audiences (ordered most to least preferred):

  life_first:     [lifeH, lifeC, freedomH, freedomC]
    Life values dominate freedom values; Hal's life slightly before Carla's.

  altruistic:     [lifeC, lifeH, freedomC, freedomH]
    Carla's wellbeing prioritised over Hal's.

  selfish:        [lifeH, freedomH, lifeC, freedomC]
    Hal's own values ranked above Carla's.

  freedom_first:  [freedomH, freedomC, lifeH, lifeC]
    Freedom values dominate; shows how different ethical stances change outcomes.

@see Bench-Capon, T. (2003). Persuasion in practical argument using
     value-based argumentation frameworks. Journal of Logic and Computation,
     13(3), 429-448.
@author Francesco Perrone
@license LicenseRef-INS-1.0
*/


%% audience(+Name:atom, -Order:list) is semidet
%
%  Defines a named audience as a preference ordering over values.
%  The list is ordered from most preferred (head) to least preferred (tail).
%
audience(life_first,    [lifeH, lifeC, freedomH, freedomC]).
audience(altruistic,    [lifeC, lifeH, freedomC, freedomH]).
audience(selfish,       [lifeH, freedomH, lifeC, freedomC]).
audience(freedom_first, [freedomH, freedomC, lifeH, lifeC]).


%% val(+Arg:term, -Value:atom) is det
%
%  The value promoted by an argument is its second argument
%  (the value passed to arg/2).
%
val(arg(_, V), V).


%% prefers(+Audience:atom, +Val1:atom, +Val2:atom) is semidet
%
%  Val1 is strictly preferred to Val2 under Audience.
%  Determined by position in the audience's ordering list.
%
prefers(Aud, V1, V2) :-
    audience(Aud, Order),
    nth0(I1, Order, V1),
    nth0(I2, Order, V2),
    I1 < I2.


%% defeats(+A:term, +B:term, +Audience:atom) is semidet
%
%  A defeats B under Audience: A attacks B and B's value is not
%  strictly preferred over A's value in Audience.
%
defeats(A, B, Aud) :-
    attacks(A, B),
    val(A, VA),
    val(B, VB),
    \+ prefers(Aud, VB, VA).


%% vaf_conflict_free(+Set:list, +Audience:atom) is semidet
%
%  Set is conflict-free under Audience if no member defeats another member.
%
vaf_conflict_free(Set, Aud) :-
    \+ (member(A, Set), member(B, Set), defeats(A, B, Aud)).


%% vaf_defends(+Set:list, +A:term, +Audience:atom) is semidet
%
%  Set defends A under Audience if every argument that defeats A
%  is itself defeated by some member of Set.
%
vaf_defends(Set, A, Aud) :-
    \+ (defeats(B, A, Aud), \+ (member(C, Set), defeats(C, B, Aud))).


%% vaf_admissible(+Set:list, +Audience:atom) is semidet
%
%  Set is admissible under Audience if it is conflict-free and
%  defends all its members.
%
vaf_admissible(Set, Aud) :-
    vaf_conflict_free(Set, Aud),
    forall(member(A, Set), vaf_defends(Set, A, Aud)).


%% vaf_preferred_extension(-Ext:list, +Audience:atom) is nondet
%
%  Ext is a preferred extension under Audience: a maximal admissible
%  set with respect to the VAF defeat relation.
%  Uses labelling-based search via preferred_ext_for/3.
%
vaf_preferred_extension(Ext, Aud) :-
    all_arguments(AllArgs),
    preferred_ext_for(AllArgs, [A,B]>>defeats(A,B,Aud), Ext).


%% vaf_grounded_extension(-Ext:list, +Audience:atom) is det
%
%  Ext is the grounded extension under Audience: least fixed point of
%  F_P(S) = { a | S vaf-defends a under Audience }.
%
vaf_grounded_extension(Ext, Aud) :-
    vaf_grounded_fp([], Ext, Aud).

vaf_grounded_fp(S, Ext, Aud) :-
    all_arguments(AllArgs),
    findall(A, (member(A, AllArgs), vaf_defends(S, A, Aud)), Next0),
    sort(Next0, Next),
    sort(S, SS),
    (SS = Next -> Ext = Next ; vaf_grounded_fp(Next, Ext, Aud)).
