-- Notify players with their character's name, money, and faction when they load into the game
function PLUGIN:PlayerLoadedCharacter(client, character)
    local name = character:GetName()
    local money = character:GetMoney()

    local factionID = character:GetFaction()

    local factionSwitch = {
        [FACTION_GRYFFINDOR] = "Estudiante",
        [FACTION_SLYTHERIN]  = "Estudiante",
        [FACTION_RAVENCLAW]  = "Estudiante",
        [FACTION_HUFFLEPUFF] = "Estudiante",
        [FACTION_ESTUDIANTE] = "Estudiante"

		--[FACTION_DOCENTE] = "Docente"
        --[FACTION_STAFF] = "Staff"
		-- Add more factions here if needed
    }

    local factionName = factionSwitch[factionID] or "Docente"

    client:Notify(string.format(
        "Buenos días %s %s, tienes %s.",
        factionName,
        name,
        ix.currency.Get(money)
    ))
end


-- Set money for new characters in the faction Estudiante
function PLUGIN:OnCharacterCreated(client, character)
	if (character:GetFaction() == FACTION_ESTUDIANTE) then
		character:SetMoney(100)
	end
end

-- Set the currency to "galeón" for singular and "galeones" for plural
function PLUGIN:InitializedPlugins()
    ix.currency.Set("G", "galeón", "galeones")
end