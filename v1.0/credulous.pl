/*  Copyright (c) 2026 Francesco Perrone. All Rights Reserved.
 *  SPDX-License-Identifier: LicenseRef-INS-1.0
 *  See the LICENSE file in the repository root for the full terms.
 */

:- module(credulous, [
    credQA/2,
    vaf_credQA/3,
    cred_qa/3,
    sceptically_accepted/1,
    vaf_sceptically_accepted/2
]).

:- use_module(args).
:- use_module(extensions, [all_arguments/1, preferred_extension/1]).
:- use_module(vaf).
:- use_module(library(lists)).

/** <module> Credulous and sceptical acceptance via dialectical proof.

Implements the φ₁-proof algorithm of Cayrol, Doutre & Mengin (2003) for
deciding whether a given argument is credulously accepted under the preferred
semantics, returning the dialectical proof as a structured dialogue.

Based on Marek Sergot's SWI-Prolog adaptation of the CDM algorithm
(articles/sergot/templates/accepted_arg.pl), extended with:
  - a parameterised defeat predicate so the same code handles both Dung
    (attacks/2) and VAF (defeats/3) without duplication;
  - a clean pair (Seq, Pro) proof term returning both the dialogue sequence
    and PRO's final admissible argument set.

Credulous acceptance (CDM 2003, Definition 2.6):
  a is credulously accepted iff a is in at least one preferred extension.

Sceptical acceptance (CDM 2003, Definition 2.6):
  a is sceptically accepted iff a is in every preferred extension.

The φ₁-proof is a won dialogue:
  - PRO opens with the argument to be proved.
  - OPP may attack any of PRO's current arguments (odd-length moves).
  - PRO counters with an argument not in conflict with its set and not
    previously excluded (even-length moves).
  - PRO wins when OPP has no legal reply (φ₁(d) = ∅).

Proof term: (Seq, Pro)
  Seq — chronological list of pro(Arg)/opp(Arg) moves (oldest first).
  Pro — PRO's final admissible argument set (contains the proved argument).

@see Cayrol, Doutre & Mengin (2003). J. Logic Computat. 13(3), 377-402.
@see articles/sergot/templates/accepted_arg.pl
@author Francesco Perrone
@license LicenseRef-INS-1.0
*/


%% credQA(+Arg:term, -Proof:term) is semidet
%
%  True if Arg is credulously accepted under Dung preferred semantics.
%  Proof = (Seq, Pro): Seq is the dialogue (chronological), Pro is PRO's set.
%
credQA(Arg, Proof) :-
    cred_qa(attacks, Arg, Proof).


%% vaf_credQA(+Arg:term, +Audience:atom, -Proof:term) is semidet
%
%  True if Arg is credulously accepted under VAF preferred semantics
%  for the given Audience. Uses defeats/3 from vaf.pl.
%
vaf_credQA(Arg, Aud, Proof) :-
    cred_qa([A,B]>>defeats(A,B,Aud), Arg, Proof).


%% cred_qa(+AP, +Arg:term, -Proof:term) is semidet
%
%  Generic φ₁-proof algorithm parameterised on the defeat predicate AP,
%  called as call(AP, Attacker, Target). Exported for extensibility.
%
cred_qa(AP, Arg, (Seq, Pro)) :-
    \+ call(AP, Arg, Arg),
    findall(X, call(AP, X, X), Refl),
    cred_neighbours(AP, Arg, Arglist),
    cred_append_new(Refl, Arglist, Out),
    cred_rec(AP, ([pro(Arg)], [Arg]), Out, RevSeq, Pro),
    reverse(RevSeq, Seq).


%% sceptically_accepted(+Arg:term) is semidet
%
%  True if Arg is in every preferred extension (sceptical acceptance, Dung).
%
sceptically_accepted(Arg) :-
    all_arguments(All),
    member(Arg, All),
    forall(preferred_extension(Ext), member(Arg, Ext)).


%% vaf_sceptically_accepted(+Arg:term, +Audience:atom) is semidet
%
%  True if Arg is in every VAF preferred extension for Audience.
%
vaf_sceptically_accepted(Arg, Aud) :-
    all_arguments(All),
    member(Arg, All),
    forall(vaf_preferred_extension(Ext, Aud), member(Arg, Ext)).


% =========================================================
% Core recursive dialogue procedure
% Internal state: (D, ProD) where D is the dialogue sequence
% (most recent move first) and ProD is PRO's current argument set.
% =========================================================

% Base case: no member of ProD has an undefended attacker — PRO wins.
% Returns D (the accumulated dialogue) and ProD (PRO's admissible set).
%
% Active case: find P in ProD attacked by some X not defended by ProD;
% PRO picks counter Y attacking X, not in Out; recurse with extended state.
% If recursion succeeds take that proof; otherwise exclude Y and retry.

cred_rec(AP, (D, ProD), Out, Seq, Pro) :-
    member(P, ProD),
    call(AP, X, P),
    \+ cred_defends(AP, ProD, X), !,
    call(AP, Y, X), \+ member(Y, Out),
    cred_neighbours(AP, Y, Yneighbours),
    cred_append_new(Yneighbours, Out, OutNew),
    list_to_set([Y|ProD], ProDnew),
    (   cred_rec(AP, ([pro(Y),opp(X)|D], ProDnew), OutNew, Seq, Pro)
    ->  true
    ;   cred_rec(AP, (D, ProD), [Y|Out], Seq, Pro)
    ).
cred_rec(_, (D, ProD), _, D, ProD).


% =========================================================
% Helpers
% =========================================================

%  cred_defends(+AP, +Args, +P) is semidet
%  True if some member of Args defeats P.
%
cred_defends(AP, Args, P) :-
    member(Px, Args),
    call(AP, Px, P).


%  cred_neighbours(+AP, +Arg, -Neighbours) is det
%  Neighbours = R±(Arg): all args that defeat Arg UNION all args Arg defeats.
%  PRO must exclude these when extending its argument set.
%
cred_neighbours(AP, Arg, Neighbours) :-
    findall(X, call(AP, X, Arg), Attackers),
    findall(Y, call(AP, Arg, Y), Attacked),
    list_to_set(Attacked, AttackedU),
    cred_append_new(Attackers, AttackedU, Neighbours).


%  cred_append_new(+New, +Acc, -Out) is det
%  Appends elements of New to Acc, skipping those already present.
%
cred_append_new([], X, X) :- !.
cred_append_new([U|V], X, Y) :-
    (memberchk(U, X) -> Next = X ; Next = [U|X]), !,
    cred_append_new(V, Next, Y).
