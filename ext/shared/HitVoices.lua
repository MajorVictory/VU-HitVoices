class "HitVoices"

function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

function HitVoices:__init()
	self:RegisterVars()
	self:RegisterEvents()
end

function HitVoices:RegisterVars()

	self.Config = {}
	self.characterLookup = {}
	self.showNameChoices = ''
	self.showNameChoicesConsole = ''

	-- defaults
	self:onSetConfig({
		['Voices'] = "Captain,Combine,Ganon,Incineroar,Peach,Wolf,Fox,Luigi,Zombie1,Zombie2,Zombie3,Off",
		['BotVoices'] = "Zombie1,Zombie2,Zombie3"
	})
end

function HitVoices:RegisterEvents()
	NetEvents:Subscribe('HitVoices:OnGetConfig', self, self.onGetConfig)
	NetEvents:Subscribe('HitVoices:OnSetConfig', self, self.onSetConfig)
	NetEvents:Subscribe('HitVoices:OnChangeCharacter', self, self.setCharacter)
end

function HitVoices:onGetConfig(player)
	print('HitVoices:onGetConfig: '..player.name)
	NetEvents:SendToLocal('HitVoices:OnSetConfig', player, self.Config, self.characterLookup)
end

function HitVoices:onSetConfig(configData, lookupData)
	print('HitVoices:onSetConfig')
	if (configData ~= nil) then
		self.Config = configData
		self.validNames = self.Config.Voices:split(',')
		self.botVoices = self.Config.BotVoices:split(',')

		self.showNameChoices = ''
		self.showNameChoicesConsole = ''

		for i=1, #self.validNames do
			if (self.showNameChoices:len() > 0) then
				self.showNameChoices = self.showNameChoices..', '
			end
			if (self.showNameChoicesConsole:len() > 0) then
				self.showNameChoicesConsole = self.showNameChoicesConsole..', '
			end
			self.showNameChoices = self.showNameChoices..'!'..self.validNames[i]
			self.showNameChoicesConsole = self.showNameChoicesConsole..self.validNames[i]
		end
	end
	if (lookupData ~= nil) then
		self.characterLookup = lookupData
	end
end

function HitVoices:setCharacter(playerID, characterName)
	self.characterLookup[playerID] = characterName
end

function HitVoices:getCharacter(playerID)
	if (self.characterLookup[playerID] == nil) then
		if (hitVoices:isBot(playerID)) then
			self.characterLookup[playerID] = self.botVoices[math.random(1, #self.botVoices)]:lower()
		else
			self.characterLookup[playerID] = self.validNames[math.random(1, #self.validNames-1)]:lower()
		end
	end
	return self.characterLookup[playerID]
end

function HitVoices:isValidName(characterName)
	local characterName = characterName:lower()
	for i=1, #self.validNames do
		-- exact match or partial match
		if (characterName == self.validNames[i]:lower() or self.validNames[i]:lower():starts(characterName)) then
			return self.validNames[i]:lower()
		end
	end
	return false
end

function HitVoices:isBot(playerID)
	local player = PlayerManager:GetPlayerByName(playerID)
	if (player ~= nil) then
		return player.guid == nil and player.accountGuid == nil and player.ip == nil
	end
	return false
end

return HitVoices()