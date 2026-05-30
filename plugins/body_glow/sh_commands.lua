local PLUGIN = PLUGIN

if (SERVER) then
	util.AddNetworkString("ixBodyGlowOpenMenu")
	util.AddNetworkString("ixBodyGlowSend")

	net.Receive("ixBodyGlowSend", function(len, client)
		local action = net.ReadString()
		local targetName = net.ReadString()
		local data = net.ReadTable()

		if (action == "applySelf") then
			local glowData, fault = PLUGIN:NormalizeBodyGlowData(data)

			if (!glowData) then
				client:Notify(fault or "Datos invalidos.")
				return
			end

			PLUGIN:ApplyBodyGlow(client, client, glowData)
			return
		end

		local target = PLUGIN:FindBodyGlowTarget(targetName)

		if (!IsValid(target)) then
			client:Notify("Jugador no encontrado.")
			return
		end

		if (action == "applyTarget") then
			local glowData, fault = PLUGIN:NormalizeBodyGlowData(data)

			if (!glowData) then
				client:Notify(fault or "Datos invalidos.")
				return
			end

			PLUGIN:ApplyBodyGlow(client, target, glowData)
		elseif (action == "clearSelf") then
			PLUGIN:ClearBodyGlow(client, client, data.fadeOut)
		elseif (action == "clearTarget") then
			PLUGIN:ClearBodyGlow(client, target, data.fadeOut)
		end
	end)
end

local function ParseArguments(text)
	local arguments = {}
	local current = ""
	local quoted = false

	for i = 1, #text do
		local character = string.sub(text, i, i)

		if (character == "\"") then
			quoted = !quoted
		elseif (character == " " and !quoted) then
			if (current != "") then
				arguments[#arguments + 1] = current
				current = ""
			end
		else
			current = current .. character
		end
	end

	if (current != "") then
		arguments[#arguments + 1] = current
	end

	return arguments
end

function PLUGIN:NormalizeBodyGlowData(data)
	data = data or {}

	local color = data.color or {}
	local offset = data.offset or {}

	local size = math.Clamp(math.Round(tonumber(data.size or data[1]) or 28), 8, 128)
	local red = math.Clamp(math.Round(tonumber(data.red or color[1] or color.r) or 255), 0, 255)
	local green = math.Clamp(math.Round(tonumber(data.green or color[2] or color.g) or 220), 0, 255)
	local blue = math.Clamp(math.Round(tonumber(data.blue or color[3] or color.b) or 160), 0, 255)
	local blink = math.Clamp(tonumber(data.blink or data[5]) or 0, 0, 10)
	local bodyPart = self:GetBodyGlowPartKey(data.bodyPart or data[6])
	local offsetX = math.Clamp(math.Round(tonumber(data.offsetX or offset.x or data[7]) or 0), -64, 64)
	local offsetY = math.Clamp(math.Round(tonumber(data.offsetY or offset.y or data[8]) or 0), -64, 64)
	local offsetZ = math.Clamp(math.Round(tonumber(data.offsetZ or offset.z or data[9]) or 0), -64, 64)
	local style = self:GetBodyGlowStyleKey(data.style or data[10])
	local fadeStart = math.Clamp(math.Round(tonumber(data.fadeStart or data[11]) or 700), 0, 5000)
	local maxDistance = math.Clamp(math.Round(tonumber(data.maxDistance or data[12]) or 1000), 1, 5000)

	-- modelScale: optional value supplied by client so server can apply offsets correctly
	local modelScale = math.Clamp(tonumber(data.modelScale) or 1, 0.01, 5)

	if (fadeStart > maxDistance) then
		fadeStart = maxDistance
	end

	if (!self.bodyGlowParts[bodyPart]) then
		return nil, "Parte no valida. Usa: chest, head, leftHand, rightHand, leftFoot o rightFoot."
	end

	if (!style) then
		return nil, "Estilo no valido. Usa: default, orange, red, core, core2, flare, flare2, phys, phys2, pickup o redmp."
	end

	return {
		size = size,
		color = {red, green, blue},
		blink = blink,
		bodyPart = bodyPart,
		offset = {
			x = offsetX,
			y = offsetY,
			z = offsetZ
		},
		style = style,
		fadeStart = fadeStart,
		maxDistance = maxDistance
		,
		modelScale = modelScale
	}

end

function PLUGIN:ApplyBodyGlow(client, target, data)
	target:SetNetVar("bodyGlow", data)

	local red, green, blue = data.color[1], data.color[2], data.color[3]
	local message = string.format(
		"Brillo corporal activado. Tamano: %d, color: %d %d %d, parpadeo: %.1f, parte: %s, offset: %.1f %.1f %.1f, estilo: %s, distancia: %d-%d.",
		data.size,
		red,
		green,
		blue,
		data.blink,
		data.bodyPart,
		data.offset.x,
		data.offset.y,
		data.offset.z,
		data.style,
		data.fadeStart,
		data.maxDistance
	)

	if (target == client) then
		client:Notify(message)
	else
		client:Notify(string.format("Has activado el brillo corporal de %s.", target:Name()))
		target:Notify(message) -- no hace falta
	end
end

function PLUGIN:ClearBodyGlow(client, target, duration)
	duration = math.Clamp(math.Round(tonumber(duration) or 0), 0, 10)

	if (duration <= 0) then
		target:SetNetVar("bodyGlow", nil)
	else
		local glowData = target:GetNetVar("bodyGlow")

		if (!istable(glowData)) then
			target:SetNetVar("bodyGlow", nil)
		else
			local fadeOutEnd = CurTime() + duration
			local newGlowData = table.Copy(glowData)

			newGlowData.fadeOutEnd = fadeOutEnd
			newGlowData.fadeOutDuration = duration

			target:SetNetVar("bodyGlow", newGlowData)

			timer.Simple(duration, function()
				if (IsValid(target)) then
					local currentGlow = target:GetNetVar("bodyGlow")

					if (istable(currentGlow) and currentGlow.fadeOutEnd == fadeOutEnd) then
						target:SetNetVar("bodyGlow", nil)
					end
				end
			end)
		end
	end

	if (target == client) then
		if (duration > 0) then
			client:Notify(string.format("Brillo corporal se desvanecerá en %.1f segundos.", duration))
		else
			client:Notify("Brillo corporal desactivado.")
		end
	else
		if (duration > 0) then
			client:Notify(string.format("Has desactivado el brillo corporal de %s, se desvanecerá en %.1f segundos.", target:Name(), duration))
			target:Notify(string.format("Tu brillo corporal se desvanecerá en %.1f segundos.", duration))
		else
			client:Notify(string.format("Has desactivado el brillo corporal de %s.", target:Name()))
			target:Notify("Brillo corporal desactivado.")
		end
	end
end

function PLUGIN:FindBodyGlowTarget(text)
	if (!text or text == "") then
		return nil
	end

	text = string.lower(text)

	for _, target in ipairs(player.GetAll()) do
		local character = target:GetCharacter()
		local characterName = character and string.lower(character:GetName()) or ""
		local playerName = string.lower(target:Name())

		if (characterName == text or playerName == text) then
			return target
		end
	end

	for _, target in ipairs(player.GetAll()) do
		local character = target:GetCharacter()
		local characterName = character and string.lower(character:GetName()) or ""
		local playerName = string.lower(target:Name())

		if (string.find(characterName, text, 1, true) or string.find(playerName, text, 1, true)) then
			return target
		end
	end
end

ix.command.Add("BodyGlow", {
	alias = {"LuzCuerpo"},
	description = "Gestiona el brillo visual del cuerpo.",
	privilege = "Manage Body Glow",
	adminOnly = true,
	arguments = bit.bor(ix.type.text, ix.type.optional),
	OnRun = function(self, client, text)
		local arguments = ParseArguments(text or "")
		local action = string.lower(arguments[1] or "on")

		if (action == "on" or action == "set") then
			local data, fault = PLUGIN:NormalizeBodyGlowData({
				size = arguments[2],
				red = arguments[3],
				green = arguments[4],
				blue = arguments[5],
				blink = arguments[6],
				bodyPart = arguments[7],
				offsetX = arguments[8],
				offsetY = arguments[9],
				offsetZ = arguments[10],
				style = arguments[11],
				fadeStart = arguments[12],
				maxDistance = arguments[13]
			})

			if (!data) then
				return fault
			end

			PLUGIN:ApplyBodyGlow(client, client, data)
		elseif (action == "off") then
			local duration = arguments[2]
			PLUGIN:ClearBodyGlow(client, client, duration)
		elseif (action == "give") then
			local target = PLUGIN:FindBodyGlowTarget(arguments[2])

			if (!IsValid(target)) then
				return "Jugador no encontrado."
			end

			local data, fault = PLUGIN:NormalizeBodyGlowData({
				size = arguments[3],
				red = arguments[4],
				green = arguments[5],
				blue = arguments[6],
				blink = arguments[7],
				bodyPart = arguments[8],
				offsetX = arguments[9],
				offsetY = arguments[10],
				offsetZ = arguments[11],
				style = arguments[12],
				fadeStart = arguments[13],
				maxDistance = arguments[14]
			})

			if (!data) then
				return fault
			end

			PLUGIN:ApplyBodyGlow(client, target, data)
		elseif (action == "clear") then
			local target = PLUGIN:FindBodyGlowTarget(arguments[2])

			if (!IsValid(target)) then
				return "Jugador no encontrado."
			end

			local duration = arguments[3]
			PLUGIN:ClearBodyGlow(client, target, duration)
		else
			return "Uso: /BodyGlow on [tamano] [rojo] [verde] [azul] [parpadeo] [parte] [x] [y] [z] [estilo] [fadeStart] [maxDistance], /BodyGlow off [fadeOut], /BodyGlow give \"jugador\" [tamano] [rojo] [verde] [azul] [parpadeo] [parte] [x] [y] [z] [estilo] [fadeStart] [maxDistance], /BodyGlow clear \"jugador\" [fadeOut]"
		end
	end
})

ix.command.Add("BodyGlowMenu", {
	alias = {"LuzCuerpoMenu"},
	description = "Abrir la interfaz de configuracion de BodyGlow.",
	privilege = "Manage Body Glow",
	adminOnly = true,
	OnRun = function(self, client)
		net.Start("ixBodyGlowOpenMenu")
		net.Send(client)
	end
})
