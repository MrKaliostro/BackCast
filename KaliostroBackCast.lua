local KaliBackCast = {}

local MainOption = Menu.AddOptionBool({"Utility", "KaliBackCast"}, "Enable", false)
local ToggleKey = Menu.AddKeyOption({"Utility", "KaliBackCast"}, "Toggle Key", Enum.ButtonCode.KEY_NONE)
local PosX = Menu.AddOptionSlider({"Utility", "KaliBackCast"}, "PosX", 0, 3840, 0)
local PosY = Menu.AddOptionSlider({"Utility", "KaliBackCast"}, "PosY", 0, 2160, 0)

local spells = {
	"pudge_meat_hook",
	"windrunner_powershot",
	"death_prophet_carrion_swarm",
	"mars_spear",
	"vengefulspirit_wave_of_terror",
	"rattletrap_hookshot",
	"mirana_arrow",
	"queenofpain_sonic_wave",
	"keeper_of_the_light_illuminate",
	"drow_ranger_wave_of_silence",
	"dragon_knight_breathe_fire",
	"nyx_assassin_impale",
	"earthshaker_fissure",
	"shredder_timber_chain",
	"jakiro_ice_path",
	"venomancer_venomous_gale",
	"weaver_the_swarm",
	"invoker_deafening_blast",
	"invoker_tornado",
	"jakiro_dual_breath",
	"jakiro_ice_path",
	"jakiro_macropyre",
	"lina_dragon_slave",
	"lina_laguna_blade",
	"lion_impale",
	"magnataur_shockwave",
	"phoenix_icarus_dive",
	"puck_illusory_orb",
	"shadow_demon_shadow_poison",
	"spectre_spectral_dagger",
	"tidehunter_gush",
	"ancient_apparition_ice_blast",
	"troll_warlord_whirling_axes_ranged",
	"earth_spirit_rolling_boulder"
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
	--Log.Write(orders.order)
	
	if orders.order ~= 5 then return true end
	myHero = Heroes.GetLocal()
	local ability_name = Ability.GetName(orders.ability)
	--Log.Write(ability_name)
	local enable = false
	for i, name in pairs(spells) do
		if ability_name == name then
			enable = true
			break
		end
	end
	if not enable then return true end 
	if not (ability_name == "phoenix_icarus_dive") and
	(NPC.IsChannellingAbility(myHero) or 
	NPC.HasModifier(myHero, "modifier_teleporting") or
	((Ability.GetCastRange(orders.ability) + NPC.GetCastRangeBonus(myHero)) < (orders.position - Entity.GetAbsOrigin(myHero)):Length2D()))
	then return true end
	
	if NPC.GetActivity(myHero) == 1502 or NPC.IsTurning(myHero) then
		Player.HoldPosition(orders.player, myHero, false, false) 
	end
	ability = orders.ability
	target_position = orders.position
	used = true
	lastIteration = time()
	
	return false
end

return KaliBackCast