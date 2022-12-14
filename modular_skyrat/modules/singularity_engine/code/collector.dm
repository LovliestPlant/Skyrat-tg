/obj/item/circuitboard/machine/rad_collector
	name = "radiation collector (Machine Board)"
	icon_state = "engineering"
	build_path = /obj/machinery/power/rad_collector
	req_components = list(
		/obj/item/stack/cable_coil = 5,
		/obj/item/stack/sheet/plasmarglass = 2,
		/obj/item/stock_parts/capacitor = 1,
		/obj/item/stock_parts/manipulator = 1)
	needs_anchored = FALSE



// stored_energy += (pulse_strength-RAD_COLLECTOR_EFFICIENCY)*RAD_COLLECTOR_COEFFICIENT
#define RAD_COLLECTOR_EFFICIENCY 80 	// radiation needs to be over this amount to get power
#define RAD_COLLECTOR_COEFFICIENT 100
#define RAD_COLLECTOR_STORED_OUT 0.4	// (this*100)% of stored power outputted per tick. Doesn't actualy change output total, lower numbers just means collectors output for longer in absence of a source
#define RAD_COLLECTOR_MINING_CONVERSION_RATE 0.00001 //This is gonna need a lot of tweaking to get right. This is the number used to calculate the conversion of watts to research points per process()
#define RAD_COLLECTOR_OUTPUT min(stored_energy, (stored_energy*RAD_COLLECTOR_STORED_OUT)+1000) //Produces at least 1000 watts if it has more than that stored

#define GAS_PLASMA "plasma"
#define GAS_TRITIUM "tritium"
#define GAS_CO2 "co2"
#define GAS_O2 "o2"


/obj/machinery/power/rad_collector
	name = "Radiation Collector Array"
	desc = "A device which uses Hawking Radiation and plasma to produce power."
	icon = 'modular_skyrat/modules/aesthetics/emitter/icons/emitter.dmi'
	icon_state = "ca"
	anchored = FALSE
	density = TRUE
	req_access = list(ACCESS_ENGINE_EQUIP)
//	use_power = NO_POWER_USE
	max_integrity = 350
	integrity_failure = 80
	circuit = /obj/item/circuitboard/machine/rad_collector
	rad_insulation = RAD_EXTREME_INSULATION
	var/obj/item/tank/internals/plasma/loaded_tank = null
	var/stored_energy = 0
	var/active = 0
	var/locked = FALSE
	var/drainratio = 0.5
	var/powerproduction_drain = 0.01
	var/bitcoinproduction_drain = 0.15
	var/bitcoinmining = FALSE
	var/obj/item/radio/radio
	
	var/input_power_multiplier = 1
	var/input_efficiency_multiplier = 1

/obj/machinery/power/rad_collector/Initialize(mapload)
	. = ..()

	radio = new(src)
	radio.keyslot = new /obj/item/encryptionkey/headset_eng
	radio.subspace_transmission = TRUE
	radio.canhear_range = 0
	radio.recalculateChannels()

/obj/machinery/power/rad_collector/anchored
	anchored = TRUE

/obj/machinery/power/rad_collector/Destroy()
	QDEL_NULL(radio)
	return ..()

/obj/machinery/power/rad_collector/RefreshParts()
	. = ..()
	var/power_multiplier = 0
	var/efficiency_multiplier = 0
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		power_multiplier += C.rating
	for(var/obj/item/stock_parts/manipulator/C in component_parts)
		efficiency_multiplier += C.rating
	input_power_multiplier = power_multiplier
	input_efficiency_multiplier = efficiency_multiplier

/obj/machinery/power/rad_collector/process(delta_time)
	var/power_produced = get_power_output()
	//to_chat(world, "Rad collector processing, could generate [power_produced] this tick from a total of [stored_energy]")
	if(!loaded_tank)
		return
	//to_chat(world, "Rad collector process passed tank check")
	//to_chat(world, "Rad collector trying to add [power_produced] to grid [powernet]")
	add_avail(power_produced)
	stored_energy -= power_produced
	//to_chat(world, "Rad collector finished processing, stored energy at [stored_energy]")
	/*if(loaded_tank.air_contents.gases[GAS_PLASMA][MOLES] < 0.0001)
		//to_chat(world, "Rad collector plasma depleted")
		//investigate_log("<font color='red'>out of fuel</font>.", INVESTIGATE_ENGINES)
		playsound(src, 'sound/machines/ding.ogg', 50, 1)
		var/msg = "Plasma depleted, recommend replacing tank."
		radio.talk_into(src, msg, RADIO_CHANNEL_ENGINEERING)
		eject()
		//to_chat(world, "Rad collector dumped tank")
	else
		//to_chat(world, "Rad collector trying to power gen")
		//var/gasdrained = min(powerproduction_drain*drainratio*delta_time,loaded_tank.air_contents.gases[GAS_PLASMA][MOLES])
		//loaded_tank.air_contents.remove_specific(GAS_PLASMA, -gasdrained)
		//loaded_tank.air_contents.remove_specific(GAS_TRITIUM, gasdrained)
		//var/power_produced = RAD_COLLECTOR_OUTPUT
		//add_avail(power_produced)
		//stored_energy-=power_produced
		//release_energy(power_produced)
		*/

/obj/machinery/power/rad_collector/interact(mob/user)
	if(anchored)
		if(!src.locked)
			toggle_power()
			user.visible_message("[user.name] turns the [src.name] [active? "on":"off"].", \
			"<span class='notice'>You turn the [src.name] [active? "on":"off"].</span>")
			var/fuel = loaded_tank?.air_contents.gases[GAS_PLASMA][MOLES]
			//investigate_log("turned [active?"<font color='green'>on</font>":"<font color='red'>off</font>"] by [key_name(user)]. [loaded_tank?"Fuel: [round(fuel/0.29)]%":"<font color='red'>It is empty</font>"].", INVESTIGATE_ENGINES)
			return
		else
			to_chat(user, "<span class='warning'>The controls are locked!</span>")
			return

/obj/machinery/power/rad_collector/can_be_unfasten_wrench(mob/user, silent)
	if(loaded_tank)
		if(!silent)
			to_chat(user, "<span class='warning'>Remove the plasma tank first!</span>")
		return FAILED_UNFASTEN
	return ..()

/obj/machinery/power/rad_collector/default_unfasten_wrench(mob/user, obj/item/I, time = 20)
	. = ..()
	if(. == SUCCESSFUL_UNFASTEN)
		if(anchored)
			connect_to_network()
		else
			disconnect_from_network()

/obj/machinery/power/rad_collector/should_have_node()
	return anchored

/obj/machinery/power/rad_collector/proc/get_stored_joules()
	return energy_to_joules(stored_energy)

/obj/machinery/power/rad_collector/proc/get_power_output()
	// Always consume at least 2kJ of energy if we have at least that much stored
	return min(stored_energy, (stored_energy*RAD_COLLECTOR_STORED_OUT)+joules_to_energy(2000))

/obj/machinery/power/rad_collector/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/tank/internals/plasma))
		if(!anchored)
			to_chat(user, "<span class='warning'>[src] needs to be secured to the floor first!</span>")
			return TRUE
		if(loaded_tank)
			to_chat(user, "<span class='warning'>There's already a plasma tank loaded!</span>")
			return TRUE
		if(panel_open)
			to_chat(user, "<span class='warning'>Close the maintenance panel first!</span>")
			return TRUE
		if(!user.transferItemToLoc(W, src))
			return
		loaded_tank = W
		update_icon()
	else if(W.GetID())
		if(allowed(user))
			if(active)
				locked = !locked
				to_chat(user, "<span class='notice'>You [locked ? "lock" : "unlock"] the controls.</span>")
			else
				to_chat(user, "<span class='warning'>The controls can only be locked when \the [src] is active!</span>")
		else
			to_chat(user, "<span class='danger'>Access denied.</span>")
			return TRUE
	else
		return ..()

/obj/machinery/power/rad_collector/wrench_act(mob/living/user, obj/item/I)
	default_unfasten_wrench(user, I)
	return TRUE

/obj/machinery/power/rad_collector/screwdriver_act(mob/living/user, obj/item/I)
	if(..())
		return TRUE
	if(loaded_tank)
		to_chat(user, "<span class='warning'>Remove the plasma tank first!</span>")
	else
		default_deconstruction_screwdriver(user, icon_state, icon_state, I)
	return TRUE

/obj/machinery/power/rad_collector/crowbar_act(mob/living/user, obj/item/I)
	if(loaded_tank)
		if(locked)
			to_chat(user, "<span class='warning'>The controls are locked!</span>")
			return TRUE
		eject()
		return TRUE
	if(default_deconstruction_crowbar(I))
		return TRUE
	to_chat(user, "<span class='warning'>There isn't a tank loaded!</span>")
	return TRUE

/obj/machinery/power/rad_collector/multitool_act(mob/living/user, obj/item/I)
	if(!is_station_level(z) && !SSresearch.science_tech)
		to_chat(user, "<span class='warning'>[src] isn't linked to a research system!</span>")
		return TRUE
	if(locked)
		to_chat(user, "<span class='warning'>[src] is locked!</span>")
		return TRUE
	if(active)
		to_chat(user, "<span class='warning'>[src] is currently active, producing [bitcoinmining ? "research points":"power"].</span>")
		return TRUE
	bitcoinmining = !bitcoinmining
	to_chat(user, "<span class='warning'>You [bitcoinmining ? "enable":"disable"] the research point production feature of [src].</span>")
	return TRUE

/obj/machinery/power/rad_collector/return_analyzable_air()
	if(loaded_tank)
		return loaded_tank.return_analyzable_air()
	else
		return null

/obj/machinery/power/rad_collector/examine(mob/user)
	. = ..()
	if(active)
		if(!bitcoinmining)
			// stored_energy is converted directly to watts every SSmachines.wait * 0.1 seconds.
			// Therefore, its units are joules per SSmachines.wait * 0.1 seconds.
			// So joules = stored_energy * SSmachines.wait * 0.1
			var/joules = stored_energy * SSmachines.wait * 0.1
			. += "<span class='notice'>[src]'s display states that it has stored <b>[display_joules(joules)]</b>, and is processing <b>[display_power(RAD_COLLECTOR_OUTPUT)]</b>.</span>"
		else
			. += "<span class='notice'>[src]'s display states that it has stored a total of <b>[stored_energy*RAD_COLLECTOR_MINING_CONVERSION_RATE]</b>, and is producing [RAD_COLLECTOR_OUTPUT*RAD_COLLECTOR_MINING_CONVERSION_RATE] research points per minute.</span>"
	else
		if(!bitcoinmining)
			. += "<span class='notice'><b>[src]'s display displays the words:</b> \"Power production mode. Please insert <b>Plasma</b>. Use a multitool to change production modes.\"</span>"
		else
			. += "<span class='notice'><b>[src]'s display displays the words:</b> \"Research point production mode. Please insert <b>Tritium</b> and <b>Oxygen</b>. Use a multitool to change production modes.\"</span>"

/*/obj/machinery/power/rad_collector/obj_break(damage_flag)
	. = ..()
	if(.)
		eject()*/

/obj/machinery/power/rad_collector/proc/eject()
	locked = FALSE
	var/obj/item/tank/internals/plasma/Z = src.loaded_tank
	if (!Z)
		return
	Z.forceMove(drop_location())
	Z.layer = initial(Z.layer)
	Z.plane = initial(Z.plane)
	src.loaded_tank = null
	if(active)
		toggle_power()
	else
		update_icon()

/*/obj/machinery/power/rad_collector/rad_act(pulse_strength)
	. = ..()
	if(loaded_tank && active && pulse_strength > RAD_COLLECTOR_EFFICIENCY)
		stored_energy += (pulse_strength-RAD_COLLECTOR_EFFICIENCY)*RAD_COLLECTOR_COEFFICIENT*/

/obj/machinery/power/rad_collector/proc/on_pre_potential_irradiation(datum/source, datum/radiation_pulse_information/pulse_information, insulation_to_target)
	SIGNAL_HANDLER
	
	//to_chat(world, "Rad collector zapped!")
	
	if(loaded_tank && active && pulse_information.threshold > (RAD_COLLECTOR_EFFICIENCY/input_efficiency_multiplier))
		flick("ca_zapped", src)
		stored_energy += (pulse_information.threshold-(RAD_COLLECTOR_EFFICIENCY/input_efficiency_multiplier))*RAD_COLLECTOR_COEFFICIENT*input_power_multiplier

/obj/machinery/power/rad_collector/update_icon()
	cut_overlays()
	if(loaded_tank)
		add_overlay("ptank")
	if(machine_stat & (NOPOWER|BROKEN))
		return
	if(active)
		add_overlay("on")


/obj/machinery/power/rad_collector/proc/toggle_power()
	active = !active
	if(active)
		icon_state = "ca_on"
		flick("ca_active", src)
		RegisterSignal(src, COMSIG_IN_RANGE_OF_IRRADIATION, PROC_REF(on_pre_potential_irradiation))
		ADD_TRAIT(src, TRAIT_RADIATION_MACHINERY, REF(src))
	else
		icon_state = "ca"
		flick("ca_deactive", src)
		UnregisterSignal(src, COMSIG_IN_RANGE_OF_IRRADIATION, PROC_REF(on_pre_potential_irradiation))
		REMOVE_TRAIT(src, TRAIT_RADIATION_MACHINERY, REF(src))
	update_icon()
	return

#undef RAD_COLLECTOR_EFFICIENCY
#undef RAD_COLLECTOR_COEFFICIENT
#undef RAD_COLLECTOR_STORED_OUT
#undef RAD_COLLECTOR_MINING_CONVERSION_RATE
#undef RAD_COLLECTOR_OUTPUT
