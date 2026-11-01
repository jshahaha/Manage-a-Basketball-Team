# Audio files & credits

Real recordings for the game, as `.ogg` files ready to upload to Roblox. Upload them in Studio with **Asset Manager → Bulk Import**, then paste each asset ID into `src/shared/Sounds.lua`. Files named `Name_1`, `Name_2` and so on are variants of `Name`.

## Sources and licenses
- **Sonniss GDC Game Audio Bundles** (Sound Ex Machina's basketball game packs, plus UI, coin and card packs by the studios named below). Sonniss gives these away royalty-free for commercial use in games, with no credit required. You may not resell or share the raw files as a sound library, so keep the uploaded Roblox audio private to the game. Official download: https://sonniss.com/gameaudiogdc
- **BigSoundBank** recordings are CC0 (public domain). https://bigsoundbank.com
- All files were trimmed, faded and loudness-matched.

## One family per group
So sounds that play near each other match, each group comes from a single recording set at a single loudness:

| Group | Recording set | Loudness |
|---|---|---|
| Court (ball, rim, squeaks, whistles) | Sound Ex Machina basketball packs, BigSoundBank | −16 LUFS |
| Crowd (cheers, ooh, groan, boo, chant, win/loss) | Sound Ex Machina indoor basketball arena | −18 LUFS (crowd loop −26) |
| Menus | Kpow Sounds UI Soundpack 13 | −21 LUFS |
| Coins | CB Sound Design Essential Sounds Coins | −19 LUFS |
| Rewards (quests, achievements, codes, trades) | Cinematic Sound Design | −18 LUFS |
| Cards | Timothy McHugh Playing Cards | −19 LUFS |
| Reveals | Shapeforms Future UI (Rare, Epic), arena crowd (Legendary, Hall of Fame) | −18 to −16 LUFS |

## Still needed (pick from the Creator Store)
These had no good free recording, so pick them in Studio's Toolbox (Audio tab), which is already licensed for Roblox:

`Swish`, `RimIn`, `LayupKiss`, `Dunk`, `DunkHeavy`, `Block`, `Steal`, `Airball`, `PassChest`, `PassBounce`, `Catch`, `ShotRelease`, `ShotClockBeep`, `CrowdAirballChant`, `CrowdHush`, `TimeoutCall`, `BannerSlam`, `CoachsCallPop`, `CoachsCallTick`, `CoachsCallGood`, `CoachsCallBad`, `HeatUp`, `FreezeUp`, `MatchupSwap`, `ClutchHeartbeat`, `ClutchMeter (3)`, `Challenge sounds (3)`, `SlowMoIn/Out`, `PackDrop`, `PackRip`, `RevealCommon`, `FinishShimmer`, `LevelUpTier`, `TierDown`, `MatchFound`, `QueueTick`, `FansGain`, `TrainingStart/Done`, `ScoutVanHorn`, `ServerAlertLegend`, `all music`

## Commentator
The AI voice was dropped because it sounded flat. Options, best first:
1. Record the lines in `docs/AUDIO.md` yourself or with a friend, with real energy.
2. Use an expressive AI voice service that includes a commercial license on its paid plan (for example ElevenLabs). That needs your account.
3. Hire a voice actor for the full script, which is about 60 short lines.

## Files
| File | What it is | Source |
|---|---|---|
| `AchievementUnlock.ogg` | Achievement unlocked | Cinematic Sound Design (Sonniss GDC bundle) |
| `BackboardMiss.ogg` | Ball off the backboard | Sound Ex Machina (Sonniss GDC bundle) |
| `Buzzer.ogg` | Arena buzzer | BigSoundBank (CC0) #1587 |
| `CardFlip.ogg` | Card flip | Timothy McHugh, Playing Cards & Betting Chips (Sonniss GDC bundle) |
| `CardWhoosh.ogg` | Cards fan out | Timothy McHugh, Playing Cards & Betting Chips (Sonniss GDC bundle) |
| `CardsGather.ogg` | Cards gathered (Keep all) | Timothy McHugh, Playing Cards & Betting Chips (Sonniss GDC bundle) |
| `CodeRedeemed.ogg` | Code redeemed | Cinematic Sound Design (Sonniss GDC bundle) |
| `CoinsGainL.ogg` | Lots of coins | CB Sound Design, Essential Sounds Coins (Sonniss GDC bundle) |
| `CoinsGainM.ogg` | Some coins | CB Sound Design, Essential Sounds Coins (Sonniss GDC bundle) |
| `CoinsGainS.ogg` | A few coins | CB Sound Design, Essential Sounds Coins (Sonniss GDC bundle) |
| `CoinsSpend.ogg` | Purchase | CB Sound Design, Essential Sounds Coins (Sonniss GDC bundle) |
| `CrowdBed.ogg` | Arena ambience: crowd, dribbles (loop) | Sound Ex Machina (Sonniss GDC bundle) |
| `CrowdBoo.ogg` | Crowd booing | Sound Ex Machina, Basketball Game ULTRA (Sonniss GDC bundle) |
| `CrowdCheerL.ogg` | Big cheer with yells and whistling | Sound Ex Machina (Sonniss GDC bundle) |
| `CrowdCheerM.ogg` | Crowd cheers a basket | Sound Ex Machina (Sonniss GDC bundle) |
| `CrowdCheerS.ogg` | Light applause and cheer | Sound Ex Machina (Sonniss GDC bundle) |
| `CrowdDefenseChant.ogg` | Drum beat and crowd clapping in unison (loop) | Sound Ex Machina, Basketball Game ULTRA (Sonniss GDC bundle) |
| `CrowdGroan.ogg` | Crowd groans at a missed chance | Sound Ex Machina (Sonniss GDC bundle) |
| `CrowdOoh.ogg` | Crowd reacts to a near miss | Sound Ex Machina (Sonniss GDC bundle) |
| `CrowdRoar.ogg` | Arena erupts (buzzer beater, win) | Sound Ex Machina (Sonniss GDC bundle) |
| `Defeat.ogg` | Loss: crowd disappointed | Sound Ex Machina (Sonniss GDC bundle) |
| `Dribble_1.ogg` | Ball dribble | Sound Ex Machina (Sonniss GDC bundle) |
| `Dribble_2.ogg` | Ball dribble | Sound Ex Machina (Sonniss GDC bundle) |
| `Dribble_3.ogg` | Ball dribble | Sound Ex Machina (Sonniss GDC bundle) |
| `Dribble_4.ogg` | Ball dribble | Sound Ex Machina (Sonniss GDC bundle) |
| `FreeThrowBounce_1.ogg` | Single bounce before a free throw | BigSoundBank (CC0) #1045 |
| `FreeThrowBounce_2.ogg` | Single bounce before a free throw | BigSoundBank (CC0) #1045 |
| `MarketSold.ogg` | Your listing sold | CB Sound Design, Essential Sounds Coins (Sonniss GDC bundle) |
| `PackShake.ogg` | Pack handled and shaken | Timothy McHugh, Playing Cards & Betting Chips (Sonniss GDC bundle) |
| `QuestComplete.ogg` | Quest complete | Cinematic Sound Design (Sonniss GDC bundle) |
| `QuickSell.ogg` | Quick sell (coins pour) | CB Sound Design, Essential Sounds Coins (Sonniss GDC bundle) |
| `ReboundGrab.ogg` | Ball off the board and caught | Sound Ex Machina (Sonniss GDC bundle) |
| `RevealEpic.ogg` | Epic reveal | Shapeforms Audio, Future UI (Sonniss GDC bundle) |
| `RevealHallOfFame.ogg` | Hall of Fame reveal (drums and arena build) | Sound Ex Machina, Basketball Game ULTRA (Sonniss GDC bundle) |
| `RevealLegendary.ogg` | Legendary reveal (crowd erupts) | Sound Ex Machina (Sonniss GDC bundle) |
| `RevealRare.ogg` | Rare reveal | Shapeforms Audio, Future UI (Sonniss GDC bundle) |
| `RimOut_1.ogg` | Ball off the backboard and rim | Sound Ex Machina (Sonniss GDC bundle) |
| `RimOut_2.ogg` | Ball off the backboard and rim | Sound Ex Machina (Sonniss GDC bundle) |
| `RimOut_3.ogg` | Ball off the backboard and rim | Sound Ex Machina (Sonniss GDC bundle) |
| `ShoeSqueak_1.ogg` | Sneaker squeak on the court | BigSoundBank (CC0) #0938 |
| `ShoeSqueak_2.ogg` | Sneaker squeak on the court | BigSoundBank (CC0) #0938 |
| `ShoeSqueak_3.ogg` | Sneaker squeak on the court | BigSoundBank (CC0) #0938 |
| `ShoeSqueak_4.ogg` | Sneaker squeak on the court | BigSoundBank (CC0) #0938 |
| `TradeAccepted.ogg` | Trade accepted | Cinematic Sound Design (Sonniss GDC bundle) |
| `TradeRequest.ogg` | Trade request | Cinematic Sound Design (Sonniss GDC bundle) |
| `UIBack.ogg` | Back | Kpow Sounds, UI Soundpack 13 (Sonniss GDC bundle) |
| `UIClick.ogg` | Button click | Kpow Sounds, UI Soundpack 13 (Sonniss GDC bundle) |
| `UIClosePanel.ogg` | Panel closes | Kpow Sounds, UI Soundpack 13 (Sonniss GDC bundle) |
| `UIError.ogg` | Can't do that | Kpow Sounds, UI Soundpack 13 (Sonniss GDC bundle) |
| `UIOpenPanel.ogg` | Panel opens | Kpow Sounds, UI Soundpack 13 (Sonniss GDC bundle) |
| `UIToggle.ogg` | Toggle / scroll | Kpow Sounds, UI Soundpack 13 (Sonniss GDC bundle) |
| `Victory.ogg` | Win: crowd cheers | Sound Ex Machina (Sonniss GDC bundle) |
| `WhistleLong.ogg` | Referee whistle, longer | Sound Ex Machina (Sonniss GDC bundle) |
| `WhistleShort.ogg` | Referee whistle in an arena | Sound Ex Machina (Sonniss GDC bundle) |

