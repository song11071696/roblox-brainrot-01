# Brainrot Bay — roblox-brainrot-01

A 3D brainrot collection game for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01).
All twelve characters are original inventions — nothing is copied from Steal a Brainrot or any other game.

## The loop

Brainrots ride a conveyor belt into the bay. Walk up to the belt, read a brainrot's name, rarity and
dollars-per-second on its floating label, and buy it (E on the brainrot, or the shop panel). Carry it to your
own base plot, press E (or PLACE) to set it down, and it earns money every second at its rate. Spend the money
on the next tier up the rarity ladder: Common → Rare → Epic → Legendary → Mythic → Brainrot God. Mutations
(Golden x2, Diamond x5, Rainbow x10) multiply earnings.

## Tension and progression

- **Steal:** hold E on another player's brainrot to grab it, then run 40 studs from their base in 5 seconds
  or it snaps back. Every steal locks the victim's base for 60 seconds, and the owner can lock it on purpose.
- **Tsunami:** every 150 seconds a wave sweeps the map. The HUD warns 15 seconds ahead — dash to your base's
  raised platform or the spawn hill, the only high ground, or take damage and get shoved.
- **Rebirth:** trade lifetime earnings for a permanent +50% income multiplier per level (up to x6).
- **Upgrades:** +10% base income per level, up to 5 levels. Selling a brainrot refunds half its cost.

## The cast (12 originals)

| Character | Rarity | Cost | $/s |
|---|---|---|---|
| Spaghetto Scream | Common | $50 | 5 |
| Capy Cappuccino | Common | $100 | 9 |
| Banana Boogie | Common | $200 | 16 |
| Pizza Pigeon | Rare | $500 | 32 |
| Taco Tornado | Rare | $900 | 55 |
| Noodle Ninja | Rare | $1,500 | 85 |
| Burrito Bandito | Epic | $3,000 | 160 |
| Gelato Giraffe | Epic | $5,500 | 280 |
| Disco Duckling | Epic | $9,000 | 450 |
| Espresso Elephant | Legendary | $18,000 | 850 |
| Volcano Volpino | Legendary | $35,000 | 1,500 |
| Pasta Pope | Brainrot God | $150,000 | 6,000 |

## The world

A built 3D bay in `default.project.json`: grass baseplate, spawn pad and spawn hill, a striped conveyor with
a gate arch, 8 coloured base plots (each with an owner sign and a raised high-ground platform), a pond with a
sand beach, palm trees, rocks, a beach ball and umbrella, bright midday lighting. The project file is written
in compact one-line-per-part JSON (Rojo only cares about the structure, not the whitespace), so the whole
world fits in a few hundred lines instead of a few thousand.

## Structure

- `src/shared/BrainrotCatalog.luau` — the cast, rarities, mutations, rolls (one source of truth)
- `src/shared/Config.luau` — every tuning number in one place
- `src/server/Economy.luau` — the one place player money lives; 1-second earnings tick
- `src/server/Conveyor.luau` — spawning, belt movement, buying, carrying, placing
- `src/server/BaseManager.luau` — the 8 plots, slots, locks, selling
- `src/server/StealSystem.luau` — steal carries, escape checks, base locks
- `src/server/Tsunami.luau` — warning cycle and the wave sweep
- `src/server/Rebirth.luau` — rebirths, base upgrades, selling
- `src/server/WorldBuilder.luau` — builds each brainrot's 3D model and floating label
- `src/server/SoundServer.luau` — server side of the sound split (decides WHEN)
- `src/server/init.server.luau` — bootstrap: wires the systems and starts the loops
- `src/client/HUD.client.luau` — money, shop, base buttons, carry banner, tsunami banner, feed
- `src/client/Game.client.luau` — opening camera sweep, E-to-place keybind
- `src/client/SoundClient.luau` — client side of the sound split (owns the Sound objects)
- `src/client/CarryState.luau` — the one place the client keeps what it is carrying

## Build and hand in

    ~/workspace/bin/rojo build default.project.json --output game.rbxl
    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

`main.ts` (Node 22, standard library only) copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to
`/output`, leaving out every name that starts with a dot, and writes `/output/dossier.json` with
`vendor/makefun-roblox.ts`, the kit's copy, unchanged. It first checks the place is a binary Roblox place
and that `screenshots/` holds 3 or 4 images.

`PLAY.json` still names no published place yet: publishing from Roblox Studio, the play code in the
experience description, real Studio screenshots and the icon/thumbnail upload are owner-side steps that
come after the build. `TOUR.json` names the keys and functions that bring the game to each screenshot.
