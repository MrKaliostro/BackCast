local KaliBackCast = {}

local MainOption = Menu.AddOptionBool({"Utility", "KaliBackCast"}, "Enable", false)
local ToggleKey = Menu.AddKeyOption({"Utility", "KaliBackCast"}, "Toggle Key", Enum.ButtonCode.KEY_NONE)
local PosX = Menu.AddOptionSlider({"Utility", "KaliBackCast"}, "PosX", 0, 3840, 0)
local PosY = Menu.AddOptionSlider({"Utility", "KaliBackCast"}, "PosY", 0, 2160, 0)

local spells = {
	["windrunner_powershot"] = true,
	["queenofpain_sonic_wave"] = true,
	["pudge_meat_hook"] = true,
	["shredder_timber_chain"] = true,
	["lina_dragon_slave"] = true,
	["mars_spear"] = true,
	["keeper_of_the_light_illuminate"] = true,
	["lion_impale"] = true,
	["nyx_assassin_impale"] = true,
	["jakiro_macropyre"] = true,
	["jakiro_ice_path"] = true,
	["jakiro_dual_breath"] = true,
	["death_prophet_carrion_swarm"] = true,
	["shadow_demon_shadow_poison"] = true,
	["drow_ranger_wave_of_silence"] = true,
	["venomancer_venomous_gale"] = true,
	["dragon_knight_breathe_fire"] = true,
	["earthshaker_fissure"] = true,
	["magnataur_shockwave"] = true,
	["vengefulspirit_wave_of_terror"] = true,
	["rattletrap_hookshot"] = true,
	["mirana_arrow"] = true,
	["weaver_the_swarm"] = true,
	["invoker_deafening_blast"] = true,
	["invoker_tornado"] = true,
	["puck_illusory_orb"] = true,
	["spectre_spectral_dagger"] = true,
	["ancient_apparition_ice_blast"] = true,
	["troll_warlord_whirling_axes_ranged"] = true,
	["tiny_toss_tree"] = true,
	["tinker_march_of_the_machines"] = true,
	["elder_titan_earth_splitter"] = true,
	["earth_spirit_rolling_boulder"] = true,
	["phoenix_icarus_dive"] = true,
	["snapfire_scatterblast"] = true,
	["treant_natures_grasp"] = true,
}

local used = false
local myHero
local target_position
local result_vector
local ability
local myHero_position
local lastIteration
local time = os.clock
local TMSfont = Renderer.LoadFont("TimesNewRoman", 19, FONTFLAG_NONE, NORMAL)

function KaliBackCast.SleepReady(variable, delay)
	return (variable + delay <= time())
end

function KaliBackCast.OnDraw() 
	if (Menu.IsEnabled(MainOption)) then
		Renderer.SetDrawColor (0, 255, 0, 255)
		Renderer.DrawText(TMSfont, Menu.GetValue(PosX), Menu.GetValue(PosY), "BackCast:ON")
	else
		Renderer.SetDrawColor (255, 0, 0, 255)
		Renderer.DrawText(TMSfont, Menu.GetValue(PosX), Menu.GetValue(PosY), "BackCast:OFF")
	end
end;


function KaliBackCast.OnUpdate()
	if (Menu.IsKeyDownOnce(ToggleKey)) then
		Menu.SetEnabled(MainOption, not Menu.IsEnabled(MainOption))
	end

	if (not Menu.IsEnabled(MainOption)) then
		myHero = nil
		return
	end
	--Log.Write(NetChannel.GetAvgLatency(Enum.Flow.FLOW_INCOMING) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING))
	if (NetChannel.GetAvgLatency(Enum.Flow.FLOW_INCOMING) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) > 0.035) then
		if used == true and (NPC.GetActivity(myHero) ~= 1502 and not NPC.IsTurning(myHero)) then
			myHero_position = Entity.GetAbsOrigin(myHero)
			result_vector = myHero_position + ((target_position - myHero_position):Normalized())	
			Ability.CastPosition(ability, result_vector, false, false)
			used = false
		end
	else
		if used == true and (NPC.GetActivity(myHero) ~= 1502 and not NPC.IsTurning(myHero)) then
			if KaliBackCast.SleepReady(lastIteration, 0.12) then
				myHero_position = Entity.GetAbsOrigin(myHero)
				result_vector = myHero_position + ((target_position - myHero_position):Normalized())	
				Ability.CastPosition(ability, result_vector, false, false)
				used = false
			end
		end
	end
end

function KaliBackCast.OnPrepareUnitOrders(orders)
	if (not Menu.IsEnabled(MainOption)) then
		myHero = nil;
		return;
	end;
	
	

	myHero = orders.npc
	local ability_name = Ability.GetName(orders.ability)
	--Log.Write(ability_name)
	if not spells[ability_name] then return true end 

	if NPC.FindRotationAngle(orders.npc, orders.position) < 0.4 then return true end 
	if NPC.IsChannellingAbility(myHero) or 
		NPC.HasModifier(myHero, "modifier_teleporting")
	then return true end
	
	if (not (ability_name == "mars_spear" or ability_name == "phoenix_icarus_dive")) 
	and ((Ability.GetCastRange(orders.ability) + NPC.GetCastRangeBonus(myHero)) < (orders.position - Entity.GetAbsOrigin(myHero)):Length2D())
	then return true end
	
	
	if NPC.GetActivity(myHero) == 1502 or NPC.IsTurning(myHero) then
		Player.HoldPosition(orders.player, myHero, false, false) 
		lastIteration = time()
	else
		lastIteration = time() - 1
	end
	ability = orders.ability
	target_position = orders.position
	used = true
	return false
end

return KaliBackCast
