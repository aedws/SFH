class_name CreditLedger
extends Node

signal credits_changed(carried: int, secured: int)

var carried_credits: int = 0
var secured_credits: int = 0


func add_carried(amount: int) -> void:
	if amount <= 0:
		return
	carried_credits += amount
	credits_changed.emit(carried_credits, secured_credits)


func secure_carried() -> int:
	var recovered := carried_credits
	secured_credits += recovered
	carried_credits = 0
	credits_changed.emit(carried_credits, secured_credits)
	return recovered


func lose_carried() -> int:
	var lost := carried_credits
	carried_credits = 0
	credits_changed.emit(carried_credits, secured_credits)
	return lost
