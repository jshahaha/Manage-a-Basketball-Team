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
- **The Traveling Scout:** a van parks somewhere in the plaza for 5 minutes, roughly every 40 minutes, and sells one Hall of Fame tier player. A server-wide alert announces it and everyone runs to it. (This is our take on the "roaming merchant" convention.)
- **First session:** create your club by picking a badge shape, two colors and a name. Your colors paint your Home Court, kits and bench.
- You start with a free player package. You walk your avatar around, emote, and stand courtside at your own games.

## 2. PLAY: matchmaking against real clubs

- One big **PLAY** button. It queues you **across servers** through MemoryStore.
  - If a live opponent is found within about 8 seconds, it's a real-time match, and both managers see the game and can call plays.
  - Otherwise you're matched against a **snapshot of a real player's club** (their lineup, tactics and name), taken from any server. It always feels like PvP, and the queue never stalls.
- **VS screen:** both managers' avatars, club badges, team OVR, chemistry and rating.
- **Server challenge:** walk up to any manager in your server, or tap their name, and challenge them. If they accept, it's a **live game** played on the challenger's Home Court, so the rest of the server can come and watch.
  - It's **longer** than a queued game: 4 quarters of about 75 seconds each, so **about 5 to 6 minutes** in total.
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
  - **Matchmaking** looks for an opponent within ±100 Elo. The range widens by 50 every 3 seconds, up to ±400.
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
  | Queued (PLAY) | 4 × about 35 s, plus breaks | **about 2.5 to 3 min** |
  | Server challenge (live) | 4 × about 75 s, plus breaks | **about 5 to 6 min** |

  The game clock always shows 12-minute quarters (48 minutes in all), and it runs fast. A timeout pauses the game for up to 15 seconds.
- **The court is watched from the side.** The camera sits on the sideline and the court runs left to right across the screen, like a TV broadcast. Your coach avatar stands at the bench in the foreground under a HEAD COACH tag and can use emotes. The camera pans left and right to follow the ball.
- The game is played **on the home team's Home Court in the lobby world**, so other managers can walk over and watch.
- **Ball-handler tag:** a floating name tag marks whoever has the ball. Jerseys show names and numbers.
- After big plays a **REPLAY** shows a close-up from a new angle with a name lower third, and you can tap to skip.
- **Highlight moments:** big banners appear (AND-ONE!, FROM DOWNTOWN!, BIG BLOCK!, BUZZER BEATER!), dunks play as a letterboxed **slow-motion HIGHLIGHT**, and the game ends with a **VICTORY!** celebration in front of the bench. You can tap to skip.
- **Coach controls during the game:**
  - Switch **play style** between quarters, choosing only from the styles your Offensive Coach and Defensive Coach know (for example 5-Out, Pick & Roll, Motion, 2-3 Zone, Switch Everything or Full-Court Press). Each style counters some styles and is weak to others.
  - **Timeouts** (4 per game): the game pauses, and you have 15 seconds to:
    - make subs
    - switch play style
    - call the next play (Pick & Roll, Isolation, Kick-Out Three, Post Up or Lob)
    - give a team talk: Fire Up, Calm Down or Lock In, which lasts 2 minutes

    The five players on the floor get +15% energy, and the opponent's run resets. If you don't pick in time, your coaches decide.
  - **Clutch Timeout** (our signature feature): in the last minute of a close game, you pick the final play yourself: Isolation, Pick & Roll or Kick-Out Three.
- Afterward you see the score, an MVP card, coins, fans and rating change, and progress on your quests.

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

| Pack | Price | Common / Rare / Epic / Legendary / HoF |
|---|---|---|
| Blacktop Pack | 5,000 coins · R$ 29 | 70 / 24 / 5 / 0.9 / 0.1 % |
| Pro Pack | 40,000 coins · R$ 99 | 35 / 40 / 19 / 5.5 / 0.5 % |
| All-Star Pack | 250,000 coins · R$ 399 | — / 40 / 42 / 16 / 2 % |
| Coach Pack (1 coach) | 60,000 coins · R$ 149 | 55 / 30 / 12 / 2.7 / 0.3 % |
| Event pack (e.g. Holiday Hoops, limited) | R$ 499 | Epic+ only: — / — / 78 / 19 / 3 % |

Every player pack gives **3 players**. The shop shows odds both by rarity and by OVR range.

- Odds are always shown in-game, and Robux packs follow Roblox's rules on paid random items.
- **Reveal:** the pack slams on the floor, the jerseys flip one by one, and the rarity color and an announcer line ("FROM DOWNTOWN!") play. On a Legendary or better, the whole server gets an alert.

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
- **Daily quests:** for example, play 3 matches, score 60 points with threes, or win 2 games. **Weekly quests** are larger.
- There's also a login streak and codes (`TIPOFF`, `FASTBREAK`).
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
