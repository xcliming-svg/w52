class_name RWagonPricing
extends RefCounted

static func quote(purchased_additional_cars: int) -> float:
	return 11.0+2.3*float(maxi(0,purchased_additional_cars))

static func is_affordable(scrap: float, already_purchased: int) -> bool:
	return scrap+0.000001>=quote(already_purchased)
