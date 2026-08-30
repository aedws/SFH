class_name EmbeddedCsvPayload
extends Resource

@export_file("*.csv") var source_path: String = ""
@export_multiline var csv_text: String = ""


func is_valid_for(path: String) -> bool:
	return not path.is_empty() and source_path == path and not csv_text.is_empty()


func get_csv_text() -> String:
	return csv_text
