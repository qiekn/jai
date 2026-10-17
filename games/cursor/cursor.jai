#import "Basic";
#import "File_Utilities";
#import "Input";
#import "Math";
#import "Windows";
#import "Window_Creation";

Simp :: #import "Simp";
Simp_ImGui :: #import "Simp_ImGui";
Jaison :: #import "jaison";

the_window : Window_Type;
window_width := 1280;
window_height := 720;

window_should_quit := false;

WHITE :: Vector4.{1, 1, 1, 1};
CYAN :: Vector4.{0, 1, 1, 1};
CURSOR_MARKER_RADIUS :: 4.0;
CURSOR_MARKER_SEGMENTS :: 32;
HOTSPOT_CONFIG_PATH :: "assets/cursor_hotspots.json";

Cursor_Image :: struct {
  path: string;
  hotspot: Vector2;
  texture: Simp.Texture;
}

Cursor_Hotspot_Record :: struct {
  path: string;
  x: float;
  y: float;
}

Cursor_Hotspot_File :: struct {
  hotspots: [..] Cursor_Hotspot_Record;
}

cursor_images: [..] Cursor_Image;
current_cursor_index := 0;
hotspot_status: string;

main :: () {
  #if OS == .WINDOWS {
    Windows :: #import "Windows";
    Windows.SetProcessDPIAware();
  }

  the_window = create_window(window_width, window_height, "ck: cursor");
  Simp.set_render_target(the_window);

  Simp_ImGui.init();
  defer Simp_ImGui.shutdown();

  load_cursor_config();

  hide_system_cursor();
  defer show_system_cursor();

  while !window_should_quit {
    update_window_events();
    for events_this_frame {
      Simp_ImGui.process_event(it);
      if !imgui_wants_event(it) {
        handle_event(it);
      }
    }

    // Update
    Simp_ImGui.new_frame(the_window, xx window_width, xx window_height);
    draw_hotspot_panel();

    // Render
    Simp.clear_render_target(0.02, 0.15, 0.15, 1);
    draw_cursor();
    draw_cursor_position_marker();
    Simp_ImGui.render();

    Simp.swap_buffers(the_window);
    reset_temporary_storage();
  }
}

load_cursor_config :: () -> bool {
  if !file_exists(HOTSPOT_CONFIG_PATH) {
    hotspot_status = "JSON not found";
    log_error("Cursor config not found: %\n", HOTSPOT_CONFIG_PATH);
    return false;
  }

  success, config := Jaison.json_parse_file(HOTSPOT_CONFIG_PATH, Cursor_Hotspot_File);
  if !success {
    hotspot_status = "JSON load failed";
    return false;
  }

  load_cursor_textures(config);
  hotspot_status = ifx cursor_images.count > 0 then "JSON loaded" else "JSON had no loadable paths";
  return cursor_images.count > 0;
}

load_cursor_textures :: (config: Cursor_Hotspot_File) {
  current_cursor_index = 0;

  for record: config.hotspots {
    if record.path.count == 0 continue;

    image: Cursor_Image;
    image.path = record.path;
    image.hotspot = .{record.x, record.y};

    if Simp.texture_load_from_file(*image.texture, record.path) {
      array_add(*cursor_images, image);
    } else {
      log_error("Could not load %\n", record.path);
    }
  }

  if cursor_images.count == 0 {
    log_error("No cursor PNG files loaded from %.\n", HOTSPOT_CONFIG_PATH);
  }
}

load_hotspot_config :: () -> bool {
  if !file_exists(HOTSPOT_CONFIG_PATH) {
    hotspot_status = "No JSON loaded";
    return false;
  }

  success, config := Jaison.json_parse_file(HOTSPOT_CONFIG_PATH, Cursor_Hotspot_File);
  if !success {
    hotspot_status = "JSON load failed";
    return false;
  }

  loaded_count := 0;
  for record: config.hotspots {
    for 0..cursor_images.count-1 {
      if cursor_images[it].path == record.path {
        cursor_images[it].hotspot = .{record.x, record.y};
        loaded_count += 1;
        break;
      }
    }
  }

  hotspot_status = ifx loaded_count > 0 then "JSON loaded" else "JSON had no matching paths";
  return loaded_count > 0;
}

load_current_hotspot_config :: () -> bool {
  if cursor_images.count == 0 return false;

  if !file_exists(HOTSPOT_CONFIG_PATH) {
    hotspot_status = "JSON not found";
    return false;
  }

  success, config := Jaison.json_parse_file(HOTSPOT_CONFIG_PATH, Cursor_Hotspot_File);
  if !success {
    hotspot_status = "JSON load failed";
    return false;
  }

  current_path := cursor_images[current_cursor_index].path;
  for record: config.hotspots {
    if record.path == current_path {
      cursor_images[current_cursor_index].hotspot = .{record.x, record.y};
      hotspot_status = "Current reloaded";
      return true;
    }
  }

  hotspot_status = "Current path missing in JSON";
  return false;
}

save_hotspot_config :: () -> bool {
  config: Cursor_Hotspot_File;

  for cursor: cursor_images {
    array_add(*config.hotspots, .{
      path = cursor.path,
      x = cursor.hotspot.x,
      y = cursor.hotspot.y,
    });
  }

  success := Jaison.json_write_file(HOTSPOT_CONFIG_PATH, config);
  hotspot_status = ifx success then "JSON saved" else "JSON save failed";
  return success;
}

handle_event :: (event: Event) {
  if event.type == .QUIT {
    window_should_quit = true;
    return;
  }

  if event.type == .KEYBOARD && event.key_pressed && !event.repeat && event.key_code == .TAB {
    switch_cursor(ifx event.shift_pressed then -1 else 1);
    return;
  }

  if event.type == .MOUSE_WHEEL {
    if event.wheel_delta > 0 {
      switch_cursor(-1);
    } else if event.wheel_delta < 0 {
      switch_cursor(1);
    }
  }
}

imgui_wants_event :: (event: Event) -> bool {
  io := Simp_ImGui.GetIO();

  if event.type == .KEYBOARD || event.type == .TEXT_INPUT {
    return io.WantCaptureKeyboard;
  }

  if event.type == .MOUSE_WHEEL {
    return io.WantCaptureMouse;
  }

  return false;
}

switch_cursor :: (delta: int) {
  if cursor_images.count == 0 return;

  current_cursor_index += delta;
  while current_cursor_index < 0 {
    current_cursor_index += cursor_images.count;
  }
  while current_cursor_index >= cursor_images.count {
    current_cursor_index -= cursor_images.count;
  }
}

draw_hotspot_panel :: () {
  ui_scale := Simp_ImGui.get_ui_scale();
  Simp_ImGui.SetNextWindowPos(.{20 * ui_scale, 20 * ui_scale}, Simp_ImGui.Cond.FirstUseEver, .{0, 0});
  Simp_ImGui.SetNextWindowSize(.{470 * ui_scale, 330 * ui_scale}, Simp_ImGui.Cond.FirstUseEver);

  if Simp_ImGui.Begin("Cursor Hotspot") {
    if cursor_images.count == 0 {
      Simp_ImGui.Text("No cursor textures loaded.");
    } else {
      cursor := *cursor_images[current_cursor_index];

      Simp_ImGui.Text("Cursor % / %", current_cursor_index + 1, cursor_images.count);
      Simp_ImGui.Text("Path: %", cursor.path);
      Simp_ImGui.Text("Texture: % x %", cursor.texture.width, cursor.texture.height);

      if Simp_ImGui.Button("Previous") {
        switch_cursor(-1);
      }
      Simp_ImGui.SameLine();
      if Simp_ImGui.Button("Next") {
        switch_cursor(1);
      }

      Simp_ImGui.Separator();

      Simp_ImGui.SetNextItemWidth(280 * ui_scale);
      if Simp_ImGui.DragFloat2("Hotspot", *cursor.hotspot.component, 0.25, -128.0, 256.0, "%.2f") {
        hotspot_status = "Edited";
      }

      mouse_pos, mouse_success := get_mouse_position();
      if mouse_success {
        Simp_ImGui.Text("Mouse: %.1f, %.1f", mouse_pos.x, mouse_pos.y);
      }

      if Simp_ImGui.Button("Reload Current") {
        load_current_hotspot_config();
      }
      Simp_ImGui.SameLine();
      if Simp_ImGui.Button("Reload All") {
        load_hotspot_config();
      }

      if Simp_ImGui.Button("Save JSON") {
        save_hotspot_config();
      }

      if hotspot_status.count {
        Simp_ImGui.Text("Status: %", hotspot_status);
      }
    }
  }

  Simp_ImGui.End();
}

draw_cursor :: () {
  if cursor_images.count == 0 return;

  mouse_pos, success := get_mouse_position();
  if !success return;

  cursor := cursor_images[current_cursor_index];
  x0 := mouse_pos.x - cursor.hotspot.x;
  y1 := mouse_pos.y + cursor.hotspot.y;
  x1 := x0 + xx cursor.texture.width;
  y0 := y1 - xx cursor.texture.height;

  Simp.set_shader_for_images(*cursor.texture);
  Simp.immediate_quad(x0, y0, x1, y1, WHITE);
}

draw_cursor_position_marker :: () {
  mouse_pos, success := get_mouse_position();
  if !success return;

  immediate_circle(mouse_pos, CURSOR_MARKER_RADIUS, CYAN);
}

get_mouse_position :: () -> pos: Vector2, success: bool {
  mouse_x, mouse_y, success := get_mouse_pointer_position(the_window, true);
  if !success return .{}, false;

  return .{xx mouse_x, xx mouse_y}, true;
}

immediate_circle :: (center: Vector2, radius: float, color: Vector4) {
  Simp.set_shader_for_color(true);

  step_angle :: 2 * PI / CURSOR_MARKER_SEGMENTS;
  for 0..CURSOR_MARKER_SEGMENTS-1 {
    alpha := step_angle * it;
    beta := step_angle * (it + 1);
    p0 := center;
    p1 := center + Vector2.{cos(alpha), sin(alpha)} * radius;
    p2 := center + Vector2.{cos(beta), sin(beta)} * radius;
    Simp.immediate_triangle(make_vector3(p0, 0), make_vector3(p1, 0), make_vector3(p2, 0), color, color, color);
  }
}

hide_system_cursor :: () {
  set_custom_cursor_handling(true);
  while ShowCursor(0) >= 0 {
  }
}

show_system_cursor :: () {
  set_custom_cursor_handling(false);
  while ShowCursor(1) < 0 {
  }
}
