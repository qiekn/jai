main :: () {
    watcher: File_Watcher(string);

    init(*watcher, file_change_callback, *"cowabunga", events_to_watch = .MODIFIED);
    defer deinit(watcher);

    add_directories(*watcher, "data");

    while true {
        changed := process_changes(*watcher);

        sleep_milliseconds(100);
    }
}

file_change_callback :: (watcher: *File_Watcher(string), change: *File_Change, user_data: *string) {
    log("Change for path %: % (user_data points to %)", change.full_path, change.events, user_data.*);
}

#import "Basic";
#import "File_Watcher";
