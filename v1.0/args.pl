/*  Copyright (c) 2026 Francesco Perrone. All Rights Reserved.
 *  SPDX-License-Identifier: LicenseRef-INS-1.0
 *  See the LICENSE file in the repository root for the full terms.
 */

:- module(args, [arg/2, argument/3, argument/4, attacks/2]).
:- use_module(library(pldoc)).
:- use_module(counterfactual).

/** <module> Argument construction and attack relation.

Implements AS1 (positive), AS2 (negative), and AS3 (counterfactual)
argument schemes.

  AS1 — In circumstances R, perform A, leading to S, realising G,
         promoting value V.
         (Atkinson & Bench-Capon 2006)

  AS2 — In circumstances R, perform A, to avoid S, which would
         demote value V.
         (Atkinson & Bench-Capon 2006)

  AS3 — In circumstances R, perform joint action J (rather than doing
         nothing), because had Hal done nothing Val would have been
         demoted, even if J does not itself positively promote Val.
         (Counterfactual extension; see counterfactual.pl)

AS1 and AS2 use individual action sequences (trans/4) for Hal and
joint sequences (transj/4) for Carla.

AS3 uses joint action sequences (transj/4) for Hal exclusively,
since the counterfactual — "what if Hal had done doNH?" — requires
holding Carla's action fixed.  AS3 argument terms are therefore
structurally distinct from AS1/AS2 argument terms (joint vs. individual
sequences), and are NOT included in arg/2.  The Dung/VAF extension layer
(extensions.pl, vaf.pl) is unaffected.

argument/4 is the primary predicate; argument/3 and arg/2 are
backward-compatible wrappers retained so attacks/2, extensions.pl,
and vaf.pl need no changes.

@see counterfactual.pl
@author Francesco Perrone
@license LicenseRef-INS-1.0
*/


%% argument(+Ag, -Acts, -Val, -Scheme) is nondet
%
%  Constructs arguments for agent Ag under scheme Scheme.
%
%  Scheme in {as1, as2, as3}:
%    as1 — Acts promotes Val (positive; individual seqs for Hal, joint for Carla)
%    as2 — Acts protects Val from demotion (negative; same sequence types)
%    as3 — Acts is counterfactually justified for Val: had Hal done doNH
%           Val would have been demoted (Hal only; joint seqs; see counterfactual.pl)
%
%  Note: AS1 and AS2 are mutually exclusive for a given (Init, Val) pair,
%  but not at the (Acts, Val) level: the same sequence may appear under
%  both schemes across different initial states.
%
%  AS3 argument terms are joint action sequences; they are structurally
%  distinct from AS1/AS2 terms and are not included in arg/2.
%
%  @arg Ag     Agent: hal or carla
%  @arg Acts   2-step action sequence (individual for AS1/AS2 Hal; joint for AS3 and Carla)
%  @arg Val    Value promoted, protected, or counterfactually justified
%  @arg Scheme as1, as2, or as3

% --- Hal AS1 ---
argument(hal, Acts, Val, as1) :-
    setof(Acts-Val,
          Init^Next^(initial_state(Init),
                     trans(Init, Acts, Next, 2),
                     better(hal, Init, Next, Val)),
          Pairs),
    member(Acts-Val, Pairs).

% --- Hal AS2 ---
argument(hal, Acts, Val, as2) :-
    value(Val),
    setof(Acts,
          Init^Next^Alt^AltNext^(
              initial_state(Init),
              trans(Init, Acts, Next, 2),
              \+ worse(hal, Init, Next, Val),
              trans(Init, Alt, AltNext, 2),
              worse(hal, Init, AltNext, Val)
          ),
          ActsList),
    member(Acts, ActsList).

% --- Carla AS1 ---
argument(carla, Acts, Val, as1) :-
    setof(Acts-Val,
          Init^Next^(initial_state(Init),
                     transj(Init, Acts, Next, 2),
                     better(carla, Init, Next, Val)),
          Pairs),
    member(Acts-Val, Pairs).

% --- Carla AS2 ---
argument(carla, Acts, Val, as2) :-
    value(Val),
    setof(Acts,
          Init^Next^Alt^AltNext^(
              initial_state(Init),
              transj(Init, Acts, Next, 2),
              \+ worse(carla, Init, Next, Val),
              transj(Init, Alt, AltNext, 2),
              worse(carla, Init, AltNext, Val)
          ),
          ActsList),
    member(Acts, ActsList).


% --- Hal AS3 (counterfactual) ---
%
% Acts is a 2-step joint action sequence.
% Val is counterfactually justified if:
%   (a) Acts does not demote Val in the actual outcome, AND
%   (b) had Hal done doNH at every step (keeping Carla fixed),
%       Val would have been demoted.
%
argument(hal, Acts, Val, as3) :-
    value(Val),
    setof(Acts-Val,
          Init^Next^CfActs^CfNext^(
              initial_state(Init),
              transj(Init, Acts, Next, 2),
              \+ worse(hal, Init, Next, Val),
              cf_joint_seq(Acts, CfActs),
              transj(Init, CfActs, CfNext, 2),
              worse(hal, Init, CfNext, Val)
          ),
          Pairs),
    member(Acts-Val, Pairs).


%% argument(+Ag, -Acts, -Val) is nondet
%
%  Backward-compatible wrapper: strips the scheme tag.
%  Retained so dbg.pl and other callers need minimal changes.
%
argument(Ag, Acts, Val) :- argument(Ag, Acts, Val, _).


%% arg(-Acts, -Val) is nondet
%
%  Wrapper used by attacks/2, extensions.pl, and vaf.pl.
%  Includes both AS1 and AS2 arguments for Hal.
%  The labelling-based algorithm in extensions.pl (O(2^k) in ambiguous
%  arguments) is efficient enough to handle the larger combined set.
%
arg(Acts, Val) :- argument(hal, Acts, Val, _).


%% attacks(+A, +B) is nondet
%
%  Argument A attacks argument B when they advocate different action
%  sequences. The attack relation is symmetric and scheme-agnostic.
%
attacks(arg(Acts, V1), arg(ActsX, V2)) :-
    arg(Acts, V1),
    arg(ActsX, V2),
    Acts \= ActsX.
