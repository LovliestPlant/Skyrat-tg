//Reworked as naakabespoke stuff, *weh

// THE PROPOSAL RING
/obj/item/clothing/gloves/ring/diamond/naaka
	name = "chartreuse-on-black tungsten ring"
	desc = "A durable tungsten ring with a verdant green inlay. An obscure option for old-school proposals, but it'll last you as many lifetimes as NT employees end up living!"
	icon = 'modular_skyrat/modules/threeprongs/icons/naaka_customs.dmi'
	worn_icon = 'modular_skyrat/modules/threeprongs/icons/naaka_customs.dmi'
	icon_state = "ring_naaka"
	worn_icon_state = "ring_naaka_worn"

/obj/item/storage/fancy/ringbox/diamond/naaka
	icon = 'modular_skyrat/modules/threeprongs/icons/naaka_customs.dmi'
	icon_state = "naaka ringbox"
	base_icon_state = "naaka ringbox"
	spawn_type = /obj/item/clothing/gloves/ring/diamond/naaka

/datum/loadout_item/pocket_items/ringbox_naaka
	name = "Chartreuse-on-Black Tungsten Ring Box"
	item_path = /obj/item/storage/fancy/ringbox/diamond/naaka



// NAA HAT WOO WOO
/obj/item/clothing/head/hats/nk006/naaka
	name = "naaka's parade cap"
	desc = "A parade-worthy chartreuse armored cap with gemstone inlays.  It's good to be the king of kings."
	icon_state = "cap_naaka"
	worn_icon_state = "cap_naaka_worn"
	icon = 'modular_skyrat/modules/threeprongs/icons/naaka_customs.dmi'
	worn_icon = 'modular_skyrat/modules/threeprongs/icons/naaka_customs.dmi'
	flags_inv = 0
	armor = list(MELEE = 25, BULLET = 15, LASER = 25, ENERGY = 35, BOMB = 25, BIO = 0, FIRE = 50, ACID = 50, WOUND = 5)
	strip_delay = 60
	dog_fashion = null



// NAAKA PDA
/obj/item/modular_computer/pda/nk006/heads/captain/naaka
	name = "naaka's PDA"
	greyscale_colors = "#FFFFFF#AAFF00#FF6600#7f7f00"
	inserted_item = /obj/item/pen/fountain/captain



// NAAKA BACKPACKS
/obj/item/storage/backpack/nk006/naaka
	name = "naaka's backpack"
	icon = 'modular_skyrat/modules/threeprongs/icons/naaka_customs.dmi'
	worn_icon = 'modular_skyrat/modules/threeprongs/icons/naaka_customs.dmi'
	icon_state = "backpack_naaka"
	inhand_icon_state = "backpack_naaka_worn"

/obj/item/storage/backpack/satchel/nk006/naaka
	name = "naaka's satchel"
	icon = 'modular_skyrat/modules/threeprongs/icons/naaka_customs.dmi'
	worn_icon = 'modular_skyrat/modules/threeprongs/icons/naaka_customs.dmi'
	icon_state = "satchel_naaka"
	inhand_icon_state = "satchel_naaka_worn"

/obj/item/storage/backpack/duffelbag/nk006/naaka
	name = "naaka's duffel bag"
	icon = 'modular_skyrat/modules/threeprongs/icons/naaka_customs.dmi'
	worn_icon = 'modular_skyrat/modules/threeprongs/icons/naaka_customs.dmi'
	icon_state = "duffel_naaka"
	inhand_icon_state = "duffel_naaka_worn"
	slowdown = 1



// NAAKA BELT
// == CHIEF ENGINEER BELT, basically unchanged
/obj/item/storage/belt/nk006/support/naaka
	name = "naaka's belt"
	icon = 'modular_skyrat/modules/threeprongs/icons/naaka_customs.dmi'
	worn_icon = 'modular_skyrat/modules/threeprongs/icons/naaka_customs.dmi'
	desc = "A chartreuse belt with an amber badge.  Comes with all the powertools a CE can need, and space for sub-storages to really maximize potential."
	icon_state = "belt_naaka"
	worn_icon_state = "belt_naaka_worn"
	preload = TRUE

/obj/item/storage/belt/nk006/support/naaka/get_types_to_preload()
	var/list/to_preload = list() //Yes this is a pain. Yes this is the point
	to_preload += /obj/item/screwdriver/power
	to_preload += /obj/item/crowbar/power
	to_preload += /obj/item/weldingtool/experimental
	to_preload += /obj/item/multitool
	to_preload += /obj/item/stack/cable_coil
	to_preload += /obj/item/extinguisher/mini
	to_preload += /obj/item/analyzer
	return to_preload

/obj/item/storage/belt/nk006/support/naaka/PopulateContents()
	SSwardrobe.provide_type(/obj/item/screwdriver/power, src)
	SSwardrobe.provide_type(/obj/item/crowbar/power, src)
	SSwardrobe.provide_type(/obj/item/weldingtool/experimental, src) //TODO: arc welder?
	SSwardrobe.provide_type(/obj/item/multitool, src)
	SSwardrobe.provide_type(/obj/item/stack/cable_coil, src)
	SSwardrobe.provide_type(/obj/item/extinguisher/mini, src)
	SSwardrobe.provide_type(/obj/item/analyzer, src)



// NAAKA HEADSET
/obj/item/radio/headset/nk006/headset_naaka
	name = "naaka's radio headset"
	desc = "A headset for the Captain."
	icon = 'modular_skyrat/modules/threeprongs/icons/naaka_customs.dmi'
	worn_icon = 'modular_skyrat/modules/threeprongs/icons/naaka_customs.dmi'
	icon_state = "naaka_headset"
	keyslot = /obj/item/encryptionkey/headset_cent

/obj/item/radio/headset/nk006/headset_naaka/alt
	name = "naaka's bowman headset"
	desc = "An improved headset for the Captain. Protects ears from flashbangs."
	icon_state = "naaka_headset_alt"

/obj/item/radio/headset/nk006/headset_naaka/alt/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/wearertargeting/earprotection, list(ITEM_SLOT_EARS))