class_name BigNumber
extends RefCounted

## BigNumber - Handles extremely large numbers for idle/clicker games
##
## Uses mantissa + exponent system (scientific notation) to handle
## numbers up to 10^9999 and beyond.

const MAX_MANTISSA: float = 10.0
const MIN_MANTISSA: float = 1.0
const SUFFIXES: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

var mantissa: float = 0.0
var exponent: int = 0

static var Zero: BigNumber:
	get: return BigNumber.new(0)

static var One: BigNumber:
	get: return BigNumber.new(1)


static func zero() -> BigNumber:
	return BigNumber.new(0)


static func one() -> BigNumber:
	return BigNumber.new(1)

var is_zero: bool:
	get: return mantissa == 0


func _init(value: Variant = 0, exp: int = 0) -> void:
	if value is BigNumber:
		mantissa = value.mantissa
		exponent = value.exponent
	elif value is float or value is int:
		if exp != 0:
			# Direct mantissa + exponent initialization
			mantissa = value
			exponent = exp
			_normalize()
		else:
			_from_double(float(value))
	else:
		mantissa = 0
		exponent = 0


func _from_double(value: float) -> void:
	if value == 0:
		mantissa = 0
		exponent = 0
		return

	var abs_value := absf(value)
	var sign_val := 1 if value >= 0 else -1

	exponent = int(floor(log(abs_value) / log(10)))
	mantissa = sign_val * abs_value / pow(10, exponent)
	_normalize()


func _normalize() -> void:
	if mantissa == 0:
		exponent = 0
		return

	var abs_mantissa := absf(mantissa)

	while abs_mantissa >= MAX_MANTISSA:
		mantissa /= 10
		abs_mantissa /= 10
		exponent += 1

	while abs_mantissa < MIN_MANTISSA and abs_mantissa > 0:
		mantissa *= 10
		abs_mantissa *= 10
		exponent -= 1


func copy() -> BigNumber:
	return BigNumber.new(mantissa, exponent)


# Arithmetic Operations

func add(other: BigNumber) -> BigNumber:
	if other.is_zero:
		return copy()
	if is_zero:
		return other.copy()

	var exp_diff := exponent - other.exponent

	if exp_diff > 15:
		return copy()
	if exp_diff < -15:
		return other.copy()

	var result_mantissa: float
	var result_exponent: int

	if exp_diff >= 0:
		result_exponent = exponent
		result_mantissa = mantissa + other.mantissa / pow(10, exp_diff)
	else:
		result_exponent = other.exponent
		result_mantissa = other.mantissa + mantissa / pow(10, -exp_diff)

	return BigNumber.new(result_mantissa, result_exponent)


func subtract(other: BigNumber) -> BigNumber:
	if other.is_zero:
		return copy()
	if is_zero:
		return BigNumber.Zero

	var exp_diff := exponent - other.exponent

	if exp_diff > 15:
		return copy()
	if exp_diff < -15:
		return BigNumber.Zero

	var result_mantissa: float
	var result_exponent: int

	if exp_diff >= 0:
		result_exponent = exponent
		result_mantissa = mantissa - other.mantissa / pow(10, exp_diff)
	else:
		result_exponent = other.exponent
		result_mantissa = mantissa / pow(10, -exp_diff) - other.mantissa

	if result_mantissa < 0:
		return BigNumber.Zero

	return BigNumber.new(result_mantissa, result_exponent)


func multiply(other: Variant) -> BigNumber:
	var other_bn: BigNumber
	if other is BigNumber:
		other_bn = other
	else:
		other_bn = BigNumber.new(other)

	if is_zero or other_bn.is_zero:
		return BigNumber.Zero

	var new_mantissa := mantissa * other_bn.mantissa
	var new_exponent := exponent + other_bn.exponent

	return BigNumber.new(new_mantissa, new_exponent)


func divide(other: BigNumber) -> BigNumber:
	if other.is_zero:
		push_error("BigNumber: Attempted to divide by zero!")
		return BigNumber.Zero

	if is_zero:
		return BigNumber.Zero

	var new_mantissa := mantissa / other.mantissa
	var new_exponent := exponent - other.exponent

	return BigNumber.new(new_mantissa, new_exponent)


func power(p: float) -> BigNumber:
	if is_zero:
		return BigNumber.Zero
	if p == 0:
		return BigNumber.One
	if p == 1:
		return copy()

	var new_mantissa := pow(mantissa, p)
	var new_exponent_float := exponent * p

	var int_exponent := int(floor(new_exponent_float))
	var frac_exponent := new_exponent_float - int_exponent
	new_mantissa *= pow(10, frac_exponent)

	return BigNumber.new(new_mantissa, int_exponent)


func sqrt_() -> BigNumber:
	return power(0.5)


# Comparison Operations

func compare_to(other: BigNumber) -> int:
	if other == null:
		return 1

	if exponent != other.exponent:
		return 1 if exponent > other.exponent else -1

	if mantissa > other.mantissa:
		return 1
	elif mantissa < other.mantissa:
		return -1
	return 0


func greater_than_or_equal(other: BigNumber) -> bool:
	return compare_to(other) >= 0


func greater_than(other: BigNumber) -> bool:
	return compare_to(other) > 0


func less_than(other: BigNumber) -> bool:
	return compare_to(other) < 0


func less_than_or_equal(other: BigNumber) -> bool:
	return compare_to(other) <= 0


# Formatting

func to_formatted_string() -> String:
	if is_zero:
		return "0"

	if exponent < 3:
		var actual_value := mantissa * pow(10, exponent)
		if actual_value == floor(actual_value):
			return str(int(actual_value))
		return "%.2f" % actual_value

	var suffix_index := exponent / 3

	if suffix_index < SUFFIXES.size():
		var suffix_exponent := suffix_index * 3
		var remaining_exp := exponent - suffix_exponent
		var display_value := mantissa * pow(10, remaining_exp)
		return "%.2f%s" % [display_value, SUFFIXES[suffix_index]]

	return "%.2fe%d" % [mantissa, exponent]


func to_scientific_string() -> String:
	if is_zero:
		return "0"
	return "%.2f × 10^%d" % [mantissa, exponent]


func to_double() -> float:
	if is_zero:
		return 0.0
	if exponent > 308:
		return INF
	if exponent < -308:
		return 0.0
	return mantissa * pow(10, exponent)


func _to_string() -> String:
	return to_formatted_string()
