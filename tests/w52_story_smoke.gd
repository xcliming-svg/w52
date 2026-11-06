extends SceneTree
## Contract test. Godot is not run locally under AGENTS.md's current policy.
const Data = preload("res://scripts/story_data.gd")
const Flow = preload("res://scripts/story_flow.gd")
const Save = preload("res://scripts/save_manager.gd")
const Game = preload("res://scripts/game.gd")

var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")


func _check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error("W52 story: " + message)


func _placement(at_week: int) -> Array:
    var sz: Vector2i = Game.grid_size_for_week(at_week)
    return [{"instance_id":"test_unit", "unit_id":"rifle", "col":1, "row":sz.y - 1}]


func _report(at_week: int, run_id: String, result: String = "WIN") -> Dictionary:
    var scene: Dictionary = Data.get_week(at_week)
    var unit: String = str(scene["evidence_source_unit_id"])
    var units: Dictionary = {}
    units["enemy_%02d" % at_week] = unit
    return {
        "week":at_week, "run_id":run_id, "result":result,
        "enemy_instance_ids_spawned":["enemy_%02d" % at_week],
        "enemy_instance_ids_defeated":["enemy_%02d" % at_week],
        "enemy_unit_id_by_instance":units,
        "evidence_source_instance_id":"enemy_%02d" % at_week,
        "allied_survivors":1,
        "placement_snapshot":_placement(at_week),
        "optional_observations":{}
    }


func _blank_save(at_week: int, phase: String, state: Dictionary) -> Dictionary:
    return {
        "week":at_week, "g":160, "phase":phase, "dialogue":int(state["card_index"]),
        "help":at_week, "placements":_placement(at_week),
        "buildings":["hq", "robot_factory"], "story":state.duplicate(true)
    }


func _save_resume(store: Variant, at_week: int, phase: String, state: Dictionary) -> void:
    var source: Dictionary = _blank_save(at_week, phase, state)
    _check(Flow.validate_state(state, at_week, phase),
        "pre-save state rejected %02d %s" % [at_week, phase])
    if not store.save_game(source):
        _check(false, "could not write v5 state %02d %s" % [at_week, phase])
        return
    var loaded: Dictionary = store.load_game()
    _check(not loaded.is_empty(), "could not load v5 state")
    if loaded.is_empty():
        return
    _check(loaded.get("story", {}) == state, "v5 story lost flags/index at %02d %s" % [at_week, phase])
    _check(loaded.get("placements", []) == source["placements"], "v5 placement mismatch")
    var restored = Flow.new()
    _check(restored.restore(loaded["story"], at_week, phase), "v5 canonical restoration failed")


func _old_versions(store: Variant) -> void:
    for version in [1, 2, 3, 4]:
        var config := ConfigFile.new()
        var sz: Vector2i = Game.grid_size_for_week(24)
        config.set_value("session", "version", version)
        config.set_value("session", "week", 24)
        config.set_value("session", "g", 731)
        config.set_value("session", "phase", "result")
        config.set_value("session", "dialogue", 5)
        config.set_value("session", "help", 24)
        if version >= 3:
            config.set_value("session", "buildings", ["hq", "robot_factory"])
        if version <= 3:
            config.set_value("session", "placements", ["rifle"])
        else:
            config.set_value("session", "placements", [
                {"instance_id":"v4_unit", "unit_id":"rifle", "col":1, "row":sz.y - 1}])
        _check(config.save("user://game_save.cfg") == OK, "fixture file write failed")
        var loaded: Dictionary = store.load_game()
        if version == 1:
            _check(loaded.is_empty(), "v1 save incorrectly accepted")
            continue
        _check(int(loaded.get("week", -1)) == 24 and int(loaded.get("g", -1)) == 731,
            "legacy progress lost v%d" % version)
        _check(loaded.get("placements", []).size() == 1, "legacy placements lost")
        var story: Dictionary = loaded.get("story", {})
        _check(story.get("evidence_flags", []).is_empty() and
            story.get("post_win_seen_weeks", []).is_empty() and not story.get("ending_seen", true),
            "v%d demo result invented canonical evidence" % version)
        _check(story.get("last_outcome", "") == "DEMO_RESULT",
            "v%d demo outcome migration incorrect" % version)
        _check(store.save_game(loaded), "legacy to v5 write failed")
        var v5 := ConfigFile.new()
        _check(v5.load("user://game_save.cfg") == OK and
            int(v5.get_value("session", "version", 0)) == 5, "migration did not create v5")


func _early_v5_resume(store: Variant) -> void:
    var original_state: Dictionary = Flow.fresh_state()
    original_state.erase("legacy_demo_intro")
    var old_v5: Dictionary = _blank_save(1, "prepare", original_state)
    var config := ConfigFile.new()
    config.set_value("session", "version", 5)
    for key in ["week", "g", "phase", "dialogue", "help", "placements", "buildings", "story"]:
        config.set_value("session", key, old_v5[key])
    _check(config.save("user://game_save.cfg") == OK, "early-v5 fixture write failed")
    var loaded: Dictionary = store.load_game()
    _check(not loaded.is_empty(), "earlier v5 state lost on schema extension")
    if loaded.is_empty():
        return
    _check(not loaded["story"]["legacy_demo_intro"] and
        loaded["story"]["evidence_flags"].is_empty(), "earlier v5 acquired false story progress")
    _check(store.save_game(loaded), "upgraded early v5 could not be saved")
    _check(store.load_game().get("story", {}) == loaded["story"],
        "early v5 normalization did not persist")


func _legacy_dialogue_resume(store: Variant) -> void:
    for at_week in [1, 24]:
        for old_index in [0, 1, 3, 4, 5]:
            var config := ConfigFile.new()
            config.set_value("session", "version", 4)
            config.set_value("session", "week", at_week)
            config.set_value("session", "g", 211)
            config.set_value("session", "phase", "dialogue")
            config.set_value("session", "dialogue", old_index)
            config.set_value("session", "help", at_week)
            config.set_value("session", "placements", [])
            config.set_value("session", "buildings", ["hq", "robot_factory"])
            _check(config.save("user://game_save.cfg") == OK, "legacy dialogue fixture write failed")
            var loaded: Dictionary = store.load_game()
            _check(not loaded.is_empty(), "legacy dialogue v4 rejected")
            if loaded.is_empty():
                continue
            var story: Dictionary = loaded["story"]
            _check(story["evidence_flags"].is_empty() and story["intro_seen_weeks"].is_empty(),
                "legacy demo invented canonical story history")
            if old_index < 5:
                _check(loaded["phase"] == "dialogue" and story["legacy_demo_intro"] and
                    story["card_index"] == old_index,
                    "old demo dialogue index was interpreted as v9 progress")
                _check(Data.legacy_demo_cards(at_week).size() == 5,
                    "legacy dialogue deck no longer preserves five-card progress")
            else:
                _check(loaded["phase"] == "prepare" and not story["legacy_demo_intro"],
                    "completed old briefing did not move to prepare")
            _check(store.save_game(loaded), "legacy dialogue failed to save in v5")
            var resumed: Dictionary = store.load_game()
            _check(resumed.get("story", {}) == story,
                "legacy dialogue save/restore lost source index or introduced canon facts")



func _run() -> void:
    _check(Data.SCENES.size() == 52, "incomplete W01-W52 scenes")
    var ids: Dictionary = {}
    var speakers := Data.SPEAKERS.keys()
    for w in range(1, 53):
        var scene: Dictionary = Data.get_week(w)
        _check(int(scene.get("week", -1)) == w, "missing story week %02d" % w)
        _check(scene.get("evidence_id", "") == "E_W%02d" % w, "missing evidence ID")
        var source: String = str(scene.get("evidence_source_unit_id", ""))
        _check(source in scene.get("enemy_set", []), "evidence type not spawned")
        var valid_unit := false
        for node in Game.NODES:
            if node["id"] == source and node["kind"] == "unit":
                valid_unit = true
        _check(valid_unit, "evidence unit not found in the 12 known units")
        _check(not ids.has(scene["evidence_id"]), "duplicate evidence")
        ids[scene["evidence_id"]] = true
        var intro: Array = Data.cards(w, "intro")
        var post: Array = Data.cards(w, "post")
        _check(not intro.is_empty() and not post.is_empty(), "missing dialogue cards")
        var receipt_count := 0
        for card in post:
            if str(card["text"]).begins_with("회수 단서 %s:" % str(scene["evidence_id"])):
                receipt_count += 1
        _check(receipt_count == 1, "verified post-story is missing clue receipt W%02d" % w)
        var character_cards := 0
        for card in intro + post:
            _check(card.get("speaker", "") in speakers and not str(card.get("text", "")).strip_edges().is_empty(),
                "invalid speaker/card at W%02d" % w)
            if card["speaker"] != "narrator":
                character_cards += 1
            if w >= 44:
                _check(card["speaker"] != "noah", "Noah speaks after W43")
            if w < 50 or w == 50 and card in intro:
                _check(card["speaker"] != "eva_record", "Eva record leaked early")
        _check(character_cards >= 2, "not enough authored character dialogue")

    for branch in [
        [9, "intro", {"walker_owned":true}],
        [15, "intro", {"hangar_owned":true}],
        [19, "post", {"tank_deployed":true}],
        [18, "post", {"previous_match":true}],
        [26, "post", {"current_match":true}],
        [38, "post", {"decoy_a_match":true}],
        [39, "post", {"decoy_split_match":true}]
    ]:
        var with_fact: Array = Data.cards(branch[0], branch[1], branch[2])
        var without_fact: Array = Data.cards(branch[0], branch[1])
        _check(with_fact.size() == without_fact.size() and
            with_fact[-1]["text"] != without_fact[-1]["text"],
            "optional event condition changed core story or failed to branch W%02d" % branch[0])

    var locked = Flow.new()
    _check(not locked.can_show_intro(2), "W02 intro leaked without W01")
    _check(not locked.accept_report(_report(3, "early_03"), 3, _placement(3))["ok"],
        "W03 passed without consecutive W01-W02")
    _check(locked.state["evidence_flags"].size() == 0, "early report granted evidence")

    var flow = Flow.new()
    var store = Save.new()
    for w in range(1, 53):
        if w > 1:
            # Match Game._set_week_intro(): a prior WIN is not this week's result.
            flow.state["last_outcome"] = ""
            flow.state["card_index"] = 0
        _check(flow.can_show_intro(w), "consecutive story intro remained locked")
        flow.mark_intro_seen(w)
        var beginning := Flow.completed_weeks(flow.state)
        for result in ["LOSE", "DRAW"]:
            var no_win: Dictionary = flow.accept_report(
                _report(w, "no_win_%s_%02d" % [result, w], result), w, _placement(w))
            _check(no_win.get("ok", false), "valid non-win result was not recognized")
            _check(Flow.completed_weeks(flow.state) == beginning and
                flow.state["evidence_flags"].size() == beginning,
                "LOSE/DRAW unlocked post-win evidence")
        # A retry returns to prepare and clears the previous non-winning result.
        flow.state["last_outcome"] = ""
        _check(Flow.validate_state(flow.export_state(), w, "prepare"),
            "retry fixture must match a valid prepare state")
        var missing: Dictionary = _report(w, "missing_evidence_%02d" % w)
        missing["evidence_source_instance_id"] = "none"
        _check(not flow.accept_report(missing, w, _placement(w))["ok"], "missing evidence accepted")
        var unkill: Dictionary = _report(w, "undefeated_%02d" % w)
        unkill["enemy_instance_ids_defeated"] = []
        _check(not flow.accept_report(unkill, w, _placement(w))["ok"], "undefeated enemy accepted")
        var dead: Dictionary = _report(w, "allies_dead_%02d" % w)
        dead["allied_survivors"] = 0
        _check(not flow.accept_report(dead, w, _placement(w))["ok"], "no survivors accepted")
        var wrong: Dictionary = _report(w, "wrong_week_%02d" % w)
        wrong["week"] = w + 1
        _check(not flow.accept_report(wrong, w, _placement(w))["ok"], "wrong week accepted")
        var out_of_plan: Dictionary = _report(w, "wrong_placement_%02d" % w)
        out_of_plan["placement_snapshot"] = []
        _check(not flow.accept_report(out_of_plan, w, _placement(w))["ok"], "invented placement accepted")
        var duplicated: Dictionary = _report(w, "duplicate_cell_%02d" % w)
        var extra: Dictionary = _placement(w)[0].duplicate(true)
        extra["instance_id"] = "second_unit"
        var two_at_same_cell: Array = _placement(w) + [extra]
        duplicated["placement_snapshot"] = two_at_same_cell
        _check(not flow.accept_report(duplicated, w, two_at_same_cell)["ok"],
            "duplicate ally positions accepted")

        if w in [26, 38, 39]:
            var comparison_flow = Flow.new()
            _check(comparison_flow.restore(flow.export_state(), w, "prepare"),
                "comparison fixture rejected at W%02d" % w)
            var comparison: Dictionary = _report(w, "verified_comparison_%02d" % w)
            if w == 26:
                comparison["optional_observations"] = {"enemy_deployment_positions":[
                    {"col":1, "row":Game.grid_size_for_week(w).y - 1}]}
            else:
                comparison["optional_observations"] = {
                    "decoy_archived_before_battle":true,
                    "enemy_initial_positions":[{"col":2, "row":1}],
                    "decoy_plan_a_positions":[{"col":2, "row":1}],
                    "decoy_plan_b_positions":[{"col":0, "row":2}]
                }
            _check(comparison_flow.accept_report(comparison, w, _placement(w)).get("ok", false),
                "verified tactical evidence rejected")
            var key: String = "current_match" if w == 26 else "decoy_a_match" if w == 38 else "decoy_split_match"
            _check(comparison_flow.state["pending_observations"][key],
                "verified coordinate comparison did not enable matching branch")
            var verified_cards: Array = Data.cards(w, "post", comparison_flow.state["pending_observations"])
            _check(verified_cards[-1]["text"] != Data.cards(w, "post")[-1]["text"],
                "verified comparison did not change the spoken line")
            var negative_flow = Flow.new()
            _check(negative_flow.restore(flow.export_state(), w, "prepare"),
                "negative comparison fixture rejected")
            var negative_report: Dictionary = _report(w, "negative_comparison_%02d" % w)
            if w == 26:
                negative_report["optional_observations"] = {"enemy_deployment_positions":[
                    {"col":1, "row":Game.grid_size_for_week(w).y - 1, "unit_id":"bomber"}]}
            elif w == 38:
                negative_report["optional_observations"] = {
                    "decoy_archived_before_battle":true,
                    "enemy_initial_positions":[{"col":2, "row":1}],
                    "decoy_plan_a_positions":[{"col":0, "row":2}],
                    "decoy_plan_b_positions":[{"col":1, "row":2}]
                }
            else:
                negative_report["optional_observations"] = {
                    "decoy_archived_before_battle":true,
                    "enemy_initial_positions":[{"col":2, "row":1}],
                    "decoy_plan_a_positions":[{"col":2, "row":1}],
                    "decoy_plan_b_positions":[{"col":2, "row":1}]
                }
            _check(negative_flow.accept_report(negative_report, w, _placement(w)).get("ok", false),
                "negative comparison WIN was invalid")
            _check(not negative_flow.state["pending_observations"][key],
                "mismatched type/coordinates falsely unlocked tactical dialogue")
        var report: Dictionary = _report(w, "win_%02d" % w)
        if w == 18:
            report["optional_observations"] = {"w17_enemy_document_positions":[
                {"col":1, "row":Game.grid_size_for_week(17).y - 1}]}
        var accepted: Dictionary = flow.accept_report(report, w, _placement(w))
        _check(accepted.get("ok", false) and flow.state["pending_verified_post_week"] == w,
            "verified victory rejected W%02d" % w)
        _check(Flow.completed_weeks(flow.state) == beginning, "evidence granted before post ack")
        _check(not flow.accept_report(report, w, _placement(w))["ok"], "duplicate run accepted")
        if w == 18:
            _check(flow.state["pending_observations"]["previous_match"], "W17 snapshot comparison failed")
        if w in [26, 38, 39]:
            var neutral: Array = Data.cards(w, "post", flow.state["pending_observations"])
            _check(("미확인" in str(neutral[-1]["text"]) or
                "검증" in str(neutral[-1]["text"]) or
                "완료되지" in str(neutral[-1]["text"])),
                "unverified tactical comparison asserted as fact")
        if w == 17:
            var pending_story: Dictionary = flow.export_state()
            pending_story["card_index"] = 1
            _save_resume(store, w, "post_story", pending_story)
        if w == 43:
            var halfway: Dictionary = flow.export_state()
            halfway["card_index"] = 1
            _save_resume(store, w, "post_story", halfway)
        _check(flow.finish_post(w), "post-story acknowledgement rejected")
        _check(not flow.finish_post(w), "post-story duplicate granted evidence")
        _check(Flow.completed_weeks(flow.state) == w and
            flow.state["evidence_flags"].size() == w, "consecutive evidence mismatch")
        if w == 16:
            var entering_17: Dictionary = flow.export_state()
            entering_17["card_index"] = 1
            entering_17["last_outcome"] = ""
            _save_resume(store, 17, "dialogue", entering_17)
        if w == 52:
            var ending := flow.export_state()
            ending["ending_stage"] = "w52"
            ending["card_index"] = 1
            _save_resume(store, 52, "ending", ending)
            ending["ending_stage"] = "w53"
            ending["card_index"] = 6
            _check(Data.epilogue_cards().size() >= 7, "epilogue has no late-card resume case")
            _save_resume(store, 52, "ending", ending)
            flow.state["ending_stage"] = "w53"
            _check(flow.finish_epilogue(), "W53 epilogue did not complete")
            _check(not flow.finish_epilogue(), "W53 epilogue replayed")
            _check(Flow.validate_state(flow.export_state(), 52, "result"), "final state invalid")

    _old_versions(store)
    _early_v5_resume(store)
    _legacy_dialogue_resume(store)
    var corrupt: Dictionary = flow.export_state()
    corrupt["post_win_seen_weeks"] = [1, 3]
    _check(not Flow.validate_state(corrupt, 52, "result"), "nonconsecutive post history accepted")
    corrupt = flow.export_state()
    corrupt["evidence_flags"].remove_at(30)
    _check(not Flow.validate_state(corrupt, 52, "result"), "missing evidence accepted")
    corrupt = Flow.fresh_state()
    corrupt["ending_seen"] = true
    _check(not Flow.validate_state(corrupt, 1, "result"), "fake W52 ending accepted")
    corrupt = flow.export_state()
    corrupt["intro_seen_weeks"] = [2, 1]
    _check(not Flow.validate_state(corrupt, 52, "result"), "reordered intro history accepted")
    corrupt = flow.export_state()
    corrupt["last_outcome"] = "DEMO_RESULT"
    _check(not Flow.validate_state(corrupt, 52, "result"), "demo overwrote canonical ending")
    corrupt = flow.export_state()
    corrupt["legacy_demo_intro"] = true
    _check(not Flow.validate_state(corrupt, 52, "result"), "legacy flag accepted after canonical wins")
    var invalid_v5: Dictionary = _blank_save(52, "result", flow.export_state())
    invalid_v5["story"]["evidence_flags"].remove_at(5)
    _check(not store.save_game(invalid_v5), "v5 writer accepted missing canonical evidence")
    var direct := ConfigFile.new()
    direct.set_value("session", "version", 5)
    for key in ["week", "g", "phase", "dialogue", "help", "placements", "buildings", "story"]:
        direct.set_value("session", key, invalid_v5[key])
    _check(direct.save("user://game_save.cfg") == OK, "could not write v5 corruption fixture")
    _check(store.load_game().is_empty(), "v5 loader accepted missing canonical evidence")
    var incomplete := ConfigFile.new()
    incomplete.set_value("session", "version", 5)
    for key in ["week", "g", "phase", "dialogue", "placements", "buildings", "story"]:
        incomplete.set_value("session", key, _blank_save(52, "result", flow.export_state())[key])
    _check(incomplete.save("user://game_save.cfg") == OK, "missing-help fixture could not be written")
    _check(store.load_game().is_empty(), "incomplete v5 save silently substituted a help value")
    var invalid_help: Dictionary = _blank_save(52, "result", flow.export_state())
    invalid_help["help"] = -1
    _check(not store.save_game(invalid_help), "v5 writer accepted illegal help range")
    _check(store.clear_save(), "temporary fixture cleanup failed")
    if failures == 0:
        print("W52_STORY_SMOKE_OK: 52 scenes, 52 evidence IDs, WIN/LOSE/DRAW, consecutive gates, duplicate runs, placements, W43/W44/W50, W52/W53, legacy v2/v3/v4 and v5")
    quit(0 if failures == 0 else 1)
