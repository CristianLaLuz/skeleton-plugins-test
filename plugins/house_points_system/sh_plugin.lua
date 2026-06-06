PLUGIN.name = "Puntos de casa"
PLUGIN.author = "CristianLaLuz"
PLUGIN.description = "Sistema para gestionar puntos de casa"

ix.util.Include("sv_hooks.lua")
ix.util.Include("cl_hooks.lua")
ix.util.Include("sh_commands.lua")

ix.config.Add("canModifyHousePoints", true, "Permite modificar los puntos de las casas desde el menú.", nil, {
    category = "Houses"
})