title_scene_init :: () { }

title_scene_enter :: () { }

title_scene_exit :: () { }

title_scene_update :: () { }

title_scene_render :: () {
  Simp.clear_render_target(1,0,0,1); // RED
  draw_center_text("Title Scene");
}
