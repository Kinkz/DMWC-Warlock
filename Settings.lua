local DMW = DMW
DMW.Rotations.WARLOCK = {}
local Warlock = DMW.Rotations.WARLOCK
local UI = DMW.UI

function Warlock.Settings()
    UI.HUD.Options = {
        [1] = {
            Curse = {
                [1] = {Text = "Curse |cFF00FF00Enabled", Tooltip = ""},
                [2] = {Text = "Curse |cffff0000Disabled", Tooltip = ""}
            }
        },
        [2] = {
            Pause = {
                [1] = {Text = "Curse |cFF00FF00Enabled", Tooltip = ""},
                [2] = {Text = "Curse |cffff0000Disabled", Tooltip = ""}
            }
        }
    }

  UI.AddHeader("Warlock .:|:. General")
    UI.AddDropdown("Rotation", nil, {"Disabled", "Raiding", "Leveling/Solo", "PvP", "Testing"}, 2, 1)
    UI.AddDropdown("Curse", nil, {"Disabled", "Curse of Agony", "Curse of Shadow", "Curse of the Elements", "Curse of Recklessness", "Curse of Weakness", "Curse of Tongues", "Curse of Doom"}, 2, 1)
    UI.AddDropdown("Shadow Bolt", "Select Shadow Bolt mode", {"Disabled", "Always", "Only Nightfall"}, 2)
    UI.AddRange("Shadow Bolt Mana", "Minimum mana pct to cast Shadow Bolt", 0, 100, 1, 35)
    UI.AddToggle("Searing Pain", "Use Searing Pain when Shadow Bolt is disabled or not castable", false)
    UI.AddToggle("Shadowburn", "Shadowburn execute on max shards", false, true)
    UI.AddToggle("Shadowburn Priority Units", "Cast Shadowburn on priority burn mobs (lava spawn, mages, etc)", false, true)
    UI.AddDropdown("Shadowburn Modifiers", nil, {"Disabled", "2 DMG Modifiers", "3 DMG Modifiers"}, 1, true)
    UI.AddRange("Shadowburn TTD", "TTD to use Shadowburn", 0, 15, 1, 3)
    UI.AddToggle("Life Tap", "Enables the use of life tap.", true)
    UI.AddToggle("Life Tap Full HP", "Life tap at full health.", true)
    UI.AddToggle("Life Tap OOC", "Activate Life Tap usage outside combat", true)
    UI.AddRange("Life Tap Mana", "Mana pct to use Life Tap", 0, 100, 1, 15)
    UI.AddRange("Life Tap HP", "Minimum player hp to use Life Tap", 0, 100, 1, 45)
    UI.AddToggle("Safe Life Tap", "Do not Life Tap if you have aggro", false, true)
    UI.AddToggle("Debug", "Enable printing of spells casting in chat for debug reasons. ", false)

 UI.AddHeader("Warlock .:|:. Pet ")   
    UI.AddDropdown("Pet", nil, {"Disabled", "Succubus", "Voidwalker", "Imp", "Felhunter"}, 1, true)
    UI.AddToggle("Imp When No Shards", "Summon Imp when you are out of soul shards.", true, 1) 
    UI.AddToggle("Fel Domination", "Auto cast Fel Domination for instant pet summons", true) 
    UI.AddToggle("Demonic Sacrifice", "Auto cast demonic sacrifice to get its passive buff", true)

 UI.AddHeader("Warlock .:|:. DPS")
    UI.AddDropdown("Use Trinket", "Select a trink you would like the rotation to auto use.", {"Disabled", "Talisman of Epheremal Power", "Zandalarian Hero Charm"}, 2, 1)
    UI.AddRange("Trinket Mana %", "Minimum mana before using damage trinket.", 5, 100, 1, 45, false, 1, 1)
    UI.AddDropdown("Mana Potion", "Select a mana potion to use during raid", {"Disabled", "Major Mana Potion", "Superior Mana Potion", "Combat Mana Potion"}, 2, 1)
    UI.AddRange("Potion Mana %", "Use the selected mana potion when mana reaches this percent.", 5, 100, 1, 15, false, 1, 1)
    UI.AddDropdown("Mana Rune", "Select a rune to use during raid", {"Disabled", "Demonic Rune", "Dark Rune"}, 2, 1)	
    UI.AddRange("Rune Mana %", "Mana percent to use the selected rune. ", 5, 100, 1, 15, false, 1, 1)

 UI.AddHeader("Warlock .:|:. Area of Effect")
    UI.AddToggle("Hellfire" ,"Toggle the use of the hellfire AoE ability", true)
    UI.AddRange("Hellfire Enemy Count", "Amount of enemies near you in order to hellfire.", 0, 10, 1, 3)
    UI.AddRange("Hellfire TTD", "The minimum time to die of the enemies to hellfire", 0, 15, 1, 2)
    UI.AddRange("Hellfire HP", "Minimum HP Percent to cast hellfire.", 0, 100, 1, 50)
    UI.AddRange("Hellfire Mana", "Minimum Mana Percent to cast hellfire.", 0, 100, 1, 30)
    UI.AddToggle("Rain of Fire" ,"Toggle the use of the Rain of Fire AoE ability at range.", true)
    UI.AddRange("RoF Mana", "Minimum Mana Percent to cast Rain of Fire.", 0, 100, 1, 30)
    UI.AddToggle("RoF Distance" ,"Distance from enemies in order to cast RoF.", 0, 30, 1, 15)
    UI.AddRange("RoF Enemy Count", "Amount of enemies near you in order to Rain of Fire.", 0, 10, 1, 4)
    UI.AddRange("RoF TTD", "The minimum time to die of the enemies to Rain of Fire", 0, 10, 1, 2)

UI.AddTab("Leveling")
 UI.AddHeader("Warlock .:|:. Leveling")
    UI.AddToggle("Wand", "Enable the usage of Wands", true, true)
    UI.AddToggle("Auto Attack In Melee", "Use auto attack (melee, low level)", false)
    UI.AddToggle("Drain Life Filler", "Use Drain Life as filler over wanding, use this for drain tanking", false)
    UI.AddRange("Drain Life Filler HP", "Player HP to start using drain life over wanding", 0, 100, 1, 80)
    UI.AddToggle("Dark Pact", nil, false)
    UI.AddToggle("Dark Pact OOC", "Activate Life Tap usage outside combat", false)
    UI.AddRange("Dark Pact Mana", "Mana pct to use Dark Pact", 0, 100, 1, 60)
    UI.AddRange("Dark Pact Pet Mana", "Pet mana pct to use Dark Pact", 0, 100, 1, 35)

UI.AddTab("Dots")
 UI.AddHeader("Warlock .:|:. Dots")
    UI.AddToggle("Amplify Curse", "Use Amplify Curse when using CDs", true)  
    UI.AddToggle("Cycle Curse", "Spread Curse to all enemies", true)  
    UI.AddRange("Multidot Limit", "Max number of units to dot", 1, 10, 1, 3)
    UI.AddToggle("Corruption", nil, true)
    UI.AddRange("Corruption TTD", "TTD to use corruption.", 0, 15, 1, 3)
    UI.AddToggle("Cycle Corruption", "Spread Corruption to all enemies", false)
    UI.AddToggle("Multi Dot Corruption Rank 1", "Use rank 1 corruption for multi dotting", false)
    UI.AddToggle("Immolate", nil, true)
    UI.AddToggle("Cycle Immolate", "Spread Immolate to all enemies", false)
    UI.AddToggle("Siphon Life", nil, true)
    UI.AddToggle("Cycle Siphon Life", "Spread Siphon Life to all enemies", false)

UI.AddTab("Defenses")
 UI.AddHeader("Warlock .:|:. Defenses")
    UI.AddToggle("Fear Bonus Mobs", "Auto fear non target enemies when solo", false)
    UI.AddToggle("Fear Solo Farming", "Auto fear target, useful for higher level chars using voidwalker", false)
    UI.AddToggle("Healthstone", nil, true)
    UI.AddRange("Healthstone HP", nil, 0, 100, 1, 35)
    UI.AddToggle("Death Coil", nil, true)
    UI.AddRange("Death Coil HP", nil, 0, 100, 1, 25)
    UI.AddToggle("Drain Life", nil, true)
    UI.AddRange("Drain Life HP", nil, 0, 100, 1, 25)
    UI.AddToggle("Health Funnel", "Activate Health Funnel, will only use if player HP above 60", false)
    UI.AddRange("Health Funnel HP", "Pet HP to cast Health Funnel", 0, 100, 1, 20)
    UI.AddToggle("Sacrifice", "Activate Sacrifice", true)
    UI.AddRange("Sacrifice HP", "Player HP to cast Sacrifice", 0, 100, 1, 20)
    UI.AddToggle("Luffa", "Auto use luffa trinket", true)
    UI.AddToggle("Shadow Ward", "Auto cast shadow ward when targeting priest or warlock players", true)

UI.AddTab("Utility")
 UI.AddHeader("Warlock .:|:. Utility")
    UI.AddToggle("Auto Racials", nil, true) 
    UI.AddRange("War Stomp Enemy Count", "Control max number of shards in bag", 0, 3, 1, 1)
    UI.AddToggle("Demon Armor", "Auto buff with Demon Skin/Armor", true)
    UI.AddToggle("Trash Buffs", "Auto buff yourself with Unending Breath/Detect Invisibility for Garr", false)
    UI.AddToggle("Create Healthstone", nil, true)
    UI.AddToggle("Create Soulstone", nil, true)
    UI.AddToggle("Soulstone Player", "Auto Soulstone on player outside instances", true)
    UI.AddToggle("Drain Soul Snipe", "Try to auto snipe enemies with drain soul, useful for shard farming or Improved Drain Soul talent", false)
    UI.AddToggle("Stop DS At Max Shards", "Stop using Drain Soul when max shards reached", false)
    UI.AddToggle("Auto Delete Shards", "Activate automatic deletion of shards from bags, set max below", false)
    UI.AddRange("Max Shards", "Control max number of shards in bag", 0, 30, 1, 4)
    UI.AddToggle("Auto Target", "Auto target units when in combat and target dead/missing", false)
    UI.AddToggle("Auto Target Quest Units", nil, false)
    --
    DMW.Helpers.Rotation.CastingCheck = false
end
