#import "Basic";
#import "Input";
Simp :: #import "Simp";
#import "Window_Creation";

main :: () {
    window_width := 1280;
    window_height := 720;

    the_window := create_window(window_width, window_height, "ck: the window");

    // Tell Simp which window it should render into.
    // Without this, Simp does not know where to draw the frame.
    Simp.set_render_target(the_window);

    quit := false;

    while !quit {
        // Ask the operating system for new window/input events.
        update_window_events();

        for get_window_resizes() {
            if it.window == the_window {
                window_width  = it.width;
                window_height = it.height;
                Simp.update_window(the_window);
            }
        }

        // Then prcess all events that happeded during this frame.
        for events_this_frame {
            // If the user closes the window, mark the program to exit.
            // Otherwise, you close the window but this program is still running in terminal.
            if it.type == .QUIT then quit = true;

            // If the user presses Escape, mark the program to exit.
            if it.type == .KEYBOARD && it.key_pressed {
                if it.key_code == .ESCAPE {
                    quit = true;
                }
            }
        }

        Simp.clear_render_target(.02, .15, .15, 1); // naysayer green color

        // Avoid running the loop at full CPU speed.
        sleep_milliseconds(10);

        // Show the frame we jsut finished drawing.
        Simp.swap_buffers(the_window);

        // Clear temporary memory used during this frame.
        // For details, see how_to/ temporary_memory.
        reset_temporary_storage();
    }
}
