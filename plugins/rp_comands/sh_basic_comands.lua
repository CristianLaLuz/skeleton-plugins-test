function PLUGIN:InitializedChatClasses()
-- /do	
	ix.chat.Register("do", {
		format = "[DO] %s: %s",
		GetColor = function(self, speaker)
			local character = IsValid(speaker) and speaker:GetCharacter()
			local faction = character and ix.faction.indices[character:GetFaction()]

			return faction and faction.color or ix.config.Get("chatColor")
		end,
		CanHear = ix.config.Get("chatRange", 280) * 2,
		prefix = {"/Do", "/DO"},
		description = "Entorno",
		indicator = "chatPerforming",
		deadCanChat = true
	})
	
-- me
	ix.chat.Register("me", {
			format = "[ME] %s: %s",
			GetColor = function(self, speaker)
				local character = IsValid(speaker) and speaker:GetCharacter()
				local faction = character and ix.faction.indices[character:GetFaction()]

				return faction and faction.color or ix.config.Get("chatColor")
			end,
			CanHear = ix.config.Get("chatRange", 280) * 2,
			prefix = {"/me", "/ME"},
			description = "Entorno",
			indicator = "chatPerforming",
			deadCanChat = true
		})
-- Dados
	ix.chat.Register("dados", {
		CanHear = ix.config.Get("chatRange", 280) * 2,
		deadCanChat = true,
		
		OnChatAdd = function(self, speaker, text, anonymous, data)
			local name = IsValid(speaker) and speaker:Name() or "Console"
			local minimum = data and data.minimum or 0
			local maximum = data and data.maximum or 100
			
			local character = IsValid(speaker) and speaker:GetCharacter()
			local faction = character and ix.faction.indices[character:GetFaction()]
			local msgColor = faction and faction.color or ix.config.Get("chatColor")
			
			chat.AddText(msgColor, string.format(
				"[Dados] %s: %s (%d-%d)",
				name,
				text,
				minimum,
				maximum
			))
		end
	})
end
-- Comandos --


-- Dados
ix.command.Add("Dados", {
	description = "Tira dados de 0 hasta el maximo indicado.",
	arguments = bit.bor(ix.type.number, ix.type.optional),
	OnRun = function(self, client, maximum)
		maximum = math.Round(maximum or 100)

		if (maximum <= 0) then
			return "@invalidArg", 1
		end

		local minimum = 0
		local result = math.random(minimum, maximum)

		ix.chat.Send(client, "dados", tostring(result), false, nil, {
			minimum = minimum,
			maximum = maximum
		})
	end
})

-- Gestion Dinero

ix.command.Add("CharGiveMoney", {
	alias = {"DarDinero", "CharDarDinero"},
	description = "Da dinero al personaje indicado.",
	adminOnly = true,
	arguments = {
		ix.type.character,
		ix.type.number
	},
	OnRun = function(self, client, target, amount)
		amount = math.Round(amount)

		if (amount <= 0) then
			return "@invalidArg", 2
		end

		target:GiveMoney(amount)

		local targetPlayer = target:GetPlayer()

		client:Notify(string.format("Has dado %s a %s.", ix.currency.Get(amount), target:GetName()))

		if (IsValid(targetPlayer)) then
			targetPlayer:Notify(string.format("Has recibido %s.", ix.currency.Get(amount)))
		end
	end
})



ix.command.Add("CharTakeMoney", {
	alias = {"QuitarDinero", "CharQuitarDinero"},
	description = "Quita dinero al personaje indicado.",
	adminOnly = true,
	arguments = {
		ix.type.character,
		ix.type.number
	},
	OnRun = function(self, client, target, amount)
		amount = math.Round(amount)

		if (amount <= 0) then
			return "@invalidArg", 2
		end

		local currentMoney = target:GetMoney()
		local taken = math.min(currentMoney, amount)

		if (taken <= 0) then
			return target:GetName().." no tiene dinero."
		end

		target:TakeMoney(taken)

		local targetPlayer = target:GetPlayer()

		client:Notify(string.format("Has quitado %s a %s.", ix.currency.Get(taken), target:GetName()))

		if (IsValid(targetPlayer)) then
			targetPlayer:Notify(string.format("Te han quitado %s.", ix.currency.Get(taken)))
		end
	end
})

ix.command.Add("Money", {
	alias = {"Dinero", "Galeones"},
	description = "Muestra cuanto dinero tiene tu personaje.",
	OnRun = function(self, client)
		local character = client:GetCharacter()

		if (!character) then
			return
		end

		client:Notify(string.format("Tienes %s.", ix.currency.Get(character:GetMoney())))
	end
})



