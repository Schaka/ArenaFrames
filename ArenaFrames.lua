local function log(msg) DEFAULT_CHAT_FRAME:AddMessage(msg) end -- alias for convenience

local x = -200							-- Vertical Position of the UnitFrames (anchored to UIParent)
local y = 400							-- Horizontal Position of the UnitFrames
local spacing = 190  					-- Spacing between the UnitFrames
local numBuffs = 16						-- How many buffs do you want to see?
local numDebuffs = 16					-- How many debuffs do you want to see?
local showClassIcons = true				-- Show Class Icons on ArenaFrames or 2D Portrait of the Unit?
local clickThrough = false				-- Helps to not accidentally click and target an ArenaUnit while turning Camera
local frames = {						-- Which Units do you want to track? (I left out arena 4 and 5 because there is nearly no active 5vs5)
	['arena1'] = true,					
	['arena2'] = true, 
	['arena3'] = true,	
}

local arenaUnits = { }
local nameToUnit = { }
local unitBuffs = { }
local unitDebuffs = { }
local enemyCount = 0

local function tableLength(tbl)
	count = 0
	for _ in pairs(tbl) do 
		count = count + 1 
	end
	return count
end


-- Textures / Handler
--local texture = 'Interface\\TargetingFrame\\UI-TargetingFrame'
local texture = "Interface\\AddOns\\ArenaFrames\\ArenaTexture"
local ArenaHandler = CreateFrame('Frame')
local trinketList = {
	[select(1,GetSpellInfo(42292))] = 120,
}
local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {left = -1, right = -1, top = -1, bottom = -1}
}
local mpColors = {
	['DRUID']   		= {r = 69/255,  g = 57/255, b = 227/255},
	['HUNTER']  		= {r = 69/255,  g = 57/255, b = 227/255},
	['MAGE']	   		= {r = 69/255,  g = 57/255, b = 227/255},
	['PALADIN'] 		= {r = 69/255,  g = 57/255, b = 227/255},
	['PRIEST']  		= {r = 69/255,  g = 57/255, b = 227/255},
	['ROGUE']   		= {r = 1.00,    g = 1.00,   b = 34/255},
	['SHAMAN'] 			= {r = 69/255,  g = 57/255, b = 227/255},
	['WARLOCK'] 		= {r = 69/255,  g = 57/255, b = 227/255},
	['WARRIOR'] 		= {r = 255/255, g = 0,      b = 0},
}

local function ClassToTexture(id)
    if (id == 1) then -- warrior
        return "WARRIOR"
    elseif (id == 2) then -- paladin
        return "PALADIN"
    elseif (id == 3) then -- hunter
        return "HUNTER"
    elseif (id == 4) then -- rogue
        return "ROGUE"
    elseif (id == 5) then -- priest
        return "PRIEST"
    elseif (id == 6) then -- dk
        return "DEATHKNIGHT"
    elseif (id == 7) then -- sham
        return "SHAMAN"
    elseif (id == 8) then -- mage
        return "MAGE"
    elseif (id == 9) then -- lock
        return "WARLOCK"
    elseif (id == 11) then -- druid
        return "DRUID"
    else
        return "WARRIOR"
    end
end

-- Show AuraTooltip
local function OnAuraEnter()
	if(not this:IsVisible()) then return end
	local unit = this:GetParent().unit
		GameTooltip:SetOwner(this, 'ANCHOR_BOTTOMLEFT')
	if(this.isDebuff) then
		GameTooltip:SetUnitDebuff(unit, this.id)
	else
		GameTooltip:SetUnitBuff(unit, this.id)
	end
end


--Creation of ArenaFrames e.g. CreateArenaFrame('arena1', 50, 100)
local function CreateArenaFrame(unit,x,y)

	--MainFrame
	local ArenaFrame = CreateFrame('Button', unit..'_frame', UIParent, 'SecureActionButtonTemplate')
	ArenaFrame:SetHeight(100)
	ArenaFrame:SetWidth(232)
	ArenaFrame:SetPoint('RIGHT', UIParent, x,y)
	ArenaFrame:SetFrameStrata('TOOLTIP')
	ArenaFrame:RegisterForClicks('AnyDown')
	ArenaFrame:SetScript('OnEnter', UnitFrame_OnEnter)
	ArenaFrame:SetScript('OnLeave', UnitFrame_OnLeave)
	ArenaFrame.unit = unit
	
	if clickThrough then
		ArenaFrame:EnableMouse(false)
	end
	
	--RegisterUnitWatch(ArenaFrame)
	
	--ArenaFrameTexture
	ArenaFrame.texture = ArenaFrame:CreateTexture('$parentTexture', 'BORDER')
	ArenaFrame.texture:SetTexture(texture)
	ArenaFrame.texture:SetAllPoints()
	--ArenaFrame.texture:SetTexCoord(1, 0.09375, 0, 0.78125)
	ArenaFrame.texture:SetTexCoord(0.09375, 1, 0, 0.78125)
	
	--ArenaFrameHealthbar
	ArenaFrame.health = CreateFrame('StatusBar', unit..'_HealthBar', ArenaFrame)
	ArenaFrame.health:SetWidth(119)
	ArenaFrame.health:SetHeight(12)
	ArenaFrame.health:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
	ArenaFrame.health:SetStatusBarColor(0,1,0,1)
	ArenaFrame.health:SetBackdrop(backdrop)
	ArenaFrame.health:SetBackdropColor(0,0,0,.6)
	ArenaFrame.health:SetPoint('TOPRIGHT', ArenaFrame.texture, -106, -41)
	ArenaFrame.health:SetFrameStrata('BACKGROUND')
	
	--ArenaFrameHealthText
	ArenaFrame.healthText = ArenaFrame:CreateFontString('$parentHealthText', 'OVERLAY')
	ArenaFrame.healthText:SetFont('Fonts\\ARIALN.ttf', 15, 'OUTLINE')
	ArenaFrame.healthText:SetPoint('CENTER', ArenaFrame.health, 0, 0)
	ArenaFrame.healthText:SetDrawLayer('OVERLAY')
	
	--ArenaFrameManaBar
	ArenaFrame.power = CreateFrame('StatusBar', unit..'_ManaBar', ArenaFrame)
	ArenaFrame.power:SetWidth(119)
	ArenaFrame.power:SetHeight(12)
	ArenaFrame.power:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
	ArenaFrame.power:SetStatusBarColor(0,0,1,1)
	ArenaFrame.power:SetBackdrop(backdrop)
	ArenaFrame.power:SetBackdropColor(0,0,0,.6)
	ArenaFrame.power:SetPoint('TOPLEFT', ArenaFrame.health, 'BOTTOMLEFT', 0, -1)
	ArenaFrame.power:SetFrameStrata('BACKGROUND')
	
	--ArenaFrameManaText
	ArenaFrame.powerText = ArenaFrame:CreateFontString('$parentPowerText', 'OVERLAY')
	ArenaFrame.powerText:SetFont('Fonts\\ARIALN.ttf', 15, 'OUTLINE')
	ArenaFrame.powerText:SetPoint('CENTER', ArenaFrame.power, 0, 2)
	ArenaFrame.powerText:SetDrawLayer('OVERLAY')
	
	--ArenaFrameNameText
	ArenaFrame.nameText = ArenaFrame:CreateFontString(unit..'_name', 'OVERLAY')
	ArenaFrame.nameText:SetFont('Fonts\\ARIALN.ttf', 12, 'OUTLINE')
	ArenaFrame.nameText:SetPoint('CENTER', ArenaFrame.health, 0, 15)
	
	--ArenaFrameNameBackground 
	ArenaFrame.nameBackground = CreateFrame('Frame', unit..'_nameBackground', ArenaFrame)
	ArenaFrame.nameBackground:SetWidth(119)
	ArenaFrame.nameBackground:SetHeight(19)
	ArenaFrame.nameBackground:SetBackdrop(backdrop)
	ArenaFrame.nameBackground:SetBackdropColor(0,0,0,.6)
	ArenaFrame.nameBackground:SetFrameLevel(ArenaFrame:GetFrameLevel() - 1)
	ArenaFrame.nameBackground:SetPoint('TOPRIGHT', ArenaFrame, -106, -22)
	
	--ArenaFrameCombatIcon -> Combat / NoCombat, LevelText being hidden
	ArenaFrame.combat = ArenaFrame:CreateTexture('$parentCombatIcon', 'BORDER')
	ArenaFrame.combat:SetWidth(30)
	ArenaFrame.combat:SetHeight(30)
	ArenaFrame.combat:SetTexture('Interface\\CHARACTERFRAME\\UI-StateIcon')
	ArenaFrame.combat:SetTexCoord(0.5,1,0,0.49)
	ArenaFrame.combat:SetPoint('CENTER', ArenaFrame.texture, -63, -15)
	ArenaFrame.combat:SetDrawLayer('OVERLAY')
	ArenaFrame.combat:Hide()
	ArenaFrame:SetScript('OnUpdate', function()
		if UnitAffectingCombat(unit) then
			ArenaFrame.combat:Show()
		else
			ArenaFrame.combat:Hide()
		end
	end)
	
	--ArenaFrameClassIcon
	ArenaFrame.classIcon = ArenaFrame:CreateTexture(unit..'_classIcon', 'BORDER')
	ArenaFrame.classIcon:SetTexture("Interface\\AddOns\\ArenaFrames\\UI-CLASSES-CIRCLES")
	ArenaFrame.classIcon:SetWidth(64)
	ArenaFrame.classIcon:SetHeight(64)
	ArenaFrame.classIcon:SetPoint('TOPRIGHT', ArenaFrame.texture, -42, -12)
	ArenaFrame.classIcon:SetDrawLayer('BACKGROUND')
	ArenaFrame.classIcon:Hide()
	
	--ArenaFrameTrinketIcon
	ArenaFrame.trinketIcon = ArenaFrame:CreateTexture('$parentTrinketIcon', 'BORDER')
	ArenaFrame.trinketIcon:SetWidth(45)
	ArenaFrame.trinketIcon:SetHeight(45)
	ArenaFrame.trinketIcon:SetPoint('LEFT', ArenaFrame, 'RIGHT', -45, 6)
	ArenaFrame.trinketIcon:SetTexture('Interface\\Icons\\inv_jewelry_trinketpvp_01')
	
	--ArenaFrameTrinketIconCooldown
	ArenaFrame.trinketIconCooldown = CreateFrame('Cooldown', '$parentTrinketCooldown', ArenaFrame)
	ArenaFrame.trinketIconCooldown:SetAllPoints(ArenaFrame.trinketIcon)
	
	ArenaFrame.castbar = CreateFrame("StatusBar", unit.."_castbar", nil, "ArenaCastingBarFrameTemplate")
	ArenaFrame.castbar:SetPoint("RIGHT", ArenaFrame, "LEFT", 0, 0)
	ArenaFrame.castbar:Hide()
	ArenaFrame.castbar:SetHeight(20)
	ArenaFrame.castbar:SetWidth(80)
	
	
	--Creation of the BuffFrames
	local function CreateBuffFrame(i)
		buff = CreateFrame('Button', unit..'buff'..i, ArenaFrame)
		buff:SetWidth(20)
		buff:SetHeight(20)
		
		if not clickThrough then
			buff:EnableMouse(true)
			buff.unit = unit
			buff.id = i
			buff:SetScript('OnEnter', OnAuraEnter)
			buff:SetScript('OnLeave', function() GameTooltip:Hide() end)
		end
		
		buff.Icon = buff:CreateTexture(nil, 'BORDER')
		buff.Icon:SetPoint('TOPLEFT', 0, 0)
		buff.Icon:SetPoint('BOTTOMRIGHT', 0, 0)
		
		buff.Count = buff:CreateFontString(nil, 'OVERLAY')
		buff.Count:SetFont('Fonts\\ARIALN.ttf', 12, 'OUTLINE')
		buff.Count:SetPoint('TOPLEFT', buff)
		
		buff.Cooldown = CreateFrame('Cooldown', buff:GetName()..'cooldown', buff)
		buff.Cooldown:SetReverse(true)
		buff.Cooldown:SetAllPoints(buff.Icon)
		
		if i == 1 then
			buff:SetPoint('TOP', ArenaFrame.power, 'BOTTOMLEFT', 0, -5)
		elseif i == 7 then
			buff:SetPoint('TOP', unit..'buff1', 'BOTTOM', 0, -3)
		else
			buff:SetPoint('LEFT', unit..'buff'..i-1, 'RIGHT', 2,0)
		end
	end
	
	--Creation of the DebuffFrames
	local function CreateDebuffFrame(i)
		debuff = CreateFrame('Button', unit..'debuff'..i, ArenaFrame)
		debuff:SetWidth(20)
		debuff:SetHeight(20)
		
		if not clickThrough then
			debuff:EnableMouse(true)
			debuff.unit = unit
			debuff.id = i
			debuff.isDebuff = true
			debuff:SetScript('OnEnter', OnAuraEnter)
			debuff:SetScript('OnLeave', function() GameTooltip:Hide() end)
		end
				
		debuff.Icon = debuff:CreateTexture(nil, 'BORDER')
		debuff.Icon:SetPoint('TOPLEFT', 0, 0)
		debuff.Icon:SetPoint('BOTTOMRIGHT', 0, 0)
		
		debuff.Count = debuff:CreateFontString(nil, 'OVERLAY')
		debuff.Count:SetFont('Fonts\\ARIALN.ttf', 12, 'OUTLINE')
		debuff.Count:SetPoint('TOPLEFT', debuff)
		
		debuff.Cooldown = CreateFrame('Cooldown', debuff:GetName()..'cooldown', debuff)
		debuff.Cooldown:SetReverse(true)
		debuff.Cooldown:SetAllPoints(debuff.Icon)
		
		if i == 1 then
			debuff:SetPoint('TOP', ArenaFrame.power, 'BOTTOMLEFT', 0, -60)
		elseif i == 7 then
			debuff:SetPoint('TOP', unit..'debuff1', 'BOTTOM', 0, -3)
		else
			debuff:SetPoint('LEFT', unit..'debuff'..i-1, 'RIGHT', 2,0)
		end	
	end
	
	for i=1,numBuffs do
		CreateBuffFrame(i)
	end
	for j=1,numDebuffs do
		CreateDebuffFrame(j)
	end
end

function ArenaHandler:OnUpdate(elapsed)
		for i=1, 5 do
			if _G["arena"..i.."_castbar"].channel == false then
				_G["arena"..i.."_castbar"]:SetValue(_G["arena"..i.."_castbar"]:GetValue()+elapsed)
				local min, max = _G["arena"..i.."_castbar"]:GetMinMaxValues()
				local percent = _G["arena"..i.."_castbar"]:GetValue()/max
				local sparkOffset = _G["arena"..i.."_castbarSpark"]:GetWidth()/2
				_G["arena"..i.."_castbarSpark"]:SetPoint("LEFT", _G["arena"..i.."_castbar"], "LEFT", _G["arena"..i.."_castbar"]:GetWidth()*percent-sparkOffset, 0)
				if _G["arena"..i.."_castbar"]:GetValue() >= max then
					_G["arena"..i.."_castbar"]:SetStatusBarColor(0.0, 1.0, 0.0)
					_G["arena"..i.."_castbar"].fadeOut = true
				end
			elseif _G["arena"..i.."_castbar"].channel == true then
				local min, max = _G["arena"..i.."_castbar"]:GetMinMaxValues()
				_G["arena"..i.."_castbar"]:SetValue(_G["arena"..i.."_castbar"]:GetValue()-elapsed)
				local percent = _G["arena"..i.."_castbar"]:GetValue()/max
				local sparkOffset = _G["arena"..i.."_castbarSpark"]:GetWidth()/2
				_G["arena"..i.."_castbarSpark"]:SetPoint("LEFT", _G["arena"..i.."_castbar"], "LEFT", _G["arena"..i.."_castbar"]:GetWidth()*percent-sparkOffset, 0)
				if _G["arena"..i.."_castbar"]:GetValue() <= min then
					_G["arena"..i.."_castbar"]:SetStatusBarColor(0.0, 1.0, 0.0)
					_G["arena"..i.."_castbar"].fadeOut = true
				end
			end
			-- fade out castbar to display interrupt and success messages
			if _G["arena"..i.."_castbar"].fadeOut then
				_G["arena"..i.."_castbar"]:SetAlpha(_G["arena"..i.."_castbar"]:GetAlpha()- CASTING_BAR_ALPHA_STEP)
				if _G["arena"..i.."_castbar"]:GetAlpha() <= 0 then
					_G["arena"..i.."_castbar"].fadeOut = nil
					_G["arena"..i.."_castbar"]:SetAlpha(1)
					_G["arena"..i.."_castbar"]:Hide()
				end
			end
		end
end	

function ArenaHandler:UpdateCastBars(target, spell, casttime)
	local unit = nameToUnit[target]
	if not unit then return end
	-- hide castbars if interrupt or another instant spell was casted (meaning the cast had to be interrupted)
	if casttime == 99999 or casttime == 99998 or casttime == 0 then
		if casttime == 0 or casttime == 99999 then
			_G[unit.."_castbarText"]:SetText(FAILED)
			_G[unit.."_castbar"]:SetStatusBarColor(1.0, 0.0, 0.0)
			_G[unit.."_castbar"].fadeOut = true
		else
			_G[unit.."_castbarText"]:SetText(INTERRUPTED)
			_G[unit.."_castbar"]:SetStatusBarColor(1.0, 0.0, 0.0)
			_G[unit.."_castbar"].fadeOut = true
		end
		return
	else
		_G[unit.."_castbar"]:Show()
	end
	if casttime and (casttime > 0 or casttime < 0) then
		if casttime > 0 then
		_G[unit.."_castbarIcon"]:SetTexture(select(3, GetSpellInfo(spell)))
		_G[unit.."_castbarIcon"]:Show()
		_G[unit.."_castbarText"]:SetText(select(1, GetSpellInfo(spell)))
		_G[unit.."_castbar"]:SetMinMaxValues(0, casttime/1000)
		_G[unit.."_castbar"]:SetValue(0)
		_G[unit.."_castbar"]:SetAlpha(1)
		_G[unit.."_castbar"].channel = false
		_G[unit.."_castbar"]:SetStatusBarColor(1.0, 0.7, 0.0)
		_G[unit.."_castbar"].fadeOut = nil
		--log(spell.."  "..time)
		elseif casttime < 0 then
			casttime = casttime * (-1)
			_G[unit.."_castbarIcon"]:SetTexture(select(3, GetSpellInfo(spell)))
			_G[unit.."_castbarIcon"]:Show()
			_G[unit.."_castbarText"]:SetText(select(1, GetSpellInfo(spell)))
			_G[unit.."_castbar"]:SetMinMaxValues(0, casttime/1000)
			_G[unit.."_castbar"]:SetValue(casttime/1000)
			_G[unit.."_castbar"]:SetAlpha(1)
			_G[unit.."_castbar"].channel = true
			_G[unit.."_castbar"]:SetStatusBarColor(1.0, 0.7, 0.0)
			_G[unit.."_castbar"].fadeOut = nil
		end
	else
		--log(spell)
	end
end

function ArenaHandler:UpdatePushback(target, casttime)
	local unit = nameToUnit[target]
	if not unit then return end
	if casttime < 0 then
		_G[unit.."_castbar"]:SetValue(_G[unit.."_castbar"]:GetValue()+casttime/1000)
	else
		_G[unit.."_castbar"]:SetValue(_G[unit.."_castbar"]:GetValue()-casttime/1000)
	end
end

--Name & Level Update
function ArenaHandler:UpdateName(target)
	local unitLevel = 70
	local unit = nameToUnit[target]
	if not unit then return end
	local name = _G[unit..'_name']
	name:SetText(target)
	_G[unit..'_frame']:SetAttribute("*type*", "macro")
	_G[unit..'_frame']:SetAttribute("macrotext1", "/targetexact "..target)
	_G[unit..'_frame']:SetAttribute('macrotext2', "/targetexact "..target.."\n/focus\n/targetlasttarget")
end

--Class, UnitPortrait & powerColor Update
function ArenaHandler:UpdateClass(target, class)
	local class = ClassToTexture(class)
	local unit = nameToUnit[target]
	if not unit then return end
	local unitColor = RAID_CLASS_COLORS[class]
	
	local classIcon = _G[unit..'_classIcon']
	classIcon:Show()
	if showClassIcons then
		classIcon:SetTexCoord(unpack(CLASS_BUTTONS[class]))
	end
	
	local power = _G[unit..'_ManaBar']
	power:SetStatusBarColor(mpColors[class].r, mpColors[class].g, mpColors[class].b)
end

function ArenaHandler:UpdatePowerType(target, value)
	local unit = nameToUnit[target]
	if not unit then return end 
	local power = _G[unit..'_ManaBar']
	if (value == 0) then -- mana
        power:SetStatusBarColor(mpColors["DRUID"].r, mpColors["DRUID"].g, mpColors["DRUID"].b)
    elseif (value == 1) then -- rage
        power:SetStatusBarColor(mpColors["WARRIOR"].r, mpColors["WARRIOR"].g, mpColors["WARRIOR"].b)
    elseif (value == 3) then -- energy
		power:SetStatusBarColor(mpColors["ROGUE"].r, mpColors["ROGUE"].g, mpColors["ROGUE"].b)
    else
        power:SetStatusBarColor(1, 1, 1, 1)
    end
end

--UnitMana Update
function ArenaHandler:UpdatePower(target, value, type)
	local unit = nameToUnit[target]
	if not unit then return end
	local power = _G[unit..'_ManaBar']
	local powerText = _G[unit..'_framePowerText']
	if type == "current" then
		power:SetValue(value)
		if arenaUnits[nameToUnit[target]].maxPower then
			powerText:SetText(value .. "/" .. arenaUnits[nameToUnit[target]].maxPower)
		else
			powerText:SetText(value)
		end
	elseif type == "max" then
		power:SetMinMaxValues(0, value)
		arenaUnits[nameToUnit[target]].maxPower = value
	end
end

--UnitHealth Update, NameUpdate
function ArenaHandler:UpdateHealth(target, value, type)
	local unit = nameToUnit[target]
	if not unit then return end
	local health = _G[unit..'_HealthBar']
	local healthText = _G[unit..'_frameHealthText']
	if type == "current" then
		health:SetValue(value)
		if arenaUnits[nameToUnit[target]].maxHP then
			healthText:SetText(value .. "/" .. arenaUnits[nameToUnit[target]].maxHP)
		else
			healthText:SetText(value)
		end
	elseif type == "max" then
		health:SetMinMaxValues(0, value)
		arenaUnits[nameToUnit[target]].maxHP = value
	end
end

--Check for active ArenaUnits and Update them
function ArenaHandler:PLAYER_ENTERING_WORLD()
	self:Reset()
	self.lastUpdate = 0
	enemyCount = 0
	for k,v in pairs(arenaUnits) do
		arenaUnits[k] = nil
	end
	for k,v in pairs(nameToUnit) do
		nameToUnit[k] = nil
	end
	for k, v in pairs(unitBuffs) do
		for ke,va in pairs(v) do
			v[ke] = nil
		end
		unitBuffs[k] = nil
	end
	for k, v in pairs(unitDebuffs) do
		for ke,va in pairs(v) do
			v[ke] = nil
		end
		unitDebuffs[k] = nil
	end
	for i=1,5 do
		for j=1,numBuffs do
			buff = _G["arena"..i.."buff"..j]
			debuff = _G["arena"..i.."debuff"..j]
			buff.Icon:SetTexture(nil)
			buff.Cooldown:Hide()
			buff.Count:SetText("")
			debuff.Icon:SetTexture(nil)
			debuff.Cooldown:Hide()
			debuff.Count:SetText("")
		end
	end
	if select(2, IsInInstance()) == "arena" then
		SendChatMessage(".spectator reset", "GUILD");
	end
end

function ArenaHandler:Reset()
	if select(2, IsInInstance()) == "arena" then
		local status, mapName, instanceID, lowestlevel, highestlevel, teamSize, registeredMatch = GetBattlefieldStatus(1)
		if teamSize == 0 then teamSize = 2 end
		for i=1, teamSize do
			_G['arena'..i..'_frame']:Show()
		end
	else
		for i=1,5 do
			_G['arena'..i..'_frame']:Hide()
			_G['arena'..i..'_castbar']:Hide()
		end
	end
end

function ArenaHandler:TrinketUsed(target, id, cd)
	local unit = nameToUnit[target]
	local trinketCooldown = _G[unit..'_frameTrinketCooldown']
	if id == 42292 then
		trinketCooldown:SetCooldown(GetTime(), cd)
	end
end

function ArenaHandler:CalculateBuffPositions(unit)
	local counter = 1
	for k,v in pairs(unitBuffs[unit]) do
		local buff = _G[unit..'buff'..counter]
		buff.Icon:SetTexture(v.icon)
		if v.count > 1 then
			buff.Count:SetText(v.count)
		else
			buff.Count:SetText('')
		end
		
		if v.duration and v.duration > 0 then
			buff.Cooldown:SetCooldown(v.startTime, v.duration)
			buff.Cooldown:Show()
		else
			buff.Cooldown:Hide()
		end
		v.position = counter
		counter = counter + 1
		--log(unit.."  "..v.icon.."  "..v.position.."  "..v.duration)
	end
	for i=counter, numBuffs do
		_G[unit.."buff"..i].Icon:SetTexture(nil)
		_G[unit.."buff"..i].Cooldown:Hide()
		_G[unit.."buff"..i].Count:SetText("")
	end
end

function ArenaHandler:CalculateDebuffPositions(unit)
	local counter = 1
	for k,v in pairs(unitDebuffs[unit]) do
		local debuff = _G[unit..'debuff'..counter]
		debuff.Icon:SetTexture(v.icon)
		if v.count > 1 then
			debuff.Count:SetText(v.count)
		else
			debuff.Count:SetText('')
		end
		
		if v.duration and v.duration > 0 then
			debuff.Cooldown:SetCooldown(v.startTime, v.duration)
			debuff.Cooldown:Show()
		else
			debuff.Cooldown:Hide()
		end
		v.position = counter
		counter = counter + 1
		--log(unit.."  "..v.icon.."  "..v.position.."  "..v.duration)
	end
	for i=counter, numDebuffs do
		_G[unit.."debuff"..i].Icon:SetTexture(nil)
		_G[unit.."debuff"..i].Cooldown:Hide()
		_G[unit.."debuff"..i].Count:SetText("")
	end
end

function ArenaHandler:UpdateAuras(target, removeaura, count, endtime, duration, spellId, debufftype, isDebuff, caster)
	local unit = nameToUnit[target]
	endtime = endtime/1000
	duration = duration/1000
	local texture = select(3, GetSpellInfo(spellId))
	if texture == "Interface\\Icons\\Temp" then return end
	--log(removeaura.."  "..endtime.."  "..isDebuff.."  "..GetSpellInfo(spellId))
	if removeaura == 1 then
		if isDebuff == 1 and unitBuffs[unit][spellId..caster] then
			unitBuffs[unit][spellId..caster] = nil
			self:CalculateBuffPositions(unit)
		elseif isDebuff == 0 and unitDebuffs[unit][spellId..caster] then
			unitDebuffs[unit][spellId..caster] = nil
			self:CalculateDebuffPositions(unit)
		end
		return
	end
	-- isDebuff is 1 if it's a buff lol
	if isDebuff == 1 and removeaura == 0 then
		local icon = select(3, GetSpellInfo(spellId))
		--log(target.." "..endtime.."  "..duration.."  "..GetSpellInfo(spellId).."  "..caster)
		-- select which buff we have to apply a texture and cooldown to (cooldown updates e.g.)
		if unitBuffs[unit][spellId..caster] then
			local buff = _G[unit..'buff'..unitBuffs[unit][spellId..caster].position]
			buff.Icon:SetTexture(icon)
			if count > 1 then
				buff.Count:SetText(count)
			else
				buff.Count:SetText('')
			end
			
			if duration and duration > 0 then
				buff.Cooldown:SetCooldown(GetTime()-(duration-endtime), duration)
				buff.Cooldown:Show()
			else
				buff.Cooldown:Hide()
			end	
		else
			if type(unitBuffs[unit][spellId..caster]) ~= "table" then unitBuffs[unit][spellId..caster] = { } end
			unitBuffs[unit][spellId..caster].icon = icon
			unitBuffs[unit][spellId..caster].startTime = GetTime()-(duration-endtime)
			unitBuffs[unit][spellId..caster].duration = duration
			unitBuffs[unit][spellId..caster].count = count
			self:CalculateBuffPositions(unit)
		end
	elseif isDebuff == 0 and removeaura == 0 then
		local icon = select(3, GetSpellInfo(spellId))
		--log(target.." "..endtime.."  "..duration.."  "..GetSpellInfo(spellId).."  "..caster)
		-- select which buff we have to apply a texture and cooldown to (cooldown updates e.g.)
		if unitDebuffs[unit][spellId..caster] then
			local debuff = _G[unit..'debuff'..unitDebuffs[unit][spellId..caster].position]
			debuff.Icon:SetTexture(icon)
			if count > 1 then
				debuff.Count:SetText(count)
			else
				debuff.Count:SetText('')
			end
			
			if duration and duration > 0 then
				debuff.Cooldown:SetCooldown(GetTime()-(duration-endtime), duration)
				debuff.Cooldown:Show()
			else
				debuff.Cooldown:Hide()
			end
		else
			if type(unitDebuffs[unit][spellId..caster]) ~= "table" then unitDebuffs[unit][spellId..caster] = { } end
			unitDebuffs[unit][spellId..caster].icon = icon
			unitDebuffs[unit][spellId..caster].startTime = GetTime()-(duration-endtime)
			unitDebuffs[unit][spellId..caster].duration = duration
			unitDebuffs[unit][spellId..caster].count = count
			self:CalculateDebuffPositions(unit)
		end
	end	
end

function ArenaHandler:ParseCommands(data)
    local pos = 1
    local stop = 1
    local target = nil
    
    if data:find(';AUR=') then
        local tar, data = strsplit(";", data)
        local _, data2 = strsplit("=", data)
        local aremove, astack, aexpiration, aduration, aspellId, adebyfftype, aisdebuff, acaster = strsplit(",", data2)
        self:Execute(tar, "AUR", tonumber(aremove), tonumber(astack), tonumber(aexpiration), tonumber(aduration), tonumber(aspellId), tonumber(adebyfftype), tonumber(aisdebuff), acaster)
        return
    end

    stop = strfind(data, ";", pos)
    target = strsub(data, 1, stop - 1)
    pos = stop + 1

    repeat
        stop = strfind(data, ";", pos)
        if (stop ~= nil) then
            local command = strsub(data, pos, stop - 1)
            pos = stop + 1

            local prefix = strsub(command, 1, strfind(command, "=") - 1)
            local value = strsub(command, strfind(command, "=") + 1)

            self:Execute(target, prefix, value)
        end
    until stop == nil
end

function ArenaHandler:Execute(target, prefix, ...)
	--log(target)
    local value = ...
    if (nameToUnit[target] == nil and UnitName("party1") ~= target and UnitName("party2") ~= target and UnitName("player") ~= target) then
		enemyCount = enemyCount +1
        nameToUnit[target] = "arena"..enemyCount
		arenaUnits["arena"..enemyCount] = { }
		arenaUnits["arena"..enemyCount].name = target
		arenaUnits["arena"..enemyCount].unit = "arena"..enemyCount
		unitBuffs["arena"..enemyCount] = { }
		unitDebuffs["arena"..enemyCount] = { }
		self:UpdateName(target)
    end

    if (prefix == "CHP") then
        self:UpdateHealth(target, tonumber(value), "current")
    elseif (prefix == "MHP") then
        self:UpdateHealth(target, tonumber(value), "max")
    elseif (prefix == "CPW") then
       self:UpdatePower(target, tonumber(value), "current")
    elseif (prefix == "MPW") then
       self:UpdatePower(target, tonumber(value), "max")
    elseif (prefix == "PWT") then
        self:UpdatePowerType(target, tonumber(value))
    elseif (prefix == "TEM") then
        --UpdateTeam(target, tonumber(value))
    elseif (prefix == "STA") then
        --UpdateStatus(target, tonumber(value))
    elseif (prefix == "TRG") then
        --UpdateTarget(target, value)
    elseif (prefix == "CLA") then
        self:UpdateClass(target, tonumber(value))
    elseif (prefix == "SPE") then
        local casttime = tonumber(strsub(value, strfind(value, ",") + 1))
        self:UpdateCastBars(target, tonumber(strsub(value, 1, strfind(value, ",") - 1)), casttime)
	elseif (prefix == "SPB") then
        local casttime = tonumber(strsub(value, strfind(value, ",") + 1))
		self:UpdatePushback(target, casttime)
    elseif (prefix == "CD") then
        self:TrinketUsed(target, tonumber(strsub(value, 1, strfind(value, ",") - 1)), tonumber(strsub(value, strfind(value, ",") + 1)))
    elseif (prefix == "RES") then
        --SendChatMessage(".spectator reset", "GUILD")
    elseif (prefix == "AUR") then
        self:UpdateAuras(target, ...)
    elseif (prefix == "TIM") then
        --SetEndTime(tonumber(value))
    else
        DEFAULT_CHAT_FRAME:AddMessage("ARENASPECTATOR: Unhandled prefix: " .. prefix .. ". Try to update to newer version")
    end
end

function ArenaHandler:CHAT_MSG_ADDON(prefix, message, distribution, sender)
	if prefix == "ARENASPEC" then
		self:ParseCommands(message)
	end
end

function ArenaHandler:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, sourceGUID,sourceName,sourceFlags,destGUID,destName,destFlags,spellID,spellName,extraSpellID,extraSpellName)
	if (event == "SPELL_INTERRUPT") then
		local unit = nameToUnit[destName]
		if not unit then return end
		self:UpdateCastBars(destName, extraSpellID, 99998)
	end		
end

--EventHandler
function ArenaHandler:HandleEvents(event,...)
	self[event](self, ...)
end

--Creation of the ArenaFrames
for i=1,5 do
	CreateArenaFrame("arena"..i, x,-(i*spacing)+y)
end

--Register all necessary events
ArenaHandler:RegisterEvent('PLAYER_ENTERING_WORLD')
ArenaHandler:RegisterEvent('CHAT_MSG_ADDON')
ArenaHandler:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
ArenaHandler:SetScript('OnEvent', ArenaHandler.HandleEvents)
ArenaHandler:SetScript('OnUpdate', ArenaHandler.OnUpdate)

--Slash command to show an example of the frames. /showaf
SlashCmdList.SHOWAF = function()
	for i=1,5 do
		_G['arena'..i..'_frame']:Show()
		_G['arena'..i..'_frame'].Hide = _G['arena'..i..'_frame'].Show
		_G['arena'..i..'_name']:SetText('arena'..i)
		_G['arena'..i..'_frameHealthText']:SetText(30000)
		_G['arena'..i..'_framePowerText']:SetText(30000)
		_G['arena'..i..'_classIcon']:SetTexCoord(0, 0.25, 0, 0.25)
		_G['arena'..i..'_classIcon']:Show()
		_G['arena'..i..'_frameTrinketCooldown']:SetCooldown(GetTime(),120)
		for j=1, numBuffs do
			buff = _G['arena'..i..'buff'..j]
			buff.Icon:SetTexture('Interface\\ICONS\\Spell_ChargePositive')
			
			debuff = _G['arena'..i..'debuff'..j]
			debuff.Icon:SetTexture('Interface\\ICONS\\Spell_ChargeNegative')
		end
	end
end
SLASH_SHOWAF1 = '/showaf'
