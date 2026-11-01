# Players, Stamina, Bench & Coaches

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

## 1b. Names & player icons

- **Names are fictional.** Real NBA or WNBA names and faces are licensed, and near-copies like "LeBron Jamez" count too, so using either risks a copyright takedown.
- **Play styles can be based on real players.** A card's ratings and archetype can match a type everyone knows, like a deep-range shooter, a dunking point forward or a 7-foot rim protector.
- **Every player has an icon:** a blocky cartoon head and shoulders built from their ID. The generator picks skin tone, hairstyle, headband, eyebrows, mouth and facial hair. The same icon appears on every screen, and the 3D character matches it. Coaches wear a suit and tie.
- Hall of Fame legends get hand-made icons and models, which can be built in Blender.

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

## 4b. Go-To Player & shot tendencies

These are set on the Rotation screen. You can also change them at a timeout or quarter break.

- **Go-To Player (star):** mark one player with a ⭐.
  - They get about 25% more touches and shots.
  - When the Clutch Timeout calls Isolation, they take the last shot.
  - Their energy drains about 10% faster, because carrying the team is tiring.
  - You can mark a **Second Option** (☆) for a smaller boost.
- **Shot tendency bar:** one slider for the whole team, running from **Inside ← → Outside**.
  - Each player's shot mix starts from their ratings. A Sniper shoots threes and a Post Scorer posts up.
  - The bar shifts every player's mix together. Outside means more threes and mid-range shots. Inside means more drives, post-ups and dunks.
  - The game shows the result as a projected mix, such as "38% threes · 22% mid-range · 40% at the rim".
  - The bar stacks with play style. 5-Out already leans outside, and Inside Out already leans inside.
- **Per-player tendencies** (optional, later): a small 3-way split (3PT / Mid / Rim) on each player's card for managers who want fine control. The team bar covers most people, so this stays an idea for now.
- **Box score:** it shows each player's usage (share of team shots), so you can see whether your star actually got the ball.

## 5. Coaching staff: Offensive Coach + Defensive Coach

Your avatar is the **Head Coach**. You hire **two coaches**, and they decide **how your team plays**. Both stand on your bench during games.

### Play styles
Each coach knows **one main play style** and sometimes a second one. Your team can only run styles that your coaches know, so finding the right coach is how you change the way you play.

**Offense (Offensive Coach):**

| Style | How it plays | Players it suits | Strong vs | Weak vs |
|---|---|---|---|---|
| **5-Out** | All five players spread out past the arc. You get drives and kick-outs for threes | Snipers, ball handlers, a big who can shoot | Zone | Switch Everything |
| **Pace & Space** | Fast breaks and early threes, with the most possessions per game | Fast guards, high Stamina | Drop Coverage | Full-Court Press |
| **Inside Out** | Feed the post, and shooters spot up when the defense collapses | Post scorers, Strength, Close Shot | Switch Everything | 2-3 Zone |
| **Pick & Roll** | Ball handler plus a rolling big, with lots of dunks and lobs | A Floor General and a dunking big | Man-to-Man | Drop Coverage |
| **Motion** | Constant cutting and passing, so no single star is needed | High Passing across the team | Full-Court Press | Man-to-Man |
| **Iso Star** | Clear out and give the ball to your best scorer | One very high OVR scorer | Drop Coverage | 2-3 Zone |

**Defense (Defensive Coach):**

| Style | How it plays | Players it suits | Strong vs | Weak vs |
|---|---|---|---|---|
| **Man-to-Man** | Everyone guards their own player | High Perimeter D | Motion, Iso Star | Pick & Roll |
| **2-3 Zone** | Protects the paint and gives up corner threes | Tall bigs, Block, Interior D | Inside Out, Iso Star | 5-Out |
| **Switch Everything** | Swaps on every screen | Versatile defenders with similar sizes | 5-Out | Inside Out |
| **Drop Coverage** | The big stays back to protect the rim | A Rim Protector center | Pick & Roll | Pace & Space, Iso Star |
| **Full-Court Press** | Pressure all over the court that forces turnovers, but **drains energy fast** | Speed, Steal, high Stamina | Pace & Space | Motion |

- "Strong vs" is a small edge, not a guaranteed win. Under [General Rules](GENERAL_RULES.md), no style should win more than about 60% of the time.
- **Switching during a game:** between quarters, or at a timeout, you can change to any other style your coaches know.

### Coach cards
- **What a coach has:**
  - A rarity from Common to Hall of Fame.
  - A **Coaching rating** from 1 to 99. A higher rating makes their style stronger.
  - Their play style or styles.
  - One **trait**. For example:
    - Three-Point Guru gives +3PT inside their system.
    - Rim Protection gives more blocks in a zone.
    - Conditioning Freak makes the press drain less energy.
    - Clutch Caller makes your Clutch Timeout play stronger.
- **Fit:** when your roster's archetypes match the coach's system, your team gets bonus chemistry. For example, four Snipers with a 5-Out coach.
- **How you get coaches:**
  - Hire them at the **Coaching Office** in the plaza, which shows 3 coaches and refreshes every few hours. You pay with coins.
  - Rare coaches can also drop from higher-tier packs.
  - You can sell coaches on the market.
- **Free coaches:** every new club starts with a free Common coach for each side, one running Motion and one running Man-to-Man.

## 6. What this means for the sim code

The existing `MatchSim` already handles possessions, fatigue, fouls and rotation. To support this design it needs these changes:
- Swap its 6 stats for the 20 ratings above.
- Pick the shot type (3PT, mid-range, layup, dunk, close shot or post-up) from the players' ratings, then use the matching rating for the make %.
- Track energy for each player and follow the minutes targets when making subs.
- Replace the 3-and-3 tactic matchups with the style table above, and apply the coach's rating and trait.
