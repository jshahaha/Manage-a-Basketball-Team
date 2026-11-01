# Reference Study: the genre game we're learning from

These are study notes on the soccer-manager Roblox experience that js linked. They record **how the genre plays**, so our basketball game matches its feel without copying it. For what we may and may not borrow, see [GENERAL_RULES.md](GENERAL_RULES.md#originality).

**Sources (2026-11-01):** the experience's public page and API data (description, game passes, developer products, votes), about 25 YouTube gameplay videos (titles, plus auto-generated frames and thumbnails, since transcripts weren't available), and fan guide sites.

## Snapshot
- Released 2026-10-08. After about 3 weeks it had roughly 4.3M visits, 6 to 9k players online, and a 98% like ratio.
- **Servers are small (max 6 players).** Each player has their own pitch and stadium in a shared outdoor world.
- The studio made a sibling game in the same format for another sport (an F1 manager), so this is a repeatable formula. "Be a ___ Manager" is the template, and the sport is swappable.

## The actual loop (what v1 of our design missed)
1. **Spawn in a bright, outdoor, cartoony world**: grass, trees, dirt paths, a pitch with small stands. You walk around as your avatar. There's chat, emotes, and other managers walking around.
2. **Tap PLAY.** A **"MATCH FOUND / Get ready for kick-off"** screen shows both managers' avatars, club names, badges, @usernames and a small trophy count, so it feels like a real person versus you.
3. **The match plays on your own pitch in the world.** Your avatar stands in a **dugout or technical area on the sideline** under a "HEAD COACH" tag. The camera sits behind or beside the coach and looks across the pitch. **The game is watched from the sideline.**
4. Match moments get **big banners**: CORNER, GOAL! (with a confetti burst), **BIG CHANCE!** (letterboxed, cinematic slow motion), HALF TIME, and finally **VICTORY!**, where the squad celebrates in front of the camera with the score. There's a "tap to skip" option.
5. The match HUD is minimal: a compact score bar at the bottom center (both clubs and the clock), LEAVE and chat buttons, the daily quests panel, and **match emotes** for taunting or reacting (some are sold as an Emoji Pack).
6. Afterward you get club money and fans. Back in the lobby you open packs, sell, list, train and set your lineup, then press PLAY again.

## Screens & systems seen
- **Lobby HUD:**
  - coin counter at the top center with a + button
  - a boost timer pill at the top left (2× Money, 2× Fans)
  - a FREE reward button
  - Daily Quests on the right side ("Play 3 matches", "Score 6 goals", "Keep a clean sheet", "Open a pack", "Start 3 training sessions", each with a cash reward; VIP gets an extra quest)
  - a bottom bar with small icon buttons on either side of a large green **PLAY** button
- **Cards (collection):**
  - a dark panel with a card grid showing OVR, face and rarity frame
  - tabs by position group, sort by overall, rarity or newest
  - club capacity (for example 12/60)
  - a detail side panel with the player's stats and **SELL / QUICK SELL**
- **Market:**
  - tabs for Packs, Community and My Listings
  - community listings with search, position, rarity and sort filters, and a market tax
  - packs list odds as **OVR ranges** (for example "60–69 OVR 80%") instead of rarity names
- **Packs:** six tiers that get more expensive from cheap to premium. Each opens 1 to 3 players, can be bought with cash or Robux, and opens "right away".
- **Rare-player shop:** a separate, timed, limited-stock shop for top-tier retired-legend style players, sold for Robux. (We won't copy this. Ours is the Traveling Scout, which has its own rules.)
- **Shop:** tabs for Featured, Money, a seasonal event and Codes. A limited **event pack** runs with a countdown ("these players never come back").
- **Training:** **timed sessions in slots.** You start a session and it finishes later. You can skip it with Robux, there's a "Fast Training" pass that halves the time, and a last slot that costs Robux to unlock.
- **Squad presets** let you save several lineups (some slots are paid).
- **Synergy:** a team chemistry stat that creators make "how to get 100%" videos about.
- **Hidden potential:** a pass reveals every player's potential, which is a hint to buy.
- **Player lookup:** a cheap pass lets you search any manager and see their match history and their players' career stats.
- **Gifting:** every pass and money pack can be gifted to someone in the server.
- **Monetization ladder:**
  - a one-time Starter Pack, then a **chain of bundles** that unlock one after another
  - VIP (+25% money and fans, a gold club look, a tag, a better quick-sell price)
  - money packs from small to very large, and premium packs
  - nothing blocks free players from the core loop

## What makes it work (takeaways)
- **Fast loop.** You can go from PLAY to the result in a couple of minutes, and there's always a next thing to tap.
- **The match is a show you watch from the coach's spot.** It's never a stats screen. The drama comes from banners, slow motion and the celebration.
- **The PvP framing matters.** You're up against a person with a name and an avatar, even when you're really playing against their saved team.
- **Collection plus economy.** Packs, quick-selling and listing turn every player into money, and that keeps the loop going.
- **Timers bring players back:** training sessions, boost timers, limited event packs, daily quests.
- **Small social servers.** Your stadium is in the same world as everyone else's.

## What this changes for our basketball game
| Area | Decision |
|---|---|
| Camera | **Side-on sideline view.** The court runs left to right on screen, and our coach avatar stands at the bench in the foreground. This matches js's direction: "The court will be watched sideways". |
| Where games happen | On **your Home Court in the lobby world**, so others in the server can walk over and watch. |
| Match drama | Basketball versions of the banners: AND-ONE!, FROM DOWNTOWN!, BIG BLOCK!, slow-motion **HIGHLIGHT** dunks, BUZZER BEATER!, END OF QUARTER, and a **VICTORY!** celebration. |
| Coach presence | A HEAD COACH tag, sideline emotes during games, and our **Clutch Timeout** play call. |
| Training | **Timed sessions in slots** instead of the energy system from v1. |
| Packs | Show odds as **OVR ranges** plus rarity, and open 1 to 3 players each. |
| Collection | Club capacity, sell and quick-sell, and lineup presets. |
| Retention | Daily quests, boost timers, a free reward timer, and limited-time event packs. |
| Monetization (later) | Starter Pack, then a bundle chain, VIP, and gifting. All odds are shown. |

## What we will NOT copy
Its name or "Be a ___ Manager" title pattern, logo, characters, map, card frame art, UI layout and colors, its wording and banners, its rare-player shop and that tier's name, pass names, prices, and any real athletes' names or likenesses.
