#import "Gui";  // Other imports are below, but the point of this example is to use GetRect so this #import goes here.

the_window: Window_Type;

SCALE :: 1;  // I use this during development to quickly make the window real big.

window_width  : s32 = 1920*SCALE;
window_height : s32 = 1080*SCALE;

current_time: float64;
last\  _time: float64;

Font :: Simp.Dynamic_Font;

title_font: *Font;
story_font: *Font;


current_theme: s32 = xx Default_Themes.Default;
theme: Overall_Theme;  // This gets filled out by calling the Theme_Proc for current_theme.

working_directory_set := false;

// ----------------------------------------------------------------------------: data

picked_color : Vector3 = .{.1, .8, .6};

subwindow_info_text: Subwindow_Info;
subwindow_initted := false;

vertical_scroll_value: float;
horizontal_scroll_value: float;

PARADISE_LOST :: #string DONE
I thence
Invoke thy aid to my adventurous song,
That with no middle flight intends to soar
Above th' Aonian mount, while it pursues
Things unattempted yet in prose or rhyme.
And chiefly thou, O Spirit, that dost prefer
Before all temples th' upright heart and pure,
Instruct me, for thou know'st; thou from the first
Wast present, and, with mighty wings outspread,
Dove-like sat'st brooding on the vast Abyss,
And mad'st it pregnant: what in me is dark
Illumine, what is low raise and support;
That, to the height of this great argument,
I may assert Eternal Providence,
And justify the ways of God to men.
DONE

// ----------------------------------------------------------------------------: entry

main :: () {
    #if OS == .WINDOWS {
        Windows :: #import "Windows";

        Windows.SetProcessDPIAware();

        // Improve timing/thread scheduling behavior on Windows.
        Windows.timeBeginPeriod(1);
    }

    the_window = create_window(window_width, window_height, "ck: GetRect Playground");
    Simp.set_render_target(the_window);

    init_fonts();
    ui_init();


    quit := false;

    while !quit {
        current_time = seconds_since_init();

        dt := cast(float)(current_time - last_time);
        Clamp(*dt, 0, 0.1);

        last_time = current_time;


        Input.update_window_events();

        for Input.get_window_resizes() {
            Simp.update_window(it.window);

            if it.window == the_window {
                should_reinit :=
                (it.width  != window_width) ||
                (it.height != window_height);

                window_width  = it.width;
                window_height = it.height;

                if should_reinit {
                    init_fonts();
                }
            }
        }

        for it: Input.events_this_frame {
            if it.type == .QUIT {
                quit = true;
            }

            // Let GetRect process mouse / keyboard input.
            getrect_handle_event(it);

            if it.type == .KEYBOARD {
                if !it.key_pressed continue;
                key := it.key_code;

                if key == {
                    case .ESCAPE;
                        active_widget_deactivate_all();
                }
            }
        }

        draw_one_frame();

        reset_temporary_storage();
    }
}

draw_one_frame :: () {
    //
    // Theme
    //

    theme_proc := default_theme_procs[xx Default_Themes.Default];

    theme := theme_proc();

    set_default_theme(theme);


    //
    // Clear screen
    //

    bg := theme.background_color;

    Simp.clear_render_target(
        bg.x,
        bg.y,
        bg.z,
        1
    );


    //
    // Tell GetRect about this frame.
    //

    x, y, width, height := get_dimensions(the_window, true);

    ui_per_frame_update(
        the_window,
        width,
        height,
        current_time
    );


    //
    // Title
    //

    label_theme := theme.label_theme;

    label_theme.font = title_font;

    label_height := title_font.character_height * 1.5;

    title_rect := get_rect(
        0,
        window_height - label_height,
        xx window_width,
        label_height
    );

    label(title_rect, "Some Widgets", *label_theme);


    //
    // UI components will go here later.
    //
    if !subwindow_initted {
        r := get_rect(200, 200, 700, 500);
        subwindow_info_text.rect       = r;
        subwindow_info_text.draw       = draw_subwindow_text;
        subwindow_info_text.title_text = "Text";
        subwindow_info_text.open       = true;

        subwindow_initted = true;
    }

    if subwindow_info_text.open {
        subwindow_theme := theme.subwindow_theme;

        add_subwindow(
            *subwindow_info_text,
            *subwindow_theme
        );
    }


    //
    // Popups / subwindows.
    //
    // Even though we don't currently have any, keeping this here means
    // dropdowns / subwindows can be added later without restructuring.
    //

    draw_popups();


    //
    // Present frame.
    //

    Simp.swap_buffers(the_window);
}

init_fonts :: () {
    if !working_directory_set {
        path := path_strip_filename(
            get_path_of_running_executable()
        );

        set_working_directory(path);

        working_directory_set = true;
    }

    pixel_height := window_height / 7;
    title_font = Simp.get_font_at_size("data", "Miama.otf", pixel_height);

    pixel_height = window_height / 30;
    story_font = Simp.get_font_at_size("data", "OpenSans-BoldItalic.ttf", pixel_height);
}

draw_subwindow_text :: (state: *Subwindow_State, r: Rect, data: *void) {
    font := story_font;
    lines := split(PARADISE_LOST, "\n");

    pad := cast(float) font.default_line_spacing * 0.5;

    scroll_theme := theme.scrollable_region_theme;
    scroll_theme.margin_flags = 0;

    region, inside := begin_scrollable_region(r, *scroll_theme);

    x := inside.x + pad;
    y := inside.y + inside.h + vertical_scroll_value;

    color := Vector4.{0.8, 0.8, 0.8, 1};

    for lines {
        y -= cast(float) font.default_line_spacing;

        Simp.draw_text(font, xx x, xx y, it, color);
    }

    min_y := y;

    end_scrollable_region(region, 0, min_y, *vertical_scroll_value);
}

// ----------------------------------------------------------------------------: imports

using Simp  :: #import "Simp";
using Input :: #import "Input";

#import "Window_Creation";
#import "Basic";
#import "Math";
#import "System";
#import "String";
