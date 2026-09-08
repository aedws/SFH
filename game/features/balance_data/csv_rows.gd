class_name BalanceCsvRows
extends RefCounted
## RFC-style quoted cells, escaped quotes and embedded newlines. No feature dependencies.
static func parse(text: String) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var row := PackedStringArray()
	var cell := ""
	var quoted := false
	var index := 0
	text = text.trim_prefix("\ufeff").replace("\r\n", "\n")
	while index < text.length():
		var c := text[index]
		if c == '"':
			if quoted and index + 1 < text.length() and text[index + 1] == '"':
				cell += '"'
				index += 1
			else:
				quoted = not quoted
		elif c == "," and not quoted:
			row.append(cell)
			cell = ""
		elif c == "\n" and not quoted:
			row.append(cell)
			rows.append(row)
			row = PackedStringArray()
			cell = ""
		else:
			cell += c
		index += 1
	if quoted: return []
	if not row.is_empty() or not cell.is_empty():
		row.append(cell)
		rows.append(row)
	return rows
