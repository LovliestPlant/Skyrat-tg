/obj/item/clothing/gloves/ring
	icon = 'modular_skyrat/master_files/icons/obj/ring.dmi'
	worn_icon = 'modular_skyrat/master_files/icons/mob/clothing/hands.dmi'
	name = "gold ring"
	desc = "A tiny gold ring, sized to wrap around a finger."
	gender = NEUTER
	w_class = WEIGHT_CLASS_TINY
	icon_state = "ringgold"
	inhand_icon_state = null
	worn_icon_state = "gring"
	body_parts_covered = 0
	strip_delay = 4 SECONDS
	clothing_traits = list(TRAIT_FINGERPRINT_PASSTHROUGH)

/obj/item/clothing/gloves/ring/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("\[user] is putting the [src] in [user.p_their()] mouth! It looks like [user] is trying to choke on the [src]!"))
	return OXYLOSS


/obj/item/clothing/gloves/ring/diamond
	name = "diamond ring"
	desc = "An expensive ring, studded with a diamond. Cultures have used these rings in courtship for a millenia."
	icon_state = "ringdiamond"
	worn_icon_state = "dring"

/obj/item/clothing/gloves/ring/diamond/attack_self(mob/user)
	user.visible_message(span_warning("\The [user] gets down on one knee, presenting \the [src]."),span_warning("You get down on one knee, presenting \the [src]."))

/obj/item/clothing/gloves/ring/silver
	name = "silver ring"
	desc = "A tiny silver ring, sized to wrap around a finger."
	icon_state = "ringsilver"
	worn_icon_state = "sring"



// Greyscaled rings
/obj/item/clothing/gloves/ring/diamond/colorable_blackband
	name = "banded tungsten ring"
	desc = "A sturdy, yet affordable tungsten ring with a brightly colored band.  A more accessible alternative for proposals that can be much more personal."
	icon_state = "ringtung"
	worn_icon_state = "ringtung"
	greyscale_config = /datum/greyscale_config/custom_rings
	greyscale_config_worn = /datum/greyscale_config/custom_rings/worn
	greyscale_config_worn_teshari = /datum/greyscale_config/custom_rings/worn/teshari
	flags_1 = IS_PLAYER_COLORABLE_1
	greyscale_colors = "#FF0000"

/obj/item/clothing/gloves/ring/diamond/colorable_blackband/iri
	name = "iridescent banded tungsten ring"
	desc = "A sturdy, shiny, yet affordable tungsten ring with an iridescent, colored band.  A more accessible alternative for proposals that can be much more personal."
	icon_state = "ringtung_iri"
	worn_icon_state = "ringtung_iri"
	greyscale_colors = "#FF0000#FF9F00#FF009F"