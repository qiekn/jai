// -----------------------------------------------------------------------------: globals

the_window : Window_Type;
window_width  : int = 1280;
window_height : int = 720;
saved_window_info : Saved_Window_Info;

quit := false;

background_color := Vector4.{0.16, 0.17, 0.20, 1};

// -----------------------------------------------------------------------------: visual config

CELL_INNER_SIZE : int : 15;
CELL_BORDER_SIZE: int : 1;
CELL_SIZE       : int : CELL_INNER_SIZE + CELL_BORDER_SIZE;
NUMBER_SIZE     : int : CELL_SIZE;

PANEL_PADDING   : int : 10;
BOARD_Y         : int : 52;
COUNTER_WIDTH   : int : 39;
COUNTER_HEIGHT  : int : 20;
COUNTER_Y       : int : 16;
FACE_SIZE       : int : 24;
FACE_Y          : int : 14;

Theme :: struct {
  panel       := Vector4.{0.75, 0.75, 0.75, 1};
  highlight   := Vector4.{1.00, 1.00, 1.00, 1};
  shadow      := Vector4.{0.50, 0.50, 0.50, 1};
  dark_shadow := Vector4.{0.25, 0.25, 0.25, 1};
  cell_border := Vector4.{0.45, 0.45, 0.45, 1};
  black       := Vector4.{0.00, 0.00, 0.00, 1};
  counter_red := Vector4.{1.00, 0.05, 0.02, 1};
  counter_dim := Vector4.{0.18, 0.00, 0.00, 1};
}

theme: Theme;

// -----------------------------------------------------------------------------: game config/state

MIN_GRID_SIZE: int : 5;
MAX_GRID_SIZE: int : 60;

grid_width: int = 16;
grid_height: int = 16;
mine_count: int = 40;

Cell_Mark :: enum u8 {
  NONE;
  FLAG;
  QUESTION;
}

Cell :: struct {
  mine := false;
  revealed := false;
  exploded := false;
  mark: Cell_Mark;
  adjacent: int;
}

cells: [..] Cell;
mines_placed := false;
Game_State :: enum { PLAYING; LOST; WON; }
state: Game_State = .PLAYING;
revealed_count: int;
flag_count: int;
game_start_time: float64;
game_stop_time: float64;

panel_width  : int;
panel_height : int;
board_x      : int;
board_y      : int;
game_origin_x: int;
game_origin_y: int;
game_scale   : int = 1;


// -----------------------------------------------------------------------------: main

main :: () {
  if OS == .WINDOWS {
    Windows.SetProcessDPIAware();
  }

  random_seed(cast(u64) (seconds_since_init() * 1000000.0));

  init_window();
  load_assets();
  reset_game();

  while !quit {
    update();
    draw_one_frame();

    Simp.swap_buffers(the_window);
    reset_temporary_storage();
  }
}

update :: () {
  update_window_events();
  handle_window_resizes();
  update_layout();
  handle_input();
}

// -----------------------------------------------------------------------------: window/input

init_window :: () {
  WANTED_MSAA :: 1;

  the_window = create_window(window_width, window_height, "ck: minesweeper", wanted_msaa = WANTED_MSAA);
  Simp.prepare_window(the_window, wanted_msaa = WANTED_MSAA);
  Simp.set_render_target(the_window, .LEFT_HANDED);

  toggle_fullscreen(the_window, true, *saved_window_info);
  Simp.update_window(the_window);
  window_width, window_height = Simp.get_render_dimensions(the_window);
}

handle_window_resizes :: () {
  for get_window_resizes() {
    Simp.update_window(it.window);

    if it.window == the_window {
      window_width = it.width;
      window_height = it.height;
    }
  }
}

handle_input :: () {

  for events_this_frame {

    if it.type == {
      case .QUIT;
        quit = true;

      case .KEYBOARD;
        if !it.key_pressed continue;

        if it.key_code == .ESCAPE {
          quit = true;
        } else if it.key_code == .MOUSE_BUTTON_LEFT {
          handle_mouse_click(left_click = true);
        } else if  it.key_code == .MOUSE_BUTTON_RIGHT {
          handle_mouse_click(left_click = false);
        }
    }
  }
}

handle_mouse_click :: (left_click: bool) {
  mx, my, success := get_mouse_pointer_position(the_window, false);
  if !success return;

  local_x := (cast(int) mx - game_origin_x) / game_scale;
  local_y := (cast(int) my - game_origin_y) / game_scale;

  face_x := panel_width / 2 - FACE_SIZE / 2;
  if left_click && point_in_rect(local_x, local_y, face_x, FACE_Y, FACE_SIZE, FACE_SIZE) {
    reset_game();
    return;
  }

  if local_x < board_x || local_y < board_y return;

  cell_x := (local_x - board_x) / CELL_SIZE;
  cell_y := (local_y - board_y) / CELL_SIZE;

  if !in_grid(cell_x, cell_y) return;

  if left_click {
    reveal_at(cell_x, cell_y);
  } else {
    toggle_mark_at(cell_x, cell_y);
  }
}

// -----------------------------------------------------------------------------: assets

tex_flag          : Texture;
tex_cell_hidden   : Texture;
tex_cell_revealed : Texture;
tex_mine          : Texture;
tex_mine_exploded : Texture;
tex_question      : Texture;
tex_numbers       : Texture;
tex_face_smile    : Texture;
tex_face_dead     : Texture;

load_assets :: () {
  load_texture(*tex_cell_hidden,    "data/cell_hidden.png");
  load_texture(*tex_cell_revealed,  "data/cell_revealed.png");
  load_texture(*tex_flag,           "data/cell_flag.png");
  load_texture(*tex_mine,           "data/cell_mine.png");
  load_texture(*tex_mine_exploded,  "data/cell_mine_exploded.png");
  load_texture(*tex_question,       "data/cell_question.png");
  load_texture(*tex_numbers,        "data/cell_numbers.png");
  load_texture(*tex_face_smile,     "data/face_smile.png");
  load_texture(*tex_face_dead,      "data/face_dead.png");
}

load_texture :: (texture: *Texture, filename: string) {
  success := Simp.texture_load_from_file(texture, filename);
  assert(success);
  if !texture.gl_handle return;

  glBindTexture(GL_TEXTURE_2D, texture.gl_handle);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
}

// -----------------------------------------------------------------------------: game logic

reset_game :: () {
  grid_width = clamp(grid_width, MIN_GRID_SIZE, MAX_GRID_SIZE);
  grid_height = clamp(grid_height, MIN_GRID_SIZE, MAX_GRID_SIZE);
  mine_count = clamp(mine_count, 1, grid_width * grid_height - 1);

  array_resize(*cells, cast(s64) (grid_width * grid_height));
  for * cell: cells {
    cell.* = .{};
  }

  mines_placed = false;
  state = .PLAYING;
  revealed_count = 0;
  flag_count = 0;
  game_start_time = 0;
  game_stop_time = 0;

  update_layout();
}

place_mines :: (safe_x: int, safe_y: int) {
  total_cells := grid_width * grid_height;
  can_exclude_neighbors := total_cells - 9 > mine_count;

  placed: int = 0;
  while placed < mine_count {
    index := cast(s64) (random_get() % cast(u64) total_cells);
    x := cast(int) (index % cast(s64) grid_width);
    y := cast(int) (index / cast(s64) grid_width);

    if can_exclude_neighbors {
      if abs(x - safe_x) <= 1 && abs(y - safe_y) <= 1 continue;
    } else if x == safe_x && y == safe_y {
      continue;
    }

    cell := *cells[index];
    if cell.mine continue;

    cell.mine = true;
    placed += 1;
  }

  calculate_adjacencies();
  mines_placed = true;
}

calculate_adjacencies :: () {
  for y: 0..grid_height - 1 {
    for x: 0..grid_width - 1 {
      cell := cell_at(x, y);
      if cell.mine continue;

      count: int = 0;
      for ny: y - 1..y + 1 {
        for nx: x - 1..x + 1 {
          if nx == x && ny == y continue;
          if !in_grid(nx, ny) continue;
          if cell_at(nx, ny).mine count += 1;
        }
      }

      cell.adjacent = count;
    }
  }
}

reveal_at :: (x: int, y: int) {
  if state != .PLAYING return;

  cell := cell_at(x, y);
  if cell.revealed return;
  if cell.mark == .FLAG return;

  if !mines_placed {
    place_mines(x, y);
    game_start_time = seconds_since_init();
  }

  if cell.mine {
    cell.revealed = true;
    cell.exploded = true;
    state = .LOST;
    game_stop_time = seconds_since_init();
    for * mine: cells if mine.mine mine.revealed = true;
    return;
  }

  flood_reveal(x, y);
  check_win();
}

flood_reveal :: (start_x: int, start_y: int) {
  stack: [..] s64;
  defer array_free(stack);

  array_add(*stack, xy_to_index(start_x, start_y));

  while stack.count > 0 {
    index := stack[stack.count - 1];
    stack.count -= 1;
    x := cast(int) (index % cast(s64) grid_width);
    y := cast(int) (index / cast(s64) grid_width);
    cell := *cells[index];

    if cell.revealed || cell.mine || cell.mark == .FLAG continue;

    cell.mark = .NONE;
    cell.revealed = true;
    revealed_count += 1;

    if cell.adjacent != 0 continue;

    for ny: y - 1..y + 1 {
      for nx: x - 1..x + 1 {
        if !in_grid(nx, ny) continue;
        array_add(*stack, xy_to_index(nx, ny));
      }
    }
  }
}

toggle_mark_at :: (x: int, y: int) {
  if state != .PLAYING return;

  cell := cell_at(x, y);
  if cell.revealed return;

  if cell.mark == {
    case .NONE;
      cell.mark = .FLAG;
      flag_count += 1;
    case .FLAG;
      cell.mark = .QUESTION;
      flag_count -= 1;
    case .QUESTION;
      cell.mark = .NONE;
  }
}

check_win :: () {
  if revealed_count < grid_width * grid_height - mine_count return;

  state = .WON;
  game_stop_time = seconds_since_init();

  for * cell: cells {
    if cell.mine && cell.mark != .FLAG {
      cell.mark = .FLAG;
      flag_count += 1;
    }
  }
}

// -----------------------------------------------------------------------------: rendering

draw_one_frame :: () {
  Simp.clear_render_target(background_color.x, background_color.y, background_color.z, background_color.w);

  Simp.set_shader_for_color(true);
  Simp.immediate_begin();

  draw_rect(0, 0, panel_width, panel_height, theme.panel);
  draw_raised_rect(0, 0, panel_width, panel_height);

  board_w := grid_width * CELL_SIZE;
  board_h := grid_height * CELL_SIZE;
  draw_inset_rect(PANEL_PADDING - 2, BOARD_Y - 2, board_w + 4, board_h + 4);

  counter_left_x := PANEL_PADDING + 6;
  counter_right_x := panel_width - PANEL_PADDING - 6 - COUNTER_WIDTH;
  face_x := panel_width / 2 - FACE_SIZE / 2;

  draw_inset_rect(counter_left_x - 2, COUNTER_Y - 2, COUNTER_WIDTH + 4, COUNTER_HEIGHT + 4);
  draw_inset_rect(counter_right_x - 2, COUNTER_Y - 2, COUNTER_WIDTH + 4, COUNTER_HEIGHT + 4);
  draw_raised_rect(face_x, FACE_Y, FACE_SIZE, FACE_SIZE);

  draw_counter(mine_count - flag_count, counter_left_x, COUNTER_Y);
  draw_counter(current_timer_seconds(), counter_right_x, COUNTER_Y);

  draw_grid();
  Simp.immediate_flush();

  draw_cells();
  texture := ifx state == .LOST then *tex_face_dead else *tex_face_smile;
  draw_texture(texture, face_x, FACE_Y, FACE_SIZE, FACE_SIZE);
}

draw_grid :: () {
  board_w := grid_width  * CELL_SIZE;
  board_h := grid_height * CELL_SIZE;

  for x: 0..grid_width {
    px := board_x + x * CELL_SIZE;
    draw_rect(px, board_y, 1, board_h, theme.cell_border);
  }

  for y: 0..grid_height {
    py := board_y + y * CELL_SIZE;
    draw_rect(board_x, py, board_w, 1, theme.cell_border);
  }
}

draw_cells :: () {
  for y: 0..grid_height - 1 {
    for x: 0..grid_width - 1 {
      cell := cell_at(x, y);
      px := board_x + x * CELL_SIZE;
      py := board_y + y * CELL_SIZE;

      texture := ifx cell.revealed then *tex_cell_revealed else *tex_cell_hidden;
      draw_texture(texture, px, py, CELL_SIZE, CELL_SIZE);

      if cell.revealed {
        if cell.mine {
          texture := ifx cell.exploded then *tex_mine_exploded else *tex_mine;
          draw_texture(texture, px, py, CELL_SIZE, CELL_SIZE);
        } else if cell.adjacent > 0 {
          draw_number(cell.adjacent, px, py);
        }
      } else if cell.mark == .FLAG {
        draw_texture(*tex_flag, px, py, CELL_SIZE, CELL_SIZE);
      } else if cell.mark == .QUESTION {
        draw_texture(*tex_question, px, py, CELL_SIZE, CELL_SIZE);
      }
    }
  }
}

draw_raised_rect :: (x: int, y: int, w: int, h: int) {
  draw_rect(x, y, w, 1, theme.highlight);
  draw_rect(x, y, 1, h, theme.highlight);
  draw_rect(x + w - 1, y, 1, h, theme.dark_shadow);
  draw_rect(x, y + h - 1, w, 1, theme.dark_shadow);
  draw_rect(x + w - 2, y + 1, 1, h - 2, theme.shadow);
  draw_rect(x + 1, y + h - 2, w - 2, 1, theme.shadow);
}

draw_inset_rect :: (x: int, y: int, w: int, h: int) {
  draw_rect(x, y, w, h, theme.black);
  draw_rect(x, y, w, 1, theme.dark_shadow);
  draw_rect(x, y, 1, h, theme.dark_shadow);
  draw_rect(x + w - 1, y, 1, h, theme.highlight);
  draw_rect(x, y + h - 1, w, 1, theme.highlight);
}

draw_counter :: (value: int, x: int, y: int) {
  draw_rect(x, y, COUNTER_WIDTH, COUNTER_HEIGHT, theme.black);

  COUNTER_MIN: int : -99;
  COUNTER_MAX: int : 999;
  value = clamp(value, COUNTER_MIN, COUNTER_MAX);
  digit_y := y + 3;
  digit_x := x + 3;

  draw_digit(ifx value < 0 then -1 else value / 100, digit_x, digit_y);
  value = abs(value);
  draw_digit((value / 10) % 10, digit_x + 11, digit_y);
  draw_digit(value % 10, digit_x + 22, digit_y);
}

draw_digit :: (digit: int, x: int, y: int) {
  masks: [10] int : .[0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f];
  rects: [7][4] int : .[
    .[2, 0, 5, 2], .[7, 2, 2, 5], .[7, 8, 2, 5], .[2, 13, 5, 2],
    .[0, 8, 2, 5], .[0, 2, 2, 5], .[2, 7, 5, 2]
  ];
  mask := ifx digit == -1 then 0x40 else masks[digit];
  for rect, i: rects {
    color := ifx (mask & (1 << i)) != 0 then theme.counter_red else theme.counter_dim;
    draw_rect(x + rect[0], y + rect[1], rect[2], rect[3], color);
  }
}

draw_number :: (number: int, x: int, y: int) {
  if number < 1 || number > 8 return;

  src_x := (number - 1) * NUMBER_SIZE;
  u0 := cast(float) src_x / cast(float) tex_numbers.width;
  u1 := cast(float) (src_x + NUMBER_SIZE) / cast(float) tex_numbers.width;

  draw_texture(*tex_numbers, x, y, NUMBER_SIZE, NUMBER_SIZE, u0, u1);
}

draw_texture :: (texture: *Texture, x: int, y: int, w: int, h: int, u0: float = 0, u1: float = 1) {
  if !texture return;
  if !texture.width || !texture.height return;

  Simp.set_shader_for_images(texture);
  Simp.immediate_begin();

  p0 := base_to_screen(x, y);
  p1 := base_to_screen(x + w, y);
  p2 := base_to_screen(x + w, y + h);
  p3 := base_to_screen(x, y + h);

  Simp.immediate_quad(p0, p1, p2, p3, Vector4.{1, 1, 1, 1},
  .{u0, 0}, .{u1, 0}, .{u1, 1}, .{u0, 1});
  Simp.immediate_flush();
}

draw_rect :: (x: int, y: int, w: int, h: int, color: Vector4) {
  if w <= 0 || h <= 0 return;

  sx := cast(float) (game_origin_x + x * game_scale);
  sy := cast(float) (game_origin_y + y * game_scale);
  sw := cast(float) (w * game_scale);
  sh := cast(float) (h * game_scale);

  Simp.immediate_quad(sx, sy, sx + sw, sy + sh, color);
}

// -----------------------------------------------------------------------------: helpers

update_layout :: () {
  board_x = PANEL_PADDING;
  board_y = BOARD_Y;

  board_w := grid_width * CELL_SIZE;
  board_h := grid_height * CELL_SIZE;

  panel_width = board_w + PANEL_PADDING * 2;
  panel_height = board_y + board_h + PANEL_PADDING;

  sx := window_width / panel_width;
  sy := window_height / panel_height;
  game_scale = min(sx, sy);
  if game_scale < 1 game_scale = 1;

  game_origin_x = (window_width - panel_width * game_scale) / 2;
  game_origin_y = (window_height - panel_height * game_scale) / 2;
}

current_timer_seconds :: () -> int {
  if !mines_placed return 0;

  now := ifx state == .PLAYING then seconds_since_init() else game_stop_time;
  elapsed := cast(int) (now - game_start_time);
  return clamp(elapsed, 0, 999);
}

cell_at :: (x: int, y: int) -> *Cell {
  return *cells[xy_to_index(x, y)];
}

xy_to_index :: (x: int, y: int) -> s64 {
  return cast(s64) y * cast(s64) grid_width + cast(s64) x;
}

in_grid :: (x: int, y: int) -> bool {
  return x >= 0 && x < grid_width && y >= 0 && y < grid_height;
}

point_in_rect :: (px: int, py: int, x: int, y: int, w: int, h: int) -> bool {
  return px >= x && px < x + w && py >= y && py < y + h;
}

base_to_screen :: (x: int, y: int) -> Vector2 {
  return .{cast(float) (game_origin_x + x * game_scale),
  cast(float) (game_origin_y + y * game_scale)};
}

#import "Basic";

#import "GL";
#import "Input";
#import "Math";
#import "Random";
#import "Window_Creation";

Simp :: #import "Simp";
Texture :: Simp.Texture;

#if OS == .WINDOWS {
  Windows :: #import "Windows";
}
