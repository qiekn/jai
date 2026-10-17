game_scene_init :: () { }

game_scene_enter :: () { }

game_scene_exit :: () { }

game_scene_update :: () { }

game_scene_render :: () {
  Simp.clear_render_target(0,1,1,1); // CYAN
  draw_center_text("Game Scene");
}
