# Main Game Idea (v2)

**Working title:** Manage a Basketball Team
**Platform:** Roblox (Luau + Rojo)
**Genre:** Social sports-manager collector. You hang out in a lobby, collect and trade players, and play quick PvP matches that you watch in 3D.

> v2 replaces the first draft. The research behind it is in [REFERENCE_STUDY.md](REFERENCE_STUDY.md). That draft was a slow single-player menu sim, which missed what makes this genre fun on Roblox: a hangout world, matches against **real players**, players on the court as **3D characters**, the hype of pack openings, and trading. See [What changed from v1](#what-changed-from-v1).

## One-line pitch

Build a basketball club in a hangout world, open packs and trade for stars, then press PLAY to go up against real managers' teams. Your squad plays the game as full 3D players, and you call the shots from the sideline.

## What we take from the genre, and what stays ours

The reference is a soccer-manager experience on Roblox. We share the genre's **conventions**, which many Roblox and sports games use: a walkable lobby, a PLAY button for matchmaking, packs with rarity tiers and shown odds, a player market, daily quests, chemistry, and stat training.

We **don't** copy its name, logo, art, models, map, UI layout or wording. We also don't copy its specific named features such as its Black Market, its ICON players or its card variant names. Everything below has its own names, its own basketball mechanics and our own look. See [GENERAL_RULES.md](GENERAL_RULES.md#originality).

## Core loop (sessions of 30 seconds to 5 minutes)

```
 Lobby ──► PLAY ──► Match found (VS screen) ──► 3D game, 2–3 min ──► Coins + fans + rating
   ▲                                                                   │
   │                                                                   ▼
 Trade on market ◄── Train / upgrade ◄── Open packs / scout ◄────── Spend coins
```

Meta goals: climb the **rating ladder**, finish **daily quests**, complete your **collection**, and raise your **fan count**, which pays you passive income.

## 1. The lobby (hangout world)

- A server holds up to **8 managers**. Each manager claims a **Home Court** plot around a central plaza.
- Your Home Court is painted in your team's colors and has your logo at center court. Your current starting five practice on it, shooting around and running drills, so other players can see your team.
- **Plaza stations** (walk up to one, or tap its HUD button):
  - **Pack Shop:** buy packs with coins or Robux.
  - **Trade Board:** the player market.
  - **Scout Office:** send scouts out on timed trips.
  - **Quest Board:** daily and weekly quests.
  - **Hall of Fame:** leaderboards for rating, fans and collection value.
- **The Traveling Scout:** a van parks somewhere in the plaza for 5 minutes, roughly every 40 minutes, and sells one Hall of Fame player. A server-wide alert announces it and everyone runs to it. (This is our take on the "roaming merchant" convention.)
- **First session:** create your club by picking a badge shape, two colors and a name. Your colors paint your Home Court, kits and bench.
- You start with a free player package. You walk your avatar around, emote, and stand courtside at your own games.

## 2. PLAY: matchmaking against real clubs

- One big **PLAY** button. It always matches you against a **saved team**: a snapshot of a real manager's club from any server, near your Elo. The snapshot includes their lineup, minutes, coaches, styles, name and avatar.
  - The match starts within seconds, and the other manager doesn't need to be online.
  - Their AI coach calls their timeouts.
  - Every club's snapshot is saved whenever its lineup or coaches change. The owner gets a notification like "Copper Ridge beat your team 88–81 while you were away", which shows their Elo change and a Rematch button.
- **Live games happen only through server challenges** (below).
- **VS screen:** both managers' avatars, club badges, team OVR, chemistry and Elo, plus a **projected scoreline** like "104 – 99 · 62% to win". The projection comes from both teams' minutes-weighted ratings and both play styles. Even teams project around 105–110 points each, fast styles push the totals up, and slow styles bring them down.
- **Server challenge:** walk up to any manager in your server, or tap their name, and challenge them. If they accept, it's a **live game** played on the challenger's Home Court, so the rest of the server can come and watch.
  - It's **longer** than a queued game: 4 quarters of about 75 seconds each, so **about 6 to 7 minutes** in total with stops.
  - **Both coaches call their own timeouts** (4 each), make subs and switch styles in real time. The game only pauses while a timeout is running.
  - It's unranked by default, so it doesn't change Elo.
- **Elo rating:** every club has an Elo number, shown on its badge, on the Match Found screen and on leaderboards.
  - You **start at 1000**.
  - After each ranked game: `new = old + K × (result − expected)`, where `expected = 1 / (1 + 10^((opp − you)/400))` and the result is 1 for a win and 0 for a loss.
    - Beating a stronger club gains a lot.
    - Losing to a weaker one costs a lot.
    - Two equal clubs trade about ±16.
  - **K-factor:** 40 for your first 10 placement games, then 24.
  - **Saved-team matches** count fully for you. The saved club's owner isn't online, so their Elo moves at half K, which stops anyone farming offline players.
  - **Matchmaking** picks a saved team within ±100 Elo. If none is free, the range widens step by step up to ±400.
  - **Leaving a game counts as a loss.** Friendlies are unranked.
- **Tiers (from Elo):**

  | Tier | Elo | Coins per win |
  |---|---|---|
  | Blacktop | under 1100 | ×1.0 |
  | Varsity | 1100–1299 | ×1.2 |
  | College | 1300–1499 | ×1.4 |
  | Pro | 1500–1699 | ×1.7 |
  | All-League | 1700–1899 | ×2.0 |
  | Hall of Fame | 1900+ | ×2.5 |

  - **Demotion shield:** right after you reach a new tier, you get 3 games of protection before you can drop out of it.
- **Leaderboards:** global top 100, your server, and your friends.

## 3. Matches (3D)

- The game is played at the **home team's court**. Ten R15 characters wear their team's kits and numbers. A server-authoritative sim decides each possession (see the existing `MatchSim`), and the client **acts it out**: dribbling, passing, jump shots, layups, dunks, blocks and rebounds, with animations.
- **How long a game lasts:**

  | Mode | Quarters | Real time |
  |---|---|---|
  | Queued (PLAY) | 4 × about 45 s, plus breaks | **about 4 to 4.5 min** |
  | Server challenge (live) | 4 × about 75 s, plus breaks | **about 6 to 7 min** |

  The game clock always shows 12-minute quarters (48 minutes in all), and it runs fast. A timeout pauses the game for up to 15 seconds, and each team has 4. Quarter breaks last about 12 seconds. Quarters were lengthened from 35 s because the interactive moments (timeouts, quarter breaks, Coach's Calls) add about a minute of stops.
- **The court is watched from the side.** The camera sits on the sideline and the court runs left to right across the screen, like a TV broadcast. Your coach avatar stands at the bench in the foreground under a HEAD COACH tag and can use emotes. The camera pans left and right to follow the ball.
- The game is played **on the home team's Home Court in the lobby world**, so other managers can walk over and watch.
- **Who is home:** in a queued game you are always home, since it's your Home Court and your crowd, and the saved team visits. In a server challenge the challenger is home.
- **Home court edge** is small on purpose. Home teams should win about 54% of even games.
  - **Shaky free throws:** when the away team shoots a free throw, the home crowd waves and yells, and the camera wobbles slightly. Away free throws drop by 3 percentage points, and by 6 in the last 2 game-minutes of a close game.
  - **Crowd energy:** the crowd gets louder on home runs, and home makes get bigger cheers. The away team's makes get a quieter reaction.
  - Home players recover energy on the bench 5% faster.
  - The home coach gets 1 extra second to answer Coach's Calls.
  - About +1 point in the projected scoreline.
- **Ball-handler tag:** a floating name tag marks whoever has the ball. Jerseys show names and numbers.
- After big plays a **REPLAY** shows a close-up from a new angle with a name lower third, and you can tap to skip.
- **Highlight moments:** big banners appear (AND-ONE!, FROM DOWNTOWN!, BIG BLOCK!, BUZZER BEATER!), dunks play as a letterboxed **slow-motion HIGHLIGHT**, and the game ends with a **VICTORY!** celebration in front of the bench. You can tap to skip.
- **Coach controls during the game:**
  - **Quarter breaks:** after every quarter, both coaches get a free break (the same screen as a timeout, without using one) to make subs, change the minutes plan, switch play style or give a team talk.
  - Switch **play style** between quarters, choosing only from the styles your Offensive Coach and Defensive Coach know (for example 5-Out, Pick & Roll, Motion, 2-3 Zone, Switch Everything or Full-Court Press). Each style counters some styles and is weak to others.
  - **Timeouts** (4 per game): the game pauses, and you have 15 seconds to:
    - make subs
    - switch play style
    - call the next play (Pick & Roll, Isolation, Kick-Out Three, Post Up or Lob)
    - give a team talk: Fire Up, Calm Down or Lock In, which lasts 2 minutes

    The five players on the floor get +15% energy, and the opponent's run resets. If you don't pick in time, your coaches decide.
  - **Interactive moments:** quick taps during play. You still coach and never control players directly.
    - **Coach's Calls:** 2 to 3 times a quarter, a 3-second choice pops up, for example "They're doubling Deuce!" with **Kick it out** or **Force it**. The right read for that situation (based on ratings and styles) gives a better chance on that possession. If you don't pick, your coaches choose.
    - **Heat check 🔥:** a player who makes 3 shots in a row catches fire, with a flame on his tag and a small make% boost. Tap **Feed him** to double his shot share for about a minute of game time. A cold player (missed 4 in a row) gets a ❄ and you can tap **Sit him**.
    - **Defensive assignments:** the Matchups panel shows who guards who. It's set automatically by position, and you can change it **any time** during the game. Drag your defender onto an opponent, and the swap takes effect at the next dead ball. In a zone, the panel shows zone spots instead (who guards the paint, the wings and the top).
      - **Lock him up** is a shortcut: when an opponent catches fire, tap him to move your best Perimeter D (or Interior D for a big) onto him.
    - **Clutch shot meter:** on the final shot of a close game (within 3 points, last 24 seconds), you time a release meter for the shooter. Ratings decide most of it. Perfect timing adds up to +6% and a bad release takes off up to −6%. In live challenges both coaches get one. On saved teams the AI coach times it at a random, average skill.
    - **Coach's challenge:** once a game, challenge a foul call. A slow-mo replay plays, and about 40% of calls get overturned. A failed challenge costs a timeout.
  - **Clutch Timeout** (our signature feature): in the last minute of a close game, you pick the final play yourself: Isolation, Pick & Roll or Kick-Out Three.
- Afterward you see the score, a **box score** for both teams (MIN, PTS, FG, 3PT, FT, REB, AST, STL, BLK, TO), an MVP card, coins, fans, your Elo change and progress on your quests.
- **Team stats** page: W–L, PPG, opponent PPG, point differential, FG%, 3P%, FT%, RPG, APG, SPG, BPG and turnovers per game. Each player's card has the same stats for their career.

## 4. Players & collection

> Full detail on ratings, stamina, bench, minutes and coaches: [PLAYERS_AND_COACHING.md](PLAYERS_AND_COACHING.md).

- **Positions:** PG, SG, SF, PF, C. **Ratings (20):** Mid-Range, Three-Point, Free Throw · Layup, Driving Dunk, Standing Dunk, Close Shot, Post Moves · Passing, Ball Handling · Interior D, Perimeter D, Steal, Block · Off/Def Rebound · Speed, Strength, Vertical, **Stamina**. Cards show 6 group scores (SHO FIN PLY DEF REB ATH). OVR is weighted by position.
- **Stamina:** players lose energy on the floor and get it back on the bench. Tired players play worse.
- **Minutes:** you split 240 player-minutes across a 10-player matchday roster (5 starters + 5 bench), or press Auto Minutes.
- **Coaches:** your avatar is the Head Coach. You hire an **Offensive Coach** and a **Defensive Coach**, and the play styles they know decide how your team plays (for example 5-Out, Pick & Roll, 2-3 Zone or Full-Court Press).
- **Rarity:** Common (grey), Rare (blue), Epic (purple), Legendary (orange) and **Hall of Fame** (gold, above Legendary). Hall of Fame players are fictional legends we invent, such as "Big Moe Okonkwo".
- **Finishes** are rare cosmetic variants that also give a stat boost, and any player can roll one:
  - **Hot Hand** (flame trail, +3 OVR)
  - **Ice Veins** (frost aura, +5)
  - **Prism** (rainbow shimmer, +8, about 1 in 500)
- **Lineup:** a starting five plus 5 bench spots, with saved **lineup presets** (for example Small Ball or Twin Towers). The team shows a single **Team Power** number.
- **Career stats** on every card: games, points, rebounds, assists and MVP awards.
- **Archetypes** are tags that drive chemistry: Sniper, Slasher, Floor General, Lockdown and Glass Cleaner.
- **Duplicates:** combine copies of the same player to raise their **star level** (1★ to 5★), which raises their stat caps. This means you can upgrade without buying packs.

## 5. Packs

Packs climb a ladder. Each rarity only drops from at most three packs next to each other, and **Hall of Famers only drop from the top two**. The shop shows rarity odds per card. It doesn't show odds by OVR.

| Pack | Coins · Robux | Contents | Player Common / Rare / Epic / Legendary / Hall of Fame % | Badge Bronze / Silver / Gold / Diamond / Hall of Fame % |
|---|---|---|---|---|
| Rookie Pack | 2,500 · R$ 19 | 1 player, 1–2 badges, 1 item | 85 / 15 / — / — / — | 80 / 20 / — / — / — |
| Blacktop Pack | 10,000 · R$ 49 | 1 player, 1–2 badges, 1 item | 60 / 33 / 7 / — / — | 55 / 38 / 7 / — / — |
| Pro Pack | 40,000 · R$ 99 | 1–2 players (35% for a 2nd), 1–2 badges, 1 item | — / 60 / 33 / 7 / — | — / 55 / 38 / 7 / — |
| All-Star Pack | 150,000 · R$ 249 | 1–2 players (50% for a 2nd), 2–3 badges, 1 item | — / — / 70 / 27 / 3 | — / — / 70 / 27 / 3 |
| Hall of Fame Pack | 500,000 · R$ 599 | 2 players, 2–3 badges, 1 item | — / — / — / 88 / 12 | — / — / — / 88 / 12 |
| Badge Pack | 20,000 · R$ 59 | 3–4 badges | — | 50 / 35 / 13 / 2 / — |
| Coach Pack | 60,000 · R$ 149 | 1 coach | 60 / 30 / 9 / 1 / — | — |
| Elite Coach Pack | 250,000 · R$ 399 | 1 coach | — / 45 / 40 / 13 / 2 | — |

**The item.** Every player pack ends its reveal with one useful item instead of a filler player: a **Cosmetic** (40%, a jersey, court floor, ball or celebration), a **Coin Pouch** (35%, 10–30% of the pack's coin price back) or a **Badge Upgrade** (25%). Badge Upgrades have their own rarity, and the rarity decides which tier they work on: **Bronze → Silver** (60% of upgrades), **Silver → Gold** (28%), **Gold → Diamond** (10%) and **Diamond → Hall of Fame** (2%). The player still needs the stats for the new tier. Stamina only exists inside a match, so there are no energy items.

**OVR ranges for now:** Common 50–64, Rare 65–72, Epic 73–79, Legendary 80–86 and Hall of Fame 87–91. **No card goes above 93**, including Finishes and training. Stronger cards come in a later update, when we raise the cap.

- **A fixed card list.** Every player and coach in the game is on one list (`src/shared/Catalog.lua`): 216 players (80 Common, 60 Rare, 40 Epic, 24 Legendary, 12 Hall of Fame) and 28 coaches. Each card has a set name, position and ratings, so everyone pulls the same "Deuce Reyes". Duplicates raise the card's star level.
- **See what's inside:** every pack has a **Contents** button (the list icon next to it). It opens a grid of every card that pack can give, best first, with rarity, OVR, position, face, and the chance of each card. A filter switches between rarities, and cards you already own are ticked. A **Collection book** in the menu shows all 216 players and 28 coaches, with the ones you haven't found shown as silhouettes.
- **Bundles:** the shop keeps one card per pack. Pressing **Buy** opens a small popup to pick **1×, 5× or 20×**. 5 packs cost 10% less and 20 cost 20% less (for example 5 Pro Packs for 180,000 coins instead of 200,000). The popup then offers **Open now** or **Keep**.
- **A bundle is its own item.** A kept 5× or 20× bundle sits in the inventory as one box ("Pro Pack Bundle ×5"), not as 5 loose packs. Opening it plays the first pack in full, then offers **Open all**, which flips the rest fast and ends on a summary of the best pulls. In code, an inventory entry is `{ kind = "pack", pack = "Pro" }` or `{ kind = "bundle", pack = "Pro", size = 5 }`.
- **Robux:** every pack and bundle can also be bought with Robux. Game passes come later.
- **Fewer players, plus badges and an item.** Packs give **1–2 players, 1–3 badges and 1 item** (see Badges in `PLAYERS_AND_COACHING.md`), so the bench doesn't fill with junk cards. The item flips first, then badges, then players, with the best player last. Tapping a flipped badge flips it again to show what it does and the stats it needs.
- Odds are always shown in-game, and Robux packs follow Roblox's rules on paid random items.
- **Reveal:** the pack slams on the floor and shakes, glowing in the best card's rarity color, then rips open. The cards fly out face-down, and you tap each one to flip it. Each flip plays its rarity color, sound and an announcer line. On a Legendary or better, the whole server gets an alert.
- **Hover on good cards:** hovering (or holding on mobile) over an Epic or better card tilts it toward the cursor with a moving holo shine in its rarity color. Legendary and Hall of Fame cards also give off sparks, and Finish cards show their Finish pattern.
- **Walkout cutscene (Legendary and Hall of Fame):** instead of flipping, the card plays a short cutscene on your Home Court. You can tap to skip it after the first time.
  1. The arena lights go out, and a spotlight hits the tunnel with smoke.
  2. **Clues** appear one at a time, each in a different spot on the screen: the flag of the player's nation (top left), then their position (right), then the archetype (bottom, for example "Rim Protector").
  3. The player's **real 3D model**, blacked out with a rim light in the rarity color, walks out of the tunnel and does a move that fits the archetype: a jump shot (Sniper), a dunk (Slasher, Post Scorer), a dribble combo (Floor General, All-Around) or a block (Rim Protector, Lockdown, Glass Cleaner). Sounds come from the animation's own timeline, so they land on the bounce, the slam or the swat. The **OVR** slams onto the screen in the rarity color. See `docs/ANIMATIONS.md`.
  4. The lights come up on the 3D player doing a signature celebration, with the name, the card and confetti.
  5. A Hall of Fame walkout adds a drumroll, an air horn and a gold spotlight, and the whole server sees a "HALL OF FAMER PULLED" alert.

## 6. Training, scouting & chemistry

- **Training:** **3 timed slots.** You pick a player and a focus (Shooting, Finishing, Playmaking, Defense, Rebounding, Athleticism, or All). A session lasts about 1 hour and keeps running while you're offline. Progress stops at the player's potential, and star levels raise that cap.
- **Scout Office:** send a scout on a 5-minute, 30-minute or 2-hour trip, and they come back with a player card. Longer trips find better odds. You start with 1 scout slot and can get more through progression or a game pass. This gives players a reason to come back.
- **Chemistry (0–100%)** gives a flat bonus to every stat in matches (up to about +10%). It goes up when:
  - your lineup's archetypes complement each other (a Floor General plus two Snipers, a Slasher plus a Glass Cleaner)
  - players fit their positions
  - the same five play games together

## 7. Market (Trade Board)

- **Listings:** list a player at your own price. A sale takes a **15% fee**, which removes coins from the economy. VIP lowers it to 10%.
- Browse by position, rarity or Finish. You can buy instantly.
- **Direct trade:** offer players and coins to someone in your server, and both sides confirm.
- The market is cross-server, using MemoryStore with a DataStore backup. Everything is checked on the server, and trades are atomic.

## 8. Weekend Tournaments

- A **points race** that runs Friday to Sunday. Wins and big plays earn points, and entry needs a minimum fan count, so fans unlock competition as well as paying income.
- Two levels: **Neighborhood Cup** (low fan requirement) and **City Classic** (higher requirement, bigger prizes). Top finishers win coins and packs.

## 9. Economy & progression

- **Coins** are the main currency, with big numbers and fast growth.
- **Fans** grow with wins and pay passive income every minute you're online. Upgrading your Home Court (seats, scoreboard, lights) raises how much each fan pays.
- **Daily quests:** 3 a day, drawn from a pool and reset at 00:00 UTC. Each pays coins, from 1,000 to 4,000. Examples: win 2 games, make 15 threes, throw down 8 dunks, open a pack, call 3 timeouts, or play a server challenge.
- **Achievements:** lifetime goals with tiers that each pay once. The big tiers pay packs. Examples: Winner (1 / 10 / 50 / 250 / 1,000 wins), From Downtown (threes), Posterizer (dunks), Pack Rat, Collector, Climber (reach each Elo tier), Hot Streak, Clipboard Coach (timeouts), Challenger and Legend Hunter (pull Hall of Fame players).
- There's also a login streak and **redeem codes**. The owner makes codes in `src/server/Codes.lua`, or live from chat with `!makecode` (see the README).
- **Robux (later):** VIP (2× coins), an extra scout slot, Robux packs with shown odds, and court cosmetics. Nothing is pay-to-win only.

## 10. Look & feel

- The world is bright, sunny and cartoony, with outdoor courts, palm trees and plaza hoops. The UI uses chunky rounded buttons, bold outlined text, and large coin counters with juicy "+coins" pops.
- Our own palette uses court orange, sky blue and pine green, with rarity colors on top.
- It's built for mobile first, with big touch targets and the PLAY button in thumb reach.

## Technical shape

- The server is authoritative. Matchmaking and the market use MemoryStoreService, and profiles use DataStore with autosave.
- Shared, pure-Luau modules (Config, Rng, PlayerFactory, MatchSim) can be tested outside Roblox.
- **MatchSim** produces a list of possession events. The client "director" turns each event into character movement and animations.
- Character models are R15 rigs coloured per team, with an animation set for dribble, shoot, dunk, pass, defend and celebrate. Custom meshes and animations can be made in Blender.

## What changed from v1

| v1 (missed the point) | v2 |
|---|---|
| Menus only, dark esports UI | A walkable bright lobby with Home Courts |
| Single-player league against AI | One-tap PvP matchmaking against real clubs |
| Colored tokens on a court | 3D players acting out every play, slow-mo and replays |
| Pick 1 of 3 scouting instead of packs | Packs with rarity and Finishes, plus timed scout trips |
| Trades only within the server | Cross-server market plus direct trades |
| No retention hooks | Daily quests, passive fan income, a traveling scout and Elo tiers |

The parts we kept from v1 are the possession sim, the tactics counters, the **Clutch Timeout**, training with caps, and server authority.
