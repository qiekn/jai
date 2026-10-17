#import "Basic";
#import "Input";
Simp :: #import "Simp";
#import "Window_Creation";
#import "Math";


NAYSAYER :: Vector4.{0.02, 0.15, 0.15, 1};

the_window : Window_Type;

window_width := 1280;
window_height := 720;
saved_window_info : Saved_Window_Info;

window_shold_quit := false;
window_should_borderless_fullscreen := true;

main :: () {
  init_window();

  while !window_shold_quit {
    clear_background(NAYSAYER);

    update_window_events();

    for events_this_frame {
      if it.type == {
        case .QUIT;
          window_shold_quit = true;
        case .KEYBOARD;
          if it.key_pressed == 0 continue;
          if it.key_code == {
            case .ESCAPE;
              window_shold_quit = true;
            case .F11;
              toggle_borderless_fullscreen();
          }
      }
    }

    sleep_milliseconds(10);

    Simp.swap_buffers(the_window);
    reset_temporary_storage();
  }
}

init_window :: () {
  the_window = create_window(window_width, window_height, "ck: the window");
  Simp.set_render_target(the_window);

  toggle_borderless_fullscreen(true);
}

toggle_borderless_fullscreen :: (force_fullscreen : bool = false) {
  if force_fullscreen window_should_borderless_fullscreen = true;
  else window_should_borderless_fullscreen = !window_should_borderless_fullscreen;

  success := toggle_fullscreen(the_window, window_should_borderless_fullscreen, *saved_window_info);

  if success {
    Simp.update_window(the_window);
    window_width, window_height = Simp.get_render_dimensions(the_window);
  } else {
    window_should_borderless_fullscreen = !window_should_borderless_fullscreen;
  }
}

clear_background :: (color : Vector4) {
  Simp.clear_render_target(color.x, color.y, color.z, color.w);
}
