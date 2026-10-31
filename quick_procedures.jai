#import "Basic";
#import "Print_Vars";

apply :: (nums: []$T, proc: (T) -> T) -> []T {
    result : [..]T;
    for nums array_add(*result, proc(it));
    return result;
}

main :: () {
    a := int.[1, 2, 3, 4, 5, 6, 7, 8];

    //
    // x => x + 100
    //
    // This is a quick procedure: for each x it works on, it returns x + 100. 
    //
    b := apply(a, x => x * x);

    print_vars(b); // [1, 4, 9, 16, 25, 36, 49, 64]

    array_free(b);
}
