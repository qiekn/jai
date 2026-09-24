#import "Basic";
#import "Input";
#import "Math";
Simp :: #import "Simp";
#import "Window_Creation";

RED   :: Vector4.{1, 0, 0, 1};
GREEN :: Vector4.{0, 1, 0, 1};
BLUE  :: Vector4.{0, 0, 1, 1};

window_width  := 800;   
window_height := 600;

main :: () {

    center := Vector2.{window_width / 2.0, window_height / 2.0};

    p0 := ndc_to_screen(Vector2.{x=-0.5, y=-0.5}); // left bottom
    p1 := ndc_to_screen(Vector2.{x= 0.5, y=-0.5}); // right bottom
    p2 := ndc_to_screen(Vector2.{x= 0.0, y= 0.5}); // top

    the_window := create_window(window_width, window_height, "ck: Triangle");   
    Simp.set_render_target(the_window);
    Simp.set_shader_for_color(true);

    quit := false;
    while !quit {                          
        update_window_events();

        for events_this_frame {
            if it.type == .QUIT then quit = true;
        }

        Simp.immediate_triangle(p0, p1, p2, BLUE, RED, GREEN);

        Simp.swap_buffers(the_window);
        sleep_milliseconds(10);
        reset_temporary_storage();   
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
ndc_to_screen :: (p: Vector2) -> Vector3 {
    return Vector3.{
        x = (p.x * 0.5 + 0.5) * xx window_width,
        y = (p.y * 0.5 + 0.5) * xx window_height,
        z = 0,
    };
}
