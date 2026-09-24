//
// Guess the right number to compile
//
// Origianl Author : Jack Lee
// Created Time  : May 1, 2026
// Last Modified : May 1, 2026
// Github Linksi : https://github.com/kcajeel/guessing_game

are_you_winning_player := false;

#run {
    check();
    main();
}

check :: () {
    number := give_me_a_random_number();

    print("Guess a number from 0 to 10!\n");

    stdin = GetStdHandle(STD_INPUT_HANDLE);

    while !are_you_winning_player {
        input_number, success := parse_int(*input());

        if !success {
            print("What did you input????\n");
            continue;
        }

        if input_number == number {
            print("You won!\n\n");
            are_you_winning_player = true;
            break;
        }

        if input_number > number {
            print("Too high! Try again.\n");
        } else {
            print("Too low! Try again.\n");
        }
    }
}

give_me_a_random_number :: () -> int {
    random_seed(current_time_consensus().low);    
    random: int = cast(int) (random_get_within_range(0, 10) + 0.5);
    return random;
}

main :: () {
    print("Hello, Sailor!\n");
}

//
// Code below this line is borrowed from:
//
// https://github.com/Ivo-Balbaert/The_Way_to_Jai/blob/main/book/19C_Get_console_input.md
//

#import "Windows";

kernel32 :: #system_library "kernel32";

stdin, stdout: HANDLE;

ReadConsoleW  :: (
    hConsoleHandle: HANDLE, 
    buff : *u8, 
    chars_to_read : s32,  
    chars_read : *s32, 
    lpInputControl := *void 
) -> bool #foreign kernel32;

input :: () -> string {
    MAX_BYTES_TO_READ :: 1024;
    temp : [MAX_BYTES_TO_READ] u8;
    result: string = ---;
    bytes_read : s32;
    
    if !ReadConsoleW( stdin, temp.data, xx temp.count, *bytes_read )
        return "";

    result.data  = alloc(bytes_read);
    result.count = bytes_read;
    memcpy(result.data, temp.data, bytes_read);
    return result;
}

#import "Basic";
#import "Random";
#import "String";
