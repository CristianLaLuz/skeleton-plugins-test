-- Save points

util.AddNetworkString("ixHousePointsUpdate")
util.AddNetworkString("ixHousePointsModify")
util.AddNetworkString("ixHousePointsReset")

local DEFAULT_HOUSE_POINTS = {
    gryffindor = 0,
    slytherin = 0,
    ravenclaw = 0,
    hufflepuff = 0
}

function PLUGIN:InitializedPlugins()
    self.houses = ix.data.Get("housePoints", table.Copy(DEFAULT_HOUSE_POINTS))
end

function PLUGIN:SyncHousePoints()
    net.Start("ixHousePointsUpdate")
        net.WriteTable(self.houses)
    net.Broadcast()
end

function PLUGIN:SaveHousePoints()
    ix.data.Set("housePoints", self.houses)
    self:SyncHousePoints()
end

function PLUGIN:PlayerInitialSpawn(client)
    net.Start("ixHousePointsUpdate")
        net.WriteTable(self.houses)
    net.Send(client)
end

-- Modify points

net.Receive("ixHousePointsModify", function(_, ply)
    if not ix.config.Get("canModifyHousePoints", false) then return end
    if not ply:IsAdmin() then return end
    -- if not ply:HasPrivilege("Manage House Points") then return end

    local house = net.ReadString()
    local amount = net.ReadInt(16)

    amount = math.Clamp(amount, -100, 100)

    local plugin = ix.plugin.Get("house_points_system")
    if not plugin or not plugin.houses or plugin.houses[house] == nil then return end

    plugin.houses[house] = math.max(0, plugin.houses[house] + amount)

    -- Console print
    print(string.format("%s ha modificado los puntos de %s en %d. Total: %d", ply:Nick(), house, amount, plugin.houses[house]))

    plugin:SaveHousePoints()
end)

net.Receive("ixHousePointsReset", function(len, ply)
    if not ply:IsAdmin() then return end
    if not ix.config.Get("canModifyHousePoints", false) then return end

    local plugin = ix.plugin.Get("house_points_system")
    if not plugin then return end

    plugin.houses = table.Copy(DEFAULT_HOUSE_POINTS)

    plugin:SaveHousePoints()
end)
