-- BrainrotCatalog: the single source of truth for every brainrot character.
-- All names are original inventions for Brainrot Bay. Nothing here is copied
-- from Steal a Brainrot or any other game. Server and client both require it,
-- so a character's price, income and look can never drift apart.

local BrainrotCatalog = {}

-- Rarity ladder, cheapest first. RarityColours is used by labels and the HUD.
BrainrotCatalog.Rarities = {
	"Common",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Brainrot God",
}

BrainrotCatalog.RarityColours = {
	Common = Color3.fromRGB(180, 180, 180),
	Rare = Color3.fromRGB(80, 170, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Legendary = Color3.fromRGB(255, 180, 40),
	Mythic = Color3.fromRGB(255, 70, 120),
	["Brainrot God"] = Color3.fromRGB(255, 235, 90),
}

-- Mutation multipliers: a mutated brainrot earns its base rate times this.
BrainrotCatalog.Mutations = {
	Normal = 1,
	Golden = 2,
	Diamond = 5,
	Rainbow = 10,
}

BrainrotCatalog.MutationColours = {
	Normal = Color3.fromRGB(255, 255, 255),
	Golden = Color3.fromRGB(255, 215, 0),
	Diamond = Color3.fromRGB(120, 230, 255),
	Rainbow = Color3.fromRGB(255, 110, 220),
}

-- The cast. Each entry: id, display name, rarity, cost to buy, dollars per
-- second it earns on a base, body colour, size scale and a one-line joke.
-- Costs rise with income so the player always has a next tier to chase.
BrainrotCatalog.Characters = {
	{
		Id = "spaghetto_scream",
		Name = "Spaghetto Scream",
		Rarity = "Common",
		Cost = 50,
		IncomePerSecond = 5,
		BodyColour = Color3.fromRGB(255, 210, 90),
		AccentColour = Color3.fromRGB(200, 40, 40),
		Scale = 1.0,
		Joke = "A spaghetti monster that screams in Italian.",
	},
	{
		Id = "capy_cappuccino",
		Name = "Capy Cappuccino",
		Rarity = "Common",
		Cost = 100,
		IncomePerSecond = 9,
		BodyColour = Color3.fromRGB(170, 120, 70),
		AccentColour = Color3.fromRGB(120, 70, 30),
		Scale = 1.1,
		Joke = "A capybara that never puts its coffee down.",
	},
	{
		Id = "banana_boogie",
		Name = "Banana Boogie",
		Rarity = "Common",
		Cost = 200,
		IncomePerSecond = 16,
		BodyColour = Color3.fromRGB(255, 235, 60),
		AccentColour = Color3.fromRGB(90, 60, 10),
		Scale = 1.0,
		Joke = "A dancing banana with two left feet.",
	},
	{
		Id = "pizza_pigeon",
		Name = "Pizza Pigeon",
		Rarity = "Rare",
		Cost = 500,
		IncomePerSecond = 32,
		BodyColour = Color3.fromRGB(130, 130, 150),
		AccentColour = Color3.fromRGB(255, 120, 40),
		Scale = 1.1,
		Joke = "Delivers pizza. Eats the pizza. Blames you.",
	},
	{
		Id = "taco_tornado",
		Name = "Taco Tornado",
		Rarity = "Rare",
		Cost = 900,
		IncomePerSecond = 55,
		BodyColour = Color3.fromRGB(255, 180, 60),
		AccentColour = Color3.fromRGB(60, 180, 90),
		Scale = 1.2,
		Joke = "A taco spinning so fast it seasons itself.",
	},
	{
		Id = "noodle_ninja",
		Name = "Noodle Ninja",
		Rarity = "Rare",
		Cost = 1500,
		IncomePerSecond = 85,
		BodyColour = Color3.fromRGB(240, 220, 180),
		AccentColour = Color3.fromRGB(40, 40, 40),
		Scale = 1.1,
		Joke = "Silent. Slippery. Extra soy sauce.",
	},
	{
		Id = "burrito_bandito",
		Name = "Burrito Bandito",
		Rarity = "Epic",
		Cost = 3000,
		IncomePerSecond = 160,
		BodyColour = Color3.fromRGB(220, 170, 90),
		AccentColour = Color3.fromRGB(30, 30, 30),
		Scale = 1.3,
		Joke = "Steals your lunch, then sells it back to you.",
	},
	{
		Id = "gelato_giraffe",
		Name = "Gelato Giraffe",
		Rarity = "Epic",
		Cost = 5500,
		IncomePerSecond = 280,
		BodyColour = Color3.fromRGB(255, 200, 220),
		AccentColour = Color3.fromRGB(255, 140, 180),
		Scale = 1.5,
		Joke = "Its neck is a soft-serve machine.",
	},
	{
		Id = "disco_duckling",
		Name = "Disco Duckling",
		Rarity = "Epic",
		Cost = 9000,
		IncomePerSecond = 450,
		BodyColour = Color3.fromRGB(255, 240, 120),
		AccentColour = Color3.fromRGB(255, 60, 200),
		Scale = 1.2,
		Joke = "Quacks on the beat. Never off it.",
	},
	{
		Id = "espresso_elephant",
		Name = "Espresso Elephant",
		Rarity = "Legendary",
		Cost = 18000,
		IncomePerSecond = 850,
		BodyColour = Color3.fromRGB(120, 110, 130),
		AccentColour = Color3.fromRGB(90, 50, 20),
		Scale = 1.7,
		Joke = "One trumpet and the whole cafe wakes up.",
	},
	{
		Id = "volcano_volpino",
		Name = "Volcano Volpino",
		Rarity = "Legendary",
		Cost = 35000,
		IncomePerSecond = 1500,
		BodyColour = Color3.fromRGB(255, 90, 40),
		AccentColour = Color3.fromRGB(60, 30, 30),
		Scale = 1.6,
		Joke = "A tiny dog with a lava problem.",
	},
	{
		Id = "pasta_pope",
		Name = "Pasta Pope",
		Rarity = "Brainrot God",
		Cost = 150000,
		IncomePerSecond = 6000,
		BodyColour = Color3.fromRGB(255, 255, 255),
		AccentColour = Color3.fromRGB(255, 215, 0),
		Scale = 2.0,
		Joke = "Blesses every noodle. Charges every blessing.",
	},
}

-- The colour for a rarity name, falling back to white for unknown rarities.
function BrainrotCatalog.getRarityColour(rarity)
	return BrainrotCatalog.RarityColours[rarity] or Color3.fromRGB(255, 255, 255)
end

-- Look a character up by its id. Returns nil for an unknown id.
function BrainrotCatalog.getCharacter(id)
	for _, character in ipairs(BrainrotCatalog.Characters) do
		if character.Id == id then
			return character
		end
	end
	return nil
end

-- Pick a random character, weighted so cheap commons ride the belt most
-- often and the Brainrot God almost never does.
function BrainrotCatalog.rollCharacter()
	local weights = { 26, 20, 16, 11, 9, 7, 4, 3, 2, 1, 0.7, 0.3 }
	local total = 0
	for _, w in ipairs(weights) do
		total += w
	end
	local roll = math.random() * total
	for i, w in ipairs(weights) do
		roll -= w
		if roll <= 0 then
			return BrainrotCatalog.Characters[i]
		end
	end
	return BrainrotCatalog.Characters[1]
end

-- Roll a mutation for a fresh spawn. Most are Normal; Rainbow is rare.
function BrainrotCatalog.rollMutation()
	local roll = math.random()
	if roll < 0.02 then
		return "Rainbow"
	elseif roll < 0.07 then
		return "Diamond"
	elseif roll < 0.17 then
		return "Golden"
	end
	return "Normal"
end

-- Effective income once mutation (and later the rebirth multiplier) apply.
function BrainrotCatalog.incomePerSecond(character, mutation, rebirthMultiplier)
	local base = character.IncomePerSecond
	local mult = BrainrotCatalog.Mutations[mutation] or 1
	return math.floor(base * mult * (rebirthMultiplier or 1))
end

-- How long, in seconds, a brainrot takes to pay for itself.
function BrainrotCatalog.paybackSeconds(character, mutation, rebirthMultiplier)
	local income = BrainrotCatalog.incomePerSecond(character, mutation, rebirthMultiplier)
	if income <= 0 then
		return math.huge
	end
	return character.Cost / income
end

return BrainrotCatalog
