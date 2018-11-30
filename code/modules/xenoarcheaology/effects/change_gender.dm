/datum/artifact_effect/change_gender
	name = "change gender"
	effect_type = EFFECT_ORGANIC
	var/gender = null

/datum/artifact_effect/change_gender/New()
	..()
	effect = EFFECT_PULSE
	gender = pick(MALE, FEMALE)

/datum/artifact_effect/change_gender/DoEffectPulse()
	if(holder)
		var/turf/T = get_turf(holder)
		for (var/mob/living/carbon/human/H in range(src.effectrange, T))
			var/weakness = GetAnomalySusceptibility(H)
			if(prob(100 * weakness))
				to_chat(H, "<span class='warning'>You feel some discomfort in your body!</span>")
				H.change_gender(gender)

				var/datum/effect/effect/system/spark_spread/sparks = new /datum/effect/effect/system/spark_spread()
				sparks.set_up(3, 0, get_turf(H))
				sparks.start()
