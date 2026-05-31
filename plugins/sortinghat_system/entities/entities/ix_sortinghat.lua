ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Sombrero Seleccionador"
ENT.Spawnable = true

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("SortingHat_Sound")

    function ENT:Initialize()
        self:SetModel("models/genosrp/sombrero_seleccionador/sombrero_seleccionador.mdl")

        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end

        self:SetUseType(SIMPLE_USE)
    end
end

function ENT:Use(client)

    -- add a check only one use at a time
    -- revise if player disconnects while using the hat

    if not IsValid(client) or not client:IsPlayer() then
        return
    end

    local character = client:GetCharacter()

    if not character or character:GetFaction() ~= FACTION_ESTUDIANTE then
        client:Notify("Solo los estudiantes sin casa pueden usar este objeto.")
        return
    end

    ix.chat.Send(client, "it",
        "¡Has usado el Sombrero Seleccionador! Se te asignará una casa al azar."
    )

    local HOGWARTS_HOUSES = {
        FACTION_GRYFFINDOR,
        FACTION_SLYTHERIN,
        FACTION_RAVENCLAW,
        FACTION_HUFFLEPUFF
    }

    -- Duration is based on the length of the sound, we will use a timer to play the selected sound after the sorting sound has finished
    local HOUSE_SOUNDS = {
        [FACTION_GRYFFINDOR] = {
            {sound = "sortinghat/sombrero_seleccionador_Gryffindor_1.mp3", duration = 9.5},
            {sound = "sortinghat/sombrero_seleccionador_Gryffindor_2.mp3", duration = 9.5},
            {sound = "sortinghat/sombrero_seleccionador_Gryffindor_3.mp3", duration = 6.5}
        },
        [FACTION_SLYTHERIN] = {
            {sound = "sortinghat/sombrero_seleccionador_Slytherin_1.mp3", duration = 9.5},
            {sound = "sortinghat/sombrero_seleccionador_Slytherin_2.mp3", duration = 6.5},
            {sound = "sortinghat/sombrero_seleccionador_Slytherin_3.mp3", duration = 6.5}
        },
        [FACTION_RAVENCLAW] = {
            {sound = "sortinghat/sombrero_seleccionador_Ravenclaw_1.mp3", duration = 8.5},
            {sound = "sortinghat/sombrero_seleccionador_Ravenclaw_2.mp3", duration = 5.5},
            {sound = "sortinghat/sombrero_seleccionador_Ravenclaw_3.mp3", duration = 4.5}
        },
        [FACTION_HUFFLEPUFF] = {
            {sound = "sortinghat/sombrero_seleccionador_Hufflepuff_1.mp3", duration = 5.5},
            {sound = "sortinghat/sombrero_seleccionador_Hufflepuff_2.mp3", duration = 4.5},
        }
    }

    local HOUSE_SOUNDS_SELECTED = {
        [FACTION_GRYFFINDOR] = {
            "sortinghat/sombrero_seleccionador_Gryffindor.mp3"
        },
        [FACTION_SLYTHERIN] = {
            "sortinghat/sombrero_seleccionador_Slytherin.mp3"
        },
        [FACTION_RAVENCLAW] = {
            "sortinghat/sombrero_seleccionador_Ravenclaw.mp3"
        },
        [FACTION_HUFFLEPUFF] = {
            "sortinghat/sombrero_seleccionador_Hufflepuff.mp3"
        }
    }

    local newFaction = table.Random(HOGWARTS_HOUSES)
    

    local faction = ix.faction.indices[newFaction]
    local houseName = faction and faction.name
    local name = character:GetName()

    local entry = table.Random(HOUSE_SOUNDS[newFaction])
    local soundPath = entry.sound

    net.Start("SortingHat_Sound")
        net.WriteEntity(self)
        net.WriteString(soundPath)
    net.SendPVS(self:GetPos())

    -- timer to play the selected sound after the sorting sound has finished

    timer.Simple(entry.duration + 1, function()
        if not IsValid(self) then return end

        local selectedSound = table.Random(HOUSE_SOUNDS_SELECTED[newFaction])

        net.Start("SortingHat_Sound")
            net.WriteEntity(self)
            net.WriteString(selectedSound)
        net.SendPVS(self:GetPos())


        -- Last set the player's faction to the new one and whitelist them
        timer.Simple(3, function()
            if not IsValid(self) or not IsValid(client) then return end

            character:SetFaction(newFaction)
            client:SetWhitelisted(newFaction, true)

            -- Console print 
            ix.chat.Send(client, "sortinghat",
                "¡Felicidades " .. name .. "! Has sido asignado a la casa de " .. houseName .. "!"
            )

            print(string.format("%s ha sido asignado a la casa de %s", name, houseName))
        end)
    end)

end