function PLUGIN:InitializedChatClasses()
    ix.chat.Register("pointsUpdate", {
		CanHear = function(self, speaker, listener)
            return true
        end,
		deadCanChat = true,
		
		OnChatAdd = function(self, speaker, text, anonymous, data)
			local house = data and data.house
			local faction = house and ix.faction.Get(string.lower(house))
			local msgColor = faction and faction.color
			local docColor = Color(255, 145, 0) -- Faction "Docente" or "staff" color 

			chat.AddText(docColor, "[Puntos] ", msgColor, text)
		end
	})
end