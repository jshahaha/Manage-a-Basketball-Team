# General Rules

These are the ground rules for working on this game, for both people and Claude.

## Originality
- This is an **original** game in the management-sim genre. It is not a copy of any existing Roblox experience.
- **Never copy** another game's name, logo, branding, art, models, maps, UI layouts, sounds, text or signature features.
- **Allowed:** genre conventions that many games share, such as collecting players, training stats, simulated matches, leagues and an in-game economy.
- All assets are our own: made in code, made by us in Blender or Figma, or taken from Roblox's free library where the license allows.

## Roblox & player safety
- Every piece of user-typed text that other players can see, such as team and city names, must go through `TextService` filtering.
- Follow the Roblox Community Standards and the rules on paid random items. If we ever sell scouting trips for Robux, the odds must be shown in-game.
- Do not collect personal information.

## Code
- **Language:** Luau, synced with Rojo (`default.project.json`).
- **The server is authoritative.** The client only asks the server to do things and displays the result. It never decides cash, stats or match results.
- Every remote handler checks its payload's types, ownership and limits before it acts.
- Shared modules (`src/shared`) are pure Luau with no Roblox services, so they can be tested with the `luau` CLI.
- Every tunable number goes in `Config.lua`. Gameplay scripts contain no magic numbers.
- Script names use PascalCase. A service is a module that exposes `handlers` and `start()`.
- Before you push, every changed file must compile with `luau-compile`, and the sim tests must pass.

## Git workflow
- `main` is always playable.
- Work happens on a branch and is merged with a pull request that gets at least one review.
- Each PR adds an entry to [UPDATE_LOG.md](UPDATE_LOG.md) when it changes something a player can see.
- Ideas go into [IDEAS_QUEUE.md](IDEAS_QUEUE.md) and are not built straight away.

## Balance
- Balance changes need before and after numbers from the sim test, such as win rate or average score.
- No single tactic should win more than about 60% of games between equal rosters.
