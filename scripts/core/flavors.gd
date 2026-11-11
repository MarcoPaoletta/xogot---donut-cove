class_name Flavors
extends RefCounted
## The donut flavors: sale price and the colour used by numbers and icons.

const PRICES: Dictionary = {
	&"strawberry": 6,
	&"chocolate": 8,
	&"honey": 10,
}

const COLORS: Dictionary = {
	&"strawberry": Color(1.0, 0.55, 0.75),
	&"chocolate": Color(0.55, 0.33, 0.2),
	&"honey": Color(1.0, 0.8, 0.25),
}


static func price(kind: StringName) -> int:
	return int(PRICES.get(kind, 5))


static func color(kind: StringName) -> Color:
	return COLORS.get(kind, Color.WHITE) as Color
