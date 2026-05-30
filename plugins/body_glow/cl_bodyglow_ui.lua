local PLUGIN = PLUGIN

local function CreateBodyGlowMenu()
	if (IsValid(PLUGIN.bodyGlowMenu)) then
		PLUGIN.bodyGlowMenu:Remove()
	end

	local partCombo, styleCombo
	local frame = vgui.Create("DFrame")
	frame:SetTitle("")
	frame:SetSize(920, 520)
	frame:Center()
	frame:MakePopup()
	frame:SetDeleteOnClose(true)
	frame.Paint = function(panel, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(14, 16, 20, 245))
		draw.RoundedBoxEx(8, 0, 0, w, 32, Color(70, 160, 255, 200), true, true, false, false)
	end

	local titleLabel = vgui.Create("DLabel", frame)
	titleLabel:SetText("Configuración BodyGlow")
	titleLabel:SetFont("DermaLarge")
	titleLabel:SetTextColor(Color(245, 245, 245))
	titleLabel:SizeToContents()
	titleLabel:SetPos(14, 8)
	local mainPanel = vgui.Create("DPanel", frame)
	mainPanel:Dock(FILL)
	mainPanel:DockPadding(8, 8, 8, 8)

	local leftPanel = vgui.Create("DPanel", mainPanel)
	leftPanel:Dock(LEFT)
	leftPanel:SetWide(320)
	leftPanel:DockPadding(12, 12, 12, 12)
	leftPanel.Paint = function(panel, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(22, 24, 28, 235))
		draw.RoundedBoxEx(8, 0, 0, w, 4, Color(70, 160, 255, 200), true, true, false, false)
	end

	local middlePanel = vgui.Create("DPanel", mainPanel)
	middlePanel:Dock(LEFT)
	middlePanel:SetWide(260)
	middlePanel:DockPadding(10, 10, 10, 10)
	middlePanel.Paint = function(panel, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(22, 24, 28, 235))
		draw.RoundedBoxEx(8, 0, 0, w, 4, Color(70, 160, 255, 200), true, true, false, false)
	end

	local rightPanel = vgui.Create("DPanel", mainPanel)
	rightPanel:Dock(FILL)
	rightPanel:DockPadding(10, 10, 10, 10)
	rightPanel.Paint = function(panel, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(22, 24, 28, 235))
		draw.RoundedBoxEx(8, 0, 0, w, 4, Color(70, 160, 255, 200), true, true, false, false)
	end

	local leftTitle = vgui.Create("DLabel", leftPanel)
	leftTitle:SetText("Vista previa del modelo")
	leftTitle:Dock(TOP)
	leftTitle:SetFont("DermaDefaultBold")
	leftTitle:SetTall(24)
	leftTitle:SetTextColor(Color(240, 240, 240))

	local modelPanel = vgui.Create("DModelPanel", leftPanel)
	modelPanel:Dock(FILL)
	modelPanel:SetFOV(50)
	modelPanel:SetModel(LocalPlayer():GetModel() or "models/player/kleiner.mdl")
	modelPanel.PreviewGlowData = {
		size = 28,
		color = Color(255, 220, 160),
		blink = 0,
		bodyPart = "chest",
		style = "default",
		offset = {x = 0, y = 0, z = 0}
	}
	modelPanel.CameraTarget = Vector(0, 0, 40)
	modelPanel.CameraYaw = 45
	modelPanel.CameraPitch = 20
	modelPanel.CameraDistance = 70
	modelPanel.Dragging = false

local function GetPreviewBodyGlowFallback(ent, part)
	if (!IsValid(ent)) then
		return nil
	end

	if (part == "head") then
		return ent:EyePos() + ent:GetForward() * 4
	elseif (part == "lefthand") then
		return ent:WorldSpaceCenter() - ent:GetRight() * 16
	elseif (part == "righthand") then
		return ent:WorldSpaceCenter() + ent:GetRight() * 16
	elseif (part == "leftfoot") then
		return ent:GetPos() - ent:GetRight() * 6 + Vector(0, 0, 4)
	elseif (part == "rightfoot") then
		return ent:GetPos() + ent:GetRight() * 6 + Vector(0, 0, 4)
	end

	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	local height = Lerp(0.62, mins.z, maxs.z)

	return ent:LocalToWorld(Vector(0, 0, height)) + ent:GetForward() * 6
end

local function ApplyPreviewOffset(ent, position, offset)
	if (!IsValid(ent) or !istable(offset)) then
		return position
	end

	local x = tonumber(offset.x) or 0
	local y = tonumber(offset.y) or 0
	local z = tonumber(offset.z) or 0

	local scale = 1
	if (ent.GetModelScale) then
		local ok, s = pcall(function() return ent:GetModelScale() end)
		if (ok and tonumber(s)) then scale = tonumber(s) end
	end

	return position + ent:GetRight() * ((x / 6) * scale) + ent:GetForward() * ((y / 6) * scale) + ent:GetUp() * ((z / 6) * scale)
end

local function GetPreviewBodyGlowPosition(ent, part, offset)
	if (!IsValid(ent)) then
		return nil
	end

	part = PLUGIN:GetBodyGlowPartKey(part or "chest")
	local partData = PLUGIN.bodyGlowParts[part] or PLUGIN.bodyGlowParts.chest

	ent:SetupBones()

	for _, boneName in ipairs(partData.bones) do
		local bone = ent:LookupBone(boneName)

		if (bone) then
			local matrix = ent:GetBoneMatrix(bone)

			if (matrix) then
				return ApplyPreviewOffset(ent, matrix:GetTranslation() + ent:GetForward() * 4, offset)
			end

			local position = ent:GetBonePosition(bone)

			if (position and position != vector_origin) then
				return ApplyPreviewOffset(ent, position + ent:GetForward() * 4, offset)
			end
		end
	end

	return ApplyPreviewOffset(ent, GetPreviewBodyGlowFallback(ent, part), offset)
end

-- WorldToModelPanel removed: using camera projection via cam.Start3D + Vector:ToScreen()

function modelPanel:GetPreviewPosition()
	local preview = self.PreviewGlowData or {}
	return GetPreviewBodyGlowPosition(self.Entity, preview.bodyPart, preview.offset)
end

function modelPanel:UpdateCamera()
	local target = self.CameraTarget or Vector(0, 0, 40)
	local yaw = math.rad(self.CameraYaw or 0)
	local pitch = math.rad(self.CameraPitch or 0)
	local dist = self.CameraDistance or 70

	local offset = Vector(math.cos(yaw) * math.cos(pitch), math.sin(yaw) * math.cos(pitch), math.sin(pitch)) * dist
	local camPos = target + offset

	self:SetCamPos(camPos)
	self:SetLookAt(target)

	self.CameraPos = camPos
	self.LookAt = target
end

function modelPanel:LayoutEntity(ent)
	return
end

function modelPanel:OnMousePressed(key)
	if (key == MOUSE_LEFT) then
		self.Dragging = true
		self.DragStartX = gui.MouseX()
		self.DragStartY = gui.MouseY()
		self.StartYaw = self.CameraYaw
		self.StartPitch = self.CameraPitch
	end
end

function modelPanel:OnMouseReleased(key)
	if (key == MOUSE_LEFT) then
		self.Dragging = false
	end
end

function modelPanel:OnCursorMoved(x, y)
	if (self.Dragging) then
		local dx = gui.MouseX() - self.DragStartX
		local dy = gui.MouseY() - self.DragStartY
		self.CameraYaw = self.StartYaw - dx * 0.5
		self.CameraPitch = math.Clamp(self.StartPitch + dy * 0.35, -80, 80)
		self:UpdateCamera()
	end
end

function modelPanel:OnMouseWheeled(delta)
	self.CameraDistance = math.Clamp(self.CameraDistance - delta * 6, 30, 180)
	self:UpdateCamera()
	return true
end

	modelPanel.Paint = function(panel, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(20, 22, 26, 235))
		DModelPanel.Paint(panel, w, h)

	local preview = panel.PreviewGlowData or {}
	local color = Color(255, 220, 160)

	if (istable(preview.color)) then
		color = Color(preview.color[1] or 255, preview.color[2] or 220, preview.color[3] or 160, preview.color[4] or 255)
	elseif (IsColor(preview.color)) then
		color = preview.color
	end

	local size = math.Clamp(preview.size or 28, 8, 200)

	local position = panel.GetPreviewPosition and panel:GetPreviewPosition() or nil
	if (position) then
		local camPos = panel.CameraPos
		local lookAt = panel.LookAt
		local fov = panel.GetFOV and panel:GetFOV(panel) or panel.FOV or 45

		if (camPos and lookAt) then
			local vx, vy = panel:LocalToScreen(0, 0)
			cam.Start3D(camPos, (lookAt - camPos):Angle(), fov, vx, vy, w, h)
			local screenPos = position:ToScreen()

			-- choose additive sprite material by style (additive helps tinting)
			local style = panel.PreviewGlowData and panel.PreviewGlowData.style or PLUGIN.bodyGlowLastStyle or "default"
			local matName = "sprites/light_glow02"
			if (style == "soft") then matName = "sprites/glow04" end
			if (style == "ring") then matName = "particle/particle_ring_1" end

			-- try to load chosen material, fallback to a known sprite if missing
			local okMat, glowMat = pcall(function() return Material(matName) end)
			if (not okMat or not glowMat) then
				okMat, glowMat = pcall(function() return Material("sprites/light_glow02") end)
				matName = "sprites/light_glow02"
			end

			-- compute blink alpha modulation (shared for sprite and overlay)
			local baseA = math.Clamp(color.a or 180, 40, 220)
			local blink = panel.PreviewGlowData and tonumber(panel.PreviewGlowData.blink) or 0
			local alpha = baseA
			if (blink and blink > 0) then
				alpha = math.max(8, math.floor(baseA * (0.5 + 0.5 * math.sin(RealTime() * blink * math.pi))))
			end

			if (okMat and glowMat) then
				render.SetMaterial(glowMat)
				render.DrawSprite(position, math.Clamp(size / 6, 4, 64), math.Clamp(size / 6, 4, 64), Color(color.r, color.g, color.b, alpha))
			else
				-- fallback to simple 2D draw if material failed (uses same alpha)
				surface.SetDrawColor(color.r, color.g, color.b, alpha)
				surface.DrawCircle(screenPos.x, screenPos.y, math.Clamp(size / 12, 4, 16), Color(color.r, color.g, color.b, alpha))
			end

			cam.End3D()

			if (screenPos) then
				-- convert screen coords returned by ToScreen (which are relative to the cam viewport origin vx,vy)
				local lx = screenPos.x - vx
				local ly = screenPos.y - vy
				local drawAlpha = alpha
				if (not screenPos.visible) then
					-- if the point is offscreen, attenuate overlay so user sees it's out of view
					drawAlpha = math.floor(drawAlpha * 0.45)
					-- clamp inside panel for visibility
					lx = math.Clamp(lx, 8, w - 8)
					ly = math.Clamp(ly, 8, h - 8)
				end
				-- draw overlay according to style using shared alpha
				if (style == "ring") then
					surface.SetDrawColor(255, 255, 255, math.min(200, drawAlpha))
					surface.DrawOutlinedRect(lx - math.Clamp(size / 8, 4, 32), ly - math.Clamp(size / 8, 4, 32), math.Clamp(size / 4, 8, 64), math.Clamp(size / 4, 8, 64))
				else
					surface.SetDrawColor(color.r, color.g, color.b, drawAlpha)
					if (style == "soft") then
						surface.DrawCircle(lx, ly, math.Clamp(size / 6, 8, 96), Color(color.r, color.g, color.b, math.floor(drawAlpha * 0.6)))
					else
						surface.DrawCircle(lx, ly, math.Clamp(size / 12, 4, 16), Color(color.r, color.g, color.b, drawAlpha))
					end
				end
			end

			-- Debug overlay: show entity validity, world pos and screen coords
			if (panel.ShowDebug) then
				local entValid = IsValid(panel.Entity)
				local posStr = "nil"
				if position then posStr = string.format("%.2f, %.2f, %.2f", position.x, position.y, position.z) end
				local sx, sy, svis = 0, 0, false
				if screenPos then sx, sy, svis = screenPos.x, screenPos.y, screenPos.visible end
				draw.SimpleText(string.format("ent=%s pos=%s scr=%.1f,%.1f vis=%s", tostring(entValid), posStr, sx, sy, tostring(svis)), "DermaDefault", 8, 8, Color(255,255,255,220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				local col = panel.PreviewGlowData and panel.PreviewGlowData.color or Color(0,0,0)
				local st = panel.PreviewGlowData and tostring(panel.PreviewGlowData.style) or ""
				local bl = panel.PreviewGlowData and tostring(panel.PreviewGlowData.blink) or "0"
				draw.SimpleText(string.format("col=%d,%d,%d st=%s blink=%s", col.r or 0, col.g or 0, col.b or 0, st, bl), "DermaDefault", 8, 20, Color(255,255,255,220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

				if (screenPos and screenPos.visible) then
					surface.SetDrawColor(255, 80, 80, 220)
					surface.DrawLine(screenPos.x - 6, screenPos.y, screenPos.x + 6, screenPos.y)
					surface.DrawLine(screenPos.x, screenPos.y - 6, screenPos.x, screenPos.y + 6)
				end
			end
		end
	end

		surface.SetDrawColor(color.r, color.g, color.b, color.a or 180)
		surface.DrawRect(w - 96, 12, 84, 28)
		surface.SetDrawColor(255, 255, 255, 120)
		surface.DrawOutlinedRect(w - 96, 12, 84, 28)

		draw.SimpleText(string.format("Parte: %s", preview.bodyPart or "chest"), "DermaDefaultBold", w - 12, 12, Color(235, 235, 235), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		draw.SimpleText(string.format("Estilo: %s", preview.style or "default"), "DermaDefault", w - 12, 28, Color(220, 220, 220), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		draw.SimpleText(string.format("Tamaño: %d", size), "DermaDefault", w - 12, 44, Color(220, 220, 220), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		draw.SimpleText("Click y arrastra para rotar, rueda para zoom", "DermaDefault", 8, h - 14, Color(200, 200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
	end

local middleTitle = vgui.Create("DLabel", middlePanel)
middleTitle:SetText("Seleccionar jugador")
middleTitle:Dock(TOP)
middleTitle:SetFont("DermaDefaultBold")
middleTitle:SetTall(24)
middleTitle:SetTextColor(Color(240, 240, 240))

local targetSearch = vgui.Create("DTextEntry", middlePanel)
targetSearch:Dock(TOP)
targetSearch:DockMargin(0, 0, 0, 4)
targetSearch:SetPlaceholderText("Filtrar por nombre")
targetSearch:SetUpdateOnType(true)
targetSearch:SetTextColor(Color(230, 230, 230))
targetSearch:SetHighlightColor(Color(58, 150, 235))
targetSearch:SetDrawBackground(false)
targetSearch.Paint = function(panel, w, h)
	draw.RoundedBox(6, 0, 0, w, h, Color(35, 40, 48, 255))
	panel:DrawTextEntryText(Color(235, 235, 235), Color(200, 200, 200), Color(235, 235, 235))
end

local playerList = vgui.Create("DListView", middlePanel)
playerList:Dock(FILL)
playerList:AddColumn("Jugador")
playerList:AddColumn("Personaje")
playerList:SetMultiSelect(true)
playerList.Paint = function(panel, w, h)
	draw.RoundedBox(6, 0, 0, w, h, Color(28, 32, 40, 235))
end

local selectedLabel = vgui.Create("DLabel", middlePanel)
selectedLabel:Dock(BOTTOM)
selectedLabel:SetTall(24)
selectedLabel:SetText("Ningun jugador seleccionado")
selectedLabel:SetTextColor(Color(220, 220, 220))

-- forward declarations for functions used by selection/update logic
local UpdatePreview, UpdateModelPreview

-- Multi-selection helper state
local selectedPlayers = {}
local editIndex = 1 -- which selected player we're editing
PLUGIN.bodyGlowOffsets = PLUGIN.bodyGlowOffsets or {}

local function GetPlayerKey(ply)
	if (not IsValid(ply)) then return nil end
	local char = ply:GetCharacter()
	if (IsValid(char) and char.GetName) then
		return char:GetName()
	end
	return ply:SteamID()
end

local function UpdateSelectionUI()
	local count = #selectedPlayers
	if (count == 0) then
		selectedLabel:SetText("Ningun jugador seleccionado")
		if (IsValid(applyTarget)) then applyTarget:SetDisabled(true) end
		if (IsValid(clearTarget)) then clearTarget:SetDisabled(true) end
		return
	end

	editIndex = math.Clamp(editIndex, 1, count)
	local cur = selectedPlayers[editIndex]
	selectedLabel:SetText(string.format("Editando %d/%d: %s", editIndex, count, (IsValid(cur) and cur:Name()) or "Desconocido"))
	if (IsValid(applyTarget)) then applyTarget:SetDisabled(false) end
	if (IsValid(clearTarget)) then clearTarget:SetDisabled(false) end
	UpdateModelPreview(cur)

	-- load stored offsets for this player into sliders
	local key = GetPlayerKey(cur)
	if (key and PLUGIN.bodyGlowOffsets[key]) then
		local offs = PLUGIN.bodyGlowOffsets[key]
		if (offsetX and IsValid(offsetX)) then offsetX:SetValue(offs.x or 0) end
		if (offsetY and IsValid(offsetY)) then offsetY:SetValue(offs.y or 0) end
		if (offsetZ and IsValid(offsetZ)) then offsetZ:SetValue(offs.z or 0) end
	else
		if (offsetX and IsValid(offsetX)) then offsetX:SetValue(0) end
		if (offsetY and IsValid(offsetY)) then offsetY:SetValue(0) end
		if (offsetZ and IsValid(offsetZ)) then offsetZ:SetValue(0) end
	end
end

local rightTitle = vgui.Create("DLabel", rightPanel)
rightTitle:SetText("Configuracion de BodyGlow")
rightTitle:Dock(TOP)
rightTitle:SetFont("DermaDefaultBold")
rightTitle:SetTall(24)
rightTitle:SetTextColor(Color(240, 240, 240))

local scroll = vgui.Create("DScrollPanel", rightPanel)
scroll:Dock(FILL)

local form = vgui.Create("DForm", scroll)
	form:Dock(FILL)
	form:SetName("Opciones de BodyGlow")
	form:DockPadding(12, 12, 12, 12)
	form:SetSpacing(10)
form.Paint = function(panel, w, h)
	draw.RoundedBox(6, 0, 0, w, h, Color(22, 25, 30, 220))
	draw.RoundedBox(0, 0, 0, w, 30, Color(58, 150, 235, 160))
end

local function StyleFormControl(control)
	if (not IsValid(control)) then
		return
	end

	if (IsValid(control.Label) and control.Label.SetTextColor) then
		control.Label:SetTextColor(Color(235, 235, 235))
		if (control.Label.SetFont) then control.Label:SetFont("DermaDefaultBold") end
	end

	if (control.SetTextColor) then
		control:SetTextColor(Color(235, 235, 235))
	end

	if (IsValid(control.TextEntry) and control.TextEntry.SetTextColor) then
		control.TextEntry:SetTextColor(Color(235, 235, 235))
		if (control.TextEntry.SetDrawBackground) then
			control.TextEntry:SetDrawBackground(false)
		end
	end

	if (IsValid(control.DropButton) and control.DropButton.SetTextColor) then
		control.DropButton:SetTextColor(Color(235, 235, 235))
	end

	if (IsValid(control.Panels)) then
		for _, panel in ipairs(control.Panels) do
			if (IsValid(panel) and panel.SetTextColor) then
				panel:SetTextColor(Color(235, 235, 235))
			end
		end
	end
end

-- UpdateModelPreview forward-declared above; definition follows below

	local formHeader = vgui.Create("DLabel", form)
	formHeader:SetText("Ajustes de brillo")
	formHeader:SetFont("DermaLarge")
	formHeader:SetTextColor(Color(235, 235, 235))
	formHeader:SetContentAlignment(4)
	form:AddItem(formHeader)

local debugCheck = vgui.Create("DCheckBoxLabel", form)
debugCheck:Dock(TOP)
debugCheck:SetText("Mostrar depuración preview")
debugCheck:SetValue(0)
debugCheck:SetTextColor(Color(220,220,220))
debugCheck:SetChecked(false)
debugCheck.OnChange = function(_, val)
	modelPanel.ShowDebug = val
	modelPanel:InvalidateLayout(true)
end
form:AddItem(debugCheck)

local sizeSlider = form:NumSlider("Tamaño", nil, 8, 128, 0)
sizeSlider:SetValue(28)
StyleFormControl(sizeSlider)
sizeSlider.OnValueChanged = function()
	if (UpdatePreview) then
		UpdatePreview()
	end
end

	-- Color controls grouped in a horizontal panel (R/G/B)
	local redSlider, greenSlider, blueSlider
	local rEntry, gEntry, bEntry
	local colorPanel = vgui.Create("DPanel", form)
	colorPanel:SetTall(40)
	colorPanel:Dock(TOP)
	colorPanel:DockMargin(0, 4, 0, 4)
	colorPanel.Paint = function() end

	-- Palette of common colors (white, black, red, blue, green, purple, pink)
	local function SetColorFromPalette(r, g, b)
		if (redSlider and IsValid(redSlider)) then
			redSlider:SetValue(r)
		end
		if (greenSlider and IsValid(greenSlider)) then
			greenSlider:SetValue(g)
		end
		if (blueSlider and IsValid(blueSlider)) then
			blueSlider:SetValue(b)
		end
		if (rEntry and IsValid(rEntry)) then rEntry:SetValue(r) end
		if (gEntry and IsValid(gEntry)) then gEntry:SetValue(g) end
		if (bEntry and IsValid(bEntry)) then bEntry:SetValue(b) end
		if (UpdatePreview) then UpdatePreview() end
	end

	local palettePanel = vgui.Create("DPanel", colorPanel)
	palettePanel:Dock(LEFT)
	palettePanel:SetWide(200)
	palettePanel:DockPadding(4, 4, 4, 4)
	palettePanel.Paint = function() end

	-- Slider column for R/G/B
	local sliderPanel = vgui.Create("DPanel", colorPanel)
	sliderPanel:Dock(FILL)
	sliderPanel:DockPadding(6, 4, 6, 4)
	sliderPanel.Paint = function() end

	redSlider = vgui.Create("DNumSlider", sliderPanel)
	redSlider:Dock(TOP)
	redSlider:SetMin(0)
	redSlider:SetMax(255)
	redSlider:SetDecimals(0)
	redSlider:SetValue(255)
	redSlider:SetText("R")
	StyleFormControl(redSlider)
	redSlider.OnValueChanged = function(self, val)
		if (rEntry and IsValid(rEntry)) then rEntry:SetValue(math.floor(tonumber(val) or rEntry:GetValue())) end
		if (UpdatePreview) then UpdatePreview() end
	end

	greenSlider = vgui.Create("DNumSlider", sliderPanel)
	greenSlider:Dock(TOP)
	greenSlider:SetMin(0)
	greenSlider:SetMax(255)
	greenSlider:SetDecimals(0)
	greenSlider:SetValue(220)
	greenSlider:SetText("G")
	StyleFormControl(greenSlider)
	greenSlider.OnValueChanged = function(self, val)
		if (gEntry and IsValid(gEntry)) then gEntry:SetValue(math.floor(tonumber(val) or gEntry:GetValue())) end
		if (UpdatePreview) then UpdatePreview() end
	end

	blueSlider = vgui.Create("DNumSlider", sliderPanel)
	blueSlider:Dock(TOP)
	blueSlider:SetMin(0)
	blueSlider:SetMax(255)
	blueSlider:SetDecimals(0)
	blueSlider:SetValue(160)
	blueSlider:SetText("B")
	StyleFormControl(blueSlider)
	blueSlider.OnValueChanged = function(self, val)
		if (bEntry and IsValid(bEntry)) then bEntry:SetValue(math.floor(tonumber(val) or bEntry:GetValue())) end
		if (UpdatePreview) then UpdatePreview() end
	end

	local colors = {
		{255,255,255}, -- blanco
		{0,0,0},       -- negro
		{220,20,60},   -- rojo (crimson)
		{0,120,255},   -- azul
		{0,200,0},     -- verde
		{160,32,240},  -- morado
		{255,105,180}  -- rosa
	}

	for _, col in ipairs(colors) do
		local btn = vgui.Create("DButton", palettePanel)
		btn:Dock(LEFT)
		btn:DockMargin(4, 0, 0, 0)
		btn:SetWide(24)
		btn:SetText("")
		btn.Paint = function(self, w, h)
			surface.SetDrawColor(col[1], col[2], col[3], 255)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(0,0,0,120)
			surface.DrawOutlinedRect(0, 0, w, h)
		end
		btn.DoClick = function()
			SetColorFromPalette(col[1], col[2], col[3])
		end
	end

	-- sliders are local variables in the surrounding scope so ReadFormData can access them

	-- compact numeric entries for fine adjustments
	local entriesPanel = vgui.Create("DPanel", form)
	entriesPanel:Dock(TOP)
	entriesPanel:SetTall(28)
	entriesPanel:DockMargin(0, 2, 0, 6)
	entriesPanel.Paint = function() end

	local rEntry = vgui.Create("DNumberWang", entriesPanel)
	rEntry:Dock(LEFT)
	rEntry:SetWide(70)
	rEntry:SetMin(0)
	rEntry:SetMax(255)
	rEntry:SetDecimals(0)
	rEntry:SetValue(255)
	rEntry.OnValueChanged = function(_, val)
			redSlider:SetValue(tonumber(val) or rEntry:GetValue())
			-- persist to current editing player's offsets
			if (#selectedPlayers > 0 and selectedPlayers[editIndex]) then
				local key = GetPlayerKey(selectedPlayers[editIndex])
				if (key) then
					PLUGIN.bodyGlowOffsets[key] = PLUGIN.bodyGlowOffsets[key] or {x = 0, y = 0, z = 0}
				end
			end
	end

	local gEntry = vgui.Create("DNumberWang", entriesPanel)
	gEntry:Dock(LEFT)
	gEntry:SetWide(70)
	gEntry:SetMin(0)
	gEntry:SetMax(255)
	gEntry:SetDecimals(0)
	gEntry:SetValue(220)
	gEntry.OnValueChanged = function(_, val)
		greenSlider:SetValue(tonumber(val) or gEntry:GetValue())
			if (#selectedPlayers > 0 and selectedPlayers[editIndex]) then
				local key = GetPlayerKey(selectedPlayers[editIndex])
				if (key) then
					PLUGIN.bodyGlowOffsets[key] = PLUGIN.bodyGlowOffsets[key] or {x = 0, y = 0, z = 0}
				end
			end
	end

	local bEntry = vgui.Create("DNumberWang", entriesPanel)
	bEntry:Dock(LEFT)
	bEntry:SetWide(70)
	bEntry:SetMin(0)
	bEntry:SetMax(255)
	bEntry:SetDecimals(0)
	bEntry:SetValue(160)
	bEntry.OnValueChanged = function(_, val)
		blueSlider:SetValue(tonumber(val) or bEntry:GetValue())
			if (#selectedPlayers > 0 and selectedPlayers[editIndex]) then
				local key = GetPlayerKey(selectedPlayers[editIndex])
				if (key) then
					PLUGIN.bodyGlowOffsets[key] = PLUGIN.bodyGlowOffsets[key] or {x = 0, y = 0, z = 0}
				end
			end
	end

	-- Color picker button
	local colorBtn = vgui.Create("DButton", colorPanel)
	colorBtn:Dock(RIGHT)
	colorBtn:SetWide(64)
	colorBtn:SetText("Color")
	colorBtn.DoClick = function()
		local cframe = vgui.Create("DFrame")
		cframe:SetTitle("Seleccionar color")
		cframe:SetSize(320, 240)
		cframe:Center()
		cframe:MakePopup()

		local mixer = vgui.Create("DColorMixer", cframe)
		mixer:Dock(FILL)
		mixer:SetColor(Color(redSlider:GetValue(), greenSlider:GetValue(), blueSlider:GetValue()))

		local lastCol = mixer:GetColor() or Color(0,0,0)
		mixer.Think = function(self)
			local col = self:GetColor()
			if (not col) then return end
			if (col.r ~= lastCol.r or col.g ~= lastCol.g or col.b ~= lastCol.b) then
				redSlider:SetValue(col.r)
				greenSlider:SetValue(col.g)
				blueSlider:SetValue(col.b)
				if (rEntry and IsValid(rEntry)) then rEntry:SetValue(col.r) end
				if (gEntry and IsValid(gEntry)) then gEntry:SetValue(col.g) end
				if (bEntry and IsValid(bEntry)) then bEntry:SetValue(col.b) end
				if (UpdatePreview) then UpdatePreview() end
				lastCol = Color(col.r, col.g, col.b)
			end
		end

		local btnPanel = vgui.Create("DPanel", cframe)
		btnPanel:Dock(BOTTOM)
		btnPanel:SetTall(32)
		btnPanel.Paint = function() end

		local ok = vgui.Create("DButton", btnPanel)
		ok:Dock(RIGHT)
		ok:SetWide(80)
		ok:SetText("Aceptar")
		ok.DoClick = function()
			local col = mixer:GetColor()
			if (col) then
				redSlider:SetValue(col.r)
				greenSlider:SetValue(col.g)
				blueSlider:SetValue(col.b)
				rEntry:SetValue(col.r)
				gEntry:SetValue(col.g)
				bEntry:SetValue(col.b)
				if (UpdatePreview) then UpdatePreview() end
			end
			cframe:Close()
		end

		local cancel = vgui.Create("DButton", btnPanel)
		cancel:Dock(LEFT)
		cancel:SetWide(80)
		cancel:SetText("Cancelar")
		cancel.DoClick = function() cframe:Close() end
	end

local blinkSlider = form:NumSlider("Parpadeo", nil, 0, 10, 1)
blinkSlider:SetValue(0)
StyleFormControl(blinkSlider)
blinkSlider.OnValueChanged = function()
	if (UpdatePreview) then
		UpdatePreview()
	end
end

local partCombo = vgui.Create("DComboBox", form)
if (IsValid(partCombo)) then
		partCombo:SetText(PLUGIN.bodyGlowLastPart or "Body Part")
	partCombo:Dock(TOP)
	partCombo:SetTall(22)
	for part, _ in SortedPairs(PLUGIN.bodyGlowParts or {}) do
		partCombo:AddChoice(part)
	end
		-- leave choice to user; display previous selection via SetText above
	StyleFormControl(partCombo)
	form:AddItem(partCombo)
		partCombo.OnSelect = function(_, _, value)
			PLUGIN.bodyGlowLastPart = value
			if (UpdatePreview) then UpdatePreview() end
		end
end

local styleCombo = vgui.Create("DComboBox", form)
if (IsValid(styleCombo)) then
		styleCombo:SetText(PLUGIN.bodyGlowLastStyle or "Style")
	styleCombo:Dock(TOP)
	styleCombo:SetTall(22)
	for style, _ in SortedPairs(PLUGIN.bodyGlowStyles or {}) do
		styleCombo:AddChoice(style)
	end
		-- display previous selection via SetText above
		StyleFormControl(styleCombo)
		form:AddItem(styleCombo)
		styleCombo.OnSelect = function(_, _, value)
			PLUGIN.bodyGlowLastStyle = value
			if (UpdatePreview) then UpdatePreview() end
		end
end

local offsetX = form:NumSlider("Offset X", nil, -64, 64, 0)
offsetX:SetValue(0)
StyleFormControl(offsetX)
offsetX.OnValueChanged = function()
	if (UpdatePreview) then
		-- persist offset for currently edited player (either multi-select focused or single selected)
		local ply = nil
		if (#selectedPlayers > 0 and selectedPlayers[editIndex] and IsValid(selectedPlayers[editIndex])) then
			ply = selectedPlayers[editIndex]
		elseif (IsValid(selectedPlayer)) then
			ply = selectedPlayer
		end
		if (IsValid(ply)) then
			local key = GetPlayerKey(ply)
			if (key) then
				PLUGIN.bodyGlowOffsets[key] = PLUGIN.bodyGlowOffsets[key] or {x = 0, y = 0, z = 0}
				PLUGIN.bodyGlowOffsets[key].x = offsetX:GetValue()
			end
		end
		UpdatePreview()
	end
end

local offsetY = form:NumSlider("Offset Y", nil, -64, 64, 0)
offsetY:SetValue(0)
StyleFormControl(offsetY)
offsetY.OnValueChanged = function()
	if (UpdatePreview) then
		local ply = nil
		if (#selectedPlayers > 0 and selectedPlayers[editIndex] and IsValid(selectedPlayers[editIndex])) then
			ply = selectedPlayers[editIndex]
		elseif (IsValid(selectedPlayer)) then
			ply = selectedPlayer
		end
		if (IsValid(ply)) then
			local key = GetPlayerKey(ply)
			if (key) then
				PLUGIN.bodyGlowOffsets[key] = PLUGIN.bodyGlowOffsets[key] or {x = 0, y = 0, z = 0}
				PLUGIN.bodyGlowOffsets[key].y = offsetY:GetValue()
			end
		end
		UpdatePreview()
	end
end

local offsetZ = form:NumSlider("Offset Z", nil, -64, 64, 0)
offsetZ:SetValue(0)
StyleFormControl(offsetZ)
offsetZ.OnValueChanged = function()
	if (UpdatePreview) then
		local ply = nil
		if (#selectedPlayers > 0 and selectedPlayers[editIndex] and IsValid(selectedPlayers[editIndex])) then
			ply = selectedPlayers[editIndex]
		elseif (IsValid(selectedPlayer)) then
			ply = selectedPlayer
		end
		if (IsValid(ply)) then
			local key = GetPlayerKey(ply)
			if (key) then
				PLUGIN.bodyGlowOffsets[key] = PLUGIN.bodyGlowOffsets[key] or {x = 0, y = 0, z = 0}
				PLUGIN.bodyGlowOffsets[key].z = offsetZ:GetValue()
			end
		end
		UpdatePreview()
	end
end

local fadeStartSlider = form:NumSlider("Inicio desvanecimiento", nil, 0, 5000, 0)
fadeStartSlider:SetValue(700)
StyleFormControl(fadeStartSlider)
fadeStartSlider.OnValueChanged = function()
	if (UpdatePreview) then
		UpdatePreview()
	end
end

local maxDistanceSlider = form:NumSlider("Distancia máxima", nil, 1, 5000, 0)
maxDistanceSlider:SetValue(1000)
StyleFormControl(maxDistanceSlider)
maxDistanceSlider.OnValueChanged = function()
	if (UpdatePreview) then
		UpdatePreview()
	end
end

local fadeOutSlider = form:NumSlider("Duración desvanecimiento", nil, 0, 10, 1)
fadeOutSlider:SetValue(0)
StyleFormControl(fadeOutSlider)
fadeOutSlider.OnValueChanged = function()
	if (UpdatePreview) then
		UpdatePreview()
	end
end

	local buttonPanel = vgui.Create("DPanel", frame)
	buttonPanel:Dock(BOTTOM)
	buttonPanel:SetTall(48)
	buttonPanel:DockMargin(0, 12, 0, 0)
	buttonPanel:DockPadding(12, 8, 12, 8)
	buttonPanel.Paint = function(panel, w, h)
		draw.RoundedBox(6, 0, 0, w, h, Color(18, 20, 24, 235))
		draw.RoundedBox(0, 0, 0, w, 2, Color(70, 160, 255, 160))
	end

local function StyleButton(button)
	button:SetFont("DermaDefaultBold")
	button:SetTextColor(Color(245, 245, 245))
	button.Paint = function(panel, w, h)
		local bg = panel:IsDown() and Color(50, 100, 200, 240) or panel:IsHovered() and Color(80, 170, 255, 230) or Color(36, 44, 56, 220)
		draw.RoundedBox(6, 0, 0, w, h, bg)
		if (panel:IsHovered()) then
			draw.RoundedBox(6, 0, 0, w, h, Color(255, 255, 255, 10))
		end
	end
end

local applySelf = vgui.Create("DButton", buttonPanel)
applySelf:SetText("Aplicar a mi")
	applySelf:Dock(LEFT)
	applySelf:DockMargin(0, 0, 8, 0)
	applySelf:SetWide(140)
StyleButton(applySelf)

local applyTarget = vgui.Create("DButton", buttonPanel)
applyTarget:SetText("Aplicar a jugador")
	applyTarget:Dock(LEFT)
	applyTarget:DockMargin(0, 0, 8, 0)
	applyTarget:SetWide(160)
StyleButton(applyTarget)
applyTarget:SetDisabled(true)
applyTarget:SetTooltip("Selecciona un jugador para habilitar")

local clearTarget = vgui.Create("DButton", buttonPanel)
clearTarget:SetText("Borrar jugador")
	clearTarget:Dock(RIGHT)
	clearTarget:SetWide(140)
StyleButton(clearTarget)
clearTarget:SetDisabled(true)
clearTarget:SetTooltip("Selecciona un jugador para habilitar")

local clearSelf = vgui.Create("DButton", buttonPanel)
clearSelf:SetText("Borrar mi brillo")
	clearSelf:Dock(RIGHT)
	clearSelf:DockMargin(8, 0, 0, 0)
	clearSelf:SetWide(140)
StyleButton(clearSelf)


local selectedTarget = ""
local selectedPlayer = nil

UpdateModelPreview = function(ply)
	if (!IsValid(ply)) then
		selectedLabel:SetText("Ningun jugador seleccionado")
		return
	end

	local model = ply:GetModel()
	if (not modelPanel or not model or model == "") then
		selectedLabel:SetText(string.format("Seleccionado: %s", ply:Name() or "Desconocido"))
		return
	end

	-- set the model on the panel; entity may not be ready immediately
	modelPanel:SetModel(model)

	-- do entity-specific setup next tick to ensure entity exists
	timer.Simple(0, function()
		if (not IsValid(modelPanel) or not IsValid(ply)) then return end
		local entity = modelPanel.Entity
		if (IsValid(entity)) then
			-- copy player model scale to preview entity so offsets match visual scaling
			local scale = 1
			if (ply and ply.GetModelScale) then
				local ok, s = pcall(function() return ply:GetModelScale() end)
				if (ok and tonumber(s)) then scale = tonumber(s) end
			end
			if (entity.SetModelScale) then
				entity:SetModelScale(scale, true)
			end

			modelPanel.CameraTarget = entity:OBBCenter()
			modelPanel.CameraDistance = math.max(70, entity:BoundingRadius() * 1.5 * (scale or 1))
			modelPanel.CameraYaw = 45
			modelPanel.CameraPitch = 20
			modelPanel:UpdateCamera()

			-- Load stored offsets for this player into sliders if available
			local key = GetPlayerKey(ply)
			if (key and PLUGIN.bodyGlowOffsets[key]) then
				local offs = PLUGIN.bodyGlowOffsets[key]
				if (offsetX and IsValid(offsetX)) then offsetX:SetValue(offs.x or 0) end
				if (offsetY and IsValid(offsetY)) then offsetY:SetValue(offs.y or 0) end
				if (offsetZ and IsValid(offsetZ)) then offsetZ:SetValue(offs.z or 0) end
			end

			if (UpdatePreview) then
				UpdatePreview()
			end
		end
	end)

	selectedLabel:SetText(string.format("Seleccionado: %s", ply:Name() or "Desconocido"))
end

-- UI to navigate selected players for per-player offset editing
local navPanel = vgui.Create("DPanel", middlePanel)
navPanel:Dock(BOTTOM)
navPanel:SetTall(28)
navPanel.Paint = function() end

local prevBtn = vgui.Create("DButton", navPanel)
prevBtn:Dock(LEFT)
prevBtn:SetWide(80)
prevBtn:SetText("Anterior")
prevBtn.DoClick = function()
	if (#selectedPlayers == 0) then return end
	editIndex = math.max(1, editIndex - 1)
	UpdateSelectionUI()
end

local nextBtn = vgui.Create("DButton", navPanel)
nextBtn:Dock(RIGHT)
nextBtn:SetWide(80)
nextBtn:SetText("Siguiente")
nextBtn.DoClick = function()
	if (#selectedPlayers == 0) then return end
	editIndex = math.min(#selectedPlayers, editIndex + 1)
	UpdateSelectionUI()
end

local editInfo = vgui.Create("DLabel", navPanel)
editInfo:Dock(FILL)
editInfo:SetText("Editar selection")
editInfo:SetContentAlignment(5)
editInfo:SetTextColor(Color(220,220,220))

-- replace selectedLabel usage in UpdateSelectionUI to also set this label
local oldUpdateSelectionUI = UpdateSelectionUI
UpdateSelectionUI = function()
	oldUpdateSelectionUI()
	if (#selectedPlayers == 0) then
		editInfo:SetText("Editar selection")
	else
		local cur = selectedPlayers[editIndex]
		editInfo:SetText(string.format("Editando %d/%d: %s", editIndex, #selectedPlayers, (IsValid(cur) and cur:Name()) or "Desconocido"))
	end
end

local function RefreshPlayerList(filter)
    playerList:Clear()
    selectedTarget = ""
    selectedPlayer = nil
	if (IsValid(applyTarget)) then applyTarget:SetDisabled(true) end
	if (IsValid(clearTarget)) then clearTarget:SetDisabled(true) end
    selectedLabel:SetText("Ningun jugador seleccionado")
    filter = string.lower(filter or "")

	for _, ply in ipairs(player.GetAll()) do
        local name = ply:Name() or ""
        local charName = ""
        local char = ply:GetCharacter()

        if (IsValid(char)) then
            charName = char:GetName() or ""
        end

        local displayName = string.format("%s - %s", name, charName)

		if (filter == "" or string.find(string.lower(displayName), filter, 1, true)) then
			local row = playerList:AddLine(name, charName)
			if (row) then
				row.player = ply

				-- paint row with highlight when selected
				row.Paint = function(self, w, h)
					if (self:IsSelected()) then
						draw.RoundedBox(0, 0, 0, w, h, Color(70, 160, 255, 60))
					else
						draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
					end
				end

				-- Auto-select previously saved selection (by character name), or LocalPlayer as fallback
				local last = PLUGIN.bodyGlowLastSelected
				if (last and IsValid(ply)) then
					local pchar = ""
					local pcharObj = ply:GetCharacter()
					if (IsValid(pcharObj) and pcharObj.GetName) then pchar = pcharObj:GetName() or "" end
					if (pchar == last) then
						selectedTarget = name
						selectedPlayer = ply
						playerList:SelectItem(row)
						selectedLabel:SetText(string.format("Seleccionado: %s", ply:Name() or "Desconocido"))
						if (IsValid(applyTarget)) then applyTarget:SetDisabled(false) end
						if (IsValid(clearTarget)) then clearTarget:SetDisabled(false) end
						UpdateModelPreview(selectedPlayer)
					end
				end
				if (not selectedPlayer and ply == LocalPlayer()) then
					selectedTarget = name
					selectedPlayer = ply
					playerList:SelectItem(row)
					selectedLabel:SetText(string.format("Seleccionado: %s", ply:Name() or "Desconocido"))
					if (IsValid(applyTarget)) then applyTarget:SetDisabled(false) end
					if (IsValid(clearTarget)) then clearTarget:SetDisabled(false) end
					UpdateModelPreview(selectedPlayer)
				end

				-- Row click should toggle membership in selectedPlayers
				row.OnMousePressed = function(self, mcode)
					if (mcode == MOUSE_LEFT) then
						local found = false
						for i, pl in ipairs(selectedPlayers) do
							if (pl == ply) then
								table.remove(selectedPlayers, i)
								found = true
								break
							end
						end
						if (not found) then
							table.insert(selectedPlayers, ply)
						end

						-- update visual selection on the row
						if (found) then
							self:SetSelected(false)
						else
							self:SetSelected(true)
						end
						-- ensure editIndex valid
						if (#selectedPlayers > 0 and editIndex > #selectedPlayers) then editIndex = #selectedPlayers end
						UpdateSelectionUI()
					end
				end
			end
		end
    end
end

playerList.OnRowSelected = function(panel, rowIndex, row)
	-- DListView multiselect support: keep toggled selection list in sync
	local ply = row.player
	if (not IsValid(ply)) then return end
	-- Toggle selection membership
	local found = false
	for i, pl in ipairs(selectedPlayers) do
		if (pl == ply) then
			table.remove(selectedPlayers, i)
			found = true
			break
		end
	end
	if (not found) then
		table.insert(selectedPlayers, ply)
	end

	-- set focus to the last selected player for editing
	editIndex = #selectedPlayers
	UpdateSelectionUI()

	-- remember last selection by character name when single-click selecting
	if (IsValid(ply)) then
		local char = ply:GetCharacter()
		if (IsValid(char) and char.GetName) then
			PLUGIN.bodyGlowLastSelected = char:GetName()
		else
			PLUGIN.bodyGlowLastSelected = ply:SteamID()
		end
	end
end

targetSearch.OnChange = function(self)
    RefreshPlayerList(self:GetValue())
end

RefreshPlayerList("")

if (UpdatePreview) then
    UpdatePreview()
end

local function ReadFormData()
			local bodyPart = PLUGIN.bodyGlowLastPart or ""
			if (IsValid(partCombo)) then
				-- prefer stored last selection, fallback to combo current value
				if (PLUGIN.bodyGlowLastPart and PLUGIN.bodyGlowLastPart != "") then
					bodyPart = PLUGIN.bodyGlowLastPart
				else
					local v = partCombo.GetValue and partCombo:GetValue() or ""
					if (v and v != "") then bodyPart = v end
				end
			end

			local style = PLUGIN.bodyGlowLastStyle or ""
			if (IsValid(styleCombo)) then
				if (PLUGIN.bodyGlowLastStyle and PLUGIN.bodyGlowLastStyle != "") then
					style = PLUGIN.bodyGlowLastStyle
				else
					local v2 = styleCombo.GetValue and styleCombo:GetValue() or ""
					if (v2 and v2 != "") then style = v2 end
				end
			end

		return {
			size = sizeSlider:GetValue(),
			color = {redSlider:GetValue(), greenSlider:GetValue(), blueSlider:GetValue()},
			blink = blinkSlider:GetValue(),
			bodyPart = bodyPart,
			offset = {
				x = offsetX:GetValue(),
				y = offsetY:GetValue(),
				z = offsetZ:GetValue()
			},
			style = style,
			fadeStart = fadeStartSlider:GetValue(),
			maxDistance = maxDistanceSlider:GetValue(),
			fadeOut = fadeOutSlider:GetValue()
		}
	end

UpdatePreview = function()
	if (!IsValid(modelPanel)) then
		return
	end

	-- Use current editing player's stored offsets if available
	local data = ReadFormData()

	-- Normalize color to Color object for consistent usage in paint
	if (data and data.color and istable(data.color)) then
		data.color = Color(data.color[1] or 255, data.color[2] or 220, data.color[3] or 160, data.color[4] or 255)
	end
	if (#selectedPlayers > 0 and IsValid(selectedPlayers[editIndex])) then
		local key = GetPlayerKey(selectedPlayers[editIndex])
		if (key and PLUGIN.bodyGlowOffsets[key]) then
			data.offset = {
				x = PLUGIN.bodyGlowOffsets[key].x or data.offset.x,
				y = PLUGIN.bodyGlowOffsets[key].y or data.offset.y,
				z = PLUGIN.bodyGlowOffsets[key].z or data.offset.z
			}
		end
	end

	modelPanel.PreviewGlowData = data
	modelPanel:InvalidateLayout(true)
end

	-- Helper to send action + data to server
	local function SendAction(action)
		local data = ReadFormData() or {}
		local targetName = selectedTarget or ""

		net.Start("ixBodyGlowSend")
		net.WriteString(action)
		net.WriteString(targetName)
		net.WriteTable(data)
		net.SendToServer()
	end

	-- Build data for a specific player (using stored offsets if present)
	local function BuildDataForPlayer(ply)
		local data = ReadFormData() or {}
		if (IsValid(ply)) then
			local key = GetPlayerKey(ply)
			if (key and PLUGIN.bodyGlowOffsets[key]) then
				data.offset = {
					x = PLUGIN.bodyGlowOffsets[key].x or data.offset.x,
					y = PLUGIN.bodyGlowOffsets[key].y or data.offset.y,
					z = PLUGIN.bodyGlowOffsets[key].z or data.offset.z
				}
			end

			-- attach model scale so server can apply offsets correctly if needed
			local scale = 1
			if (ply.GetModelScale) then
				local ok, s = pcall(function() return ply:GetModelScale() end)
				if (ok and tonumber(s)) then scale = tonumber(s) end
			end
			data.modelScale = scale
		end
		return data
	end

	local function SendActionToPlayer(action, ply)
		if (not IsValid(ply)) then return end
		local targetName = ply:Name() or ""
		local data = BuildDataForPlayer(ply)

		net.Start("ixBodyGlowSend")
		net.WriteString(action)
		net.WriteString(targetName)
		net.WriteTable(data)
		net.SendToServer()
	end

	applySelf.DoClick = function()
		SendAction("applySelf")
		frame:Close()
	end

	applyTarget.DoClick = function()
		if (#selectedPlayers == 0 and not selectedPlayer) then
			LocalPlayer():Notify("Selecciona un jugador antes de aplicar.")
			return
		end

		-- apply to currently focused selected player if multi-select
		if (#selectedPlayers > 0 and selectedPlayers[editIndex]) then
			SendActionToPlayer("applyTarget", selectedPlayers[editIndex])
			frame:Close()
			return
		end

		SendAction("applyTarget")
		frame:Close()
	end

	clearSelf.DoClick = function()
		SendAction("clearSelf")
		frame:Close()
	end

	clearTarget.DoClick = function()
		if (#selectedPlayers == 0 and not selectedPlayer) then
			LocalPlayer():Notify("Selecciona un jugador antes de borrar.")
			return
		end

		-- clear for all selected players if multi-selected
		if (#selectedPlayers > 0) then
			for _, ply in ipairs(selectedPlayers) do
				SendActionToPlayer("clearTarget", ply)
			end
			frame:Close()
			return
		end

		SendAction("clearTarget")
		frame:Close()
	end

	-- Apply to all selected players (batch) using their stored offsets
	local applySelected = vgui.Create("DButton", buttonPanel)
	applySelected:SetText("Aplicar a seleccionados")
	applySelected:Dock(LEFT)
	applySelected:DockMargin(0, 0, 8, 0)
	applySelected:SetWide(200)
	StyleButton(applySelected)
	applySelected.DoClick = function()
		if (#selectedPlayers == 0) then
			LocalPlayer():Notify("Selecciona jugadores para aplicar.")
			return
		end
		for _, ply in ipairs(selectedPlayers) do
			SendActionToPlayer("applyTarget", ply)
		end
		frame:Close()
	end


	-- Load saved settings (if any) into controls so menu state persists between openings
	local saved = PLUGIN.bodyGlowSavedSettings or {}
	if (saved and istable(saved)) then
		if (saved.size and IsValid(sizeSlider)) then sizeSlider:SetValue(saved.size) end
		if (saved.color and IsValid(redSlider) and IsValid(greenSlider) and IsValid(blueSlider)) then
			redSlider:SetValue(saved.color[1] or redSlider:GetValue())
			greenSlider:SetValue(saved.color[2] or greenSlider:GetValue())
			blueSlider:SetValue(saved.color[3] or blueSlider:GetValue())
			if (IsValid(rEntry)) then rEntry:SetValue(saved.color[1] or rEntry:GetValue()) end
			if (IsValid(gEntry)) then gEntry:SetValue(saved.color[2] or gEntry:GetValue()) end
			if (IsValid(bEntry)) then bEntry:SetValue(saved.color[3] or bEntry:GetValue()) end
		end
		if (saved.blink and IsValid(blinkSlider)) then blinkSlider:SetValue(saved.blink) end
		if (saved.bodyPart) then PLUGIN.bodyGlowLastPart = saved.bodyPart end
		if (saved.style) then PLUGIN.bodyGlowLastStyle = saved.style end
		if (saved.offset and IsValid(offsetX) and IsValid(offsetY) and IsValid(offsetZ)) then
			offsetX:SetValue(saved.offset.x or 0)
			offsetY:SetValue(saved.offset.y or 0)
			offsetZ:SetValue(saved.offset.z or 0)
		end
		if (saved.fadeStart and IsValid(fadeStartSlider)) then fadeStartSlider:SetValue(saved.fadeStart) end
		if (saved.maxDistance and IsValid(maxDistanceSlider)) then maxDistanceSlider:SetValue(saved.maxDistance) end
		if (saved.fadeOut and IsValid(fadeOutSlider)) then fadeOutSlider:SetValue(saved.fadeOut) end
	end

	-- Save settings when the menu is closed so they persist
	frame.OnRemove = function()
		if (ReadFormData) then
			PLUGIN.bodyGlowSavedSettings = ReadFormData() or {}
		end
	end

	PLUGIN.bodyGlowMenu = frame
end

net.Receive("ixBodyGlowOpenMenu", function()
	CreateBodyGlowMenu()
end)
