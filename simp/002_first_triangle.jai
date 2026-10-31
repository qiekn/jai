#import "Basic";
#import "Math";
#import "Window_Creation";

Input :: #import "Input";
Simp  :: #import "Simp+";

RED   :: Vector4.{1, 0, 0, 1};
GREEN :: Vector4.{0, 1, 0, 1};
BLUE  :: Vector4.{0, 0, 1, 1};

the_window : Window_Type;
window_width  := 1280;
window_height := 720;

main :: () {
    p0 := ndc_to_screen(.{-0.5, -0.5}); // left bottom
    p1 := ndc_to_screen(.{ 0.5, -0.5}); // right bottom
    p2 := ndc_to_screen(.{ 0.0,  0.5}); // top

    the_window = create_window(window_width, window_height, "Triangle");
    Simp.prepare_window(the_window, 8); // MSAA
    Simp.set_render_target(the_window);

    quit := false;
    while !quit {
        // Handle inputs
        Input.update_window_events();
        for Input.events_this_frame {
            if !it.key_pressed continue;
            if it.key_code == {
                case .ESCAPE; quit = true;
            }
        }

        // Draw one frame
        Simp.set_shader_for_color(true);
        Simp.clear_render_target(0.16, 0.17, 0.20, 1);
        Simp.immediate_triangle(p0, p1, p2, BLUE, RED, GREEN);
        Simp.immediate_flush();

        Simp.swap_buffers(the_window);
    }
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
ndc_to_screen :: (using p: Vector2) -> Vector3 {
    return Vector3.{
        // Convert [-1, 1] to [0, 1]
        (x * 0.5 + 0.5) * window_width,
        (y * 0.5 + 0.5) * window_height,
        0,
    };
}
