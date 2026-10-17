#import "Basic";
#import "Window_Creation";
#import "Input";
#import "Math";

Simp :: #import "Simp";

#load "scene/scene_manager.jai";

// ----------------------------------------------------------------------------: globals

window_width := 1280;
window_height := 720;
the_window : Window_Type;
window_should_quit := false;

// ----------------------------------------------------------------------------: font

font_size := 80;
font : *Simp.Dynamic_Font;

draw_center_text :: (text : string, color := Vector4.{0,0,0,1}) {
  text_width := Simp.prepare_text(font, text);
  x := (window_width - text_width) / 2;
  y := window_height / 2 - font.character_height / 4;

  Simp.draw_prepared_text(font, x, y, color);
}

// ----------------------------------------------------------------------------: entry

main :: () {
  init();
  loop();
}

init :: () {
  init_window();
  init_fonts();
  scene_manager_init();
}

loop :: () {
  while !window_should_quit {
    update_one_frame();
    draw_one_frame();

    sleep_milliseconds(10);

    Simp.swap_buffers(the_window);
    reset_temporary_storage();
  }
}

// ----------------------------------------------------------------------------: procedures

init_window :: () {
  the_window = create_window(window_width, window_height, "ck: scene demo");
  Simp.set_render_target(the_window);
}

init_fonts :: () {
  font = Simp.get_font_at_size("data", "OpenSans-BoldItalic.ttf", font_size);
  assert(font != null);
}

update_one_frame :: () {
    update_window_events();
    for events_this_frame {
      if it.type == .QUIT then window_should_quit = true;
    }
    scene_manager_update();
}

draw_one_frame :: () {
  scene_manager_render();
}
