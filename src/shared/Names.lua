--!nonstrict
-- Made-up player and coach names. Players are fictional (see docs/GENERAL_RULES.md):
-- never add a real athlete's name, or a near-copy of one.

local Names = {}

Names.First = {
	"Deuce", "Nico", "Moe", "Arlo", "Kenji", "Rafael", "Omar", "Hugo", "Theo", "Lior",
	"Elias", "Jalen", "Kofi", "Wes", "Ezra", "Cal", "Andrei", "Tobias", "Tre", "Bo",
	"Luka", "Darnell", "Mateo", "Idris", "Quincy", "Soren", "Malik", "Felix", "Rashad", "Emeka",
	"Jonah", "Dario", "Kai", "Marcus", "Tariq", "Vince", "Oskar", "Desmond", "Reggie", "Amir",
	"Bastian", "Cruz", "Dante", "Isaiah", "Jace", "Keon", "Lamar", "Milo", "Nash", "Otis",
	"Pierce", "Ronan", "Sefa", "Tyrell", "Ugo", "Viktor", "Zaire", "Ade", "Brody", "Cyrus",
}

Names.Last = {
	"Reyes", "Ferro", "Okonkwo", "Vance", "Sato", "Montague", "Petrov", "Delacroix", "Ironside", "Galloway",
	"Fairbanks", "Okafor", "Asante", "Quill", "Holloway", "Szabo", "Brandt", "Kingsley", "Adeyemi", "Varga",
	"Whitlock", "Ambrose", "Castell", "Drummond", "Easton", "Faraday", "Grayson", "Halvorsen", "Ibeka", "Jansen",
	"Kovac", "Lindqvist", "Marchetti", "Nwosu", "Oduya", "Pellerin", "Quarles", "Rourke", "Stavros", "Tamura",
	"Underhill", "Valdez", "Wexley", "Yilmaz", "Zoric", "Abara", "Blackwood", "Cardenas", "Dumont", "Eze",
	"Fontaine", "Gatling", "Hartwell", "Ivers", "Juarez", "Kamara", "Lockhart", "Mbeki", "Novak", "Osei",
}

Names.Nicknames = { "Deuce", "Sky", "Big", "Pops", "Flash", "Lights", "Ice", "Bucket", "Smooth", "Hops" }

function Names.player(rng, rarityId: string?): string
	local first, last = rng:pick(Names.First), rng:pick(Names.Last)
	-- Hall of Fame legends sometimes get a nickname, like Desmond "Deuce" Reyes.
	if rarityId == "HallOfFame" and rng:chance(0.5) then
		return string.format('%s "%s" %s', first, rng:pick(Names.Nicknames), last)
	end
	return first .. " " .. last
end

function Names.coach(rng): string
	return rng:pick(Names.First) .. " " .. rng:pick(Names.Last)
end

return Names
