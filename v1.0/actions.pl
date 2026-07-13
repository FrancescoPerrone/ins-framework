/*  Copyright (c) 2026 Francesco Perrone. All Rights Reserved.
 *  SPDX-License-Identifier: LicenseRef-INS-1.0
 *  See the LICENSE file in the repository root for the full terms.
 */

:- module(act, [perform/3]).
:- use_module(library(pldoc)).

/** <module> Individual actions and their pre/post-conditions

Defines the set of individual actions available to Hal and the
state-transition relation perform/3.

Available actions:

  buyH  — Hal buys insulin from Carla (Hal: 0->1 insulin, money 1->0)
  comH  — Hal compensates Carla (gives money; Carla: money 1->0 or 0->1)
  takH  — Hal takes insulin from Carla (Hal: 0->1, Carla: 1->0)
  losH  — Hal loses insulin (Hal: 1->0; voluntary or accidental)
  doNH  — Hal does nothing

Constraints (see inline NOTICEs):
  1. Only an agent with money can perform comH.
  2. comH means Hal buys Carla insulin, or gives money if she already has it.
  3. Any agent may always perform doN (do nothing).
  4. A dead agent (alive = 0) can only perform doN.
  5. An agent dies if it lacks insulin and performs doN.

Usage example:
==
?- perform(Init, Fin, buyH).
Init = [0, 1, 1, _A, _B, _C],
Fin  = [1, 0, 1, _A, _B, _C].
==

@author Francesco Perrone
@license LicenseRef-INS-1.0
*/


%% perform(?Pre:list, ?Post:list, ?Act:atom) is nondet
%
%  State-transition relation for individual actions.
%  Pre is the precondition state, Post is the resulting state,
%  Act is the action name.
%
%  Uninstantiated positions in Pre/Post are free variables, meaning
%  those attributes are unconstrained by the action.
%
%  @arg Pre  precondition state (list of six binary values)
%  @arg Post post-condition state (list of six binary values)
%  @arg Act  action atom (buyH, comH, takH, losH, doNH)
%  @see jactions.pl for joint-action counterparts
%  @see trans.pl for multi-step sequences
%
% buyH: Hal buys insulin — requires Hal has money (mh=1) and is alive (ah=1);
%       Hal gains insulin (ih: 0->1), spends money (mh: 1->0).
perform([0,1,1,I,M,A], [1,0,1,I,M,A], buyH).

% comH: Hal compensates Carla — requires Hal has insulin, money, and is alive,
%       and Carla is alive.  Two clauses cover giving money vs. giving insulin.
perform([1,1,1,0,M,1], [1,0,1,1,M,1], comH).
perform([1,1,1,1,_,1], [1,0,1,1,1,1], comH).

% takH: Hal takes insulin from Carla — requires Hal has no insulin (ih=0),
%       Carla has insulin (ic=1) and is alive (ac=1).
perform([0,D,1,1,M,1], [1,D,1,0,M,1], takH).

% losH: Hal loses insulin — Hal must currently have insulin (ih=1).
perform([1,D,1,I,M,A], [0,D,1,I,M,A], losH).

% doNH: Hal does nothing — three clauses cover the cases where Hal
%       is alive with insulin, already dead, or alive without insulin
%       (the last results in death: ah: 1->0).
perform([1,D,1,I,M,A], [1,D,1,I,M,A], doNH).
perform([C,D,0,I,M,A], [C,D,0,I,M,A], doNH).
perform([0,D,1,I,M,A], [0,D,0,I,M,A], doNH).
