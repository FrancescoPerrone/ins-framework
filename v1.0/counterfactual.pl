/*  Copyright (c) 2026 Francesco Perrone. All Rights Reserved.
 *  SPDX-License-Identifier: LicenseRef-INS-1.0
 *  See the LICENSE file in the repository root for the full terms.
 */

:- module(counterfactual, [
    holds/2,
    cf_joint_seq/2,
    counterfactual_holds/3,
    causal_responsible/4
]).

:- use_module(states).
:- use_module(values).
:- use_module(trans).

/** <module> Counterfactual semantics for causal responsibility

Implements a Lewis-style counterfactual layer over the existing AATS
transition function.  The core question is:

  *Was Hal's choice causally necessary for outcome P — i.e., would P have
   failed to hold had Hal instead performed doNH, all else equal?*

This is formalised by holding Carla's action fixed and replacing Hal's
component of every joint action in the sequence with doNH.  This isolates
Hal's individual causal contribution from the joint outcome.

Three theoretical uses of this layer (all described in
docs/notes/counterfactual_extension.md):

  1. **Doing / allowing distinction** — doNH (inaction) is treated
     symmetrically with every other action in the AATS.  Counterfactual
     reasoning makes explicit when Hal's inaction is the proximate cause
     of an outcome, which AS1/AS2 alone cannot express.

  2. **Causal responsibility in joint actions** — for a joint action j = H-C,
     causal_responsible/4 identifies whether H's contribution was necessary
     for the outcome or whether C alone would have produced it.

  3. **AS3 argument scheme** — the counterfactual justification for an action:
     "Perform A rather than doing nothing, because had you done nothing Val
     would have been demoted."  AS3 arguments are constructed in args.pl
     using this module; see argument/4 there.

Note on scope:
  AS3 arguments use joint action sequences (transj/4) and are therefore
  structurally distinct from the individual-sequence arguments of AS1/AS2.
  They are accessible via argument/4 but are deliberately excluded from
  arg/2 so that the Dung / VAF extension layer (extensions.pl, vaf.pl)
  is not affected.  Integration into the extension semantics is left as
  future work.

Note on freedomH:
  The counterfactual layer does not close the freedomH coverage gap
  identified in TODO item 15 and framing_problem.md.  doNH never modifies
  mh, so no AS3 argument for freedomH can be constructed.  This is correct:
  the gap is a structural limit of the action-theoretic model, not a defect
  in the argumentation layer.

@see args.pl for the AS3 clause in argument/4.
@see docs/notes/counterfactual_extension.md for the full theoretical discussion.
@author Francesco Perrone
@license LicenseRef-INS-1.0
*/


% =========================================================
% Propositional vocabulary over states
% =========================================================

%% holds(+Prop:term, +State:list) is semidet
%
%  True if proposition Prop holds in State.
%  Provides a readable propositional interface over the attribute encoding.
%
%  Recognised propositions:
%    alive(hal)         — ah = 1
%    alive(carla)       — ac = 1
%    has_insulin(hal)   — ih = 1
%    has_insulin(carla) — ic = 1
%    has_money(hal)     — mh = 1
%    has_money(carla)   — mc = 1
%
%  @arg Prop  propositional term (see above)
%  @arg State a valid state list (six binary values)
%  @see attribute/3 in states.pl
%
holds(alive(hal),         S) :- attribute(ah, S, 1).
holds(alive(carla),       S) :- attribute(ac, S, 1).
holds(has_insulin(hal),   S) :- attribute(ih, S, 1).
holds(has_insulin(carla), S) :- attribute(ic, S, 1).
holds(has_money(hal),     S) :- attribute(mh, S, 1).
holds(has_money(carla),   S) :- attribute(mc, S, 1).


% =========================================================
% Counterfactual construction
% =========================================================

%% cf_joint_seq(+Jacs:list, -CfJacs:list) is det
%
%  Constructs the counterfactual joint action sequence by replacing
%  Hal's component in every joint action with doNH, holding Carla's
%  action fixed.
%
%  This implements the Lewis-style intervention: "what would have
%  happened had Hal done nothing at each step?"
%
%  @arg Jacs   list of joint action terms H-C
%  @arg CfJacs list of joint action terms doNH-C (same Carla actions)
%
cf_joint_seq([], []).
cf_joint_seq([_H-C | Rest], [doNH-C | CfRest]) :-
    cf_joint_seq(Rest, CfRest).


% =========================================================
% Counterfactual predicate
% =========================================================

%% counterfactual_holds(+Q:list, +J:list, +P:term) is semidet
%
%  True if:
%    (a) proposition P holds in the state reached by joint action
%        sequence J from state Q, AND
%    (b) P would NOT hold had Hal performed doNH at every step
%        (counterfactual), keeping Carla's actions fixed.
%
%  Captures the Lewisian reading: "P holds in the actual outcome and
%  would not hold in the closest possible world where Hal does nothing."
%
%  @arg Q  initial state (list of six binary values)
%  @arg J  list of joint action terms H-C  (length N)
%  @arg P  propositional term (see holds/2)
%  @see cf_joint_seq/2
%
counterfactual_holds(Q, J, P) :-
    length(J, N),
    transj(Q, J, Q1, N),
    holds(P, Q1),
    cf_joint_seq(J, JCf),
    transj(Q, JCf, Q2, N),
    \+ holds(P, Q2).


% =========================================================
% Causal responsibility
% =========================================================

%% causal_responsible(+Ag:atom, +Q:list, +J:list, +P:term) is semidet
%
%  True if agent Ag's action choice in joint sequence J from state Q
%  was causally necessary for proposition P — i.e., P holds in the
%  actual outcome but would not hold in the counterfactual where Ag
%  performs doNH at every step.
%
%  Currently only hal is supported as Ag; the counterfactual substitutes
%  Hal's component with doNH (see cf_joint_seq/2).
%
%  Example:
%  ==
%  % Was Hal causally responsible for staying alive, given he bought
%  % insulin from Carla in state [0,1,1,1,1,1]?
%  ?- causal_responsible(hal, [0,1,1,1,1,1], [buyH-doNC, doNH-doNC], alive(hal)).
%  ==
%
%  @arg Ag  agent atom (currently only hal)
%  @arg Q   initial state
%  @arg J   joint action sequence
%  @arg P   propositional term
%
causal_responsible(hal, Q, J, P) :-
    counterfactual_holds(Q, J, P).
