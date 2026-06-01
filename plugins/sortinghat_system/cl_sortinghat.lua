net.Receive("SortingHat_Sound", function()
    local ent = net.ReadEntity()
    local soundPath = net.ReadString()

    if not IsValid(ent) then return end

    local dist = LocalPlayer():GetPos():Distance(ent:GetPos())

    -- max distance for hearing the sound
    if dist > 1000 then
        return
    end

    sound.Play(soundPath, ent:GetPos(), 85, 100, 1)
end)