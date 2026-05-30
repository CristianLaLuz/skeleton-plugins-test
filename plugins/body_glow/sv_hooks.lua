function PLUGIN:PlayerLoadedCharacter(client, character, oldCharacter)
	if (oldCharacter and client:GetNetVar("bodyGlow")) then
		client:SetNetVar("bodyGlow", nil)
	end
end
