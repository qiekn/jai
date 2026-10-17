#import "Basic";

#import "Input";
#import "Math";
#import "Window_Creation";

Simp :: #import "Simp";
ImGui :: #import "Simp_ImGui";

#if OS == .WINDOWS {
  Windows :: #import "Windows";
}

// ----------------------------------------------------------------------------: globals

the_window : Window_Type;
window_width : s32 = 1280;
window_height : s32 = 720;
saved_window_info : Saved_Window_Info;

quit := false;

background_color := Vector4.{0.02, 0.15, 0.15, 1};

// ----------------------------------------------------------------------------: main

main :: () {
  init();
  while !quit {
    update();
    render();

    Simp.swap_buffers(the_window);
    reset_temporary_storage();
  }
  shutdown();
}

init :: () {
  if OS == .WINDOWS {
    Windows.SetProcessDPIAware();
  }
  init_window();
  ImGui.init();

}

update :: () {
  update_window_events();
  handle_input();
}

render :: () {
  render_one_frame();
  render_imgui();
}

shutdown :: () {
  ImGui.shutdown();
}

// ----------------------------------------------------------------------------: helpers

init_window :: () {
  the_window = create_window(window_width, window_height, "ck: minesweeper");
  Simp.set_render_target(the_window);
  toggle_fullscreen(the_window, true, *saved_window_info);
  Simp.update_window(the_window);
  window_width, window_height = Simp.get_render_dimensions(the_window);
}

handle_input :: () {
  for events_this_frame {
    ImGui.process_event(it);
    if it.type == {
      case .QUIT; quit = true;
      case .KEYBOARD;
        if !it.key_pressed continue;
        if it.key_code == .ESCAPE
          quit = true;
    }
  }
}

render_one_frame :: () {
  clear_background(background_color);
}

render_imgui :: () {
  ImGui.new_frame(the_window, window_width, window_height);

  ui_scale := ImGui.get_ui_scale();
  ImGui.SetNextWindowPos(.{40 * ui_scale, 20 * ui_scale}, .FirstUseEver);
  ImGui.SetNextWindowSize(.{430 * ui_scale, 300 * ui_scale}, .FirstUseEver);
  ImGui.Begin("Settings");
  ImGui.ColorEdit4("Background", *background_color.component);
  ImGui.End();

  ImGui.render();
}

clear_background :: (color : Vector4) {
  Simp.clear_render_target(color.x, color.y, color.z, color.w);
}
