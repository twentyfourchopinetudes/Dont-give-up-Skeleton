# Handover 5: Decayed Palace and the Giles / Mabel / Ossaria questline

Status: all of this is in src/ and imported into DGUS.rbxlx. **None of it has been played in Studio yet.**

## Workflow reminders
- Edit src/, then `python tools/export_scripts.py --import` (it backs the place up to DGUS.rbxlx.bak). Reopen the place in Studio **without saving**.
- After Studio changes, run `python tools/export_scripts.py`, then `graphify update .`.
- Run `graphify query` before you grep (CLAUDE.md rule).
- A bracket/block balance checker was used during the session; it isn't saved in the repo.

## What was built

### Area
- The Weald field is renamed **Vale of Errants**, and the Colosseum no longer has an area name.
- North of the Silver Knight runback there's a **grand gate** (built in `DecayedPalace.luau`, data in `info.DecayedGate`).
- Behind the gate, in order: the decayed woods, the decayed town, and the **Decayed Palace**, a clone of the Palace of Pyralis enclosed by rocks.
- Dev teleport: button 26 **DevDecayed** in SoulsClient.

### Decayed enemies (`Decay.luau`, `Enemies.luau`)
- Spawn specs take `Decayed = true`. Those enemies get HP ×1.5 and Speed ×0.75, and `Decay.apply(model)` recolors them:
  - warm reds become purple and oranges become dark green
  - Fire becomes a dark smoke "DecayAura"
  - CrackedLava becomes Slate
  - warm Neon effects become ForceField
  - particles, lights, trails and beams are recolored
- `Decay.watch(rects, map)` rots anything enemies spawn later (attack effects) inside the decayed area.
- **Palace garrison:** copies of the Pyralis palace guards (Stoker, Forgeknight, Ashsmith, Executioner, Pyre).
- **Town:** 10 enemies, mostly Pyre mages, plus a Stoker, an Executioner, a Forgeknight and an Ashsmith.

### Gate (`init.server.luau`)
- The padlock has an "Unlock" prompt.
- Without `GateKey` it says the gate is locked.
- With the key:
  - it sets `Map.DecayedGateOpen` and tells every player "The grand gate groans open."
  - it removes the chain and roots and swings both leaves open by ±80°
  - it splits the "Edge" rim parts across the gateway
- Once open, it stays open for the whole server.

## The questline (as built)
Characters: Giles is `Characters/Taylor.luau` with text in `Config.Taylor`. Mabel is `Characters/Mabel.luau` with text in `Config.Wick`.

1. **Shack Giles** sits in the doorway of his shack by the Crossing and calls out when you come within 45 studs. His intro takes 3 talks.
2. **The armor:** after you've killed 5 enemies, your next talk gives you Wretch's Motley.
3. **The key:** the next 3 talks (`KeyLines`) give you **Giles's Gate Key** (attribute `GateKey`, talk count in `GilesKeyTalk`). After that he gives `AfterKey` hints: the gate is left of the road to the Colosseum.
4. **Opening the gate:** use the key on the padlock in the Vale of Errants.
5. **Wood Giles** sits in the gate passage at `info.GilesWood` and only calls out once the gate is open. Over his talks he explains:
   - this is Ossaria's court now
   - Ossaria is the land's strongest child, from the heights above the Colosseum. The King let her in as a cure, but she was the sickness, and he shut the gate on her.
   - his granddaughter Mabel was inside when it shut. He made her a ring from a palace button.
   - he asks you to find out what became of her
6. **The ring:** **Mabel's Ring** is in a chest in the palace armoury by the grindstone (`Map.MabelRingAt`), guarded by a decayed Ashsmith. It sets the `MabelRing` attribute. If you show it to Giles, he hints "somewhere low and dark."
7. **Finding Mabel:** she's in her drain nook. Her 3 `RingLines` tell you she fled into the drains and is alive, and set `MabelKnows`.
8. **Giles's death:** go back to Wood Giles.
   - He says `ReunionLine` (sets `GilesReunited`).
   - Ossaria's voice says `OssariaLine`, and dark smoke rises around him.
   - He says `LastLine`, "Tell.. tell my button.. Grandpa came back..", and the player gets `GilesDead`.
9. **Remains:** both Gileses are hidden for that player on the client. The `GilesRemains` ragdoll, which exists in the workspace and is shown only to players with `GilesDead`, has a "Search" prompt that gives `GilesScrap`, a coat scrap reading "Mabel. Grandpa came back for you."
10. **Mabel's grief:** her 4 `GriefLines` end with "Now go and make her sorry." They give **+1 Nobility** and set `MabelMourned`.

**Lore chests in the town** (`info.DecayedLore`): a proclamation, a tin of crown buttons and a hymnal with "King" scratched out.

## Known problems and risks
- **Must fix:** chests open once per server for everyone, so only the first player can get Mabel's Ring and later players are soft-locked. Make the MabelRing chest per-player, or give the ring straight to any player who opens it while they don't have it yet.
- The +1 Nobility from Mabel adds to the stat directly and skips any accounting for points already spent.
- Possible visual problems:
  - Giles may clip the shack door frame.
  - The remains ragdoll at server start and may settle oddly (they're anchored after 5 s).
- Nothing links Ossaria to "the daughter" that Shack Giles and the Consul mention. They're probably meant to be the same person; that isn't wired up.
- Ossaria is only a voice: there's no model or boss yet.

## Next steps (planned, not built)
Ideas for making Giles's death sadder; the ones marked ★ were offered as the first to build:
1. ★ **It's the player's fault:** Ossaria found Giles through the ring you carried. Have her say so: "You brought me his little button."
2. **A gift for Mabel:** Giles gives you something (a ribbon) to take to her.
3. **He reaches:** he stands up and dies reaching toward the palace.
4. **Slow death:** his last line breaks off mid-word.
5. ★ **Mabel changes:** she's cheerful and giggly the first time you meet her, and stops giggling after his death.
6. ★ **The world remembers:**
   - a second candle by Mabel
   - his shack left empty
   - Mabel's other lines changed
   - the Wretch's Motley description updated
7. **A keepsake instead of a stat:** Mabel gives you a keepsake (the ring back) instead of +1 Nobility.
8. **Silence:** no music or sound at the moment he dies.

Other next steps:
- Build Ossaria as the decayed area's leader and boss (the land's strongest child), and tie her to "the daughter".
- Fix the one-chest-per-server ring problem (above).
- Playtest the whole chain in Studio.
