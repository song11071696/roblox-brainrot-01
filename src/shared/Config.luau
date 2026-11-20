-- Config: every tuning number for Brainrot Bay in one place.
-- No other module hard-codes a price, a timer or a limit; change it here.

local Config = {}

-- Starting cash for a fresh player.
Config.StartMoney = 100

-- Conveyor: a new brainrot rides in this often, and rides this fast.
Config.ConveyorSpawnInterval = 6
Config.ConveyorSpeed = 10 -- studs per second along the belt
Config.ConveyorLength = 160 -- studs, from the spawn gate to the despawn end
Config.ConveyorMaxAlive = 8 -- brainrots riding at once

-- Bases: 8 plots, each with this many brainrot slots.
Config.PlotCount = 8
Config.SlotsPerPlot = 6

-- Base lock: after a steal attempt (or a lock click) the base cannot be
-- stolen from again until this cooldown ends.
Config.BaseLockCooldown = 60 -- seconds

-- Steal: how long a stolen brainrot is carried before it is yours, and how
-- far from the victim's base you must get for the steal to stick.
Config.StealCarrySeconds = 5
Config.StealEscapeDistance = 40 -- studs from the victim's plot centre

-- Tsunami: a wave sweeps the map on this cycle.
Config.TsunamiInterval = 150 -- seconds between waves
Config.TsunamiWarningSeconds = 15 -- warning before the wave hits
Config.TsunamiWaveHeight = 26 -- studs; only base platforms are above it
Config.TsunamiWaveSpeed = 55 -- studs per second the wave front travels
Config.TsunamiDamage = 25 -- health lost if caught in the open
Config.TsunamiKnockback = 60 -- studs per second of push

-- Selling: a brainrot sold back refunds this share of its cost.
Config.SellRefundFraction = 0.5

-- Rebirth: reset money and brainrots for a permanent income multiplier.
-- Cost is the lifetime money earned needed to rebirth at each level.
Config.RebirthBaseRequirement = 50000
Config.RebirthRequirementGrowth = 2.5
Config.RebirthMultiplierPerLevel = 0.5 -- +50% income per rebirth
Config.RebirthMaxLevel = 10

-- Upgrades bought with money at your own base (per-player, permanent
-- until rebirth): each level adds +10% income on that base.
Config.UpgradeBaseCost = 1000
Config.UpgradeCostGrowth = 2.2
Config.UpgradeMaxLevel = 5

-- Economy tick: money is paid out this often.
Config.EconomyTickSeconds = 1

-- Money shown in the HUD is rounded to whole dollars.
function Config.formatMoney(amount)
	amount = math.floor(amount)
	local text = tostring(amount)
	local out = ""
	while #text > 3 do
		out = "," .. string.sub(text, -3) .. out
		text = string.sub(text, 1, -4)
	end
	return "$" .. text .. out
end

return Config
