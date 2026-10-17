#import "Basic";
#import "Input";

#load "scene_title.jai";
#load "scene_game.jai";

//
// This is the scene manger
//

SceneType :: enum u8 {
  Title;
  Game;
}

current_scene := SceneType.Title;

#scope_file

Scene :: struct {
  init, enter, exit, update, render : ();
}

// Indexed by SceneType, so the order must match the enum.
scenes := Scene.[
  .{title_scene_init, title_scene_enter, title_scene_exit, title_scene_update, title_scene_render},
  .{game_scene_init,  game_scene_enter,  game_scene_exit,  game_scene_update,  game_scene_render},
];

set_scene :: (target : SceneType) {
  if current_scene == target return;

  scenes[current_scene].exit();
  current_scene = target;
  scenes[current_scene].enter();
}

#scope_module

scene_manager_init :: () {
  print("scene manager: init\n");
  for scenes it.init();
  scenes[current_scene].enter();
}

scene_manager_update :: () {
  for events_this_frame {
    if it.type == .KEYBOARD && it.key_code == .TAB && it.key_pressed {
      set_scene(ifx current_scene == .Title then .Game else .Title);
    }
  }

  scenes[current_scene].update();
}

scene_manager_render :: () {
  scenes[current_scene].render();
}
