/*  Copyright (c) 2026 Francesco Perrone. All Rights Reserved.
 *  SPDX-License-Identifier: LicenseRef-INS-1.0
 *  See the LICENSE file in the repository root for the full terms.
 */

/** <module> Debug and regression-test runner

Loads the entire INS module stack and exercises each layer in order,
printing labelled output to standard output.  Intended to be run with:

==
$ swipl dbg.pl
==

Test sections (numbered for reference in output):
  1.  Valid states               — all 64 states via state/1
  2.  Initial states             — morally relevant starting configurations
  3.  1-step individual transitions
  4.  2-step individual transitions
  5.  Value evaluations (Hal)
  6.  All arguments (Hal, both schemes)
  7.  Attack relation
  8.  Grounded extension         — Dung (1995)
  9.  Preferred extensions       — Dung (1995)
  10. Stable extensions          — Dung (1995)
  11. VAF extensions per audience — Bench-Capon (2003)
  12. 1-step joint transitions
  13. Value evaluations (Carla, joint)
  14. Carla's arguments (both schemes)
  15. AS2 arguments (both agents)
  16. Credulous acceptance (Dung)  — φ₁ proof
  17. Sceptical acceptance (Dung)
  18. Credulous acceptance (VAF, altruistic audience)
  19. AS3 arguments (counterfactual, Hal)
  20. Causal responsibility (alive(hal))
  21. counterfactual_holds spot-checks
  22. Value weights and distances (possible worlds)
  23. Lewis and Stalnaker conditionals per audience

@author Francesco Perrone
@license LicenseRef-INS-1.0
*/

:- use_module(states).
:- use_module(actions).
:- use_module(jactions).
:- use_module(trans).
:- use_module(values).
:- use_module(counterfactual).
:- use_module(possible_worlds).
:- use_module(args).
:- use_module(extensions).
:- use_module(vaf).
:- use_module(credulous).


%           Starts the PlDoc services

:- doc_server(_).
:- doc_collect(true).
:- portray_text(true).


%           Tests

% 1. Enumerate all valid states
:- format("~n--- Valid states ---~n"),
   forall(state(S), format("state: ~w~n", [S])).

% 2. Show all initial states
:- format("~n--- Initial states ---~n"),
   forall(initial_state(S), format("initial: ~w~n", [S])).

% 3. Show all 1-step transitions from each initial state
:- format("~n--- 1-step transitions from initial states ---~n"),
   forall((initial_state(Init), perform(Init, Next, Act)),
          format("~w --[~w]--> ~w~n", [Init, Act, Next])).

% 4. Show all 2-step action sequences from initial states
:- format("~n--- 2-step transitions ---~n"),
   forall((initial_state(Init), trans(Init, Acts, Next, 2)),
          format("~w --~w--> ~w~n", [Init, Acts, Next])).

% 5. Evaluate state pairs for Hal
:- format("~n--- Value evaluations (hal) ---~n"),
   forall((initial_state(S1), perform(S1, S2, _),
           eval(hal, S1, S2, Eval)),
          format("~w -> ~w : ~w~n", [S1, S2, Eval])).

% 6. List all arguments
:- format("~n--- Arguments ---~n"),
   forall(arg(Acts, Val),
          format("arg(~w, ~w)~n", [Acts, Val])).

% 7. List all attacks between arguments
:- format("~n--- Attacks ---~n"),
   forall(attacks(A1, A2),
          format("~w attacks ~w~n", [A1, A2])).


% 8. Grounded extension
:- format("~n--- Grounded extension ---~n"),
   grounded_extension(Ext),
   format("grounded: ~w~n", [Ext]).

% 9. Preferred extensions
:- format("~n--- Preferred extensions ---~n"),
   forall(preferred_extension(Ext),
          format("preferred: ~w~n", [Ext])).

% 10. Stable extensions
:- format("~n--- Stable extensions ---~n"),
   forall(stable_extension(Ext),
          format("stable: ~w~n", [Ext])).


% 11. VAF defeats and preferred extensions per audience
:- format("~n--- VAF: defeats and preferred extensions by audience ---~n"),
   forall(audience(Aud, Order),
          (format("~naudience(~w): ~w~n", [Aud, Order]),
           format("  defeats:~n"),
           forall(defeats(A, B, Aud),
                  format("    ~w defeats ~w~n", [A, B])),
           format("  grounded: "),
           vaf_grounded_extension(GExt, Aud),
           format("~w~n", [GExt]),
           format("  preferred extensions:~n"),
           forall(vaf_preferred_extension(Ext, Aud),
                  format("    ~w~n", [Ext])))).


% 12. Show all 1-step joint transitions from initial states
:- format("~n--- 1-step joint transitions from initial states ---~n"),
   forall((initial_state(Init), performj(Init, Next, Jac)),
          format("~w --[~w]--> ~w~n", [Init, Jac, Next])).

% 13. Value evaluations for Carla (via joint transitions)
:- format("~n--- Value evaluations (carla, joint transitions) ---~n"),
   forall((initial_state(S1), performj(S1, S2, _),
           eval(carla, S1, S2, Eval)),
          format("~w -> ~w : ~w~n", [S1, S2, Eval])).

% 14. Carla's arguments (joint action sequences, both schemes)
:- format("~n--- Carla's arguments ---~n"),
   forall(argument(carla, Acts, Val, Scheme),
          format("argument(carla, ~w, ~w, ~w)~n", [Acts, Val, Scheme])).

% 15. All AS2 arguments (both agents)
:- format("~n--- AS2 arguments (both agents) ---~n"),
   forall((member(Ag, [hal, carla]), argument(Ag, Acts, Val, as2)),
          format("argument(~w, ~w, ~w, as2)~n", [Ag, Acts, Val])).


% 16. Credulous acceptance (Dung) — sample: one proof per accepted argument
:- format("~n--- Credulous acceptance (Dung preferred semantics) ---~n"),
   forall(
       (arg(Acts, Val), credQA(arg(Acts,Val), (Seq,_))),
       format("credulous: arg(~w,~w)~n  proof: ~w~n", [Acts, Val, Seq])
   ).

% 17. Sceptical acceptance (Dung)
:- format("~n--- Sceptical acceptance (Dung preferred semantics) ---~n"),
   forall(
       (arg(Acts, Val), sceptically_accepted(arg(Acts,Val))),
       format("sceptical: arg(~w,~w)~n", [Acts, Val])
   ).

% 18. Credulous acceptance under VAF (one audience as illustration)
:- format("~n--- Credulous acceptance (VAF, altruistic audience) ---~n"),
   forall(
       (arg(Acts, Val), vaf_credQA(arg(Acts,Val), altruistic, (Seq,_))),
       format("credulous/altruistic: arg(~w,~w)~n  proof: ~w~n", [Acts, Val, Seq])
   ).


% 19. AS3 arguments (counterfactual justification, Hal only)
:- format("~n--- AS3 arguments (counterfactual, Hal) ---~n"),
   forall(argument(hal, Acts, Val, as3),
          format("argument(hal, ~w, ~w, as3)~n", [Acts, Val])).

% 20. Causal responsibility: for each AS3 argument, show the initial state
%     from which Hal's contribution was causally necessary for the outcome
:- format("~n--- Causal responsibility (sample: alive(hal)) ---~n"),
   forall(
       (initial_state(Q),
        argument(hal, Acts, _, as3),
        causal_responsible(hal, Q, Acts, alive(hal))),
       format("causal: hal responsible for alive(hal) via ~w from ~w~n", [Acts, Q])
   ).

% 21. counterfactual_holds spot-checks
:- format("~n--- counterfactual_holds spot-checks ---~n"),
   forall(
       (initial_state(Q),
        member(P, [alive(hal), alive(carla), has_insulin(hal)]),
        argument(hal, Acts, _, as3),
        counterfactual_holds(Q, Acts, P)),
       format("cf_holds(~w, ~w, ~w)~n", [Q, Acts, P])
   ).


% 22. Value weights and distances (possible worlds layer)
:- format("~n--- Value weights per audience (possible worlds) ---~n"),
   forall(vaf:audience(Aud, Order),
          (format("~naudience(~w): ~w~n", [Aud, Order]),
           forall(member(Val, Order),
                  (value_weight(Aud, Val, W),
                   format("  value_weight(~w, ~w) = ~w~n", [Aud, Val, W]))))).

:- format("~n--- Distance spot-checks (selfish vs altruistic) ---~n"),
   Actual = [1,1,1,0,1,1],
   forall(
       member(Aud, [selfish, altruistic]),
       (forall(
            (member(W, [[0,1,1,0,1,1],
                        [1,0,1,0,1,1],
                        [1,1,0,0,1,1],
                        [1,1,1,0,0,1],
                        [1,1,1,0,1,0]]),
             value_distance(Actual, W, Aud, D)),
            format("  d_~w(~w, ~w) = ~w~n", [Aud, Actual, W, D])))
   ).


% 23. Lewis and Stalnaker conditionals per audience
%
%     Query A — [0,1,1,1,1,1], [buyH-losC,doNH-buyC]:
%     "Had Hal lacked insulin (after this sequence), would he be dead?"
%     Unique closest world across all audiences; Lewis = Stalnaker.
%
%     Query B — [0,0,1,1,1,1], [takH-comC,losH-doNC]:
%     "Had Carla lacked insulin, would Hal be dead?"
%     Under life_first/altruistic/freedom_first: 3, 2, 2 tied worlds; the first
%     sorted world has Hal dead (ah=0) but the others do not — Stalnaker
%     returns TRUE, Lewis returns FALSE.  Under selfish: 1 world, both agree.
%     This is the canonical demonstration that Lewis and Stalnaker can diverge
%     within the same finite AATS world space.
:- format("~n--- Lewis conditionals (Query A: unique closest world) ---~n"),
   Q = [0,1,1,1,1,1],
   J = [buyH-losC, doNH-buyC],
   transj(Q, J, Actual, 2),
   format("actual outcome: ~w~n", [Actual]),
   forall(
       vaf:audience(Aud, _),
       (closest_worlds(Q, Actual, hal_lacks_insulin, Aud, Closest),
        length(Closest, NW),
        (   (lewis_would(Q, J, hal_lacks_insulin, hal_dead, Aud)
            ->  Res = true ; Res = false),
            format("~w (~w world(s)): lewis(hal_lacks_insulin -> hal_dead) = ~w~n",
                   [Aud, NW, Res])
        )
       )
   ).

%     Query B: canonical Lewis/Stalnaker divergence example.
:- format("~n--- Lewis vs Stalnaker divergence (Query B) ---~n"),
   Q = [0,0,1,1,1,1],
   J = [takH-comC, losH-doNC],
   transj(Q, J, Actual, 2),
   format("actual outcome: ~w~n", [Actual]),
   forall(
       vaf:audience(Aud, _),
       (closest_worlds(Q, Actual, carla_lacks_insulin, Aud, Closest),
        length(Closest, NTies),
        (   (lewis_would(Q, J, carla_lacks_insulin, hal_dead, Aud)
            ->  LR = true ; LR = false),
            (   (stalnaker_would(Q, J, carla_lacks_insulin, hal_dead, Aud)
                ->  SR = true ; SR = false),
                (LR \= SR
                ->  format("~w (~w worlds): lewis=~w stalnaker=~w [DIVERGE]~n",
                           [Aud, NTies, LR, SR])
                ;   format("~w (~w worlds): lewis=stalnaker=~w~n",
                           [Aud, NTies, LR])
                )
            )
        )
       )
   ).


%           Listener
