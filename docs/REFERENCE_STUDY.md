# Reference Study: the genre game we're learning from

These are study notes on the soccer-manager Roblox experience that js linked. They record **how the genre plays**, so our basketball game matches its feel without copying it. For what we may and may not borrow, see [GENERAL_RULES.md](GENERAL_RULES.md#originality).

**Sources (2026-11-01):** the experience's public page and API data (description, game passes, developer products, votes), about 40 YouTube gameplay videos (titles, plus auto-generated frames and thumbnails, since transcripts weren't available), and fan guide sites.

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

## Deep study, round 2 (zoomed-in frames)

These notes come from about 60 more full-resolution frames across 18 more videos, read panel by panel. The numbers are the reference game's and are recorded only so we understand its pacing. We set our own numbers.

### Club creation (first session)
- A new manager picks one of about 5 badge shapes, a main color and a second color (about 12 each), and types a club name. "Your colors are used on your badge and your kits." The whole world (kits, stands, dugout) then wears your colors.

### Lobby HUD, read precisely
- **Top left:** the club card shows the badge, club name, @username, the **division** (for example AMATEUR or PROFESSIONAL) and a **fan count**.
- **Top center:** money with a + button.
- **Live boost banner:** for example "2X MONEY 2X FANS · UPDATE DAY" with a countdown, so update days feel like events.
- **Bottom bar:** SQUAD, CARDS, TRAINING, then PLAY, then MARKET, TOURNAMENTS (with a NEW badge) and SHOP. Pressing PLAY turns the button into **CANCEL** with a "FINDING A MATCH… 00:11" timer and a "Looking for an opponent…" toast.
- **Daily Quests** panel on the right with a reset countdown, 3 free quests plus 1 VIP-only quest that advertises VIP. Examples: open a pack, score 6 goals, keep a clean sheet, start 2 training sessions, play 3 matches, win 2 matches. Rewards are small cash amounts or a basic pack. The panel stays on screen during matches too.
- Chat has a Here (server) tab and a Global tab.

### Squad
- **6-a-side** with formations such as 4-1, 3-2, 2-3 and 1-4.
- **Synergy %** (for example 63–70%) gives a flat bonus to all stats ("+9.5% to all stats"). A single **Team Power** number sums up the squad.
- Several saved **squad tabs** (the later ones locked behind Robux), a KIT tab, plus AUTO FILL and CLEAR. Players in training are tagged and can't be picked.

### Cards (collection)
- Tabs by position group, sort by Overall, Rarity or Newest, and a capacity counter (for example 16/50).
- Each card shows 5 stats, OVR, a nation flag and an IN SQUAD tag.
- The detail panel shows **career stats** (matches, goals, assists, average rating, MVP awards; clean sheets and saves for goalkeepers), a **MAX potential** value, and SELL or QUICK SELL with the quick-sell price on the button.

### Training
- **3 slots.** Pick a card and a focus (one stat or ALL). A session gives a fixed chunk of XP, shows "OVR 78 → 80" progress, and **takes 2 hours, running while you're offline**. A card stops at its potential (hidden as "???" unless you own the reveal pass). Skipping costs Robux, and a toast announces "<player> started SPRINT!".

### Market
- **Packs tab:** every pack gives 2 to 3 players and lists odds as **OVR bands** (for example 62-69 28%, 70-76 40%, 77-79 28%, 80-87 4%), payable with cash or Robux. Prices climb steeply from tier to tier.
- **Community tab:** search by name or country, position, rarity and sort, with "by seller". **A 30% tax is taken from every sale** (a pass lowers it to 10%). That heavy tax is the main money sink.
- **Rare-player shop:** appears without warning for a few minutes. Each player has **10 copies shared by every server**, so it sells out fast. Robux only.

### Tournaments
- **Daily Cup:** a points race over the day. Entry needs a minimum fan count, it shows how many managers joined, and it has a countdown. Top places win cash plus a pack.
- **Major Cup:** a longer race with a higher fan requirement and bigger prizes.
- This gives fan count a purpose beyond income: it unlocks competitions.

### Matches, read precisely
- The camera sits **behind the coach at the dugout on the touchline**, looking across and along the pitch. Your coach avatar fills the left foreground. A HEAD COACH card at the bottom left shows the club and your @username.
- **Bottom center score bar:** both badges, club names and @usernames, a LIVE tag, the half and clock, a possession % bar under it, and an expandable scorer list ("P. Abdullahi 3', 16'").
- Every goal gets a **REPLAY**: a close-up from a new angle with a lower third ("GOAL · N. FARKAS 42' · club") and TAP TO SKIP. Players wear their name and number on their backs, and a floating tag ("9 N. FARKAS") marks whoever has the ball.
- Between highlights the camera can pull up to a high wide shot of the whole pitch.
- The end is a **VICTORY!** shot with the squad celebrating in front of the camera above the final score.
- The world scoreboard by your pitch shows the live score, so passers-by can see it.

### Sister game
- The same studio runs an F1 manager built on the same formula (lobby, PLAY, packs, market, training slots), which confirms that the sport is a swappable layer on top of one shared loop.

## What round 2 changes for us
| Area | Decision |
|---|---|
| Lineup | Basketball is 5 on the floor plus a bench. We keep a **starting five plus 3 bench** spots and **lineup presets** (Small Ball, Twin Towers, Balanced) in place of formations. |
| Chemistry | Shown as a % that grants a flat bonus to every stat, next to a single **Team Power** number. |
| Training | **3 timed slots** with a stat focus, sessions run while offline, and progress stops at potential. |
| Collection | Cards show **career stats** (points, rebounds, assists, MVPs) plus a potential cap. |
| Market fee | Raise our fee from 5% to **15%** so the market removes money from the economy. A VIP perk lowers it, but never to zero. |
| Competitions | Add **Weekend Tournaments**: a points race whose entry needs fans. Our own names and formats. |
| Match camera | Bench camera behind the coach, a **REPLAY** close-up after big plays, and a tag on the ball handler. |
| Club setup | First session: badge shape, two colors and a name. The colors paint your Home Court and kits. |
| Divisions | Shown on the club card next to fans. |

## What we will NOT copy
Its name or "Be a ___ Manager" title pattern, logo, characters, map, card frame art, UI layout and colors, its wording and banners, its rare-player shop and that tier's name, pass names, prices, and any real athletes' names or likenesses.
