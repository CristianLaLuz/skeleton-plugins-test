PLUGIN.bodyGlowPartAliases = {
	pecho = "chest",
	cabeza = "head",
	manoizquierda = "lefthand",
	manoderecha = "righthand",
	pieizquierdo = "leftfoot",
	piederecho = "rightfoot",
	lefthand = "lefthand",
	righthand = "righthand",
	leftfoot = "leftfoot",
	rightfoot = "rightfoot"
}

PLUGIN.bodyGlowParts = {
	chest = {
		bones = {
			"ValveBiped.Bip01_Spine2",
			"ValveBiped.Bip01_Spine1",
			"ValveBiped.Bip01_Spine"
		}
	},
	head = {
		bones = {"ValveBiped.Bip01_Head1"}
	},
	lefthand = {
		bones = {"ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_L_Forearm"}
	},
	righthand = {
		bones = {"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_R_Forearm"}
	},
	leftfoot = {
		bones = {"ValveBiped.Bip01_L_Foot", "ValveBiped.Bip01_L_Calf"}
	},
	rightfoot = {
		bones = {"ValveBiped.Bip01_R_Foot", "ValveBiped.Bip01_R_Calf"}
	}
}

PLUGIN.bodyGlowStyles = {
	default = "sprites/light_glow02_add",
	orange = "sprites/orangeglow1",
	red = "sprites/redglow1",
	core = "sprites/orangecore1",
	core2 = "sprites/orangecore2",
	flare = "sprites/orangeflare1",
	flare2 = "sprites/flare6",
	phys = "sprites/physg_glow1",
	phys2 = "sprites/physg_glow2",
	pickup = "sprites/gmdm_pickups/light",
	redmp = "sprites/redglow_mp1"
}

PLUGIN.bodyGlowVisibility = {
	hideWhenNoDraw = true,
	hideWhenTransparent = true,
	transparentAlphaThreshold = 250,
	netVars = {
		"invisible",
		"stealthed",
		"cloaked"
	},
	localVars = {
		"observer"
	},
	nwBools = {
		"invisible",
		"stealth",
		"stealthed",
		"cloaked"
	}
}

function PLUGIN:GetBodyGlowPartKey(part)
	part = string.lower(part or "chest")

	return self.bodyGlowPartAliases[part] or part
end

function PLUGIN:GetBodyGlowStyleKey(style)
	style = string.lower(style or "default")

	return self.bodyGlowStyles[style] and style or nil
end
