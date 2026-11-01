# Update Log

Newest first. Each entry gets a version, a date, and short bullets under **Added / Changed / Fixed / Removed**.

---

## v0.1.0 (2026-11-01): First code
### Added
- Rojo project with tests (`luau tests/run.luau`), run by GitHub Actions on every push
- Shared logic: 20 player ratings, the fictional player generator, Elo, projected scoreline, box scores and team stats, daily quests and achievements
- Saving: profiles with autosave and a session lock
- **Codes:** `src/server/Codes.lua`, plus live `!makecode`, `!delcode`, `!codes` and `!codehelp` chat commands for admins, and a CODES button with a redeem panel in game
- No card goes above 93 OVR for now. New ranges are Legendary 80–86 and Hall of Fame 87–91
- Design: a Go-To Player (star) and Second Option, and a shot share bar that sets who takes the most shots
- Design: interactive moments: Coach's Calls, Heat check, defensive assignments you can change any time (with Lock him up), a clutch shot meter and a coach's challenge
- Design: a free sub and strategy break after every quarter, box scores, and a team stats page. Player badges added to the Ideas Queue

---

## v0.0.7 (2026-11-01): Elo & challenges
### Changed
- Server challenges are live games of about 5 to 6 minutes, with timeouts for both coaches. Queued games last about 2.5 to 3 minutes
- Ranked seasons moved to the Ideas Queue (idea only)
- PLAY always matches you against saved teams of real clubs. Live games happen only through server challenges
### Added
- Elo rating: start at 1000, K = 40 for placement and 24 after, half K for the owner of a saved team, an Elo-based matchmaking range, tiers from Elo with coin multipliers, a demotion shield and leaderboards

---

## v0.0.6 (2026-11-01): Player icons
### Added
- Generated player icons on every screen, and a rule: fictional names, with play styles based on real player types

---

## v0.0.5 (2026-11-01): Timeouts & Pack Shop
### Added
- Timeout system: 4 per game, a 15-second timer, subs, a style switch, a next-play call, a team talk, +15% energy, and a momentum reset
- Pack Shop with Coach Pack and limited event packs, prices in coins and Robux, and odds by rarity and by OVR range
- UI page with all 13 screens: https://claude.ai/artifact/RvesrYaenTjTgAxmMeYxBA
### Fixed
- Button text that wrapped onto two lines on the Match Found and Pack opening screens

---

## v0.0.4 (2026-11-01): Players & coaching
### Added
- [Players & Coaching](PLAYERS_AND_COACHING.md): 20 basketball ratings in 6 groups, in-game stamina and energy, a 10-player matchday roster, minutes allocation (240 player-minutes) and coaches
### Changed
- Coaching staff cut to an **Offensive Coach** and a **Defensive Coach**. Each coach brings play styles: 5-Out, Pace & Space, Inside Out, Pick & Roll, Motion and Iso Star on offense, and Man-to-Man, 2-3 Zone, Switch Everything, Drop Coverage and Full-Court Press on defense

---

## v0.0.3 (2026-11-01): Deep study, round 2
### Added
- [Reference Study](REFERENCE_STUDY.md) round 2: club creation, the exact lobby and match HUD, squads and synergy, training slots, market tax, tournaments and goal replays
- Main Game Idea: club creation, lineup presets with Team Power, career stats on cards, Weekend Tournaments, ball-handler tags and replays
### Changed
- Training uses 3 timed slots that keep running offline and stop at potential
- Market fee goes from 5% to 15% (10% with VIP) so the market removes money from the economy

---

## v0.0.2 (2026-11-01): Design v2
### Changed
- Rewrote [Main Game Idea](MAIN_GAME_IDEA.md) around the real genre loop: a walkable lobby with Home Courts, one-tap PvP matchmaking against real clubs, matches played by 3D players, packs with Finishes, a cross-server market, daily quests and chemistry
- Redid the UI mockups in the new bright, mobile-first style

---

## v0.0.1 (2026-11-01): Project setup
### Added
- Repo docs: [Main Game Idea](MAIN_GAME_IDEA.md), [Ideas Queue](IDEAS_QUEUE.md), [General Rules](GENERAL_RULES.md) and this log
- UI mockups for review: start screen, club hub, roster, scouting, training, match view with Clutch Timeout, season table

### Next
- Commit the match sim and server services after the design is approved
- Build the client UI from the approved mockups
