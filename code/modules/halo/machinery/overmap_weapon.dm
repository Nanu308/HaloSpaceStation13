
/obj/machinery/overmap_weapon_console
	icon = 'code/modules/halo/machinery/overmap_weapon_base.dmi'
	icon_state = "wep_base"
	anchored = 1
	density = 1
	var/direction_locked = 0 //Determines if this weapon can freely fire on the overmap or not.
	var/obj/item/projectile/overmap/fired_projectile = /obj/item/projectile/overmap
	var/sound/fire_sound = null
	var/requires_ammo = 0
	var/list/loaded_ammo = list()
	var/list/linked_devices = list() //Handled on a weapon-by-weapon basis

/obj/machinery/overmap_weapon_console/attack_hand(var/mob/user)
	equip_aim_tool(user)

/obj/machinery/overmap_weapon_console/proc/scan_linked_devices() //Overriden on a weapon-by-weapon basis

/obj/machinery/overmap_weapon_console/check_eye(var/mob/user)
	if(!istype(user.l_hand,/obj/item/weapon/gun/aim_tool) && !istype(user.r_hand,/obj/item/weapon/gun/aim_tool))
		user.machine = null
		user.reset_view(null)
		return -1
	if(get_dist(user,src) > 1)
		user.machine = null
		user.reset_view(null)
		return -1
	return 0

/obj/machinery/overmap_weapon_console/proc/equip_aim_tool(var/mob/living/carbon/human/user)
	scan_linked_devices()
	if(!user || !istype(user))
		return
	var/obj/item/aim_tool = new /obj/item/weapon/gun/aim_tool(src)
	if(!user.put_in_active_hand(aim_tool) && !user.put_in_inactive_hand(aim_tool))
		qdel(aim_tool)
		return
	user.machine = src
	user.reset_view(map_sectors["[z]"])

/obj/machinery/overmap_weapon_console/proc/consume_external_ammo()
	var/obj/ammo_to_remove = loaded_ammo[loaded_ammo.len]
	loaded_ammo -= ammo_to_remove
	qdel(ammo_to_remove)

/obj/machinery/overmap_weapon_console/proc/consume_loaded_ammo(var/mob/user)
	if(!requires_ammo)
		return 1
	if(loaded_ammo.len == 0)
		to_chat(user,"<span class = 'warning'>No ammunition loaded.</span>")
		return 0
	consume_external_ammo()
	return 1

/obj/machinery/overmap_weapon_console/proc/get_linked_device_damage_mod()//Defined on a weapon-by-weapon basis.
	return 0

/obj/machinery/overmap_weapon_console/proc/fire_projectile(var/atom/target,var/mob/user)

	var/obj/item/projectile/new_projectile = new fired_projectile
	new_projectile.damage += get_linked_device_damage_mod()
	new_projectile.loc = map_sectors["[z]"]
	new_projectile.permutated = map_sectors["[z]"] //Ensuring we don't hit ourselves somehow
	new_projectile.firer = user
	new_projectile.launch(target)

/obj/machinery/overmap_weapon_console/proc/play_fire_sound()
	if(isnull(fire_sound))
		return

	playsound(src, fire_sound, 50, 1, 5, 5)

/obj/machinery/overmap_weapon_console/proc/fire(var/atom/target,var/mob/living/user,var/click_params)
	scan_linked_devices()
	if(!user)
		return
	var/obj/overmap_sector = map_sectors["[z]"]
	if(!overmap_sector)
		return 0
	if(target.loc == overmap_sector.loc)
		to_chat(user,"<span class = 'warning'>You can't fire at yourself!</span>")
		return 0
	if(direction_locked && (get_dir(overmap_sector,target) != overmap_sector.dir)) //Direction lock check.
		to_chat(user,"<span class = 'warning'>Weapon is locked to direction of ship. Realign ship to fire.</span>")
		return 0
	if(!consume_loaded_ammo(user))
		return 0

	fire_projectile(target,user)
	return 1

//Overmap Weapon Aim Tool//

/obj/item/weapon/gun/aim_tool
	name = "Aiming Tool"
	desc = "Used for aiming a ship- or planet- board weapon"
	w_class = ITEM_SIZE_LARGE
	can_rename = 0
	var/obj/machinery/overmap_weapon_console/creator_console

/obj/item/weapon/gun/aim_tool/New(var/console)
	. = ..()
	creator_console = console

/obj/item/weapon/gun/aim_tool/afterattack(var/atom/target,var/mob/user,adjacent,var/clickparams)
	creator_console.fire(target,user,clickparams)

/obj/item/weapon/gun/aim_tool/dropped()
	qdel(src)
