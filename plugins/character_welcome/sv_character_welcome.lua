function PLUGIN:PlayerLoadedCharacter(client, character)
    local name = character:GetName()
    local money = character:GetMoney()

    local currency = money == 1
        and ix.currency.singular
        or ix.currency.plural
		
	local factionName = "Ciudadano"

	if character:GetFaction() == FACTION_ALUMNO then
		factionName = "estudiante"
	end

    client:Notify(string.format(
		"Buenos días %s %s, tienes %d %s.",
		factionName,
		name,
		money,
		money == 1 and ix.currency.singular or ix.currency.plural
	))
end