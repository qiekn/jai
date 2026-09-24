#import "Basic";
#import "Input";
#import "Window_Creation";
Simp :: #import "Simp";
#import "Math";

CYAN :: Vector4.{0,1,1,1};

WINDOW_WIDHT :: 800;
WINDOW_HEIGHT :: 600;
WIDNOW_NAME :: "ck: window";

main :: () {
   the_window := create_window(WINDOW_WIDHT, WINDOW_HEIGHT, WIDNOW_NAME);
   Simp.set_render_target(the_window);

   quit := false;
   while !quit {
      Simp.clear_render_target(0.02, 0.15, 0.15, 1);

      update_window_events();
      for events_this_frame {
         if it.type == .QUIT quit = true;
      }

      draw_one_frame();

      sleep_milliseconds(10);
      Simp.swap_buffers(the_window);
   }
}

draw_one_frame :: () {
   Simp.set_shader_for_color();
   base := Vector2.{100.0, 100.0};
   offset := 100.0;

   for 0..3 {
      x := base.x + offset * it;
      y := base.y + offset * it;
      Simp.immediate_quad(x, y, x+offset, y+offset, CYAN);
   }
}
