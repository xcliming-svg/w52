extends RefCounted
## The sole canonical story gate. Demo results never call accept_report().
const StoryData = preload("res://scripts/story_data.gd")
const MAX_WEEK := 52

var state: Dictionary = fresh_state()

static func fresh_state() -> Dictionary:
    return {
        "intro_seen_weeks": [], "post_win_seen_weeks": [], "evidence_flags": [],
        "card_index": 0, "pending_verified_post_week": 0,
        "processed_run_ids": [], "previous_deployment_snapshot": [],
        "pending_placement_snapshot": [], "pending_observations": {},
        "last_outcome": "", "ending_stage": "", "ending_seen": false,
        "legacy_demo_intro": false
    }

static func upgrade_early_v5(raw: Variant) -> Variant:
    # The first unreleased v5 revision did not include this legacy-dialogue flag.
    if not (raw is Dictionary):
        return raw
    var compatible: Dictionary = (raw as Dictionary).duplicate(true)
    if compatible.size() == fresh_state().size() - 1 and not compatible.has("legacy_demo_intro"):
        compatible["legacy_demo_intro"] = false
    return compatible


static func completed_weeks(raw: Dictionary) -> int:
    return (raw.get("post_win_seen_weeks", []) as Array).size()

func export_state() -> Dictionary:
    return state.duplicate(true)

func clear() -> void:
    state = fresh_state()

func can_show_intro(at_week: int) -> bool:
    return at_week >= 1 and at_week <= MAX_WEEK and completed_weeks(state) >= at_week - 1

func mark_intro_seen(at_week: int) -> bool:
    if not can_show_intro(at_week):
        return false
    if at_week not in state["intro_seen_weeks"]:
        state["intro_seen_weeks"].append(at_week)
    return true

static func _valid_snapshot(raw: Variant) -> bool:
    if not (raw is Array) or raw.size() > 12:
        return false
    var ids: Dictionary = {}
    var occupied: Dictionary = {}
    for item in raw:
        if not (item is Dictionary) or item.size() != 4:
            return false
        for key in ["instance_id", "unit_id", "col", "row"]:
            if not item.has(key):
                return false
        if not (item["instance_id"] is String) or not (item["unit_id"] is String):
            return false
        if not (item["col"] is int) or not (item["row"] is int):
            return false
        if str(item["instance_id"]).strip_edges().is_empty() or ids.has(item["instance_id"]):
            return false
        if str(item["unit_id"]).strip_edges().is_empty() or int(item["col"]) < 0 or int(item["row"]) < 0:
            return false
        var cell_key: String = "%d:%d" % [item["col"], item["row"]]
        if occupied.has(cell_key):
            return false
        ids[item["instance_id"]] = true
        occupied[cell_key] = true
    return true

static func _valid_unique_strings(raw: Variant, max_count: int) -> bool:
    if not (raw is Array) or (max_count >= 0 and raw.size() > max_count):
        return false
    var keys: Dictionary = {}
    for value in raw:
        if not (value is String) or value.strip_edges().is_empty() or keys.has(value):
            return false
        if value.length() > 160:
            return false
        keys[value] = true
    return true

static func validate_state(raw: Variant, at_week: int, phase: String) -> bool:
    if not (raw is Dictionary) or at_week < 1 or at_week > MAX_WEEK:
        return false
    var canonical := fresh_state()
    if raw.size() != canonical.size():
        return false
    for key in canonical:
        if not raw.has(key):
            return false
    if not (raw["intro_seen_weeks"] is Array) or not (raw["post_win_seen_weeks"] is Array):
        return false
    var intros: Array = raw["intro_seen_weeks"]
    for i in range(intros.size()):
        if not (intros[i] is int) or intros[i] != i + 1 or intros[i] > at_week:
            return false
    var finished: Array = raw["post_win_seen_weeks"]
    if finished.size() > at_week:
        return false
    for i in range(finished.size()):
        if not (finished[i] is int) or finished[i] != i + 1:
            return false
        if i + 1 not in raw["intro_seen_weeks"]:
            return false
    for w in raw["intro_seen_weeks"]:
        if w > finished.size() + 1:
            return false
    var evidence: Variant = raw["evidence_flags"]
    if not (evidence is Array) or evidence.size() != finished.size():
        return false
    for i in range(evidence.size()):
        if not (evidence[i] is String) or evidence[i] != "E_W%02d" % (i + 1):
            return false
    if not _valid_unique_strings(raw["processed_run_ids"], -1):
        return false
    if raw["processed_run_ids"].size() < finished.size():
        return false
    if not _valid_snapshot(raw["previous_deployment_snapshot"]) or not _valid_snapshot(raw["pending_placement_snapshot"]):
        return false
    if finished.size() > 0 and raw["previous_deployment_snapshot"].is_empty():
        return false
    if finished.is_empty() and not raw["previous_deployment_snapshot"].is_empty():
        return false
    if not (raw["pending_observations"] is Dictionary):
        return false
    for key in raw["pending_observations"]:
        if key not in ["previous_match", "current_match", "decoy_a_match", "decoy_split_match", "tank_deployed"]:
            return false
        if not (raw["pending_observations"][key] is bool):
            return false
    if not (raw["card_index"] is int) or raw["card_index"] < 0:
        return false
    if not (raw["pending_verified_post_week"] is int):
        return false
    if not (raw["last_outcome"] is String) or raw["last_outcome"] not in ["", "DEMO_RESULT", "WIN", "LOSE", "DRAW"]:
        return false
    if not (raw["ending_seen"] is bool) or not (raw["ending_stage"] is String) or not (raw["legacy_demo_intro"] is bool):
        return false
    if raw["ending_stage"] not in ["", "w52", "w53"]:
        return false
    if raw["legacy_demo_intro"]:
        if phase != "dialogue" or not finished.is_empty() or not raw["intro_seen_weeks"].is_empty():
            return false
        if raw["card_index"] >= 5 or raw["last_outcome"] != "":
            return false
    var pending: int = raw["pending_verified_post_week"]
    if pending != 0 and raw["processed_run_ids"].size() <= finished.size():
        return false
    if phase == "post_story":
        if pending != at_week or finished.size() != at_week - 1 or raw["last_outcome"] != "WIN":
            return false
        if at_week not in intros:
            return false
        if raw["pending_placement_snapshot"].is_empty():
            return false
    elif pending != 0 or not raw["pending_observations"].is_empty() or not raw["pending_placement_snapshot"].is_empty():
        return false
    if raw["ending_seen"] and (at_week != 52 or finished.size() != 52 or phase != "result"):
        return false
    if phase == "ending":
        if at_week != 52 or finished.size() != 52 or raw["ending_seen"] or raw["ending_stage"] == "":
            return false
    elif raw["ending_stage"] != "":
        return false
    var outcome: String = raw["last_outcome"]
    if phase in ["dialogue", "prepare", "battle"] and outcome != "":
        return false
    if phase in ["post_story", "ending"] and outcome != "WIN":
        return false
    if phase in ["dialogue", "prepare", "battle"] and finished.size() >= at_week:
        return false
    if phase == "result":
        if outcome == "" or (outcome == "WIN" and finished.size() != at_week):
            return false
        if outcome in ["DEMO_RESULT", "LOSE", "DRAW"] and finished.size() >= at_week:
            return false
        if finished.size() == MAX_WEEK and not raw["ending_seen"]:
            return false
    if raw["ending_seen"] and outcome != "WIN":
        return false
    if not raw["ending_seen"] and finished.size() == MAX_WEEK and phase != "ending":
        return false
    var count := 0
    if phase == "dialogue":
        count = 5 if raw["legacy_demo_intro"] else (StoryData.cards(at_week, "intro").size() if finished.size() >= at_week - 1 else 1)
    elif phase == "post_story":
        count = StoryData.cards(at_week, "post").size()
    elif phase == "ending":
        count = StoryData.ending_cards().size() if raw["ending_stage"] == "w52" else StoryData.epilogue_cards().size()
    if phase in ["dialogue", "post_story", "ending"]:
        if raw["card_index"] >= count:
            return false
    elif raw["card_index"] != 0:
        return false
    return true

func restore(raw: Variant, at_week: int, phase: String) -> bool:
    var compatible: Variant = upgrade_early_v5(raw)
    if not validate_state(compatible, at_week, phase):
        return false
    state = (compatible as Dictionary).duplicate(true)
    return true

static func _matching_positions(source: Variant, observation: Variant) -> bool:
    if not (source is Array) or not (observation is Array) or source.is_empty() or observation.is_empty():
        return false
    var keys: Dictionary = {}
    for raw in source:
        if not (raw is Dictionary) or not (raw.get("col", null) is int) or not (raw.get("row", null) is int):
            return false
        if not (raw.get("unit_id", null) is String):
            return false
        keys["%d:%d" % [raw["col"], raw["row"]]] = raw["unit_id"]
    var matched := 0
    for raw in observation:
        if not (raw is Dictionary) or not (raw.get("col", null) is int) or not (raw.get("row", null) is int):
            return false
        if raw.has("unit_id") and not (raw["unit_id"] is String):
            return false
        var key: String = "%d:%d" % [raw["col"], raw["row"]]
        if keys.has(key) and (not raw.has("unit_id") or raw["unit_id"] == keys[key]):
            matched += 1
    return matched > 0


static func _identical_positions(left: Variant, right: Variant) -> bool:
    if not (left is Array) or not (right is Array) or left.is_empty() or left.size() != right.size():
        return false
    var a: Array[String] = []
    var b: Array[String] = []
    var left_seen: Dictionary = {}
    var right_seen: Dictionary = {}
    for raw in left:
        if not (raw is Dictionary) or not (raw.get("col", null) is int) or not (raw.get("row", null) is int):
            return false
        if raw["col"] < 0 or raw["row"] < 0:
            return false
        var key: String = "%d:%d" % [raw["col"], raw["row"]]
        if left_seen.has(key):
            return false
        left_seen[key] = true
        a.append(key)
    for raw in right:
        if not (raw is Dictionary) or not (raw.get("col", null) is int) or not (raw.get("row", null) is int):
            return false
        if raw["col"] < 0 or raw["row"] < 0:
            return false
        var other_key: String = "%d:%d" % [raw["col"], raw["row"]]
        if right_seen.has(other_key):
            return false
        right_seen[other_key] = true
        b.append(other_key)
    a.sort()
    b.sort()
    for i in range(a.size()):
        if a[i] != b[i]:
            return false
    return true


func _context_from_report(report: Dictionary) -> Dictionary:
    var observations: Variant = report.get("optional_observations", {})
    if not (observations is Dictionary):
        return {}
    var current: Array = report.get("placement_snapshot", [])
    var at_week: int = report["week"]
    var context := {"tank_deployed": false, "previous_match": false,
        "current_match": false, "decoy_a_match": false, "decoy_split_match": false}
    for p in current:
        if (p as Dictionary).get("unit_id", "") == "tank":
            context["tank_deployed"] = true
    if at_week == 18:
        context["previous_match"] = _matching_positions(
            state["previous_deployment_snapshot"], observations.get("w17_enemy_document_positions", []))
    if at_week == 26:
        context["current_match"] = _matching_positions(
            current, observations.get("enemy_deployment_positions", []))
    var archive_verified: Variant = observations.get("decoy_archived_before_battle", false)
    if at_week in [38, 39] and archive_verified is bool and archive_verified:
        var enemy: Variant = observations.get("enemy_initial_positions", [])
        var a: Variant = observations.get("decoy_plan_a_positions", [])
        var b: Variant = observations.get("decoy_plan_b_positions", [])
        context["decoy_a_match"] = _identical_positions(enemy, a)
        context["decoy_split_match"] = context["decoy_a_match"] and b is Array and not b.is_empty() and not _identical_positions(enemy, b)
    return context

func accept_report(report: Dictionary, at_week: int, expected_snapshot: Array) -> Dictionary:
    # Called by a future genuine combat adapter, never by the timed demonstration.
    var failure := {"ok": false, "error": "invalid_report"}
    if at_week < 1 or at_week > MAX_WEEK or not can_show_intro(at_week) or at_week not in state["intro_seen_weeks"]:
        failure["error"] = "story_locked"
        return failure
    if not (report.get("week", null) is int) or report["week"] != at_week:
        failure["error"] = "week_mismatch"
        return failure
    var run_id: Variant = report.get("run_id", "")
    var result: Variant = report.get("result", "")
    if not (run_id is String) or run_id.strip_edges().is_empty() or run_id.length() > 160:
        return failure
    if run_id in state["processed_run_ids"]:
        failure["error"] = "duplicate_run"
        return failure
    if result not in ["WIN", "LOSE", "DRAW"]:
        return failure
    if state["pending_verified_post_week"] != 0 or at_week in state["post_win_seen_weeks"]:
        failure["error"] = "already_resolved"
        return failure
    if result == "WIN":
        var scene: Dictionary = StoryData.get_week(at_week)
        var spawned: Variant = report.get("enemy_instance_ids_spawned", null)
        var defeated: Variant = report.get("enemy_instance_ids_defeated", null)
        var unit_map: Variant = report.get("enemy_unit_id_by_instance", null)
        var evidence: Variant = report.get("evidence_source_instance_id", "")
        var survivors: Variant = report.get("allied_survivors", -1)
        var placement: Variant = report.get("placement_snapshot", null)
        if not _valid_unique_strings(spawned, 256) or spawned.is_empty():
            failure["error"] = "invalid_enemies"
            return failure
        if not _valid_unique_strings(defeated, 256) or defeated.size() != spawned.size():
            failure["error"] = "enemy_not_defeated"
            return failure
        if not (unit_map is Dictionary) or unit_map.size() != spawned.size():
            failure["error"] = "invalid_unit_mapping"
            return failure
        for id in spawned:
            if id not in defeated or not (unit_map.get(id, null) is String) or unit_map[id] not in scene["enemy_set"]:
                failure["error"] = "enemy_not_defeated"
                return failure
        if not (evidence is String) or evidence not in spawned or evidence not in defeated:
            failure["error"] = "evidence_missing"
            return failure
        if unit_map[evidence] != scene["evidence_source_unit_id"]:
            failure["error"] = "evidence_unit_mismatch"
            return failure
        if not (survivors is int) or survivors < 1:
            failure["error"] = "no_allied_survivors"
            return failure
        if not _valid_snapshot(placement) or not _valid_snapshot(expected_snapshot) or placement.is_empty() or placement != expected_snapshot:
            failure["error"] = "placement_mismatch"
            return failure
        var obs := _context_from_report(report)
        state["pending_verified_post_week"] = at_week
        state["pending_observations"] = obs
        state["pending_placement_snapshot"] = (placement as Array).duplicate(true)
        state["card_index"] = 0
    state["processed_run_ids"].append(run_id)
    state["last_outcome"] = result
    return {"ok": true, "result": result}

func finish_post(at_week: int) -> bool:
    if state["pending_verified_post_week"] != at_week or completed_weeks(state) != at_week - 1:
        return false
    state["post_win_seen_weeks"].append(at_week)
    state["evidence_flags"].append("E_W%02d" % at_week)
    state["previous_deployment_snapshot"] = state["pending_placement_snapshot"].duplicate(true)
    state["pending_placement_snapshot"] = []
    state["pending_observations"] = {}
    state["pending_verified_post_week"] = 0
    state["card_index"] = 0
    return true

func finish_epilogue() -> bool:
    if completed_weeks(state) != MAX_WEEK or state["ending_seen"] or state["ending_stage"] != "w53":
        return false
    state["ending_stage"] = ""
    state["ending_seen"] = true
    state["card_index"] = 0
    return true
