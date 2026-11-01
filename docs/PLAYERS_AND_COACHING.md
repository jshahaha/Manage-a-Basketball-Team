# Players, Stamina, Bench & Coaching Staff

This is the detailed design for player ratings, stamina, the bench, minutes and coaches. It expands section 4 of [MAIN_GAME_IDEA.md](MAIN_GAME_IDEA.md).

## 1. Player ratings

Every rating runs from 1 to 99. There are 20 ratings in 6 groups.

| Group | Ratings | What they drive in the sim |
|---|---|---|
| **Shooting** | Mid-Range (2PT), Three-Point (3PT), Free Throw | Jump-shot make %, how often the player looks for threes, and free throws |
| **Finishing** | Layup, Driving Dunk, Standing Dunk, Close Shot, Post Moves | Make % at the rim, the chance of an and-one, and which animation plays (dunk or layup) |
| **Playmaking** | Passing, Ball Handling | Assists, turnovers, and how easily the player creates a shot |
| **Defense** | Interior Defense, Perimeter Defense, Steal, Block | How much the player lowers the make % of the man they guard, plus steals and blocks |
| **Rebounding** | Offensive Rebound, Defensive Rebound | Second chances and ending the other team's possessions |
| **Athleticism** | Speed, Strength, Vertical, **Stamina** | Fast breaks, winning in the post, dunk and block reach, and how fast energy drains |

**On the card:**
- The front shows OVR, position, archetype and the 6 group scores (SHO, FIN, PLY, DEF, REB, ATH). This keeps cards readable on a phone.
- The detail panel shows all 20 ratings, the player's potential cap and their career stats.

**OVR** is a weighted average that depends on position:
- **PG:** Passing, Ball Handling, 3PT and Speed count most.
- **SG:** 3PT, Mid-Range, Perimeter Defense and Speed count most.
- **SF:** a balanced mix of Shooting, Finishing, Perimeter Defense and Athleticism.
- **PF:** Close Shot, Post Moves, Interior Defense, Rebounding and Strength count most.
- **C:** Standing Dunk, Block, Interior Defense, Rebounding and Strength count most.

**Physicals:** height and wingspan are shown on the card, such as 6'9" with a 7'1" wingspan. Players have no rating for them, but they nudge blocks, rebounds and contested shots.

**Archetypes** come from the ratings. For example, high 3PT gives Sniper, high Driving Dunk plus Speed gives Slasher, high Block plus Interior Defense gives Rim Protector, and high Passing plus Ball Handling gives Floor General. Chemistry uses archetypes.

**Training** focuses on one group, and the XP is spread across that group's ratings. The "All" focus gives smaller gains to everything.

## 2. Stamina & energy

- Each player has **Energy** from 0 to 100% during a game. Energy drains faster when:
  - the player's Stamina is lower
  - the team runs Pace & Space or Press, which drain more
  - the player has heavy usage, meaning lots of shots and drives
- Energy recovers while the player sits on the bench, and partly at quarter breaks and at halftime.
- **Low energy hurts:**
  - Below 70%, shooting and defense drop a little.
  - Below 40%, they drop sharply and turnovers go up.
  - The sim shows a tired icon on that player's tag.
- Energy resets fully after every game, so stamina never blocks you from pressing PLAY.

## 3. Bench & rotation

- **Matchday roster: 10 players.** That's 5 starters and 5 bench players. The rest of your club stays in your collection (capacity limits still apply).
- Bench players sit on the bench next to your coach avatar in 3D, so the side-on camera shows them.
- **Substitutions:**
  - The sim substitutes automatically to follow your minutes plan (section 4).
  - It also subs out players who are in foul trouble (4 fouls in the first half, or 5 fouls) or whose energy has run low.
  - During a timeout or a quarter break you can make a **manual sub** by dragging a bench player onto a starter.
- **Fouling out:** a player is out of the game at 6 fouls.

## 4. Minutes allocation

- A game has **4 quarters of 12 minutes on the game clock**, which is 48 game minutes. The real game still plays in about 2 to 3 minutes because the clock runs fast.
- Each team has **240 player-minutes** (5 players × 48 minutes). The Rotation screen has a slider for each of the 10 players, from 0 to 48 minutes, and a counter that must show exactly **240 / 240**.
- **Auto Minutes** fills in a sensible plan from OVR and Stamina. A usual plan looks like:
  - starters at about 30 to 36 minutes each
  - the first 3 bench players at about 12 to 20 minutes each
  - the last 2 bench players at about 0 to 6 minutes
- The sim tries to hit your targets. Foul trouble, fatigue and blowouts can move the real minutes by a few, and the box score shows target versus actual.
- **Trade-offs:**
  - Starters on heavy minutes get tired, and tired players play worse.
  - Spreading the minutes keeps everyone fresh but gives more floor time to weaker players.
  - High-Stamina players can carry 38 or more minutes well.
- **Minutes presets** are saved along with each lineup preset.

## 5. Coaching staff

Your avatar is always the **Head Coach**. You hire up to **4 staff coaches**, who stand at the bench during games.

| Staff role | What it boosts |
|---|---|
| **Offensive Coordinator** | The strength of your offensive tactic, and team shooting and finishing in games |
| **Defensive Coordinator** | The strength of your defensive tactic, and the defensive ratings of your players |
| **Player Development** | Training XP and training speed |
| **Strength & Conditioning** | How fast energy drains and recovers in games, and fewer injuries if we add them later |

- **Each coach** has a rarity (Common to Hall of Fame), a rating from 1 to 99 for their role, and one **specialty trait**. For example:
  - **Three-Point Guru:** +3PT for Snipers
  - **Rim Protection:** +Block and Interior Defense for bigs
  - **Pace Lover:** Pace & Space drains less energy
  - **Clutch Caller:** your Clutch Timeout play gets a bigger boost
- **How you get coaches:**
  - Hire them at the **Coaching Office** station in the plaza. It has a rotating list of 3 coaches that refreshes every few hours, and you pay with coins.
  - A rare coach can also drop from higher-tier packs.
  - Coaches can be sold on the market like players.
- **Coach chemistry:** a staff coach whose specialty matches your tactics or archetypes adds a little chemistry.
- Staff appear as 3D characters on your bench and on your Home Court, wearing your club colors.

## 6. What this means for the sim code

The existing `MatchSim` already handles possessions, fatigue, fouls and rotation. To support this design it needs these changes:
- Swap its 6 stats for the 20 ratings above.
- Pick the shot type (3PT, mid-range, layup, dunk, close shot or post-up) from the players' ratings, then use the matching rating for the make %.
- Track energy for each player and follow the minutes targets when making subs.
- Apply the staff coach boosts.
