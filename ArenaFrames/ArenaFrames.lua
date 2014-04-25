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

-- We still need Blizzards ArenaUI to be able to alter the Castbars & PetFrames
if not IsAddOnLoaded('Blizzard_ArenaUI') then	
	LoadAddOn('Blizzard_ArenaUI')
end

-- Textures / Handler
local texture = 'Interface\\TargetingFrame\\UI-TargetingFrame'
local ArenaHandler = CreateFrame('Frame')
local trinketList = {
	[select(1,GetSpellInfo(42292))] = 120,
	[select(1,GetSpellInfo(59752))] = 120,
	[select(1,GetSpellInfo(7744))] = 45,
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
	['DEATHKNIGHT'] 	= {r = 0.00, 	g = 0.82, 	b = 1.00 }
}
--UnitMana events 
local eventList = {
	['UNIT_MANA'] = true,
	['UNIT_RAGE'] = true,
	['UNIT_FOCUS'] = true,
	['UNIT_ENERGY'] = true,
	['UNIT_RUNIC_POWER'] = true,
}

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
	local ArenaFrame = CreateFrame('Button', unit..'_frame', UIParent, 'SecureUnitButtonTemplate')
	ArenaFrame:SetHeight(100)
	ArenaFrame:SetWidth(232)
	ArenaFrame:SetPoint('RIGHT', UIParent, x,y)
	ArenaFrame:SetFrameStrata('TOOLTIP')
	ArenaFrame:RegisterForClicks('AnyUp')
	ArenaFrame:SetAttribute('unit', unit)
	ArenaFrame:SetAttribute('*type1', 'target')
	ArenaFrame:SetAttribute('*type2', 'focus')
	ArenaFrame:SetScript('OnEnter', UnitFrame_OnEnter)
	ArenaFrame:SetScript('OnLeave', UnitFrame_OnLeave)
	ArenaFrame.unit = unit
	
	if clickThrough then
		ArenaFrame:EnableMouse(false)
	end
	
	RegisterUnitWatch(ArenaFrame)
	
	--ArenaFrameTexture
	ArenaFrame.texture = ArenaFrame:CreateTexture('$parentTexture', 'BORDER')
	ArenaFrame.texture:SetTexture(texture)
	ArenaFrame.texture:SetAllPoints()
	ArenaFrame.texture:SetTexCoord(1, 0.09375, 0, 0.78125)
	
	--ArenaFrameHealthbar
	ArenaFrame.health = CreateFrame('StatusBar', unit..'_HealthBar', ArenaFrame)
	ArenaFrame.health:SetWidth(119)
	ArenaFrame.health:SetHeight(12)
	ArenaFrame.health:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
	ArenaFrame.health:SetStatusBarColor(0,1,0,1)
	ArenaFrame.health:SetBackdrop(backdrop)
	ArenaFrame.health:SetBackdropColor(0,0,0,.6)
	ArenaFrame.health:SetPoint('TOPLEFT', ArenaFrame.texture, 108, -41)
	ArenaFrame.health:SetFrameStrata('BACKGROUND')
	
	--ArenaFrameHealthText
	ArenaFrame.healthText = ArenaFrame:CreateFontString('$parentHealthText', 'OVERLAY')
	ArenaFrame.healthText:SetFont('Fonts\\ARIALN.ttf', 10, 'OUTLINE')
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
	ArenaFrame.powerText:SetFont('Fonts\\ARIALN.ttf', 10, 'OUTLINE')
	ArenaFrame.powerText:SetPoint('CENTER', ArenaFrame.power, 0, 2)
	ArenaFrame.powerText:SetDrawLayer('OVERLAY')
	
	--ArenaFrameNameText
	ArenaFrame.nameText = ArenaFrame:CreateFontString(unit..'_name', 'OVERLAY')
	ArenaFrame.nameText:SetFont('Fonts\\ARIALN.ttf', 12, 'OUTLINE')
	ArenaFrame.nameText:SetPoint('CENTER', ArenaFrame.health, 0, 15)
	
	--ArenaFrameLevelText
	ArenaFrame.levelText = ArenaFrame:CreateFontString(unit..'_level', 'OVERLAY')
	ArenaFrame.levelText:SetFont('Fonts\\ARIALN.ttf', 12, 'OUTLINE')
	ArenaFrame.levelText:SetPoint('BOTTOMLEFT', ArenaFrame.texture, 45, 28)
	
	--ArenaFrameNameBackground 
	ArenaFrame.nameBackground = CreateFrame('Frame', unit..'_nameBackground', ArenaFrame)
	ArenaFrame.nameBackground:SetWidth(120)
	ArenaFrame.nameBackground:SetHeight(15)
	ArenaFrame.nameBackground:SetBackdrop(backdrop)
	ArenaFrame.nameBackground:SetBackdropColor(0,0,0,.6)
	ArenaFrame.nameBackground:SetFrameLevel(ArenaFrame:GetFrameLevel() - 1)
	ArenaFrame.nameBackground:SetPoint('CENTER', ArenaFrame, 50,18)
	
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
			ArenaFrame.levelText:Hide()
		else
			ArenaFrame.combat:Hide()
			ArenaFrame.levelText:Show()
		end
	end)
	
	--ArenaFrameClassIcon
	ArenaFrame.classIcon = ArenaFrame:CreateTexture(unit..'_classIcon', 'BORDER')
	ArenaFrame.classIcon:SetTexture('Interface\\TargetingFrame\\UI-Classes-Circles')
	ArenaFrame.classIcon:SetWidth(64)
	ArenaFrame.classIcon:SetHeight(64)
	ArenaFrame.classIcon:SetPoint('LEFT', ArenaFrame.texture, 42, 5)
	ArenaFrame.classIcon:SetDrawLayer('BACKGROUND')
	ArenaFrame.classIcon:Hide()
	
	--ArenaFrameTrinketIcon
	ArenaFrame.trinketIcon = ArenaFrame:CreateTexture('$parentTrinketIcon', 'BORDER')
	ArenaFrame.trinketIcon:SetWidth(45)
	ArenaFrame.trinketIcon:SetHeight(45)
	ArenaFrame.trinketIcon:SetPoint('LEFT', ArenaFrame, 'RIGHT', 5, 6)
	ArenaFrame.trinketIcon:SetTexture('Interface\\Icons\\inv_jewelry_trinketpvp_01')
	
	--ArenaFrameTrinketIconCooldown
	ArenaFrame.trinketIconCooldown = CreateFrame('Cooldown', '$parentTrinketCooldown', ArenaFrame)
	ArenaFrame.trinketIconCooldown:SetAllPoints(ArenaFrame.trinketIcon)
	
	--Castbars
	unitID = gsub(unit, '%a', '')
	ArenaFrame.castbar = _G['ArenaEnemyFrame'..unitID..'CastingBar']
	ArenaFrame.castbar:SetWidth(180)
	ArenaFrame.castbar:ClearAllPoints()
	ArenaFrame.castbar:SetPoint('RIGHT', ArenaFrame.trinketIcon, -2, -140)
	ArenaFrame.castbar.SetPoint = function() end
	ArenaFrame.castbar:SetParent(_G['ArenaEnemyFrame'..unitID])
	ArenaFrame.castbartext = _G['ArenaEnemyFrame'..unitID..'CastingBarText']
	ArenaFrame.castbartext:SetWidth(100)
	
	--Castbar Background
	ArenaFrame.castbarBackground = CreateFrame('Frame', '$parentBackground', ArenaFrame.castbar)
	ArenaFrame.castbarBackground:SetPoint('TOPLEFT', -1, 1)
	ArenaFrame.castbarBackground:SetPoint('BOTTOMRIGHT', 1, -1)
	ArenaFrame.castbarBackground:SetBackdrop(backdrop)
	ArenaFrame.castbarBackground:SetBackdropColor(0,0,0,1)
	ArenaFrame.castbarBackground:SetFrameLevel(ArenaFrame.castbar:GetFrameLevel() - 1)
	
	
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
		buff.Cooldown:SetReverse()
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
		debuff.Cooldown:SetReverse()
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

--Name & Level Update
local function UpdateName(unit)
	local unitName = UnitName(unit)
	local unitLevel = UnitLevel(unit)
	
	local name = _G[unit..'_name']
	name:SetText(unitName)
	
	local level = _G[unit..'_level']
	level:SetText(unitLevel)
end

--Class, UnitPortrait & powerColor Update
local function UpdateClass(unit)
	local unitClass = select(2,UnitClass(unit))
	local unitColor = RAID_CLASS_COLORS[unitClass]
	
	local classIcon = _G[unit..'_classIcon']
	classIcon:Show()
	if showClassIcons then
		classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[unitClass]))
	else
		SetPortraitTexture(classIcon, unit)
	end
	
	local power = _G[unit..'_ManaBar']
	power:SetStatusBarColor(mpColors[unitClass].r, mpColors[unitClass].g, mpColors[unitClass].b)
end

--UnitMana Update
function ArenaHandler:UpdatePower(unit)
	if not frames[unit] then return end
	local power = _G[unit..'_ManaBar']
	local powerText = _G[unit..'_framePowerText']
	power:SetMinMaxValues(0, UnitManaMax(unit))
	power:SetValue(UnitMana(unit))
	powerText:SetText(UnitMana(unit))
	UpdateClass(unit)
end

--UnitHealth Update, NameUpdate
function ArenaHandler:UNIT_HEALTH(_,unit)
	if not frames[unit] then return end
	local health = _G[unit..'_HealthBar']
	local healthText = _G[unit..'_frameHealthText']
	health:SetMinMaxValues(0, UnitHealthMax(unit))
	health:SetValue(UnitHealth(unit))
	healthText:SetText((UnitHealth(unit) > 0 and UnitHealth(unit)) or 'DEAD')
end

--Aura Update
function ArenaHandler:UNIT_AURA(_,unit)
	if not frames[unit] then return end
	for i=1,16 do
		name,_,icon,count,_,duration,endtime = UnitBuff(unit, i)	
		buff = _G[unit..'buff'..i]
		buff.Icon:SetTexture(icon or nil)
		
		if count then
			buff.Count:SetText((count > 1 and count) or '')
		else
			buff.Count:SetText('')
		end
		
		if duration and duration > 0 then
			buff.Cooldown:SetCooldown((endtime-duration), duration)
			buff.Cooldown:Show()
		else
			buff.Cooldown:Hide()
		end
	end	
	
	for j= 1, 16 do
		_,_,icon,count,_,duration,endtime = UnitDebuff(unit, j)
		debuff = _G[unit..'debuff'..j]
		debuff.Icon:SetTexture(icon or nil)

		if count then
			debuff.Count:SetText((count > 1 and count) or '')
		else
			debuff.Count:SetText('')
		end
		
		if duration and duration > 0 then
			debuff.Cooldown:SetCooldown((endtime-duration), duration)
			debuff.Cooldown:Show()
		else
			debuff.Cooldown:Hide()
		end
	end
end

--MoveDamnit
local function MoveDefaultArenaFrames(id)
	ArenaFrame = _G['ArenaEnemyFrame'..id]
	ArenaFrame:ClearAllPoints()
	ArenaFrame:SetPoint('LEFT', UIParent, 'RIGHT', 5000, 0)
end

--Hide Default ArenaFrames
local function NoMoreDefaultArenaFrames()
	for i=4,5 do
		OldArena = _G['ArenaEnemyFrame'..i]
		OldArenaPet = _G['ArenaEnemyFrame'..i..'PetFrame']
		if OldArena then
			OldArena:SetAlpha(0)
			OldArena.Show = OldArena:SetAlpha(0)
			OldArenaPet:SetAlpha(0)
			OldArenaPet.Show = OldArenaPet:SetAlpha(0)
		end
	end
end

--UpdateUnit
local function UpdateUnit(unit)
	ArenaHandler:UNIT_HEALTH(_,unit)
	ArenaHandler:UpdatePower(unit)
	ArenaHandler:UNIT_AURA(_,unit)
	UpdateName(unit)
	UpdateClass(unit)
end

--Check for active ArenaUnits and Update them
function ArenaHandler:PLAYER_ENTERING_WORLD()
	for i=1,3 do
		if UnitExists('arena'..i) then
			UpdateUnit('arena'..i)
			
			ArenaPetFrame = _G['ArenaEnemyFrame'..i..'PetFrame']
			ArenaPetFrame:SetScale(1.3)
			ArenaPetFrame:ClearAllPoints()
			ArenaPetFrame:SetPoint('RIGHT', _G['arena'..i..'_frame'], 'LEFT')
			ArenaPetFrame.SetPoint = function() end
			
			if clickThrough then
				ArenaPetFrame:EnableMouse(false)
			end
			MoveDefaultArenaFrames(i)
		end
	end
	NoMoreDefaultArenaFrames()
end

--UpdateNames
function ArenaHandler:UNIT_NAME_UPDATE()
	for i=1,3 do
		if UnitExists('arena'..i) then
			UpdateName('arena'..i)
		end
	end
end

--UpdateArenaUnits, fired if ArenaUnitsType changes e.g cleared, destroyed, seen, unseen
function ArenaHandler:ARENA_OPPONENT_UPDATE(_,unit)
	if frames[unit] then
		if UnitExists(unit) then
			UpdateUnit(unit)
		end
	end
	id = gsub(unit, '%a', '')
	MoveDefaultArenaFrames(id)
end

--Track ArenaFrame trinket / wotf usage
function ArenaHandler:UNIT_SPELLCAST_SUCCEEDED(_,unit,spellName)
	if frames[unit] then
		trinketCooldown = _G[unit..'_frameTrinketCooldown']
		for trinketName,data in pairs(trinketList) do
			if trinketName == spellName then
				trinketCooldown:SetCooldown(GetTime(),data)
			end
		end		
	end
end

--EventHandler
local function handleEvents(self,event,unit,...)
	if eventList[event] then
		self:UpdatePower(unit)
	else
		self[event](self,event,unit,...)
	end
end

--Creation of the ArenaFrames
for i=1,3 do
	CreateArenaFrame('arena'..i, x,-(i*spacing)+y)
end

--Register all necessary events
ArenaHandler:RegisterEvent('PLAYER_ENTERING_WORLD')
ArenaHandler:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
ArenaHandler:RegisterEvent('ARENA_OPPONENT_UPDATE')
ArenaHandler:RegisterEvent('UNIT_NAME_UPDATE')
ArenaHandler:RegisterEvent('UNIT_AURA')
ArenaHandler:RegisterEvent('UNIT_HEALTH')
ArenaHandler:RegisterEvent('UNIT_POWER')
ArenaHandler:RegisterEvent('UNIT_MANA')
ArenaHandler:RegisterEvent('UNIT_RAGE')
ArenaHandler:RegisterEvent('UNIT_FOCUS')
ArenaHandler:RegisterEvent('UNIT_ENERGY')
ArenaHandler:RegisterEvent('UNIT_RUNIC_POWER')
ArenaHandler:SetScript('OnEvent', handleEvents)

--Slash command to show an example of the frames. /showaf
SlashCmdList.SHOWAF = function()
	for i=1,3 do
		_G['arena'..i..'_frame']:Show()
		_G['arena'..i..'_frame'].Hide = _G['arena'..i..'_frame'].Show
		_G['arena'..i..'_name']:SetText('arena'..i)
		_G['arena'..i..'_frameHealthText']:SetText(30000)
		_G['arena'..i..'_framePowerText']:SetText(30000)
		_G['arena'..i..'_classIcon']:SetTexCoord(0, 0.25, 0, 0.25)
		_G['arena'..i..'_classIcon']:Show()
		_G['arena'..i..'_level']:SetText(80)
		_G['arena'..i..'_frameTrinketCooldown']:SetCooldown(GetTime(),120)
		for j=1,16 do
			buff = _G['arena'..i..'buff'..j]
			buff.Icon:SetTexture('Interface\\ICONS\\Spell_ChargePositive')
			
			debuff = _G['arena'..i..'debuff'..j]
			debuff.Icon:SetTexture('Interface\\ICONS\\Spell_ChargeNegative')
		end
	end
end
SLASH_SHOWAF1 = '/showaf'
