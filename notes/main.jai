#import "Basic";

#placeholder auto_run_once;
#placeholder auto_run_every_frame;

main :: () {
    auto_run_once();

    quit := false;
    while !quit {
        auto_run_every_frame();
        sleep_milliseconds(1000);
    }
}

// ----------------------------------------------------------------------------: yours

number : int;

write_note_at_declaration : string; @"note string test ,.!@#$% (x) // Cowabunga"

init_fonts :: () {
    log("init all my fonts");
} @init:1

test_1 :: () { log("test_1"); } @init:101
test_2 :: () { log("test_2"); } @init:102
test_3 :: () { log("test_3"); } @init:103 @hello @sailor

run_once :: () {
    number = 1;
    log("Hello, Sailor!");
    log("number is %\n", number);
} @init:200


run_every_frame :: () {
    number += 1;
    log("number is %\n", number);
} @update

// say_hello_to_me :: () {
//     log("hello, qiekn!");
// } @update


// ----------------------------------------------------------------------------: todo

ls :: () { } @command

switch_level :: (index : int) { } @command
