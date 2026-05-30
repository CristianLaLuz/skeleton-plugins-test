local PLUGIN = PLUGIN
local glowMaterials = {}
local defaultGlowColor = Color(255, 220, 160)
local defaultGlowSize = 28

local function GetBodyGlowMaterial(style)
	style = PLUGIN:GetBodyGlowStyleKey(style) or "default"

	if (!glowMaterials[style]) then
		glowMaterials[style] = Material(PLUGIN.bodyGlowStyles[style] or PLUGIN.bodyGlowStyles.default)
	end

	return glowMaterials[style]
end

local function HasTruthyState(client, getterName, keys)
	local getter = client[getterName]

	if (!getter) then
		return false
	end

	for _, key in ipairs(keys or {}) do
		local value = getter(client, key)

		if (value == true or value == 1 or value == "1" or value == "true") then
			return true
		end
	end

	return false
end

function PLUGIN:ShouldHideBodyGlow(client)
	local visibility = self.bodyGlowVisibility or {}

	if (visibility.hideWhenNoDraw and client:GetNoDraw()) then
		return true
	end

	if (visibility.hideWhenTransparent) then
		local color = client:GetColor()
		local threshold = visibility.transparentAlphaThreshold or 250

		if (color.a < threshold) then
			return true
		end
	end

	if (HasTruthyState(client, "GetNetVar", visibility.netVars)) then
		return true
	end

	if (HasTruthyState(client, "GetLocalVar", visibility.localVars)) then
		return true
	end

	if (HasTruthyState(client, "GetNWBool", visibility.nwBools)) then
		return true
	end

	return false
end

local function GetBodyGlowFallback(client, part)
	if (part == "head") then
		return client:EyePos() + client:GetForward() * 4
	elseif (part == "lefthand") then
		return client:WorldSpaceCenter() - client:GetRight() * 16
	elseif (part == "righthand") then
		return client:WorldSpaceCenter() + client:GetRight() * 16
	elseif (part == "leftfoot") then
		return client:GetPos() - client:GetRight() * 6 + Vector(0, 0, 4)
	elseif (part == "rightfoot") then
		return client:GetPos() + client:GetRight() * 6 + Vector(0, 0, 4)
	end

	local mins, maxs = client:OBBMins(), client:OBBMaxs()
	local height = Lerp(0.62, mins.z, maxs.z)

	return client:LocalToWorld(Vector(0, 0, height)) + client:GetForward() * 6
end

local function ApplyBodyGlowOffset(client, position, offset, modelScale)
	if (!istable(offset)) then
		return position
	end

	local x = tonumber(offset.x) or 0
	local y = tonumber(offset.y) or 0
	local z = tonumber(offset.z) or 0

	modelScale = tonumber(modelScale) or 1

	return position + client:GetRight() * ((x / 6) * modelScale) + client:GetForward() * ((y / 6) * modelScale) + client:GetUp() * ((z / 6) * modelScale)
end

local function GetBodyGlowPosition(client, part, offset, modelScale)
	part = PLUGIN:GetBodyGlowPartKey(part)

	local partData = PLUGIN.bodyGlowParts[part] or PLUGIN.bodyGlowParts.chest

	if (client == LocalPlayer() and !client:ShouldDrawLocalPlayer()) then
		return ApplyBodyGlowOffset(client, GetBodyGlowFallback(client, part), offset, modelScale)
	end

	client:SetupBones()

	for _, boneName in ipairs(partData.bones) do
		local bone = client:LookupBone(boneName)

		if (bone) then
			local matrix = client:GetBoneMatrix(bone)

			if (matrix) then
				return ApplyBodyGlowOffset(client, matrix:GetTranslation() + client:GetForward() * 4, offset, modelScale)
			end

			local position = client:GetBonePosition(bone)

			if (position and position != vector_origin) then
				return ApplyBodyGlowOffset(client, position + client:GetForward() * 4, offset, modelScale)
			end
		end
	end

	return ApplyBodyGlowOffset(client, GetBodyGlowFallback(client, part), offset, modelScale)
end

function PLUGIN:PostDrawTranslucentRenderables()
	for _, client in ipairs(player.GetAll()) do
		local glowData = client:GetNetVar("bodyGlow")

		if (glowData and client:Alive() and !client:IsDormant() and !PLUGIN:ShouldHideBodyGlow(client)) then
			local size = defaultGlowSize
			local color = defaultGlowColor
			local blink = 0
			local bodyPart = "chest"
			local style = "default"
			local fadeStart = 700
			local maxDistance = 1000
			local offset
	            local modelScale = 1

			if (istable(glowData)) then
				size = glowData.size or size
				blink = glowData.blink or blink
				bodyPart = glowData.bodyPart or bodyPart
				style = glowData.style or style
				fadeStart = glowData.fadeStart or fadeStart
				maxDistance = glowData.maxDistance or maxDistance
				offset = glowData.offset

				if (istable(glowData.color)) then
					color = Color(glowData.color[1] or 255, glowData.color[2] or 220, glowData.color[3] or 160)
				end

				modelScale = tonumber(glowData.modelScale) or modelScale
			end

			local position = GetBodyGlowPosition(client, bodyPart, offset, modelScale)
			local distance = LocalPlayer():GetPos():Distance(position)

			if (distance > maxDistance) then
				continue
			end

			if (maxDistance > fadeStart and distance > fadeStart) then
				local fade = 1 - ((distance - fadeStart) / (maxDistance - fadeStart))

				color = Color(color.r, color.g, color.b, math.Clamp(color.a * fade, 0, 255))
			end

			if (glowData.fadeOutEnd) then
				local remaining = glowData.fadeOutEnd - CurTime()

				if (remaining <= 0) then
					continue
				end

				if (glowData.fadeOutDuration and glowData.fadeOutDuration > 0) then
					local fade = math.Clamp(remaining / glowData.fadeOutDuration, 0, 1)

					size = size * fade
				end
			end

			if (blink > 0) then
				local pulse = (math.sin(CurTime() * math.pi * 2 * blink) + 1) * 0.5
				local alpha = color.a

				size = size * Lerp(pulse, 0.35, 1)
				color = Color(color.r, color.g, color.b, math.Clamp(Lerp(pulse, alpha * 0.27, alpha), 0, 255))
			end

			render.SetMaterial(GetBodyGlowMaterial(style))
			render.DrawSprite(position, size, size, color)
		end
	end
end
