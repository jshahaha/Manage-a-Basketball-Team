# Manage a Basketball Team

An original Roblox basketball manager. You build a club in a hangout world, open packs, set minutes and hire coaches, then watch your team play from the bench and call timeouts.

| Doc | What's in it |
|---|---|
| [Main Game Idea](docs/MAIN_GAME_IDEA.md) | Pitch, core loop and every system |
| [Ideas Queue](docs/IDEAS_QUEUE.md) | Ideas waiting to be built |
| [Update Log](docs/UPDATE_LOG.md) | What changed in each version |
| [General Rules](docs/GENERAL_RULES.md) | Originality, safety, code and git rules |
| [Reference Study](docs/REFERENCE_STUDY.md) | Research notes on how the genre plays |
| [Players & Coaching](docs/PLAYERS_AND_COACHING.md) | Ratings, stamina, bench, minutes, coaches and play styles |

**UI mockups:** https://claude.ai/artifact/RvesrYaenTjTgAxmMeYxBA

## Code

A [Rojo](https://rojo.space) project written in Luau.

| Folder | Goes to | What's there |
|---|---|---|
| `src/shared` | ReplicatedStorage.Shared | Pure game logic: Config, ratings, player generator, Elo, stats, quests, achievements, projected score, code rules |
| `src/server` | ServerScriptService.Server | Services (data, codes, progress), **`Codes.lua`** and **`Admins.lua`** |
| `src/client` | StarterPlayerScripts.Client | Client UI (codes panel for now) |
| `tests` | — | `luau tests/run.luau` tests the shared logic |

**Run it:** install [Rokit](https://github.com/rojo-rbx/rokit), run `rokit install`, then `rojo serve`, and connect from the Rojo plugin in Studio. To save data in Studio, turn on *Game Settings → Security → Enable Studio Access to API Services*.

### Making codes
- **Permanent:** add a line to [`src/server/Codes.lua`](src/server/Codes.lua) and publish. The file explains every option.
- **Live, no publish needed:** in any server, an admin types `!makecode SUMMER coins=5000 pack=Pro:1 days=7` in chat. The code works in every server within seconds. `!codes` lists codes, `!delcode NAME` deletes one, and `!codehelp` shows every option.
- The game owner is always an admin. Add more people in [`src/server/Admins.lua`](src/server/Admins.lua).
