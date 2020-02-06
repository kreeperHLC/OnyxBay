/datum/admin_secret_item/random_event/trigger_CompanyProvocation
	name = "Trigger Company Provocation"
	buttonName = "��������� ���������� ���������-�����������"

	var/announceTitle = ""
	var/announceMessage = ""
	var/wasTriggered = FALSE

/datum/admin_secret_item/random_event/trigger_CompanyProvocation/execute(mob/user)
	. = ..()
	if(!.)
		return

	if (wasTriggered)
		log_and_message_admins("Company Provocation Event Error: ����� ����� ��������� ������ ���� ���!", user)
		return

	// count factions Participants
	var/list/factionsParticipants[0]
	var/notEmptyFractionsNum = 0 // without NanoTrasen
	for (var/faction in GLOB.using_map.faction_choices)
		factionsParticipants[faction] = 0

	for (var/mob/living/carbon/human/character in GLOB.living_mob_list_)
		if (length(character.personal_faction))
			for (var/faction in GLOB.using_map.faction_choices)
				if (cmptext(character.personal_faction, faction))
					if (!factionsParticipants[faction] && !cmptext(GLOB.using_map.faction_choices[1], faction)) // don't count NanoTrasen
						notEmptyFractionsNum++
					factionsParticipants[faction]++
					break

	if (!notEmptyFractionsNum)
		log_and_message_admins("Company Provocation Event Error: ��� ������� ������ �������!", user)
		return

	// choose enemy fraction
	var/enemyFaction = ""
	var/enemyFactionNumber = 2 // 1 - NanoTrasen
	var/randomNotEmptyFractionNumber = rand(1, notEmptyFractionsNum)

	do
		if (factionsParticipants[GLOB.using_map.faction_choices[enemyFactionNumber]])
			randomNotEmptyFractionNumber--
			if (!randomNotEmptyFractionNumber)
				enemyFaction = GLOB.using_map.faction_choices[enemyFactionNumber]
				break
		enemyFactionNumber++
	while (TRUE)

	announceTitle = "����������"
	announceMessage = "��������! ��������� [enemyFaction] ���� ��������� ���������� �� ����� �� ����� �������. NanoTrasen ��� ������� �������� ���� � ��������� ������������. ���������� ��������� ��� ����� ����������� � ������ ����������� � ������� ����������� ���� ��� ����������� ������������ �������������� ���������! ������ �������� �����."

	command_announcement.Announce(announceMessage, announceTitle)
	wasTriggered = TRUE
