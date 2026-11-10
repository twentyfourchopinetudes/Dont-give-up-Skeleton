--!nonstrict
-- Music: Dark Souls-style score. Silent exploration; the boss theme hits when
-- the fog is crossed, swells for phase 2, cuts dead when you die, fades on victory.
-- Track ids live in ReplicatedStorage.Config.Music.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local M = Config.Music or {}

local function track(id, looped)
	if not id or id == "" then
		return nil
	end
	if tonumber(id) then -- (a bare asset number pasted in: give it its scheme)
		id = "rbxassetid://" .. id
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Looped = looped
	s.Volume = 0
	s.Parent = SoundService
	return s
end

local boss1 = track(M.Boss, true)
local boss2 = track(M.BossPhase2, true)
local victory = track(M.Victory, false)
local ambience = track(M.Ambience, true)
local usherTrack = track(Config.Usher and Config.Usher.Music, true) -- optional
local usherTrack2 = track(Config.Usher and Config.Usher.Music2, true) -- optional second-life theme
local CM = Config.Champion and Config.Champion.Music or {}
local champIntro1 = track(CM.P1Intro, false)
local champ1 = track(CM.P1, true)
local champIntro2 = track(CM.P2Intro, false)
local champ2 = track(CM.P2, true)
local castellan1 = track(Config.Castellan and Config.Castellan.Music, true) -- the Castellan's own (optional)
local castellan2 = track(Config.Castellan and Config.Castellan.Music2, true)
local consulTrack = track(Config.Consul and Config.Consul.Music, true) -- the Consul of Decay's (placeholder: "" = silence)
local consulIntro = track(Config.Consul and Config.Consul.CutsceneMusic, false) -- his cutscene's (played once through)
local consulRise = track(Config.Consul and Config.Consul.RiseMusic, false) -- his phase-change cutscene's
local consul2 = track(Config.Consul and Config.Consul.Music2, true) -- his phase 2 fight piece ("" = phase 1's plays on)
local loopEnd =Config.Castellan and Config.Castellan.Music2Length or 0
if castellan2 and loopEnd > 0 then
	-- the upload gets a few ms of silence tacked on; loop at the real end instead
	castellan2.PlaybackRegionsEnabled = true
	castellan2.LoopRegion = NumberRange.new(0, loopEnd)
end

-- single-track mode: phase 1 plays darker/muffled, phase 2 opens it up
local eq
if boss1 and not boss2 then
	eq = Instance.new("EqualizerSoundEffect")
	eq.HighGain = -14
	eq.MidGain = -4
	eq.LowGain = 2
	eq.Parent = boss1
end

if not boss1 then
	print("[DGUS] No boss music set - add a track id to Config.Music.Boss (see README).")
end

local function fade(s, vol, time, stopAfter)
	if not s then
		return
	end
	local tw = TweenService:Create(s, TweenInfo.new(time, Enum.EasingStyle.Sine), { Volume = vol })
	tw:Play()
	if stopAfter then
		tw.Completed:Connect(function(st)
			-- (only a fade that ran its course stops it: one cut off by a fade back in, as the cutscene's piece hands over to the fight's, must not)
			if st == Enum.PlaybackState.Completed and s.Volume <= 0.001 then
				s:Stop()
			end
		end)
	end
end

if ambience then
	ambience:Play()
	fade(ambience, M.AmbienceVolume or 0.12, 4)
end

local current = "none"

-- the Consul's fight piece: straight in, at full volume, no fade - the moment the cutscene's piece ends (or at once,
-- if it isn't playing: skipped, or none)
local CONSUL = { consul = 1, consulintro = 1, consul2 = 2, consulrise = 2 } -- (state -> phase)
local function startConsul()
	local ph = CONSUL[current]
	local t = ph == 2 and consul2 or consulTrack
	if t and not t.IsPlaying then
		t.TimePosition = 0
		t.Volume = (ph == 2 and consul2 and Config.Consul.Music2Volume or Config.Consul.MusicVolume) or 0.55
		t:Play()
	end
end
if consulIntro then
	consulIntro.Ended:Connect(startConsul)
end
if consulRise then
	consulRise.Ended:Connect(startConsul)
end
-- the Silver Knight: *intro states start the intro late enough that it ends as the cutscene does
-- (server attr "MusicIntro" = seconds of cutscene left); the plain states are the phase's loop
local champPhase = { championintro = 1, champion = 1, championintro2 = 2, champion2 = 2 }
local champTracks = { { champIntro1, champ1 }, { champIntro2, champ2 } }
local champVol = math.min(1, (M.Volume or 0.55) * 1.15) -- (his two themes sit 15% louder than the rest)

-- phase 1 dies away as he nears his second wind: from 2% of his health above the threshold down to it
local PHASE2_AT, DIM_BAND = 0.5, 0.02
task.spawn(function()
	local dimmed = false
	while true do
		task.wait(0.1)
		if (current == "champion" or current == "championintro") and ReplicatedStorage:GetAttribute("BossActive") and not ReplicatedStorage:GetAttribute("MusicSteady") then -- (MusicSteady: Ossaria's own fight, on his theme: no second wind at half a bar)
			local mx = ReplicatedStorage:GetAttribute("BossMaxHP") or 0
			if mx > 0 then
				local f = math.clamp(((ReplicatedStorage:GetAttribute("BossHP") or mx) / mx - PHASE2_AT) / DIM_BAND, 0, 1)
				if f < 1 or dimmed then
					dimmed = f < 1
					for _, t in ipairs({ champIntro1, champ1 }) do
						if t and t.IsPlaying then
							t.Volume = champVol * (0.08 + 0.92 * f * f)
						end
					end
				end
			end
		else
			dimmed = false
		end
	end
end)

local function apply(state)
	-- no Silver Knight tracks set: he gets the Warden's
	if (state == "champion" or state == "championintro") and not champ1 then
		state = "boss"
	elseif (state == "champion2" or state == "championintro2") and not champ2 then
		state = "boss2"
	end
	if state == current then
		return
	end
	local prev = current
	current = state
	local vol = M.Volume or 0.55
	if (prev == "usher" or prev == "usher2") and state ~= "usher" and state ~= "usher2" then
		-- her first bar emptying cuts it almost dead (the silence sells the "death")
		local cut = prev == "usher" and 0.4 or 1.5
		fade(usherTrack, 0, cut, true)
		fade(usherTrack2, 0, cut, true)
	end
	local ph, prevPh = champPhase[state], champPhase[prev]
	if prevPh and not ph then
		local cut = state == "victory" and 3 or 0.25
		for _, set in ipairs(champTracks) do
			for _, t in ipairs(set) do
				fade(t, 0, cut, true)
			end
		end
	end
	if ph then
		fade(ambience, 0, 1.5)
		if ph == 2 then -- the second-wind cutscene: phase 1 is gone in a tenth of a second, long before this music starts
			for _, t in ipairs({ champIntro1, champ1 }) do
				fade(t, 0, 0.1, true)
			end
		end
		local intro, loop = champTracks[ph][1], champTracks[ph][2]
		local function dropPhase1() -- (phase 2's music cuts phase 1's)
			if ph == 2 then
				fade(champIntro1, 0, 0.4, true)
				fade(champ1, 0, 0.4, true)
			end
		end
		if state == "championintro" or state == "championintro2" then
			if intro then
				task.spawn(function()
					if intro.TimeLength == 0 then
						intro.Loaded:Wait()
					end
					local lead = (ReplicatedStorage:GetAttribute("MusicIntro") or intro.TimeLength) - intro.TimeLength
					if lead > 0 then
						task.wait(lead)
					end
					if current == state then
						dropPhase1()
						intro.TimePosition = math.max(-lead, 0)
						intro.Volume = champVol
						intro:Play()
					end
				end)
			end
		else
			dropPhase1()
			fade(intro, 0, 0.3, true)
			loop.TimePosition = 0
			loop.Volume = champVol
			loop:Play()
		end
		return
	end
	if CONSUL[prev] and not CONSUL[state] then
		local cut = state == "victory" and 3 or state == "consulfall" and 1 or 0.25 -- (consulfall: he's scattered)
		for _, t in ipairs({ consulTrack, consulIntro, consulRise, consul2 }) do
			fade(t, 0, cut, true)
		end
	end
	if state == "consulintro" or state == "consulrise" then
		fade(ambience, 0, 1.5)
		local cs = state == "consulrise" and consulRise or consulIntro
		local csVol = state == "consulrise" and Config.Consul.RiseVolume or Config.Consul.CutsceneVolume
		if cs then -- held back so it ends right as the cutscene does (server attr "MusicIntro" = its length)
			task.spawn(function()
				if cs.TimeLength == 0 then
					cs.Loaded:Wait()
				end
				local lead = (ReplicatedStorage:GetAttribute("MusicIntro") or cs.TimeLength) - cs.TimeLength
				if lead > 0 then
					task.wait(lead)
				end
				if current == state then
					cs.TimePosition = math.max(-lead, 0)
					local target = csVol or Config.Consul.MusicVolume or vol
					cs.Volume = state == "consulrise" and 0 or target
					cs:Play()
					if state == "consulrise" then
						fade(cs, target, 3) -- (the phase change's piece swells in over 3 s)
					end
				end
			end)
		end
		return
	end
	if state == "consul" or state == "consul2" then
		fade(ambience, 0, 1.5)
		if state == "consul2" and not consul2 then -- (no phase 2 piece: phase 1's plays on)
			startConsul()
			return
		end
		local cs = state == "consul2" and consulRise or consulIntro
		if not (cs and cs.IsPlaying) then -- (else it starts when that ends: .Ended)
			if state == "consul2" then
				fade(consulTrack, 0, 0.3, true)
			end
			startConsul()
		end
		return
	end
	if (prev == "castellan" or prev == "castellan2") and state ~= "castellan" and state ~= "castellan2" then
		local cut = state == "victory" and 3 or 0.25
		fade(castellan1, 0, cut, true)
		fade(castellan2, 0, cut, true)
	end
	if state == "castellan" or state == "castellan2" then
		fade(ambience, 0, 1.5)
		if state == "castellan2" and castellan2 then
			-- phase 2: hard cut, phase 2 comes in at full volume the same instant
			if castellan1 then
				castellan1:Stop()
				castellan1.Volume = 0
			end
			castellan2.TimePosition = 0
			castellan2.Volume = vol
			castellan2:Play()
			return
		end
		-- phase 2: its own piece if one is set, otherwise phase 1's plays on
		local t = state == "castellan2" and castellan2 or castellan1
		if t and not t.IsPlaying then
			t.TimePosition = 0
			t:Play()
			fade(t, vol, state == "castellan2" and 1.5 or 0.8)
		end
		if state == "castellan2" and castellan2 then
			fade(castellan1, 0, 1.5, true)
		end
	elseif state == "usher" or state == "usher2" then
		fade(ambience, 0, 1.5)
		-- second life: its own theme if one is set, otherwise the first one from the top, faster
		local own2 = state == "usher2" and usherTrack2 ~= nil
		local t = own2 and usherTrack2 or usherTrack
		if t then
			t.TimePosition = 0
			t.PlaybackSpeed = (state == "usher2" and not own2) and 1.05 or 1
			t:Play()
			fade(t, state == "usher2" and math.min(1, vol * 1.1) or vol, state == "usher2" and 0.3 or 0.8)
		end
		if own2 then
			fade(usherTrack, 0, 0.3, true)
		end
	elseif state == "boss" then
		fade(ambience, 0, 1.5)
		if boss1 then
			boss1.TimePosition = 0
			boss1.PlaybackSpeed = 1
			if eq then
				eq.HighGain, eq.MidGain = -14, -4
			end
			boss1:Play()
			fade(boss1, eq and vol * 0.8 or vol, 0.6) -- it hits almost at once
		end
	elseif state == "boss2" then
		if boss2 then
			boss2.TimePosition = 0
			boss2:Play()
			fade(boss2, vol, 1.5)
			fade(boss1, 0, 1.5, true)
		elseif boss1 then
			-- open the filter, push the volume, tighten the tempo a hair
			TweenService:Create(eq, TweenInfo.new(2.5, Enum.EasingStyle.Sine), { HighGain = 0, MidGain = 0, LowGain = 3 }):Play()
			fade(boss1, math.min(1, vol * 1.25), 2.5)
			TweenService:Create(boss1, TweenInfo.new(2.5), { PlaybackSpeed = 1.03 }):Play()
		end
	elseif state == "victory" then
		fade(boss1, 0, 3, true)
		fade(boss2, 0, 3, true)
		if victory then
			task.delay(1.5, function()
				victory.Volume = vol
				victory:Play()
			end)
		end
		fade(ambience, M.AmbienceVolume or 0.12, 8)
	else -- "none": you died / the fight reset. Cut it, almost dead.
		local cut = (prev == "boss" or prev == "boss2") and 0.25 or 1
		fade(boss1, 0, cut, true)
		fade(boss2, 0, cut, true)
		fade(ambience, M.AmbienceVolume or 0.12, 4)
	end
end

-- the Castellan's phase 1 piece fades out as he nears his second phase
local fadeAt = Config.Castellan and Config.Castellan.MusicFadeAt or 0
local fadedOut = false
ReplicatedStorage:GetAttributeChangedSignal("BossHP"):Connect(function()
	local hp, max = ReplicatedStorage:GetAttribute("BossHP"), ReplicatedStorage:GetAttribute("BossMaxHP")
	if current ~= "castellan" then
		fadedOut = false -- re-arms for the next attempt
	elseif not fadedOut and hp and max and hp <= max * fadeAt then
		fadedOut = true
		fade(castellan1, 0, 2)
	end
end)

-- the Consul's cutscene skipped: its piece cut short (and if it hadn't started yet, it won't: the state moves on)
ReplicatedStorage:GetAttributeChangedSignal("ConsulIntroCut"):Connect(function()
	fade(consulIntro, 0, 0.4, true)
	fade(consulRise, 0, 0.4, true)
	task.delay(0.5, function() -- (and the fight's piece, if the fight has already begun, in the place of the one just cut)
		if current == "consul" or current == "consul2" then
			startConsul()
		end
	end)
end)

apply(ReplicatedStorage:GetAttribute("Music") or "none")
ReplicatedStorage:GetAttributeChangedSignal("Music"):Connect(function()
	apply(ReplicatedStorage:GetAttribute("Music") or "none")
end)
