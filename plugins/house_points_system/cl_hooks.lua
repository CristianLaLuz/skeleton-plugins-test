net.Receive("ixHousePointsUpdate", function()
    ixHousePoints = net.ReadTable()
end)

local function GetHouseColor(name)
    local faction = ix.faction.Get(string.lower(name))
    if faction and faction.color then
        return faction.color
    end

    return Color(255, 255, 255)
end

local PANEL = {}

function PANEL:Init()
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

    local function AddRow(name, color)
        local row = self.list:Add("DPanel")
        row:SetTall(40)

        function row:Paint(w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(30, 30, 30))
            draw.SimpleText(
                name .. ": " .. (ixHousePoints[name] or 0),
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
                    net.WriteString(name)
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
                    net.WriteString(name)
                    net.WriteInt(-amount, 16)
                net.SendToServer()
            end
        end

        self.list:AddItem(row)
    end

    -- Revise this
    local houses = {"gryffindor", "slytherin", "ravenclaw", "hufflepuff"}

    for _, name in ipairs(houses) do
        AddRow(name, GetHouseColor(name))
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
    if not input.IsKeyDown(KEY_F2) then return end

    if not ix._f2Pressed then
        ix._f2Pressed = true

        if IsValid(ix.housePointsPanel) then
            ix.housePointsPanel:Remove()
        else
            ix.housePointsPanel = vgui.Create("ixHousePointsPanel")
        end
    end
end)

hook.Add("Think", "ixHousePointsF2Reset", function()
    if not input.IsKeyDown(KEY_F2) then
        ix._f2Pressed = false
    end
end)
