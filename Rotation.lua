local DMW = DMW
local Warlock = DMW.Rotations.WARLOCK
local Rotation = DMW.Helpers.Rotation
local Setting = DMW.Helpers.Rotation.Setting
local Player, Pet, Buff, Debuff, Spell, Target, Talent, Item, GCD, GCDRemain, CDs, HP, HUD, Enemy20Y, Enemy20YC, Enemy30Y, Enemy30YC, Friends40Y, Friends40YC, NewTarget, ShardCount, Curse, Pause, CTime, dmgTrinkets, ManaPct, Pause, Mouseover
local WandTime = GetTime()
local PetAttackTime = GetTime()
local ItemUsage = GetTime()
local Raid = IsInRaid()
local SendAddonMessage = C_ChatInfo.SendAddonMessage
local bossName = nil
local threatPercent = 0
local BossEngaged = false
local Trinket1 = GetInventoryItemID("player", 13)
local Trinket2 = GetInventoryItemID("player", 14)
local CorruptionPower = CorruptionPower

if not kinkydots then kinkydots = {} end
if not stopRotation then stopRotation = false end
if not dmgMods then dmgMods = 0 end

local trinketBuffs = {
   28779,
   27675,
   23271,
   24658 
}
local dmgBuffs = {
	{spellID = EP, check = true, hasBuff = false, endTime = nil},
	{spellID = REOS, check = true, hasBuff = false, endTime = nil},
	{spellID = UP, check = true, hasBuff = false, endTime = nil},
	{spellID = DIE, check = true, hasBuff = false, endTime = nil}
}

local dmgTrinkets = {
    18820, -- Talisman of Ephemeral Power
    19950, -- Zandalarian Hero Charm
    23046, -- The Restrained Essence of Sapphiron
    11832, -- The Burst of Knowledge
    21473, -- Eye of Moam
    22268, -- Draconic Infused Emblem
    19930  -- Mar'li's Eye
}
local dmgDebuff = {
    15258, -- Shadow Vulnerability (priest)
    17800, -- Shadow Vulnerability (Improved Shadow bolt)
    23605, -- Nightfall
    17937 -- Curse of Shadow
   }

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
    if HUD.Curse == 1 then
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
    HP = Player.HP
    Pet = DMW.Player.Pet
    CTimer = Player.CombatTime
    Buff = Player.Buffs
    Debuff = Player.Debuffs
    Spell = Player.Spells
    Talent = Player.Talents
    Item = Player.Items
    Target = Player.Target or false
    Mouseover = Player.Mouseover or false
    HUD = DMW.Settings.profile.HUD
    CDs = Player:CDs()
    GCD = Player:GCD()
    GCDRemain = Player:GCDRemain()
    --HardCC = Target:HardCC()
    --CC = Target:CCed()
    Enemy20Y, Enemy20YC = Player:GetEnemies(20)
    Enemy30Y, Enemy30YC = Player:GetEnemies(30)
    Friends40Y, Friends40YC = Player:GetFriends(40)
    ManaPct = Player.PowerPct
    Curse = GetCurse()
end

local function debug(message)
    if Setting("Debug") then print(tostring(message)) end
end

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

--https://classic.wowhead.com/spell=6346/fear-ward

-- Getting the Encounter Name
local function ENCOUNTER_START(encounterID, name, difficulty, size)
	name = bossName
    BossEngaged = true
    debug("ENCOUNTER START: ".. bossName)
end

-- Removing the Encounter Name
local function ENCOUNTER_END(encounterID, name, difficulty, size)
	bossName = nil
    BossEngaged = false
    debug("ENCOUNTER END")
end

local function dot_tracker()




    		if DMW.Player.Target ~= nil 
		and DMW.Player.Target.Distance < 50 then
			for i = 1, 16 do
				if UnitGUID("target") == nil then
					break		
				elseif DMW.Player.Target.ValidEnemy and UnitDebuff("target", i) == "Sunder Armor" then
					SunderedMobStacks[UnitGUID("target")] = select(3, UnitDebuff("target", i))
					break
				elseif DMW.Player.Target.ValidEnemy and UnitDebuff("target", i) ~= "Sunder Armor" then
					SunderedMobStacks[UnitGUID("target")] = 0
				end
			end
		end
end




local function PauseHotkey()
    keyDown,_ = GetKeyState("0x12")
    if keyDown then PauseRotKey = true else PauseRotKey = false end

    if PauseRotKey == true and GetTime() - someTime > toggleDelay then
        someTime = GetTIme()
        if PauseRotKey == true then
            PauseRotKey = false
            print("|cff347C2CSpecial Ability Hold: |cff79BAECDisabled|cffffffff", "Notice")
        else
            PauseRotKey = true
            print("|cff347C2CSpecial Ability Hold: |cffDC143CEnabled|cffffffff", "Notice")
        end
    end
end

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

--[[local function FireImmuneBoss()
    if Target ~= nil 
    and Target.ValidEnemy 
    and Target.Distance < 36
    and (Target.Name == "Barron Geddon")
    or Target.Name == "Ragnaros"
    or Target.Name == "Nefarian" 
    or Target.Name == "Firemaw"
    or Target.Name == "Vaelastrasz the Corrupt"
    or Target.Name == "Onyxia" then return true else return false end
end--]]

local function PriorityUnits()

end

local function isMindControledUnit(unit)
	if IsInRaid() then group = "raid"
		elseif IsInGroup() then group = "party"
	else return true end
		
	-- Stop dots on MCed raid members
	for i=1,GetNumGroupMembers() do
		local member = group..i
		if not UnitCanAttack("player",unit) then return true
		else
			if UnitName(unit) == member then return false end
		end
		return true
	end
end

local function smartRecast(spell,unit,rank)
    if rank == 0 then
        rank = nil
    end
    if (not Spell[spell]:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7) or 
        not UnitIsUnit(Spell[spell].LastBotTarget, unit.Pointer)) then 
            if Spell[spell]:Cast(unit,rank) then return true end
    end
end

local function equippedCheck(table)
    local count = 0
	for i=1,#table do if IsEquippedItem(table[i]) then count = count + 1 end end
    return count
end

local function UseTrinkets()
    if Setting("Trinket") ~= 1 and CDs
    and Target and Target.ValidEnemy and Target.TTD > Setting("Trinket TTD")
    and equippedCheck(dmgTrinkets) >= 1 
    and not Player.Casting
    then 
        if Setting("Trinket") == 2 and Player.PowerPct >= Setting("Trinket Mana %")
        and GetItemCount(18820) >= 1 and GetItemCooldown(18820) == 0  then 
            debug("Using TOEP") 
            name = GetItemInfo(18820)
            RunMacroText("/use " .. name)
            return true
        elseif Setting("Trinket") == 3 and Player.PowerPct >= Setting("Trinket Mana %") 
        and GetItemCount(19950) >= 1 and GetItemCooldown(19950) == 0  then 
            debug("Using ZHC") 
            name = GetItemInfo(19950)
            RunMacroText("/use " .. name)
            return true
        elseif Setting("Trinket") == 4 and Player.PowerPct >= Setting("Trinket Mana %") 
        and GetItemCount(23046) >= 1 and GetItemCooldown(23046) == 0  then 
            debug("Using REOS") 
            name = GetItemInfo(23046)
            RunMacroText("/use " .. name)
            return true
        elseif Setting("Trinket") == 5 and Player.PowerPct >= Setting("Trinket Mana %") 
        and GetItemCount(22268) >= 1 and GetItemCooldown(22268) == 0  then 
            debug("Using DIE") 
            name = GetItemInfo(22268)
            RunMacroText("/use " .. name)
            return true
        elseif Setting("Trinket") == 6 and Player.PowerPct >= Setting("Trinket Mana %") 
        and GetItemCount(11832) >= 1 and GetItemCooldown(11832) == 0  then 
            debug("Using Burst of Knowledge") 
            name = GetItemInfo(11832)
            RunMacroText("/use " .. name)
            return true
        elseif Setting("Trinket") == 7 and Player.PowerPct >= Setting("Trinket Mana %") 
        and GetItemCount(21473) >= 1 and GetItemCooldown(21473) == 0  then 
            debug("Using Eye of Moam") 
            name = GetItemInfo(21473)
            RunMacroText("/use " .. name)
            return true
        elseif Setting("Trinket") == 7 and Player.PowerPct >= Setting("Trinket Mana %") 
        and GetItemCount(19930) >= 1 and GetItemCooldown(19930) == 0  then 
            debug("Using Mar'li's Eye") 
            name = GetItemInfo(19930)
            RunMacroText("/use " .. name)
            return true
        end
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
    if (Player.Level - Target.Level) > 30 and Target.CreatureType ~= "Totem" and Setting("Corruption") then
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

-- PET MANAGEMENT 
local function PetManagement()
   if Setting("Auto Pet Attack")
      and HUD.PetAttack == 1 
      and not Setting("Pet Pullback at mend Pet HP") 
      and Pet and not Pet.Dead 
      and not UnitIsUnit(Target.Pointer, "pettarget") 
      then PetAttack() return true 
   elseif Setting("Auto Pet Attack")
      and Setting("Pet Pullback at mend Pet HP")
      and Pet and not Pet.Dead 
      --and not UnitIsUnit(Target.Pointer, "pettarget")
      and Pet.HP < Setting("Mend Pet HP") then
      PetPassiveMode()
   elseif Setting("Auto Pet Attack")
      and Setting("Pet Pullback at mend Pet HP")
	  and HUD.PetAttack == 1
      and Pet and not Pet.Dead 
      and not UnitIsUnit(Target.Pointer, "pettarget")
      and Pet.HP > Setting("Send Pet back in") then
      PetAttack() 
   end
end


local function Utility()
   -- Racials
   if Setting("Auto Racials") and Player.Combat and Target and Target.ValidEnemy and Target.TTD > 6 and Target:IsBoss() or CDs then

      -- BloodFury (Orcs)
      if Spell.BloodFury:Known() and Spell.BloodFury:IsReady() and Spell.BloodFury:Cast(Player) then return true end

      -- Berserking (Troll)
      if Spell.BerserkingTroll:Known() 
      and Spell.BerserkingTroll:IsReady() 
      and Target and Target.ValidEnemy
      and Player.Power > 400
      and Spell.BerserkingTroll:Cast(Player) then 
        debug("Berserking (Racial)")
        return true 
      end

      -- WIll of The Forsaken (Undead)
      if Spell.WillofTheForsaken:Known() 
      and Spell.WillofTheForsaken:IsReady()
      and Target and Target.ValidEnemy
      and Debuff.Feared:Exist(Player)
      and Spell.WillofTheForsaken:Cast(Player) then 
        debug("Will of The Forsaken (Racial)")
        return true 
    end
      -- Escape Artist (Gnome)
      -- Perception (Human)
      --20600
   end

   -- Major Rejuvenation Potion
   if Setting("Major Rejuvenation Potion") ~= 1 and CDs
   and Target and Target.ValidEnemy and Player.Combat 
   and Target.TTD > 6 and Target:IsBoss()
   and Item.RejuvenationPotion:IsReady()
   and HP > Setting("Rejuvenation HP %")
   and ManaPct <= Setting("Rejuvenation Mana %") then
      if Item.RejuvenationPotion:Use() then debug("Use Rejuvenation Potion") return true end
   end


   -- Use best available Mana potion --
   if Setting("Mana Potion") ~= 1 and CDs 
   and Target and Target.ValidEnemy 
   and Target.TTD >= 15 and Target:IsBoss() then
     if ManaPct <= Setting("Potion Mana %") and Player.Combat then
        if Setting("Mana Potion") == 2 and GetItemCount(13444) >= 1 and GetItemCooldown(13444) == 0 then
               debug("Use Mana Potion")
               name = GetItemInfo(13444)
               RunMacroText("/use " .. name)
               return true 
        elseif Setting("Mana Potion") == 3 and GetItemCount(13443) >= 1 and GetItemCooldown(13443) == 0 then
               debug("Use Mana Potion")
               name = GetItemInfo(13443)
               RunMacroText("/use " .. name)
               return true
        elseif Setting("Mana Potion") == 4 and GetItemCount(18841) >= 1 and GetItemCooldown(18841) == 0 then 
               debug("Use Mana Potion")
               name = GetItemInfo(18841) 
               RunMacroText("/use " .. name) 
               return true
           end
        end
     end

    -- Use Demonic or Dark Rune --
   if Setting("Mana Rune") ~= 1 and CDs
   and Target and Target.ValidEnemy 
   and Target.TTD > 6 and Target:IsBoss() 
   and HP > Setting("Rune HP %")
   and ManaPct <= Setting("Rune Mana %") 
   and Player.Combat then

    --Excess Demonic Runes
    if Setting("Excess Demonic Runes") 
    and Setting("Mana Rune") == 2 
    and GetItemCount(12662) >= Setting("Demonic Rune Count")
    and GetItemCooldown(12662) == 0 then
        debug("Using Demonic Rune because we got lots of em!")
        name = GetItemInfo(12662)
        RunMacroText("/use " .. name)
        return true 
    end   

    -- Demonic Runes
    if Setting("Mana Rune") == 2 
    and GetItemCount(12662) >= 1 
    and GetItemCooldown(12662) == 0 then
        debug("Using Demonic Rune")
        name = GetItemInfo(12662)
        RunMacroText("/use " .. name)
        return true 
    end

    -- Dark Runes
    if Setting("Mana Rune") == 3 and GetItemCount(20520) >= 1 and GetItemCooldown(20520) == 0 then
        debug("Using Dark Rune")
        name = GetItemInfo(20520)
        RunMacroText("/use " .. name)
        return true	
    end
end	   
    -- Night Dragon's Breath
    if Setting("Night Dragons Breath")
      and Target and Target.ValidEnemy 
      and Target.TTD > 6 and Target:IsBoss()
      and ManaPct <= Setting("Night Dragon Mana %")
      and Player.Combat then
        if GetItemCount(11952) >= 1 and GetItemCooldown(11952) == 0 then
           debug("Using Night Dragon's Breath")
           name = GetItemInfo(11952)
           RunMacroText("/use " .. name)
           return true	
        end
    end

    -- Swiftness Potion
    if Setting("Swiftness Potion") and Player.Combat
    and Target and Target.ValidEnemy and Target.Distance > 30
    and (Target.TTD > 6 and Target:IsBoss())
    or (Target.TTD > 4 and Target.Player)
    then
        if GetItemCount(2459) >= 1 and GetItemCooldown(2459) == 0 then
           debug("Using Swiftness Potion")
           name = GetItemInfo(2459)
           RunMacroText("/use " .. name)
           return true	
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

local function Defensive()
    ------------------------------------------------
    --LIMITED INVULNERABILITY POTION ---------------
    ------------------------------------------------
    if Setting("Limited Invulnerability Potion") 
    and IsInRaid() and Player.IsTanking()
    and Player.HP < Setting("LIP HP") then
        Item.LimitedInvulnerabilityPotion:Use(Player) 
        debug("Used Limited Invuln Potion") 
        ItemUsage = DMW.Time 
        return true 
    end

    ------------------------------------------------
    -- HEALTHSTONE ---------------------------------
    ------------------------------------------------
    if Setting("Healthstone") 
    and Player.HP < Setting("Healthstone HP") 
    and (DMW.Time - ItemUsage) > 0.2 
    and (Item.MajorHealthstone:Use(Player) 
    or Item.GreaterHealthstone:Use(Player) 
    or Item.Healthstone:Use(Player) 
    or Item.LesserHealthstone:Use(Player) 
    or Item.MinorHealthstone:Use(Player)) then
        debug("Used Healthstone")
        ItemUsage = DMW.Time
        return true
    end

    ------------------------------------------------
    -- HEALTH POTION -------------------------------
    ------------------------------------------------
    if Setting("Health Potion") 
    and HP < Setting("Health Potion HP") 
    and (DMW.Time - ItemUsage) > 0.2 
    and (Item.MajorHealingPotion:Use(Player) 
    or Item.SuperiorHealingPotion:Use(Player) 
    or Item.GreaterHealingPotion:Use(Player) 
    or Item.HealingPotion:Use(Player))
    and not Player.InInstance then
        debug("Used Health Potion")
        ItemUsage = DMW.Time
        return true
    end

    -- Death Coil
    if Setting("Death Coil Mode") ~= 1 and Setting("Death Coil Mode") == 2
    and Target and Target.ValidEnemy and Target.Facing
    and Player.HP < Setting("Death Coil HP") and Spell.DeathCoil:Known() and Spell.DeathCoil:IsReady() 
    and Spell.DeathCoil:Cast(Target) then 
        debug("Death Coil (Defemse Mode)") 
        return true 
    end 

    if Setting("Sacrifice") and Player.HP < Setting ("Sacrifice HP") and Pet and not Pet.Dead and Spell.Sacrifice:Cast(Player) then
        debug("Voidwalker Sacrifice") return true
    end

    if not Player.Casting and not Player.Moving and Setting("Drain Life") and Player.HP < Setting("Drain Life HP") and Target.CreatureType ~= "Mechanical" and Spell.DrainLife:Cast(Target) then
        debug("Drain Life") return true
    end
    if Setting("Luffa") and Item.Luffa:Equipped() and (DMW.Time - ItemUsage) > 0.2 and Player:Dispel(Item.Luffa) and Item.Luffa:Use(Player) then
        ItemUsage = DMW.Time
        return true
    end
    if not Player.Casting and not Player.Moving and Setting("Health Funnel") and Pet and not Pet.Dead and Pet.HP < Setting("Health Funnel HP") and Target.TTD > 2 and Player.HP > 60 and Spell.HealthFunnel:Cast(Pet) then
        return true
    end
end

------------------------------------------------
-- MULTI - DOT ROTATION ------------------------
------------------------------------------------
local function MultiDot()
    if Curse and Setting("Cycle Curse") and Debuff[Curse]:Count() < Setting("Multidot Limit") then
        for _, Unit in ipairs(Enemy30Y) do
            if Debuff.CurseOfDoom:Exist(Unit) then return false end
            if not Debuff[Curse]:Exist(Unit) and Unit.TTD > Setting("Curse TTD") 
            and Unit.CreatureType ~= "Totem" 
            and Spell[Curse]:Cast(Unit) then
                return true
            end
        end
    end
    if Setting("Cycle Siphon Life") and Setting("Siphon Life") and Debuff.SiphonLife:Count() < Setting("Multidot Limit") then
        for _, Unit in ipairs(Enemy30Y) do
            if not Debuff.SiphonLife:Exist(Unit) and Unit.TTD > 10 and Unit.CreatureType ~= "Totem" and Spell.SiphonLife:Cast(Unit) then
                return true
            end
        end
    end
    if Setting("Cycle Corruption") and Setting("Corruption") and (not Player.Moving or Talent.ImprovedCorruption.Rank == 5) and Debuff.Corruption:Count() < Setting("Multidot Limit") then
        for _, Unit in ipairs(Enemy30Y) do
            if (not Spell.Corruption:LastCast() or (DMW.Player.LastCast[1].SuccessTime 
            and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7) or not UnitIsUnit(Spell.Corruption.LastBotTarget, Unit.Pointer)) 
            and Unit.CreatureType ~= "Totem" 
            and (Unit.Facing or (Talent.ImprovedCorruption.Rank == 5 and DMW.Settings.profile.Enemy.AutoFace)) 
            and not Debuff.Corruption:Exist(Unit) 
            and Unit.TTD > 7 
            and ((Setting("Multi Dot Corruption Rank 1") 
            and Spell.Corruption:Cast(Unit, 1)) or Spell.Corruption:Cast(Unit)) then
                return true
            end
        end
    end
    if Setting("Immolate") and Setting("Cycle Immolate") and not Player.Moving and Debuff.Immolate:Count() < Setting("Multidot Limit") then
        for _, Unit in ipairs(Enemy30Y) do
            if (not Spell.Immolate:LastCast() or (DMW.Player.LastCast[1].SuccessTime 
            and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7) or not UnitIsUnit(Spell.Immolate.LastBotTarget, Unit.Pointer)) 
            and Unit.CreatureType ~= "Totem" 
            and Unit.Facing 
            and not Debuff.Immolate:Exist(Unit) 
            and Unit.TTD > 10 and Spell.Immolate:Cast(Unit) then
                return true
            end
        end
    end
end

------------------------------------------------
-- (FISKEE) LEVELING/SOLO ROTATION -------------
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
            if Unit.Facing and math.abs(Player.Level - Unit.Level) <= 10 and not Unit.Player and (Unit.TTD < 3 or Unit.HP < 8) and not UnitIsTapDenied(Unit.Pointer) then
                if Spell.DrainSoul:Cast(Unit) then
                    WandTime = DMW.Time
                    return true
                end
            end
        end
    end
    if Setting("Shadowburn") and ShardCount >= Setting("Max Shards") and (not Player.Casting or (Player.Casting ~= Spell.DrainSoul.SpellName and Player.Casting ~= Spell.Hellfire.SpellName and Player.Casting ~= Spell.RainOfFire.SpellName)) and Spell.Shadowburn:IsReady() then
        for _, Unit in ipairs(Enemy30Y) do
            if Unit.Facing and (Unit.TTD < Setting("Shadowburn TTD") or Unit.HP < Setting("Shadowburn HP")) and not UnitIsTapDenied(Unit.Pointer) then
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
            if Enemy20YC > 1 and not Player.InGroup and not (CreatureType == "Undead" or CreatureType == "Mechanical" or CreatureType == "Totem") and Target.TTD > 3 and
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
-- RAID - DOT ROTATION -------------------------
------------------------------------------------
local function Dot_Raid()
    -------------------------------------------------
    -- CORRUPTION - APPLY  --------------------------
    -------------------------------------------------
    if Setting("Corruption") and Target.CreatureType ~= "Totem" 
    and (not Spell.Corruption:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7) 
    or not UnitIsUnit(Spell.Corruption.LastBotTarget, Target.Pointer)) 
    and (Talent.ImprovedCorruption.Rank == 5 or not Player.Moving)  and ((Talent.ImprovedCorruption.Rank == 5  
    and Target.Facing and DMW.Settings.profile.Enemy.AutoFace)) then   
   
        ------------------------------------------------
        -- CORRUPTION - APPLY  -------------------------
        ------------------------------------------------
        if not Debuff.Corruption:Exist(Target) and Target.TTD > Setting("Corruption TTD") and Spell.Corruption:Cast(Target) then
           debug("Corruption (Apply)") 
           return true
        end

        ------------------------------------------------
        -- CORRUPTION < COR CAST TIME ------------------
        ------------------------------------------------
        if Debuff.Corruption:Remain(Target) < Spell.Corruption:CastTime() and Target.TTD > Setting("Corruption TTD") and Spell.Corruption:Cast(Target) then
           debug("Corruption (<Cor Cast Time)") 
           return true
        end
        ------------------------------------------------
        -- CORRUPTION [SNAPSHOTTING] (BOSSES) ----------
        ------------------------------------------------
       --[[ for i=1,5 do
           local id = UnitGUID(bossUnit)
           local bossUnit = "boss"..i
        
           if IsInRaid() and Debuff.Corruption:Exist(Target) then
              for i=1,#kinkydots do
                if kinkydots[i].guid == id then
                   if DMW.Player.Buffs.EphemeralPower:Exist(Player) then
                         if CorruptionPower() > kinkydots[i].corPower then
                            debug("Refreshing Corruption, Corruption Power > Corruption's power in tracker")
                            if Target.TTD > Setting("Corruption TTD") and Spell.Corruption:Cast(Target) then return true end
                         end
                    end
                end
            end
        end
    end--]]
    end

    if Setting("Siphon Life") and not Debuff.SiphonLife:Exist(Target) and Target.TTD > 10 and Target.CreatureType ~= "Totem" and Spell.SiphonLife:Cast(Target) then
        return true
    end

    if (Setting("Immolate") or Spell.ShadowBolt:CD() > 2) and not Player.Moving and (not Spell.Immolate:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7) or not UnitIsUnit(Spell.Immolate.LastBotTarget, Target.Pointer)) and Target.CreatureType ~= "Totem" and Target.Facing and not Debuff.Immolate:Exist(Target) and Target.TTD > 7 and Spell.Immolate:Cast(Target) then
        return true
    end
   -- if Setting("Corruption") and (not Player.Moving or Talent.ImprovedCorruption.Rank == 5) and (not Spell.Corruption:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7) or not UnitIsUnit(Spell.Corruption.LastBotTarget, Target.Pointer)) and Target.CreatureType ~= "Totem" and (Target.Facing or (Talent.ImprovedCorruption.Rank == 5 and DMW.Settings.profile.Enemy.AutoFace)) and not Debuff.Corruption:Exist(Target) and Target.TTD > 7 and Spell.Corruption:Cast(Target) then
   --     return true
    --end
end

------------------------------------------------
-- RAID ROTATION -------------------------------
------------------------------------------------
local function Raid_Rotation()
    if Player.Casting and Player.Casting == Spell.Fear.SpellName and NewTarget then
        TargetUnit(NewTarget.Pointer)
        DMW.Player.Target = NewTarget
        NewTarget = false
    end

    ------------------------------------------------
    -- UTILITY -------------------------------------
    ------------------------------------------------
    if Utility() then return true end

    ------------------------------------------------
    -- DEFENSIVES ----------------------------------
    ------------------------------------------------
    if Defensive() then return true end

    ------------------------------------------------
    -- SHADOWBURN (MAX SHARDS) ---------------------
    ------------------------------------------------
    if Setting("Shadowburn") and ShardCount >= Setting("Max Shards") 
    and (not Player.Casting or (Player.Casting ~= Spell.DrainSoul.SpellName 
    and Player.Casting ~= Spell.Hellfire.SpellName 
    and Player.Casting ~= Spell.RainOfFire.SpellName)) 
    and Spell.Shadowburn:IsReady() then
        for _, Unit in ipairs(Enemy30Y) do
            if Unit == nil then return false end 
            if not Unit:IsBoss() and Unit.Facing and not Target.Player
            and (Unit.TTD < Setting("Shadowburn TTD") or Unit.HP < Setting("Shadowburn HP")) 
            and not UnitIsTapDenied(Unit.Pointer) then
                   if Player.Casting then SpellStopCasting() end
                   if Spell.Shadowburn:Cast(Unit) then
                   return true
                end
            end
        end
    end

    ------------------------------------------------
    -- DRAIN SOUL (SHARDS) -------------------------
    ------------------------------------------------
    if Setting("Drain Soul Snipe") 
    and not Player.Moving 
    and not Target.Player 
    and (not Setting("Stop DS At Max Shards") or ShardCount < Setting("Max Shards")) 
    and (not Player.Casting or (Player.Casting ~= Spell.DrainSoul.SpellName and Player.Casting ~= Spell.Hellfire.SpellName 
    and Player.Casting ~= Spell.RainOfFire.SpellName)) 
    and Spell.DrainSoul:CD() < 0.2 
    and Debuff.Shadowburn:Count() == 0 then
       for _, Unit in ipairs(Enemy30Y) do
           if Unit == nil then return false end 
           if Unit.Facing and math.abs(Player.Level - Unit.Level) <= 10 
           and not Unit.Player 
           and (Unit.TTD < Setting("Drain Soul TTD") or Unit.HP < Setting("Drain Soul HP")) 
           and not Unit:IsBoss() 
           and not UnitIsTapDenied(Unit.Pointer) then
              if Spell.DrainSoul:Cast(Unit) then
                 WandTime = DMW.Time
                 return true
              end
            end
        end
    end

    ------------------------------------------------
    -- AOE ROTATION --------------------------------
    ------------------------------------------------
    -- Hellfire
    if Setting("Hellfire") 
    and not Player.Moving 
    and Player.Casting ~= Spell.Hellfire.SpellName 
    and Player.Casting ~= Spell.RainOfFire.SpellName
    and ManaPct >= Setting("Hellfire Mana") 
    and Player.HP >= Setting("Hellfire HP")
    and select(2, Target:GetEnemies(10, Setting("Hellfire TTD"))) >= Setting("Hellfire Enemy Count") 
    and Spell.Hellfire:Cast(Target) then 
        debug("Hellfire ".. "Enemies: " .. select(2, Target:GetEnemies(10, Setting("Hellfire TTD"))))
        return true 
    end

    -- Rain of Fire
    if Setting("Rain of FIre") 
    and not Player.Moving 
    and Player.Casting ~= Spell.Hellfire.SpellName 
    and Player.Casting ~= Spell.RainOfFire.SpellName
    and Target.Distance >= Setting("RoF Distance") 
    and ManaPct >= Setting("RoF Mana") 
    and Player.HP >= Setting("RoF HP") 
    and select(2, Target:GetEnemies(10, Setting("RoF TTD"))) >= Setting("RoF Enemy Count") 
    and Spell.RainOfFire:Cast(Target) then 
        debug("Rain of FIre ".. "Enemies: " .. select(2, Target:GetEnemies(10, Setting("RoF TTD"))))
        return true 
    end

    ------------------------------------------------
    -- Curse ---------------------------------------
    ------------------------------------------------
    if Curse and Target.CreatureType ~= "Totem" and Target.TTD > 10 and not Debuff[Curse]:Exist(Target) then
        if Debuff.CurseOfDoom:Exist(Target) then return false end
        if CDs and Target.TTD > 15 and Target.Distance <= Spell[Curse].MaxRange and Spell.AmplifyCurse:Cast(Player) then return true end
        if Spell[Curse]:Cast(Target) then 
            debug("Curse")
            return true 
        end
    end

    ------------------------------------------------
    -- On Use Trinket ------------------------------
    ------------------------------------------------
    if UseTrinkets() then return true end

    ------------------------------------------------
    -- Target Dotting ------------------------------
    ------------------------------------------------
    if Dot_Raid() then return true end 

    ------------------------------------------------
    -- Multi-Dotting -------------------------------
    ------------------------------------------------
    if MultiDot() then return true end 

    ------------------------------------------------
    -- Spell Queuing -------------------------------
    ------------------------------------------------
    if Setting("Shadow Bolt Mode") ~= 1 and Target.Facing 
    and Spell.ShadowBolt:IsReady()
    and (not Player.Moving or Buff.ShadowTrance:Exist(Player))
    and Player.PowerPct >= Setting("Shadow Bolt Mana")
    and Target.Name ~= "Zevrim Thornhoof" then
        if not IsInRaid() and Target.TTD > Spell.ShadowBolt:CastTime() + GCD + 0.5 then 
            if Spell.ShadowBolt:Cast(Target) then return true end
        elseif (Target:IsBoss() and Debuff.Corruption:Exist(Target) and Debuff.Corruption:Remain(Target) > Spell.ShadowBolt:CastTime() + GCD + Spell.Corruption:CastTime()) then
            if Spell.ShadowBolt:Cast(Target) then return true end
        end
       if Spell.ShadowBolt:Cast(Target) then return true end   
    end

    
-- (Target:IsBoss() and Debuff.Corruption:Exist(Target) and Debuff.Corruption:Remain(Target) > Spell.ShadowBolt:CastTime() + GCD + Spell.COrruption:CastTime())
    if Setting("Searing Pain") and Target.Facing
    and Spell.SearingPain:IsReady()
    and not Player.Moving 
    and (Setting("Shadow Bolt Mode") ~= 2 
    or Spell.ShadowBolt:CD() > 2 
    or Target.TTD < Spell.ShadowBolt:CastTime()) 
    and Spell.SearingPain:Cast(Target) then
        return true
    end

   if not Player.Casting then
   --[[ if Buff.EphemeralPower:Exist(Player) 
    and Buff.EphemeralPower:Remain(Player) <= 4 
    and not Spell.Corruption:LastCast() then
        debug("Refreshing Corruption, Corruption Power > Corruption's power in tracker")
        if Spell.Corruption:Cast(Target) then return true end
    end--]]
   --[[] for i=1,#kinkydots do
        if kinkydots[i].guid == id then
            if DMW.Player.Buffs.EphemeralPower:Exist(Player) then
                if CorruptionPower() > kinkydots[i].corPower or DMW.Player.Buffs.EphemeralPower:Remain(Player) < 5.0 then
                    debug("Refreshing Corruption, Corruption Power > Corruption's power in tracker")
        if Spell.Corruption:Cast(Target) then return true end
                end
            end
        end
    end--]]


    ------------------------------------------------
    -- Life Tap (Waiting for Corruption) -----------
    ------------------------------------------------
    --(not Setting("Safe Life Tap") or (not Player:IsTanking() and not Debuff.LivingBomb:Exist(Player)))
    if Setting("Life Tap") 
    and Target and Target.ValidEnemy 
    and not Debuff.LivingBomb:Exist(Player) 
    and not Debuff.BurningAdrenaline:Exist(Player)
    and Player.HP >= Setting("Life Tap HP")
    and ManaPct <= Setting("Life Tap Mana") then
       if Target:IsBoss() 
       and (Player.Power < 290 
       and (Debuff.Corruption:Exist(Target) and Debuff.Corruption:Remain(Target) <= 2) or Player.Power < 362)
       and Spell.LifeTap:Cast(Player) then 
          debug("Life Tap (Waiting for Corr)")
          return true 
       end
    end

    ------------------------------------------------
    -- Shadow Bolt (Shadow Trance) -----------------
    ------------------------------------------------
	if Setting("Shadow Bolt Mode") ~= 1 
    and Buff.ShadowTrance:Exist(Player) 
    and Buff.ShadowTrance:Remain(Player) < 3 
    and ManaPct > Setting("Shadow Bolt Mana") 
    and Spell.ShadowBolt:Cast(Target) then
       debug("Shadowbolt Shadow Trance") 
       return true
    end 
    
    ------------------------------------------------
    -- Life Tap ------------------------------------
    ------------------------------------------------
    if Setting("Life Tap") 
    and Player.HP >= Setting("Life Tap HP") 
    and (not Setting("Aggro Life Tap") or (not Player:IsTanking() and not Debuff.LivingBomb:Exist(Player)))
    and ManaPct <= Setting("Life Tap Mana") or Setting("Life Tap Full HP") and ManaPct > 97 and not Spell.DarkPact:LastCast() and Spell.LifeTap:Cast(Player) then return true end
  
    ------------------------------------------------
    -- Shadow Bolt (Always) ------------------------
    ------------------------------------------------
    if Setting("Shadow Bolt Mode") == 2 and Target.Facing and (not Player.Moving or Buff.ShadowTrance:Exist(Player)) 
    and ManaPct > Setting("Shadow Bolt Mana") and Target.TTD > Spell.ShadowBolt:CastTime() + GCD and Debuff.Corruption:Exist(Target) and Spell.ShadowBolt:Cast(Target) then rdebug("Shadowbolt Regular 1") return true end

    ------------------------------------------------
    -- Shadow Bolt (Nightfall) ----------------------
    ------------------------------------------------

    if Setting("Shadow Bolt Mode") == 3 and Target.Facing and ManaPct > Setting("Shadow Bolt Mana") 
    and Buff.ShadowTrance:Exist(Player) and Spell.ShadowBolt:Cast(Target) then debug("Shadowbolt") return true end

    ------------------------------------------------
    -- Shadowburn Modifiers ------------------------
    ------------------------------------------------
    if Setting("Shadowburn") and ShardCount >= Setting("Max Shards") and (not Player.Casting or (Player.Casting ~= Spell.DrainSoul.SpellName 
    and Player.Casting ~= Spell.Hellfire.SpellName and Player.Casting ~= Spell.RainOfFire.SpellName)) and Spell.Shadowburn:IsReady() and not Debuff.Shadowburn:Exist(Target) then      
        
        -- Power Infusion
        if Buff.PowerInfusion:Exist(Player) then Spell.Shadowburn:Cast(Target) debug("Shadowburn (Power Infusion)") return true end
        
        -- Damage Modifiers
        --[[if Setting("Shadowburn Modifiers") ~= 1 then
            if Setting("Shadowburn Modifiers") == 2 
            and DamageModifiers > 1 
            and Spell.Shadowburn:Cast(Target) then 
                debug("true dmg mod >1") 
                return true 
                
            elseif Setting("Shadowburn Modifiers") == 3 
            and DamageModifiers > 2 
            and Spell.Shadowburn:Cast(Target) then 
                debug("true dmg mods >3") 
                return true 
            end --]]
        end
    end
end
--end 

    --if DMW.Player.Equipment[18] and Target.Facing and Wand() then return true end

------------------------------------------------
-- OUT OF COMBAT - ROTATION --------------------
------------------------------------------------
local function OoC()
    ShardCount = Shards(Setting("Max Shards"))
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
             if (Spell.DemonicSac:Known() and not Buff.DemonSac:Exist(Player)) or not Spell.DemonicSac:Known() then --or not Spell.DemonicSac:Known()
                if (not Pet or Pet.Dead) then
                  if Setting("Imp When No Shards") and ShardCount < 1 
                  and GetPetActionInfo(4) ~= GetSpellInfo(11763) 
                  and not Player.Moving and not Spell.SummonImp:LastCast() and Spell.SummonImp:Cast(Player) then
                     debug("[Summoning]| Imp - No Shards")
                     return true
                  end
                   if Setting("Pet") == 2 and ShardCount > 0 
                   and not Player.Moving and (Spell.DemonicSac:Known() and not Buff.DemonSac:Exist(Player) or not Spell.DemonicSac:Known()) and not Spell.SummonSuccubus:LastCast() and Spell.SummonSuccubus:Cast(Player) then
                     debug("[Summoning]| Succubus")
                     return true
                   elseif Setting("Pet") == 3 and ShardCount > 0 
                   and not Player.Moving and (Spell.DemonicSac:Known() and not Buff.DemonSac:Exist(Player) or not Spell.DemonicSac:Known()) and not Spell.SummonVoidwalker:LastCast() and Spell.SummonVoidwalker:Cast(Player) then
                      debug("[Summoning]| Voidwalker")
                      return true
                   elseif Setting("Pet") == 4 and ShardCount < 1 
                   and GetPetActionInfo(4) ~= GetSpellInfo(11763) 
                   and not Player.Moving and (Spell.DemonicSac:Known() and not Buff.DemonSac:Exist(Player) or not Spell.DemonicSac:Known()) and not Spell.SummonImp:LastCast() and Spell.SummonImp:Cast(Player) then
                     debug("[Summoning]| Imp")
                     return true
                   elseif Setting("Pet") == 5 and ShardCount > 0 
                   and not Player.Moving and (Spell.DemonicSac:Known() and not Buff.DemonSac:Exist(Player) or not Spell.DemonicSac:Known()) and not Spell.SummonFelhunter:LastCast() and Spell.SummonFelhunter:Cast(Player) then
                      debug("[Summoning]| Felhunter")
                      return true
                   end
                end
          end
        if Setting("Auto Target Quest Units") then if Player:AutoTargetQuest(30, true) then return true end end
 
        if Player.Combat and Setting("Auto Target") then if Player:AutoTarget(30, true) then return true end end  
     end    
        if Setting("Demonic Sacrifice") 
        and Pet and not Pet.Dead
        and (not Setting("Imp When No Shards") or GetPetActionInfo(4) ~= GetSpellInfo(11763))
        and not Debuff.EnslaveDemon:Exist(Pet) and Spell.DemonicSac:Cast(Player) then
            debug("Demonic Sacrifice")
            return true
        end
     
        if Spell.DemonArmor:Known() then 
            if Setting("Auto Buff") and Buff.DemonArmor:Remain() < 300 and Spell.DemonArmor:Cast(Player) then debug("Buffing Demon Armor") return true end
        elseif Spell.DemonSkin:Known() then
            if Setting("Auto Buff") and Buff.DemonSkin:Remain() < 300 and Spell.DemonSkin:Cast(Player) then debug("Buffing Demon Skin") return true end
        end    
    ------------------------------------------------
    -- Out of Combat -------------------------------
    ------------------------------------------------ 
    if not Player.Combat then
         if not Player.Moving and Setting("Create Healthstone") and ShardCount > 1 and CreateHealthstone() then debug("Creating Healthstone") return true end
             
         if not Player.Moving and Setting("Create Soulstone") and ShardCount > 1 and CreateSoulstone() then debug("Creating Soulstone") return true end
             
         if Setting("Life Tap OOC") and Player.HP >= Setting("Life Tap HP") 
         and ManaPct <= Setting("Life Tap Mana") and Spell.LifeTap:Cast(Player) then debug("OOC Life Tap") return true end
         end
    end
end

function Warlock.Rotation() 
    if Setting("Pause Key") == 1 then 
        if IsLeftControlKeyDown() then return end
    elseif Setting("Pause Key") == 2 then 
        if IsLeftShiftKeyDown() then return end
    elseif Setting("Pause Key") == 3 then 
        if IsLeftAltKeyDown() then return end
    elseif Setting("Pause Key") == 4 then 
        if IsRightControlKeyDown() then return end
    elseif Setting("Pause Key") == 5 then 
        if IsRightShiftKeyDown() then return end
    elseif Setting("Pause Key") == 6 then 
        if IsRightAltKeyDown() then return end
    end

    ------------------------------------------------
    -- Locals Init ---------------------------------
    ------------------------------------------------ 
    Locals()
    ------------------------------------------------
    -- Pause Rotation ------------------------------
    ------------------------------------------------ 
    --PauseRotation() 

    ------------------------------------------------
    -- Out of Combat Init --------------------------
    ------------------------------------------------ 
    OoC()
    ------------------------------------------------
    -- Rotation Style ------------------------------
    ------------------------------------------------ 
    if Target and Target.ValidEnemy and Target.Distance < 40 and Player.Combat then
       if Setting("Rotation") ~= 1 then
          if Setting("Rotation") == 2 then 
             Raid_Rotation() 
             return true 
          elseif Setting("Rotation") == 3 then 
             Leveling_Rotation()
             return true 
          end
       end
    end      
end

local function CorruptionPower()
    -- Fetch our current stats.
    local crit, spd = GetSpellCritChance(6), GetSpellBonusDamage(6)
    local _,_,_,_,SM_rank,_ = GetTalentInfo(1,16) -- get rank of Shadow Mastery
    local _,_,_,_,DS_rank,_ = GetTalentInfo(2,13) -- get rank of Demonic Sacrifice
    local _,_,_,_,ISB_rank,_ = GetTalentInfo(3,1) -- get rank of Improved Shadow Bolt
    local ISB_List = {17800,17799,17798,17797,17794} -- spellIds for Improved Shadow Bolt Debuffs

    -- Calculate potential damage buffs.
    dmg_buff = 1

    -- Power Infusion
    if Buff.PowerInfusion:Exist(Player) then dmg_buff = dmg_buff * 1.05 end
       
    -- Shadow Mastery
    local SM_increase = SM_rank * .02
    dmg_buff = dmg_buff + (dmg_buff * SM_increase)
    
    -- Demonic Sacrifice (Succubus)
    if Buff.TouchOfShadow:Exist(Player) then dmg_buff = dmg_buff + (dmg_buff * .15) end
    
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
    bonus = 1 + crit / 100
    tick_every = 3
    
    ticks     = Round(18/tick_every)
    duration  = ticks*tick_every
    damage    = (137 + ticks * spd * 1) * bonus * dmg_buff
    dps       = Round(damage / duration)
    kinky_power = Round(dps / 100) / 10
    return kinky_power
    
end

local function CombatLogEvent(...)
    local timeStamp, subEvent, _, sourceID, sourceName, _, _, targetID = ...;
	local destGUID		= select(8, ...)
    local spellID		= select(12, ...)
    
    -- CLear dot table after each death/individual combat scenarios. 
    if SubEvent == "PLAYER_REGEN_ENABLED" or SubEvent == "PLAYER_REGEN_DISABLED" then if #kinkydots > 0 then kinkydots = {} end end
    if subEvent == "UNIT_DIED" then if #kinkydots > 0 then for i=1,#kinkydots do if kinkydots[i].guid == destGUID then tremove(kinkydots, i) return true end end end end

    -- Corruption was refreshed. 
	if subEvent == "SPELL_AURA_REFRESH" then
        if UnitName("player") == sourceName
        and (spellID == 172 or spellID == 11672 or spellID == 25311) then
		   if #kinkydots > 0 then
				for i=1,#kinkydots do
					if kinkydots[i].guid == destGUID and kinkydots[i].spellID == spellID then
						kinkydots[i].corPower = CorruptionPower()
                        kinkydots[i].spellID = spellID
                         debug("<DOT TRACKER>" .. " | Tracker Power: " .. kinkydots[i].corPower .. " | Current Power: " .. CorruptionPower())
                        --if DMW.Player.Buffs.EphemeralPower:Exist() then kinkydots[i].spellPower = true else kinkydots[i].spellPower = false end
                       -- debug("<DOT TRACKER>" .. "- : " .. kinkydots[i].corPower .. " | Current: " .. CorruptionPower())
					end
				end
			end
        end
    end

    -- Corruption was removed.
	if subEvent == "SPELL_AURA_REMOVED" then
		if UnitName("player") == sourceName then
			-- Doom fell of a unit, remove unit from tracker.
			if spellID == 172 or spellID == 11672 or spellID == 25311 or spellID == 6223 or spellID == 6222 then
                if #kinkydots > 0 then for i=1,#kinkydots do 
                   if kinkydots[i].guid == destGUID and kinkydots[i].spellID == spellID then tremove(kinkydots, i) return true end 
                end
            end
        end
       for i=1,#trinketBuffs do if spellID == trinketBuffs[i] then trinketBuffs = trinketBuffs - 1 end end
    end

    -- Corruption was applied. 
    if subEvent == "SPELL_AURA_APPLIED" then
        if UnitName("player") == sourceName then
          for i=1,#kinkydots do if kinkydots[i].guid == destGUID and kinkydots[i].spellID == spellID then return false end end

              table.insert(kinkydots, {guid = destGUID, corPower = CorruptionPower(), spellID = spellID})
               debug("<DOT TRACKER>" .. " | Tracker Power: " .. kinkydots[i].corPower .. " | Current Power: " .. CorruptionPower())
              --debug("<DOT TRACKER>" .. "- : " .. kinkydots[i].corPower .. " | Current: " .. CorruptionPower())
          end

          for i=1,#trinketBuffs do if spellID == trinketBuffs[i] then trinketBuffs = trinketBuffs + 1 end end
        end
    end
    if #kinkydots > 0 then 
       for i=1,#kinkydots do 
        debug("<DOT TRACKER>" .. " | Tracker Power: " .. kinkydots[i].corPower .. " | Current Power: " .. CorruptionPower())
       end 
    end
    -- debug("<DOT TRACKER>" .. " | Tracker Power: " .. kinkydots[i].corPower .. " | Current Power: " .. CorruptionPower() .. " | DMG Buffs: " .. dmgBuffs)
end

local kinkFrame = CreateFrame("Frame")
kinkFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
kinkFrame:RegisterEvent("COMBAT_LOG_EVENT")
kinkFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
kinkFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
kinkFrame:RegisterEvent("COMBAT_RATING_UPDATE")
kinkFrame:RegisterEvent("SPELL_POWER_CHANGED")
kinkFrame:RegisterEvent("UNIT_STATS")
--kinkFrame:RegisterEvent("UNIT_DIED")
kinkFrame:RegisterEvent("UNIT_AURA")
--kinkFrame:RegisterEvent("CHAT_MSG_ADDON")
kinkFrame:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
kinkFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
kinkFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
kinkFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

--kinkFrame:SetScript("OnUpdate",Warlock.Rotation())

kinkFrame:SetPropagateKeyboardInput(true)
kinkFrame:SetScript("OnKeyDown", testKeys);

kinkFrame:SetScript("OnEvent", function(self, event, ...)
	if(event == "COMBAT_LOG_EVENT_UNFILTERED" ) then
        CombatLogEvent(CombatLogGetCurrentEventInfo());
    elseif (event == "PLAYER_ENTERING_WORLD") then
       if not UnitAffectingCombat("player") and #kinkydots > 0 then kinkydots = {} end
    end
end)

--keyboardFrame:EnableKeyboard(true)

kinkFrame:Show()
	CombatLogEvent(CombatLogGetCurrentEventInfo());
	if(event == "PLAYER_ENTERING_WORLD") then
		C_ChatInfo.RegisterAddonMessagePrefix("D4C") -- DBM
	elseif(event == "ENCOUNTER_START") then
		ENCOUNTER_START(encounterID, name, difficulty, size)
	elseif(event == "ENCOUNTER_END") then
		ENCOUNTER_END(encounterID, name, difficulty, size)
	end
