#import "Basic";
#import "Input";
#import "Math";
Simp :: #import "Simp";
#import "Window_Creation";

window_width  :: 800;
window_height :: 600;

background_color :: Vector4.{x=0.86, y=0.78, z=0.64, w=1};
grid_color       :: Vector4.{x=0.34, y=0.42, z=0.48, w=1};

grid_cols :: 16;
grid_rows :: 16;

grid_width  :: 560;
grid_height :: 560;

grid_cell_width  :: grid_width / grid_cols;
grid_cell_height :: grid_height / grid_rows;

grid_x : float : (window_width  - grid_width)  * 0.5;
grid_y : float : (window_height - grid_height) * 0.5;

immediate_cell_quad :: (col: s64, row: s64, color: Vector4) {
    x : float = grid_x + xx(col * grid_cell_width);
    y : float = grid_y + xx(row * grid_cell_height);
    w : float = grid_cell_width;
    h : float = grid_cell_height;

    Simp.immediate_quad(x, y, x + w, y + h, color);
}

main :: () {
    win := create_window(window_width, window_height, "ck: Dense Grid Board");

    Simp.set_render_target(win);
    Simp.set_shader_for_color(true);

    quit := false;
    while !quit {
        Simp.clear_render_target(0.12, 0.14, 0.16, 1);

        update_window_events();

        for event : events_this_frame {
            if event.type == {
                case .QUIT; {
                    quit = true;
                    break;
                }

                case .KEYBOARD; if event.key_pressed {
                    if event.key_code == {
                        case .ESCAPE;
                        quit = true;
                        break;
                    }
                }
            }
        }

        for col: 0..grid_cols-1 {
            for row: 0..grid_rows-1 {
                color := ifx (col + row) % 2 == 0 then background_color else grid_color;
                immediate_cell_quad(col, row, color);
            }
        }

        sleep_milliseconds(10);
        Simp.swap_buffers(win);
        reset_temporary_storage();
    }
}
