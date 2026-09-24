#import "Basic";
#import "Input";
#import "Math";
Simp :: #import "Simp";
#import "Window_Creation";

ndc :: #import "NDC";

RED     :: Vector4.{1, 0, 0, 1};
GREEN   :: Vector4.{0, 1, 0, 1};
BLUE    :: Vector4.{0, 0, 1, 1};
MAGENTA :: Vector4.{1, 0, 1, 1};

SEGMENT :: 128; // number of triangles used to draw circle

window_width  := 800;   
window_height := 600;

immediate_circle :: (center: Vector2, radius: float, color : Vector4) {
    STEP_ANGLE :: 2*PI/SEGMENT;
    for 0..SEGMENT-1 {
        alpha, beta := STEP_ANGLE*it, STEP_ANGLE*(it+1);
        p0 := center;
        p1 := center + Vector2.{cos(alpha), sin(alpha)}*radius;
        p2 := center + Vector2.{cos(beta), sin(beta)}*radius;
        Simp.immediate_triangle(make_vector3(p0, 0), make_vector3(p1, 0), make_vector3(p2, 0), color, color, color);
    }
}

main :: () {
    center := Vector2.{window_width / 2.0, window_height / 2.0};

    the_window := create_window(window_width, window_height, "ck: Triangle");   
    Simp.set_render_target(the_window);
    Simp.set_shader_for_color(true);

    quit := false;
    while !quit {                          
        Simp.clear_render_target(0.02, 0.15, 0.15, 1);
        update_window_events();
        ndc.update_width_height(xx window_width, xx window_height);

        for events_this_frame {
            if it.type == .QUIT then quit = true;
        }

        immediate_circle(ndc.to_screen_vector2(0,0), 200, BLUE);  

        x, y, success := get_mouse_pointer_position();
        immediate_circle(.{xx x.(float), xx (window_height - y)}, 15, MAGENTA);

        Simp.swap_buffers(the_window);
        sleep_milliseconds(10);
        reset_temporary_storage();   
    }
}
