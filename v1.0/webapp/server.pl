/*  Copyright (c) 2026 Francesco Perrone. All Rights Reserved.
 *  SPDX-License-Identifier: LicenseRef-INS-1.0
 *  See the LICENSE file in the repository root for the full terms.
 */

/** <module> HTTP server and JSON API for the INS web application

Starts an SWI-Prolog HTTP server that exposes the full INS reasoning
stack as a JSON REST API and serves the HTML/JS frontend.

Start the server (default port 8000):
==
$ swipl webapp/server.pl
==
or from the SWI-Prolog top-level:
==
?- server(8000).
==
Then open http://127.0.0.1:8000/ in a browser.

Routes:

  GET /
    Serves index.html from the webapp directory.

  GET /args
    All arguments for both agents (Hal and Carla), with scheme tags.
    Each entry: {"agent":"...","actions":[...],"value":"...","scheme":"as1"|"as2"}.

  GET /attacks
    All attack pairs between arguments.
    Each entry: {"attacker":<arg>,"attacked":<arg>}.

  GET /extensions
    Dung (1995) grounded, preferred, and stable extensions.
    {"grounded":[...],"preferred":[[...],...],"stable":[[...],...]}.

  GET /vaf
    All named audiences and their value orderings.

  GET /vaf/:audience
    VAF preferred extensions for the named audience (Bench-Capon 2003).
    {"audience":"...","order":[...],"preferred":[[...],...]}.

  GET /vaf/:audience/grounded
    VAF grounded extension for the named audience.
    {"audience":"...","grounded":[...]}.

  GET /credulous
    All credulously accepted arguments under Dung preferred semantics,
    each with its φ₁ dialectical proof (Cayrol, Doutre & Mengin 2003).
    [{"actions":[...],"value":"...","proof":[...]}, ...]

  GET /credulous/sceptical
    All sceptically accepted arguments (present in every preferred extension).

  GET /credulous/vaf/:audience
    Credulously accepted arguments under VAF semantics for audience.

  GET /counterfactual
    All AS3 (counterfactual) arguments for Hal with their witness states.
    Each entry: {"actions":[...],"value":"...","actual":{...},"counterfactual":{...}}.

  GET /counterfactual/causal/:prop
    All (state, sequence) pairs where Hal is causally responsible for
    proposition prop.  Prop is one of: alive_hal, alive_carla,
    has_insulin_hal, has_insulin_carla, has_money_hal, has_money_carla.

@see args.pl, extensions.pl, vaf.pl, credulous.pl, counterfactual.pl
@author Francesco Perrone
@license LicenseRef-INS-1.0
*/

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_files)).

% Capture the webapp directory at load time so handle_root can find index.html.
:- dynamic webapp_dir/1.
:- prolog_load_context(file, F), file_directory_name(F, D), assertz(webapp_dir(D)).

:- use_module('../states').
:- use_module('../actions').
:- use_module('../jactions').
:- use_module('../trans').
:- use_module('../values').
:- use_module('../counterfactual').
:- use_module('../args').
:- use_module('../extensions').
:- use_module('../vaf').
:- use_module('../credulous').

% Routes
:- http_handler(root(.),              handle_root,              []).
:- http_handler(root(args),           handle_args,              []).
:- http_handler(root(attacks),        handle_attacks,           []).
:- http_handler(root(extensions),     handle_extensions,        []).
:- http_handler(root(vaf),            handle_vaf,               [prefix]).
:- http_handler(root(credulous),      handle_credulous,         [prefix]).
:- http_handler(root(counterfactual), handle_counterfactual,    [prefix]).


%% server(+Port:integer) is det
%
%  Starts the HTTP server on Port and blocks until the process is killed.
%
%  @arg Port TCP port number (e.g. 8000)
%
server(Port) :-
    http_server(http_dispatch, [port(Port)]),
    thread_get_message(_).

:- initialization(server(8000), main).


% =========================================================
% Route handlers
% =========================================================

% GET /
handle_root(Request) :-
    webapp_dir(Dir),
    atom_concat(Dir, '/index.html', Index),
    http_reply_file(Index, [unsafe(true)], Request).


% GET /args
% All arguments for all agents.
% Hal uses individual action sequences; Carla uses joint action sequences.
% Each entry is {"agent": "...", "actions": [...], "value": "...", "scheme": "as1"|"as2"}.
handle_args(_Request) :-
    findall(J, (member(Ag, [hal, carla]),
                argument(Ag, Acts, Val, Scheme),
                arg_json(Ag, Acts, Val, Scheme, J)),
            Args),
    reply_json(Args).


% GET /attacks
% All attack pairs between arguments.
% Each entry is {"attacker": <arg>, "attacked": <arg>}.
handle_attacks(_Request) :-
    findall(json([attacker=JA, attacked=JB]),
            (attacks(arg(A1,V1), arg(A2,V2)),
             arg_to_json(arg(A1,V1), JA),
             arg_to_json(arg(A2,V2), JB)),
            Attacks),
    reply_json(Attacks).


% GET /extensions
% Dung (1995) grounded, preferred, and stable extensions.
% An extension is a list of arguments; preferred and stable return
% a list of such lists.
handle_extensions(_Request) :-
    grounded_extension(Grounded),
    findall(E, preferred_extension(E), Preferred),
    findall(E, stable_extension(E),    Stable),
    ext_json(Grounded, GroundedJSON),
    maplist(ext_json, Preferred, PreferredJSON),
    maplist(ext_json, Stable,    StableJSON),
    reply_json(json([
        grounded  = GroundedJSON,
        preferred = PreferredJSON,
        stable    = StableJSON
    ])).


% GET /vaf  and  GET /vaf/:audience  and  GET /vaf/:audience/grounded
handle_vaf(Request) :-
    (   memberchk(path_info(PathInfo), Request),
        atom_concat('/', Rest, PathInfo),
        Rest \= ''
    ->  atomic_list_concat(Parts, '/', Rest),
        handle_vaf_path(Parts)
    ;   findall(json([audience=A, order=O]), audience(A, O), Auds),
        reply_json(Auds)
    ).

handle_vaf_path([Aud]) :-
    !,
    handle_vaf_audience(Aud).
handle_vaf_path([Aud, grounded]) :-
    !,
    handle_vaf_grounded(Aud).
handle_vaf_path(_) :-
    reply_json(json([error='not found']), [status(404)]).

handle_vaf_audience(Aud) :-
    (   audience(Aud, Order)
    ->  findall(E, vaf_preferred_extension(E, Aud), Exts),
        maplist(ext_json, Exts, ExtsJSON),
        reply_json(json([
            audience  = Aud,
            order     = Order,
            preferred = ExtsJSON
        ]))
    ;   reply_json(json([error='unknown audience', audience=Aud]), [status(404)])
    ).

handle_vaf_grounded(Aud) :-
    (   audience(Aud, _)
    ->  vaf_grounded_extension(Grounded, Aud),
        ext_json(Grounded, GroundedJSON),
        reply_json(json([
            audience = Aud,
            grounded = GroundedJSON
        ]))
    ;   reply_json(json([error='unknown audience', audience=Aud]), [status(404)])
    ).


% GET /credulous  and  GET /credulous/sceptical  and  GET /credulous/vaf/:audience
handle_credulous(Request) :-
    (   memberchk(path_info(PathInfo), Request),
        atom_concat('/', Rest, PathInfo),
        Rest \= ''
    ->  atomic_list_concat(Parts, '/', Rest),
        handle_credulous_path(Parts)
    ;   handle_credulous_dung
    ).

handle_credulous_path([sceptical]) :-
    !,
    findall(J,
            (arg(Acts, Val),
             sceptically_accepted(arg(Acts, Val)),
             arg_to_json(arg(Acts, Val), J)),
            Accepted),
    reply_json(Accepted).
handle_credulous_path([vaf, Aud]) :-
    !,
    (   audience(Aud, _)
    ->  findall(J,
                (arg(Acts, Val),
                 vaf_credQA(arg(Acts, Val), Aud, (Seq, _)),
                 proof_to_json(Seq, SeqJSON),
                 arg_to_json(arg(Acts, Val), ArgJ),
                 ArgJ = json(Fields),
                 J = json([proof=SeqJSON|Fields])),
                Results),
        reply_json(json([audience=Aud, credulous=Results]))
    ;   reply_json(json([error='unknown audience', audience=Aud]), [status(404)])
    ).
handle_credulous_path(_) :-
    reply_json(json([error='not found']), [status(404)]).

handle_credulous_dung :-
    findall(J,
            (arg(Acts, Val),
             credQA(arg(Acts, Val), (Seq, _)),
             proof_to_json(Seq, SeqJSON),
             arg_to_json(arg(Acts, Val), ArgJ),
             ArgJ = json(Fields),
             J = json([proof=SeqJSON|Fields])),
            Results),
    reply_json(Results).


% GET /counterfactual  and  GET /counterfactual/causal/:prop
handle_counterfactual(Request) :-
    (   memberchk(path_info(PathInfo), Request),
        atom_concat('/', Rest, PathInfo),
        Rest \= ''
    ->  atomic_list_concat(Parts, '/', Rest),
        handle_cf_path(Parts)
    ;   handle_cf_args
    ).

% GET /counterfactual
% All AS3 arguments for Hal, each accompanied by:
%   - "actual":        state attributes after the actual joint sequence
%   - "counterfactual": state attributes after the doNH substitution
handle_cf_args :-
    findall(J,
            (argument(hal, Acts, Val, as3),
             initial_state(Q),
             cf_joint_seq(Acts, CfActs),
             transj(Q, Acts, Actual, 2),
             transj(Q, CfActs, CfActual, 2),
             \+ worse(hal, Q, Actual, Val),
             worse(hal, Q, CfActual, Val),
             maplist(action_to_atom, Acts, ActAtoms),
             state_json(Q,        QJ),
             state_json(Actual,   ActualJ),
             state_json(CfActual, CfJ),
             J = json([actions=ActAtoms, value=Val,
                       initial=QJ, actual=ActualJ, counterfactual=CfJ])),
            Results0),
    sort(Results0, Results),
    reply_json(Results).

% GET /counterfactual/causal/:prop
% All (initial_state, joint_sequence) pairs where Hal is causally responsible
% for proposition Prop.
handle_cf_path([PropAtom]) :-
    !,
    atom_to_prop(PropAtom, Prop),
    (   Prop = unknown
    ->  reply_json(json([error='unknown proposition', prop=PropAtom]), [status(404)])
    ;   findall(json([state=SJ, actions=ActAtoms]),
                (initial_state(Q),
                 argument(hal, Acts, _, as3),
                 causal_responsible(hal, Q, Acts, Prop),
                 state_json(Q, SJ),
                 maplist(action_to_atom, Acts, ActAtoms)),
                Results0),
        sort(Results0, Results),
        reply_json(json([prop=PropAtom, responsible=Results]))
    ).
handle_cf_path(_) :-
    reply_json(json([error='not found']), [status(404)]).

% atom_to_prop(+Atom, -Prop)
% Maps URL path tokens to holds/2 proposition terms.
atom_to_prop(alive_hal,          alive(hal)).
atom_to_prop(alive_carla,        alive(carla)).
atom_to_prop(has_insulin_hal,    has_insulin(hal)).
atom_to_prop(has_insulin_carla,  has_insulin(carla)).
atom_to_prop(has_money_hal,      has_money(hal)).
atom_to_prop(has_money_carla,    has_money(carla)).
atom_to_prop(_,                  unknown).

% state_json(+State:list, -JSON)
% Serialises a state list as a JSON object with named fields.
state_json([Ih,Mh,Ah,Ic,Mc,Ac],
           json([ih=Ih, mh=Mh, ah=Ah, ic=Ic, mc=Mc, ac=Ac])).


% =========================================================
% JSON serialisation helpers
% =========================================================

% proof_to_json(+Seq:list, -JSON:list)
% Converts a dialogue sequence [pro(Arg)|opp(Arg)...] (most recent first)
% into a JSON array of {"player":"pro"|"opp","actions":[...],"value":"..."}.
proof_to_json(Seq, JSON) :-
    reverse(Seq, Chronological),
    maplist(move_to_json, Chronological, JSON).

move_to_json(pro(arg(Acts, Val)), json([player=pro, actions=ActAtoms, value=Val])) :-
    maplist(action_to_atom, Acts, ActAtoms).
move_to_json(opp(arg(Acts, Val)), json([player=opp, actions=ActAtoms, value=Val])) :-
    maplist(action_to_atom, Acts, ActAtoms).


% arg_json(+Ag, +Acts, +Val, -JSON) — scheme-free variant (stable interface).
% Action terms are converted to atoms so reply_json can serialise joint
% actions like buyH-comC (compound terms) without a type error.
arg_json(Ag, Acts, Val, json([agent=Ag, actions=ActAtoms, value=Val])) :-
    maplist(action_to_atom, Acts, ActAtoms).

% arg_json(+Ag, +Acts, +Val, +Scheme, -JSON) — includes the scheme field.
arg_json(Ag, Acts, Val, Scheme, json([agent=Ag, actions=ActAtoms, value=Val, scheme=Scheme])) :-
    maplist(action_to_atom, Acts, ActAtoms).

% action_to_atom(+Act, -Atom)
% Converts a joint-action compound H-C to the dash-separated atom 'H-C'.
% Plain atoms (individual actions) pass through unchanged.
action_to_atom(H-C, Atom) :-
    !,
    atomic_list_concat([H, C], '-', Atom).
action_to_atom(A, A).

% ext_json(+Ext, -JSON) converts a list of arg/2 terms to a JSON array.
ext_json(Ext, JSON) :-
    maplist(arg_to_json, Ext, JSON).

arg_to_json(arg(Acts, Val), json([actions=ActAtoms, value=Val])) :-
    maplist(action_to_atom, Acts, ActAtoms).
