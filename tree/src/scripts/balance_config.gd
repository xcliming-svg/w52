class_name RBalance
extends RefCounted

# CONTRACT.md v1.1: game rules are shared by Windows and Web.
const TICK_RATE: int = 60
const WORLD_SIZE: Vector2 = Vector2(1325.0, 950.0)
const CENTER: Vector2 = Vector2(662.5, 457.5)
const CORNERS: Array[Vector2] = [Vector2(75,70), Vector2(1250,70), Vector2(1250,845), Vector2(75,845)]
const PERIMETER: float = 3900.0
const RAIL_SPACING: float = 28.0
const MAX_TRAIN: int = 50
const START_SPEED: float = 260.0
const HULL_MAX: float = 250.0
const BARRIER_MAX: float = 30.0
const START_TP: float = 0.0
const START_XP: float = 20.0
const START_SCRAP: float = 0.0
const TP_PER_SECOND: float = 0.0335
const XP_PER_KILL: float = 1.05
const SCRAP_PER_KILL: float = 0.109
const XP_MULTIPLIER_CAP: float = 1.28
const SCRAP_MULTIPLIER_CAP: float = 1.30
const TP_MULTIPLIER_CAP: float = 1.24
const SPAWNS_PER_SEC: float = 0.14
const ENEMY_BASE_HP: float = 12.0
const ENEMY_SPEED: float = 13.0
const TREE_BRANCHES: int = 12
const TREE_NODES: int = 121
const WAGON_VARIANTS: int = 36
const ENEMY_VARIANTS: int = 14
const VFX_DAMAGE_CAP: int = 35
const MAX_ENEMIES_PC: int = 1500
const MAX_ENEMIES_WEB: int = 600
const MAX_PROJECTILES_PC: int = 4000
const MAX_PROJECTILES_WEB: int = 1200
const MAX_DEBRIS_PC: int = 12000
const MAX_DEBRIS_WEB: int = 3000
const WEB_WARNING: String = "웹 저장은 브라우저 저장소/시크릿 모드 설정에 따라 사라질 수 있습니다."
const VERSION: String = "0.1.0-static"

static func positive_mod(value: float, modulus: float) -> float:
	if not is_finite(value) or modulus <= 0.0:
		return 0.0
	return RFloatSafety.safe_mod(value,modulus)

static func max_entities() -> int:
	return MAX_ENEMIES_WEB if OS.has_feature("web") else MAX_ENEMIES_PC

static func max_projectiles() -> int:
	return MAX_PROJECTILES_WEB if OS.has_feature("web") else MAX_PROJECTILES_PC
