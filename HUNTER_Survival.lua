local _,class = UnitClass("player")
if class~="HUNTER" then return end
local HarmonyMedia, _A, Harmony = ...
-- local _, class = UnitClass("player");
-- if class ~= "WARRIOR" then return end;
local DSL = function(api) return _A.DSL:Get(api) end
local hooksecurefunc =_A.hooksecurefunc
local Listener = _A.Listener
-- top of the CR
local player
local enemytreshhold = 3
local survival = {}
local immunebuffs = {
	"Deterrence",
	-- "Anti-Magic Shell",
	"Hand of Protection",
	-- "Spell Reflection",
	-- "Mass Spell Reflection",
	"Dematerialize",
	-- "Smoke Bomb",
	-- "Cloak of Shadows",
	"Ice Block",
	"Divine Shield"
}
local immunedebuffs = {
	"Cyclone",
	-- "Smoke Bomb"
}
local healerspecid = {
	-- [265]="Lock Affli",
	-- [266]="Lock Demono",
	-- [267]="Lock Destro",
	[105]="Druid Resto",
	-- [102]="Druid Balance",
	[270]="monk mistweaver",
	-- [65]="Paladin Holy",
	-- [66]="Paladin prot",
	-- [70]="Paladin retri",
	[257]="Priest Holy",
	[256]="Priest discipline",
	-- [258]="Priest shadow",
	[264]="Sham Resto",
	-- [262]="Sham Elem",
	-- [263]="Sham enh",
	-- [62]="Mage Arcane",
	-- [63]="Mage Fire",
	-- [64]="Mage Frost"
}
local darksimulacrumspecsBGS = {
	[265]="Lock Affli",
	[266]="Lock Demono",
	[267]="Lock Destro",
	-- [105]="Druid Resto",
	-- [102]="Druid Balance",
	-- [270]="monk mistweaver",
	-- [65]="Paladin Holy",
	-- [66]="Paladin prot",
	-- [70]="Paladin retri",
	-- [257]="Priest Holy",
	-- [256]="Priest discipline",
	[258]="Priest shadow",
	-- [264]="Sham Resto",
	[262]="Sham Elem",
	[263]="Sham enh",
	[62]="Mage Arcane",
	[63]="Mage Fire",
	[64]="Mage Frost"
}
local darksimulacrumspecsARENA = {
	[265]="Lock Affli",
	[266]="Lock Demono",
	[267]="Lock Destro",
	[105]="Druid Resto",
	[102]="Druid Balance",
	[270]="monk mistweaver",
	[65]="Paladin Holy",
	[66]="Paladin prot",
	[70]="Paladin retri",
	[257]="Priest Holy",
	[256]="Priest discipline",
	[258]="Priest shadow",
	[264]="Sham Resto",
	[262]="Sham Elem",
	[263]="Sham enh",
	[62]="Mage Arcane",
	[63]="Mage Fire",
	[64]="Mage Frost"
}
local hunterspecs = {
	[253]=true,
	[254]=true,
	[255]=true
}
local frozen_debuffs = {
	"Frost Nova",
	"Freeze",
	33395,
	122
}
local function manaregen()
	local regen = GetPowerRegen()
	return tonumber(regen)
end
local function power(unit)
	local intel2 = UnitPower(unit)
	if intel2 == 0
		or intel2 == nil
		then return 0
		else return intel2
	end
	intel2=nil
end
local function pull_location()
	local whereimi = string.lower(select(2, GetInstanceInfo()))
	return string.lower(select(2, GetInstanceInfo()))
end
local usableitems= { -- item slots
	13, --first trinket
	14 --second trinket
}

local function cditemRemains(itemid)
	local itempointerpoint;
	if itemid ~= nil
		then 
		if tonumber(itemid)~=nil
			then 
			if itemid<=23
				then itempointerpoint = (select(1, GetInventoryItemID("player", itemid)))
			end
			if itemid>23
				then itempointerpoint = itemid
			end
		end
	end
	local startcast1 = (select(2, GetItemCooldown(itempointerpoint)))
	local endcast1 = (select(1, GetItemCooldown(itempointerpoint)))
	local gettm1 = GetTime()
	if startcast1 + (endcast1 - gettm1) > 0 then
		return startcast1 + (endcast1 - gettm1)
		else
		return 0
	end
end
--
--

local cobraid = _A.Core:GetSpellID("Cobra Shot")
local steadyid = _A.Core:GetSpellID("Steady Shot") 
local ESid = _A.Core:GetSpellID("Explosive Shot") 
local gtID = _A.Core:GetSpellID("Glaive Toss") 
local baID = _A.Core:GetSpellID("Black Arrow") 
local amocID = _A.Core:GetSpellID("A Murder of Crows") 
local GUI = {
}
local exeOnLoad = function()
	local STARTSLOT = 1
	local STOPSLOT = 8
	_A.pressedbuttonat = 0
	_A.buttondelay = 0.6
	--
	_A.latency = (select(3, GetNetStats())) and ((select(3, GetNetStats()))/1000) or 0
	_A.interrupttreshhold = math.max(_A.latency, .1)
	Listener:Add("warrior_stuff", {"PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD"}, function(event)
		_A.pull_location = pull_location()
	end)
	_A.pull_location = _A.pull_location or pull_location()
	
	_A.casttimers = {}
	_A.Listener:Add("delaycasts_DK", "COMBAT_LOG_EVENT_UNFILTERED", function(event, _, subevent, _, guidsrc, _, _, _, guiddest, _, _, _, idd,_,_,amount)
		if guidsrc == UnitGUID("player") then
			if subevent == "SPELL_CAST_SUCCESS" then -- doesnt work with channeled spells
				_A.casttimers[idd] = _A.GetTime()
			end
		end
	end)
	function _A.castdelay(idd, delay)
		local spellid = idd and _A.Core:GetSpellID(idd)
		if delay == nil then return true end
		if _A.casttimers[spellid]==nil then return true end
		return (_A.GetTime() - _A.casttimers[spellid])>=delay
	end
	--
	hooksecurefunc("UseAction", function(...)
		local slot, target, clickType = ...
		local Type, id, subType, spellID
		-- print(slot)
		local player = Object("player")
		if slot==STARTSLOT then 
			_A.pressedbuttonat = 0
			if _A.DSL:Get("toggle")(_,"MasterToggle")~=true then
				_A.Interface:toggleToggle("mastertoggle", true)
				_A.print("ON")
				return true
			end
		end
		if slot==STOPSLOT then 
			-- TEST STUFF
			-- _A.print(string.lower(player.name)==string.lower("PfiZeR"))
			-- TEST STUFF
			-- print(player:stance())
			-- local target = Object("target")
			-- if target and target:exists() then print(target:creatureType()) end
			if _A.DSL:Get("toggle")(_,"MasterToggle")~=false then
				_A.Interface:toggleToggle("mastertoggle", false)
				_A.print("OFF")
				return true
			end
		end
		--
		if slot ~= STARTSLOT and slot ~= STOPSLOT and clickType ~= nil then
			Type, id, subType = _A.GetActionInfo(slot)
			if Type == "spell" or Type == "macro" -- remove macro?
				then
				_A.pressedbuttonat = _A.GetTime()
			end
		end
	end)
	
	function _A.unitfrozen(unit)
		if unit then 
			for _,debuffs in ipairs(frozen_debuffs) do
				if unit:DebuffAny(debuffs) then return true
				end
			end
		end
		return false
	end
	
	function _A.groundposition(unit)
		if unit then 
			local x,y,z=_A.ObjectPosition(unit.guid)
			local flags = bit.bor(0x100000, 0x10000, 0x100, 0x10, 0x1)
			local los, cx, cy, cz = _A.TraceLine(x, y, z+5, x, y, z-200, flags)
			if not los then
				return cx, cy, cz
			end
		end
	end
	function _A.groundpositiondetail(x,y,z)
		local flags = bit.bor(0x100000, 0x10000, 0x100, 0x10, 0x1)
		local los, cx, cy, cz = _A.TraceLine(x, y, z+5, x, y, z-200, flags)
		if not los then
			return cx, cy, cz
		end
	end
	
	_A.buttondelayfunc = function()
		if _A.GetTime() - _A.pressedbuttonat < _A.buttondelay then return true end
		return false
	end
	
	function _A.notimmune(unit) -- needs to be object
		if unit then 
			if unit:immune("all") then return false end
		end
		for _,v in ipairs(immunebuffs) do
			if unit:BuffAny(v) then return false end
		end
		for _,v in ipairs(immunedebuffs) do
			if unit:DebuffAny(v) then return false end
		end
		return true
	end
	--
	_A.clusteredenemy = function()
        local targets = {}
        local most, mostGuid = 0
        
        -- Pre-filter enemies to avoid redundant checks
        local validEnemies = {}
        for _, enemy in pairs(_A.OM:Get('Enemy')) do
			if enemy:InConeOf(player, 150) and 
				(_A.pull_location == "none" or enemy:combat()) and 
				not enemy:state("incapacitate || fear || disorient || charm || misc || sleep") and 
				not enemy:BuffAny("Divine Shield || Deterrence") and 
				_A.notimmune(enemy) and enemy:los() then
				table.insert(validEnemies, enemy)
			end
		end
        
        -- Count clusters
        for _, enemy in pairs(validEnemies) do
			local count = 0
			for _, enemy2 in pairs(validEnemies) do
				if enemy ~= enemy2 and enemy:rangefrom(enemy2) <= 8 then
					count = count + 1
				end
			end
			targets[enemy.guid] = count
		end
        
        -- Find the enemy with the most neighbors
        for guid, count in pairs(targets) do
			if count > most then
				most = count
				mostGuid = guid
			end
		end
		
        return most, mostGuid
	end
	--]]
	--[[
		_A.clusteredenemy = function() -- 8 yards
        local most, mostGuid = 0
        local positions = {}
        -- Pre-filter enemies and cache positions
        for _, enemy in pairs(_A.OM:Get('Enemy')) do
		if enemy:InConeOf(player, 150) and 
		(_A.pull_location == "none" or enemy:combat()) and 
		not enemy:state("incapacitate || fear || disorient || charm || misc || sleep") and 
		not enemy:BuffAny("Divine Shield || Deterrence") and 
		_A.notimmune(enemy) and enemy:los() then
		local x, y, z = _A.ObjectPosition(enemy.guid)
		-- local CR = _A.UnitCombatReach(enemy.guid)
		table.insert(positions, {guid = enemy.guid, x = x, y = y, z = z})
		positions[#positions+1] = {
		guid = enemy.guid,
		-- cr = CR,
		x = x, 
		y = y, 
		z = z
		}
		end
		end
        -- Calculate clusters using positions
        local count = {}
		if #positions>1 then
		for _,v1 in ipairs(positions) do
		for _,v2 in ipairs(positions) do
		if _A.GetDistanceBetweenPositions(v1.x, v1.y, v1.z, v2.x, v2.y, v2.z) <= 8 then
		count[v1.guid]=count[v1.guid] and count[v1.guid] + 1 or 1
		end
		end
		end
		end
        -- Find the best cluster
        for guid, cnt in pairs(count) do
		if cnt > most then
		most = cnt
		mostGuid = guid
		end
		end
        return most, mostGuid
		end
	--]]
	
	function _A.clickcast(unit, spell)
		local px,py,pz = _A.groundposition(unit)
		if px then
			_A.CallWowApi("CastSpellByName", spell)
			if player:SpellIsTargeting() then
				_A.ClickPosition(px, py, pz)
				_A.CallWowApi("SpellStopTargeting")
			end
		end
	end
	
	local function chanpercent(unit)
		local tempvar1, tempvar2 = select(5, UnitChannelInfo(unit))
		local givetime = GetTime()
		if unit == nil
			then 
			unit = "target"
		end	
		if UnitChannelInfo(unit)~=nil
			then local maxcasttime = abs(tempvar1-tempvar2)/1000
			local remainingcasttimeinsec = abs(givetime - (tempvar2/1000))
			local percentageofthis = (remainingcasttimeinsec * 100)/maxcasttime
			return percentageofthis
		end
		return 999
	end
	
	local function interruptable(unit)
		if unit == nil
			then unit = "target"
		end
		local intel5 = (select(9, UnitCastingInfo(unit)))
		local intel6 = (select(8, UnitChannelInfo(unit)))
		if intel5==false
			or intel6==false
			then return true
			else return false
		end
		return false
	end
	
	function _A.modifier_shift()
		local modkeyb = IsShiftKeyDown()
		if modkeyb then
			return true
			else
			return false
		end
	end
	
	local function castsecond(unit)
		local givetime = GetTime()
		local tempvar = select(6, UnitCastingInfo(unit))
		local timetimetime15687
		if unit == nil
			then 
			unit = "target"
		end
		if UnitCastingInfo(unit)~=nil
			then timetimetime15687 = abs(givetime - (tempvar/1000)) 
		end
		return timetimetime15687 or 999
	end
	
	local function channelinfo(unit)
		local channeling = _A.UnitChannelInfo(unit)
		return channeling and string.lower((select(1, channeling))) or " "
	end
	
	
	_A.FakeUnits:Add('lowestEnemyInSpellRange', function(num, spell)
		local tempTable = {}
		local target = Object("target")
		if target and target:enemy() and target:spellRange(spell) and target:InConeOf(player, 150) and  _A.notimmune(target)  and target:los() then
			return target and target.guid
		end
		for _, Obj in pairs(_A.OM:Get('Enemy')) do
			if Obj:spellRange(spell) and  Obj:InConeOf(player, 150) and  Obj:combat() and _A.notimmune(Obj)  and Obj:los() then
				tempTable[#tempTable+1] = {
					guid = Obj.guid,
					health = Obj:health(),
					isplayer = Obj.isplayer and 1 or 0
				}
			end
		end
		if #tempTable>1 then
			table.sort( tempTable, function(a,b) return (a.isplayer > b.isplayer) or (a.isplayer == b.isplayer and a.health < b.health) end )
		end
		if #tempTable>=1 then
			return tempTable[num] and tempTable[num].guid
		end
	end)
	
	_A.FakeUnits:Add('lowestEnemyInSpellRangeNOTAR', function(num, spell)
		local tempTable = {}
		for _, Obj in pairs(_A.OM:Get('Enemy')) do
			if Obj:spellRange(spell) and  Obj:InConeOf(player, 150) and Obj:combat() and _A.notimmune(Obj)  and Obj:los() then
				tempTable[#tempTable+1] = {
					guid = Obj.guid,
					health = Obj:health(),
					isplayer = Obj.isplayer and 1 or 0
				}
			end
		end
		if #tempTable>1 then
			table.sort( tempTable, function(a,b) return (a.isplayer > b.isplayer) or (a.isplayer == b.isplayer and a.health < b.health) end )
		end
		if #tempTable>=1 then
			return tempTable[num] and tempTable[num].guid
		end
		local target = Object("target")
		if target and target:enemy() and target:spellRange(spell) and target:InConeOf(player, 150) and  _A.notimmune(target)  and target:los() then
			return target and target.guid
		end
	end)
	
	_A.FakeUnits:Add('highestEnemyInSpellRangeNOTAR', function(num, spell)
		local tempTable = {}
		for _, Obj in pairs(_A.OM:Get('Enemy')) do
			if Obj:spellRange(spell) and  Obj:InConeOf(player, 150) and Obj:combat() and _A.notimmune(Obj)  and Obj:los() then
				tempTable[#tempTable+1] = {
					guid = Obj.guid,
					health = Obj:HealthActual(),
					isplayer = Obj.isplayer and 1 or 0
				}
			end
		end
		if #tempTable>1 then
			table.sort( tempTable, function(a,b) return (a.isplayer > b.isplayer) or (a.isplayer == b.isplayer and a.health > b.health) end )
		end
		if #tempTable>=1 then
			return tempTable[num] and tempTable[num].guid
		end
		local target = Object("target")
		if target and target:enemy() and target:spellRange(spell) and target:InConeOf(player, 150) and  _A.notimmune(target)  and target:los() then
			return target and target.guid
		end
	end)
	
	_A.DSL:Register('caninterrupt', function(unit)
		return interruptable(unit)
	end)
	
	_A.DSL:Register('chanpercent', function(unit)
		return chanpercent(unit)
	end)
	
	_A.DSL:Register('castsecond', function(unit)
		return castsecond(unit)
	end)
	
	_A.DSL:Register('channame', function(unit)
		return channelinfo(unit)
	end)
	
	
	_A.castchecktbl = {}
	_A.Listener:Add("steadycasting", "COMBAT_LOG_EVENT_UNFILTERED", function(event, _, subevent, _, guidsrc, _, _, _, guiddest, _, _, _, idd)
		if guidsrc == UnitGUID("player") then
			if idd == cobraid or idd == steadyid then
				-- print(subevent.." "..idd)
				if subevent == "SPELL_CAST_START" then
					_A.castchecktbl[idd] = true
				end
				if subevent == "SPELL_CAST_SUCCESS" or subevent == "SPELL_CAST_FAILED" then
					_A.castchecktbl[idd] = false
				end
			end
		end
	end)
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	--=========================== SPELL CHECKS
	_A.lowpriocheck = function(spellid)
		-- Avoid focus capping
		-- if player:focus() >= (player:FocusMax() - 5) then return true end
		
		-- Helper to compute required focus with time-based regeneration
		local function required_focus(spell, elapsed)
			-- if not player:spellknown(spell) then return 0 end
			local cd = player:SpellCooldown(spell) -- Cooldown remaining
			local regen = manaregen() * math.max(0, cd - elapsed) -- Regen focus during cooldown after elapsed time
			return -player:spellcost(spell) + regen
		end
		
		-- Define abilities with cooldowns and conditions
		local spells = {
			{ name = "Explosive Shot", ready = true },
			{ name = "Glaive Toss", ready = player:talent("Glaive Toss") },
			{ name = "Black Arrow", ready = _A.IsSpellKnown(3674) },
			{ name = "A Murder of Crows", ready = player:talent("A Murder of Crows") }
		}
		
		-- Sort spells by cooldown (shortest first)
		table.sort(spells, function(a, b)
			return player:SpellCooldown(a.name) < player:SpellCooldown(b.name)
		end)
		
		-- Track elapsed time and current focus
		local time_elapsed = 0
		local current_focus = player:focus() - player:spellcost(spellid)
		
		-- Simulate focus pooling without loops (nested conditions)
		local focus_cost, cooldown
		
		-- First spell
		if spells[1].ready then
			cooldown = player:SpellCooldown(spells[1].name)
			focus_cost = required_focus(spells[1].name, time_elapsed)
			if current_focus < -focus_cost then return false end
			current_focus = current_focus + focus_cost
			time_elapsed = cooldown -- Update elapsed time
		end
		
		-- Second spell
		if spells[2].ready then
			cooldown = player:SpellCooldown(spells[2].name)
			focus_cost = required_focus(spells[2].name, time_elapsed)
			if current_focus < -focus_cost then return false end
			current_focus = current_focus + focus_cost
			time_elapsed = cooldown -- Update elapsed time
		end
		
		-- Third spell
		if spells[3].ready then
			cooldown = player:SpellCooldown(spells[3].name)
			focus_cost = required_focus(spells[3].name, time_elapsed)
			if current_focus < -focus_cost then return false end
			current_focus = current_focus + focus_cost
			time_elapsed = cooldown -- Update elapsed time
		end
		
		-- Fourth spell
		if spells[4].ready then
			cooldown = player:SpellCooldown(spells[4].name)
			focus_cost = required_focus(spells[4].name, time_elapsed)
			if current_focus < -focus_cost then return false end
			current_focus = current_focus + focus_cost
			time_elapsed = cooldown -- Update elapsed time
		end
		
		-- If all focus checks pass, Arcane Shot can be cast
		return true
	end
	------------------------------------------------------------------
	------------------------------------------------------------------
	------------------------------------------------------------------
	_A.EScheck = function()
		-- Avoid focus capping
		-- if player:focus() >= (player:FocusMax() - 5) then return true end
		if player:buff("Lock and Load") then return true end
		
		-- Helper to compute required focus with time-based regeneration
		local function required_focus(spell, elapsed)
			-- if not player:spellknown(spell) then return 0 end
			local cd = player:SpellCooldown(spell) -- Cooldown remaining
			local regen = manaregen() * math.max(0, cd - elapsed) -- Regen focus during cooldown after elapsed time
			return -player:spellcost(spell) + regen
		end
		
		-- Define abilities with cooldowns and conditions
		local spells = {
			{ name = "Black Arrow", ready = _A.IsSpellKnown(3674) },
			{ name = "A Murder of Crows", ready = player:talent("A Murder of Crows") }
		}
		
		-- Sort spells by cooldown (shortest first)
		table.sort(spells, function(a, b)
			return player:SpellCooldown(a.name) < player:SpellCooldown(b.name)
		end)
		
		-- Track elapsed time and current focus
		local time_elapsed = 0
		local current_focus = player:focus() - player:spellcost("Explosive Shot")
		
		-- Simulate focus pooling without loops (nested conditions)
		local focus_cost, cooldown
		
		-- First spell
		if spells[1].ready then
			cooldown = player:SpellCooldown(spells[1].name)
			focus_cost = required_focus(spells[1].name, time_elapsed)
			if current_focus < -focus_cost then return false end
			current_focus = current_focus + focus_cost
			time_elapsed = cooldown -- Update elapsed time
		end
		
		-- Second spell
		if spells[2].ready then
			cooldown = player:SpellCooldown(spells[2].name)
			focus_cost = required_focus(spells[2].name, time_elapsed)
			if current_focus < -focus_cost then return false end
			current_focus = current_focus + focus_cost
			time_elapsed = cooldown -- Update elapsed time
		end
		
		-- If all focus checks pass, Arcane Shot can be cast
		return true
	end
	------------------------------------------------------------------
	------------------------------------------------------------------
	------------------------------------------------------------------
	_A.BAcheck = function()
		-- Avoid focus capping
		-- if player:focus() >= (player:FocusMax() - 5) then return true end
		-- Check if spell exists
		if not _A.IsSpellKnown(3674) then return false end
		-- Helper to compute required focus with time-based regeneration
		local function required_focus(spell, elapsed)
			-- if not player:spellknown(spell) then return 0 end
			local cd = player:SpellCooldown(spell) -- Cooldown remaining
			local regen = manaregen() * math.max(0, cd - elapsed) -- Regen focus during cooldown after elapsed time
			return -player:spellcost(spell) + regen
		end
		
		-- Define abilities with cooldowns and conditions
		local spells = {
			{ name = "A Murder of Crows", ready = player:talent("A Murder of Crows") }
		}
		
		-- Sort spells by cooldown (shortest first)
		table.sort(spells, function(a, b)
			return player:SpellCooldown(a.name) < player:SpellCooldown(b.name)
		end)
		
		
		-- Track elapsed time and current focus
		local time_elapsed = 0
		local current_focus = player:focus() - player:spellcost("Black Arrow")
		
		-- Simulate focus pooling without loops (nested conditions)
		local focus_cost, cooldown
		
		-- First spell
		if spells[1].ready then
			cooldown = player:SpellCooldown(spells[1].name)
			focus_cost = required_focus(spells[1].name, time_elapsed)
			if current_focus < -focus_cost then return false end
			current_focus = current_focus + focus_cost
			time_elapsed = cooldown -- Update elapsed time
		end
		-- If all focus checks pass, Arcane Shot can be cast
		return true
	end
	------------------------------------------------------------------
	------------------------------------------------------------------
	------------------------------------------------------------------
	_A.CobraCheck = function() -- we only want to cast Cobra Shot if not enough ressources by the time important cds come up (Idk if this is necessary just yet)
		-- if not _A.EScheck() then return true end
		local ct = player:level()<81 and player:SpellCasttime("Steady Shot") or player:SpellCasttime("Cobra Shot")
		if player:focus()+((player:spellcooldown("Explosive Shot"))*manaregen())<player:spellcost("Explosive Shot") then return true end
		-- print(ct<=player:spellcooldown("Explosive Shot"))
		return ct<=player:spellcooldown("Explosive Shot")
	end
	-------------------------------------------------------
	-------------------------------------------------------
	-------------------------------------------------------
	-------------------------------------------------------
	-------------------------------------------------------
	------------------------------------------------------- PET
	------------------------------------------------------- ENGINE
	-------------------------------------------------------
	-------------------------------------------------------
	-------------------------------------------------------
	-------------------------------------------------------
	-------------------------------------------------------
	_A.FakeUnits:Add('HealingStreamTotem', function(num)
		local tempTable = {}
		for _, Obj in pairs(_A.OM:Get('Enemy')) do
			if Obj.name=="Healing Stream Totem" and Obj:los() then
				tempTable[#tempTable+1] = {
					guid = Obj.guid,
					range = Obj:range(),
				}
			end
		end
		if #tempTable>1 then
			table.sort( tempTable, function(a,b) return a.range < b.range end )
		end
		if #tempTable>=1 then
			return tempTable[num] and tempTable[num].guid
		end
	end)
	_A.PetGUID  = nil
	local function attacktotem()
		local htotem = Object("HealingStreamTotem")
		if htotem then
			return _A.CallWowApi("PetAttack", htotem.guid), 1
		end
	end
	local function attackfocus()
		local _focus = Object("focus")
		local htotem = Object("HealingStreamTotem")
		if not htotem and _focus then
			if _focus:alive() and _focus:enemy() and _focus:exists() then
				if (_A.pull_location~="party" and _A.pull_location~="raid") or _focus:combat() then -- avoid pulling shit by accident
					if _A.PetGUID and (not _A.UnitTarget(_A.PetGUID) or _A.UnitTarget(_A.PetGUID)~=_focus.guid) then
						return _A.CallWowApi("PetAttack", _focus.guid), 2
					end
				end
				return 2
			end
		end
	end
	local function attacklowest()
		local target = Object("lowestEnemyInSpellRange(Arcane Shot)")
		if target and target:alive() and target:enemy() and target:exists() then
			if (_A.pull_location~="party" and _A.pull_location~="raid") or target:combat() then -- avoid pulling shit by accident
				if _A.PetGUID and (not _A.UnitTarget(_A.PetGUID) or _A.UnitTarget(_A.PetGUID)~=target.guid) then
					return _A.CallWowApi("PetAttack", target.guid), 3
				end
			end
			return 3
		end
	end
	local function attacktarget()
		local target = Object("target")
		if target and target:alive() and target:enemy() and target:exists() then
			if (_A.pull_location~="party" and _A.pull_location~="raid") or target:combat() then -- avoid pulling shit by accident
				if _A.PetGUID and (not _A.UnitTarget(_A.PetGUID) or _A.UnitTarget(_A.PetGUID)~=target.guid) then
					return _A.CallWowApi("PetAttack", target.guid), 3
				end
			end
			return 3
		end
	end
	local function petengine()
		if not player then return true end
		if player:spec()~=255 then return true end
		if not player:combat() then return true end
		if _A.DSL:Get("toggle")(_,"MasterToggle")~=true then return true end
		if player:mounted() then return end
		if UnitInVehicle(player.guid) and UnitInVehicle(player.guid)==1 then return end
		if not _A.UnitExists("pet") or _A.UnitIsDeadOrGhost("pet") or not _A.HasPetUI() then if _A.PetGUID then _A.PetGUID = nil end return true end
		_A.PetGUID = _A.PetGUID or _A.UnitGUID("pet")
		if _A.PetGUID == nil then return end
		-- Rotation
		if attacktotem() then return true end
		if attackfocus() then return true end
		if attacklowest() then return true end
		-- if attacktarget() then return true end
	end
	C_Timer.NewTicker(.3, petengine, false, "petengineengine")
end
local exeOnUnload = function()
end


survival.rot = {
	mendpet =  function()
		if	_A.UnitExists("pet")
			and not _A.UnitIsDeadOrGhost("pet")
			and _A.HasPetUI()
			and _A.castdelay("Mend Pet", (2*player:gcd()))
			then
			pet = Object("pet")
			if pet and pet:range()<=40 and not pet:buff("Mend Pet") and pet:los() then 
				return player:cast("Mend Pet") 
			end
		end
	end,
	-- serpent sting, find a way to put dot on as many people as possible in the least amount of multishots, it is a big deal.
	explosiveshot = function()
		if _A.EScheck() and player:SpellUsable("Explosive Shot") and player:SpellCooldown("Explosive Shot")<.3 then
			local lowestmelee = Object("lowestEnemyInSpellRange(Arcane Shot)")
			if lowestmelee then
				return lowestmelee:Cast("Explosive Shot")
			end
		end
	end,
	
	amoc = function()
		if player:talent("A Murder of Crows") and player:SpellUsable("A Murder of Crows") and player:SpellCooldown("A Murder of Crows")<.3 then
			local lowestmelee = Object("lowestEnemyInSpellRange(Arcane Shot)")
			if lowestmelee then
				return lowestmelee:Cast("A Murder of Crows")
			end
		end
	end,
	
	blackarrow = function()
		if _A.BAcheck() and player:SpellUsable("Black Arrow") and player:SpellCooldown("Black Arrow")<.3 then
			local lowestmelee = nil
			if _A.pull_location=="pvp" then
				lowestmelee = Object("highestEnemyInSpellRangeNOTAR(Arcane Shot)")
				else 
				lowestmelee = Object("lowestEnemyInSpellRange(Arcane Shot)")
			end
			if lowestmelee then
				return lowestmelee:Cast("Black Arrow")
			end
		end
	end,
	
	
	serpentsting = function()
		if _A.castdelay(1978, (2*player:gcd())) and _A.lowpriocheck("Serpent Sting") and player:SpellUsable("Serpent Sting")  then
			local lowestmelee = Object("lowestEnemyInSpellRange(Arcane Shot)")
			if lowestmelee and not lowestmelee:debuff("Serpent Sting") then
				return lowestmelee:Cast("Serpent Sting")
			end
		end
	end,
	
	multishot = function()
		-- if player:SpellUsable("Multi-Shot") and _A.mostclumpedenemy then
		if player:SpellUsable("Multi-Shot") then
			local lowestmelee = Object("lowestEnemyInSpellRange(Arcane Shot)")
			if lowestmelee then
				return lowestmelee:Cast("Multi-Shot")
			end
		end
	end,
	
	arcaneshot = function()
		if _A.lowpriocheck("Arcane Shot") and player:SpellUsable("Arcane Shot") then
			local lowestmelee = Object("lowestEnemyInSpellRange(Arcane Shot)")
			if lowestmelee then
				return lowestmelee:Cast("Arcane Shot")
			end
		end
	end,
	
	glaivetoss = function()
		if player:talent("Glaive Toss") and _A.lowpriocheck("Glaive Toss") and player:SpellUsable("Glaive Toss") and player:SpellCooldown("Glaive Toss")<.3 then
			local lowestmelee = Object("lowestEnemyInSpellRange(Arcane Shot)")
			if lowestmelee then
				return lowestmelee:Cast("Glaive Toss")
			end
		end
	end,
	
	killshot = function()
		if player:Spellcooldown("Kill Shot")<.3 then
			local lowestmelee = Object("lowestEnemyInSpellRangeNOTAR(Kill Shot)")
			if lowestmelee and lowestmelee:health()<=20 then
				return lowestmelee:Cast("Kill Shot")
			end
		end
	end,
	
	pet_misdirect = function()
		if player:Spellcooldown("Misdirection")==0 and _A.castdelay("Misdirection", 1.5)
			and player:combat() and _A.pull_location=="none" and not player:isCastingAny()
			then
			local pet = Object("pet")
			if pet and pet:alive() and pet:exists() and not player:buff("Misdirection") and pet:SpellRange("Misdirection") and pet:los() then
				return pet:Cast("Misdirection")
			end
		end
	end,
	
	cobrashot = function()
		local lowestmelee = nil
		if _A.pull_location=="pvp" then
			lowestmelee = Object("highestEnemyInSpellRangeNOTAR(Arcane Shot)")
			else 
			lowestmelee = Object("lowestEnemyInSpellRange(Arcane Shot)")
		end
		if lowestmelee then
			if player:level()<81 then
				return lowestmelee:Cast("Steady Shot")
				else  return lowestmelee:Cast("Cobra Shot")
			end
		end
	end,
}
local function AOEcheck()
	if _A.modifier_shift() then return true end
	-- if (_A.clumpcount>=enemytreshhold) then return true end
	return false
end
---========================
---========================
---========================
---========================
---========================
_A.mostclumpedenemy = nil
_A.clumpcount = 0
local inCombat = function()	
	player = Object("player")
	if not player then return end
	_A.latency = (select(3, GetNetStats())) and math.ceil(((select(3, GetNetStats()))/100))/10 or 0
	_A.interrupttreshhold = .3 + _A.latency
	-- _A.clumpcount, _A.mostclumpedenemy = _A.clusteredenemy()
	-- print(_A.mostclumpedenemy)
	-- print(_A.clumpcount)
	-- print(player:spellexists("Black Arrow"))
	if not _A.pull_location then return end
	if _A.buttondelayfunc()  then return end
	if player:mounted() then return end
	if not player:combat() then return end
	if UnitInVehicle(player.guid) and UnitInVehicle(player.guid)==1 then return end
	if not player:isCastingAny() or player:CastingRemaining() < 0.3 then
		-- no gcd
		survival.rot.pet_misdirect()
		-- aoe
		if AOEcheck() and survival.rot.multishot() then return end -- make a complete aoe check function
		-- single target important rotation
		if survival.rot.killshot() then return end
		if not AOEcheck() and survival.rot.amoc() then return end
		if not AOEcheck() and survival.rot.blackarrow() then return end
		if (not AOEcheck() or player:buff("Lock and Load")) and survival.rot.explosiveshot() then return end
		if not AOEcheck() and survival.rot.glaivetoss() then return end
		-- Fills
		if not AOEcheck() and survival.rot.serpentsting() then return end
		if not AOEcheck() and survival.rot.arcaneshot() then return end
		if player:combat() and survival.rot.mendpet() then return end
		if (_A.CobraCheck() or AOEcheck()) and survival.rot.cobrashot() then return end -- needs to be on highest HP
	end
end
local spellIds_Loc = function()
end
local blacklist = function()
end
_A.CR:Add(255, {
	name = "Youcef's Survival Hunter",
	ic = inCombat,
	ooc = inCombat,
	use_lua_engine = true,
	gui = GUI,
	gui_st = {title="CR Settings", color="87CEFA", width="315", height="370"},
	wow_ver = "5.4.8",
	apep_ver = "1.1",
	-- ids = spellIds_Loc,
	-- blacklist = blacklist,
	-- pooling = false,
	load = exeOnLoad,
	unload = exeOnUnload
})
