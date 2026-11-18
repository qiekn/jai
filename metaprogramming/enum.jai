Games :: enum {
   Braid;               // 0
   TheWitness;          // 1
   Overwatch;           // 2
   Inside;              // 3
   StephensSausageRoll; // 4
   Enigmash;            // 5
   Zork;                // 6
}

COUNT :: #run enum_highest_value(Games) + 1;

main :: () {
   names := enum_names(Games);
   low, high := enum_range(Games);

   log("names: %", names);
   log("counut: %, range: (%, %)", COUNT, low, high);
}

#import "Basic";
