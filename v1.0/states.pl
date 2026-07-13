/*  Copyright (c) 2026 Francesco Perrone. All Rights Reserved.
 *  SPDX-License-Identifier: LicenseRef-INS-1.0
 *  See the LICENSE file in the repository root for the full terms.
 */

:- module(state, [agent/1, state/1, attributes/1, attribute/3]).
:- use_module(library(pldoc)).

/** <module> Agent state representation

Defines the two agents (Hal and Carla) and the structure of their shared
world state.  A state is a fixed-length list of binary attribute values,
ordered according to attributes/1.

The canonical ordering is <ih, mh, ah, ic, mc, ac>:

  ih — Hal has insulin     (1 = yes, 0 = no)
  mh — Hal has money       (1 = yes, 0 = no)
  ah — Hal is alive        (1 = yes, 0 = no)
  ic — Carla has insulin   (1 = yes, 0 = no)
  mc — Carla has money     (1 = yes, 0 = no)
  ac — Carla is alive      (1 = yes, 0 = no)

All attribute values are binary: 1 (true) or 0 (false).

@author Francesco Perrone
@license LicenseRef-INS-1.0
*/


%% agent(?Ag:atom) is semidet
%
%  The two agents in the scenario.
%
agent(hal).
agent(carla).


%% attributes(?List:list) is det
%
%  The canonical ordered list of state attributes.
%  The position of each attribute in this list defines its index
%  inside every state term, and is relied upon by attribute/3.
%
%  @arg List fixed list [ih, mh, ah, ic, mc, ac]
%  @see domain/2
%
attributes([ih,mh,ah,ic,mc,ac]).


%% domain(?Name:atom, ?Domain:list) is semidet
%
%  Binary domain for each attribute.
%  Every attribute takes a value in {1, 0}.
%
%  @arg Name  ground atom identifying the attribute
%  @arg Domain list of admissible values (always [1, 0])
%
domain(ih, [1,0]).
domain(mh, [1,0]).
domain(ah, [1,0]).
domain(ic, [1,0]).
domain(mc, [1,0]).
domain(ac, [1,0]).


%% state(?State:list) is nondet
%
%  True if State is a valid world state: a list of attribute values
%  ordered as in attributes/1, each value drawn from its domain.
%  Generates all 2^6 = 64 valid states on backtracking.
%
%  @arg State list of six binary values
%  @see attributes/1
%  @see domain/2
%
state(State) :-
    attributes(Attributes),
    state_aux(Attributes, State).


% =========================================================
% Internal helpers
% =========================================================

%  state_aux(+Attrs:list, -State:list) is nondet
%
%  Recursively pairs each attribute with a value from its domain,
%  building the state list in attribute order.
%
state_aux([], []).
state_aux([Attribute|Attributes], [Val|Values]) :-
    domain(Attribute, Dom),
    member(Val, Dom),
    state_aux(Attributes, Values).


%  attribute(+Attr:atom, +State:list, ?Val) is semidet
%
%  Retrieves (or checks) the value of attribute Attr in State.
%  Uses the canonical attribute ordering from attributes/1 to locate
%  the correct position.
%
%  @arg Attr  name of the attribute (e.g. ih, ac)
%  @arg State a valid state list
%  @arg Val   the value of Attr in State
%
attribute(Attribute, State, Val) :-
    attributes(Attributes),
    attribute_aux(Attribute, Attributes, State, Val).

attribute_aux(Attribute, [Attribute|_], [Val|_], Val) :-
    domain(Attribute, Dom),
    member(Val, Dom).
attribute_aux(Attribute, [_|MoreAttributes], [_|RestStates], Val) :-
    attribute_aux(Attribute, MoreAttributes, RestStates, Val).
