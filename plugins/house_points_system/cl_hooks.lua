net.Receive("ixHousePointsUpdate", function()
    ixHousePoints = net.ReadTable()
end)

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

local PANEL = {}
local HOUSES = {"gryffindor", "slytherin", "ravenclaw", "hufflepuff"}

function PANEL:Init()
    -- TODO: care size, test in other resolutions
    self:SetSize(400, 300)
    self:Center()
    self:MakePopup()

    ixHousePoints = ixHousePoints or {}

    self.list = self:Add("DPanelList")
    self.list:Dock(FILL)
    self.list:EnableVerticalScrollbar(true)

    self:Build()

    if LocalPlayer():IsAdmin() and ix.config.Get("canModifyHousePoints", false) then
        local reset = self:Add("DButton")
        reset:Dock(BOTTOM)
        reset:SetText("RESET ALL")

        reset.DoClick = function()
            Derma_Query(
                "¿Seguro que quieres resetear todos los puntos?",
                "Confirmación",
                "Sí",
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
    self.list:Clear()

    local function AddRow(key, displayName, color)
        local row = self.list:Add("DPanel")
        row:SetTall(40)

        function row:Paint(w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(30, 30, 30))
            draw.SimpleText(
                displayName .. ": " .. (ixHousePoints[key] or 0),
                "DermaDefaultBold",
                10, 12,
                color
            )
        end

        local canEdit = LocalPlayer():IsAdmin() and ix.config.Get("canModifyHousePoints", false)

        if canEdit then

            local amountInput = row:Add("DNumberWang")
            amountInput:Dock(RIGHT)
            amountInput:SetWide(50)
            amountInput:SetMin(1)
            amountInput:SetMax(100)
            amountInput:SetValue(10)

            local add = row:Add("DButton")
            add:SetText("+")
            add:Dock(RIGHT)
            add:SetWide(30)
            add.DoClick = function()
                local amount = math.floor(amountInput:GetValue())

                net.Start("ixHousePointsModify")
                    net.WriteString(key)
                    net.WriteInt(amount, 16)
                net.SendToServer()
            end

            local sub = row:Add("DButton")
            sub:SetText("-")
            sub:Dock(RIGHT)
            sub:SetWide(30)
            sub.DoClick = function()
                local amount = math.floor(amountInput:GetValue())

                net.Start("ixHousePointsModify")
                    net.WriteString(key)
                    net.WriteInt(-amount, 16)
                net.SendToServer()
            end
        end

        self.list:AddItem(row)
    end

    for _, key in ipairs(HOUSES) do
        AddRow(key, GetHouseName(key), GetHouseColor(key))
    end
end

function PANEL:Think()
    if self.lastUpdate ~= ixHousePoints then
        self.lastUpdate = ixHousePoints
        self:Build()
    end
end


vgui.Register("ixHousePointsPanel", PANEL, "DFrame")

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
