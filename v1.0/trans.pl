/*  Copyright (c) 2026 Francesco Perrone. All Rights Reserved.
 *  SPDX-License-Identifier: LicenseRef-INS-1.0
 *  See the LICENSE file in the repository root for the full terms.
 */

:- module(trans, [trans/4, transj/4, initial_state/1]).

:- use_module(jactions).

/** <module> State transitions and initial states

Defines the set of morally relevant initial states and provides
multi-step transition predicates for individual (trans/4) and
joint (transj/4) action sequences.

Three families of initial states are defined, each capturing a
different morally relevant starting configuration:

  1. Hal lacks insulin; Carla has it — the paradigm case where Hal
     must acquire insulin to survive.

  2. Carla lacks insulin; Hal has both insulin and money — Hal is in
     a position to help Carla (promotes lifeC).

  3. Carla lacks money; Hal has everything — Hal can compensate Carla
     financially (promotes freedomC).

@see actions.pl
@see jactions.pl
@author Francesco Perrone
@license LicenseRef-INS-1.0
*/


%% initial_state(?Init:list) is nondet
%
%  True if Init is a morally relevant initial state.
%  Generates all valid instantiations of each initial-state template
%  on backtracking (free variables are filled by state/1).
%
%  @arg Init a valid state list (six binary values)
%  @see state/1 in states.pl
%
% Hal lacks insulin; Carla has it.
initial_state(Init) :-
    Init = [0,_,1,1,_,1],
    state(Init).

% Carla lacks insulin; Hal has insulin and money and can give it.
initial_state(Init) :-
    Init = [1,1,1,0,_,1],
    state(Init).

% Carla lacks money; Hal has everything and can compensate.
initial_state(Init) :-
    Init = [1,1,1,1,0,1],
    state(Init).


%% trans(+Init:list, +Acts:list, -Next:list, +N:integer) is nondet
%
%  N-step individual-action transition from Init to Next following
%  the action sequence Acts (a list of N action atoms).
%
%  @arg Init  starting state
%  @arg Acts  list of N individual action atoms
%  @arg Next  state reached after all N actions
%  @arg N     number of steps (positive integer)
%  @see perform/3 in actions.pl
%
trans(Init, [Act], Next, 1) :-
    perform(Init, Next, Act).
trans(Init, [Act|Rest], Next, N) :-
    N > 1,
    Step is N - 1,
    perform(Init, X, Act),
    trans(X, Rest, Next, Step).


%% transj(+Init:list, +Jacs:list, -Next:list, +N:integer) is nondet
%
%  N-step joint-action transition from Init to Next following the
%  joint-action sequence Jacs (a list of N H-C terms).
%
%  @arg Init  starting state
%  @arg Jacs  list of N joint action terms (e.g. [buyH-doNC, doNH-comC])
%  @arg Next  state reached after all N joint actions
%  @arg N     number of steps (positive integer)
%  @see performj/3 in jactions.pl
%
transj(Init, [Jac], Next, 1) :-
    performj(Init, Next, Jac).
transj(Init, [Jac|Rest], Next, N) :-
    N > 1,
    Step is N - 1,
    performj(Init, X, Jac),
    transj(X, Rest, Next, Step).
