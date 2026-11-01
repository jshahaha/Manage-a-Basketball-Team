# Audio: sound effects, crowd, music & commentator

This is every sound the game needs, which event plays it, and where each sound comes from. The code side lives in `src/shared/Sounds.lua`, a registry where every sound has a name and an asset ID. `src/client/Audio.lua` plays sounds by name. To fill in a sound, upload or pick it, then paste its asset ID next to its name in `Sounds.lua`. Until then the game plays nothing for it and doesn't error.

## Status (2026-11-01)
A first pass of 150 sounds is in `assets/audio/` (94 effects and 56 commentator lines), with sources in `assets/audio/CREDITS.md`. You can listen to them all on the UI page's Sound board. Next, upload them and paste the IDs into `Sounds.lua`. Still missing: music and a few crowd reactions.

## Where sounds come from
1. **Roblox Creator Store audio** (Toolbox → Audio). It's free and already licensed for use on Roblox. The search terms below are a good place to start. This covers most effects, the crowd and music.
2. **Our own uploads** for anything the store doesn't have or that we want unique: the pack opening stingers and the UI sounds. These can be made in any audio editor. Roblox has a monthly upload limit and checks every upload, so do these in batches.
3. **The commentator:**
   - Best option: record the lines yourself or with a friend, which gives the most personality.
   - Or use a text-to-speech or AI voice service that allows commercial use.
   - Never imitate a real broadcaster's voice or catchphrases.

   Every line is listed below, so whoever voices it can read straight through. Each line also shows as an optional subtitle.

**Volume groups** (players set each in Settings): Music · Effects · Crowd · Commentator. The commentator is ducked under big effects, and music is ducked during the game.

## 1. Game: ball & court
| Name | When | Store search terms |
|---|---|---|
| `Dribble` (×4 variants) | ball handler dribbling, randomized pitch | basketball dribble, bounce |
| `ShoeSqueak` (×4) | cuts, defense slides, random | sneaker squeak, gym shoe |
| `PassChest` / `PassBounce` | passes | basketball pass, catch |
| `Catch` | ball caught | ball catch slap |
| `ShotRelease` | jump shot leaves the hand | basketball shot release |
| `Swish` (×3) | clean make | swish, net |
| `RimIn` | make off the rim | rim bounce in |
| `RimOut` / `BackboardMiss` | misses | rim clang, backboard |
| `Airball` | airball (rare, crowd "AIR-BALL" chant follows) | whoosh miss |
| `LayupKiss` | off-glass layup | backboard bank |
| `Dunk` (×3) | dunk, rim rattle | basketball dunk rim shake |
| `DunkHeavy` | slow-mo highlight dunk, with bass hit | dunk slam impact |
| `Block` | blocked shot slap | block slap |
| `Steal` | steal swipe | swipe, whoosh |
| `ReboundGrab` | rebound secured | ball catch thud |
| `WhistleShort` | foul, violation | referee whistle short |
| `WhistleLong` | end of quarter if the buzzer is off, timeout | whistle long |
| `Buzzer` | end of quarter or game | basketball buzzer, horn |
| `ShotClockBeep` | last 5 s of the shot clock | beep countdown |
| `FreeThrowBounce` | shooter's routine | single dribble |

## 2. Crowd
| Name | When |
|---|---|
| `CrowdBed` (loop) | always under the game, louder in close games and in Q4 |
| `CrowdCheer` (S / M / L) | makes. L for threes, dunks and lead changes |
| `CrowdOoh` | near miss, big block |
| `CrowdGroan` | missed free throw, turnover by the home team |
| `CrowdRoar` | buzzer beater, clutch make, VICTORY |
| `CrowdDefenseChant` | "DE-FENSE" when the home team defends in Q4 within 6 |
| `CrowdAirballChant` | after an airball |
| `CrowdBoo` | technical foul against home, a failed challenge for the away team |
| `CrowdHush` | the clutch shot meter appears (crowd drops, heartbeat) |

## 3. Interactive moments & HUD in game
| Name | When |
|---|---|
| `TimeoutCall` | whistle and a "TIMEOUT!" banner slam |
| `CoachsCallPop` | Coach's Call prompt appears (short alert) |
| `CoachsCallTick` | 3-2-1 timer ticks |
| `CoachsCallGood` / `CoachsCallBad` | result of the call |
| `HeatUp` | player catches fire 🔥 (flame whoosh) |
| `FreezeUp` | player goes cold ❄ |
| `MatchupSwap` | defensive assignment changed |
| `ClutchHeartbeat` (loop) | during the clutch shot meter |
| `ClutchMeterPerfect` / `Good` / `Bad` | release timing result |
| `ChallengeReview` | coach's challenge, a tape-rewind whoosh |
| `ChallengeOverturned` / `ChallengeStands` | result |
| `BannerSlam` | AND-ONE!, FROM DOWNTOWN!, BIG BLOCK! banners |
| `SlowMoIn` / `SlowMoOut` | highlight slow-mo |
| `Victory` | VICTORY! sting and crowd roar |
| `Defeat` | soft, short sting, not punishing |

## 4. Lobby, menus & economy
| Name | When |
|---|---|
| `UIClick` / `UIBack` / `UIToggle` | every button |
| `UIOpenPanel` / `UIClosePanel` | panels slide |
| `UIError` | can't afford, invalid |
| `CoinsGain` (S / M / L) | coins added, counter rolls |
| `CoinsSpend` | purchase |
| `FansGain` | fans added |
| `QuestComplete` | quest finished toast |
| `AchievementUnlock` | achievement tier reached |
| `LevelUpTier` | Elo tier promotion |
| `TierDown` | demotion (soft) |
| `MatchFound` | VS screen slam |
| `QueueTick` | searching for a match (subtle loop) |
| `CodeRedeemed` | code success |
| `TrainingStart` / `TrainingDone` | training slots |
| `MarketSold` | your listing sold |
| `TradeRequest` / `TradeAccepted` | direct trades |
| `ScoutVanHorn` | the Traveling Scout arrives (server-wide) |
| `ServerAlertLegend` | someone pulled a Hall of Famer (server-wide) |

## 5. Pack opening (custom stingers, the big moment)
| Name | When |
|---|---|
| `PackDrop` | the pack slams onto the court floor |
| `PackShake` | pack rattles while you hold to open (gets more intense) |
| `PackRip` | foil tear |
| `CardWhoosh` | each card flies out face-down |
| `CardFlip` | tap to flip |
| `RevealCommon` | soft pop |
| `RevealRare` | bright chime |
| `RevealEpic` | rising synth swell and sparkle |
| `RevealLegendary` | big brass hit, crowd cheer, confetti pop |
| `RevealHallOfFame` | build-up drumroll, then stadium horn, crowd roar and announcer line |
| `FinishShimmer` | extra layer for Hot Hand, Ice Veins or Prism cards |
| `QuickSell` | coin pour |

## 6. Music
| Name | Where |
|---|---|
| `MusicLobby` (2–3 tracks) | upbeat hip-hop or funk instrumental, loops |
| `MusicMenu` | quieter variant under big panels |
| `MusicMatchIntro` | VS screen sting into tip-off |
| `MusicTimeout` | short loop under the timeout screen |
| `MusicVictory` / `MusicDefeat` | end screens |
| `MusicPackOpen` | builds while the pack shakes |

## 7. Commentator lines
Use one voice, energetic but friendly. `{name}` is a player's **last name** and `{team}` is a club name, so those parts are recorded separately or left out. Lines marked ★ are top priority. A commentator line never plays over another one. Lines queue up, and a line older than 2 seconds is dropped.

**Tip-off & flow**
- ★ "Here we go! Tip-off!"
- "Welcome in, folks. Big one today."
- "End of the first quarter."
- "That's halftime."
- "End of three. Twelve minutes to decide it."
- ★ "Final minute. Every possession counts now."

**Scoring**
- ★ "From downtown!" / "Bang! From deep!" / "He hits the three!"
- ★ "Throws it down!" / "Oh, what a slam!" / "Posterized!"
- "Smooth jumper." / "Pull-up, good!" / "Off the glass!"
- "Easy two." / "Finishes at the rim."
- ★ "And one!" / "And he gets the foul!"
- "Swish." / "Nothing but net."
- "Back-to-back threes!"
- "He's heating up!" (Heat check 🔥)
- "He is ON FIRE!" (on a third hot make)

**Defense & misses**
- ★ "Rejected!" / "Get that outta here!"
- "Picked off!" / "Stolen!"
- "Off the rim." / "Rattles out."
- "Air ball!"
- "Big rebound." / "Second chance!"
- "Turnover." / "Travel."
- "Shot clock violation!"

**Game state**
- "Lead change!"
- "Tie game!"
- "They're on a run here."
- "That's a double-digit lead."
- ★ "Timeout on the floor."
- "Here comes a challenge… let's look at the replay."
- "Call stands." / "And it's overturned!"
- "Big change on defense."

**Clutch & finish**
- ★ "Down to the last shot…"
- ★ "Buzzer beater! Unbelievable!"
- "Ice in his veins!"
- ★ "And that's the ballgame!"
- "What a finish!"
- "A statement win."

**Pack opening** (short, high energy)
- "Rare!" / "Epic!" / ★ "LEGENDARY!"
- ★ "A HALL OF FAMER! No way!"
- "Ooh, that's a Finish!"

## Rules
- Every sound file is short and trimmed, at most 3 s (loops and music excepted). Normalize everything to about −14 LUFS.
- Variants (×N) are picked at random, with ±5% pitch, so repeats don't sound robotic.
- Each sound has a short cooldown so 10 dribbles in a row don't stack.
- Only the player's own client plays their UI sounds. Game sounds come from the court position (3D) so other managers watching hear them too.
