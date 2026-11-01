# Update Log

Newest first. Each entry gets a version, a date, and short bullets under **Added / Changed / Fixed / Removed**.

---

## v0.0.7 (2026-11-01): Elo
### Added
- Elo rating: start at 1000, K = 40 for placement and 24 after, half K for the owner of a saved team, an Elo-based matchmaking range, tiers from Elo with coin multipliers, a demotion shield, a 2-week season with soft reset, and leaderboards

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
