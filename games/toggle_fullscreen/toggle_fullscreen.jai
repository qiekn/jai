the_window : Window_Type;

window_width  := 1280;
window_height := 720;
not_fullscreen_window_info : Saved_Window_Info;

fullscreen := true;

main :: () {
  the_window = create_window(window_width, window_height, "ck: A window");
  set_render_target(the_window);

  // If you want fullscreen by default.
  if fullscreen toggle_fullscreen(the_window, true, *not_fullscreen_window_info);

  quit := false;
  while !false {
    update_window_events();

    // Update window size.
    for get_window_resizes() {
      update_window(it.window);
      if it.window == the_window {
        window_width = it.width;
        window_height = it.height;
      }
    }

    // Handle input
    for events_this_frame {
      if it.type == {
        case .QUIT; quit = true;
        case .KEYBOARD;
          if !it.key_pressed continue;
          if it.key_code == {
            case .ESCAPE; quit = true;
            case .TAB; #through;
            case .F11;
              // EXAMPLE CODE HERE
              // EXAMPLE CODE HERE
              fullscreen = !fullscreen;
              toggle_fullscreen(the_window, fullscreen, *not_fullscreen_window_info);
              // EXAMPLE CODE HERE
              // EXAMPLE CODE HERE
          }
      }
    }

    clear_render_target(0.12, 0.13, 0.14, 1);

    sleep_milliseconds(10);
    swap_buffers(the_window);
  }
}

#import "Basic";
#import "Math";
#import "Window_Creation";

#import "Input";
#import "Simp";
