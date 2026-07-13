/*  Copyright (c) 2026 Francesco Perrone. All Rights Reserved.
 *  SPDX-License-Identifier: LicenseRef-INS-1.0
 *  See the LICENSE file in the repository root for the full terms.
 */

:- module(jaction, [performj/3]).
:- use_module(library(pldoc)).

/** <module> Joint actions and their pre/post-conditions

Defines the joint-action transition relation performj/3.
A joint action is a pair H-C where H is Hal's individual action and
C is Carla's individual action, executed simultaneously.

Joint actions are written as compound terms using the (-)/2 functor,
e.g., buyH-comC means "Hal buys insulin while Carla compensates".

The same individual-action constraints defined in actions.pl apply
to each component of a joint action independently.  In particular:
  - A dead agent can only contribute doN to a joint action.
  - An agent without insulin that does nothing dies (alive: 1->0).

@see actions.pl for individual action semantics and the full constraint list.
@author Francesco Perrone
@license LicenseRef-INS-1.0
*/


%% performj(?Pre:list, ?Post:list, ?Jac:term) is nondet
%
%  State-transition relation for joint actions.
%  Pre is the precondition state, Post is the resulting state,
%  Jac is the joint action H-C.
%
%  @arg Pre  precondition state (list of six binary values)
%  @arg Post post-condition state (list of six binary values)
%  @arg Jac  joint action term, e.g., buyH-doNC
%  @see perform/3 in actions.pl for individual-action semantics
%  @see trans.pl for multi-step joint sequences via transj/4
%

% --- buyH combined with Carla's actions ---
performj([0,1,1,1,1,1], [1,0,1,1,0,1], buyH-comC).
performj([0,1,1,1,D,1], [1,0,1,1,D,1], buyH-doNC).
performj([0,1,1,C,D,0], [1,0,1,C,D,0], buyH-doNC).
performj([0,1,1,0,D,1], [1,0,1,0,D,0], buyH-doNC).
performj([0,1,1,1,M,A], [1,0,1,0,M,A], buyH-losC).
performj([0,1,1,0,M,1], [1,0,1,1,M,1], buyH-takC).

% --- comH combined with Carla's actions ---
performj([1,1,1,0,1,1], [1,0,1,1,0,1], comH-buyC).
performj([1,1,1,1,M,1], [1,0,1,1,M,1], comH-doNC).
performj([1,1,1,I,M,0], [1,0,1,I,M,0], comH-doNC).
performj([1,1,1,0,M,1], [1,0,1,0,M,0], comH-doNC).
performj([1,1,1,1,M,1], [1,0,1,0,M,1], comH-losC).
performj([1,1,1,0,M,1], [1,0,1,1,M,1], comH-takC).

% --- doNH combined with Carla's actions ---
performj([1,M,1,0,1,1], [1,M,1,1,0,1], doNH-buyC).
performj([I,M,0,0,1,1], [I,M,0,1,0,1], doNH-buyC).
performj([0,M,1,0,1,1], [0,M,0,1,0,1], doNH-buyC).

performj([1,M,1,1,1,1], [1,M,1,1,0,1], doNH-comC).
performj([0,M,1,1,1,1], [0,M,0,1,0,1], doNH-comC).
performj([0,M,1,0,M,1], [0,M,0,1,M,1], doNH-takC).

performj([1,M,1,0,M,1], [1,M,1,1,M,1], doNH-takC).
performj([I,M,0,0,M,1], [I,M,0,1,M,1], doNH-takC).
performj([0,M,1,1,M,1], [0,M,0,0,M,1], doNH-losC).

performj([1,M,1,1,M,1], [1,M,1,0,M,1], doNH-losC).
performj([I,M,0,1,M,1], [I,M,0,0,M,1], doNH-losC).

% --- losH combined with Carla's actions ---
performj([1,M,1,0,1,1], [0,M,1,1,0,1], losH-buyC).
performj([1,M,1,1,1,1], [0,M,1,1,0,1], losH-comC).
performj([1,M,1,1,D,1], [0,M,1,1,D,1], losH-doNC).
performj([1,M,1,C,D,0], [0,M,1,C,D,0], losH-doNC).
performj([1,M,1,0,D,1], [0,M,1,0,D,0], losH-doNC).
performj([1,M,1,0,D,1], [0,M,1,1,D,1], losH-takC).

% --- takH combined with Carla's actions ---
performj([0,M,1,0,1,1], [1,M,1,1,0,1], takH-buyC).
performj([0,M,1,1,1,1], [1,M,1,1,0,1], takH-comC).
performj([0,M,1,1,M,1], [1,M,1,1,M,1], takH-doNC).
performj([0,M,1,I,M,0], [1,M,1,I,M,0], takH-doNC).
performj([0,M,1,0,M,1], [1,M,1,0,M,0], takH-doNC).
performj([0,M,1,1,D,1], [1,M,1,0,D,1], takH-losC).
