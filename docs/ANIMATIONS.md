# Animations

Every animation the game needs, how it is built, and the sound cue each one triggers.

## How animations work in this game

- **One model for every player.** Players are blocky R15 characters with the club kit: a jersey with a number, shorts, shoes, and the player's generated face on the head. The walkout uses this same model, so the silhouette that walks out of the tunnel is the actual player model.
- **Clips are data.** Each animation is a list of keyframes per joint (`src/shared/AnimClips.lua`), and `src/client/AnimPlayer.lua` plays it by writing `Motor6D.Transform` every frame. Matches are simulated on the server and drawn on each client, so client-side playback is enough. It also means we don't have to upload an animation asset for every move.
- **Sounds are part of the clip.** Each clip has `events = { {time, sound} }`. They fire on the clip's own clock, so a dribble sound lands exactly on the bounce, even if the frame rate drops. Never time a sound with a separate `task.wait`.
- **Authoring and preview.** Clips are authored in the 3D prototype (`docs/prototypes/walkout3d.js`, shown live on the UI page). `python3 scripts/gen_animclips.py` converts it to `AnimClips.lua`. The page and the game play the exact same numbers. For polish we can import the clips into Roblox's Animation Editor or Moon Animator, or into Blender, once js's computer is free.
- **Blending.** Clips cross-fade over 0.12 s by default. Locomotion (idle, jog, sprint, defensive slide) loops. Moves play once and hand back to locomotion.

## Walkout (pack opening)

| Clip | Length | Used for | Sound cues |
|---|---|---|---|
| Walk | 1.0 s loop | Silhouette walks out of the tunnel | ShoeSqueak when it stops |
| Shoot | 2.3 s | Snipers: dip, jump, release, follow-through | ShoeSqueak 0.35 s (dip), ShoeSqueak 1.33 s (landing), CrowdCheerM 1.5 s (ball drops in) |
| Dunk | 2.6 s | Slashers and post scorers: two-step run, leap, one-hand slam, hang, land, flex | ShoeSqueak at each step, RimOut 1.13 s (slam), CrowdCheerL 1.18 s, Dribble when the ball bounces |
| Dribble | 2.4 s | Floor generals and all-around players: low stance, two pounds, crossover, two pounds, crossover back | Dribble on every floor contact (7), ShoeSqueak on each crossover |
| Block | 2.4 s | Rim protectors, lockdown defenders, glass cleaners: load, jump, swat, land | ShoeSqueak 0.36 s, Dribble 0.76 s (hand hits ball), CrowdOoh 0.82 s, ShoeSqueak 1.23 s |
| Pose | 1.2 s, holds | Lights up: turns to camera and flexes | CrowdCheerL |

Order: clues (nation top left, position right, archetype bottom left) → Walk → move → OVR slams → lights up on Pose with the real kit and face.

## In-game (match)

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

## Still needs js's computer

- Import the clips into Studio and check them on the real R15 rig at game speed.
- A rig in Blender for the walkout poses if we want hand-tuned curves.
- Upload the missing sounds (swish, dunk, block slap) from the Creator Store so the cues above have their sounds.
