ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Sombrero Seleccionador"
ENT.Spawnable = true

local SORTINGHAT_TIMEOUT = 30

local HOGWARTS_HOUSES = {
    FACTION_GRYFFINDOR,
    FACTION_SLYTHERIN,
    FACTION_RAVENCLAW,
    FACTION_HUFFLEPUFF
}

--Duration is based on the length of the sound | TODO: if file not found, what happens?
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
        {sound = "sortinghat/sombrero_seleccionador_Hufflepuff_2.mp3", duration = 4.5}
    }
}

local SELECTED_HOUSE_SOUNDS = {
    [FACTION_GRYFFINDOR] = "sortinghat/sombrero_seleccionador_Gryffindor.mp3",
    [FACTION_SLYTHERIN] = "sortinghat/sombrero_seleccionador_Slytherin.mp3",
    [FACTION_RAVENCLAW] = "sortinghat/sombrero_seleccionador_Ravenclaw.mp3",
    [FACTION_HUFFLEPUFF] = "sortinghat/sombrero_seleccionador_Hufflepuff.mp3"
}

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "User")
    self:NetworkVar("Bool", 0, "Locked")
end

function ENT:GetTimeoutName()
    return "SortingHat_Timeout_" .. self:EntIndex()
end

function ENT:ClearUser()
    timer.Remove(self:GetTimeoutName())

    self:SetUser(NULL)
    self:SetLocked(false)
    self._userCharID = nil
    self._session = (self._session or 0) + 1
end

function ENT:OnRemove()
    if SERVER then
        self:ClearUser()
    end
end

if SERVER then
    -- AddCSLuaFile() TODO: revise this

    util.AddNetworkString("SortingHat_Sound")

    function ENT:Initialize()
        self:SetModel("models/genosrp/sombrero_seleccionador/sombrero_seleccionador.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end
    end

    -- Function to play a sound for players around the hat, with distance-based volume attenuation

    function ENT:PlayHatSound(soundPath)
        net.Start("SortingHat_Sound")
            net.WriteEntity(self)
            net.WriteString(soundPath)
        net.SendPVS(self:GetPos())
    end

    -- Validates the session and character to ensure the hat is being used by the correct player and character

    function ENT:IsSessionValid(client, session, charID)
        if self._session ~= session or self:GetUser() ~= client then
            return false
        end

        if not IsValid(client) then
            self:ClearUser()
            return false
        end

        local character = client:GetCharacter()
        if not character or character:GetID() ~= charID then
            self:ClearUser()
            return false
        end

        return character
    end

    -- Timeout and cleanup logic to prevent the hat from being locked indefinitely

    function ENT:StartTimeout(client, session, charID)
        timer.Create(self:GetTimeoutName(), SORTINGHAT_TIMEOUT, 1, function()
            if not IsValid(self) then return end
            if self._session ~= session then return end

            self:ClearUser()

            if IsValid(client) then
                print(string.format("El lock del Sombrero Seleccionador para %s se ha liberado por timeout.", client:Nick()))
            end
        end)
    end

    function ENT:Use(client)
        if not IsValid(client) or not client:IsPlayer() then return end

        local character = client:GetCharacter()
        if not character or character:GetFaction() ~= FACTION_ESTUDIANTE then
            client:Notify("Solo los estudiantes sin casa pueden usar este objeto.")
            return
        end

        local currentUser = self:GetUser()
        if self:GetLocked() and not IsValid(currentUser) then
            self:ClearUser()
            currentUser = self:GetUser()
        end

        if self:GetLocked() or IsValid(currentUser) then
            if currentUser == client then
                client:ChatPrint("Ya estas usando el Sombrero Seleccionador.")
            else
                client:ChatPrint("El Sombrero ya esta en uso.")
            end

            return
        end

        local charID = character:GetID()

        -- Lock the hat for this user

        self._session = (self._session or 0) + 1
        local session = self._session

        self:SetLocked(true)
        self:SetUser(client)
        self._userCharID = charID
        self:StartTimeout(client, session, charID)

        ix.chat.Send(client, "it", "Has usado el Sombrero Seleccionador. Se te asignara una casa al azar.")

        -- Randomly select a house and play the corresponding sound

        local newFaction = character:GetData("sortingHatPendingFaction")
        if not HOUSE_SOUNDS[newFaction] then
            newFaction = table.Random(HOGWARTS_HOUSES)
            character:SetData("sortingHatPendingFaction", newFaction)
        end

        local firstSound = table.Random(HOUSE_SOUNDS[newFaction])
        local finalSound = SELECTED_HOUSE_SOUNDS[newFaction]
        local faction = ix.faction.indices[newFaction]
        local houseName = faction and faction.name or "desconocida"

        -- Console print, add admin group or faction staff
        print(string.format("%s ha sido asignado a la casa de %s", character:GetName(), houseName))

        self:PlayHatSound(firstSound.sound)

        -- Wait for the first sound to finish before assigning the house and playing the final sound

        timer.Simple(firstSound.duration + 1, function()
            if not IsValid(self) then return end

            local currentCharacter = self:IsSessionValid(client, session, charID)
            if not currentCharacter then return end

            -- Last assign the house and play the final sound

            self:PlayHatSound(finalSound)
            client:SetWhitelisted(newFaction, true)
            currentCharacter:SetFaction(newFaction)
            currentCharacter:SetData("sortingHatPendingFaction", nil)

            ix.chat.Send(client, "sortinghat",
                "Felicidades " .. currentCharacter:GetName() ..
                "! Has sido asignado a la casa de " .. houseName .. "!"
            )

            self:ClearUser()
        end)
    end

    -- Cleanup on disconnect or character change

    hook.Add("PlayerDisconnected", "SortingHat_ClearUser", function(client)
        for _, ent in ipairs(ents.FindByClass("ix_sortinghat")) do
            if IsValid(ent) and ent:GetUser() == client then
                ent:ClearUser()
            end
        end
    end)

    hook.Add("PlayerLoadedCharacter", "SortingHat_ClearUserOnCharChange", function(client, character)
        for _, ent in ipairs(ents.FindByClass("ix_sortinghat")) do
            if IsValid(ent) and ent:GetUser() == client and (not character or ent._userCharID ~= character:GetID()) then
                ent:ClearUser()
            end
        end
    end)
end
