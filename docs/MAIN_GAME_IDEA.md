# Main Game Idea

**Working title:** Manage a Basketball Team (in-game brand: *Hardwood Dynasty*. We can pick one before launch.)
**Platform:** Roblox, written in Luau and synced with Rojo
**Genre:** Sports management sim (you run the club and don't control a player)

## One-line pitch

Start a basketball franchise from nothing. Scout and develop players, set the game plan, and call the clutch play in the final two minutes as you climb from the Rec League to the Dynasty Elite.

## Where the idea comes from (and what we don't copy)

The reference is a Roblox club-management sim in another sport. We take the **genre conventions** that are common to the whole management-sim category:

- create a team, collect players, train them, simulate matches, earn money and fans, and climb leagues

We do **not** copy that game's name, branding, logo, assets, map, UI layout, text, or its signature features, such as its card-pack opening, its secret market or its icon players. Every system below has been redesigned for basketball and has its own twist. See [GENERAL_RULES.md](GENERAL_RULES.md#originality).

## Core loop

```
Scout prospects ─► Sign one ─► Train skills ─► Set lineup & game plan
      ▲                                              │
      │                                              ▼
  Spend cash ◄── Earn cash + fans ◄── Play live game (call Clutch Timeouts)
                         │
                         ▼
           Season ends ─► Promotion / relegation ─► New season
```

A session of 5 to 10 minutes covers one game, a few drills and a scouting trip. A full season is 10 games.

## Systems

### 1. Franchise creation
- You choose a team name and city (both run through Roblox text filtering), two colors from a 12-color palette, and an emblem (★ ◆ ⚡ ♛ …).
- A three-letter short code (for example `HAW`) is generated for the scoreboard.
- You start with 8 players (one per position plus 3 extras), $3,000 and 50 fans.

### 2. Players
- **Positions:** PG, SG, SF, PF, C
- **Six skills (1–99):** Shooting, Finishing, Playmaking, Defense, Rebounding, Athleticism
- **Overall** is a weighted mix of the skills that depends on position. For example, a C's overall leans on Finishing, Defense and Rebounding.
- **Potential:** each skill has a hidden cap. Scouting only shows potential as a range, for example "OVR 54 · POT 61–66".
- **Age** sets how fast a player grows. Players 21 and under grow fast and those over 32 grow slowly. Players age every season, and from 32 they start to decline.
- **Tiers:** Prospect (grey), Rotation (green), Starter (blue), All-Star (purple), Legend (gold)

### 3. Scouting (replaces "card packs")
You send scouts to an event and they bring back **3 prospects**. You **sign one** and the other two are gone. You make a choice instead of just opening a pack.

| Event | Cost | Odds (Prospect / Rotation / Starter / All-Star / Legend) |
|---|---|---|
| Local Gym Run | $400 (free every 4h) | 70 / 25 / 4.6 / 0.38 / 0.02 % |
| College Showcase | $2,500 | 25 / 45 / 25 / 4.7 / 0.3 % |
| Global Combine | $12,000 | — / 20 / 52 / 25 / 3 % |

The Scouting Department upgrade raises the odds of Starter tier and above. The roster cap is 13, so you sometimes have to release a player, which pays back some cash.

### 4. Development (training)
- There are six drills, one per skill: Shootaround, Finishing Circuit, Film & Passing, Defensive Slides, Box-Out Battles and Conditioning.
- Each drill costs **25 energy** and some cash, which goes up as the skill gets higher. Energy regenerates over time, and the Recovery Center makes it regenerate faster.
- Each drill gives +0 to +3 to the skill, scaled by age and the Training Center level. You can't train a skill past its hidden cap, and the last few points come more slowly.

### 5. Game plan
Before each game you pick one offense and one defense. Offenses and defenses counter each other in a small rock-paper-scissors:

| Offense | Strong vs | Weak vs |
|---|---|---|
| Pace & Space (fast, many threes) | Zone | Press |
| Inside Out (post-ups, paint) | Man | Zone |
| Motion (cuts, assists) | Press | Man |

Before tip-off you can see the opponent's tactics, so you can counter them. The effect is small, about ±2.5% on make chance, so talent still matters most.

### 6. Live games
- Games are simulated one possession at a time on the server, covering turnovers, steals, shot selection, blocks, fouls, free throws, offensive rebounds, fatigue and substitutions.
- You watch on the 3D court. Players appear as colored tokens with numbers and the ball arcs to the rim. A play-by-play feed and a scoreboard sit on screen, and you can watch at 1×, 2× or skip.
- **Highlights** (dunks, buzzer-beaters, late lead changes) slow down and show a banner.
- **Clutch Timeout:** in the last 2:00 of the 4th quarter, when the game is within 6 points, the game pauses on your possession and you pick a play:
  - **Isolation:** your best scorer goes one-on-one
  - **Pick & Roll:** a two-man game between your best playmaker and your best big
  - **Kick-Out Three:** a drive and kick to your best shooter
  - **Let them play:** keeps your timeout for later
  You get 2 per game. This is the main "I'm the coach" moment.
- Scoring and balance were tested over 1,000+ simulated games. Teams average about 95 to 110 points, and overtime happens.

### 7. Seasons & divisions
- There are 8-team divisions (you plus 7 AI franchises) and seasons are 10 games long.
- Division ladder: **Rec League → Regional Circuit → National Pro → Dynasty Elite**
- At the end of a season the top 2 are promoted and the bottom 2 are relegated. Prize money depends on where you finish.
- In the off-season every player ages by one year.

### 8. Economy
| Source | Notes |
|---|---|
| Game result | Win/loss payouts go up with the division |
| Ticket sales | Home games only: fans × Seating Bowl level |
| Season prize | Depends on where you finish |
| Team Store | Passive income every minute you're online |
| Exhibitions | Small payout |
| Codes | `TIPOFF`, `FASTBREAK` |

### 9. Arena upgrades (5 levels each)
These are Seating Bowl, Training Center, Scouting Department, Recovery Center and Team Store.

### 10. Social
- **Exhibition challenge:** challenge any manager in your server. Both of you watch the same game and both of you can call Clutch Timeouts.
- **Direct trades:** offer up to 5 of your players plus optional cash for up to 5 of theirs. Everything is checked again on the server when the trade is accepted.
- The leaderboard shows your Division and Fans.

## Technical shape

- **Server-authoritative:** every purchase, drill, trade and match result is computed on the server.
- The **shared** modules (Config, Rng, PlayerFactory, MatchSim) are pure Luau, so the sim can be unit-tested outside Roblox.
- One `RemoteFunction` handles requests and one `RemoteEvent` handles server pushes.
- Data is saved to DataStore with autosave, plus a save when a player leaves and when the server shuts down.
- The arena is built from parts in code, so no imported assets are needed for v0.1. Custom meshes can come later from Blender.

## Status

Design and UI are **in review**. The match sim and server services are drafted locally but not committed. They will land after the design and UI are approved.
