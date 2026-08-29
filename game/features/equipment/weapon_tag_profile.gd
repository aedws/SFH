class_name WeaponTagProfile
extends Resource

## 무기 분류를 코드 enum이 아닌 데이터로 정의해 새 분류를 추가할 수 있게 합니다.

@export var major_tag: StringName
@export var middle_tag: StringName
@export var minor_tag: StringName
@export var major_label: String
@export var middle_label: String
@export var minor_label: String


func is_complete() -> bool:
	return major_tag != &"" and middle_tag != &"" and minor_tag != &""


func matches(other: WeaponTagProfile) -> bool:
	return (
		other != null
		and is_complete()
		and other.is_complete()
		and major_tag == other.major_tag
		and middle_tag == other.middle_tag
		and minor_tag == other.minor_tag
	)


func display_text() -> String:
	return "%s > %s > %s" % [
		major_label if not major_label.is_empty() else String(major_tag),
		middle_label if not middle_label.is_empty() else String(middle_tag),
		minor_label if not minor_label.is_empty() else String(minor_tag),
	]
