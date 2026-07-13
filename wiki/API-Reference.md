# API Reference

The HTTP server (`webapp/server.pl`) exposes the entire reasoning system as a JSON
API.  All endpoints return JSON.  Start the server with:

```bash
swipl v1.0/webapp/server.pl
# Server starts on http://127.0.0.1:8000/
```

---

## Endpoints

### Arguments

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/args` | All arguments (Hal + Carla, all schemes). Each object has `agent`, `actions`, `value`, `scheme` fields. |

**Example response item:**
```json
{ "agent": "hal", "actions": ["buyH","doNH"], "value": "lifeH", "scheme": "as1" }
```

---

### Attack relation

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/attacks` | All attack pairs between arguments in `arg/2`. |

---

### Dung extensions

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/extensions` | Grounded, preferred, and stable extensions as JSON arrays. |

---

### VAF

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/vaf` | All named audiences and their value orderings. |
| `GET` | `/vaf/:audience` | VAF preferred extensions for the named audience. |
| `GET` | `/vaf/:audience/grounded` | VAF grounded extension for the named audience. |

Valid audience names: `life_first`, `selfish`, `altruistic`, `freedom_first`.
Unknown audience → HTTP 404.

---

### Credulous acceptance

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/credulous` | All credulously accepted arguments with their φ₁-proof sequences. |
| `GET` | `/credulous/sceptical` | All sceptically accepted arguments (currently empty). |
| `GET` | `/credulous/vaf/:audience` | VAF credulous acceptance for the named audience. |

---

### Counterfactual reasoning

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/counterfactual` | All AS3 arguments with actual and counterfactual witness states. |
| `GET` | `/counterfactual/causal/:prop` | All (state, sequence) pairs where Hal is causally responsible for `prop`. |

Valid `prop` tokens:

| Token | Proposition |
|-------|-------------|
| `alive_hal` | `alive(hal)` |
| `alive_carla` | `alive(carla)` |
| `has_insulin_hal` | `has_insulin(hal)` |
| `has_insulin_carla` | `has_insulin(carla)` |
| `has_money_hal` | `has_money(hal)` |
| `has_money_carla` | `has_money(carla)` |

Unknown token → HTTP 404.

---

### Frontend

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/` | HTML frontend (`webapp/index.html`) — fetches from the JSON API. |

---

## Notes

- All endpoints return `Content-Type: application/json`.
- State lists are serialised as JSON arrays: `[0,1,1,1,1,1]`.
- Action sequences are serialised as JSON arrays of strings: `["buyH","doNH"]`.
- Joint action sequences use hyphen notation in strings: `["buyH-losC","doNH-buyC"]`.

---

*Previous: [[Getting Started]] · Next: [[Module Reference]]*
