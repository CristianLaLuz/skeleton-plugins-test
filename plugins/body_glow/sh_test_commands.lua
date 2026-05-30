ix.command.Add("BodyGlowTestAlpha", {
	description = "Comando temporal para probar transparencia con Body Glow.",
	privilege = "Manage Body Glow",
	adminOnly = true,
	arguments = bit.bor(ix.type.number, ix.type.optional),
	OnRun = function(self, client, alpha)
		alpha = math.Clamp(math.Round(alpha or 255), 0, 255)

		client:SetRenderMode(RENDERMODE_TRANSALPHA)
		client:SetColor(Color(255, 255, 255, alpha))

		client:Notify(string.format("Alpha del jugador establecido en %d.", alpha))
	end
})

ix.command.Add("BodyGlowResetAlpha", {
	description = "Restaura la transparencia usada por BodyGlowTestAlpha.",
	privilege = "Manage Body Glow",
	adminOnly = true,
	OnRun = function(self, client)
		client:SetRenderMode(RENDERMODE_NORMAL)
		client:SetColor(color_white)

		client:Notify("Alpha del jugador restaurado.")
	end
})
