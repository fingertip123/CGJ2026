extends Node2D

export(float) var docking_radius = 52.0 setget set_docking_radius
export(float) var hold_time_required = 0.2

func set_docking_radius(value):
    docking_radius = value
    update()

func get_anchor_data():
    return {
        "position": global_position,
        "docking_radius": docking_radius,
        "hold_time_required": hold_time_required
    }

func is_docked(ship_position):
    return ship_position.distance_to(global_position) <= docking_radius

func _draw():
    draw_circle(Vector2.ZERO, docking_radius, Color(0.1, 0.95, 0.65, 0.16))
    draw_arc(Vector2.ZERO, docking_radius, 0.0, PI * 2.0, 80, Color(0.25, 1.0, 0.75, 0.85), 3.0)
    draw_line(Vector2(-14, 0), Vector2(14, 0), Color(0.8, 1.0, 0.9), 2.0)
    draw_line(Vector2(0, -14), Vector2(0, 14), Color(0.8, 1.0, 0.9), 2.0)
