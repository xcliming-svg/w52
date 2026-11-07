class_name RBalanceProvenance
extends RefCounted

# Candidates from CONTRACT v1.1, not measured/approved shipped balancing.
const CONTRACT_VERSION: String="v1.1"
const SOURCE_DATE: String="2026-11-07"
const COHORT_MODEL_MULTIPLIER: float=1.25
const MODEL_ASSUMPTION: String="R15 aggregate firepower compensation: provisional, not applied blindly to physics"
const LIVE_QA: bool=false

static func metadata() -> Dictionary:
	return {"contract":CONTRACT_VERSION,"source_date":SOURCE_DATE,"cohort_compensation":COHORT_MODEL_MULTIPLIER,"runtime_balance_verified":LIVE_QA,"note":MODEL_ASSUMPTION}

static func tooltip() -> String:
	return "밸런스 수치는 실플레이 확정값이 아니라 초기 후보입니다."
