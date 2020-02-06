GLOBAL_LIST_EMPTY(all_crew_records)
GLOBAL_LIST_INIT(blood_types, list("A-", "A+", "B-", "B+", "AB-", "AB+", "O-", "O+"))
GLOBAL_LIST_INIT(physical_statuses, list("Active", "Disabled", "SSD", "Deceased"))
GLOBAL_VAR_INIT(default_physical_status, "Active")
GLOBAL_LIST_INIT(security_statuses, list("None", "Released", "Parolled", "Incarcerated", "Arrest"))
GLOBAL_VAR_INIT(default_security_status, "None")
GLOBAL_VAR_INIT(arrest_security_status, "Arrest")

// Kept as a computer file for possible future expansion into servers.
/datum/computer_file/crew_record
	filetype = "CDB"
	size = 2

	// String fields that can be held by this record.
	// Try to avoid manipulating the fields_ variables directly - use getters/setters below instead.
	var/icon/photo_front = null
	var/icon/photo_side = null
	var/list/fields = list()	// Fields of this record

/datum/computer_file/crew_record/New()
	..()
	for(var/T in subtypesof(/record_field/))
		new T(src)
	load_from_mob(null)

/datum/computer_file/crew_record/Destroy()
	. = ..()
	GLOB.all_crew_records.Remove(src)

/datum/computer_file/crew_record/proc/load_from_mob(mob/living/carbon/human/H, automatic = FALSE)
	if(istype(H))
		photo_front = getFlatIcon(H, SOUTH, always_use_defdir = 1)
		photo_side = getFlatIcon(H, WEST, always_use_defdir = 1)
	else
		var/mob/living/carbon/human/dummy = new()
		photo_front = getFlatIcon(dummy, SOUTH, always_use_defdir = 1)
		photo_side = getFlatIcon(dummy, WEST, always_use_defdir = 1)
		qdel(dummy)

	// Generic record
	set_name(H ? H.real_name : "Unset")
	set_job(H ? GetAssignment(H) : "Unset")
	set_sex(H ? gender2text(H.gender) : "Unset")
	set_age(H ? H.age : 30)
	set_status(GLOB.default_physical_status)
	set_species(H ? H.get_species() : SPECIES_HUMAN)
	set_branch(H ? (H.char_branch && H.char_branch.name) : "None")
	set_rank(H ? (H.char_rank && H.char_rank.name) : "None")

	// Medical record
	set_bloodtype(H ? H.b_type : "Unset")
	set_medRecord((H && H.med_record && !jobban_isbanned(H, "Records") ? H.med_record : "No record supplied"))

	// Security record
	set_criminalStatus(GLOB.default_security_status, automatic)
	set_dna(H ? H.dna.unique_enzymes : "")
	set_fingerprint(H ? md5(H.dna.uni_identity) : "")
	set_secRecord((H && H.sec_record && !jobban_isbanned(H, "Records") ? H.sec_record : "No record supplied"), automatic)

	// Employment record
	set_emplRecord((H && H.gen_record && !jobban_isbanned(H, "Records") ? H.gen_record : "No record supplied"))
	set_homeSystem(H ? H.home_system : "Unset")
	set_citizenship(H ? H.citizenship : "Unset")
	set_faction(H ? H.personal_faction : "Unset")
	set_religion(H ? H.religion : "Unset")

	// Antag record
	set_antagRecord((H && H.exploit_record && !jobban_isbanned(H, "Records") ? H.exploit_record : ""))

// Returns independent copy of this file.
/datum/computer_file/crew_record/clone(rename = 0)
	var/datum/computer_file/crew_record/temp = ..()
	return temp

/datum/computer_file/crew_record/proc/get_field(field_type)
	var/record_field/F = locate(field_type) in fields
	if(F)
		return F.get_value()

/datum/computer_file/crew_record/proc/set_field(field_type, value)
	var/record_field/F = locate(field_type) in fields
	if(F)
		return F.set_value(value)

// Global methods
// Used by character creation to create a record for new arrivals.
/proc/CreateModularRecord(mob/living/carbon/human/H)
	var/datum/computer_file/crew_record/CR = new /datum/computer_file/crew_record()
	GLOB.all_crew_records.Add(CR)
	CR.load_from_mob(H, TRUE)
	return CR

// Gets crew records filtered by set of positions
/proc/department_crew_manifest(list/filter_positions, blacklist = FALSE)
	var/list/matches = list()
	for(var/datum/computer_file/crew_record/CR in GLOB.all_crew_records)
		var/rank = CR.get_job()
		if(blacklist)
			if(!(rank in filter_positions))
				matches.Add(CR)
		else
			if(rank in filter_positions)
				matches.Add(CR)
	return matches

// Simple record to HTML (for paper purposes) conversion.
// Not visually that nice, but it gets the work done, feel free to tweak it visually
/proc/record_to_html(datum/computer_file/crew_record/CR, access)
	var/dat = "<tt><H2>RECORD DATABASE DATA DUMP</H2><i>Generated on: [stationdate2text()] [stationtime2text()]</i><br>******************************<br>"
	dat += "<table>"
	for(var/record_field/F in CR.fields)
		if(F.can_see(access))
			dat += "<tr><td><b>[F.name]</b>"
			if(F.valtype == EDIT_LONGTEXT)
				dat += "<tr>"
			dat += "<td>[F.get_display_value()]"
	dat += "</tt>"
	return dat

/proc/get_crewmember_record(name)
	for(var/datum/computer_file/crew_record/CR in GLOB.all_crew_records)
		if(CR.get_name() == name)
			return CR
	return null

/proc/GetAssignment(mob/living/carbon/human/H)
	if(!H)
		return "Unassigned"
	if(!H.mind)
		return H.job
	if(H.mind.role_alt_title)
		return H.mind.role_alt_title
	return H.mind.assigned_role

/record_field
	var/name = "Unknown"
	var/value = "Unset"
	var/valtype = EDIT_SHORTTEXT
	var/acccess
	var/acccess_edit
	var/record_id
	var/hidden = FALSE

/record_field/New(datum/computer_file/crew_record/record)
	if(!acccess_edit)
		acccess_edit = acccess ? acccess : access_heads
	if(record)
		record_id = record.uid
		record.fields += src
	..()

/record_field/proc/get_value()
	return value

/record_field/proc/get_display_value()
	if(valtype == EDIT_LONGTEXT)
		return rustoutf(rhtml_decode(pencode2html(value)))
	return rustoutf(rhtml_decode(value))

/record_field/proc/set_value(newval, automatic = FALSE)
	if(isnull(newval))
		return
	switch(valtype)
		if(EDIT_LIST)
			var/options = get_options()
			if(!(newval in options))
				return
		if(EDIT_SHORTTEXT)
			newval = sanitize(newval)
		if(EDIT_LONGTEXT)
			newval = sanitize(replacetext(newval, "\n", "\[br\]"), MAX_PAPER_MESSAGE_LEN)
	value = newval
	announce(automatic)
	return 1

/record_field/proc/get_options()
	return list()

/record_field/proc/can_edit(used_access)
	if(!acccess_edit)
		return TRUE
	if(!used_access)
		return FALSE
	return islist(used_access) ? (acccess_edit in used_access) : acccess_edit == used_access

/record_field/proc/can_see(used_access)
	if (hidden)
		return FALSE
	if(!acccess)
		return TRUE
	if(!used_access)
		return FALSE
	return islist(used_access) ? (acccess_edit in used_access) : acccess_edit == used_access

/record_field/proc/announce(automatic)
	return

#define GETTER_SETTER(KEY) /datum/computer_file/crew_record/proc/get_##KEY(){var/record_field/F = locate(/record_field/##KEY) in fields; if(F) return F.get_value()} \
/datum/computer_file/crew_record/proc/set_##KEY(value, automatic){var/record_field/F = locate(/record_field/##KEY) in fields; if(F) return F.set_value(value, automatic)}

// Fear not the preprocessor, for it is a friend. To add a field, use one of these, depending on value type and if you need special access to see it.
// It will also create getter/setter procs for record datum, named like /get_[key here]() /set_[key_here](value) e.g. get_name() set_name(value)
// Use getter setters to avoid errors caused by typoing the string key.
#define FIELD_SHORT(NAME, KEY, HIDDEN) /record_field/##KEY/name = ##NAME; /record_field/##KEY/hidden = ##HIDDEN; GETTER_SETTER(##KEY)
#define FIELD_SHORT_SECURE(NAME, KEY, HIDDEN, ACCESS) FIELD_SHORT(##NAME, ##KEY, ##HIDDEN); /record_field/##KEY/acccess = ##ACCESS

#define FIELD_LONG(NAME, KEY, HIDDEN) FIELD_SHORT(##NAME, ##KEY, ##HIDDEN); /record_field/##KEY/valtype = EDIT_LONGTEXT
#define FIELD_LONG_SECURE(NAME, KEY, HIDDEN, ACCESS) FIELD_LONG(##NAME, ##KEY, ##HIDDEN); /record_field/##KEY/acccess = ##ACCESS

#define FIELD_NUM(NAME, KEY, HIDDEN) FIELD_SHORT(##NAME, ##KEY, ##HIDDEN); /record_field/##KEY/valtype = EDIT_NUMERIC; /record_field/##KEY/value = 0
#define FIELD_NUM_SECURE(NAME, KEY, HIDDEN, ACCESS) FIELD_NUM(##NAME, ##KEY, ##HIDDEN); /record_field/##KEY/acccess = ##ACCESS

#define FIELD_LIST(NAME, KEY, HIDDEN, OPTIONS) FIELD_SHORT(##NAME, ##KEY, ##HIDDEN); /record_field/##KEY/valtype = EDIT_LIST; /record_field/##KEY/get_options(){. = ##OPTIONS;}
#define FIELD_LIST_SECURE(NAME, KEY, HIDDEN, OPTIONS, ACCESS) FIELD_LIST(##NAME, ##KEY, ##HIDDEN, ##OPTIONS); /record_field/##KEY/acccess = ##ACCESS

// GENERIC RECORDS
FIELD_SHORT("Name",name, FALSE)
FIELD_SHORT("Job",job, FALSE)
FIELD_LIST("Sex", sex, FALSE, record_genders())
FIELD_NUM("Age", age, FALSE)

FIELD_LIST("Status", status, FALSE, GLOB.physical_statuses)
/record_field/status/acccess_edit = access_medical

FIELD_SHORT("Species",species, FALSE)
FIELD_LIST("Branch", branch, TRUE, record_branches()) // hidden field
FIELD_LIST("Rank", rank, TRUE, record_ranks()) // hidden field

// MEDICAL RECORDS
FIELD_LIST("Blood Type", bloodtype, FALSE, GLOB.blood_types)
FIELD_LONG_SECURE("Medical Record", medRecord, FALSE, access_medical)

// SECURITY RECORDS
FIELD_LIST_SECURE("Criminal Status", criminalStatus, FALSE, GLOB.security_statuses, access_security)
/record_field/criminalStatus/announce(automatic)
	if(automatic)
		return
	for(var/datum/computer_file/crew_record/R in GLOB.all_crew_records)
		if(R.uid == record_id)
			var/status = "<font color='black'><b>None</b></font>"

			switch(value)
				if("Arrest")
					status = "<font color='red'><b>Arrest</b></font>"
				if("Incarcerated")
					status = "<font color='orange'><b>Incarcerated</b></font>"
				if("Parolled")
					status = "<font color='green'><b>Parolled</b></font>"
				if("Released")
					status = "<font color='blue'><b>Released</b></font>"

			GLOB.global_announcer.autosay("<font color='black'><b>[R.get_name()]</b> security status is changed to [status]!</font>", "<b>Security Records Announcer</b>", "Security")

FIELD_LONG_SECURE("Security Record", secRecord, FALSE, access_security)
/record_field/secRecord/announce(automatic)
	if(automatic)
		return
	for(var/datum/computer_file/crew_record/R in GLOB.all_crew_records)
		if(R.uid == record_id)
			GLOB.global_announcer.autosay("<font color='black'><b>[R.get_name()]</b> security record was changed!</font>", "<b>Security Records Announcer</b>", "Security")

FIELD_SHORT_SECURE("DNA", dna, FALSE, access_security)
FIELD_SHORT_SECURE("Fingerprint", fingerprint, FALSE, access_security)

// EMPLOYMENT RECORDS
FIELD_LONG_SECURE("Employment Record", emplRecord, FALSE, access_heads)
FIELD_SHORT_SECURE("Home System", homeSystem, FALSE, access_heads)
FIELD_SHORT_SECURE("Citizenship", citizenship, FALSE, access_heads)
FIELD_SHORT_SECURE("Faction", faction, FALSE, access_heads)
FIELD_SHORT_SECURE("Religion", religion, FALSE, access_heads)

// ANTAG RECORDS
FIELD_LONG_SECURE("Exploitable Information", antagRecord, FALSE, access_syndicate)

//Options builderes
/record_field/rank/proc/record_ranks()
	for(var/datum/computer_file/crew_record/R in GLOB.all_crew_records)
		if(R.uid == record_id)
			var/datum/mil_branch/branch = mil_branches.get_branch(R.get_branch())
			if(!branch)
				return null
			. = list()
			. |= "Unset"
			for(var/rank in branch.ranks)
				var/datum/mil_rank/RA = branch.ranks[rank]
				. |= RA.name

/record_field/sex/proc/record_genders()
	. = list()
	. |= "Unset"
	for(var/G in gender_datums)
		. |= gender2text(G)

/record_field/branch/proc/record_branches()
	. = list()
	. |= "Unset"
	for(var/B in mil_branches.branches)
		var/datum/mil_branch/BR = mil_branches.branches[B]
		. |= BR.name
