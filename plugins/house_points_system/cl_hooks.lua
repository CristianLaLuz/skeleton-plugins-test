net.Receive("ixHousePointsUpdate", function()
    ixHousePoints = net.ReadTable()
end)


-- Use a server table?

local HOUSES = {
    "gryffindor",
    "slytherin",
    "ravenclaw",
    "hufflepuff"
}

local HOUSE_IMAGES = {
    gryffindor = "gryffindor.png",
    slytherin = "slytherin.png",
    ravenclaw = "ravenclaw.png",
    hufflepuff = "hufflepuff.png"
}

local function GetHouseFaction(key)
    return ix.faction.Get(string.lower(key))
end

local function GetHouseName(key)
    local faction = GetHouseFaction(key)

    return faction and faction.name or key
end

local function GetHouseColor(key)
    local faction = GetHouseFaction(key)

    return faction and faction.color or color_white
end

local function CanEditHousePoints()
    return LocalPlayer():IsAdmin() and ix.config.Get("canModifyHousePoints", false)
end

local function SendHousePointsChange(key, amount)
    net.Start("ixHousePointsModify")
        net.WriteString(key)
        net.WriteInt(amount, 16)
    net.SendToServer()
end

local function PaintContainedMaterial(material, x, y, w, h)
    if not material or material:IsError() then return end

    local materialWidth = material:Width()
    local materialHeight = material:Height()

    if materialWidth <= 0 or materialHeight <= 0 then return end

    -- This was calculated by AI

    local scale = math.min(w / materialWidth, h / materialHeight)
    local drawWidth = math.floor(materialWidth * scale)
    local drawHeight = math.floor(materialHeight * scale)
    local drawX = x + math.floor((w - drawWidth) * 0.5)
    local drawY = y + math.floor((h - drawHeight) * 0.5)

    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(material)
    surface.DrawTexturedRect(drawX, drawY, drawWidth, drawHeight)
end

local PANEL = {}

function PANEL:Init()
    ixHousePoints = ixHousePoints

    -- Set size to full screen. And make it a popup so it gets mouse input

    self:SetSize(ScrW(), ScrH())
    self:MakePopup()

    self.container = self:Add("DPanel")
    self.container:Dock(FILL)
    self.container:SetPaintBackground(false)

    self:Build()

    if CanEditHousePoints() then
        local reset = self:Add("DButton")
        reset:SetText("RESET ALL")
        reset:Dock(BOTTOM)

        reset.DoClick = function()
            Derma_Query(
                "Seguro que quieres resetear todos los puntos?",
                "Confirmacion",
                "Si",
                function()
                    net.Start("ixHousePointsReset")
                    net.SendToServer()
                end,
                "No",
                function() end
            )
        end
    end
end

function PANEL:Build()
    self.container:Clear()
    self.houseCards = {}

    for _, key in ipairs(HOUSES) do
        self:AddHouseCard(key)
    end

    -- Recalculate layout after building cards
    self:InvalidateLayout(true)
end

function PANEL:AddHouseCard(key)
    local color = GetHouseColor(key)
    local displayName = GetHouseName(key)
    local canEdit = CanEditHousePoints()

    local card = self.container:Add("DPanel")
    card:Dock(LEFT)
    card:DockMargin(0, 0, 16, 0)

    -- Rounded edges and background color based on house color with some transparency
    function card:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(color.r, color.g, color.b, 200))
    end

    -- Add house
    local title = card:Add("DLabel")
    title:SetText(displayName)
    title:SetFont("DermaLarge")
    title:SetTextColor(color_white)
    title:SetContentAlignment(5)
    title:Dock(TOP)
    title:SetTall(56)
    title:DockMargin(12, 12, 12, 0)

    if canEdit then

        -- Add controls to modify points
        local controls
        controls = card:Add("DPanel")
        controls:Dock(BOTTOM)
        controls:SetTall(44)
        controls:DockMargin(16, 0, 16, 16)
        controls:SetPaintBackground(false)

        -- Center panel
        local center = controls:Add("DPanel")
        card.center = center
        center:Dock(FILL)
        center:DockMargin(100, 0, 100, 0)

        local minus = center:Add("DButton")
        minus:SetText("-")

        minus:Dock(LEFT)
        minus:SetWide(32)
        minus:SetPaintBackground(false)

        local amountInput = center:Add("DNumberWang")
        amountInput:Dock(FILL)
        amountInput:SetFont("DermaLarge")
        amountInput:HideWang()
  
        amountInput:SetMin(1)
        amountInput:SetMax(300)
        amountInput:SetValue(10)
        
        -- Background color
        amountInput.Paint = function(self, w, h)
            surface.SetDrawColor(color.r, color.g, color.b, 200)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 220))
            --self:DrawTextEntryText(color_white, Color(80, 140, 255), color_white)
            draw.SimpleText(self:GetValue(), self:GetFont(), w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        end

        local plus = center:Add("DButton")
        plus:SetText("+")

        plus:Dock(RIGHT)
        plus:SetWide(32)
        plus:SetPaintBackground(false)

        minus.DoClick = function()
            SendHousePointsChange(key, -math.floor(amountInput:GetValue()))
        end

        plus.DoClick = function()
            SendHousePointsChange(key, math.floor(amountInput:GetValue()))
        end
    end

    local points = card:Add("DLabel")
    points:Dock(BOTTOM)
    points:SetTall(52)

    points:SetFont("DermaLarge")
    points:SetTextColor(color_white)
    points:SetContentAlignment(5)


    function points:Think()
        self:SetText(tostring(ixHousePoints[key]) .. " puntos")
    end

    local houseMaterial = Material(HOUSE_IMAGES[key], "smooth")
    local image = card:Add("DPanel")
    image:Dock(FILL)

    function image:Paint(w, h)
        -- 8% margin
        local inset = math.max(8, math.floor(math.min(w, h) * 0.08))

        PaintContainedMaterial(houseMaterial, inset, inset, w - inset * 2, h - inset * 2)
    end

    self.houseCards[#self.houseCards + 1] = card
end

-- Calculated by AI
function PANEL:PerformLayout()
    local screenWidth = ScrW()
    local screenHeight = ScrH()

    self:SetSize(screenWidth, screenHeight)
    self:SetPos(0, 0)

    local marginX = math.max(20, math.floor(screenWidth * 0.025))
    local marginY = math.max(28, math.floor(screenHeight * 0.06))
    local resetSpace = CanEditHousePoints() and 76 or 0

    self.container:DockMargin(marginX, marginY, marginX, marginY + resetSpace)

    local gap = math.max(10, math.floor(screenWidth * 0.008))
    local cardWidth = math.floor((screenWidth - marginX * 2 - gap * (#HOUSES - 1)) / #HOUSES)

    for index, card in ipairs(self.houseCards or {}) do
        card:SetWide(cardWidth)
        card:DockMargin(0, 0, index == #HOUSES and 0 or gap, 0)
        card.center:DockMargin(cardWidth / 3, 0, cardWidth / 3, 0)
    end

end

-- Background blur and dark overlay
function PANEL:Paint(w, h)
    ix.util.DrawBlur(self, 4)
    surface.SetDrawColor(8, 8, 8, 220)
end

-- Update points
function PANEL:Think()
    if self.lastUpdate ~= ixHousePoints then
        self.lastUpdate = ixHousePoints
        self:Build()
    end
end

vgui.Register("ixHousePointsPanel", PANEL, "EditablePanel")

-- Is better use PlayerButtonDown?
hook.Add("Think", "ixHousePointsF2", function()
    if not input.IsKeyDown(KEY_F2) then
        ix._f2Pressed = false
        return
    end

    if ix._f2Pressed then return end
    ix._f2Pressed = true

    if IsValid(ix.housePointsPanel) then
        ix.housePointsPanel:Remove()
    else
        ix.housePointsPanel = vgui.Create("ixHousePointsPanel")
    end
end)
