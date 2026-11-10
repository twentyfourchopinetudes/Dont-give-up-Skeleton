--!nonstrict
-- Decay: turns fire into rot. Decay.apply(inst) reskins an enemy (its bright oranges and lava gone to dark greens and
-- purples); Decay.watch(rects, skip) does the same, as they're made, to everything that appears inside the Decayed
-- Palace's rects (the attacks' bolts, cracks, bursts, breath), so the character files stay as they are.
-- Fire -> a dark aura (smoke, not flame) of the same size; Neon fx -> ForceField; CrackedLava skin -> Slate.
local Decay = {}

local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local AURA = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 40, 92)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(34, 58, 34)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 16, 14)),
})

-- fire's colours: reds/oranges/yellows, saturated and bright, or near white-hot with a warm cast
local function warm(c)
	local h, s, v = c:ToHSV()
	return (h < 0.17 or h > 0.93) and ((s > 0.4 and v > 0.4) or (s > 0.12 and v > 0.85))
end
local function rot(c) -- reds -> dark purple, oranges/yellows -> dark green; the brighter, the less dark
	local h, _, v = c:ToHSV()
	return Color3.fromHSV((h < 0.05 or h > 0.93) and 0.78 or 0.3, 0.55, 0.12 + 0.3 * v)
end
local function rotSeq(seq)
	local kps = {}
	for i, kp in ipairs(seq.Keypoints) do
		kps[i] = ColorSequenceKeypoint.new(kp.Time, warm(kp.Value) and rot(kp.Value) or kp.Value)
	end
	return ColorSequence.new(kps)
end

local function aura(fire) -- a Fire can't be hidden, only switched off: it goes, and a dark aura burns in its place
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "DecayAura"
	pe.Texture, pe.Color, pe.LightEmission, pe.LightInfluence = SMOKE, AURA, 0, 0.3
	pe.Lifetime, pe.Rate, pe.Speed = NumberRange.new(0.5, 1), 40, NumberRange.new(1, 3)
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.2, 0.25), NumberSequenceKeypoint.new(1, 1) })
	pe.Rotation, pe.RotSpeed, pe.SpreadAngle = NumberRange.new(0, 360), NumberRange.new(-60, 60), Vector2.new(25, 25)
	local function sync()
		pe.Size = NumberSequence.new(fire.Size * 0.35, fire.Size * 0.9)
		pe.Acceleration = Vector3.new(0, fire.Heat * 0.6, 0)
		pe.Enabled = fire.Enabled
	end
	sync()
	fire.Changed:Connect(sync) -- (the character files still drive it: Size, Enabled)
	pe.Parent = fire.Parent
	task.defer(function() -- (out of the world, not destroyed: the scripts keep their handle on it)
		fire.Parent = nil
	end)
end

local function one(inst, fx) -- fx: an attack's, not on a body (its Neon goes to ForceField)
	if inst:IsA("BasePart") then
		if inst.Material == Enum.Material.CrackedLava then
			inst.Material, inst.Color = Enum.Material.Slate, Color3.fromRGB(42, 46, 36)
		end
		local function recolor()
			if warm(inst.Color) then
				inst.Color = rot(inst.Color)
			end
		end
		if warm(inst.Color) then
			if fx and inst.Material == Enum.Material.Neon then
				inst.Material = Enum.Material.ForceField
			end
			recolor()
			inst:GetPropertyChangedSignal("Color"):Connect(recolor) -- (a grate drawn white-hot frame by frame)
		end
	elseif inst:IsA("Fire") then
		aura(inst)
	elseif inst:IsA("ParticleEmitter") then
		inst.Color = rotSeq(inst.Color)
		inst.LightEmission = math.min(inst.LightEmission, 0.15) -- (additive light would make the dark colours vanish)
		if string.find(inst.Texture, "fire") then
			inst.Texture = SMOKE
		end
	elseif inst:IsA("Light") then
		if warm(inst.Color) then
			inst.Color, inst.Brightness = rot(inst.Color), inst.Brightness * 0.6
		end
	elseif inst:IsA("Trail") or inst:IsA("Beam") then
		inst.Color = rotSeq(inst.Color)
		inst.LightEmission = math.min(inst.LightEmission, 0.15)
	end
end

function Decay.apply(root)
	one(root, false)
	for _, d in ipairs(root:GetDescendants()) do
		one(d, false)
	end
end

function Decay.watch(rects, skip)
	local function inside(p)
		for _, q in ipairs(rects) do
			if p.X >= q[1] and p.X <= q[3] and p.Z >= q[2] and p.Z <= q[4] then
				return true
			end
		end
		return false
	end
	workspace.DescendantAdded:Connect(function(inst)
		if not (inst:IsA("BasePart") or inst:IsA("Fire") or inst:IsA("ParticleEmitter") or inst:IsA("Light") or inst:IsA("Trail") or inst:IsA("Beam")) then
			return
		end
		local part = inst:IsA("BasePart") and inst or inst:FindFirstAncestorWhichIsA("BasePart")
		if not part or inst:IsDescendantOf(skip) or not inside(part.Position) then
			return
		end
		local model = inst:FindFirstAncestorWhichIsA("Model")
		if model then -- (in a model: only an enemy's, not a player's armour put on in here)
			local a = model
			while a and not a:GetAttribute("Enemy") do
				a = a:FindFirstAncestorWhichIsA("Model")
			end
			if not a then
				return
			end
		end
		one(inst, model == nil)
	end)
end

return Decay
