//
// Press Tab to do transition
//


// ----------------------------------------------------------------------------: color

INK     :: Vector4.{0.055, 0.075, 0.120, 1};
CORAL   :: Vector4.{0.880, 0.180, 0.280, 1};
AMBER   :: Vector4.{0.960, 0.560, 0.140, 1};
LAGOON  :: Vector4.{0.000, 0.500, 0.620, 1};
VIOLET  :: Vector4.{0.300, 0.220, 0.680, 1};
MOSS    :: Vector4.{0.160, 0.540, 0.320, 1};
SKY     :: Vector4.{0.120, 0.420, 0.820, 1};
BLACK   :: Vector4.{0.000, 0.000, 0.000, 1};

colors := Vector4.[
    CORAL,
    AMBER,
    LAGOON,
    VIOLET,
    MOSS,
    SKY,
    INK,
];

pending_color_index := 0; // delay the bg color change until closing phase finished when we do transition
current_color_index := 0;
background_color_index := 0;

// ----------------------------------------------------------------------------: transition

Transition_Phase :: enum {
  NONE;
  CLOSING;
  HOLDING;
  OPENING;
}

transition_phase := Transition_Phase.NONE;
transition_timer: float = 0.0;
transition_duration: float = 0.50;
transition_hold_duration: float = 0.16;
transition_open_horizontal := true;

last_time : float64;
delta_time: float;

// ----------------------------------------------------------------------------: window

window_width  : s32;
window_height : s32;

the_window : Window_Type;
window_info : Saved_Window_Info;

font : *Simp.Dynamic_Font;

quit := false;
fullscreen := true;

// ----------------------------------------------------------------------------: entry

main :: () {
  init_window();
  init_fonts();

  last_time = seconds_since_init();

  while !quit {
    update_time();
    update_window_events();

    for events_this_frame {
      if it.type == {
        case .QUIT;
          quit = true;
        case .KEYBOARD;
          if it.key_pressed == 0 continue;
          if it.key_code == {
            case .ESCAPE;
              quit = true;
          }
      }
      handle_blackground_color_switch(it);
    }

    update_transition(delta_time);

    clear_background(colors[current_color_index]);
    draw_text_centered("Press TAB to switch scene.");
    draw_transition();

    Simp.swap_buffers(the_window);
    reset_temporary_storage();
  }
}

// ----------------------------------------------------------------------------: helpers

init_window :: () {
  if OS == .WINDOWS {
    Windows :: #import "Windows";
    Windows.SetProcessDPIAware();
  }

  the_window = create_window(0, 0, "ck: the window");
  toggle_fullscreen(the_window, true, *window_info);
  record := get_window_resizes();
  if record.count {
    window_width  = record[0].width;
    window_height = record[0].height;
  }
  Simp.set_render_target(the_window, .LEFT_HANDED);
  Simp.update_window(the_window);
}

update_time :: () {
  current_time := seconds_since_init();
  delta_time = cast(float) (current_time - last_time);
  last_time = current_time;
}

clear_background :: (color : Vector4) {
  Simp.clear_render_target(color.x, color.y, color.z, color.w);
}

handle_blackground_color_switch :: (e : Event) {
  if e.type == {
    case .KEYBOARD;
      if e.key_code == {
        case .TAB;
          if e.shift_pressed
            prev_background_color();
          else 
            next_background_color();

          case #char "J";
            next_background_color();

          case #char "K";
            prev_background_color();
      }
  }
}

cycle_index :: (index: int, delta: int, count: int) -> int {
  result := index + delta;

  if result < 0 return count - 1;
  if result >= count return 0;

  return result;
}

request_background_color :: (index : int) {
  if transition_phase != .NONE return;

  pending_color_index = index;
  transition_phase = .CLOSING;
  transition_timer = 0.0;
}

next_background_color :: () {
  request_background_color(cycle_index(current_color_index, 1, colors.count));
}

prev_background_color :: () {
  request_background_color(cycle_index(current_color_index, -1, colors.count));
}

update_transition :: (dt: float) {
  if transition_phase == .NONE return;
  transition_timer += dt;

  if transition_phase == .HOLDING {
    if transition_timer < transition_hold_duration return;

    transition_phase = .OPENING;
    transition_timer = 0.0;
    return;
  }

  if transition_timer < transition_duration return;

  // Hit the duration, we need to change phase.
  if transition_phase == .CLOSING {
    current_color_index = pending_color_index;
    transition_phase = .HOLDING;
    transition_timer = 0.0;
  } else if transition_phase == .OPENING {
    transition_phase = .NONE;
    transition_timer = 0.0;
  }
}

draw_transition :: () {
  if transition_phase == .NONE return;

  w, h := Simp.get_render_dimensions(the_window);
  vw, vh := cast(float) w, cast(float) h;

  p := transition_progress();
  
  Simp.set_shader_for_color(true);
  Simp.immediate_begin();

  if transition_phase == {
    case .CLOSING;
      close := ease_out(p);
      x := vw * 0.5 * close;

      // Use bottom-left and top-right x,y to draw a rectangle.
      Simp.immediate_quad(0.0, 0.0, x, vh, BLACK);     // left
      Simp.immediate_quad(vw - x, 0.0, vw, vh, BLACK); // right
    case .HOLDING;
      Simp.immediate_quad(0.0, 0.0, vw, vh, BLACK);
    case .OPENING;
      if (transition_open_horizontal) {
        open :=  1 - ease_in(p);
        x := vw * 0.5 * open;

        // Use bottom-left and top-right x,y to draw a rectangle.
        Simp.immediate_quad(0.0, 0.0, x, vh, BLACK);
        Simp.immediate_quad(vw - x, 0.0, vw, vh, BLACK);
      } else {
        cover := 1.0 - ease_in(p);
        y := vh * 0.5 * cover;

        Simp.immediate_quad(0.0, 0.0, vw, y, BLACK);
        Simp.immediate_quad(0.0, vh - y, vw, vh, BLACK);
      }
  }
  Simp.immediate_flush();
}

transition_progress :: () -> float {
  return clamp(transition_timer / transition_duration, 0.0, 1.0);
}

// ----------------------------------------------------------------------------: fonts

init_fonts :: () {
  font = Simp.get_font_at_size(".", "OpenSans-BoldItalic.ttf", 40);
  assert(font != null);
}

draw_text_centered :: (text : string, color := Vector4.{0,0,0,1}) {
  text_width := Simp.prepare_text(font, text);
  x := (window_width - text_width) / 2;
  y := window_height / 2 - font.character_height / 4;

  Simp.draw_prepared_text(font, x, y, color);
}

// ----------------------------------------------------------------------------: ease

ease_in:: (t: float) -> float {
  return ifx t == 0 then 0 else pow(2, 10*t-10); // expo
}

ease_out:: (t: float) -> float {
  return sqrt(1-pow(t-1, 2)); // circ
}

#import "Basic";
#import "Input";
using Simp :: #import "Simp";
#import "Window_Creation";
#import "Math";
