
/obj/structure/ai_terminal
	name = "AI Auxilliary Storage Terminal"
	desc = "This terminal contains hardware to store, upload and download AI constructs."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "pflash1"
	var/mob/living/silicon/ai/held_ai = null
	var/allow_remote_moveto = 1
	var/inherent_network = "Exodus" //Our inherent camera network.
	var/radio_channels_access = list() //Accessing this node will permenantly add these radio channels. This should only be placed on spawn_terminal subtypes.

	var/area_nodescan_override = null //If set, this will scan this area and all subtypes of this area for nodes to add to inherent_nodes
	var/list/inherent_nodes = list()// This should only really be fully populated for roundstart terminals, aka the ones AI cores spawn.
	//Otherwise this should just contain the node in it's own area.

/obj/structure/ai_terminal/Initialize()
	. = ..()
	var/area/our_area = loc.loc
	if(istype(our_area) && !isnull(our_area.ai_routing_node))
		inherent_nodes += our_area.ai_routing_node
	if(!isnull(area_nodescan_override))
		for(var/area_type in typesof(area_nodescan_override))
			var/area/a = locate(area_type)
			if(istype(a) && !isnull(a.ai_routing_node))
				inherent_nodes  += a.ai_routing_node

/obj/structure/ai_terminal/attack_ai(var/mob/living/silicon/ai/user)
	if(!istype(user))
		return
	if(user.our_terminal != src && held_ai != user)
		var/obj/structure/ai_terminal/old_term = user.our_terminal
		if(check_move_to(user))
			if(!isnull(old_term))
				old_term.ai_exit_node(user)
			pre_move_to_node(user)
			user.cancel_camera()
	if(held_ai == user)
		held_ai.cancel_camera()

/obj/structure/ai_terminal/proc/clear_old_nodes(var/mob/living/silicon/ai/ai)
	ai.nodes_accessed.Cut()

/obj/structure/ai_terminal/proc/can_exit_node(var/mob/ai) //TODO: CYBERSPACE WARFARE STUFF, TERMINAL LOCKDOWNS ETC.
	return 1

/obj/structure/ai_terminal/proc/ai_exit_node(var/mob/living/silicon/ai/ai)
	if(ai == held_ai)
		held_ai = null
		contents -= ai
		ai.loc = null

/obj/structure/ai_terminal/proc/pre_move_to_node(var/mob/living/silicon/ai/ai)
	var/clear_old = 0
	if(!(ai.network == inherent_network || ai.native_network == inherent_network))
		var/confirm = alert("This network holds no relation to any of your old networks. Switching will cause loss of previous node access.","Confirm Switch","Yes","No")
		if(confirm == "No")
			return
		clear_old = 1

	if(move_to_node(ai) && clear_old)
		clear_old_nodes(ai)
		invalidateCameraCache()
	to_chat(ai,"<span class = 'notice'>Consciousness moved to new AI node.</span>")

/obj/structure/ai_terminal/proc/check_move_to(var/mob/living/silicon/ai/ai)
	var/obj/structure/ai_terminal/o_t = ai.our_terminal
	if(istype(o_t) && !o_t.can_exit_node())
		to_chat(ai,"<span class = 'danger'>Could not exit current node.</span>")
		return
	if(!allow_remote_moveto)
		to_chat(ai,"<span class = 'danger'>External access attempt failed. Terminal does not accept external connections.</span>")
		if(held_ai)
			to_chat(held_ai,"<span class = 'danger'>External access attempt detected. Terminal halted external connection.</span>")
		return 0
	if(held_ai)
		to_chat(ai,"<span class = 'danger'>External access attempt failed. Terminal is currently occupied by an intelligence.</span>")
		to_chat(held_ai,"<span class = 'danger'>External access attempt detected. Presence has been detected in this terminal.</span>")
		return 0
	return 1

/obj/structure/ai_terminal/proc/can_card_ai()
	if(held_ai)
		return !held_ai.resist_carding

/obj/structure/ai_terminal/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W, /obj/item/weapon/aicard))
		var/obj/item/weapon/aicard/card = W
		if(card.carded_ai && !held_ai)
			move_to_node(card.carded_ai)
			card.carded_ai.control_disabled = 0
			card.carded_ai.aiRadio.disabledAi = 0
			card.carded_ai.create_eyeobj(loc)
			card.carded_ai.cancel_camera()
			to_chat(user, "<span class='notice'>Transfer successful:</span> [card.carded_ai.name] ([rand(1000,9999)].exe) downloaded to host terminal. Local copy wiped.")
			to_chat(card.carded_ai, "You have been uploaded to a stationary terminal. Remote device connection restored.")
			card.clear()

		else if(held_ai)
			if(!can_exit_node(held_ai) || !can_card_ai())
				to_chat(user,"<span class = 'notice'>Connection to construct failed. Network locks active. Construct resisting carding or system is locked down..</span>")
				to_chat(held_ai,"<span class = 'danger'>External forced consciousness shift detected at current terminal.</span>")
				return
			var/ai_to_transfer = held_ai
			if(held_ai.our_terminal)
				ai_exit_node(ai_to_transfer)

			card.grab_ai(ai_to_transfer, user,1)
		else
			to_chat(user,"<span class = 'notice'>Unable to pull or place any construct in [name].</span>")

/obj/structure/ai_terminal/proc/move_to_node(var/mob/living/silicon/ai/ai)
	held_ai = ai
	ai.forceMove(src)
	ai.our_terminal = src
	ai.network = inherent_network
	ai.nodes_accessed |= inherent_nodes.Copy()
	ai.switch_to_net_by_name(inherent_network)

/obj/structure/ai_terminal/spawn_terminal
	name = "AI Core"
	desc = "A terminal containing the main consciousness of an AI. Security reasons leave remote access disabled on this terminal."
	icon = 'icons/mob/AI.dmi'
	icon_state = "ai-empty"
	allow_remote_moveto = 0

/obj/structure/ai_terminal/spawn_terminal/unsc
	radio_channels_access = list("SHIPCOM","TEAMCOM","SQUADCOM","FLEETCOM","EBAND","TACCOM","ONICOM","SIERRACOM")

/obj/structure/ai_terminal/spawn_terminal/city
	radio_channels_access = list("GCPD","MEDCOM","EBAND")

/obj/structure/ai_terminal/spawn_terminal/covenant
	radio_channels_access = list("BattleNet","EBAND")

/obj/structure/ai_terminal/spawn_terminal/innie
	radio_channels_access = list("CMDOCOM","EBAND")

/obj/structure/ai_terminal/spawn_terminal/innie/Initialize()
	. = ..()
	radio_channels_access += halo_frequencies.innie_channel_name

/obj/structure/ai_terminal/debug
	name = "Forerunner Access Terminal"
	desc = "Limitless power for any construct.... (Inform an admin if you see this)"
	area_nodescan_override = /area
