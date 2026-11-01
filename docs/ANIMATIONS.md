# Animations

Every animation the game needs, how it is built, and the sound cue each one triggers.

## How animations work in this game

- **One model for every player.** Players are blocky R15 characters with the club kit: a jersey with a number, shorts, shoes, and the player's generated face on the head. The walkout uses this same model, so the silhouette that walks out of the tunnel is the actual player model.
- **Clips are data.** Each animation is a list of keyframes per joint (`src/shared/AnimClips.lua`), and `src/client/AnimPlayer.lua` plays it by writing `Motor6D.Transform` every frame. Matches are simulated on the server and drawn on each client, so client-side playback is enough. It also means we don't have to upload an animation asset for every move.
- **Sounds are part of the clip.** Each clip has `events = { {time, sound} }`. They fire on the clip's own clock, so a dribble sound lands exactly on the bounce, even if the frame rate drops. Never time a sound with a separate `task.wait`.
- **Authoring and preview.** Clips are authored in the 3D prototype (`docs/prototypes/walkout3d.js`, shown live on the UI page). `python3 scripts/gen_animclips.py` converts it to `AnimClips.lua`. The page and the game play the exact same numbers. For polish we can import the clips into Roblox's Animation Editor or Moon Animator, or into Blender, once js's computer is free.
- **Blending.** Clips cross-fade over 0.12 s by default. Locomotion (idle, jog, sprint, defensive slide) loops. Moves play once and hand back to locomotion.

## What real basketball movement looks like (study, 2026-11-01)

These numbers are what the clips are tuned to. They come from published motion-capture studies and coaching material (sources at the bottom). Our characters are blocky, so we keep the timing and the shapes and push the poses a little for readability.

| Move | What real players do | What the clip does |
|---|---|---|
| Jump shot | Dip to a knee angle of about 110–115°, then extend to about 165–170° at release. The elbow is about 80–90° at the set point and about 160° (20° short of straight) at release. **Good shooters release on the way up, before the top of the jump.** Release angle is 50–60°. Proficient shooters stay upright and lean forward less. | Dip at 0.30 s, takeoff 0.55 s, release 0.72 s, apex 0.82 s, land 1.08 s. About 0.5 s in the air. The shooting arm finishes about 40° above horizontal (not straight up, which read as a block) and **holds the follow-through until the ball drops**. |
| Ball flight | A deep jumper takes about 1 s to reach the rim at 7–7.6 m/s. | Ball reaches the rim about 1.0 s after release, with a high arc. |
| Layup | One-foot takeoff off the **opposite** foot (right hand, left foot). The last step is long and low, and the free knee drives up. Push-off height can exceed half the player's height. | Gather, right step, plant left, right knee up, release at the top, land, recover. |
| Dunk | Same footwork as the layup with a faster approach. Upward takeoff speed is about 3.5–3.8 m/s, which is a jump of about 0.5–0.6 m and about 0.7 s in the air. One-foot takeoffs are faster, and two-foot takeoffs go a little higher. | Penultimate step lowered, takeoff off the left foot with the right knee driving (this was the wrong leg before), slam at 1.12 s, short rim hang, two-foot landing. |
| Dribble | A live pound dribble bounces about 2–3 times a second, and a low dribble is faster. The ball always comes back to a hand before a crossover. | 2.5 bounces a second. **Fixed:** the old crossover bounced the ball twice on the floor with no hand in between. |
| Block | Two-foot jump, timed so the hand meets the ball at the top of the jump, arm straight. | Hand meets the ball at 0.76 s, at the apex. |
| Rebound | Read the miss, load, jump with both hands high, and "chin" the ball with the elbows out. | Catch at the top, then chin it as the player lands. |
| Chest pass | Step toward the target, extend the arms, turn the thumbs down, and follow through. | Release at 0.45 s on the step. |
| Defensive slide | Wide, low stance. Push off the trail foot and never cross the feet. Hands active. | Feet open and close, and never cross. |

**Skilled-player style** (from studying Practical Basketball on Roblox and real guards; we don't copy its animations, only learn what makes moves look skilled):

- **Body and ball size:** players have a slim athletic build (narrow torso, thin long limbs) and the ball is a little wider than the head. Our first chunky model made the ball look tiny. The rim is about twice the ball. In Roblox, use a slim R15 body scale for the same look.
- **Wrists and ankles:** the rig now has wrist and ankle joints (R15 has them). The shot ends in a wrist snap ("goose neck"), every dribble push is a wrist snap, and feet stay flat on the floor in a crouch and point their toes in the air (automatic, so clips don't need ankle keys).
- **Dribble posture:** low and wide, chest up, eyes up, off arm out as an arm bar, the body bobs on each push, and the hand rides the ball back up instead of slapping it.
- **Separate moves that chain:** live dribble, crossover, between the legs, behind the back and hesitation all start and end in the same pose, so the game can chain any of them (the walkout combo is four of them chained).
- **One-motion jumper:** the ball goes from the shot pocket straight up the middle to a set point above the forehead with the wrist cocked, the guide hand stays quiet on the side, and the feet are slightly staggered.

**Game-feel rules we follow** (from game animation practice):

- Keep the wind-up short. Put the "ready" feeling into the idle stance so a move can start right away.
- Transitions are part of the animation. Blend into and out of every clip, and make sure a clip can be interrupted cleanly (for example, a pass cancelled into a shot).
- The silhouette must read from the match camera. That's why the shooting arm and the block arm are clearly different now.
- Put contact frames (bounce, release, rim, catch) on exact keys and hang sounds on them.

Sources:

- [Jump shot kinematics at 4.75 m and 5.75 m (Journal of Sports, 2025)](https://www.journalofsports.com/pdf/2025/vol10issue2/PartE/10-2-61-835.pdf)
- [Proficient vs non-proficient shooters (Frontiers, 2023)](https://www.frontiersin.org/journals/sports-and-active-living/articles/10.3389/fspor.2023.1208915/pdf)
- [Release the ball early for better jump shots (Physical Education Update)](https://www.physicaleducationupdate.com/public/329.cfm)
- [Three-step layup ankle biomechanics (PMC)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10618240/)
- [One-foot vs two-foot takeoff (ISBS)](https://ojs.ub.uni-konstanz.de/cpa/article/view/4049/3748)
- [The 12 principles of animation, reframed for games (Animworks)](https://anim.works/?p=23056)

## Walkout (pack opening)

| Clip | Length | Used for | Sound cues |
|---|---|---|---|
| Walk | 1.0 s loop | Silhouette walks out of the tunnel | ShoeSqueak when it stops |
| Shoot | 2.6 s | Snipers: dip, jump, release on the way up, held follow-through | ShoeSqueak 0.30 s (dip), ShotRelease 0.72 s, ShoeSqueak 1.08 s (landing), Swish 1.85 s, CrowdCheerM 1.9 s |
| Dunk | 2.6 s | Slashers and post scorers: two steps, long low last step, left-foot takeoff, one-hand slam, hang, land, flex | ShoeSqueak 0.42 s and 0.62 s, Dunk and RimOut 1.12 s (slam), CrowdCheerL 1.18 s, Dribble when the ball bounces |
| Dribble | 2.4 s | Floor generals and all-around players: low stance, two pounds, crossover, two pounds, crossover back | Dribble on every floor contact (7), ShoeSqueak on each crossover (0.85 s, 1.85 s) |
| Block | 2.4 s | Rim protectors, lockdown defenders, glass cleaners: load, jump, swat, land | ShoeSqueak 0.36 s, Block 0.76 s (hand hits ball), CrowdOoh 0.82 s, ShoeSqueak 1.23 s |
| Pose | 1.2 s, holds | Lights up: turns to camera and flexes | CrowdCheerL |

Order: clues (nation top left, position right, archetype bottom left) → Walk → move → OVR slams → lights up on Pose with the real kit and face.

## In-game (match)

**Built so far** (in `AnimClips.lua` and the Animation lab on the UI page, mapped from match plays by `AnimClips.ForPlay`):

| Clip | Length | Sound cues |
|---|---|---|
| Idle (loop) | 2.0 s | none |
| Jog (loop) | 0.7 s | ShoeSqueak |
| DefSlide (loop) | 0.9 s | ShoeSqueak on each push |
| Layup | 2.2 s | ShoeSqueak on steps, LayupKiss 0.85 s, Swish 1.22 s, CrowdCheerM |
| ChestPass | 1.2 s | PassChest 0.45 s |
| Rebound | 2.0 s | ReboundGrab 0.75 s |
| Shoot, Dunk, Dribble, Block | see the walkout table | |

**Still to build:**

| Group | Clips | Sync points |
|---|---|---|
| Locomotion | Idle, Jog, Sprint, BackPedal, DefensiveSlide (L/R), Stance (offense, defense) | Squeaks on direction changes |
| Ball handling | Dribble (R, L), Crossover, BetweenLegs, BehindBack, Hesitation, PickUp | Dribble on each floor contact |
| Passing | Chest, Bounce, Overhead, Lob, NoLook, Catch | Pass sound on release, Catch on contact |
| Shooting | JumpShot, PullUp, StepBack, Fadeaway, Hook, FreeThrow (routine with 2 bounces), Floater, Layup (R, L), ReverseLayup | ShotRelease on release, Swish, RimIn or RimOut when the ball arrives |
| Dunks | OneHand, TwoHand, Tomahawk, Windmill (Legendary and up), Putback, Alley-oop finish | Dunk on rim contact, rim rattle, CrowdCheer |
| Defense | Contest, Block, Steal (reach, poke), Take charge, Box out | Block slap, Steal swipe |
| Rebounding | Jump rebound, Tip, Secure | ReboundGrab on catch |
| Reactions | Celebrate (fist pump, chest bump, three-point goggles), Frustrated, Ref argue, Help up teammate | Crowd reacts |
| Bench and coach | Coach clap, Coach point, Coach clipboard (timeout), Bench stand and cheer, High fives on subs | Whistle on timeout |
| Clutch | Slow-mo shot (0.4× speed), Buzzer-beater celebration pile-up | Buzzer, CrowdRoar |

Signature moves: a few dunks and celebrations are locked to Legendary and Hall of Fame cards (for example Windmill), so pulling one is something you can see.

## UI motion (not character animation)

- Pack: drop, shake, rip, cards fly out, flip, badge info flip (tap again), walkout.
- Shop: buy popup scales in. Bundle box shows a stacked box with ×5 or ×20.
- Badge applier: eligible players glow green, and the slot fills with a pop when equipped.

## Signature moves (src/shared/AnimSets.lua)

Every player rolls these once when generated and keeps them (saved as `player.anims`).

| Set | Options (rarest last) |
|---|---|
| Shot style | Textbook, Quick Release, High Release, Set Shot, Fadeaway (Rare+) |
| Dunk package | One-Hand, Two-Hand, Tomahawk (Rare+), Windmill (Epic+), 360 (Legendary+) |
| Dribble moves | Crossover, In-and-Out, Hesitation, Between the Legs (Rare+), Behind the Back (Rare+), Spin (Epic+), Step-Back (Epic+) |

Commons know 1 dribble move, Rares 2, Epics and Legendaries 3, Hall of Famers 4. Snipers lean toward
quick and high releases; Slashers and Post Scorers toward flashier dunks. Hands have a palm, four
fingers and a thumb so wrist flicks read on court.

## Practical Basketball reference (watched on js's Mac, 2026-11-01)

Watched two videos in Chrome through screenshots (about one frame a second, so this is
pose and style, not timing). Their camera sits behind the player, not side-on like ours.

- Bodies: plain blocky R15 with hair and chunky sneakers. Narrow body type, long legs. The
  ball is about the size of the head and sits low at the hip when dribbling.
- Defense: deep knee bend, chest up, both arms spread wide to the sides with palms out.
  Slides leave a short dashed trail on the floor.
- Running: about 15° forward lean, big arm pumps, ball pushed out in front on a drive.
- Dunks: the player glides high and the rim and net flex; a white light burst plays at the rim.
- Feedback ideas that fit our sim: a ring under the ball handler's feet, and shot text like
  "Perfect Release" or "0% Contested" next to the shooter.

What we changed from it: DefSlide arms go wider, and player bodies use slim limbs
(src/shared/PlayerModel.lua).

## Still needs js's computer

- Upload ShotRelease, Swish, LayupKiss, Dunk, Block and PassChest sounds. The cues already fire, and the lab shows them as "to upload".
- Import the remaining clips into Studio (Shoot, Idle and 11 more are in; BetweenLegs, BehindBack, Hesitation, Dribble, BouncePass and ForPlay are not yet).
- A rig in Blender for the walkout poses if we want hand-tuned curves.
- Upload the missing sounds (swish, dunk, block slap) from the Creator Store so the cues above have their sounds.

## Rebound and block reference (stepped frame by frame, timings ±0.15–0.2 s)

Sources: slow-motion rebound (youtube.com/watch?v=PNnHNhOoKsU, about 20x), Steven Adams playoff offensive boards (wH_EDYN6TMU), Sport Science on LeBron's 2016 chase-down (kExlzEaOCYU), Ja Morant two-hand block (tbqtVPHBsIw).

- **Two-hand rebound:** gather ~0.35 s (arms swing back, quarter-to-half squat, eyes on the ball), explode ~0.18 s (both arms straight up, two-foot takeoff), catch at the peak ~0.25 s after takeoff with arms fully extended, land ~0.55 s after takeoff on the same spot. Arms stay overhead until the feet touch; the chin pull happens in ~0.12 s after landing, then a ~0.15 s settle into a deep, wide crouch with elbows flared. The Rebound clip follows this.
- **Box-out scrum:** 3–4 bodies on the low block ~0.5 s before the miss arrives; box-out is a wide stance, butt into the opponent, arms out at shoulder height. The rebounder leaves the floor ~0.5 s after the shot goes up and is up for ~0.5 s. Ball out of the paint 1–1.5 s after the grab. Outlet (typical, not measured): 0.5–0.8 s from landing to release.
- **Chase-down block:** trailer closes at ~1.2–1.4x the shooter's speed, takes off one foot about a step behind on the shooter's off-arm side, contact ~0.25–0.3 s after takeoff at the top of the reach, arm straight and hand open, pinning the ball to the glass. Momentum carries them past the rim; they land 1–2 steps beyond it.
- **Two-hand block on a dunk:** blocker trails one body length on the help side, takes off one foot from farther out than the dunker, contact ~0.4 s after takeoff with both hands on the ball at or above the rim, arms vertical (not a side swipe). Blocker drifts past the backboard and lands out of bounds (~1 s airtime). Dunker lands under the rim and stumbles back a step; ball pops back out toward the free-throw line or off to the side.
- **To do in the game:** the current block uses the single-hand Block clip from a standing rotation. A one-foot chase-down/two-hand block clip with forward carry, and the dunker's stumble, would match the reference better.
