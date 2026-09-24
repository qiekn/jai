#import "Basic";
#import "Print_Vars";

apply :: (a: []int, proc: (int) -> int) -> []int {
    result : [..]int;
    for a {
        array_add(*result, proc(a[it_index]));
    }
    return result;
}

main :: () {
    a := int.[1, 2, 3, 4, 5, 6, 7, 8];

    //
    // (x) => x + 100
    // 
    // This is a lambda: for each x it works on, it returns x + 100. 
    //
    b := apply(a, (x) => x + 100);

    print_vars(b);
    // b = [101, 102, 103, 104, 105, 106, 107, 108] ([] s64)

    array_free(b);
}
