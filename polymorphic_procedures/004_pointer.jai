#import "Basic";

my_swap :: (a: *$T, b: *T) {
    temp := a.*;
    a.* = b.*;
    b.* = temp;
}

main :: () {
    a, b := "Sailor!", "Hello,";
    my_swap(*a, *b);

    print("% %\n", a, b); // Hello, Sailor!
}
