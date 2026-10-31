//
// Compile-Time stuff:
//
// At compile-time, we load an image file off disk and into memory, then call add_global_data
// to map it into the global space. This goes into the actual executable in a way that is
// going to be pretty consistent across operating systems, but this has other costs, like,
// it makes your executable bigger!  There are other ways of attaching data that are
// more os-dependent, like for example the stuff that happens in modules/Windows_Resources,
// but then, you have to query these at runtime. The advantage of these is that maybe your
// operating system treats them a little differently than actual code+data, if you think
// that is an actual advantage.
//
// Why bake data into your main program? Well, maybe you want to distribute a standalone exe
// that doesn't require any data files and doesn't care where it is located in the filesystem.
// Maybe you want fast access to some of your data at startup, and can load the rest later.
//
image :: #run add_global_data(get_data("witness_stones.jpg"), .READ_ONLY);

get_data :: (name : string) -> [] u8 {
    filename := tprint("%/%", #filepath, name);
    content, success := read_entire_file(filename);

    if !success log_error(tprint("Unable to read file '%'!\n", filename));
    return xx content;
}

//
// Runtime stuff:
//
// Largely a copy of the Simp example, but with some setup wherein we decompress the bitmap
// from memory, then put it into a texture map that we can draw using the GPU. Each frame,
// we draw this texture map at full-screen size.
//
my_window: Window_Type;
window_width  : s32 = 1920;
window_height : s32 = 1080;

bitmap:  Simp.Bitmap;
texture: Simp.Texture;

main :: () {
    #if OS == .WINDOWS {
        Windows :: #import "Windows";
        Windows.SetProcessDPIAware();

        // Windows is very bad at thread-switching by default unless you do this. Sad.
        Windows.timeBeginPeriod(1);
    }

    my_window = create_window(window_width, window_height, "A Window");

    Simp.set_render_target(my_window);
    Simp.bitmap\_load_from_memory(*bitmap, image);
    Simp.texture_load_from_bitmap(*texture, *bitmap);
    print("Texture: %\n", texture);
    
    quit := false;
    while !quit {
        Input.update_window_events();

        for Input.get_window_resizes() {
            Simp.update_window(it.window);
            
            if it.window == my_window {
                should_reinit := (it.width != window_width) || (it.height != window_height);
                
                window_width  = it.width;
                window_height = it.height;
            }
        }

        for Input.events_this_frame {
            if it.type == .QUIT then quit = true;

            if it.type == {
              case .KEYBOARD;
                if it.key_pressed && it.key_code == .ESCAPE {
                    quit = true;
                }
            }
        }

        draw_one_frame();
        
        sleep_milliseconds(10);
        reset_temporary_storage();
    }
}

draw_one_frame :: () {
    Simp.clear_render_target(.15, .08, .08, 1);
    
    Simp.set_shader_for_images(*texture);
    
    p0 := Vector2.{0, 0};
    p1 := Vector2.{xx window_width, 0};
    p2 := Vector2.{xx window_width, xx window_height};
    p3 := Vector2.{0, xx window_height};

    c := Vector4.{1, 1, 1, 1};
    
    Simp.immediate_quad(p0, p1, p2, p3, c);

    Simp.swap_buffers(my_window);
}

Simp  :: #import "Simp";
Input :: #import "Input";

#import "Window_Creation";
#import "Math";
#import "Basic";
#import "Compiler";
#import "File";
#import "stb_image";

#import "Windows_Resources";

#run {
    disable_runtime_console();
    set_build_options_dc(.{
        output_executable_name = "app",
    });
}

// vim: nonu
