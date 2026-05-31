function PLUGIN:InitializedChatClasses()
    ix.chat.Register("sortinghat", {
		CanHear = function(self, speaker, listener)
            return listener == speaker
            -- add admin group or faction staff
        end,
		deadCanChat = true,
		
		OnChatAdd = function(self, speaker, text, anonymous, data)

			local character = IsValid(speaker) and speaker:GetCharacter()
			local faction = character and ix.faction.indices[character:GetFaction()]
			local msgColor = faction and faction.color or ix.config.Get("chatColor")
			
			chat.AddText(msgColor, "[Sombrero] ", text)
		end
	})
end