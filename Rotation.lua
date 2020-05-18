local DMW = DMW
local Warlock = DMW.Rotations.WARLOCK
local Rotation = DMW.Helpers.Rotation
local Setting = DMW.Helpers.Rotation.Setting
local Player, Pet, Buff, Debuff, Spell, Target, Talent, Item, GCD, CDs, HUD, Enemy20Y, Enemy20YC, Enemy30Y, Enemy30YC, NewTarget, ShardCount, Curse, CTime, dmgTrinkets, ManaPct
local WandTime = GetTime()
local PetAttackTime = GetTime()
local ItemUsage = GetTime()
local SendAddonMessage = C_ChatInfo.SendAddonMessage
local bossName = nil
local threatPercent = 0
local BossEngaged = false
local Trinket1 = GetInventoryItemID("player", 13)
local Trinket2 = GetInventoryItemID("player", 14)

if not KinkyDots then KinkyDots = {} end

local function Shards(Max)
    local Count = 0
    for Bag = 0, 4, 1 do
        for Slot = 1, GetContainerNumSlots(Bag), 1 do
            local ItemID = GetContainerItemID(Bag, Slot)
            if ItemID and ItemID == 6265 then
                if Count >= Max then
                    PickupContainerItem(Bag, Slot)
                    DeleteCursorItem()
                else
                    Count = Count + 1
                end
            end
        end
    end
    return Count
end

--Lucifron: Sacrifice Imp + equip branch
local function GetCurse()
    local CurseSetting = Setting("Curse")
    if CurseSetting ~= 1 and HUD.Curse == 1 then
        if CurseSetting == 2 then
            return "CurseOfAgony"
        elseif CurseSetting == 3 then
            return "CurseOfShadow"
        elseif CurseSetting == 4 then
            return "CurseOfTheElements"
        elseif CurseSetting == 5 then
            return "CurseOfRecklessness"
        elseif CurseSetting == 6 then
            return "CurseOfWeakness"
        elseif CurseSetting == 7 then
            return "CurseOfTongues"
        elseif CurseSetting == 8 then
            return "CurseOfDoom"
        end
    elseif Target and Target.Player then
        return "CurseOfAgony"
    end
    return nil
end

local function Locals()
    Player = DMW.Player
    Pet = DMW.Player.Pet
    CTimer = Player.CombatTime
    Buff = Player.Buffs
    Debuff = Player.Debuffs
    Spell = Player.Spells
    Talent = Player.Talents
    Item = Player.Items
    Target = Player.Target or false
    HUD = DMW.Settings.profile.HUD
    CDs = Player:CDs()
    GCD = Player:GCD()
    Enemy20Y, Enemy20YC = Player:GetEnemies(20)
    Enemy30Y, Enemy30YC = Player:GetEnemies(30)
    ShardCount = Shards(Setting("Max Shards"))
    dmgTrinkets = {
        18820, -- Talisman of Ephemeral Power
        19950, -- Zandalarian Hero Charm
        23046, --The Restrained Essence of Sapphiron
        11832 -- The Burst of Knowledge
    }
    dmgDebuff = {
     15258, -- Shadow Vulnerability (priest)
     17800, -- Shadow Vulnerability (Improved Shadow bolt)
     23605, -- Nightfall
     17938 -- Curse of Shadow
    
    }
    dmgBuff = {

    }
    ManaPct = Player.PowerPct
    Curse = GetCurse()
end
local function debug(message)
    if Setting("Debug") then print(tostring(message)) end
end
--https://classic.wowhead.com/spell=6346/fear-ward

-- Getting the Encounter Name
local function ENCOUNTER_START(encounterID, name, difficulty, size)
	name = bossName
	BossEngaged = true
end
-- Removing the Encounter Name
local function ENCOUNTER_END(encounterID, name, difficulty, size)
	bossName = nil
	BossEngaged = false
end
local function CorruptionPower()
    -- Fetch our current stats.
    local  crit, spd = GetSpellCritChance(6), GetSpellBonusDamage(6)
    local _,_,_,_,SM_rank,_ = GetTalentInfo(1,16) -- get rank of Shadow Mastery
    local _,_,_,_,DS_rank,_ = GetTalentInfo(2,13) -- get rank of Demonic Sacrifice
    local _,_,_,_,ISB_rank,_ = GetTalentInfo(3,1) -- get rank of Improved Shadow Bolt
    local ISB_List = {17800,17799,17798,17797,17794} -- spellIds for Improved Shadow Bolt Debuffs
    
    
    -- Calculate potential damage buffs.
    dmg_buff = 1
    local pi = Buff.PowerInfusion:Exist(Player)
    if pi then dmg_buff = dmg_buff * 1.05 end
       
    -- Shadow Mastery
    local SM_increase = SM_rank * .02
    dmg_buff = dmg_buff + (dmg_buff * SM_increase)
    
    -- Demonic Sacrifice (Succubus)
    if Buff.DemonicSac:Exist(Player) then dmg_buff = dmg_buff + (dmg_buff * .15) end
    
    -- Improved Shadow Bolt 
    if Target and ISB_rank then
       local ISB_increase = ISB_rank * .04
       for k = 1, 40 do
          local testName,_,_,_,_,_,_,_,_,ISB_spellId = UnitDebuff("target", k)
          for index, value in ipairs(ISB_List) do
             if value == ISB_spellId then dmg_buff = dmg_buff + (dmg_buff * ISB_increase) end
          end
       end
    end
    
    bonus = 1+crit/100
    tick_every = 3
    
    -- Corruption
    ticks     = PowerRound(18/tick_every)
    duration  = ticks*tick_every
    damage    = (666+ticks*spd*1.0)*bonus*dmg_buff
    dps       = PowerRound(damage/duration)
    dot_power = PowerRound(dps/100)/10
    return dot_power
end

function CombatLogEvent(...)
    if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then if #KinkyDots > 0 then KinkyDots = {} end end


    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local subEvent		= select(2, ...)
		local source		= select(5, ...)
		local destGUID		= select(8, ...)
		local destination	= select(9, ...)
		local spellID		= select(12, ...)
		local spell			= select(13, ...)
		local damage		= select(15, ...)
		local critical		= select(21, ...)
        local cor_tick_every = 3
		
		-- Unit Death events
		if subEvent == "UNIT_DIED" then
			-- A unit has died, is it in our tracker?
			if #KinkyDots > 0 then for i=1,#KinkyDots do if KinkyDots[i].guid == destGUID then tremove(KinkyDots, i) return true end end end
		end
		
		-- Refreshed Aura Events
		if subEvent == "SPELL_AURA_REFRESH" then
			-- Corruption Was refreshed. 
			if UnitName("player") == source and spellID == 11672 then
				if #KinkyDots > 0 then
					for i=1,#KinkyDots do
						if KinkyDots[i].guid == destGUID and KinkyDots[i].spellID == spellID then
							KinkyDots[i].corPower = CorruptionPower()
							KinkyDots[i].cor_tick_every = cor_tick_every 
							KinkyDots[i].spellID = spellID
                            if UnitBuffID("player",23271) then KinkyDots[i].toep = true else KinkyDots[i].toep = false end
                            debug("PELL_AURA_REFRESH" .. KinkyDots[i].corPower .. KinkyDots[i].toep)
                            debug("PELL_AURA_REFRESH" .. KinkyDots)
						end
					end
				end
			end
		end
		
		-- Removed Aura Events
		if subEvent == "SPELL_AURA_REMOVED" then
			if UnitName("player") == source then
				-- Doom fell of a unit, remove unit from tracker.
				if spellID == 11672 then
					if #KinkyDots > 0 then
						for i=1,#KinkyDots do
							if KinkyDots[i].guid == destGUID and KinkyDots[i].spellID == spellID then tremove(KinkyDots, i) return true end
                            debug("SPELL_AURA_REMOVED" .. KinkyDots)
                        end
					end
				end				
				-- Did we get buffed?!
			--	for i=1,#hasteProcs do
			--		if spellID == hasteProcs[i] then hasteBuffs = hasteBuffs - 1 end
			--	end
			--	for i=1,#intellectProcs do
			--		if spellID == intellectProcs[i] then intBuffs = intBuffs - 1 end
			--	end
			end
		end
		
		-- Applied Aura Events
		if subEvent == "SPELL_AURA_APPLIED" then
			if UnitName("player") == source then
				-- Doom applied to a unit, add unit to tracker
				if spellID == 11672 then
					for i=1,#KinkyDots do if KinkyDots[i].guid == destGUID and KinkyDots[i].spellID == spellID then return false end end
					
					if UnitBuffID("player",23271) then
						table.insert(KinkyDots, {guid = destGUID, corPower = CorruptionPower(), cor_tick_every = cor_tick_every, spellID = spellID, toep = true})
                        debug("SPELL_AURA_APPLIED" .. KinkyDots)
                    else
						table.insert(KinkyDots, {guid = destGUID, corPower = CorruptionPower(), cor_tick_every = cor_tick_every, spellID = spellID, toep = false})
                        debug("SPELL_AURA_APPLIED" .. KinkyDots)
                    end
				end
								
				---- Did we get buffed?!
				--for i=1,#hasteProcs do
				--	if spellID == hasteProcs[i] then hasteBuffs = hasteBuffs + 1 end
				---end
				---for i=1,#intellectProcs do
				---	if spellID == intellectProcs[i] then intBuffs = intBuffs + 1 end
				---end
			end
		end
	end
end

local PlayerDebuff = {
--PlayerDebuff.Fear
--PlayerDebuff.Breakable
--PlayerDebuff.Root
--PlayerDebuff.Slow
    Fear = {
        642, -- Divine Shield
        11958, -- Ice Block
        5199, -- Cyclone
        10890, -- Psychic Scream
        5246, -- Intimidating Shout
        6358, -- Seduction
        5484, -- Howl of Terror
        17928, -- Howl of Terror rank 2
        5782, -- Fear
        6213, -- Fear 2
        6215, -- Fear 3
    },
    Breakable = {
        1499, -- Freezing Trap
        19503, -- Scattering Shot
        6358, -- Seduction
        6770, -- Sap
        118, -- Polymorph
        28271, -- Polymorph: Turtle
        28272, -- Polymorph: Pig
        16097, -- Hex
        2094, -- Blind
        2637, -- Hibernate
     },
    Root = {
        339, -- Entangling Roots,
        122, -- Frost Nova,
        16979, --Feral Charge - Bear
        715, -- Hamstring
    },
    Slow = {
        2974, -- Wing CLip
        5116, -- Concussive Shot
        2974, -- Wing Clip
        13809, -- Ice Trap
        116, -- Frostbolt
        120, -- Cone of Cold
        11113, -- Blast Wave
        15407, -- Mind Flay
        3408, -- Crippling Poison
        8056, -- Frost Shock
        2484, -- Earthbind Totem
        18223, -- Curse of Exhaustion
        1715, -- Hamstring
        12323, -- Piercing Howl
    }
}

local function Immunities()
    -- Twin Consorts (Immune while channeling Nuclear Inferno and Tidal Force)
if UnitChannelInfo("target") == GetSpellInfo(137531) or UnitChannelInfo("target") == GetSpellInfo(137491) or UnitCastingInfo("target") == GetSpellInfo(138763)
then end

local ImmuneList = {
    642, -- Divine Shield
    11958, -- Ice Block
    5199, --Cyclone
    710, -- Banish Rank 1
    18647, -- Banish Rank 2
}
local FireImmuneBosses = {
    12056, -- Barron Geddon
    11502, -- Ragnaros
    11583, -- Nefarian
    11983, -- Firemaw
    14601, -- Ebonroc
    11981, -- Flamegore
    13020, -- Vaelastrasz the Corrupt
    10184, -- Onyxia
}
end

local function FireImmuneBoss()
    if DMW.Player.Target ~= nil 
    and DMW.Player.Target.ValidEnemy 
    and DMW.Player.Target.Distance < 36
    and (DMW.Player.Target.Name == "Barron Geddon")
    or DMW.Player.Target.Name == "Ragnaros"
    or DMW.Player.Target.Name == "Nefarian" 
    or DMW.Player.Target.Name == "Firemaw"
    or DMW.Player.Target.Name == "Vaelastrasz the Corrupt"
    or DMW.Player.Target.Name == "Onyxia" then return true else return false end
end

local function PriorityUnits()

end

local function DamageModifiers()

end


local function equippedCheck(table)
    local count = 0
	for i=1,#table do if IsEquippedItem(table[i]) then count = count + 1 end end
	return count
end

local function SoloJumpRuns()
    if Pet and not Pet.Dead and Debuff.EnslaveDemon:Exist(Pet) then
       if Player.Combat then
          -- Fireball
          local name, subtext, texture, isToken, isActive, autoCastAllowed, fireballEnabled = GetPetActionInfo(5)

          if fireballEnabled then TogglePetAutocast(5) end
       else
          -- Rain of Fire
          local name, subtext, texture, isToken, isActive, autoCastAllowed, rofEnabled = GetPetActionInfo(4)

          if rofEnabled then TogglePetAutocast(4) end
       end


    end

end



local function Utility()
-- Racials
if Setting("Auto Racials") and Player.Combat and Target and Target.ValidEnemy and Target.TTD > 6 and Target:IsBoss() then
   -- BloodFury (Orcs)
   if Spell.BloodFury:Known() and Spell.BloodFury:IsReady() and Spell.BloodFury:Cast(Player) then return true end
   -- Berserking (Troll)
   if Spell.BerserkingTroll:Known() and Spell.BerserkingTroll:IsReady() and Spell.BerserkingTroll:Cast(Player) then return true end
   -- WIll of The Forsaken (Undead)
   -- Escape Artist (Gnome)
   -- Perception (Human)
   --20600
end
-- Use Demonic or Dark Rune --
if Setting("Mana Rune") ~= 1 and Target and Target.ValidEnemy and Target.TTD > 6 and Target:IsBoss() and HP > 60 then
    if Power <= Setting("Rune Mana %") and Player.Combat then
        if Setting("Mana Rune") == 2 and GetItemCount(12662) >= 1 and GetItemCooldown(12662) == 0 then
            name = GetItemInfo(12662)
            RunMacroText("/use " .. name)
            return true 
        elseif Setting("Mana Rune") == 3 and GetItemCount(20520) >= 1 and GetItemCooldown(20520) == 0 then
            name = GetItemInfo(20520)
            RunMacroText("/use " .. name)
            return true	
        end
    end
end	
-- Use best available Mana potion --
if Setting("Mana Potion") ~= 1 and CDs and Target and Target.ValidEnemy and Target.TTD >= 15 and Target:IsBoss() then
    if Power <= Setting("Potion Mana %") and Player.Combat then
        if Setting("Mana Potion") == 2 and GetItemCount(13444) >= 1 and GetItemCooldown(13444) == 0 then
            name = GetItemInfo(13444)
            RunMacroText("/use " .. name)
            return true 
        elseif Setting("Mana Potion") == 3 and GetItemCount(13443) >= 1 and GetItemCooldown(13443) == 0 then
            name = GetItemInfo(13443)
            RunMacroText("/use " .. name)
            return true
        elseif Setting("Mana Potion") == 4 and GetItemCount(18841) >= 1 and GetItemCooldown(18841) == 0 then 
            name = GetItemInfo(18841) 
            RunMacroText("/use " .. name) 
            return true
        end
    end
  end
end

local function Wand()
    if not Player.Moving and not DMW.Helpers.Queue.Spell and not IsAutoRepeatSpell(Spell.Shoot.SpellName) and (DMW.Time - WandTime) > 0.7 and (Target.Distance > 1 or not Setting("Auto Attack In Melee")) and
    (ManaPct < 10 or Spell.ShadowBolt:CD() > 2 or ((not Curse or not Spell[Curse]:Known() or Debuff[Curse]:Exist(Target) or Target.TTD < 10 or Target.CreatureType == "Totem") and 
    (not Setting("Immolate") or not Spell.Immolate:Known() or Debuff.Immolate:Exist(Target) or Target.TTD < 10 or Target.CreatureType == "Totem") and 
    (not Setting("Corruption") or not Spell.Corruption:Known() or Debuff.Corruption:Exist(Target) or Target.TTD < 7 or Target.CreatureType == "Totem") and
    (not Setting("Siphon Life") or not Spell.SiphonLife:Known() or Debuff.SiphonLife:Exist(Target) or Target.TTD < 10 or Target.CreatureType == "Totem") and
    (Setting("Shadow Bolt Mode") == 1 or not Spell.ShadowBolt:Known() or ManaPct < Setting("Shadow Bolt Mana") or Target.TTD < Spell.ShadowBolt:CastTime()) and
    (not Setting("Drain Life Filler") or not Spell.DrainLife:Known() or Player.HP > Setting("Drain Life Filler HP") or Target.CreatureType == "Mechanical" or (not Target.Player and Target.TTD < 3) or Target.Distance > Spell.DrainLife.MaxRange)))
    and Spell.Shoot:Cast(Target) then
        WandTime = DMW.Time
        return true
    end
end
--	if select(2,GetSpellAutocast(134477)) then
   -- DisableSpellAutocast(GetSpellInfo(134477))
--end
local function Defensive()
    if Setting("Healthstone") and Player.HP < Setting("Healthstone HP") and (DMW.Time - ItemUsage) > 0.2 and (Item.MajorHealthstone:Use(Player) or Item.GreaterHealthstone:Use(Player) or Item.Healthstone:Use(Player) or Item.LesserHealthstone:Use(Player) or Item.MinorHealthstone:Use(Player)) then
        ItemUsage = DMW.Time
        return true
    end

   -- if Setting("Death Coil") and Player.HP < Setting("Death COil HP") or Target and Target.IsBoss() and 

    if Setting("Sacrifice") and Player.HP < Setting ("Sacrifice HP") and Pet and not Pet.Dead  and (GetPetActionInfo(4) == GetSpellInfo(3716)) and Spell.Sacrifice:Cast(Player) then
        return true
    end
    if not Player.Casting and not Player.Moving and Setting("Drain Life") and Player.HP < Setting("Drain Life HP") and Target.CreatureType ~= "Mechanical" and Spell.DrainLife:Cast(Target) then
        return true
    end
    if Setting("Luffa") and Item.Luffa:Equipped() and (DMW.Time - ItemUsage) > 0.2 and Player:Dispel(Item.Luffa) and Item.Luffa:Use(Player) then
        ItemUsage = DMW.Time
        return true
    end
    if not Player.Casting and not Player.Moving and Setting("Health Funnel") and Pet and not Pet.Dead and Pet.HP < Setting("Health Funnel HP") and Target.TTD > 2 and Player.HP > 60 and Spell.HealthFunnel:Cast(Pet) then
        return true
    end
end

local function CreateHealthstone()
    if Spell.CreateHealthstoneMajor:Known() then
        if not Spell.CreateHealthstoneMajor:LastCast() and not Item.MajorHealthstone:InBag() and Spell.CreateHealthstoneMajor:Cast(Player) then
            return true
        end
    elseif Spell.CreateHealthstoneGreater:Known() then
        if not Spell.CreateHealthstoneGreater:LastCast() and not Item.GreaterHealthstone:InBag() and Spell.CreateHealthstoneGreater:Cast(Player) then
            return true
        end
    elseif Spell.CreateHealthstone:Known() then
        if not Spell.CreateHealthstone:LastCast() and not Item.Healthstone:InBag() and Spell.CreateHealthstone:Cast(Player) then
            return true
        end
    elseif Spell.CreateHealthstoneLesser:Known() then
        if not Spell.CreateHealthstoneLesser:LastCast() and not Item.LesserHealthstone:InBag() and Spell.CreateHealthstoneLesser:Cast(Player) then
            return true
        end
    elseif Spell.CreateHealthstoneMinor:Known() then
        if not Spell.CreateHealthstoneMinor:LastCast() and not Item.MinorHealthstone:InBag() and Spell.CreateHealthstoneMinor:Cast(Player) then
            return true
        end
    end
end

local function CreateSoulstone()
    if Spell.CreateSoulstoneMajor:Known() then
        if not Spell.CreateSoulstoneMajor:LastCast() and not Item.MajorSoulstone:InBag() and Spell.CreateSoulstoneMajor:Cast(Player) then
            return true
        end
    elseif Spell.CreateSoulstoneGreater:Known() then
        if not Spell.CreateSoulstoneGreater:LastCast() and not Item.GreaterSoulstone:InBag() and Spell.CreateSoulstoneGreater:Cast(Player) then
            return true
        end
    elseif Spell.CreateSoulstone:Known() then
        if not Spell.CreateSoulstone:LastCast() and not Item.Soulstone:InBag() and Spell.CreateSoulstone:Cast(Player) then
            return true
        end
    elseif Spell.CreateSoulstoneLesser:Known() then
        if not Spell.CreateSoulstoneLesser:LastCast() and not Item.LesserSoulstone:InBag() and Spell.CreateSoulstoneLesser:Cast(Player) then
            return true
        end
    elseif Spell.CreateSoulstoneMinor:Known() then
        if not Spell.CreateSoulstoneMinor:LastCast() and not Item.MinorSoulstone:InBag() and Spell.CreateSoulstoneMinor:Cast(Player) then
            return true
        end
    end
end

local function Dot_Leveling()
    if (Player.Level - Target.Level) > 30 and not Target:IsBoss() and Target.CreatureType ~= "Totem" and Setting("Corruption") then
        if (not Player.Moving or Talent.ImprovedCorruption.Rank == 5) and (not Spell.Corruption:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7) or not UnitIsUnit(Spell.Corruption.LastBotTarget, Target.Pointer)) and (Target.Facing or (Talent.ImprovedCorruption.Rank == 5 and DMW.Settings.profile.Enemy.AutoFace)) and not Debuff.Corruption:Exist(Target) and Spell.Corruption:Cast(Target) then
            return true
        end
        return true
    end
    if Setting("Siphon Life") and not Debuff.SiphonLife:Exist(Target) and Target.TTD > 10 and Target.CreatureType ~= "Totem" and Spell.SiphonLife:Cast(Target) then
       return true
    end
    if Curse and Target.CreatureType ~= "Totem" and Target.TTD > 10 and not Debuff[Curse]:Exist(Target) then
        if CDs and Target.TTD > 15 and Target.Distance <= Spell[Curse].MaxRange and Spell.AmplifyCurse:Cast(Player) then
            return true
        end
        if Spell[Curse]:Cast(Target) then
            return true
        end
    end
    if Setting("Corruption") and (not Player.Moving or Talent.ImprovedCorruption.Rank == 5) and (not Spell.Corruption:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7) or not UnitIsUnit(Spell.Corruption.LastBotTarget, Target.Pointer)) and Target.CreatureType ~= "Totem" and (Target.Facing or (Talent.ImprovedCorruption.Rank == 5 and DMW.Settings.profile.Enemy.AutoFace)) and not Debuff.Corruption:Exist(Target) and Target.TTD > 7 and Spell.Corruption:Cast(Target) then
       return true
    end
    if (Setting("Immolate") or Spell.ShadowBolt:CD() > 2) and not Player.Moving and (not Spell.Immolate:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7) or not UnitIsUnit(Spell.Immolate.LastBotTarget, Target.Pointer)) and Target.CreatureType ~= "Totem" and Target.Facing and not Debuff.Immolate:Exist(Target) and Target.TTD > 10 and Spell.Immolate:Cast(Target) then
        return true
    end
end


local function Dot_Raid()
    if Setting("Corruption")
    and (not Spell.Corruption:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7) 
    or not UnitIsUnit(Spell.Corruption.LastBotTarget, Target.Pointer)) and Target.CreatureType ~= "Totem" then    
        -- If corruption is not active, apply it. 
        --if not Debuff.Corruption:Exist(Target) and (not Spell.Corruption:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7)) and Target.TTD > Setting("Corruption TTD") and Spell.Corruption:Cast(Target) then
         --   debug("Corruption") 
        --    return true
       -- end
       --[[ if Setting("Corruption") and Target and Target.ValidEnemy and Target.TTD > 5 
        and Debuff.Corruption.Remain(Target) < Spell.Corruption.CastTime() + GCD and Spell.Corruption:Cast(Target) then 
            debug("Corruption < Cast Time)")
            return true
        end--]]
        if Setting("Corruption") and (not Player.Moving or Talent.ImprovedCorruption.Rank == 5) and (not Spell.Corruption:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7) or not UnitIsUnit(Spell.Corruption.LastBotTarget, Target.Pointer)) and Target.CreatureType ~= "Totem" and (Target.Facing or (Talent.ImprovedCorruption.Rank == 5 and DMW.Settings.profile.Enemy.AutoFace)) and not Debuff.Corruption:Exist(Target) and Target.TTD > 7 and Spell.Corruption:Cast(Target) then
           debug("Corruption") 
           return true
        end
        --if Target.IsBoss() and Target.TTD > Setting("Corruption TTD") and Debuff.Corruption.Remain() < Spell.Corruption.CastTime() and Spell.Corruption:Cast(Target) then 
        --    return true
        --end
    end
    if Setting("Siphon Life") and not Debuff.SiphonLife:Exist(Target) and Target.TTD > 10 and Target.CreatureType ~= "Totem" and Spell.SiphonLife:Cast(Target) then
        return true
    end
    if (Setting("Immolate") or Spell.ShadowBolt:CD() > 2) and not Player.Moving and (not Spell.Immolate:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7) or not UnitIsUnit(Spell.Immolate.LastBotTarget, Target.Pointer)) and Target.CreatureType ~= "Totem" and Target.Facing and not Debuff.Immolate:Exist(Target) and Target.TTD > 10 and Spell.Immolate:Cast(Target) then
        return true
    end
   -- if Setting("Corruption") and (not Player.Moving or Talent.ImprovedCorruption.Rank == 5) and (not Spell.Corruption:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7) or not UnitIsUnit(Spell.Corruption.LastBotTarget, Target.Pointer)) and Target.CreatureType ~= "Totem" and (Target.Facing or (Talent.ImprovedCorruption.Rank == 5 and DMW.Settings.profile.Enemy.AutoFace)) and not Debuff.Corruption:Exist(Target) and Target.TTD > 7 and Spell.Corruption:Cast(Target) then
   --     return true
    --end
end

local function MultiDot()
    if Setting("Cycle Siphon Life") and Setting("Siphon Life") and Debuff.SiphonLife:Count() < Setting("Multidot Limit") then
        for _, Unit in ipairs(Enemy30Y) do
            if not Debuff.SiphonLife:Exist(Unit) and Unit.TTD > 10 and Unit.CreatureType ~= "Totem" and Spell.SiphonLife:Cast(Unit) then
                return true
            end
        end
    end
    if Curse and Setting("Cycle Curse") and Debuff[Curse]:Count() < Setting("Multidot Limit") then
        for _, Unit in ipairs(Enemy30Y) do
            if not Debuff[Curse]:Exist(Unit) and Unit.TTD > 10 and Unit.CreatureType ~= "Totem" and Spell[Curse]:Cast(Unit) then
                return true
            end
        end
    end
    if Setting("Cycle Corruption") and Setting("Corruption") and (not Player.Moving or Talent.ImprovedCorruption.Rank == 5) and Debuff.Corruption:Count() < Setting("Multidot Limit") then
        for _, Unit in ipairs(Enemy30Y) do
            if (not Spell.Corruption:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7) or not UnitIsUnit(Spell.Corruption.LastBotTarget, Unit.Pointer)) and Unit.CreatureType ~= "Totem" and (Unit.Facing or (Talent.ImprovedCorruption.Rank == 5 and DMW.Settings.profile.Enemy.AutoFace)) and not Debuff.Corruption:Exist(Unit) and Unit.TTD > 7 and ((Setting("Multi Dot Corruption Rank 1") and Spell.Corruption:Cast(Unit, 1)) or Spell.Corruption:Cast(Unit)) then
                return true
            end
        end
    end
    if Setting("Immolate") and Setting("Cycle Immolate") and not Player.Moving and Debuff.Immolate:Count() < Setting("Multidot Limit") then
        for _, Unit in ipairs(Enemy30Y) do
            if (not Spell.Immolate:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7) or not UnitIsUnit(Spell.Immolate.LastBotTarget, Unit.Pointer)) and Unit.CreatureType ~= "Totem" and Unit.Facing and not Debuff.Immolate:Exist(Unit) and Unit.TTD > 10 and Spell.Immolate:Cast(Unit) then
                return true
            end
        end
    end
end

local function OoC()
   -- if not Player.Combat and #KinkyDots > 0 then KinkyDots = {} end
    if not Player.Casting then      
        -------------------------------------------------------------------------
        -------------------------------PET SUMMONS-------------------------------
        -------------------------------------------------------------------------
        if Setting("Fel Domination") and not Player.Moving and (not Pet or Pet.Dead) and not Buff.DemonSac:Exist(Player) and (ShardCount > 0 or not Pet and Setting("Imp When No Shards"))
        and Spell.FelDomination:Known() and Spell.FelDomination:IsReady() and Spell.FelDomination:Cast(Player) then 
           debug("Fel Domination")  
           return true
        end
        if Setting("Pet") ~= 1 and (not Player.Combat or Buff.FelDomination:Exist(Player)) then
            if (Spell.DemonicSac:Known() and not Buff.DemonSac:Exist(Player)) or not Spell.DemonicSac:Known() then
               if (not Pet or Pet.Dead) then
                 if Setting("Imp When No Shards") and ShardCount < 1 and not Player.Moving and not Spell.SummonImp:LastCast() and Spell.SummonImp:Cast(Player) then
                    debug("[Summoning]| Imp - No Shards")
                    return true
                 end
                  if Setting("Pet") == 2 and ShardCount > 0 and not Player.Moving and not Spell.SummonSuccubus:LastCast() and Spell.SummonSuccubus:Cast(Player) then
                    debug("[Summoning]| Succubus")
                    return true
                  elseif Setting("Pet") == 3 and ShardCount > 0 and not Player.Moving and not Spell.SummonVoidwalker:LastCast() and Spell.SummonVoidwalker:Cast(Player) then
                     debug("[Summoning]| Voidwalker")
                     return true
                  elseif Setting("Pet") == 4 and not Player.Moving and not Spell.SummonImp:LastCast() and Spell.SummonImp:Cast(Player) then
                    debug("[Summoning]| Imp")
                    return true
                  elseif Setting("Pet") == 5 and ShardCount > 0 and not Player.Moving and not Spell.SummonFelhunter:LastCast() and Spell.SummonFelhunter:Cast(Player) then
                     debug("[Summoning]| Felhunter")
                     return true
                  end
                else
                    if Setting("Demonic Sacrifice") and (not Setting("Imp When No Shards") or GetPetActionInfo(4) ~= GetSpellInfo(11763))
                    and not Debuff.EnslaveDemon:Exist(Pet) and Spell.DemonicSac:Cast(Player) then
                        debug("Demonic Sacrifice")
                        return true
                    end
               end
         end

        
        if Setting("Auto Target Quest Units") then if Player:AutoTargetQuest(30, true) then return true end end

        if Player.Combat and Setting("Auto Target") then if Player:AutoTarget(30, true) then return true end end  
    end
     
    if not Player.Combat then
        if Spell.DemonArmor:Known() then 
            if Setting("Auto Buff") and Buff.DemonArmor:Remain() < 300 and Spell.DemonArmor:Cast(Player) then debug("Buffing Demon Armor")  return true end
        elseif Spell.DemonSkin:Known() then
            if Setting("Auto Buff") and Buff.DemonSkin:Remain() < 300 and Spell.DemonSkin:Cast(Player) then debug("Buffing Demon Skin") return true end
        end
            
        if not Player.Moving and Setting("Create Healthstone") and ShardCount > 0 and CreateHealthstone() then debug("Creating Healthstone")  return true end
            
        if not Player.Moving and Setting("Create Soulstone") and ShardCount > 0 and CreateSoulstone() then debug("Creating Soulstone") return true end
            
        if Setting("Life Tap OOC") and Player.HP >= Setting("Life Tap HP") 
        and ManaPct <= Setting("Life Tap Mana") and Spell.LifeTap:Cast(Player) then debug("OOC Life Tap") return true end
        end
    end
end

------------------------------------------------
--LEVELING/SOLO ROTATION -----------------------
------------------------------------------------
local function Leveling_Rotation()
    if Player.Casting and Player.Casting == Spell.Fear.SpellName and NewTarget then
        TargetUnit(NewTarget.Pointer)
        DMW.Player.Target = NewTarget
        NewTarget = false
    end

    if Defensive() then return true end

    -- Rain of Fire
    if Setting("Rain of FIre") and not Player.Moving and Target.Distance >= Setting("RoF Distance") and ManaPct >= Setting("RoF Mana") 
    and Player.HP >= Setting("RoF HP") and select(2, Target:GetEnemies(10, Setting("RoF TTD"))) >= Setting("RoF Enemy Count") and Spell.RainOfFire:Cast(Target) then return true end

    if not Player.Casting then
        if Setting("Shadow Bolt Mode") ~= 1 and Buff.ShadowTrance:Exist(Player) and Buff.ShadowTrance:Remain(Player) < 2 and Player.PowerPct > Setting("Shadow Bolt Mana") and Spell.ShadowBolt:Cast(Target) then
            return true
        end
        if Target.Player and (Target.Class == "PRIEST" or Target.Class == "WARLOCK") and Setting("Shadow Ward") and Spell.ShadowWard:Cast(Player) then
            return true
        end 
        --Force refresh on fear
        if Setting("Corruption") and Debuff.Fear:Exist(Target) and (Spell.Fear:LastCast() or Spell.Fear:LastCast(2)) and Debuff.Corruption:Remain(Target) < Target.TTD and (not Player.Moving or Talent.ImprovedCorruption.Rank == 5) and Spell.Corruption:Cast(Target) then
            return true
        end
    end
    if not Player.Moving and not Target.Player and Setting("Drain Soul Snipe") and (not Setting("Stop DS At Max Shards") or ShardCount < Setting("Max Shards")) and (not Player.Casting or (Player.Casting ~= Spell.DrainSoul.SpellName and Player.Casting ~= Spell.Hellfire.SpellName and Player.Casting ~= Spell.RainOfFire.SpellName)) and Spell.DrainSoul:CD() < 0.2 and Debuff.Shadowburn:Count() == 0 then
        for _, Unit in ipairs(Enemy30Y) do
            if Unit.Facing and math.abs(Player.Level - Unit.Level) <= 10 and not Unit.Player and (Unit.TTD < 3 or Unit.HP < 8) and not Unit:IsBoss() and not UnitIsTapDenied(Unit.Pointer) then
                if Spell.DrainSoul:Cast(Unit) then
                    WandTime = DMW.Time
                    return true
                end
            end
        end
    end
    if Setting("Shadowburn") and ShardCount >= Setting("Max Shards") and (not Player.Casting or (Player.Casting ~= Spell.DrainSoul.SpellName and Player.Casting ~= Spell.Hellfire.SpellName and Player.Casting ~= Spell.RainOfFire.SpellName)) and Spell.Shadowburn:IsReady() then
        for _, Unit in ipairs(Enemy30Y) do
            if Unit.Facing and (Unit.TTD < Setting("Shadowburn TTD") or Unit.HP < Setting("Shadowburn HP")) and not Unit:IsBoss() and not UnitIsTapDenied(Unit.Pointer) then
                if Player.Casting then
                    SpellStopCasting()
                end
                if Spell.Shadowburn:Cast(Unit) then
                    return true
                end
            end
        end
    end
    if not Player.Casting then
        if not Player.Moving and Setting("Fear Bonus Mobs") and Spell.Fear:IsReady() and Debuff.Fear:Count() == 0 and (not Spell.Fear:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7)) then
            local CreatureType = Target.CreatureType
            if Enemy20YC > 1 and not Player.InGroup and not (CreatureType == "Undead" or CreatureType == "Mechanical" or CreatureType == "Totem") and Target.TTD > 3 and not Target:IsBoss() and
            (not Setting("Immolate") or not Spell.Immolate:Known() or Debuff.Immolate:Exist(Target) or Target.TTD < 10) and 
            (not Setting("Corruption") or not Spell.Corruption:Known() or Debuff.Corruption:Exist(Target) or Target.TTD < 7) and
            (not Setting("Siphon Life") or not Spell.SiphonLife:Known() or Debuff.SiphonLife:Exist(Target) or Target.TTD < 10) and 
            (not Curse or not Spell[Curse]:Known() or Debuff[Curse]:Exist(Target) or Target.TTD < 10 ) then                    
                for i, Unit in ipairs(Enemy20Y) do
                    if i > 1 and Unit.TTD > 3 and Spell.Fear:Cast(Target) then
                        NewTarget = Unit
                        return true
                    end
                end
            end
        end
        if Setting("Auto Pet Attack") and Pet and not Pet.Dead and not UnitIsUnit(Target.Pointer, "pettarget") and DMW.Time > (PetAttackTime + 1) then
            PetAttackTime = DMW.Time
            PetAttack()
        end
        if (not DMW.Player.Equipment[18] or (Target.Distance <= 1 and Setting("Auto Attack In Melee"))) and not IsCurrentSpell(Spell.Attack.SpellID) then
            StartAttack()
        end

        if Dot_Leveling() then return true end

        if MultiDot() then return true end

        if Setting("Life Tap") and Player.HP >= Setting("Life Tap HP") and (not Setting("Safe Life Tap") or (not Player:IsTanking() and not Debuff.LivingBomb:Exist(Player))) and Player.PowerPct <= Setting("Life Tap Mana") and not Spell.DarkPact:LastCast() and Spell.LifeTap:Cast(Player) then
            return true
        end
        if Pet and not Pet.Dead and Setting("Dark Pact") and Player.PowerPct <= Setting("Dark Pact Mana") and Pet:PowerPct() > Setting("Dark Pact Pet Mana") and not Spell.DarkPact:LastCast() and not Spell.LifeTap:LastCast() and Spell.DarkPact:Cast(Pet) then
            return true
        end
        if Setting("Fear Solo Farming") and not Player.Moving and Target.TTD > 3 and #DMW.Friends.Units < 2 and not (Target.CreatureType == "Undead" or Target.CreatureType == "Mechanical" or Target.CreatureType == "Totem") and (Setting("Shadow Bolt Mode") ~= 2 or Player.PowerPct < Setting("Shadow Bolt Mana") or Spell.ShadowBolt:LastCast() or (Spell.ShadowBolt:LastCast(2) and (Spell.LifeTap:LastCast() or Spell.DarkPact:LastCast()))) and Debuff.Fear:Count() == 0 and (not Spell.Fear:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7)) and Spell.Fear:Cast(Target) then 
            return true
        end
        if Setting("Shadow Bolt Mode") == 2 and Target.Facing and (not Player.Moving or Buff.ShadowTrance:Exist(Player)) and Player.PowerPct > Setting("Shadow Bolt Mana") and (Target.TTD > Spell.ShadowBolt:CastTime() or (Target.Distance > 5 and not DMW.Player.Equipment[18])) and Spell.ShadowBolt:Cast(Target) then
            return true
        end
        if Setting("Shadow Bolt Mode") == 3 and Target.Facing and Player.PowerPct > Setting("Shadow Bolt Mana") and Buff.ShadowTrance:Exist(Player) and Spell.ShadowBolt:Cast(Target) then
            return true
        end
        if Setting("Searing Pain") and Target.Facing and not Player.Moving and (Setting("Shadow Bolt Mode") ~= 2 or Spell.ShadowBolt:CD() > 2 or Target.TTD < Spell.ShadowBolt:CastTime()) and Spell.SearingPain:Cast(Target) then
            return true
        end
        if Setting("Drain Life Filler") and not Player.Moving and Player.HP <= Setting("Drain Life Filler HP") and Target.CreatureType ~= "Mechanical" and (Target.Player or Target.TTD > 3) and Spell.DrainLife:Cast(Target) then
            return true
        end
        if Setting("Wand") and DMW.Player.Equipment[18] and Target.Facing and Wand() then return true end
    end
end

------------------------------------------------
--RAID BURST ROTATION --------------------------
------------------------------------------------
local function Raid_BurstRotation()
    if Setting("Use Trinket") ~= 1 and equippedCheck(dmgTrinkets) >= 1 and not Player.Casting and CDs and Target and Target.ValidEnemy and Target.TTD > 10 then
        if Setting("Use Trinket") == 2 and ManaPct >= Setting("Trinket Mana %")
        and GetItemCount(18820) >= 1 and GetItemCooldown(18820) == 0  then 
         debug("Using TOEP") 
            name = GetItemInfo(18820)
            RunMacroText("/use " .. name)
            return true
        elseif Setting("Use Trinket") == 3 and ManaPct >= Setting("Trinket Mana %") and GetItemCount(19950) >= 1 and GetItemCooldown(19950) == 0  then 
         debug("Using ZHC") 
            name = GetItemInfo(19950)
            RunMacroText("/use " .. name)
            return true
        end
    end
end


------------------------------------------------
--RAID ROTATION --------------------------------
------------------------------------------------
local function Raid_Rotation()
    if Utility() then return true end
    if Defensive() then return true end

    ------------------------------------------------
    --AOE ROTATION ---------------------------------
    ------------------------------------------------

    -- Hellfire
    if Setting("Hellfire") and not Player.Moving and ManaPct >= Setting("Hellfire Mana") and Player.HP >= Setting("Hellfire HP")
    and select(2, Target:GetEnemies(10, Setting("Hellfire TTD"))) >= Setting("Hellfire Enemy Count") and Spell.Hellfire:Cast(Target) then return true end

    -- Rain of Fire
    if Setting("Rain of FIre") and not Player.Moving and Target.Distance >= Setting("RoF Distance") and ManaPct >= Setting("RoF Mana") 
    and Player.HP >= Setting("RoF HP") and select(2, Target:GetEnemies(10, Setting("RoF TTD"))) >= Setting("RoF Enemy Count") and Spell.RainOfFire:Cast(Target) then return true end

    ------------------------------------------------
    --Curse ----------------------------------------
    ------------------------------------------------
    if Curse and Target.CreatureType ~= "Totem" and Target.TTD > 10 and not Debuff[Curse]:Exist(Target) then
        if CDs and Target.TTD > 15 and Target.Distance <= Spell[Curse].MaxRange and Spell.AmplifyCurse:Cast(Player) then return true end
        if Spell[Curse]:Cast(Target) then return true end
    end

    ------------------------------------------------
    --On Use Trinket -------------------------------
    ------------------------------------------------
   --and Target.IsBoss()
    if Setting("Use Trinket") ~= 1 and equippedCheck(dmgTrinkets) >= 1 and not Player.Casting and CDs and Target and Target.ValidEnemy and Target.TTD > 10 then
       if Setting("Use Trinket") == 2 and ManaPct >= Setting("Trinket Mana %")
       and GetItemCount(18820) >= 1 and GetItemCooldown(18820) == 0  then 
        debug("Using TOEP") 
           name = GetItemInfo(18820)
           RunMacroText("/use " .. name)
           return true
       elseif Setting("Use Trinket") == 3 and ManaPct >= Setting("Trinket Mana %") and GetItemCount(19950) >= 1 and GetItemCooldown(19950) == 0  then 
        debug("Using ZHC") 
           name = GetItemInfo(19950)
           RunMacroText("/use " .. name)
           return true
       end
    end
    
    ------------------------------------------------
    -- Shadow Bolt (Queue While Casting) -----------
    ------------------------------------------------
    if Target and Target.ValidEnemy and Target.TTD > Spell.ShadowBolt:CastTime() + GCD then 
       ------------------------------------------------
       -- Shadow Bolt (Queue While Casting) -----------
       ------------------------------------------------
       if Setting("Shadow Bolt Mode") ~= 1 and not Setting("Searing Pain") and not Player.Moving and Target and Target.ValidEnemy and Target.TTD > Spell.ShadowBolt:CastTime() + GCD + 2
       and Debuff.Corruption:Exist(Target) and Debuff.Corruption:Remain(Target) > Spell.ShadowBolt:CastTime() + GCD + 1.5 and ManaPct > Setting("Shadow Bolt Mana") 
       and Spell.ShadowBolt:Cast(Target) then debug("Shadowbolt Always (Corruption > Cast Time)") return true end 

       ------------------------------------------------
       -- Searing Pain (Queue While Casting) ----------
       ------------------------------------------------
       if Setting("Searing Pain") and not Player.Moving and Target and Target.ValidEnemy and Target.TTD > Spell.SearingPain:CastTime() + GCD and Debuff.Corruption:Exist(Target) 
       and Debuff.Corruption:Remain(Target) > Spell.SearingPain:CastTime() + GCD + 1.5 and Spell.SearingPain:Cast(Target) then debug("Searing Pain Always (Corruption > Cast Time)") return true end 

    else
        if Setting("Searing Pain") and not FireImmuneBoss()
        and Target.Facing and not Player.Moving and (Setting("Shadow Bolt Mode") ~= 2 
        or Spell.ShadowBolt:CD() > 2 or Target.TTD < Spell.ShadowBolt:CastTime()) and Spell.SearingPain:Cast(Target) then
            debug("Searing Pain") 
            return true
        end
    end

    ------------------------------------------------
    -- Searing Pain (Queue While Casting) ----------
    ------------------------------------------------
    --[[if Setting("Searing Pain") and not Player.Moving and Target and Target.ValidEnemy and Target.TTD > Spell.SearingPain:CastTime() + GCD and Debuff.Corruption:Exist(Target) 
    and Debuff.Corruption:Remain(Target) > Spell.SearingPain:CastTime() + GCD + 1.5 and Spell.SearingPain:Cast(Target) then debug("Searing Pain Always (Corruption > Cast Time)") return true end --]]

    ------------------------------------------------
    -- Shadow Bolt (Shadow Trance) -----------------
    ------------------------------------------------
    if not Player.Casting then
  
     if Setting("Shadow Bolt Mode") ~= 1 and Buff.ShadowTrance:Exist(Player) and Buff.ShadowTrance:Remain(Player) < 2 and ManaPct > Setting("Shadow Bolt Mana") and Spell.ShadowBolt:Cast(Target) then
        debug("Shadowbolt Shadow Trance") 
        return true
     end
   

    ------------------------------------------------
    --Drain Soul Sniping ---------------------------
    ------------------------------------------------

    if not Player.Moving and not Target.Player and Setting("Drain Soul Snipe") and (not Setting("Stop DS At Max Shards") or ShardCount < Setting("Max Shards")) and (not Player.Casting or (Player.Casting ~= Spell.DrainSoul.SpellName and Player.Casting ~= Spell.Hellfire.SpellName and Player.Casting ~= Spell.RainOfFire.SpellName)) and Spell.DrainSoul:CD() < 0.2 and Debuff.Shadowburn:Count() == 0 then
        for _, Unit in ipairs(Enemy30Y) do
            if Unit.Facing and math.abs(Player.Level - Unit.Level) <= 10 and not Unit.Player and (Unit.TTD < 2 or Unit.HP < 6) and not Unit:IsBoss() and not UnitIsTapDenied(Unit.Pointer) then
                if Spell.DrainSoul:Cast(Unit) then
                    WandTime = DMW.Time
                    return true
                end
            end
        end
    end

    ------------------------------------------------
    --Target Dotting -------------------------------
    ------------------------------------------------

    if Dot_Raid() then return true end  

    ------------------------------------------------
    --Multi-Dotting --------------------------------
    ------------------------------------------------
    if MultiDot() then return true end

    ------------------------------------------------
    --Life Tap (Waiting for Corruption) ------------
    ------------------------------------------------
    if Setting("Life Tap") and Target and Target.ValidEnemy and Target.TTD > 5 and Player.HP >= Setting("Life Tap HP") 
    and (not Setting("Safe Life Tap") or (not Player:IsTanking() and not Debuff.LivingBomb:Exist(Player))) and ManaPct <= Setting("Life Tap Mana") 
    and Debuff.Corruption:Remain(Target) < Spell.ShadowBolt:CastTime() + GCD + Spell.Corruption:CastTime() and Spell.LifeTap:Cast(Player) then debug("Life Tap (Waiting)")  return true end
    
    ------------------------------------------------
    --Life Tap -------------------------------------
    ------------------------------------------------
    if Setting("Life Tap") and Player.HP >= Setting("Life Tap HP") 
    and (not Setting("Safe Life Tap") or (not Player:IsTanking() and not Debuff.LivingBomb:Exist(Player))) 
    and ManaPct <= Setting("Life Tap Mana") and not Spell.DarkPact:LastCast() and Spell.LifeTap:Cast(Player) then debug("Life Tap")  return true end
    --and Debuff.Corruption:Remain(Target) > Spell.ShadowBolt:CastTime() + GCD + Spell.Corruption:CastTime()
  
    ------------------------------------------------
    --Shadow Bolt (Always) -------------------------
    ------------------------------------------------
    if Setting("Shadow Bolt Mode") == 2 and Target.Facing and (not Player.Moving or Buff.ShadowTrance:Exist(Player)) 
    and ManaPct > Setting("Shadow Bolt Mana") and Target.TTD > Spell.ShadowBolt:CastTime() and Debuff.Corruption:Exist(Target) and Spell.ShadowBolt:Cast(Target) then rdebug("Shadowbolt Regular 1") return true end

    ------------------------------------------------
    --Shadow Bolt (Nightfall) ----------------------
    ------------------------------------------------

    if Setting("Shadow Bolt Mode") == 3 and Target.Facing and ManaPct > Setting("Shadow Bolt Mana") 
    and Buff.ShadowTrance:Exist(Player) and Spell.ShadowBolt:Cast(Target) then debug("Shadowbolt") return true end

    ------------------------------------------------
    --Shadowburn Modifiers -------------------------
    ------------------------------------------------
    if Setting("Shadowburn") and ShardCount >= Setting("Max Shards") and (not Player.Casting or (Player.Casting ~= Spell.DrainSoul.SpellName 
    and Player.Casting ~= Spell.Hellfire.SpellName and Player.Casting ~= Spell.RainOfFire.SpellName)) and Spell.Shadowburn:IsReady() and not Debuff.Shadowburn:Exist(Target) then      
        -- Shadowburn (Power Infusion)
        if Buff.PowerInfusion:Exist(Player) then Spell.Shadowburn:Cast(Unit) return true end
        -- Shadowburn (Damage Modifiers)
        --[[if Setting("Shadowburn Modifiers") ~= 1 then
           if Setting("Shadowburn Modifiers") == 2 then
              for i = 1, unitdebuffs do 
                Name = UnitDebuff(Target, i)
              
                

              end
            end

        end--]]
       --if Spell.Shadowburn:Cast(Unit) then return true end
    end
 end
    --if DMW.Player.Equipment[18] and Target.Facing and Wand() then return true end
end

function Warlock.Rotation()
    Locals()
    OoC()
    if Target and Target.ValidEnemy and Target.Distance < 40 then
        if Setting("Rotation") ~= 1 then 
            if Setting("Rotation") == 1 then 
                Raid_Rotation()
                return true 
            elseif Setting("Rotation") == 3 then 
                Leveling_Rotation()
                return true 
            end
           
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
eventFrame:RegisterEvent("CHAT_MSG_ADDON");
eventFrame:RegisterEvent("ENCOUNTER_START");
eventFrame:RegisterEvent("ENCOUNTER_END");

eventFrame:SetScript("OnEvent", function(self, event, ...)
	if(event == "COMBAT_LOG_EVENT_UNFILTERED" ) then
		CombatLogEvent(CombatLogGetCurrentEventInfo());
	elseif(event == "PLAYER_ENTERING_WORLD") then
		C_ChatInfo.RegisterAddonMessagePrefix("D4C") -- DBM
	elseif(event == "ENCOUNTER_START") then
		ENCOUNTER_START(encounterID, name, difficulty, size)
	elseif(event == "ENCOUNTER_END") then
		ENCOUNTER_END(encounterID, name, difficulty, size)
	end
end)
