#import "Basic";
#import "Window_Creation";

Simp  :: #import "Simp+";
Input :: #import "Input";

the_window    := Window_Type;
window_width  := 1280;
window_height := 720;

main :: () {
    the_window := create_window(window_width, window_height, "The Window");

    // Tell Simp which window it should render into.
    // Without this, Simp does not know where to draw the frame.
    Simp.set_render_target(the_window);

    quit := false;
    while !quit {
        // Ask the operating system for new window/input events.
        nputupdate_window_events();

        // Then prcess all events that happeded during this frame.
        for events_this_frame {
            // If the user closes the window, mark the program to exit.
            if it.type == .QUIT {
                quit = true;
            }

            // If the user press Esc, mark the program to exit.
            if it.type == .KEYBOARD {
                if it.key_code == .ESCAPE && it.key_pressed {
                    quit = true;
                }
            }
        }
    }
}
