# Update Log

Newest first. Each entry gets a version, a date, and short bullets under **Added / Changed / Fixed / Removed**.

---

## v0.2.0 (2026-11-01): Coins down 10x, gems slower, tutorial
### Changed
- Every coin number divided by 10: starting coins (250), packs (Rookie 250 to Hall of Fame 50,000), badge equip costs, quest and achievement rewards, Arena and Training Facility costs, scout sign prices and refresh (500), Coin Pouch rounding, and the launch codes
- Gems come in slower: start with 10, daily sweep 3, each achievement tier 3, Elo tier rewards halved (10 / 20 / 40 / 75 / 150)
- Badges: equipping is now free and taking a badge off costs the tier's coins (Bronze 250, Silver 1,000, Gold 2,500, Diamond 6,000, Hall of Fame 15,000; the top three were 3,500 / 10,000 / 30,000). Equipped badges can't be upgraded in place: take off, then equip the better one
### Added
- `Tutorial.lua`: 9-step first-time tutorial with Coach Dee (club, first pack, starting five, badge, minutes, warm-up game, training, scouting, quests). Free Rookie Pack, 250 coins for the warm-up game, and 250 coins + 20 gems + a Blacktop Pack for finishing. Skippable.
- In-game lessons: the warm-up game freezes for 8 lessons (ball tag, Coach's Call, heat check, Lock him up, timeout, timeout screen, tired player sub, clutch meter), each with a spotlight, box and arrow, and waits until you do it (`Tutorial.MatchLessons`, `src/client/TutorialOverlay.lua`). Plus 7 one-time tips in real games (`Tutorial.Tips`)
- `Badges.unequip`: takes a badge off for the tier's coins and returns the badge card

## v0.1.9 (2026-11-01): Facilities, scouting prices, score effects
### Added
- Gem slots: Scouting Report starts at 3 players, up to 6 (100/250/650 gems); training starts at 3 slots, up to 5 (150/400 gems)
- `Facilities.lua`: Arena (+4% game coins and +0.2 home OVR per level) and Training Facility (shorter sessions, bigger gains), upgraded with coins over a build timer; gems skip the timer
- Score Effect cosmetics: a burst at the rim after a made shot (Net Pop, Confetti Burst, Splash, Flame Ring, Star Shower, Supernova)
### Changed
- Scouting sign prices scale with OVR, overpriced (x1.3 to x1.8) with overlapping ranges, and 4% off per scout level
### Removed
- Net cosmetics

## v0.1.8 (2026-11-01): Scouting, gems and cosmetics in code
### Added
- `Scouting.lua`: roll a 5-player report, what each scout level reveals (never OVR), refresh by timer, coins or Scout Ticket, flat 25,000-coin sign price (replaced in v0.1.9), gem upgrade costs (50/100/200/400/800)
- Gems on the profile (start with 25), paid by achievements (5 per tier), sweeping the daily quests (5) and first time reaching each Elo tier (20 to 300)
- `Cosmetics.lua`: 15 slots and 73 cosmetics with rarities; the Cosmetic pack item now rolls a real cosmetic
- UI page: Scouting Report screen and the cosmetics list

## v0.1.7 (2026-11-01): Scouting Report and gems (design)
### Added
- Scouting Report: 5 players with hidden OVR, signed for coins. Scout levels 0–5 reveal best stat, position, 2nd stat, archetype and nationality, 3rd stat, then rarity
- Gems: premium currency for scout upgrades, cosmetics, a Gem Pack and skipping training timers
- Scout Ticket pack item (one free refresh). Items are now Cosmetic 35%, Coin Pouch 30%, Badge Upgrade 20%, Scout Ticket 15%

## v0.1.6 (2026-11-01): Skilled-player animations
### Added
- Dribble moves: live dribble, crossover, between the legs, behind the back, hesitation. They chain, and the walkout combo is four of them
- Bounce pass. Wrist and ankle joints, with automatic foot planting (flat on the floor, toes pointed in the air)
### Changed
- Slim athletic player build, and the ball a little wider than the head, with the rim about twice the ball (the old chunky model made the ball look tiny)
- Jump shot reworked as a one-motion shot with a set point, wrist cock and snap, a quiet guide hand and staggered feet

## v0.1.5 (2026-11-01): Animations tuned to real basketball movement
### Added
- In-game clips: Idle, Jog, Defensive Slide (loops), Layup, Chest Pass, Rebound. `AnimClips.ForPlay` maps match plays to clips
- Animation lab on the UI page: every clip on the player model, with 1×, 0.5× and 0.25× speed, looping and live sound cues
- Movement study in `docs/ANIMATIONS.md`, with the numbers each clip is tuned to and the sources
### Changed
- Jump shot: the ball now leaves on the way up, before the top of the jump. The arm finishes at a shooter's angle instead of straight up, and the follow-through is held until the ball drops. The ball takes about 1 s to reach the rim
- Dunk: takeoff off the left foot with the right knee driving, after a longer and lower last step
- Pack items are now Cosmetic (40%), Coin Pouch (35%) and Badge Upgrade (25%), which has its own rarity: Bronze→Silver 60%, Silver→Gold 28%, Gold→Diamond 10%, Diamond→Hall of Fame 2%. Energy Drink and Training Pass were removed because stamina only exists inside a match
- Shot, dunk, block and layup now fire ShotRelease, Swish, Dunk, Block and LayupKiss cues, which will play once those sounds are uploaded
### Fixed
- Crossover: the ball bounced on the floor twice with no hand in between

## v0.1.4 (2026-11-01): Badge icons, Badge Applier, 3D walkout, sound check
### Added
- An icon for each of the 20 badges, in a hex frame per tier (100 PNGs in `assets/icons/badges/`)
- Badge cards flip over to show what they do, the stats they need and the equip cost
- Badge Applier: badge → Use → eligible players highlighted, or player → empty slot → badges that fit
- Packs include 1 item: Energy Drink, Training Pass, Coin Pouch or a cosmetic (`Config.PackItems`)
- 3D walkout with the real blocky player model: walk, jump shot, dunk, dribble combo, block and a pose
- `AnimClips.lua` (generated from the prototype) and `AnimPlayer.lua`: keyframe clips with sound events on the same clock. `docs/ANIMATIONS.md` lists every animation the game needs
### Changed
- Pack contents: 1–2 players, 1–3 badges and 1 item (Badge Pack: 3–4 badges)
- Sounds: every file checked with an audio classifier. The whistles, boo, groan, crowd loop and big cheers were replaced because they were mostly dribbling or had no whistle

## v0.1.3 (2026-11-01): Badges
### Added
- Badges (`Badges.lua`): 20 badges in 5 tiers (Bronze, Silver, Gold, Diamond, Hall of Fame). Equipping needs the stat bar for the tier and coins. Badge slots go by rarity (Common 1 up to Hall of Fame 5)
- Badge Pack (4 badges)
- Bundles stay one inventory item (`kind = "bundle"`) when kept
- Walkout silhouette does a move that fits the archetype (shot, dunk, dribble or block)
### Changed
- Player packs give 1 or 2 players plus 2 or 3 badges instead of 3 to 5 players
- Archetypes show with spaces ("Rim Protector")
- Shop is back to the original look. 1×, 5× or 20× is picked in a popup after pressing Buy
- Sounds: each group (menus, coins, crowd, cards, reveals) now comes from one recording family at one loudness

## v0.1.2 (2026-11-01): Pack ladder, card list, playbook
### Added
- Fixed card list (`Catalog.lua`): 216 players and 28 coaches. Packs draw from it, and each pack has a Contents view
- 5 player packs on a ladder (Rookie, Blacktop, Pro, All-Star, Hall of Fame) and 2 coach packs (Coach, Elite Coach)
- Bundles of 5 (10% off) and 20 (20% off), with coin and Robux prices
- Playbook: plays per style, more plays and a success bonus for rarer coaches, and court diagrams for every play and defense
### Changed
- Each rarity drops from at most 3 neighbouring packs, and Hall of Famers only from the top 2
- The shop no longer shows odds by OVR range
- Sounds: the synthesized effects and AI commentator were replaced with real recordings from professional sound libraries (see `assets/audio/CREDITS.md`)

## v0.1.1 (2026-11-01): Sound
### Added
- `docs/AUDIO.md`: every sound the game needs (ball and court, crowd, in-game moments, menus, pack opening, music), where to get each one, and the full commentator script
- `Sounds.lua` registry and `Audio.lua` player: volume groups, random variants and pitch, cooldowns, and a commentator queue that never talks over itself. Sounds stay silent until their asset IDs are filled in
- First 150 sound files in `assets/audio/`: CC0 recordings (ball, squeaks, whistles, buzzer, crowd), synthesized effects, and commentator lines from an open-source AI voice
- The CODES panel plays open, close, success and error sounds
- Design: pack opening animation (drop, shake, rip, cards fly out, tap to flip, special reveals for Legendary and Hall of Fame)
- Packs now have 3, 4 or 5 cards, a guaranteed best card in the bigger packs, and `PlayerFactory.openPack`. Hall of Famers only drop from the All-Star Pack and event packs
- Hover effect on Epic or better cards, and a walkout cutscene for Legendary and Hall of Fame pulls
- Player info: nationality, weight, extra positions, and the owning club (never a real team)
- Positions: anyone can play anywhere, with an OVR penalty at unlisted positions. Some players list extra positions, and a few are Positionless
- Home court edge: shaky away free throws, crowd energy, faster bench recovery
### Changed
- Coaches have no rating, only rarity. Rarity boosts their play style and sets how many styles they know
- Queued games: quarters go from about 35 s to about 45 s (about 4 to 4.5 min in total with stops). Server challenges take about 6 to 7 min

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
