net.Receive("SortingHat_Sound", function()
    local ent = net.ReadEntity()
    local soundPath = net.ReadString()

    if not IsValid(ent) then return end

    local dist = LocalPlayer():GetPos():Distance(ent:GetPos())

    if dist > 750 then
        return
    end

    local volume = 1

    if dist > 500 then
        volume = 1 - ((dist - 500) / 250)
    end

    sound.Play(soundPath, ent:GetPos(), 75, 100, volume)
end)