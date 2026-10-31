#!/bin/env jai

#import "Basic";
#import "Ico_File";
#import "Windows_Resources";
#import "Compiler";

#run {
    set_build_options_dc(.{do_output=false});

    executable_filename := tprint("%/app.exe",  #filepath);
    icon\     _filename := tprint("%/icon.png", #filepath);

    icon := create_ico_file_from_bitmap_filename(icon_filename);

    if !set_icon_by_data(executable_filename, icon) {
        log_error(tprint("Could not embed the application icon in %.", executable_filename));
        return;
    }
}
