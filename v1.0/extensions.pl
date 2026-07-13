/*  Copyright (c) 2026 Francesco Perrone. All Rights Reserved.
 *  SPDX-License-Identifier: LicenseRef-INS-1.0
 *  See the LICENSE file in the repository root for the full terms.
 */

:- module(extensions, [
    all_arguments/1,
    conflict_free/1,
    defends/2,
    admissible/1,
    preferred_extension/1,
    grounded_extension/1,
    stable_extension/1,
    preferred_ext_for/3,
    powerset/2,
    is_subset/2
]).

:- use_module(args).
:- use_module(library(apply)).   % foldl/4, include/3

/** <module> Dung-style abstract argumentation semantics.

Implements the core Dung (1995) semantics over the argument set
produced by arg/2 and the attack relation produced by attacks/2.

Semantics provided:
  - conflict_free/1          — no internal conflicts
  - admissible/1             — conflict-free and self-defending
  - preferred_extension/1    — maximal admissible sets
  - grounded_extension/1     — least fixed point of the characteristic function
  - stable_extension/1       — conflict-free and attacks all outside arguments

preferred_extension/1 uses complete-labelling search (Caminada 2006) rather
than brute-force powerset enumeration (O(2^n)). A labelling
L : Args → {in, out, undec} is *complete* if:
  L(a)=in   <->  all args b with b attacks a have L(b)=out
  L(a)=out  <->  some arg b with b attacks a has L(b)=in
A *preferred* labelling has a maximal in-set among all complete labellings.
The labelling is computed by constraint propagation followed by a binary
choice (in / keep-undec) for each genuinely ambiguous argument.

The generic predicate preferred_ext_for/3 is exported so vaf.pl can reuse
the same algorithm with the VAF defeat relation instead of attacks/2.

@see args.pl
@author Francesco Perrone
@license LicenseRef-INS-1.0
*/


%% all_arguments(-Args:list) is det
%
%  Collect all arguments from arg/2 into a sorted list of arg/2 terms.
%
all_arguments(Args) :-
    setof(arg(Acts, Val), arg(Acts, Val), Args).


%% conflict_free(+Set:list) is semidet
%
%  Set is conflict-free if no member attacks any other member.
%
conflict_free(Set) :-
    \+ (member(A, Set), member(B, Set), attacks(A, B)).


%% defends(+Set:list, +A:term) is semidet
%
%  Set defends A if every argument that attacks A is itself
%  attacked by some member of Set.
%
defends(Set, A) :-
    \+ (attacks(B, A), \+ (member(C, Set), attacks(C, B))).


%% admissible(+Set:list) is semidet
%
%  Set is admissible if it is conflict-free and defends all its members.
%
admissible(Set) :-
    conflict_free(Set),
    forall(member(A, Set), defends(Set, A)).


%% preferred_extension(-Ext:list) is nondet
%
%  Ext is a preferred extension: a maximal admissible set.
%  Enumerates all preferred extensions on backtracking.
%  Uses labelling-based search; see preferred_ext_for/3.
%
preferred_extension(Ext) :-
    all_arguments(AllArgs),
    preferred_ext_for(AllArgs, attacks, Ext).


%% preferred_ext_for(+AllArgs:list, +AttackPred, -Ext:list) is nondet
%
%  Generic labelling-based preferred extension computation.
%  AttackPred is called as call(AttackPred, A, B) to test whether A attacks B.
%  Enumerates all preferred extensions on backtracking.
%
%  Algorithm (Caminada 2006):
%    1. Initialise all arguments as undec.
%    2. Propagate forced labels:
%         - all attackers of A are out  =>  A must be in
%         - some attacker of A is in    =>  A must be out
%    3. For each remaining undec argument (in fixed order):
%         Option 1: force it to in and propagate.
%         Option 2: leave it as undec.
%    4. A complete labelling is preferred if no undec argument can be moved to in.
%
%  Note: two different choice sequences can yield the same in-set when
%  propagation from a later choice forces an earlier undec arg to in.
%  Duplicates are removed via findall/sort before enumerating.
%
preferred_ext_for(AllArgs, AttackPred, Ext) :-
    findall(E, preferred_ext_raw(AllArgs, AttackPred, E), Exts0),
    sort(Exts0, Exts),
    member(Ext, Exts).

preferred_ext_raw(AllArgs, AP, Ext) :-
    lb_init(AllArgs, L0),
    lb_propagate(AP, AllArgs, L0, L1),
    \+ lb_contradicted(AP, L1),
    lb_undec_args(L1, Undecs),
    lb_extend(Undecs, AP, AllArgs, L1, L),
    lb_is_complete(AP, AllArgs, L),
    \+ lb_can_extend_in(AP, AllArgs, L),
    lb_in_set(L, Ext).


%% grounded_extension(-Ext:list) is det
%
%  Ext is the grounded extension: least fixed point of F(S) = {a | S defends a}.
%  Computed iteratively from the empty set.
%
grounded_extension(Ext) :-
    grounded_fp([], Ext).

grounded_fp(S, Ext) :-
    all_arguments(AllArgs),
    findall(A, (member(A, AllArgs), defends(S, A)), Next0),
    sort(Next0, Next),
    sort(S, SS),
    (SS = Next -> Ext = Next ; grounded_fp(Next, Ext)).


%% stable_extension(-Ext:list) is nondet
%
%  Ext is a stable extension: a preferred extension that attacks every
%  argument outside it.
%  Stable extensions form a subset of preferred extensions.
%
stable_extension(Ext) :-
    preferred_extension(Ext),
    all_arguments(AllArgs),
    forall(member(A, AllArgs),
           (member(A, Ext) ; (member(B, Ext), attacks(B, A)))).


% =========================================================
% Labelling helpers (lb_ prefix to avoid name clashes)
% =========================================================

% Labelling: list of Arg-Label pairs, Label in {in, out, undec}.

lb_init(Args, L) :-
    pairs_keys_values(L, Args, Labels),
    maplist(=(undec), Labels).

lb_undec_args(L, Undecs) :-
    include([_-undec]>>true, L, Pairs),
    pairs_keys(Pairs, Undecs).

lb_in_set(L, Ext) :-
    include([_-in]>>true, L, InPairs),
    pairs_keys(InPairs, Ext0),
    sort(Ext0, Ext).

lb_set(A, Label, L0, L) :-
    select(A-_, L0, Rest),
    L = [A-Label|Rest].

% lb_propagate: apply forced-label rules until fixed point.
lb_propagate(AP, AllArgs, L0, L) :-
    lb_propagate_step(AP, AllArgs, L0, L1),
    (L0 == L1 -> L = L1 ; lb_propagate(AP, AllArgs, L1, L)).

lb_propagate_step(AP, AllArgs, L0, L) :-
    foldl(lb_force_one(AP, AllArgs), AllArgs, L0, L).

lb_force_one(AP, AllArgs, A, L0, L) :-
    memberchk(A-undec, L0), !,
    (   lb_all_attackers_out(AP, AllArgs, A, L0)
    ->  lb_set(A, in,  L0, L)
    ;   lb_some_attacker_in(AP, AllArgs, A, L0)
    ->  lb_set(A, out, L0, L)
    ;   L = L0
    ).
lb_force_one(_, _, _, L, L).

lb_all_attackers_out(AP, AllArgs, A, L) :-
    \+ (member(B, AllArgs), call(AP, B, A),
        memberchk(B-BL, L), BL \= out).

lb_some_attacker_in(AP, AllArgs, A, L) :-
    member(B, AllArgs), call(AP, B, A), memberchk(B-in, L), !.

% Contradiction: two in-labeled args where one defeats the other
% (in EITHER direction). Must check both because defeat may be asymmetric
% (e.g. VAF) and lb_force_one only updates undec args, so a previously-in
% arg is not retroactively set to out when a new in arg defeats it.
lb_contradicted(AP, L) :-
    member(A-in, L),
    member(B-in, L),
    (call(AP, B, A) ; call(AP, A, B)), !.

% lb_extend: for each undec arg (in order), choose in (+ propagate) or undec.
lb_extend([], _, _, L, L).
lb_extend([A|Rest], AP, AllArgs, L0, L) :-
    memberchk(A-Label, L0),
    (   Label \= undec
    ->  lb_extend(Rest, AP, AllArgs, L0, L)
    ;   (   lb_set(A, in, L0, L1),
            lb_propagate(AP, AllArgs, L1, L2),
            \+ lb_contradicted(AP, L2),
            lb_extend(Rest, AP, AllArgs, L2, L)
        ;   lb_extend(Rest, AP, AllArgs, L0, L)
        )
    ).

% lb_can_extend_in: some undec arg can be moved to in without contradiction.
% lb_set puts A=in before propagation; propagation never reverts in-labels,
% so A will remain in throughout any subsequent lb_extend — no need to verify.
lb_can_extend_in(AP, AllArgs, L) :-
    member(A-undec, L),
    lb_set(A, in, L, L1),
    lb_propagate(AP, AllArgs, L1, L2),
    \+ lb_contradicted(AP, L2).

% lb_is_complete: verify the labelling satisfies all completeness conditions.
%   in(A)  <->  all args that defeat A are out
%   out(A) <->  some arg that defeats A is in
% Required for correctness with asymmetric defeat relations (VAF): lb_extend
% may leave a labelling where in(A) holds but some defeater of A is still undec
% (not out), which is not a valid complete labelling.
lb_is_complete(AP, AllArgs, L) :-
    forall(member(A-in,  L), lb_all_attackers_out(AP, AllArgs, A, L)),
    forall(member(A-out, L), lb_some_attacker_in(AP, AllArgs, A, L)).


% =========================================================
% Legacy predicates (retained for callers that import them)
% =========================================================

%% powerset(+List:list, -Sub:list) is nondet
powerset([], []).
powerset([_|T], Sub)    :- powerset(T, Sub).
powerset([H|T], [H|Sub]):- powerset(T, Sub).

%% is_subset(+Sub:list, +Sup:list) is semidet
is_subset(Sub, Sup) :-
    forall(member(X, Sub), member(X, Sup)).
