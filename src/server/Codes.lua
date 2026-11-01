--[[
  REDEEM CODES — edit this list, then publish the game.

  Each line is CODE = { what it gives, options }.
  Code names must be CAPITAL letters, numbers, _ or -. Players can type them
  in any case, so "tipoff" works for TIPOFF.

  What a code can give (use one or more):
    coins = 5000
    fans = 100
    packs = { Pro = 1 }                  -- pack ids: Rookie, Blacktop, Pro, AllStar, HallOfFame, Badge, Coach, EliteCoach
    boost = { kind = "DoubleCoins", minutes = 30 }   -- or "DoubleFans"

  Options:
    expires = "2026-12-31"   -- last day it works (UTC)
    maxUses = 500            -- total uses across every player
    newPlayersOnly = true    -- only clubs made in the last 3 days
    disabled = true          -- turn it off without deleting it

  Want a code without publishing? In any live server, admins can type in chat:
    !makecode NAME coins=5000 pack=Pro:1 days=7
  Type !codehelp in game for the full list. Admins are set in Admins.lua.

  The tests (tests/run.luau) check every entry here, so a typo shows up
  before it reaches the game.
]]

return {
	TIPOFF = { coins = 5000 },
	FASTBREAK = { coins = 10000, packs = { Blacktop = 1 } },
	WELCOME = { packs = { Pro = 1 }, newPlayersOnly = true },
}
