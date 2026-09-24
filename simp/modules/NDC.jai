#import "Math";

window_width : float;
window_height : float;

update_width_height :: (w : float, h : float) {
    window_width, window_height = w, h;
}

// Convert from normalized device coordinates to Simp screen coordinates.
// NDC uses the center of the window as the origin:
//   (-1, -1) is the bottom-left corner.
//   ( 0,  0) is the center of the window.
//   ( 1,  1) is the top-right corner.
//
// Simp screen coordinates use the bottom-left corner as the origin:
//   (0, 0) is the bottom-left corner.
//   x goes right, y goes up.
to_screen_vector3 :: (p: Vector2) -> Vector3 {
    return Vector3.{
        x = (p.x * 0.5 + 0.5) * xx window_width,
        y = (p.y * 0.5 + 0.5) * xx window_height,
        z = 0,
    };
}

to_screen_vector3 :: (x: float, y: float) -> Vector3 {
    return to_screen_vector3(Vector2.{x, y});
}

to_screen_vector2 :: (p: Vector2) -> Vector2 {
    return Vector2.{
        x = (p.x * 0.5 + 0.5) * xx window_width,
        y = (p.y * 0.5 + 0.5) * xx window_height,
    };
}

to_screen_vector2 :: (x: float, y: float) -> Vector2 {
    return to_screen_vector2(Vector2.{x, y});
}
