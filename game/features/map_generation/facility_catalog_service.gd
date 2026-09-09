class_name FacilityCatalogService
extends "res://game/features/balance_data/validated_csv_catalog_service.gd"
## Typed catalog adapter; HTTP lifecycle is shared, gameplay consumes detached rows.
func _init() -> void:
	catalog_name="Facility"
	live_csv_url="https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/gviz/tq?tqx=out:csv&sheet=Facility&headers=1"
	catalog=create_catalog()

func create_catalog() -> RefCounted:
	return preload("res://game/features/map_generation/facility_catalog.gd").new()
