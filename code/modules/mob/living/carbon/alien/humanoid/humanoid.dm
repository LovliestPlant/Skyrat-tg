/mob/living/carbon/alien/humanoid
	name = "alien"
	icon_state = "alien"
	pass_flags = PASSTABLE
	butcher_results = list(/obj/item/food/meat/slab/xeno = 5, /obj/item/stack/sheet/animalhide/xeno = 1)
	limb_destroyer = 1
	hud_type = /datum/hud/alien
	melee_damage_lower = 20 //Refers to unarmed damage, aliens do unarmed attacks.
	melee_damage_upper = 20
	max_grab = GRAB_AGGRESSIVE
	var/caste = ""
	var/alt_icon = 'icons/mob/alienleap.dmi' //used to switch between the two alien icon files.
	var/leap_on_click = 0
	var/pounce_cooldown = 0
	var/pounce_cooldown_time = 30
	death_sound = 'sound/voice/hiss6.ogg'
	bodyparts = list(
		/obj/item/bodypart/chest/alien,
		/obj/item/bodypart/head/alien,
		/obj/item/bodypart/l_arm/alien,
		/obj/item/bodypart/r_arm/alien,
		/obj/item/bodypart/r_leg/alien,
		/obj/item/bodypart/l_leg/alien,
		)

//TODO: this is the beginning of making it so xenos can slap the shit out of you with gloves of the north star whilst wearing a ya-yoinked captain's hat

GLOBAL_LIST_INIT(strippable_alien_humanoid_items, create_strippable_list(list(
	/datum/strippable_item/hand/left,
	/datum/strippable_item/hand/right,
	/datum/strippable_item/mob_item_slot/head,
	/datum/strippable_item/mob_item_slot/gloves,
	/datum/strippable_item/mob_item_slot/handcuffs,
	/datum/strippable_item/mob_item_slot/legcuffs,
)))

/mob/living/carbon/alien/humanoid/can_equip(obj/item/I, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE)
	return TRUE //todo oh god we need to pull over an equivlanet to /datum/species/proc/can_equip just for GLOVES??

/mob/living/carbon/alien/humanoid/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/footstep, FOOTSTEP_MOB_CLAW, 0.5, -11)
	AddElement(/datum/element/strippable, GLOB.strippable_alien_humanoid_items)

/mob/living/carbon/alien/humanoid/create_internal_organs()
	internal_organs += new /obj/item/organ/internal/stomach/alien()
	return ..()

/mob/living/carbon/alien/humanoid/cuff_resist(obj/item/I)
	playsound(src, 'sound/voice/hiss5.ogg', 40, TRUE, TRUE)  //Alien roars when starting to break free
	..(I, cuff_break = INSTANT_CUFFBREAK)

/mob/living/carbon/alien/humanoid/resist_grab(moving_resist)
	if(pulledby.grab_state)
		visible_message(span_danger("[src] breaks free of [pulledby]'s grip!"), \
						span_danger("You break free of [pulledby]'s grip!"))
	pulledby.stop_pulling()
	. = 0

/mob/living/carbon/alien/humanoid/alien_evolve(mob/living/carbon/alien/humanoid/new_xeno)
	drop_all_held_items()
	..()

//For alien evolution/promotion/queen finder procs. Checks for an active alien of that type
/proc/get_alien_type(alienpath)
	for(var/mob/living/carbon/alien/humanoid/A in GLOB.alive_mob_list)
		if(!istype(A, alienpath))
			continue
		if(!A.key || A.stat == DEAD) //Only living aliens with a ckey are valid.
			continue
		return A
	return FALSE

/mob/living/carbon/alien/humanoid/check_breath(datum/gas_mixture/breath)
	if(breath?.total_moles() > 0 && !HAS_TRAIT(src, TRAIT_ALIEN_SNEAK))
		playsound(get_turf(src), pick('sound/voice/lowHiss2.ogg', 'sound/voice/lowHiss3.ogg', 'sound/voice/lowHiss4.ogg'), 50, FALSE, -5)
	return ..()

/mob/living/carbon/alien/humanoid/set_name()
	if(numba)
		name = "[name] ([numba])"
		real_name = name

/mob/living/carbon/alien/humanoid/proc/grab(mob/living/carbon/human/target)
	if(target.check_block())
		target.visible_message(span_warning("[target] blocks [src]'s grab!"), \
						span_userdanger("You block [src]'s grab!"), span_hear("You hear a swoosh!"), COMBAT_MESSAGE_RANGE, src)
		to_chat(src, span_warning("Your grab at [target] was blocked!"))
		return FALSE
	target.grabbedby(src)
	return TRUE

/mob/living/carbon/alien/humanoid/setGrabState(newstate)
	if(newstate == grab_state)
		return
	if(newstate > GRAB_AGGRESSIVE)
		newstate = GRAB_AGGRESSIVE
	SEND_SIGNAL(src, COMSIG_MOVABLE_SET_GRAB_STATE, newstate)
	. = grab_state
	grab_state = newstate
	switch(grab_state) // Current state.
		if(GRAB_PASSIVE)
			REMOVE_TRAIT(pulling, TRAIT_IMMOBILIZED, CHOKEHOLD_TRAIT)
			if(. >= GRAB_NECK) // Previous state was a a neck-grab or higher.
				REMOVE_TRAIT(pulling, TRAIT_FLOORED, CHOKEHOLD_TRAIT)
		if(GRAB_AGGRESSIVE)
			if(. >= GRAB_NECK) // Grab got downgraded.
				REMOVE_TRAIT(pulling, TRAIT_FLOORED, CHOKEHOLD_TRAIT)
			else // Grab got upgraded from a passive one.
				ADD_TRAIT(pulling, TRAIT_IMMOBILIZED, CHOKEHOLD_TRAIT)
		if(GRAB_NECK, GRAB_KILL)
			if(. <= GRAB_AGGRESSIVE)
				ADD_TRAIT(pulling, TRAIT_FLOORED, CHOKEHOLD_TRAIT)

/mob/living/carbon/alien/humanoid/MouseDrop_T(atom/dropping, atom/user)
	if(devour_lad(dropping))
		return
	return ..()

/// Returns FALSE if we're not allowed to eat it, true otherwise
/mob/living/carbon/alien/humanoid/proc/can_consume(atom/movable/poor_soul)
	if(!isliving(poor_soul) || pulling != poor_soul)
		return FALSE
	if(incapacitated() || grab_state < GRAB_AGGRESSIVE || stat != CONSCIOUS)
		return FALSE
	if(get_dir(src, poor_soul) != dir) // Gotta face em 4head
		return FALSE
	return TRUE

/// Attempts to devour the passed in thing in devour_time seconds
/// The mob needs to be consumable, as decided by [/mob/living/carbon/alien/humanoid/proc/can_consume]
/// Returns FALSE if the attempt never even started, TRUE otherwise
/mob/living/carbon/alien/humanoid/proc/devour_lad(atom/movable/candidate, devour_time = 13.5 SECONDS)
	setDir(get_dir(src, candidate))
	if(!can_consume(candidate))
		return FALSE
	var/mob/living/lucky_winner = candidate

	lucky_winner.audible_message(span_danger("You hear a great snapping, like the disjointing of muscle and bone."))
	lucky_winner.visible_message(span_danger("[src] is attempting to devour [lucky_winner]!"), \
			span_userdanger("[src] is attempting to devour you!"))

	playsound(lucky_winner, 'sound/creatures/alien_eat.ogg', 100)
	if(!do_mob(src, lucky_winner, devour_time, extra_checks = CALLBACK(src, .proc/can_consume, lucky_winner)))
		return TRUE
	if(!can_consume(lucky_winner))
		return TRUE

	var/obj/item/organ/internal/stomach/alien/melting_pot = getorganslot(ORGAN_SLOT_STOMACH)
	if(!istype(melting_pot))
		visible_message(span_clown("[src] can't seem to consume [lucky_winner]!"), \
			span_alien("You feel a pain in your... chest? You can't get [lucky_winner] down."))
		return TRUE

	lucky_winner.audible_message(span_danger("You hear a deep groan, and a harsh snap like a mantrap."))
	lucky_winner.visible_message(span_danger("[src] devours [lucky_winner]!"), \
			span_userdanger("[lucky_winner] devours you!"))
	log_combat(src, lucky_winner, "devoured")
	melting_pot.consume_thing(lucky_winner)
	return TRUE
