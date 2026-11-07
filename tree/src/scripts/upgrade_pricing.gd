class_name RUpgradePricing
extends RefCounted

static func quote(depth: int, total_purchased: int) -> Dictionary:
	var d: int=clampi(depth,1,10)
	return {
		"tp":1+int(floor(float(d-1)/2.0))+int(floor(float(maxi(0,total_purchased))/20.0)),
		"xp":10+7*d+3*d*d
	}

static func affordable(tp: float, xp: float, price: Dictionary) -> bool:
	return tp+0.000001>=float(price.tp) and xp+0.000001>=float(price.xp)
