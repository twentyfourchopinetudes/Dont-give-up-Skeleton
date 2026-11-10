# Handover: the live test loop and the "lab" pattern

How Claude built and verified Ossaria's fight against the running game, and how to repeat it for any other boss,
enemy or system. Ask for it by name: **"set up a test lab for X like HANDOVER_TESTLAB.md"**.

## What you (the user) do

1. Open `DGUS.rbxlx` in Roblox Studio with the Studio MCP plugin connected. Leave it in Edit mode.
2. Tell Claude Studio is open. Claude checks with `list_roblox_studios`; an empty list means it is not connected.
3. When Claude says it edited scripts **in Studio**, press **Ctrl+S**, then say so. Claude then runs
   `python tools/export_scripts.py` and `graphify update .` to bring `src/` back in line.
4. Do not play-test in the same Studio window while Claude is running a session: it starts and stops play itself.

## The two ways code gets into the place (never mix them in one step)

| Direction | When | Steps |
|---|---|---|
| `src/` to place | Studio is closed, or you will reopen it | Edit `src/`, `python tools/export_scripts.py --import`, reopen the place **without saving** |
| Studio to `src/` | Studio is open and Claude needs to test now | Claude edits scripts with the MCP `multi_edit` tool, tests, you press Ctrl+S, Claude runs `python tools/export_scripts.py` |

The import refuses if the place was saved since the last export, so after a Ctrl+S always export before the next import.

### Getting Studio edits onto disk without a save

Claude cannot save the place, but it can read script sources out of Studio and rebuild the files itself:

1. In the Edit datamodel, `execute_luau` returns, for each edited script, a chunk of at most 85,000 characters as
   `@@@@BEGIN <name> <part> <total> <len> <checksum>`, the chunk, `@@@@STOP`, then padding up to about 99,000
   characters. A result that large is saved by the harness as a text file instead of being shown.
2. `python tools/pull_from_studio.py <tool-results folder>` checks every chunk's length and checksum and writes the
   scripts into `src/`. A mismatch writes nothing.
3. `python tools/export_scripts.py --import` then puts them in the place file on disk, and they can be committed.

A result over 100,000 characters is cut off, which is why scripts go in 85,000-character parts. If you later press
Ctrl+S in that Studio session it saves the same content, so run `python tools/export_scripts.py` before the next import.

## The verification loop Claude runs

All through the Roblox Studio MCP tools. Each step is one tool call.

1. **Compile check (Edit mode).** `loadstring(script.Source, script.Name)` on every touched script; a `nil` result
   carries the syntax error. This is the only real compiler available: there is no Luau binary on this machine and
   downloaded ones are blocked from running.
2. **Start play** (`start_stop_play`), then wait in a Server `execute_luau` until the player's character exists.
3. **Collect errors.** Server-side, connect `LogService.MessageOut` and append every non-print message to a
   `StringValue` in ServerStorage (`LabLog`). Read it back after each test. `get_console_output` alone is not
   enough: it is dominated by startup prints.
4. **Drive the game as the player.** From a Client `execute_luau`, fire the game's own remote:
   `ReplicatedStorage.Remotes.Action:FireServer("DevOss", "lab2")`. Dev actions need the `Dev` attribute, which
   Studio sessions get automatically.
5. **Trace what happened.** Poll the boss model's `BP` attribute (its current body pose) every 0.05 s and log each
   change with a timestamp. A move that runs to its last pose and back to idle, with an empty `LabLog`, has executed.
6. **Look at it.** `screen_capture` returns the live viewport during play.
7. **Stop play** before editing scripts again (`multi_edit` only works in Edit mode).

### Things that do not work (already tried)

- `require(module)` from `execute_luau` returns a **separate copy** of the module, not the game's. Its state is
  empty and its functions are not the running ones. Always go through a remote or through instances and attributes.
- Studio cannot fetch from `localhost`: the MCP HTTP allowlist blocks it. There is no way to push files from disk
  into an open Studio except `multi_edit`.
- Claude cannot save the place. Only you can (Ctrl+S).
- Passing a function's internals to `execute_luau` is impossible; expose what a test needs as an attribute, an
  instance, or a dev remote command.

## The lab pattern (what was built for Ossaria)

The goal: fire any one behaviour on demand, with the thing otherwise idle, and record a verdict on each.

1. **One table of behaviours.** Each attack is `{ name, fn, min, max, w, cd, ... }` in a `MOVES` list
   (`Characters/OssariaHeir.luau`).
2. **Candidates in their own module.** `GameServer/OssariaMoves.luau` returns `function(kit) ... return moves end`.
   The owner hands it a **kit** table of its internal helpers (`hold`, `mark`, `flight`, `cut1`, ...) from `M.init`,
   so candidates are written with the same pieces as real moves without living in the main file.
3. **A `lab = true` flag** on every candidate. The normal picker skips flagged entries, so nothing unapproved
   reaches the real fight. Promoting one is setting `lab = false` and giving it a weight and cooldown; cutting one is
   deleting it.
4. **Three control fields on the owner:** `passive` (do nothing on its own), `forced` (run this move next),
   `loop` (keep running it). The brain loop checks them before its normal pick. Exposed as
   `M.lab.passive(on)`, `M.lab.fire(name, loop)`, `M.lab.stop()`.
5. **Dev commands over the existing dev remote** (`Ossaria.luau`'s `M.dev`): `lab2`, `lab3`, `fire:<name>`,
   `loop:<name>`, `stop`, `passive:on|off`, `mark:<name>:<keep|tweak|cut>`. Starting the lab also turns on
   invulnerability.
6. **The list published as one attribute.** `ReplicatedStorage "OssLab"` = `name|phase|pool-or-lab|note;...`.
   The client panel builds its rows from it, so new moves appear with no client change. Notes must not contain
   `;` or `|`.
7. **A client panel** (`SoulsClient.client.luau`, inside the Ossaria menu block): start buttons, toggles, and per
   move a fire button, a loop button and K / T / C marks. Marks are stored as `Lab_<name>` player attributes and
   printed as `[Lab] name = verdict` in the server output, which is how Claude reads them back.

### Reusing it for something else

Ask for the same five pieces for the new target: a behaviour table, a kit plus candidates module, the `lab` flag,
the passive/forced/loop fields, and dev commands plus a panel. For anything that is not a boss (a trap, an enemy
kind, a cutscene), the minimum useful version is one dev command per behaviour and a `BP` or attribute Claude can
poll.

## The working rhythm

1. Claude pitches a batch as one-line descriptions. You strike the ones you do not want.
2. Claude builds the survivors as lab-only candidates and runs each once (steps above) to catch errors.
3. You try them in the lab and mark each K, T or C.
4. Claude reads the marks, promotes the keeps, applies the tweaks, deletes the cuts, and pitches the next batch.

Claude can confirm that a move **executes cleanly**. Only you can judge how it looks and feels.

## Project gotchas learned along the way

- `SoulsClient.client.luau` is close to Luau's limit of 200 locals in its main body. New UI goes inside a
  `do ... end` block.
- Character files in `ReplicatedStorage/Characters` load on clients too. Do not `require(PuppetMath)` at the top of
  one (circular through Roster); do it inside `M.init` or lazily.
- The dev menu's reset for Ossaria brings the Heights down. The opening cutscene options skip that reset on a
  fresh save for this reason.
- With invulnerability off and no dodging, phase 2 kills a standing player in about 4 seconds.
- Shell heredocs on this machine mangle backslashes and long scripts. Patch scripts are written to the scratchpad
  with the Write tool and then run.
- A block-balance and unbound-name checker lives only in the session scratchpad; the Studio `loadstring` check
  replaces it whenever Studio is connected.

## State when this was written (9 November 2026)

- The attack lab and `GameServer/OssariaMoves` are in `src/`, in the place file and committed.
- 19 candidate moves exist. One (Spokes) is promoted into her phase 3 fight; 18 are lab-only and waiting on a keep,
  tweak or cut each.
