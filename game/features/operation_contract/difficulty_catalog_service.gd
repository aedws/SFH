class_name DifficultyCatalogService
extends "res://game/features/balance_data/validated_csv_catalog_service.gd"
## Typed catalog adapter; HTTP lifecycle is shared, gameplay consumes detached rows.
func _init() -> void:
	catalog_name="Difficulty"
	live_csv_url="https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/gviz/tq?tqx=out:csv&sheet=Difficulty&headers=1"
	catalog=create_catalog()

func create_catalog() -> RefCounted:
	return preload("res://game/features/operation_contract/difficulty_catalog.gd").new()
