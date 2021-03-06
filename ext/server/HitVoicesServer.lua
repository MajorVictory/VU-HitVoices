class "HitVoicesServer"

function HitVoicesServer:__init()
	self:RegisterVars()
	self:RegisterEvents()
end

function HitVoicesServer:RegisterVars()
end

function HitVoicesServer:RegisterEvents()
	Events:Subscribe('Player:Joining', self, self.onPlayerJoining)
	Events:Subscribe('Player:Killed', self, self.onPlayerKilled)
	Events:Subscribe('Player:Chat', self, self.onPlayerChat)
	Hooks:Install('Soldier:Damage', 0, self, self.onSoldierDamage)

	for conVar, conValue in pairs(hitVoices.Config) do
		RCON:RegisterCommand('vu-hitvoices.'..conVar, RemoteCommandFlag.RequiresLogin, function(command, args, loggedIn)
			local varName = command:split('.')[2]
			
			if (args ~= nil and args[1] ~= nil) then
				hitVoices.Config[varName] = table.concat(args, ',')
			end

			hitVoices:onSetConfig(hitVoices.Config)
			NetEvents:BroadcastLocal('HitVoices:OnSetConfig', hitVoices.Config)

			return {'OK', tostring(hitVoices.Config[varName])}
		end)
	end

end

function HitVoicesServer:onPlayerJoining(name, playerGuid, ipAddress, accountGuid)
	ChatManager:Yell(name..' Joins the Battle!', 30)
	NetEvents:BroadcastLocal('HitVoices:OnChangeCharacter', name, hitVoices:getCharacter(name))
end

function HitVoicesServer:onSoldierDamage(hookCtx, soldier, info, giverInfo)
	-- player took damage from anything
	if (soldier ~= nil and soldier.player ~= nil and info.damage ~= nil and info.damage > 0) then
		NetEvents:BroadcastLocal('HitVoices:OnDamageTaken', soldier.player.name, info.damage, info.boneIndex == 1)
	end
	-- we only care about player to player damage
	if giverInfo ~= nil and giverInfo.giver ~= nil and
		soldier ~= nil and soldier.player ~= nil and
		info.damage ~= nil and info.damage > 0 then
		if (giverInfo.giver.id ~= soldier.player.id) then -- player1 on player2 damage
			NetEvents:BroadcastLocal('HitVoices:OnDamageGiven', giverInfo.giver.name, soldier.player.name, info.damage, info.boneIndex == 1)
		end
	end
	hookCtx:Pass(soldier, info, giverInfo)
end

function HitVoicesServer:onPlayerKilled(player, inflictor, position, weapon, isRoadKill, isHeadShot, wasVictimInReviveState, info)
	-- check for melee kill first
	if (player ~= nil and inflictor ~= nil) then
		local isMelee = false
		if (info.weaponUnlock ~= nil) then
			local weaponId = _G[info.weaponUnlock.typeInfo.name](info.weaponUnlock).debugUnlockId
			if (weaponId == 'U_Knife_Razor' or weaponId == 'U_Knife') then
				isMelee = true
			end
		end
		NetEvents:BroadcastLocal('HitVoices:OnPlayerKilled', player.name, inflictor.name, isMelee)
	end

	-- possible bot kill
	if (player ~= nil and inflictor == nil) then
		NetEvents:BroadcastLocal('HitVoices:OnPlayerKilled', player.name, '', false)
	end
end

function HitVoicesServer:onPlayerChat(player, recipientMask, message)

	if player == nil or message == nil then
		return
	end

	local parts = string.lower(message):split(' ')
	if (parts ~= nil and #parts > 0) then
		if (parts[1] == '!voice' and parts[2] ~= nil) then

			local characterName = hitVoices:isValidName(parts[2])

			if (characterName ~= false) then
				NetEvents:BroadcastLocal('HitVoices:OnChangeCharacter', player.name, characterName)
				return
			end
			ChatManager:SendMessage("Choices are: "..hitVoices.showNameChoices, player)
			return
		elseif (#parts == 1 and parts[1] == '!voice') then
			ChatManager:SendMessage("Choices are: "..hitVoices.showNameChoices, player)
		end

		if (parts[1] ~= nil) then
			local characterName = hitVoices:isValidName(parts[1]:sub(2))
			if (characterName ~= false) then
				NetEvents:BroadcastLocal('HitVoices:OnChangeCharacter', player.name, characterName)
				return
			end
		end
		
	end
end

return HitVoicesServer()