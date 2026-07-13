# Getting Started

## Prerequisites

SWI-Prolog 9.0 or later.

```bash
# Debian / Ubuntu
sudo apt install swi-prolog

# macOS (Homebrew)
brew install swi-prolog
```

---

## Running the full system

```bash
git clone <repo-url>
cd ins/v1.0
swipl dbg.pl
```

This loads all modules, starts the PlDoc documentation server, and runs 23 test
sections covering every layer of the framework.  Output is approximately 400 lines.

---

## Interactive queries

After loading `dbg.pl` (or any entry point), query the system at the `?-` prompt.

### State space

```prolog
?- state(S).                              % enumerate all 64 states
?- initial_state(S).                      % the 3 morally relevant starting states
```

### Transitions

```prolog
?- trans([0,1,1,1,1,1], Acts, Next, 2).  % all 2-step individual sequences from a state
?- transj([0,1,1,1,1,1], JActs, Next, 2).% all 2-step joint sequences
```

### Value evaluation

```prolog
?- eval(hal, [0,1,1,1,1,1], [1,0,1,1,1,1], Evals).   % +lifeH, -freedomH, ...
```

### Arguments

```prolog
?- arg(Acts, Val).                        % Hal's AS1+AS2 arguments (35)
?- argument(hal, Acts, Val, as3).         % Hal's AS3 arguments (10)
?- argument(carla, Acts, Val, Scheme).    % Carla's arguments
?- attacks(A1, A2).                       % all attack pairs
```

### Dung extensions

```prolog
?- grounded_extension(Ext).              % Ext = [] (empty)
?- preferred_extension(Ext).             % 13 solutions
?- stable_extension(Ext).
```

### VAF extensions

```prolog
?- vaf_preferred_extension(Ext, altruistic).   % 10 solutions
?- vaf_preferred_extension(Ext, freedom_first).% 6 solutions
?- vaf_grounded_extension(Ext, selfish).
```

### Dialectical proof

```prolog
?- credQA(arg([buyH,doNH], lifeH), (Seq, Pro)).
?- vaf_credQA(arg([comH,doNH], lifeC), altruistic, Proof).
?- sceptically_accepted(Arg).            % no solutions
```

### Counterfactual reasoning

```prolog
?- counterfactual_holds([0,1,1,1,1,1], [buyH-losC,doNH-buyC], alive(hal)).
?- causal_responsible(hal, [0,1,1,1,1,1], [buyH-losC,doNH-buyC], alive(hal)).
?- argument(hal, Acts, lifeH, as3).      % all 10 AS3 arguments for lifeH
?- argument(hal, _, lifeC, as3).         % fails — lifeC = 0
```

### Possible world semantics

```prolog
?- value_weight(selfish, lifeH, W).      % W = 4
?- value_weight(altruistic, lifeC, W).   % W = 4

?- value_distance([1,1,1,0,1,1], [0,1,1,0,1,1], selfish, D).   % D = 4
?- value_distance([1,1,1,0,1,1], [0,1,1,0,1,1], altruistic, D).% D = 3

?- closest_worlds([0,1,1,1,1,1], [1,0,1,1,0,1],
                  hal_lacks_insulin, selfish, Worlds).

?- lewis_would([0,1,1,1,1,1], [buyH-losC,doNH-buyC],
               hal_lacks_insulin, hal_dead, selfish).

?- stalnaker_would([0,0,1,1,1,1], [takH-comC,losH-doNC],
                   carla_lacks_insulin, hal_dead, life_first).
```

---

## HTTP server

```bash
swipl v1.0/webapp/server.pl
```

The server starts automatically on **port 8000**.  Visit `http://127.0.0.1:8000/`
for the HTML frontend.  See [[API Reference]] for all endpoints.

---

## PlDoc documentation

`dbg.pl` starts the PlDoc server automatically.  After loading, visit:

```
http://localhost:4000/
```

to browse the inline documentation for all exported predicates.

---

*Next: [[API Reference]]*
