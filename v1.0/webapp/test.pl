/*  Copyright (c) 2026 Francesco Perrone. All Rights Reserved.
 *  SPDX-License-Identifier: LicenseRef-INS-1.0
 *  See the LICENSE file in the repository root for the full terms.
 */

/** <module> Earlier webapp server (without credulous routes)

Earlier version of the HTTP server, retained for reference.
Exposes the same API as server.pl except the /credulous routes.
Use server.pl for the full API.

Routes:
  GET /               — serves index.html
  GET /args           — all arguments (scheme-free)
  GET /attacks        — all attack pairs
  GET /extensions     — Dung grounded / preferred / stable extensions
  GET /vaf            — audiences list
  GET /vaf/:audience  — VAF preferred extensions
  GET /vaf/:audience/grounded — VAF grounded extension

@see webapp/server.pl for the current full-featured server.
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
:- use_module('../args').
:- use_module('../extensions').
:- use_module('../vaf').

% Routes
:- http_handler(root(.),          handle_root,       []).
:- http_handler(root(args),       handle_args,       []).
:- http_handler(root(attacks),    handle_attacks,    []).
:- http_handler(root(extensions), handle_extensions, []).
:- http_handler(root(vaf),        handle_vaf,        [prefix]).


%% server(+Port:integer) is det
%
%  Starts the HTTP server on Port and blocks until the process is killed.
%
server(Port) :-
    http_server(http_dispatch, [port(Port)]),
    thread_get_message(_).


% GET /
handle_root(Request) :-
    webapp_dir(Dir),
    atom_concat(Dir, '/index.html', Index),
    http_reply_file(Index, [unsafe(true)], Request).


% GET /args
% All arguments for all agents (scheme-free).
% Each entry is {"agent": "...", "actions": [...], "value": "..."}.
handle_args(_Request) :-
    findall(J, (member(Ag, [hal, carla]),
                argument(Ag, Acts, Val),
                arg_json(Ag, Acts, Val, J)),
            Args),
    reply_json(Args).


% GET /attacks
handle_attacks(_Request) :-
    findall(json([attacker=JA, attacked=JB]),
            (attacks(arg(A1,V1), arg(A2,V2)),
             arg_to_json(arg(A1,V1), JA),
             arg_to_json(arg(A2,V2), JB)),
            Attacks),
    reply_json(Attacks).


% GET /extensions
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


% =========================================================
% JSON serialisation helpers
% =========================================================

% arg_json(+Ag, +Acts, +Val, -JSON)
arg_json(Ag, Acts, Val, json([agent=Ag, actions=Acts, value=Val])).

% ext_json(+Ext, -JSON)
ext_json(Ext, JSON) :-
    maplist(arg_to_json, Ext, JSON).

arg_to_json(arg(Acts, Val), json([actions=Acts, value=Val])).
