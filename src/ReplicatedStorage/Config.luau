--!nonstrict
-- Shared tuning values for Don'tGiveUpSkeleton. Tweak freely.
local Config = {}

-- Prints combat info (hits per swing, rig type) to the Output window.
Config.Debug = true

Config.Player = {
	MaxHealth = 100,
	MaxStamina = 100,
	StaminaRegen = 42, -- per second
	StaminaRegenDelay = 0.55, -- seconds after spending before regen resumes
	WalkSpeed = 12,
	SprintSpeed = 19,
	SprintDrain = 16, -- per second

	RollCost = 22,
	RollDuration = 0.55,
	RollSpeed = 26,
	IFrameStart = 0.03, -- invulnerability window, seconds after the roll starts
	IFrameEnd = 0.415, -- (+1 frame at 30fps; the roll animation always spans exactly this window)

	BackstepCost = 12, -- roll with no movement input = backstep
	BackstepDuration = 0.32,
	BackstepSpeed = 20,
	BackstepIFrameEnd = 0.235,

	Flasks = 3,
	FlaskHeal = 45,
	FlaskTime = 1.4,

	RingSlots = 2, -- equipped ring slots

	RespawnTime = 5,
}

-- Attacks. Light is a 3-hit chain; pressing light again inside the combo
-- window continues it. Poses = { windup pose, mid-swing pose, end pose }.
-- Poise = how much the hit chips at an enemy's poise (break it -> stagger).
-- HitStop = seconds attacker and target freeze when the blade connects.
-- Range/HalfAngle are only a fallback if the sword is missing.
Config.Attacks = {
	Light = {
		{ Cost = 18, Windup = 0.17, Swing = 0.1, Recover = 0.33, Damage = 26, Poise = 12, HitStop = 0.06, Poses = { "Raise", "Mid", "Strike" }, Range = 7, HalfAngle = 65 },
		{ Cost = 18, Windup = 0.14, Swing = 0.12, Recover = 0.34, Damage = 24, Poise = 12, HitStop = 0.06, Poses = { "SweepBack", "SweepMid", "SweepEnd" }, Range = 7, HalfAngle = 80 },
		{ Cost = 22, Windup = 0.2, Swing = 0.12, Recover = 0.42, Damage = 34, Poise = 18, HitStop = 0.08, Poses = { "SweepEnd", "SweepMid", "SweepBack" }, Range = 7, HalfAngle = 80 },
	},
	Heavy = {
		{ Cost = 32, Windup = 0.48, Swing = 0.12, Recover = 0.45, Damage = 50, Poise = 35, HitStop = 0.11, Poses = { "Raise", "Mid", "Strike" }, Range = 7.5, HalfAngle = 60 },
	},
	-- Light attack while moving: a big sweep you run through. Your momentum carries
	-- you forward (CarrySpeed) for Carry x the whole attack, stopping right at the end.
	-- Body = full-body poses for the windup and the slash.
	Running = {
		{ Cost = 22, Windup = 0.12, Swing = 0.2, Recover = 0.34, Damage = 42, Poise = 30, HitStop = 0.03, Poses = { "SweepBack", "SweepMid", "SweepEnd" }, Body = { "RunWindup", "RunSlash" }, Range = 8, HalfAngle = 90, Carry = 0.85, CarrySpeed = 21 },
	},
}

-- Oculast's harvest-blade (her drop): quicker, wider cuts that hit a little less hard.
-- Light: across, back across, then a chop. Heavy: dragged low behind you, reaped up.
-- Running: one huge flat sweep. Grip poses are hers (Characters/Oculast.lua, Usher.Grips).
Config.ScytheAttacks = {
	Light = {
		{ Cost = 16, Windup = 0.12, Swing = 0.11, Recover = 0.27, Damage = 21, Poise = 10, HitStop = 0.05, Poses = { "USweepBack", "USweepMid", "USweepEnd" }, Range = 10, HalfAngle = 100 },
		{ Cost = 16, Windup = 0.1, Swing = 0.11, Recover = 0.28, Damage = 21, Poise = 10, HitStop = 0.05, Poses = { "USweepEndR", "USweepMidR", "USweepBackR" }, Range = 10, HalfAngle = 100 },
		{ Cost = 20, Windup = 0.16, Swing = 0.1, Recover = 0.36, Damage = 30, Poise = 16, HitStop = 0.07, Poses = { "URaise", "UChop", "UChop" }, Range = 10, HalfAngle = 45 },
	},
	Heavy = {
		{ Cost = 30, Windup = 0.4, Swing = 0.13, Recover = 0.42, Damage = 46, Poise = 32, HitStop = 0.1, Poses = { "UDragBack", "URising", "URising" }, Body = { "Crouch", "Strike" }, Range = 10, HalfAngle = 50 },
	},
	Running = {
		{ Cost = 22, Windup = 0.1, Swing = 0.2, Recover = 0.32, Damage = 38, Poise = 28, HitStop = 0.03, Poses = { "USweepBack", "USweepMid", "USweepEnd" }, Body = { "RunWindup", "RunSlash" }, Range = 11, HalfAngle = 120, Carry = 0.85, CarrySpeed = 21 },
	},
}

-- The Castellan's mace (his drop): slow, heavy, two-handed, dragged behind you at rest. It
-- has one blow, whatever you press: heaved all the way up and brought down.
local maceSmash = { Cost = 40, Windup = 0.85, Swing = 0.14, Recover = 0.75, Damage = 120, Poise = 65, HitStop = 0.16, Poses = { "Raise", "Mid", "Strike" }, Range = 8.5, HalfAngle = 50, Name = "Smash" }
local maceSmashRunning = table.clone(maceSmash)
maceSmashRunning.Carry, maceSmashRunning.CarrySpeed = 0.3, 0 -- (only your own momentum, bleeding off)
Config.MaceAttacks = {
	Light = { maceSmash },
	Heavy = { maceSmash },
	Running = { maceSmashRunning },
}

-- The Old Book: every attack casts a fireball where you aim (lock-on target, else the
-- camera). Fireball = { Speed (studs/s), Range (studs), Radius (its hit sphere), Size }.
-- 12 damage x Fire scaling (+55% a point): 25 at 2 Fire, 32 at 3 (the sword's hits: 24-34).
Config.BookAttacks = {
	Light = {
		{ Cost = 16, Windup = 0.2, Swing = 0.1, Recover = 0.35, Damage = 12, Poise = 6, HitStop = 0.03, Poses = { "BRead", "BCast", "BCast" }, Range = 7, HalfAngle = 60, Fireball = { Speed = 90, Range = 140, Radius = 1.4, Size = 1 } },
	},
	Heavy = {
		{ Cost = 30, Windup = 0.55, Swing = 0.1, Recover = 0.45, Damage = 22, Poise = 16, HitStop = 0.06, Poses = { "BRead", "BCast", "BCast" }, Range = 7, HalfAngle = 60, Fireball = { Speed = 70, Range = 140, Radius = 2.2, Size = 1.8 } },
	},
	Running = {
		{ Cost = 16, Windup = 0.2, Swing = 0.1, Recover = 0.35, Damage = 12, Poise = 6, HitStop = 0.03, Poses = { "BRead", "BCast", "BCast" }, Range = 7, HalfAngle = 60, Carry = 0.6, CarrySpeed = 0, Fireball = { Speed = 90, Range = 140, Radius = 1.4, Size = 1 } },
	},
}

-- The Dragon Tooth Wand (both Watchdogs' drop; key PyralisFang): the Old Book's casts from a wand, harder, faster and bigger, and Fire tells
-- more on it (Config.Weapons.PyralisFang): 16 x (1 + 0.7 a point) - 38 at 2 Fire, 50 at 3 (the Old Book's: 25, 32)
Config.WandAttacks = {
	Light = {
		{ Cost = 16, Windup = 0.18, Swing = 0.1, Recover = 0.32, Damage = 16, Poise = 8, HitStop = 0.03, Poses = { "WDraw", "BCast", "BCast" }, Range = 7, HalfAngle = 60, Fireball = { Speed = 105, Range = 150, Radius = 1.7, Size = 1.25 } },
	},
	Heavy = {
		{ Cost = 30, Windup = 0.5, Swing = 0.1, Recover = 0.42, Damage = 30, Poise = 20, HitStop = 0.06, Poses = { "WDraw", "BCast", "BCast" }, Range = 7, HalfAngle = 60, Fireball = { Speed = 80, Range = 150, Radius = 2.8, Size = 2.3 } },
	},
	Running = {
		{ Cost = 16, Windup = 0.18, Swing = 0.1, Recover = 0.32, Damage = 16, Poise = 8, HitStop = 0.03, Poses = { "WDraw", "BCast", "BCast" }, Range = 7, HalfAngle = 60, Carry = 0.6, CarrySpeed = 0, Fireball = { Speed = 105, Range = 150, Radius = 1.7, Size = 1.25 } },
	},
}

-- The Dark Book (the Consul of Decay's drop - Aldous's own): like the Old Book, but every cast is a dark beam from the
-- pages, along your aim, for Duration s. It hurts everything in it every Tick s for Pct % of that
-- enemy's MAX health (x the Darkness scaling). Laser = { Pct, Duration, Range, Width, Poise, Hold, Drain }.
-- Hold: the light attack's beam stays out while the button is held (Duration is the least a tap
-- gives), draining Drain stamina a second until it runs out; the aim follows camera/lock-on.
Config.DarkBookTick = 0.25
Config.DarkBookAttacks = {
	Light = {
		{ Cost = 16, Windup = 0.2, Swing = 0.1, Recover = 0.35, Damage = 0, Poise = 0, HitStop = 0, Poses = { "BRead", "BCast", "BCast" }, Range = 7, HalfAngle = 60, Laser = { Pct = 0.5, Duration = 0.45, Range = 70, Width = 1, Poise = 2, Hold = true, Drain = 10 } },
	},
	Heavy = {
		{ Cost = 30, Windup = 0.55, Swing = 0.1, Recover = 0.45, Damage = 0, Poise = 0, HitStop = 0, Poses = { "BRead", "BCast", "BCast" }, Range = 7, HalfAngle = 60, Laser = { Pct = 0.8, Duration = 1.0, Range = 70, Width = 2.2, Poise = 3 } },
	},
	Running = {
		{ Cost = 16, Windup = 0.2, Swing = 0.1, Recover = 0.35, Damage = 0, Poise = 0, HitStop = 0, Poses = { "BRead", "BCast", "BCast" }, Range = 7, HalfAngle = 60, Carry = 0.6, CarrySpeed = 0, Laser = { Pct = 0.5, Duration = 0.45, Range = 70, Width = 1, Poise = 2, Hold = true, Drain = 10 } },
	},
}

-- The Foul Dagger: short and quick, scales with Decay. Its running attack carries you at RunBoost x
-- your speed for the rest of the attack if it hits anything. Q (FoulPhase): you go half-transparent
-- and nothing can hurt you for Duration s; Cooldown s from the press.
Config.FoulPhase = { Duration = 2, Cooldown = 10 }
Config.DaggerAttacks = {
	Light = {
		{ Cost = 12, Windup = 0.09, Swing = 0.08, Recover = 0.22, Damage = 16, Poise = 7, HitStop = 0.04, Poses = { "Raise", "Mid", "Strike" }, Range = 5, HalfAngle = 65 },
		{ Cost = 12, Windup = 0.08, Swing = 0.09, Recover = 0.22, Damage = 15, Poise = 7, HitStop = 0.04, Poses = { "SweepBack", "SweepMid", "SweepEnd" }, Range = 5, HalfAngle = 80 },
		{ Cost = 15, Windup = 0.12, Swing = 0.09, Recover = 0.3, Damage = 22, Poise = 11, HitStop = 0.05, Poses = { "SweepEnd", "SweepMid", "SweepBack" }, Range = 5, HalfAngle = 80 },
	},
	Heavy = {
		{ Cost = 24, Windup = 0.3, Swing = 0.1, Recover = 0.34, Damage = 34, Poise = 22, HitStop = 0.08, Poses = { "Raise", "Mid", "Strike" }, Range = 5.5, HalfAngle = 60 },
	},
	Running = {
		{ Cost = 16, Windup = 0.1, Swing = 0.18, Recover = 0.28, Damage = 28, Poise = 18, HitStop = 0.03, Poses = { "SweepBack", "SweepMid", "SweepEnd" }, Body = { "RunWindup", "RunSlash" }, Range = 6, HalfAngle = 90, Carry = 0.85, CarrySpeed = 21 },
	},
}

-- Caelen's twin blades (the Silver Knight's drop): both swords swing together, each pose mirrored
-- onto the left hand. Slow and heavy: a scissoring sweep both ways, then an X, then a double slam.
Config.CaelenAttacks = {
	Light = {
		{ Cost = 22, Windup = 0.26, Swing = 0.14, Recover = 0.4, Damage = 36, Poise = 20, HitStop = 0.07, Poses = { "GHeaveBack", "SweepMid", "GHeaveEnd" }, Body = { "CHeave", "CHeaveEnd" }, Range = 8, HalfAngle = 90 },
		{ Cost = 22, Windup = 0.22, Swing = 0.14, Recover = 0.4, Damage = 36, Poise = 20, HitStop = 0.07, Poses = { "GHeaveEnd", "SweepMid", "GHeaveBack" }, Body = { "CHeaveEnd", "CHeave" }, Range = 8, HalfAngle = 90 },
		{ Cost = 28, Windup = 0.34, Swing = 0.14, Recover = 0.55, Damage = 58, Poise = 38, HitStop = 0.1, Poses = { "GCrossSet", "Mid", "GCrossEnd" }, Body = { "CHoist", "CSlam" }, Range = 8, HalfAngle = 80 },
	},
	Heavy = {
		{ Cost = 40, Windup = 0.7, Swing = 0.14, Recover = 0.6, Damage = 95, Poise = 70, HitStop = 0.13, Poses = { "GHigh", "Mid", "GSlam" }, Body = { "CHoist", "CSlam" }, Range = 8.5, HalfAngle = 70 },
	},
	Running = {
		{ Cost = 26, Windup = 0.14, Swing = 0.22, Recover = 0.36, Damage = 48, Poise = 34, HitStop = 0.04, Poses = { "SweepBack", "SweepMid", "SweepEnd" }, Body = { "RunWindup", "RunSlash" }, Range = 8.5, HalfAngle = 100, Carry = 0.85, CarrySpeed = 21 },
	},
}
-- Q with the twin blades: spin in place of the cut, steering by walking (like Garen's E). Every
-- Tick it hurts everything within Radius for Damage x the weapon's Scaling; Yaw = rad/s of the turn
Config.CaelenSpin = { Cost = 30, Cooldown = 5, Duration = 2.4, Tick = 0.3, Damage = 24, Poise = 14, Radius = 10, Yaw = 16 }

-- What you can wield. Each key names its model (a character file's M.Weapons entry).
-- Idle = its resting grip, Scale = model size, Reach = how far past the visible tip
-- its hits reach, TwoHand = studs up the haft the left hand holds (nil = one hand).
-- HealthBonus = extra max health while it's in your hands (0.1 = +10%). Note = shown in
-- the weapon menu (I). You own the Sword from the start; the rest are found (a "Has_<key>"
-- player attribute), and the menu lists them in WeaponOrder.
Config.Weapons = {
	Sword = { Name = "Sword", Attacks = Config.Attacks, Idle = "SwordUp", Scale = 1, Reach = 1.2, TwoHand = 0.4, SlashSound = "rbxassetid://7118966167" },
	Scythe = { Name = "Usher's Harvest-Blade", Attacks = Config.ScytheAttacks, Idle = "UGuard", Scale = 0.8, Reach = 1.25, TwoHand = 0.9, CanDeflect = true, SlashSound = "rbxassetid://140277245983305", Note = "Q: Deflect" },
	-- an early weapon: barely scales (Strength), and Nobility only starts to tell past 4
	CastellanMace = {
		Name = "Castellan's Mace", Attacks = Config.MaceAttacks, Idle = "MDrag", Scale = 0.75, Reach = 1.0, TwoHand = -0.8, HealthBonus = 0.1, NoLight = true, -- (no light attack: left click does nothing)
		Strength = 1, Scaling = { Strength = { Per = 0.03 }, Nobility = { Per = 0.02, After = 4 } },
	},
	-- swings like the sword; lightning crawls on it always. Q: the draw (Config.TachiDraw)
	GozenTachi = {
		Name = "Gozen Tachi", Attacks = Config.Attacks, Idle = "TIdle", Scale = 1, Reach = 1.2, TwoHand = 0.5, Iai = true, MoveSpeed = 1.05, SlashSound = "rbxassetid://140277245983305",
		Scaling = { Nobility = { Per = 0.08 } },
		Note = "Q: Sheathe, draw",
	},
	-- the Silver Knight's pair, half the size of his own and still comic in your hands. Dual: a second
	-- one in the left hand. Q: the spin (Config.CaelenSpin)
	CaelenBlades = {
		Name = "Caelen's Twin Blades", Attacks = Config.CaelenAttacks, Idle = "GLow", Scale = 1, Reach = 1.0, Dual = true, Spin = true,
		Strength = 3, Scaling = { Strength = { Per = 0.04 } }, SlashSound = "rbxassetid://140277245983305",
		Note = "Q: Spin",
	},
	-- weak in your hands; Fire is what makes it. At 3 Fire it out-hits the sword
	OldBook = {
		Name = "Old Book", Attacks = Config.BookAttacks, Idle = "BRead", Scale = 1, Reach = 1,
		Scaling = { Fire = { Per = 0.55 } },
	},
	-- the Watchdogs' drop: the Malformed one's fang, the True one's fire still in it. The Old Book, bettered
	PyralisFang = {
		Name = "Dragon Tooth Wand", Attacks = Config.WandAttacks, Idle = "WHold", Scale = 1, Reach = 1, FireReq = 4, -- (FireReq: the Fire it needs to wield)
		Scaling = { Fire = { Per = 0.7 } },
	},
	-- the Old Book's dark twin: a beam, not a ball. Darkness raises the % of max health it takes
	DarkBook = {
		Name = "Dark Book", Attacks = Config.DarkBookAttacks, Idle = "BRead", Scale = 1, Reach = 1,
		Scaling = { Darkness = { Per = 0.35 } },
	},
	FoulDagger = {
		Name = "Foul Dagger", Attacks = Config.DaggerAttacks, Idle = "SwordUp", Scale = 1, Reach = 2.2, Phase = true, RunBoost = 1.5,
		Scaling = { Decay = { Per = 0.06 } }, SlashSound = "rbxassetid://140277245983305",
		Note = "Q: Phase",
	},
}
-- SlashSound = the sound of its swings (nil = the sword's slash / heavy lunge).
-- MoveSpeed = your walk/sprint speed multiplier while it's in your hands (nil = 1).
-- Strength = the Strength stat it needs to be wielded (nil = none). Fireball = its attacks
-- cast one instead of swinging (Config.BookAttacks).
-- Scaling = { Stat = { Per = x, After = n } }: every point of that stat past n (default 0)
-- adds x to the damage multiplier (0.03 = +3% a point).

-- Stats: each starts at 0. Every boss drops a Bone Splinter; resting at a bonfire with one
-- lets you raise one stat by 1. They count through weapon Strength/Scaling and ScytheSplinter.
Config.Stats = { "Strength", "Decay", "Speed", "Nobility", "Darkness", "Fire" }

-- Armor. Each piece takes up its Slots (Head, Body): putting one on takes off whatever was
-- in its slots (so the Dark Cloak goes with the Castellan's Helm, but not with the Motley,
-- and the Dark Hood not with the Helm). Picked in the menu (I) from what you've found.
-- Grow = how much bigger it makes you (1.15 = 15%). Found = a player attribute of its key (true); worn = "ArmorHead" / "ArmorBody". While
-- worn: Health = extra max health (0.5 = +50%), Stats = points added to your stats, Aura =
-- the dark you give off (1 faint, 2 thick; Armor.luau). ArmorSets: worn together, more.
Config.Armor = {
	Helmet = { Name = "Castellan's Helm", Slots = { "Head" }, Health = 0.5 },
	Motley = { Name = "Wretch's Motley", Slots = { "Head", "Body" }, Stats = { Nobility = 1, Darkness = 1, Fire = 3 } },
	DarkCloak = { Name = "Dark Cloak", Slots = { "Body" }, Stats = { Darkness = 1 }, Aura = 1 },
	-- Regen = { Amount, Every }: that much health every that many seconds, always
	CaelenArmor = { Name = "Caelen's Silver Plate", Slots = { "Body" }, Health = 0.1, Grow = 1.15, Regen = { Amount = 1, Every = 0.5 } },
	DarkHood = { Name = "Dark Hood", Slots = { "Head" }, Stats = { Darkness = 1 } },
	-- the blazing chest in the Underfire's side chamber (key PotbellyArmor): heavy - much more health, slower on your feet.
	-- MoveSpeed = your walk/sprint speed multiplier while it's worn (nil = 1)
	PotbellyArmor = { Name = "Armor of a Lion Hunter", Slots = { "Body" }, Health = 0.9, Grow = 1.15, MoveSpeed = 0.85, Regen = { Amount = 1, Every = 0.5 } },
}
Config.ArmorSets = {
	{ Pieces = { "DarkCloak", "DarkHood" }, Stats = { Darkness = 1 }, Aura = 2 }, -- (3 Darkness in all)
}
Config.ArmorOrder = { "Helmet", "Motley", "DarkCloak", "DarkHood", "CaelenArmor", "PotbellyArmor" }
-- the dark aura's look (Armor.luau): an asset id - a VFX model (its particle emitters are
-- used as they are), or an image/decal (the haze is drawn with it). 0 = the built-in haze
Config.DarkAuraAsset = 108947832678179
Config.DarkAuraScale = 1.6 -- how far out it reaches, and how big and how many its particles (1 = as made)
Config.ArmorSlots = { "Head", "Body" }
-- what you have on: { [key] = its Config.Armor entry }
function Config.wornArmor(player)
	local worn = {}
	for _, slot in ipairs(Config.ArmorSlots) do
		local key = player:GetAttribute("Armor" .. slot)
		if key and Config.Armor[key] then
			worn[key] = Config.Armor[key]
		end
	end
	return worn
end
-- what it all adds up to, sets included: { Stats = { [stat] = n }, Health = x, Aura = n }
function Config.armorBonus(player)
	local worn = Config.wornArmor(player)
	local out = { Stats = {}, Health = 0, Aura = 0, Regen = 0, Grow = 1, MoveSpeed = 1 } -- (Regen: health a second)
	local function add(def)
		for k, v in pairs(def.Stats or {}) do
			out.Stats[k] = (out.Stats[k] or 0) + v
		end
		out.Health += def.Health or 0
		out.Regen += def.Regen and def.Regen.Amount / def.Regen.Every or 0
		out.Grow *= def.Grow or 1
		out.MoveSpeed *= def.MoveSpeed or 1
		out.Aura = math.max(out.Aura, def.Aura or 0)
	end
	for _, def in pairs(worn) do
		add(def)
	end
	for _, set in ipairs(Config.ArmorSets) do
		local all = true
		for _, k in ipairs(set.Pieces) do
			all = all and worn[k] ~= nil
		end
		if all then
			add(set)
		end
	end
	return out
end
-- put a piece on, taking off whatever had its slots - or, if it's already on, take it off
-- (server: these attributes are what dresses you, init.server's dressArmor)
function Config.wearArmor(player, key)
	local def = Config.Armor[key]
	local wasOn = Config.wornArmor(player)[key] ~= nil
	for _, slot in ipairs(Config.ArmorSlots) do
		local cur = player:GetAttribute("Armor" .. slot)
		if cur and (cur == key or table.find(def.Slots, slot)) then
			for _, other in ipairs(Config.ArmorSlots) do -- off it comes, from every slot it had
				if player:GetAttribute("Armor" .. other) == cur then
					player:SetAttribute("Armor" .. other, nil)
				end
			end
		end
	end
	if not wasOn then
		for _, slot in ipairs(def.Slots) do
			player:SetAttribute("Armor" .. slot, key)
		end
	end
end
-- a stat as it counts: the points you've put in, plus what your armor adds
function Config.statOf(player, name)
	return (player:GetAttribute("Stat_" .. name) or 0) + (Config.armorBonus(player).Stats[name] or 0)
end
Config.WeaponOrder = { "Sword", "Scythe", "CastellanMace", "GozenTachi", "OldBook", "PyralisFang", "DarkBook", "FoulDagger", "CaelenBlades" }
function Config.weaponOf(player)
	return Config.Weapons[player:GetAttribute("Weapon") or "Sword"] or Config.Weapons.Sword
end
-- the damage multiplier a weapon's Scaling gives this player's stats
function Config.scaling(player, def)
	local m = 1
	for name, s in pairs(def.Scaling or {}) do
		m += s.Per * math.max(0, Config.statOf(player, name) - (s.After or 0))
	end
	return m
end

-- a kill with the Usher's harvest-blade may leave a Bone Splinter: Chance, plus
-- PerDarkness for every point of Darkness (2% at 0, 3% at 1, ...)
Config.ScytheSplinter = { Chance = 0.02, PerDarkness = 0.01 }

-- The Gozen Tachi's draw (Q). Q sheathes it and you settle into the stance (SheatheTime).
-- You're rooted in it: a roll gets you out any time, and from CancelAfter on so does
-- pressing A, S or D (W is kept for the dash). Then Q draws it in
-- one huge cut - holding W as you press it, a long dash forward with a wide cut through
-- everything along the way. A Q pressed while it's still going home is queued for the draw.
-- Only the draw is invulnerable, and only for IFrames seconds (a roll's are 0.385).
Config.TachiDraw = {
	SheatheTime = 0.35,
	CancelAfter = 0.5, -- seconds into the stance before A/S/D walk you out of it
	IFrames = 0.15, -- (you're invisible for these; the cut lands as they end: keep each Windup equal)
	Cost = 20, -- stamina, paid on the draw
	Attack = { Windup = 0.15, Swing = 0.1, Recover = 0.42, Damage = 107, Poise = 80, HitStop = 0.1, Poses = { "TSheathed", "SweepMid", "SweepBack" }, Range = 8, HalfAngle = 100, Name = "Draw", Draw = true },
	-- the dash: DashSpeed studs/s for DashTime (~18 studs); Reach stretches the cut out wide and
	-- PathRadius also catches everything within that of the line you dashed along
	DashSpeed = 85,
	DashTime = 0.22,
	DashAttack = { Windup = 0.15, Swing = 0.12, Recover = 0.5, Damage = 107, Poise = 80, HitStop = 0.1, Poses = { "TSheathed", "SweepMid", "SweepBack" }, Range = 10, HalfAngle = 140, Reach = 1.8, PathRadius = 5, Name = "DashDraw", Draw = true },
}

-- Scythe Deflect: Lies of P style deflect frames (exclusive to the Scythe, bound to Q).
-- Timed shortly before an incoming hit, the hit is deflected: 0 damage taken,
-- plays a crisp metallic deflect sound instantly, and grants i-frames for 2/3rds
-- the duration of a dodgeroll without moving or dodging.
Config.ScytheDeflect = {
	Cost = 10, -- stamina cost
	Twirl = 0.35, -- seconds spinning the scythe overhead before it clicks into guard (you can be hit meanwhile)
	Window = 0.22, -- seconds active window after the click to catch an incoming hit
	-- the beat you hear: whoosh (press), whoosh (half-way), CLICK = the deflect frames start
	TwirlSound = "rbxasset://sounds/swordslash.wav",
	ClickSound = "rbxasset://sounds/clickfast.wav",
	Duration = 0.38, -- seconds total action duration / recovery
	-- Dodgeroll i-frame duration in Config.Player is IFrameEnd - IFrameStart = 0.415 - 0.03 = 0.385s.
	-- 2/3rds of dodgeroll i-frame duration is ~0.26s.
	IFrameDuration = 0.26,
	-- a deflect also cuts everything in a circle around you, about the scythe's length
	Radius = Config.ScytheAttacks.Light[1].Range,
	Damage = Config.ScytheAttacks.Light[1].Damage * 4,
	Poise = Config.ScytheAttacks.Light[1].Poise * 1.5, -- 1.5x a light swing's posture damage
	Sound = "rbxassetid://8820780818", -- classic crisp parry/deflect clash
	Sound2 = "rbxasset://sounds/collide.wav", -- layered on top of Sound, same instant (a heavier clang)
}

-- The mimic on the Prison Ramparts' yard walk (GameServer/Mimic.lua). You have 100 HP.
Config.Mimic = {
	HP = 220,
	Poise = 60, -- ~5 light scythe cuts to tip it over
	Stagger = 2, -- seconds it lies tipped over, lid flopped open
	-- opening it: it lets you lift the lid a crack, then gapes, drags you in, chews, spits you out
	Grab = {
		Chews = 3,
		ChewDamage = 15, -- per chew
		ChewTime = 0.6, -- seconds per chew
		SpitDamage = 10, -- the knockdown as it spits you out (3 chews + this = 55 in all)
	},
	ChompDamage = 30, -- up close: gapes slowly, lunges, snaps shut
	PounceDamage = 26, -- from range: squats, leaps on you, slams down
	HopLength = 5, -- studs per hop as it chases
	Aggro = 40, -- studs; lose it past this for 6 s and it goes back to pretending
}

-- Rings. No effects yet: a ring is just a name.
Config.Rings = {
	Embellishment = { Name = "Ring of Embellishment" },
}

-- Cancel windows & input buffer (fractions are of the attack's recovery time).
Config.Combat = {
	DodgeCancel = 0.3, -- you can roll out of an attack after 30% of its recovery...
	AttackCancel = 0.5, -- ...but the next attack (combo) only comes out after 50%
	ComboGrace = 0.45, -- seconds after an attack ends that light still continues the chain
	BufferTime = 0.5, -- how long a press made during an action is remembered
	BladeRadius = 0.8, -- thickness of the sword's hit capsule
	PlayerRadius = 1.2, -- personal space vs. enemies (you can't walk through or climb them)
	RunAttackMinSpeed = 7, -- moving at least this fast when you press light = running attack
}

-- How hard you get hit. Stun = seconds you can't act. Push = knockback speed.
-- Knockdown: invincible from IFrom..ITo while down, and you can roll out after RollOut.
Config.HitReactions = {
	Small = { Stun = 0.25, Push = 8 },
	Stagger = { Stun = 0.25, Push = 10 }, -- short but unmistakable: knocked off balance, rooted, a pale flash (the dogs)
	Medium = { Stun = 0.45, Push = 14 },
	Large = { Stun = 0.75, Push = 22 },
	Knockdown = { Stun = 1.5, Push = 26, IFrom = 0.2, ITo = 1.25, RollOut = 0.8, Down = true },
	-- sent flying: a knockdown thrown up (Lift, studs/s) and far (Push for PushTime) (the Silver Knight)
	Launch = { Stun = 1.8, Push = 50, PushTime = 0.5, Lift = 34, IFrom = 0.15, ITo = 1.5, RollOut = 1.0, Down = true },
	Grabbed = { Stun = 0.5, Push = 0 }, -- held in a dog's jaws: rooted, nothing pushes you (Characters/Dog)
}

-- BREAK (a Lies of P style status; the dogs' bites build it - Core's breakPlayer). A meter
-- out of Max that fills with every bite and, after DrainDelay seconds of none, drains at
-- DrainPerSec. Full, you're BROKEN for Duration seconds: every hit on you does DamageMult
-- times as much, and you can't walk or roll. Its badge sits just above
-- Poison's (HudPosition).
Config.Break = { Max = 100, DrainDelay = 6, DrainPerSec = 7, Duration = 6, DamageMult = 1.5, HudPosition = UDim2.fromScale(0.5, 0.725) }

-- Music, Dark Souls style: silence while exploring, the boss theme hits when you
-- pass the fog, swells for phase 2, cuts the instant you die, fades on victory.
-- Paste asset ids like "rbxassetid://1234567890" (Creator Store tracks or your own uploads).
-- Leave BossPhase2 empty to use ONE track that starts muffled and opens up in phase 2.
Config.Music = {
	Boss = "rbxassetid://133441230367053", -- "jajaphase1"
	BossPhase2 = "rbxassetid://114483495293470", -- "jajaphase2"
	Victory = "", -- optional short sting when the Warden falls
	Ambience = "", -- optional low drone/wind loop for the jail (very quiet)
	Volume = 0.55,
	AmbienceVolume = 0.12,
}

Config.Boss = {
	Name = "The Ossuary Warden",
	HP = 950, -- (was 715)
	DamageScale = 0.9, -- multiplies every boss hit (slams, sweeps, eruptions, fire...)
	IdleExtra = 0.11, -- extra seconds he circles you between attacks (was 0.15)
	Poise = 300, -- (was 140) heavy attacks break it much faster than lights
	Stagger = 1.8,
}

-- The Castellan: the keep's last knight, on its battlements. Slow, long strings of
-- blows, a shield that turns aside anything from the front while he stands guard.
-- Killing him lets the prison's bell be rung.
Config.Castellan = {
	Name = "The Castellan",
	Name2 = "Ulrich Vale, the Last Castellan", -- the bar's name from his second phase on
	HP = 1800, -- (the Warden's is 950)
	Scale = 2.6,
	DamageScale = 1,
	Poise = 320, -- (the Warden's is 300)
	Stagger = 2.2,
	IdleExtra = 0.5, -- extra seconds he stands guard between strings
	Lines = {
		"Yet another?",
		"I swore none would leave this keep.",
		"You'll be no different, Skeleton!",
	},
	Again = "None leave this cursed prison.", -- every attempt after the first
	Dying = "As you wish then... ring the bell, and leave this cursed prison.",
	-- his music ("" = the Warden's boss tracks, Config.Music)
	Music = "rbxassetid://110000973487973", -- phase 1 ("cast1")
	Music2 = "rbxassetid://90667409622789", -- phase 2 ("cast2")
	Music2Length = 16.151, -- the source wav's exact length; loops there, past Roblox's added padding (0 = off)
	MusicFadeAt = 0.75, -- phase 1's piece fades out at this fraction of his HP (phase 2 is at 0.7)
}

-- THE CONSUL OF DECAY: the daughter's right hand, in the Hollow Mansion's attic (Characters/Consul.lua).
-- Lies in pieces until someone climbs up; then his head notices them and the rest of him crawls back to it.
-- (No attacks yet: he takes his stance and holds it.)
Config.Consul = {
	Name = "The Consul of Decay",
	Name2 = "Aldous, disciple of the forsaken Heir", -- his health bar's name in phase 2
	DeathLine = "I'm sorry, my dear Ossaria, my star... will you forgive me... will you forgive this sinner...",
	HP = 1650, -- (was 2200; his rise is 8/9 of it, so phase 2 stays 1467)
	Scale = 2.28,
	RollSpeed = 15.7, -- how fast he crawls at the top of a surge, studs/s (he comes on in fits, from about half this)
	Keep = 13, -- how close he comes before he stops and holds his stance (studs)
	-- DEV: set to "Slash", "Stilt", "Beam", "Blast" or "Matrix" (phase 2) and he uses only that attack (still on its own cooldown), to look at it
	-- without dodging the rest; nil = all of them, as in the real fight
	OnlyAttack = nil,
	-- the slash: the right sword, drawn up and back (he keeps turning to you as he does), brought down across him; and
	-- at once (Upper) the left sword, up from low on his left, back across him. Range/HalfAngle: the wedge in front of
	-- him they land in (studs, degrees); seconds otherwise
	Slash = { Damage = 34, Range = 15, HalfAngle = 70, Windup = 0.75, Swing = 0.14, Recover = 0.8, Cooldown = 2.2,
		-- (Gap + Windup + 0.6 x Swing = 0.65 s from the first hit to the second: one roll's i-frames, 0.385 s, can't
		-- cover both, but a second roll the moment the first ends can)
		Upper = { Damage = 30, Gap = 0.08, Windup = 0.45, Swing = 0.2 } },
	-- the stilt: up on his long limbs, as high as they reach (Lift studs, over Rise s), a moment there (Hold), then
	-- crashing down onto you like a wave (Fall s, forward first and then down; he lands up to Reach studs out): Damage within Radius of the line of
	-- his body, from where he lands to where his head comes down, and then he lies sprawled (Down s) while his limbs scramble back under him, and rights himself (Righting s). Used from Min to Max studs away
	SlashSounds = { "rbxassetid://137628815514180", "rbxassetid://128079790745111" }, -- (the slash, then the uppercut)
	-- his crawl's sound: the two layered, looped, as loud as he's moving (CrawlVolume at full tilt)
	CrawlSounds = { "rbxassetid://9120827051", "rbxassetid://9113124889" },
	CrawlVolume = 2.8, -- (4 x the old 0.7)
	SlamSound = "rbxassetid://8164951181", -- (the stilt's landing, and the wheel's)
	-- the beam: he rises (Lift studs, over Rise s) into a casting pose, a purple orb swelling before him for Charge s
	-- with a thin line out of it where the beam will start, then it fires and he turns with it, one whole circle in
	-- Sweep s. Width studs across, level at the height a player is hit at, out of his purple catalyst, Length at most (a wall or column stops it);
	-- Damage once to each player it crosses. Recover s after. Used from Min to Max studs away
	-- the blast: the censer's spell. He clutches in on himself for Charge s, then a pale dome of rot races out to Radius
	-- studs in Blast s (drawn 5% bigger than what hurts, left hanging and fading a few seconds). Damage to whatever is
	-- on the ground as its front passes (a jump clears it), once each; Recover s lying
	-- open after. Used up to Max studs away
	Blast = { Charge = 1.9, Blast = 0.5, Radius = 38, Damage = 50, Recover = 0.55, Max = 70, Cooldown = 17 },
	Beam = { Lift = 2.5, Rise = 0.9, Charge = 1.3, Sweep = 2.2, Width = 3, Length = 95, Damage = 42, Recover = 0.35, Min = 0, Max = 70, Cooldown = 15 },
	Stilt = { Lift = 8, Rise = 1.1, Hold = 0.45, Fall = 0.23, Damage = 48, Radius = 4.5, Reach = 15, Down = 0.6, Righting = 0.35, Min = 8, Max = 26, Cooldown = 8 },
	-- his rise (phase 1's health gone): he lies felled Lie s, then a cutscene (skippable) - he stands, says Line, and his
	-- beam takes the attic's whole top off Cut studs over the floor (about his shoulder), Rubble pieces of it crashing
	-- down round the arena; then he fights on at full health in the purple-lit ruin (phase 2's moves: not built yet)
	-- phase 2's matrix: he crawls to the nearest broken column and climbs it (Climb s), raises his catalysts to the sky
	-- (Raise s); then Waves times a pattern of Cell-stud floor squares glows (Telegraph s) and lasers come down on them
	-- (Fire s: Damage once a wave to whoever's in one; a roll goes through), Gap s between; then a ring where you stand,
	-- a crouch (Crouch s), and he leaps down onto it (Air s, Arc studs high): LeapDamage within LeapRadius. Recover s
	-- open after. First s into phase 2, then every Cooldown s
	Matrix = { Climb = 1.4, Raise = 1.0, Cell = 8, Telegraph = 1.1, Fire = 0.3, Gap = 0.35, Waves = 3, Damage = 38, Crouch = 0.45, Air = 0.75, Arc = 14, LeapDamage = 46, LeapRadius = 9, Recover = 0.9, First = 5, Cooldown = 20 },
	-- Slow: how much slower than his intro's his pieces crawl back and knit together (2.2 = 7.6 s becomes ~16.7 s)
	-- Health: his phase 2 health, as a share of HP
	Rise = { Lie = 5.5, Cut = 13, Rubble = 12, Slow = 2.2, Health = 8 / 9, Line = "Young Skeleton... you know not the wrath of Ossaria's lineage." },
	-- MUSIC PLACEHOLDER: paste an asset id ("rbxassetid://1234567890") to give him a theme; "" = silence.
	-- It starts when the cutscene ends (the Music attribute "consul") and cuts when you die or he falls.
	Music = "rbxassetid://112494537600315",
	MusicVolume = 0.55,
	-- the cutscene's own piece (consul_cutscene_p1.wav, 12.2 s): upload it and paste its id here. It starts late
	-- enough to end just as the cutscene does (first meeting only); "" = silence
	CutsceneVolume = 0.72, -- (30% over MusicVolume)
	CutsceneMusic = "131116687468378",
	-- phase 2, the same way: RiseMusic is the phase-change cutscene's piece (starts late enough to end as the cutscene
	-- does), Music2 is phase 2's fight piece (starts the instant the cutscene ends, loops till the fight is over).
	-- "" = silence (Music2 "" = phase 1's piece plays on)
	RiseMusic = "107561153188358",
	RiseVolume = 0.72,
	Music2 = "76598797206746",
	Music2Volume = 0.55,
}

-- THE SILVER KNIGHT: the boss of the Crowned Colosseum, out past the Weald
-- (Characters/Champion.lua). Damages are before DamageScale.
Config.Champion = {
	Name = "Silver Knight",
	Name2 = "Caelen, Knight of the Silver Oath", -- the bar's name from his second wind on
	-- his own music (uploaded silverknightp1intro / p1 / p2intro / p2 .wav; "" = the Warden's boss tracks).
	-- each intro plays once (the fight's start / his second wind), then its loop takes over
	Music = { P1Intro = "rbxassetid://130253765861787", P1 = "rbxassetid://126176375966417", P2Intro = "rbxassetid://74473873752463", P2 = "rbxassetid://129112960192641" },
	HP = 800,
	Scale = 2.0, -- (tall and lean: the Castellan is 2.6 and broad)
	DamageScale = 1,
	Poise = 240,
	Stagger = 1.6,
	WalkSpeed = 10.4, -- (0.8x of 13: a sprinting player can strafe him)
	IdleExtra = 0, -- extra seconds he circles between moves
	-- the spring: down on his haunches for SpringTell, then a flat leap through you
	SpringTell = 0.75, SpringSpeed = 70, SpringHeight = 3.5, SpringOvershoot = 12, SpringDamage = 48, SpringRecover = 0.7,
	-- the somersault slam
	FlipTell = 0.45, FlipTime = 0.95, FlipHeight = 11, FlipRadius = 5, FlipDamage = 58, FlipRecover = 1.0,
	FlipReach = 10, -- studs ahead of him the point lands: the slam's blast is centred there, clear of his feet
	ChainRecover = 0.1, -- the beat between leaps in a chain (a spring or flip is followed by 1-2 more)
	ChainAlternate = 0.9, -- chance each leap in a chain is the other kind from the one before
	-- the heave: three whole-body cuts (the last, the overhead slam, x1.3)
	CutDamage = 28, StringRecover = 1.0,
	HeaveTell = 0.75, HoistTell = 0.9, -- how long each coil is held before the cut
	HeaveDrag = 0.3, -- the beat the sword's weight drags on him after each cut
	SlamRadius = 7, -- the overhead slam's blast where the point lands
	SpinDamage = 40, SpinTell = 0.75, -- (the spin hurts only where the blade actually passes)
	HopDistance = 11, LungeDistance = 20, LungeDamage = 40, LungeRecover = 0.7,
	RoarDamage = 30, -- his second wind's blast
	PhaseLine = "Alright, Unyielding Skeleton, I declare you worthy of a true execution.",
	-- phase 2's whirlwind: held tell WhirlTell, then spinning (WhirlSpin rad/s) once round a curved
	-- triangle through the arena (radius WhirlPath, corners out / edges in by WhirlBulge) over
	-- WhirlTime; the blades reach WhirlReach, hitting each player at most once per WhirlTick
	WhirlTell = 1.8, WhirlTime = 5.0, WhirlSpin = 19, WhirlPath = 19, WhirlBulge = 0.26, WhirlReach = 18, WhirlDamage = 26, WhirlTick = 1.2, WhirlRecover = 1.8,
	-- the guaranteed phase 2 opener, ArenaSlash seconds after his second wind: a huge cut that hits
	-- everything on the sand for ArenaSlashWindow seconds - only a roll's invulnerability beats it.
	-- (test: ArenaSlash = false switches it off; Champion.luau's arenaSlash can be deleted with it)
	ArenaSlash = true, ArenaSlashTell = 2.0, ArenaSlashDamage = 0, ArenaSlashWindow = 0.2, ArenaSlashRecover = 1.6, -- (damage 0: it only knocks you down, about 1.8s)
	Regen = 0.002, -- he mends this fraction of his max health every second
	-- phase 2's crossing cut: both swords down across each other in front of him
	CrossTell = 0.8, CrossRange = 16, CrossArc = 70, CrossDamage = 33, CrossRecover = 1.1,
	-- the throw: aimed (he turns with you exactly) for ThrowTell, then it spins dead straight across the sand
	ThrowTell = 1.1, ThrowSpeed = 60, ThrowTime = 2.2, ThrowSpin = 22, ThrowRadius = 6, ThrowDamage = 45,
	-- ...the leap after it (GrabLeapSpeed studs/s), and the huge sweep out of the landing
	GrabLeapSpeed = 55, GrabLeapHeight = 10, GrabSweepTell = 0.45, GrabSweepRange = 20, GrabSweepArc = 110, GrabSweepDamage = 60, ThrowRecover = 1.4,
	Lines = {
		"200 years I've guarded the High Sanctum from my sister's wretched abominations.",
		"Foul Heap of Bones, turn back or I'll put you under ground.",
	},
	Again = "Again? Begone, foul Skeleton!", -- every attempt after the first
	Victor = "Come back when you're stronger, proud skeleton.", -- to you, when you fall on his sand
	Dying = "...At last... someone worthy of this armor, and this sword. Take them...",
	-- beaten, he stays kneeling on the sand: a line each time you talk to him, then FallenAfter
	-- over and over. On line FallenKeyAt he gives you the Silver Key (the "SilverKey" attribute).
	Fallen = {
		"Well fought, Skeleton. Two hundred years, and no one has put me on my knees. You have my respect.",
		"But hear me. My defeat opens nothing on its own. The Bastion above is sealed by three keys - one held by each of us siblings.",
		"Take mine. I give it freely.",
		"The other two will not come so easily. My sister least of all: a merciless dark mage. Her rotten magics have laid whole regions to waste.",
		"I gave my life to keeping her from the Bastion. That burden is yours now.",
		"If you truly wish to conquer this world, then get out there and challenge it with your own hands. And mark my words: <font color=\"rgb(160,12,12)\">Don't give up, Skeleton.</font>",
	},
	FallenKeyAt = 3,
	FallenAfter = "Go. The Bastion waits above... and so does she.",
	Gift = "Caelen's Twin Blades (needs 3 Strength) and Caelen's Silver Plate. Press T to choose weapons and armor.",
	SilverKey = "Silver Key. Bright and cold, untarnished by two hundred years. One of three.",
}

-- Oculast, the Blinded Usher: optional miniboss behind the Ashen Yard's west wall.
-- Two lives: when her first bar empties she falls, the bar vanishes... and the
-- rot gets her back up with a second bar, a new name and a new way of fighting.
-- Every damage number is before DamageScale.
Config.Usher = {
	Name = "Oculast, the Blinded Usher",
	Name2 = "Oculast, Forsaken Zealot", -- the surprise second bar
	HP = 570, -- first life (was 620)
	HP2 = 430, -- second life (was 480)
	WeakTo = { CastellanMace = 1.5, CaelenBlades = 1.5 }, -- damage taken x this, by the weapon in hand (strength weapons)
	Scale = 1.3,
	DamageScale = 1.4, -- multiplies every one of her hits (was 1.3)
	Damage = {
		Spin = 22, Chop = 38, Rising = 34, Turnabout = 24, -- first life
		Reap = 28, Reverse = 26, -- (used by her second life's Lurch)
		Burst = 20, -- the spore burst as she rises again
		Dance1 = 24, Dance2 = 26, Dance3 = 30, Plunge = 36, Breath = 26, -- second life
	},
	-- her first-life spin: floating a hair off the floor, turning and drifting after you
	Spin = {
		TurnRate = 210, -- degrees per second she turns (lower = slower spin)
		DriftSpeed = 2.5, -- studs per second she drifts toward you (lower = slower)
		FloatHeight = 0.3, -- studs off the floor (0.3 is a few inches on her)
		Duration = 7, -- seconds the spin lasts
		RehitTime = 0.9, -- seconds before the blade can cut the same person again
		Recover = 1.1, -- seconds she stands open after settling
		-- she spins in her second life too: faster and harder
		SpeedMult2 = 1.43, -- second-life turn rate = TurnRate x this (was 1.3: 10% faster)
		DriftMult2 = 2.2, -- second-life drift = DriftSpeed x this (2.5 -> 5.5 studs/s; you walk at 12)
		Weight2 = 4, -- how often she picks it in her second life (was 2; Lurch is 4, Dance 3)
		Cooldown2 = 6, -- seconds before she can spin again in her second life (was 10)
		DamageMult2 = 1.5, -- second-life spin damage = Damage.Spin x this
	},
	-- COUNTER STANCE (both lives): she sinks low, blade laid flat behind her back, hood
	-- burning, and waits. Hit her during it and she slips your blow, appears at your
	-- side and kills you outright. Leave her be (or deflect the counter) to live.
	Stance = {
		Hold = 2.2, -- seconds she waits in the stance
		Delay = 0.12, -- seconds from your hit to her killing cut
		Weight = 2, -- how often she picks it (Chop/Spin are 3)
		Cooldown = 12, -- seconds before she can use it again
	},
	-- ROT TETHER, her second life only. A ring of spores on the floor follows her
	-- around. Stay inside it and you're fine; step outside and after Grace seconds
	-- the haze starts choking you. It starts wide, closes in over ShrinkTime, then
	-- STOPS at MinRadius and never gets tighter. For scale: a player is about 5
	-- studs tall, so MinRadius 20 is roughly 4 body-lengths away from her, well
	-- outside her scythe (about 12 studs). The haze never stuns you and isn't
	-- dodged by rolling. Set Enabled = false to turn the whole thing off.
	Tether = {
		Enabled = true,
		StartRadius = 36, -- studs from her when the ring first rises
		MinRadius = 20, -- where it stops closing in (raise it to be even kinder)
		ShrinkTime = 50, -- seconds to close from StartRadius to MinRadius
		Grace = 1.75, -- seconds you can be outside before it hurts at all
		DPS = 2, -- damage per second when it starts (you have 100 HP)
		DPSMax = 6, -- damage per second after RampTime more seconds outside
		RampTime = 6,
		TickTime = 0.5, -- how often it checks and hurts
		Markers = 32, -- how many glowing marks make up the ring
		RingTransparency = 0.55, -- 0 = solid marks, 1 = invisible (the spores still show)
		Warning = "The rot will not let you stray far from her.", -- "" = no message
	},
	-- How long she draws back before each swing of her standing attacks (Chop,
	-- the reaps, Turnabout, Spin's start, Dance's cuts, Breath), as a multiplier.
	-- Each wind-up also flares her hood, grates the haft, and flashes a glint on
	-- the blade's tip just before the swing. 1 = her old timing.
	Telegraph = 1.6,
	Telegraph2 = 1.35, -- the same, in her second life: the rot gives less warning
	Poise = 95, -- ~8 lights or 3 heavies to stagger her (was 80)
	Stagger = 1.1, -- (was 1.3)
	-- walking speed (first / second life): used when she circles you between attacks,
	-- closes in when nothing reaches, and walks back to her altar. Her rushes (Lunge,
	-- Lurch, Plunge, Spin) are their own moves and ignore it. Raise IdleExtra to
	-- see more walking: that's how long she circles between attacks.
	WalkSpeed = 16,
	WalkSpeed2 = 19,
	TurnRate = 220, -- deg/s (x1.35 while you're loud, x0.8 while you're quiet)
	TurnRate2 = 280,
	Phase2Tempo = 0.8, -- windup multiplier in her second life
	IdleExtra = 0, -- extra pause between her attacks (was 0.05)
	WakeQuiet = 11, -- she wakes if you come this close, even walking...
	WakeNoisy = 24, -- ...or this close while running, rolling or drinking
	Music = "rbxassetid://90273096397979", -- her first-life theme ("" = silence, just the scythe)
	Music2 = "rbxassetid://128853027264126", -- her second-life theme ("" = reuse Music, a touch faster)
	Music2Volume = 1.125, -- her second-life theme plays 12.5% louder (read by the client music script)
}

-- The Ruined Township's fog: a sickly haze lying over the whole outdoor town. Breathing
-- it builds poison up (the small bar under your stamina); when the bar fills you're
-- poisoned (the same poison as Oculast's breath) and it starts over. Out of the fog it
-- ebbs away. It drags at your legs too. Zone = the area name it covers (MapBuilder Zones).
Config.TownFog = {
	Zone = "Ruined Township",
	Buildup = 4, -- per second in the fog; 100 = poisoned (about 25 seconds)
	Ebb = 15, -- per second out of it
	Slow = 0.5, -- your walk and run speed in it (1 = no slow; was 0.88)
	Poison = { Total = 24, DPS = 2, Label = "POISONED" }, -- health it eats, how fast
	-- how it looks from inside (the client thickens the air while you're in it)
	Density = 0.74, Haze = 3, -- (20% thicker than it was: 0.62) Color = Color3.fromRGB(132, 140, 112), Decay = Color3.fromRGB(70, 76, 58),
}

-- WICK, the girl in the nook north of the Upper Drain. Edit her lines freely.
-- Intro plays once, in order, the first times you talk to her; after that she
-- cycles through More forever (the first of them is her CloakLine, and her cloak).
-- AfterUsher / AfterWarden are said once each, the
-- next time you talk to her after that boss falls. Lines with "He he" in them make
-- her hunch her shoulders and giggle; any others, she just tilts her head at you.
Config.Wick = {
	Name = "Mabel",
	Intro = {
		"Oh! Someone came up the drain on bones, same as me. He he...",
		"I think you might get out of here if you try... the jailers have all gone quiet.",
		"Don't mind the mud on these bones... He he he...",
	},
	More = {
		"Oh, I almost forgot...",
		"There's a lady kneeling in the old chapel, past the yard's west wall. Walk soft in there. She hears you breathing. He he...",
		"That sad sad girl... her leader betrayed her here and left her there blinded...",
		"The Vanguard's daughter came this way once. She stopped right where you're standing, and she wept, and the stone went soft...",
		"She scares the daylights out of me... I'd be sure grateful if you got rid of her...",
		"Go on, then. The dark's waiting for you, and it's ever so patient.",
	},
	AfterUsher = "Oh! She's at rest? Really? Oh, thank goodness... Here, the hood that goes with my cloak. Ever so fashionable together. He he...",
	AfterWarden = "I'll have dark magics to teach you next time you return then..",
	-- her gifts (Config.Armor): the Dark Cloak with CloakLine, the first time you talk to her
	-- after her Intro; the Dark Hood with AfterUsher, once the Usher is dead
	CloakLine = "You're shivering, bones and all. Take my old cloak... it likes the dark, and the dark likes it. He he...",
}

-- WRETCH GILES, in the shack by the Crossing in the rotted encampment. Edit freely.
-- Intro plays once, in order; after that he cycles through More. Lines with "Ha!", "Ha ha" or
-- "He he" in them make him rock back and laugh; any others, he leans toward you.
-- Once you've killed ArmorKills enemies (any, anywhere) he gives you his armor - his own
-- outfit, cone hat and all (Config.Armor.Motley) - with ArmorLine.
Config.Taylor = {
	Name = "Wretch Giles",
	ArmorKills = 5,
	ArmorLine = "Ha! Busy little bones, aren't you? Here - my best work, stitched to fit. Wear it in good health.. He he..",
	Intro = {
		"Aha! A most fresh skeleton in this town! Come to save this place from the daughter? Eh?",
		"Too late, I'm afraid, by many many years... but a young chap like you could find a worthwhile adventure in this little town, I'm sure of it..",
		"In fact, across the bridge there are many poor souls who you might do quite a favor by putting them to rest.",
	},
	More = {
		"Put a few of them to rest for old Giles, and I'll sell you some armor! Fine stitching I promise.. He he...",
		"Mind the bridge, though.. watch your footing..",
	},
}

-- THE OLD HAG, shut in behind the tunnel door at the end of the high bridge (Characters/Hag).
-- Edit freely. Intro plays once, in order; the next time you talk she gives you the Old Book
-- with BookLine; after that she cycles through More.
Config.Hag = {
	Name = "Old Hag",
	Intro = {
		"Th-thank you..",
		"You saved me..",
		"So long in the dark.. so long..",
		"I can teach you pyromancies.. as my way of thanks..",
	},
	BookLine = "Here's a book of pyromancies.. as a start..",
	More = {
		"Fire cleanses the rot, little bones.. remember that..",
		"Dry old wood chokes the way west of here.. it would burn so nicely..",
	},
}

return Config
