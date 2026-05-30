function PLUGIN:OnCharacterCreated(client, character)
	if (character:GetFaction() == FACTION_ALUMNO) then
		character:SetMoney(100)
	end
end
