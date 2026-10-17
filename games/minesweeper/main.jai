#import "Basic";

#import "GL";
#import "Input";
#import "Math";
#import "Random";
#import "Window_Creation";

Simp :: #import "Simp";
ImGui :: #import "Simp_ImGui";

#if OS == .WINDOWS {
  Windows :: #import "Windows";
}

// ----------------------------------------------------------------------------: globals

Texture :: Simp.Texture;

the_window : Window_Type;
window_width : s32 = 1280;
window_height : s32 = 720;
saved_window_info : Saved_Window_Info;

quit := false;

background_color := Vector4.{0.02, 0.15, 0.15, 1};

// ----------------------------------------------------------------------------: visual config

CELL_INNER_SIZE: s32 : 15;
CELL_BORDER_SIZE: s32 : 1;
CELL_SIZE: s32 : CELL_INNER_SIZE + CELL_BORDER_SIZE;
NUMBER_SIZE: s32 : CELL_SIZE;

PANEL_PADDING: s32 : 10;
HEADER_Y: s32 : 10;
HEADER_HEIGHT: s32 : 32;
BOARD_Y: s32 : 52;
COUNTER_WIDTH: s32 : 39;
COUNTER_HEIGHT: s32 : 20;
COUNTER_Y: s32 : 16;
FACE_SIZE: s32 : 24;
FACE_Y: s32 : 14;

CELL_NORMAL       :: Vector4.{0.75, 0.75, 0.75, 1};
CELL_REVEALED     :: Vector4.{0.66, 0.66, 0.66, 1};
PANEL_COLOR       :: Vector4.{0.75, 0.75, 0.75, 1};
HIGHLIGHT_COLOR   :: Vector4.{1.00, 1.00, 1.00, 1};
SHADOW_COLOR      :: Vector4.{0.50, 0.50, 0.50, 1};
DARK_SHADOW_COLOR :: Vector4.{0.25, 0.25, 0.25, 1};
CELL_BORDER_COLOR :: Vector4.{0.45, 0.45, 0.45, 1};
BLACK             :: Vector4.{0.00, 0.00, 0.00, 1};
COUNTER_RED       :: Vector4.{1.00, 0.05, 0.02, 1};
COUNTER_DIM       :: Vector4.{0.18, 0.00, 0.00, 1};

// ----------------------------------------------------------------------------: game config/state

MIN_GRID_SIZE: s32 : 5;
MAX_GRID_SIZE: s32 : 60;

grid_width: s32 = 16;
grid_height: s32 = 16;
mine_count: s32 = 40;

settings_grid_width: s32 = 16;
settings_grid_height: s32 = 16;
settings_mine_count: s32 = 40;

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
  adjacent: s32;
}

cells: [..] Cell;
mines_placed := false;
game_started := false;
game_over := false;
game_won := false;
revealed_count: s32;
flag_count: s32;
game_start_time: float64;
game_stop_time: float64;

panel_width: s32;
panel_height: s32;
board_x: s32;
board_y: s32;
game_origin_x: s32;
game_origin_y: s32;
game_scale: s32 = 1;

tex_flag: Texture;
tex_cell_hidden: Texture;
tex_cell_revealed: Texture;
tex_mine: Texture;
tex_mine_exploded: Texture;
tex_question: Texture;
tex_numbers: Texture;
tex_face_smile: Texture;
tex_face_dead: Texture;

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

  random_seed(cast(u64) (seconds_since_init() * 1000000.0));

  init_window();
  load_assets();
  ImGui.init();
  reset_game();
}

update :: () {
  update_window_events();
  handle_window_resizes();
  update_layout();
  handle_input();
}

render :: () {
  render_one_frame();
  render_imgui();
}

shutdown :: () {
  ImGui.shutdown();
}

// ----------------------------------------------------------------------------: window/input

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
  io := ImGui.GetIO();

  for events_this_frame {
    ImGui.process_event(it);

    if it.type == {
      case .QUIT;
        quit = true;

      case .KEYBOARD;
        if !it.key_pressed continue;

        if it.key_code == .ESCAPE {
          quit = true;
        } else if !io.WantCaptureMouse && it.key_code == .MOUSE_BUTTON_LEFT {
          handle_mouse_click(left_click = true);
        } else if !io.WantCaptureMouse && it.key_code == .MOUSE_BUTTON_RIGHT {
          handle_mouse_click(left_click = false);
        }
    }
  }
}

handle_mouse_click :: (left_click: bool) {
  mx, my, success := get_mouse_pointer_position(the_window, false);
  if !success return;

  local_x := (cast(s32) mx - game_origin_x) / game_scale;
  local_y := (cast(s32) my - game_origin_y) / game_scale;

  face_x := panel_width / 2 - FACE_SIZE / 2;
  if left_click && point_in_rect(local_x, local_y, face_x, FACE_Y, FACE_SIZE, FACE_SIZE) {
    reset_game();
    return;
  }

  if local_x < board_x || local_y < board_y return;

  cell_x := (local_x - board_x) / CELL_SIZE;
  cell_y := (local_y - board_y) / CELL_SIZE;

  if cell_x < 0 || cell_x >= grid_width return;
  if cell_y < 0 || cell_y >= grid_height return;

  if left_click {
    reveal_at(cell_x, cell_y);
  } else {
    toggle_mark_at(cell_x, cell_y);
  }
}

// ----------------------------------------------------------------------------: assets

load_assets :: () {
  load_texture(*tex_cell_hidden,    "assets/sprites/cell_hidden.png");
  load_texture(*tex_cell_revealed,  "assets/sprites/cell_revealed.png");
  load_texture(*tex_flag,          "assets/sprites/cell_flag.png");
  load_texture(*tex_mine,          "assets/sprites/cell_mine.png");
  load_texture(*tex_mine_exploded, "assets/sprites/cell_mine_exploded.png");
  load_texture(*tex_question,      "assets/sprites/cell_question.png");
  load_texture(*tex_numbers,       "assets/sprites/cell_numbers.png");
  load_texture(*tex_face_smile,    "assets/sprites/face_smile.png");
  load_texture(*tex_face_dead,     "assets/sprites/face_dead.png");
}

load_texture :: (texture: *Texture, filename: string) {
  success := Simp.texture_load_from_file(texture, filename);
  assert(success);
  set_texture_nearest(texture);
}

set_texture_nearest :: (texture: *Texture) {
  if !texture.gl_handle return;

  glBindTexture(GL_TEXTURE_2D, texture.gl_handle);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
}

// ----------------------------------------------------------------------------: game logic

reset_game :: () {
  grid_width = clamp(settings_grid_width, MIN_GRID_SIZE, MAX_GRID_SIZE);
  grid_height = clamp(settings_grid_height, MIN_GRID_SIZE, MAX_GRID_SIZE);
  mine_count = clamp(settings_mine_count, 1, grid_width * grid_height - 1);

  settings_grid_width = grid_width;
  settings_grid_height = grid_height;
  settings_mine_count = mine_count;

  array_resize(*cells, cast(s64) (grid_width * grid_height));
  for * cell: cells {
    cell.mine = false;
    cell.revealed = false;
    cell.exploded = false;
    cell.mark = .NONE;
    cell.adjacent = 0;
  }

  mines_placed = false;
  game_started = false;
  game_over = false;
  game_won = false;
  revealed_count = 0;
  flag_count = 0;
  game_start_time = 0;
  game_stop_time = 0;

  update_layout();
}

place_mines :: (safe_x: s32, safe_y: s32) {
  total_cells := grid_width * grid_height;
  can_exclude_neighbors := total_cells - 9 > mine_count;

  placed: s32 = 0;
  while placed < mine_count {
    index := cast(s64) (random_get() % cast(u64) total_cells);
    x := cast(s32) (index % cast(s64) grid_width);
    y := cast(s32) (index / cast(s64) grid_width);

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

      count: s32 = 0;
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

reveal_at :: (x: s32, y: s32) {
  if game_over || game_won return;

  cell := cell_at(x, y);
  if cell.revealed return;
  if cell.mark == .FLAG return;

  if !mines_placed {
    place_mines(x, y);
    game_started = true;
    game_start_time = seconds_since_init();
  }

  if cell.mine {
    cell.revealed = true;
    cell.exploded = true;
    game_over = true;
    game_stop_time = seconds_since_init();
    reveal_all_mines();
    return;
  }

  flood_reveal(x, y);
  check_win();
}

flood_reveal :: (start_x: s32, start_y: s32) {
  stack: [..] s64;
  defer array_free(stack);

  array_add(*stack, xy_to_index(start_x, start_y));

  while stack.count > 0 {
    index := stack[stack.count - 1];
    stack.count -= 1;
    x := cast(s32) (index % cast(s64) grid_width);
    y := cast(s32) (index / cast(s64) grid_width);
    cell := *cells[index];

    if cell.revealed continue;
    if cell.mine continue;
    if cell.mark == .FLAG continue;

    if cell.mark == .QUESTION cell.mark = .NONE;

    cell.revealed = true;
    revealed_count += 1;

    if cell.adjacent != 0 continue;

    for ny: y - 1..y + 1 {
      for nx: x - 1..x + 1 {
        if nx == x && ny == y continue;
        if !in_grid(nx, ny) continue;

        neighbor := cell_at(nx, ny);
        if neighbor.revealed continue;
        if neighbor.mine continue;
        if neighbor.mark == .FLAG continue;

        array_add(*stack, xy_to_index(nx, ny));
      }
    }
  }
}

toggle_mark_at :: (x: s32, y: s32) {
  if game_over || game_won return;

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

reveal_all_mines :: () {
  for * cell: cells {
    if cell.mine cell.revealed = true;
  }
}

check_win :: () {
  if revealed_count < grid_width * grid_height - mine_count return;

  game_won = true;
  game_stop_time = seconds_since_init();

  for * cell: cells {
    if cell.mine && cell.mark != .FLAG {
      cell.mark = .FLAG;
      flag_count += 1;
    }
  }
}

// ----------------------------------------------------------------------------: rendering

render_one_frame :: () {
  clear_background(background_color);
  draw_game();
}

render_imgui :: () {
  ImGui.new_frame(the_window, window_width, window_height);

  ui_scale := ImGui.get_ui_scale();
  ImGui.SetNextWindowPos(.{40 * ui_scale, 20 * ui_scale}, .FirstUseEver);
  ImGui.SetNextWindowSize(.{320 * ui_scale, 210 * ui_scale}, .FirstUseEver);

  if ImGui.Begin("Minesweeper") {
    ImGui.SliderInt("Grid width", *settings_grid_width, MIN_GRID_SIZE, MAX_GRID_SIZE);
    ImGui.SliderInt("Grid height", *settings_grid_height, MIN_GRID_SIZE, MAX_GRID_SIZE);

    ONE: s32 : 1;
    max_mines := max(ONE, settings_grid_width * settings_grid_height - ONE);
    settings_mine_count = clamp(settings_mine_count, 1, max_mines);
    ImGui.SliderInt("Mines", *settings_mine_count, 1, max_mines);

    if ImGui.Button("New game") {
      reset_game();
    }

    ImGui.Separator();
    ImGui.Text("Current: % x %, mines %", grid_width, grid_height, mine_count);
    ImGui.Text("Cell: %px inner + %px border", CELL_INNER_SIZE, CELL_BORDER_SIZE);
  }
  ImGui.End();

  ImGui.render();
}

draw_game :: () {
  update_layout();

  Simp.set_shader_for_color(true);
  Simp.immediate_begin();

  draw_rect_base(0, 0, panel_width, panel_height, PANEL_COLOR);
  draw_raised_rect_base(0, 0, panel_width, panel_height);

  board_w := grid_width * CELL_SIZE;
  board_h := grid_height * CELL_SIZE;
  draw_inset_rect_base(PANEL_PADDING - 2, BOARD_Y - 2, board_w + 4, board_h + 4);

  counter_left_x := PANEL_PADDING + 6;
  counter_right_x := panel_width - PANEL_PADDING - 6 - COUNTER_WIDTH;
  face_x := panel_width / 2 - FACE_SIZE / 2;

  draw_inset_rect_base(counter_left_x - 2, COUNTER_Y - 2, COUNTER_WIDTH + 4, COUNTER_HEIGHT + 4);
  draw_inset_rect_base(counter_right_x - 2, COUNTER_Y - 2, COUNTER_WIDTH + 4, COUNTER_HEIGHT + 4);
  draw_raised_rect_base(face_x, FACE_Y, FACE_SIZE, FACE_SIZE);

  draw_counter_base(mine_count - flag_count, counter_left_x, COUNTER_Y);
  draw_counter_base(current_timer_seconds(), counter_right_x, COUNTER_Y);

  draw_grid_base();
  draw_cells_base();

  Simp.immediate_flush();

  draw_cell_overlays();
  draw_face_texture(face_x, FACE_Y);
}

draw_cells_base :: () {
  for y: 0..grid_height - 1 {
    for x: 0..grid_width - 1 {
      cell := cell_at(x, y);
      px := board_x + x * CELL_SIZE;
      py := board_y + y * CELL_SIZE;

      if cell.revealed {
        draw_revealed_cell_base(px, py);
      } else {
        draw_hidden_cell_base(px, py);
      }
    }
  }
}

draw_grid_base :: () {
  board_w := grid_width * CELL_SIZE;
  board_h := grid_height * CELL_SIZE;

  for x: 0..grid_width {
    px := board_x + x * CELL_SIZE;
    draw_rect_base(px, board_y, 1, board_h, CELL_BORDER_COLOR);
  }

  for y: 0..grid_height {
    py := board_y + y * CELL_SIZE;
    draw_rect_base(board_x, py, board_w, 1, CELL_BORDER_COLOR);
  }
}

draw_cell_overlays :: () {
  for y: 0..grid_height - 1 {
    for x: 0..grid_width - 1 {
      cell := cell_at(x, y);
      px := board_x + x * CELL_SIZE;
      py := board_y + y * CELL_SIZE;

      if cell.revealed {
        if cell.mine {
          texture := ifx cell.exploded then *tex_mine_exploded else *tex_mine;
          draw_texture_base(texture, px, py, CELL_SIZE, CELL_SIZE);
        } else if cell.adjacent > 0 {
          draw_number_base(cell.adjacent, px, py);
        }
      } else if cell.mark == .FLAG {
        draw_texture_base(*tex_flag, px, py, CELL_SIZE, CELL_SIZE);
      } else if cell.mark == .QUESTION {
        draw_texture_base(*tex_question, px, py, CELL_SIZE, CELL_SIZE);
      }
    }
  }
}

draw_face_texture :: (x: s32, y: s32) {
  texture := ifx game_over then *tex_face_dead else *tex_face_smile;
  draw_texture_base(texture, x, y, FACE_SIZE, FACE_SIZE);
}

draw_hidden_cell_base :: (x: s32, y: s32) {
  draw_texture_base(*tex_cell_hidden, x, y, CELL_SIZE, CELL_SIZE);
}

draw_revealed_cell_base :: (x: s32, y: s32) {
  draw_texture_base(*tex_cell_revealed, x, y, CELL_SIZE, CELL_SIZE);
}

draw_raised_rect_base :: (x: s32, y: s32, w: s32, h: s32) {
  draw_rect_base(x, y, w, 1, HIGHLIGHT_COLOR);
  draw_rect_base(x, y, 1, h, HIGHLIGHT_COLOR);
  draw_rect_base(x + w - 1, y, 1, h, DARK_SHADOW_COLOR);
  draw_rect_base(x, y + h - 1, w, 1, DARK_SHADOW_COLOR);
  draw_rect_base(x + w - 2, y + 1, 1, h - 2, SHADOW_COLOR);
  draw_rect_base(x + 1, y + h - 2, w - 2, 1, SHADOW_COLOR);
}

draw_inset_rect_base :: (x: s32, y: s32, w: s32, h: s32) {
  draw_rect_base(x, y, w, h, BLACK);
  draw_rect_base(x, y, w, 1, DARK_SHADOW_COLOR);
  draw_rect_base(x, y, 1, h, DARK_SHADOW_COLOR);
  draw_rect_base(x + w - 1, y, 1, h, HIGHLIGHT_COLOR);
  draw_rect_base(x, y + h - 1, w, 1, HIGHLIGHT_COLOR);
}

draw_counter_base :: (value: s32, x: s32, y: s32) {
  draw_rect_base(x, y, COUNTER_WIDTH, COUNTER_HEIGHT, BLACK);

  COUNTER_MIN: s32 : -99;
  COUNTER_MAX: s32 : 999;
  value = clamp(value, COUNTER_MIN, COUNTER_MAX);
  digit_y := y + 3;
  digit_x := x + 3;

  if value < 0 {
    abs_value := -value;
    draw_digit_base(-1, digit_x, digit_y);
    draw_digit_base((abs_value / 10) % 10, digit_x + 11, digit_y);
    draw_digit_base(abs_value % 10, digit_x + 22, digit_y);
  } else {
    draw_digit_base((value / 100) % 10, digit_x, digit_y);
    draw_digit_base((value / 10) % 10, digit_x + 11, digit_y);
    draw_digit_base(value % 10, digit_x + 22, digit_y);
  }
}

draw_digit_base :: (digit: s32, x: s32, y: s32) {
  draw_digit_segments_base(digit, x, y, COUNTER_DIM);
  draw_digit_segments_base(digit, x, y, COUNTER_RED, active_only = true);
}

draw_digit_segments_base :: (digit: s32, x: s32, y: s32, color: Vector4, active_only := false) {
  segments := digit_segments(digit);

  draw_digit_segment_base((segments & 0x01) != 0, active_only, x, y, 2, 0, 5, 2, color);
  draw_digit_segment_base((segments & 0x02) != 0, active_only, x, y, 7, 2, 2, 5, color);
  draw_digit_segment_base((segments & 0x04) != 0, active_only, x, y, 7, 8, 2, 5, color);
  draw_digit_segment_base((segments & 0x08) != 0, active_only, x, y, 2, 13, 5, 2, color);
  draw_digit_segment_base((segments & 0x10) != 0, active_only, x, y, 0, 8, 2, 5, color);
  draw_digit_segment_base((segments & 0x20) != 0, active_only, x, y, 0, 2, 2, 5, color);
  draw_digit_segment_base((segments & 0x40) != 0, active_only, x, y, 2, 7, 5, 2, color);
}

draw_digit_segment_base :: (active: bool, active_only: bool, x: s32, y: s32,
                            sx: s32, sy: s32, sw: s32, sh: s32, color: Vector4) {
  if active_only && !active return;
  draw_rect_base(x + sx, y + sy, sw, sh, ifx active then color else COUNTER_DIM);
}

digit_segments :: (digit: s32) -> s32 {
  if digit == -1 return 0x40;
  if digit == 0 return 0x3f;
  if digit == 1 return 0x06;
  if digit == 2 return 0x5b;
  if digit == 3 return 0x4f;
  if digit == 4 return 0x66;
  if digit == 5 return 0x6d;
  if digit == 6 return 0x7d;
  if digit == 7 return 0x07;
  if digit == 8 return 0x7f;
  if digit == 9 return 0x6f;
  return 0;
}

draw_number_base :: (number: s32, x: s32, y: s32) {
  if number < 1 || number > 8 return;

  src_x := (number - 1) * NUMBER_SIZE;
  u0 := cast(float) src_x / cast(float) tex_numbers.width;
  u1 := cast(float) (src_x + NUMBER_SIZE) / cast(float) tex_numbers.width;

  draw_texture_region_base(*tex_numbers, x, y, NUMBER_SIZE, NUMBER_SIZE,
                           .{u0, 0}, .{u1, 0}, .{u1, 1}, .{u0, 1});
}

draw_texture_base :: (texture: *Texture, x: s32, y: s32, w: s32, h: s32) {
  draw_texture_region_base(texture, x, y, w, h, .{0, 0}, .{1, 0}, .{1, 1}, .{0, 1});
}

draw_texture_region_base :: (texture: *Texture, x: s32, y: s32, w: s32, h: s32,
                             uv0: Vector2, uv1: Vector2, uv2: Vector2, uv3: Vector2) {
  if !texture return;
  if !texture.width || !texture.height return;

  Simp.set_shader_for_images(texture);
  Simp.immediate_begin();

  p0 := base_to_screen(x, y);
  p1 := base_to_screen(x + w, y);
  p2 := base_to_screen(x + w, y + h);
  p3 := base_to_screen(x, y + h);

  Simp.immediate_quad(p0, p1, p2, p3, Vector4.{1, 1, 1, 1}, uv0, uv1, uv2, uv3);
  Simp.immediate_flush();
}

draw_rect_base :: (x: s32, y: s32, w: s32, h: s32, color: Vector4) {
  if w <= 0 || h <= 0 return;

  sx := cast(float) (game_origin_x + x * game_scale);
  sy := cast(float) (game_origin_y + y * game_scale);
  sw := cast(float) (w * game_scale);
  sh := cast(float) (h * game_scale);

  Simp.immediate_quad(sx, sy, sx + sw, sy + sh, color);
}

clear_background :: (color: Vector4) {
  Simp.clear_render_target(color.x, color.y, color.z, color.w);
}

// ----------------------------------------------------------------------------: helpers

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

current_timer_seconds :: () -> s32 {
  if !game_started return 0;

  now := ifx (game_over || game_won) then game_stop_time else seconds_since_init();
  elapsed := cast(s32) (now - game_start_time);
  return clamp(elapsed, 0, 999);
}

cell_at :: (x: s32, y: s32) -> *Cell {
  return *cells[xy_to_index(x, y)];
}

xy_to_index :: (x: s32, y: s32) -> s64 {
  return cast(s64) y * cast(s64) grid_width + cast(s64) x;
}

in_grid :: (x: s32, y: s32) -> bool {
  return x >= 0 && x < grid_width && y >= 0 && y < grid_height;
}

point_in_rect :: (px: s32, py: s32, x: s32, y: s32, w: s32, h: s32) -> bool {
  return px >= x && px < x + w && py >= y && py < y + h;
}

base_to_screen :: (x: s32, y: s32) -> Vector2 {
  return .{cast(float) (game_origin_x + x * game_scale),
           cast(float) (game_origin_y + y * game_scale)};
}
