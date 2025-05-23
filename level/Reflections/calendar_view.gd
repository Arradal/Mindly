extends Control

var cal: Calendar = Calendar.new()
var current_date: Calendar.Date
var selected_date: Calendar.Date

var displayed_year: int
var displayed_month: int

@onready var month_grid: GridContainer = %MonthGrid
@onready var year_label: Label = %YearLabel

func _ready() -> void:
	current_date = Calendar.Date.today()
	selected_date = current_date
	displayed_year = current_date.year
	displayed_month = current_date.month
	
	update_year_label(displayed_year, displayed_month)
	populate_month_calendar(displayed_year, displayed_month)

func update_year_label(year: int, month: int) -> void:
	var months = cal.get_months_formatted(Calendar.MonthFormat.MONTH_FORMAT_FULL)
	year_label.text = months[month - 1] + " " + str(year)

func populate_month_calendar(year: int, month: int) -> void:
	for child in month_grid.get_children():
		child.queue_free()
	
	var weekdays = cal.get_weekdays_formatted(Calendar.WeekdayFormat.WEEKDAY_FORMAT_SHORT)
	for weekday in weekdays:
		var header_label = Label.new()
		header_label.text = weekday
		header_label.horizontal_alignment = 1
		month_grid.add_child(header_label)
	
	var month_calendar = cal.get_calendar_month(year, month, true)
	for week in month_calendar:
		for date in week:
			var day_button = Button.new()
			if date.month == month:
				day_button.text = str(date.day)
				if date.is_equal(current_date):
					day_button.modulate = Color(0.7, 0.7, 1)
				var cb: Callable = Callable(self, "_on_date_pressed").bind(date, day_button)
				day_button.pressed.connect(cb)
			else:
				day_button.text = ""
				day_button.disabled = true
			month_grid.add_child(day_button)

func _on_date_pressed(date: Calendar.Date, _btn: Button) -> void:
	selected_date = date
	var date_str = "%04d-%02d-%02d" % [date.year, date.month, date.day]
	var popup_scene = preload("res://level/Reflections/ReflectionPopup.tscn")
	var popup = popup_scene.instantiate()
	popup.selected_date = date_str
	get_tree().current_scene.add_child(popup)

func _on_month_plus_pressed() -> void:
	displayed_month += 1
	if displayed_month > 12:
		displayed_month = 1
		displayed_year += 1
	update_year_label(displayed_year, displayed_month)
	populate_month_calendar(displayed_year, displayed_month)

func _on_month_minus_pressed() -> void:
	displayed_month -= 1
	if displayed_month < 1:
		displayed_month = 12
		displayed_year -= 1
	update_year_label(displayed_year, displayed_month)
	populate_month_calendar(displayed_year, displayed_month)
