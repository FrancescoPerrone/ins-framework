/*  Copyright (c) 2026 Francesco Perrone. All Rights Reserved.
 *  SPDX-License-Identifier: LicenseRef-INS-1.0
 *  See the LICENSE file in the repository root for the full terms.
 */

:- module(value, [value/1, sub/2, affects/2, better/4, worse/4, eval/4]).

/** <module> Values, evaluation, and value-change detection

Defines the ethical values at stake in the scenario and provides
predicates for evaluating how a state transition affects those values
for a given agent.

Values and the attributes that realise them:

  lifeH    — Hal is alive       (attribute ah)
  lifeC    — Carla is alive     (attribute ac)
  freedomH — Hal has money      (attribute mh)
  freedomC — Carla has money    (attribute mc)

Each agent subscribes to a subset of values via sub/2:
  Hal   subscribes to all four values.
  Carla subscribes only to her own values (lifeC, freedomC).

The evaluation function eval/4 returns a tagged list of value changes:
  +Val   — Val is promoted  (state improves w.r.t. Val)
  -Val   — Val is demoted   (state worsens  w.r.t. Val)
  @(Val) — Val is neutral   (state unchanged w.r.t. Val)

@author Francesco Perrone
@license LicenseRef-INS-1.0
*/


%% value(?Val:atom) is nondet
%
%  The four ethical values in the scenario.
%
value(lifeH).
value(lifeC).
value(freedomH).
value(freedomC).


%% sub(?Values:list, ?Ag:atom) is semidet
%
%  The set of values to which agent Ag subscribes.
%  Hal cares about all four values; Carla only about her own.
%
%  @arg Values list of value atoms
%  @arg Ag     agent atom (hal or carla)
%
sub([lifeH, lifeC, freedomH, freedomC], hal).
sub([lifeC, freedomC], carla).


%% affects(?Attr:atom, ?Val:atom) is semidet
%
%  The attribute that is the direct realiser of value Val.
%  A change in Attr's value in the state corresponds to a change in Val.
%
%  @arg Attr  state attribute (e.g. mh, ic)
%  @arg Val   value realised by that attribute
%  @see state.pl for the attribute vocabulary
%
% attributes([ih,mh,ah,ic,mc,ac])   (see state.pl)
affects(mh, freedomH).
affects(mc, freedomC).
affects(ih, lifeH).
affects(ic, lifeC).
affects(ah, lifeH).
affects(ac, lifeC).


%% better(+Ag:atom, +S1:list, +S2:list, ?Val:atom) is nondet
%
%  Val is promoted for Ag in the transition S1 -> S2:
%  the attribute realising Val was 0 in S1 and is 1 in S2.
%
%  @arg Ag   agent whose value subscription is used
%  @arg S1   initial state
%  @arg S2   resulting state
%  @arg Val  value that is promoted
%
better(Ag, StateA, StateB, Val) :-
    value(Val),
    sub(SetV, Ag),
    member(Val, SetV),
    affects(At, Val),
    attribute(At, StateA, 0),
    attribute(At, StateB, 1).


%% worse(+Ag:atom, +S1:list, +S2:list, ?Val:atom) is nondet
%
%  Val is demoted for Ag in the transition S1 -> S2:
%  the attribute realising Val was 1 in S1 and is 0 in S2.
%
%  @arg Ag   agent whose value subscription is used
%  @arg S1   initial state
%  @arg S2   resulting state
%  @arg Val  value that is demoted
%
worse(Ag, StateA, StateB, Val) :-
    value(Val),
    sub(SetV, Ag),
    member(Val, SetV),
    affects(At, Val),
    attribute(At, StateA, 1),
    attribute(At, StateB, 0).


%% eval(+Ag:atom, +S1:list, +S2:list, -Eval:list) is semidet
%
%  Full value evaluation of the transition S1 -> S2 for agent Ag.
%  Eval is a sorted list of tagged value changes over Ag's subscribed values:
%
%    +Val   — Val is promoted  (better/4)
%    -Val   — Val is demoted   (worse/4)
%    @(Val) — Val is neutral   (neut/4)
%
%  Neutral values are included for completeness: callers that care only
%  about changes can filter on the +/- tags.
%
%  @arg Ag    agent atom
%  @arg S1    initial state
%  @arg S2    resulting state
%  @arg Eval  sorted list of tagged value atoms
%
eval(Ag, S1, S2, Eval) :-
    setof(Val,
          (   promotes(Ag, S1, S2, Val)
          ;   demotes(Ag, S1, S2, Val)
          ;   neutral(Ag, S1, S2, Val)
          ),
          Eval),
    true.


% =========================================================
% Internal helpers — tagged wrappers used by eval/4
% =========================================================

promotes(Ag, S1, S2, +Val) :-
    agent(Ag),
    better(Ag, S1, S2, Val).

demotes(Ag, S1, S2, -Val) :-
    agent(Ag),
    worse(Ag, S1, S2, Val).

neutral(Ag, S1, S2, @(Val)) :-
    agent(Ag),
    neut(Ag, S1, S2, Val).

%  neut(+Ag, +S1, +S2, ?Val) is nondet
%  Val is neutral for Ag: the attribute realising Val has the same value
%  in S1 and S2.
%
neut(Ag, S1, S2, Val) :-
    value(Val),
    sub(SetV, Ag),
    member(Val, SetV),
    affects(At, Val),
    attribute(At, S1, Val1),
    attribute(At, S2, Val2),
    Val1 = Val2.
