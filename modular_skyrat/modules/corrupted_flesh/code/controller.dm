#define CORE_DAMAGE_WIREWEED_ACTIVATION_RANGE 6
#define GENERAL_DAMAGE_WIREWEED_ACTIVATION_RANGE 2
#define SPREAD_PROGRESS_REQUIRED 100

/// A list of objects that are considered part of a door, used to determine if a wireweed should attack it.
#define DOOR_OBJECT_LIST list(/obj/machinery/door/airlock, /obj/structure/door_assembly, /obj/machinery/door/firedoor)

/**
 * The corrupted flesh controller
 *
 * This is the heart of the corruption, here is where we handle spreading and other stuff.
 */

/datum/corrupted_flesh_controller
	/// This is the name we will use to identify all of our babies.
	var/controller_fullname = "DEFAULT"
	/// First name, set automatically.
	var/controller_firstname = "DEFAULT"
	/// Second name, set automatically.
	var/controller_secondname = "DEFAULT"
	/// A list of all of our currently controlled mobs.
	var/list/controlled_mobs = list()
	/// A list of all of our currently controlled machine components.
	var/list/controlled_machine_components = list()
	/// A list of all of our current wireweed.
	var/list/controlled_wireweed = list()
	/// Currently active and able to spread wireweed.
	var/list/active_wireweed = list()
	/// A list of all current structures.
	var/list/controlled_structures = list()
	/// A list of all our wireweed walls.
	var/list/controlled_walls = list()
	/// A list of all of our current cores
	var/list/cores = list()

	/// Can the wireweed attack?
	var/can_attack = TRUE
	/// Can we attack doors?
	var/wireweed_attacks_doors = TRUE
	/// Can we attack windows?
	var/wireweed_attacks_windows = TRUE

	/// Whether the wireweed can spawn walls.
	var/spawns_walls = TRUE
	/// Whether the wireweed can spawn walls to seal off vaccuum.
	var/wall_off_vaccuum = TRUE
	/// Whether the resin can spawn walls to seal off planetary environments.
	var/wall_off_planetary = TRUE

	/// Types of structures we can spawn.
	var/list/structure_types = list(
		/obj/structure/corrupted_flesh/structure/babbler,
		/obj/structure/corrupted_flesh/structure/modulator,
		/obj/structure/corrupted_flesh/structure/screamer,
		/obj/structure/corrupted_flesh/structure/whisperer,
		/obj/structure/corrupted_flesh/structure/assembler,
		/obj/structure/corrupted_flesh/structure/turret,
	)
	/// Our wireweed type, defines what is spawned when we grow.
	var/wireweed_type = /obj/structure/corrupted_flesh/wireweed
	/// We have the ability to make walls, this defines what kind of walls we make.
	var/wall_type = /obj/structure/corrupted_flesh/structure/wireweed_wall

	/// Our core level, what is spawned will depend on the level of this core.
	var/level = CONTROLLER_LEVEL_1
	/// To level up, we much reach this threshold.
	var/level_up_progress_required = CONTROLLER_LEVEL_UP_THRESHOLD
	/// Used to track our last points since levelup.
	var/last_level_up_points = 0
	/// Progress to the next wireweed spread.
	var/spread_progress = 0
	/// Progress to spawning the next structure.
	var/structure_progression = 0
	/// How many times do we need to spread to spawn an extra structure.
	var/spreads_for_structure = 60
	/// How many spread in our initial expansion.
	var/initial_expansion_spreads = 30
	/// How many structures in our initial expansion.
	var/initial_expansion_structures = 3
	/// How much progress to spreading we get per second.
	var/spread_progress_per_second = 100
	/// Probably of resin attacking structures per process
	var/attack_prob = 20
	/// Probability of resin making a wall when able per process
	var/wall_prob = 30
	/// Whether we can put resin on walls. This slows down the expansion and will cause the structures to be more densely packed.
	var/can_do_wall_wireweed = TRUE
	/// When we spawn, do we create an expansion zone?
	var/do_initial_expansion = TRUE
	/// The amount of time until we can activate nearby resin again.
	var/next_core_damage_resin_activation_cooldown = 10 SECONDS
	/// A cooldown to determine when we can activate nearby wireweed after the core has been attacked.
	COOLDOWN_DECLARE(next_core_damage_resin_activation)

/datum/corrupted_flesh_controller/New(obj/structure/corrupted_flesh/structure/core/new_core)
	. = ..()
	controller_firstname = pick(AI_FORENAME_LIST)
	controller_secondname = pick(AI_SURNAME_LIST)
	controller_fullname = "[controller_firstname] [controller_secondname]"
	if(new_core)
		cores += new_core
		new_core.our_controller = src
		RegisterSignal(new_core, COMSIG_PARENT_QDELETING, .proc/core_death)
		new_core.name = "[controller_fullname] Processor Unit"
		register_new_asset(new_core)
	START_PROCESSING(SSfastprocess, src)
	if(do_initial_expansion)
		initial_expansion()

/datum/corrupted_flesh_controller/proc/register_new_asset(obj/structure/corrupted_flesh/new_asset)
	new_asset.RegisterSignal(src, COMSIG_PARENT_QDELETING, /obj/structure/corrupted_flesh/proc/controller_destroyed)

/datum/corrupted_flesh_controller/process(delta_time)
	if(!LAZYLEN(cores)) // We have no more processor cores, it's time to die.
		qdel(src)
		return

	spread_progress += spread_progress_per_second * delta_time
	var/spread_times = 0
	while(spread_progress >= SPREAD_PROGRESS_REQUIRED)
		spread_progress -= SPREAD_PROGRESS_REQUIRED
		spread_times++

	var/first_process_spread = FALSE
	if(spread_times)
		first_process_spread = TRUE
		spread_times--

	wireweed_process(first_process_spread, TRUE)

	if(spread_times)
		for(var/i in 1 to spread_times)
			wireweed_process(TRUE, FALSE)

	calculate_level_system()

/datum/corrupted_flesh_controller/Destroy(force, ...)
	active_wireweed = null
	controlled_machine_components = null
	controlled_wireweed = null
	controlled_structures = null
	controlled_walls = null
	cores = null
	STOP_PROCESSING(SSfastprocess, src)
	message_admins("Corruption AI [controller_fullname] has been destroyed.")
	return ..()


/datum/corrupted_flesh_controller/proc/initial_expansion()
	for(var/i in 1 to initial_expansion_spreads)
		wireweed_process(TRUE, FALSE, FALSE)
	spawn_structures(initial_expansion_structures)

/// The process of handling active resin behaviours
/datum/corrupted_flesh_controller/proc/wireweed_process(do_spread, do_attack, progress_structure = TRUE)
	// If no resin, spawn one under our first core.
	if(!LAZYLEN(controlled_wireweed))
		spawn_wireweed(get_turf(cores[1]), wireweed_type) // We use the first core in the list to spread.

	// If no active resin, make all active and let the process figure it out.
	if(!LAZYLEN(active_wireweed))
		for(var/obj/structure/corrupted_flesh/wireweed/iterating_wireweed as anything in controlled_wireweed)
			iterating_wireweed.active = TRUE
			iterating_wireweed.update_appearance()
		active_wireweed = controlled_wireweed.Copy()

	var/list/spread_turf_canidates = list()
	for(var/obj/structure/corrupted_flesh/wireweed/wireweed as anything in active_wireweed)
		var/could_attack = FALSE
		var/could_do_wall = FALSE

		var/turf/wireweed_turf = get_turf(wireweed)

		var/tasks = 0

		if(do_attack && can_attack)
			for(var/turf/open/adjacent_open in get_adjacent_open_turfs(wireweed))
				for(var/obj/object in adjacent_open)
					if(object.density && (wireweed_attacks_doors && is_type_in_list(object, DOOR_OBJECT_LIST)) || (wireweed_attacks_windows && istype(object, /obj/structure/window)))
						could_attack = TRUE
						tasks++
						if(prob(attack_prob))
							wireweed.do_attack_animation(object, ATTACK_EFFECT_CLAW)
							playsound(object, 'sound/effects/attackblob.ogg', 50, TRUE)
							object.take_damage(wireweed.object_attack_damage, BRUTE, MELEE, 1, get_dir(object, wireweed))
						break
				if(could_attack)
					break
		if(do_spread)
			for(var/turf/open/adjacent_open in wireweed_turf.atmos_adjacent_turfs + wireweed_turf)
				if(spawns_walls && !could_do_wall)
					if((wall_off_vaccuum && isspaceturf(adjacent_open)) || (wall_off_planetary && adjacent_open.planetary_atmos))
						could_do_wall = TRUE
						tasks++
						if(prob(wall_prob))
							spawn_wall(wireweed_turf, wall_type)
						continue

				///Check if we can place resin in here
				if(isopenspaceturf(adjacent_open))
					//If we're trying to place on an openspace turf, make sure there's a non openspace turf adjacent
					var/forbidden = TRUE
					for(var/turf/range_turf as anything in RANGE_TURFS(1, adjacent_open))
						if(!isopenspaceturf(range_turf))
							forbidden = FALSE
							break
					if(forbidden)
						continue
				var/wireweed_count = 0
				var/place_count = 1
				for(var/obj/structure/corrupted_flesh/wireweed/iterated_wireweed in adjacent_open)
					wireweed_count++
				if(can_do_wall_wireweed)
					for(var/wall_dir in GLOB.cardinals)
						var/turf/step_turf = get_step(adjacent_open, wall_dir)
						if(step_turf.density)
							place_count++
				if(wireweed_count < place_count)
					tasks++
					spread_turf_canidates[adjacent_open] = TRUE

		//If it tried to spread and attack and failed to do any task, remove from active
		if(!tasks && do_spread && do_attack)
			active_wireweed -= wireweed
			wireweed.active = FALSE
			wireweed.update_appearance()

	if(LAZYLEN(spread_turf_canidates))
		var/turf/picked_turf = pick(spread_turf_canidates)
		spawn_wireweed(picked_turf, wireweed_type)

		if(progress_structure && structure_types)
			structure_progression++
		if(structure_progression >= spreads_for_structure)
			var/obj/structure/corrupted_flesh/structure/existing_structure = locate() in picked_turf
			if(!existing_structure)
				structure_progression -= spreads_for_structure
				var/list/possible_structures = list()
				for(var/obj/structure/corrupted_flesh/iterating_structure as anything in structure_types)
					if(initial(iterating_structure.required_controller_level) > level)
						continue
					possible_structures += iterating_structure
				spawn_structure(picked_turf, pick(possible_structures))

/datum/corrupted_flesh_controller/proc/calculate_level_system()
	var/points = calculate_current_points()
	if(points >= (last_level_up_points + level_up_progress_required) && level < CONTROLLER_LEVEL_MAX)
		level_up()
		last_level_up_points = points

/datum/corrupted_flesh_controller/proc/level_up()
	level++
	spawn_new_core()
	message_admins("Corruption AI [controller_fullname] has leveld up to level [level]!")

/datum/corrupted_flesh_controller/proc/spawn_new_core()
	var/obj/structure/corrupted_flesh/wireweed/selected_wireweed = pick(controlled_wireweed)
	var/obj/structure/corrupted_flesh/structure/core/new_core = new(get_turf(selected_wireweed), FALSE)
	register_new_asset(new_core, FALSE)
	new_core.our_controller = src
	cores += new_core
	new_core.name = "[controller_fullname] Processor Unit"

/// Spawns and registers a resin at location
/datum/corrupted_flesh_controller/proc/spawn_wireweed(turf/location, wireweed_type)

	//Spawn effect
	for(var/obj/machinery/light/light_in_place in location)
		light_in_place.break_light_tube()

	for(var/obj/machinery/iterating_machine in location)
		if(iterating_machine.GetComponent(/datum/component/machine_corruption))
			continue
		iterating_machine.AddComponent(/datum/component/machine_corruption, src)

	var/obj/structure/corrupted_flesh/wireweed/new_wireweed = new wireweed_type(location)
	new_wireweed.our_controller = src
	active_wireweed += new_wireweed
	new_wireweed.active = TRUE
	new_wireweed.update_appearance()
	controlled_wireweed += new_wireweed

	register_new_asset(new_wireweed)
	RegisterSignal(new_wireweed, COMSIG_PARENT_QDELETING, .proc/wireweed_death)

/// Spawns and registers a wall at location
/datum/corrupted_flesh_controller/proc/spawn_wall(turf/location, wall_type)
	var/obj/structure/corrupted_flesh/structure/wireweed_wall/new_wall = new wall_type(location)
	new_wall.our_controller = src
	controlled_walls += new_wall

	register_new_asset(new_wall)
	RegisterSignal(new_wall, COMSIG_PARENT_QDELETING, .proc/wall_death)

/// Spawns and registers a structure at location
/datum/corrupted_flesh_controller/proc/spawn_structure(turf/location, structure_type)
	var/obj/structure/corrupted_flesh/structure/new_structure = new structure_type(location)
	new_structure.our_controller = src
	controlled_structures += new_structure

	new_structure.name = "[controller_firstname] [new_structure.name]"

	register_new_asset(new_structure)
	RegisterSignal(new_structure, COMSIG_PARENT_QDELETING, .proc/structure_death)

/// Spawns an amount of structured across all resin, guaranteed to spawn atleast 1 of each type
/datum/corrupted_flesh_controller/proc/spawn_structures(amount)
	if(!structure_types)
		return
	var/list/possible_structures = list()
	for(var/obj/structure/corrupted_flesh/iterating_structure as anything in structure_types)
		if(initial(iterating_structure.required_controller_level) > level)
			continue
		possible_structures += iterating_structure
	var/list/locations = list()
	for(var/obj/structure/corrupted_flesh/wireweed/iterating_wireweed as anything in controlled_wireweed)
		locations[get_turf(iterating_wireweed)] = TRUE
	var/list/guaranteed_structures = possible_structures.Copy()
	for(var/i in 1 to amount)
		if(!length(locations))
			break
		var/turf/location = pick(locations)
		locations -= location
		var/structure_to_spawn
		if(length(guaranteed_structures))
			structure_to_spawn = pick_n_take(guaranteed_structures)
		else
			structure_to_spawn = pick(possible_structures)
		spawn_structure(location, structure_to_spawn)

/// Activates resin of this controller in a range around a location, following atmos adjacency.
/datum/corrupted_flesh_controller/proc/activate_wireweed_nearby(turf/location, range)
	var/list/turfs_to_check = list()
	turfs_to_check[location] = TRUE

	if(range)
		var/list/turfs_to_iterate = list()
		var/list/new_iteration_list = list()
		turfs_to_iterate[location] = TRUE
		for(var/i in 1 to range)
			for(var/turf/iterated_turf as anything in turfs_to_iterate)
				for(var/turf/adjacent_turf as anything in iterated_turf.atmos_adjacent_turfs)
					if(!turfs_to_check[adjacent_turf])
						new_iteration_list[adjacent_turf] = TRUE
					turfs_to_check[adjacent_turf] = TRUE
			turfs_to_iterate = new_iteration_list

	for(var/turf/iterated_turf as anything in turfs_to_check)
		for(var/obj/structure/corrupted_flesh/wireweed/iterating_wireweed in iterated_turf)
			if(iterating_wireweed.our_controller == src && !QDELETED(iterating_wireweed))
				iterating_wireweed.active = TRUE
				iterating_wireweed.update_appearance()
				active_wireweed |= iterating_wireweed

/// When the core is damaged, activate nearby resin just to make sure that we've sealed up walls near the core, which could be important to prevent cheesing.
/datum/corrupted_flesh_controller/proc/core_damaged(obj/structure/corrupted_flesh/structure/core/damaged_core)
	if(!COOLDOWN_FINISHED(src, next_core_damage_resin_activation))
		return
	COOLDOWN_START(src, next_core_damage_resin_activation, next_core_damage_resin_activation_cooldown)
	activate_wireweed_nearby(get_turf(damaged_core), CORE_DAMAGE_WIREWEED_ACTIVATION_RANGE)

/// Returns the amount of evolution points this current controller has.
/datum/corrupted_flesh_controller/proc/calculate_current_points()
	return LAZYLEN(controlled_wireweed) + LAZYLEN(controlled_walls) + LAZYLEN(controlled_structures) + LAZYLEN(controlled_machine_components)

// Death procs

/// When a core is destroyed.
/datum/corrupted_flesh_controller/proc/core_death(obj/structure/corrupted_flesh/structure/core/dead_core, force)
	cores -= dead_core
	activate_wireweed_nearby(get_turf(dead_core), CORE_DAMAGE_WIREWEED_ACTIVATION_RANGE)
	return

/datum/corrupted_flesh_controller/proc/wireweed_death(obj/structure/corrupted_flesh/dying_wireweed, force)
	SIGNAL_HANDLER

	controlled_wireweed -= dying_wireweed
	active_wireweed -= dying_wireweed
	activate_wireweed_nearby(get_turf(dying_wireweed), GENERAL_DAMAGE_WIREWEED_ACTIVATION_RANGE)

/// When a wall dies, called by wall
/datum/corrupted_flesh_controller/proc/wall_death(obj/structure/corrupted_flesh/structure/wireweed_wall/dying_wall, force)
	SIGNAL_HANDLER

	controlled_walls -= dying_wall
	activate_wireweed_nearby(get_turf(dying_wall), GENERAL_DAMAGE_WIREWEED_ACTIVATION_RANGE)

/// When a structure dies, called by structure
/datum/corrupted_flesh_controller/proc/structure_death(obj/structure/corrupted_flesh/structure/dying_structure, force)
	SIGNAL_HANDLER

	controlled_structures -= dying_structure
	activate_wireweed_nearby(get_turf(dying_structure), GENERAL_DAMAGE_WIREWEED_ACTIVATION_RANGE)

/datum/corrupted_flesh_controller/proc/component_death(datum/component/machine_corruption/deleting_component, force)
	SIGNAL_HANDLER

	var/obj/parent_object = deleting_component.parent
	if(parent_object)
		activate_wireweed_nearby(get_turf(parent_object), GENERAL_DAMAGE_WIREWEED_ACTIVATION_RANGE)
	controlled_machine_components -= deleting_component


