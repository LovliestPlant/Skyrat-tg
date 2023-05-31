//we are become scrumble

/datum/quirk/item_quirk/stuffable
	name = "True Glutton"
	desc = "Voracious alt ft. BWELLY ITEM.  Alt-click it in-hand to change the color to match your sprite, then equip or use for nommage as the description says."
	icon = FA_ICON_DRUMSTICK_BITE
	value = 0
	mob_trait = TRAIT_VORACIOUS
	gain_text = span_notice("You feel like you could eat a horse!")
	lose_text = span_danger("Food suddenly feels a lot less appealing.")
	medical_record_text = "Patient's midriff and stomach are unusually stretchy."
	mail_goodies = list(/obj/effect/spawner/random/entertainment/musical_instrument, /obj/item/instrument/piano_synth/headphones)

/datum/quirk/item_quirk/stuffable/add_unique(client/client_source)
	give_item_to_holder(/obj/item/clothing/sextoy/belly_function, list(LOCATION_BACKPACK = ITEM_SLOT_BACKPACK, LOCATION_HANDS = ITEM_SLOT_HANDS))

/obj/item/clothing/sextoy/belly_function
	name = "bwelly"
	desc = "Gobble friends, stuff yourself, be big and round, get cancelled on Twitter for endosoma only.  Equip with Ctrl-Shift-Click on your Nipples slot for display of stuffedness, or click a friend with this to nom them beforehand.  Drop on the floor or unequip from the Interact menu to free a nommed friend."
	icon_state = "bwelly"
	icon = 'modular_skyrat/modules/naaka_nom_sys/items.dmi'
	worn_icon_state = "Belly0"
	worn_icon = 'modular_skyrat/modules/naaka_nom_sys/bellies.dmi'
	worn_icon_teshari = 'modular_skyrat/modules/naaka_nom_sys/bellies_teshari.dmi'
	w_class = WEIGHT_CLASS_TINY
	lewd_slot_flags = LEWD_SLOT_NIPPLES
	color = "#b1f91f"
	
	var/mob/living/carbon/human/nommed
	var/full_cooldown = 6
	var/stuffLo_cooldown = 3
	var/stuffHi_cooldown = 9
	var/last_size = 0
	
	var/full_sounds = list("modular_skyrat/modules/naaka_nom_sys/sounds/Fullness/digest (36).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/Fullness/digest (47).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/Fullness/Gurgle6.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/Fullness/Gurgle8.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/Fullness/Gurgle14.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/Fullness/digest (8).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/Fullness/digest (9).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/Fullness/digest (13).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/Fullness/digest (15).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/Fullness/digest (18).ogg")
	var/stuff_minor = list("modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/digest (25).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/digest (26).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/digest (28).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/digest (29).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/digest (31).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/digest (33).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/digest (34).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/digest (37).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/digest (48).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/Gurgle1.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/Gurgle2.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/Gurgle3.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/Gurgle9.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/Gurgle10.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/Gurgle11.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/Gurgle12.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/Gurgle13.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/Gurgle15.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/Gurgle16.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/stomach-burble.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/digest (3).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/digest (11).ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMinor/digest (17).ogg")
	var/stuff_major = list("modular_skyrat/modules/naaka_nom_sys/sounds/StuffMajor/digest_10.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMajor/digest_12.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMajor/digest_17.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMajor/Gurgle4.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMajor/Gurgle5.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMajor/Gurgle7.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMajor/digest_02.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMajor/digest_04.ogg", "modular_skyrat/modules/naaka_nom_sys/sounds/StuffMajor/digest_05.ogg")

/obj/item/clothing/sextoy/belly_function/AltClick(mob/living/user)
	var/temp_col = input("Enter new color:", "Color", src.color) as color|null
	if(temp_col != null)
		src.color = temp_col

/obj/item/clothing/sextoy/belly_function/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(!istype(user))
		return
	//to_chat(world, "begin processing")
	START_PROCESSING(SSobj, src)

/obj/item/clothing/sextoy/belly_function/dropped(mob/user, slot)
	. = ..()
	if(loc != user)
		//to_chat(world, "loc mismatched, stopping process")
		if(istype(nommed))
			nommed.loc = user.loc
			nommed = null
		STOP_PROCESSING(SSobj, src)

/obj/item/clothing/sextoy/belly_function/process(seconds_per_tick)
	//to_chat(world, "screem - process is running")
	var/mob/living/carbon/human/user = loc
	if(!istype(user))
		return
	
	var/guest_temp = istype(nommed) ? 1 : 0
	var/stuffed_temp = user.get_fullness() / 800 //800u == more or less @ same-size endo
	var/total_fullness = guest_temp + stuffed_temp //maximum creaks from overfilled belly
	var/spr_size = 0
	if(total_fullness >= 1)
		spr_size = 3
	else if(total_fullness >= 0.66)
		spr_size = 2
	else if(total_fullness >= 0.33)
		spr_size = 1
	else
		spr_size = 0
	if(spr_size != last_size)
		last_size = spr_size
		worn_icon_state = "Belly[spr_size]"
		update_icon_state()
		update_icon()
		user.update_inv_nipples()
	
	if(total_fullness >= 0.5)
		full_cooldown = full_cooldown - (seconds_per_tick * total_fullness)
		if(full_cooldown < 0)
			full_cooldown = rand(6, 36)
			playsound(user, pick(full_sounds), 50, TRUE)
	if(stuffed_temp >= 0.1)
		stuffLo_cooldown = stuffLo_cooldown - (seconds_per_tick * (stuffed_temp + (total_fullness/5)))
		if(stuffLo_cooldown < 0)
			stuffLo_cooldown = rand(3, 6)
			playsound(user, pick(stuff_minor), 30, TRUE)
	if(stuffed_temp >= 0.5)
		stuffHi_cooldown = stuffHi_cooldown - (seconds_per_tick * (stuffed_temp + (total_fullness/10)))
		if(stuffHi_cooldown < 0)
			stuffHi_cooldown = rand(9, 60)
			playsound(user, pick(stuff_major), 70, TRUE)
	
/obj/item/clothing/sextoy/belly_function/attack(mob/living/carbon/human/target, mob/living/carbon/human/user)
	. = ..()
	if(!ishuman(target) || (target.stat == DEAD) || !ishuman(user) || ishuman(nommed) || user == target) //sanity check
		return
	
	target.visible_message("[user] gulps down [target]!")
	nommed = target
	SEND_SIGNAL(user, COMSIG_MACHINERY_SET_OCCUPANT, target)
	target.forceMove(user)