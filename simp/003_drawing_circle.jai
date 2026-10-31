// ----------------------------------------------------------------------------: yours

RED     :: Vector4.{1, 0, 0, 1};
GREEN   :: Vector4.{0, 1, 0, 1};
BLUE    :: Vector4.{0, 0, 1, 1};
MAGENTA :: Vector4.{1, 0, 1, 1};

v2 :: Vector2;

immediate_circle :: (cx: float, cy: float, radius: float, color : Vector4, segment := 64) {
    step_angle := 2 * PI / segment;

    cos_theta := cos(step_angle);
    sin_theta := sin(step_angle);
    rotate_matrix := Matrix2.{
        cos_theta, -sin_theta,
        sin_theta,  cos_theta,
    };

    p0 := v2.{cx, cy};          // origin
    p1 := v2.{cx + radius, cy}; // previous point
    p2 : v2;                    // next     point

    for 0..segment {
        p2 = p0 + rotate_matrix * (p1 - p0);
        Simp.immediate_triangle(p0, p1, p2, color);
        p1 = p2;
    }
}

// ----------------------------------------------------------------------------: interface

init :: () {}

simulate :: () {}

render :: () {
    Simp.clear_render_target(0.16, 0.17, 0.20, 1);
    Simp.set_shader_for_color();

    x, y := window_width / 2.0, window_height / 2.0;
    radius := min(window_width, window_height) / 3.0;
    immediate_circle(x, y, radius, RED, segment=256);

    mouse_x, mouse_y := get_mouse_pointer_position(the_window, right_handed=true);
    immediate_circle(mouse_x.(float), mouse_y.(float), 100, GREEN, segment=64);
}


// ----------------------------------------------------------------------------: framework

the_window    : Window_Type;
window_width  := 1280;
window_height := 720;
window_title :: "Circle";
WANTED_MSAA :: 8;

main :: () {
    // Initializatiion
    init_window();
    init ();

    quit := false;
    while !quit {
        // Handle Input
        Input.update_window_events();
        for Input.events_this_frame {
            if !it.key_pressed continue;
            if it.type == .KEYBOARD {
                key_code := it.key_code;
                if key_code == {
                    case .ESCAPE; quit = true;
                }
            }
        }

        simulate();
        render();

        Simp.swap_buffers(the_window);
        reset_temporary_storage();
    }
}

init_window :: () {
    #if OS == .WINDOWS {
        Windows :: #import "Windows";
        // Windows.SetProcessDPIAware(); // auto hidpi scale
        Windows.timeBeginPeriod(1);
    }

    // On Linux, we need to pass the MSAA value to create_window
    the_window = create_window(window_width, window_height, window_title, wanted_msaa = WANTED_MSAA);

    // On other operating systems, the MSAA value needs to be passed to *_create_context,
    // so we need to have an extra step here if you want MSAA.
    msaa := Simp.prepare_window(the_window, wanted_msaa = WANTED_MSAA);
    log("Wanted MSAA: %\nChosen MSAA: %\n", WANTED_MSAA, msaa);

    // Actual render size in pixels can be different from the window dimensions we specified above (for example on high-resolution displays on macOS/iOS).
    window_width, window_height = Simp.get_render_dimensions(the_window);
}

// ----------------------------------------------------------------------------: imports

#import "Basic";
#import "Math";
#import "Window_Creation";

Input :: #import "Input";
Simp  :: #import "Simp+";
