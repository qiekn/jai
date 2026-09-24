#import "Basic";

sum :: (array: [] $T) -> T {
    result: T;
    for array {
        result += it;
    }
    return result;
}

main :: () {
    arr: [4] int;
    arr[0] = 45;
    arr[1] = 42;
    arr[2] = 43;
    arr[3] = 100;
    print("The sum over the array of ints is: %\n", sum(arr));

    arr2: [4] float32;
    arr2[0] = 4.5;
    arr2[1] = 4.2;
    arr2[2] = 4.3;
    arr2[3] = 10.0;
    print("The sum over the array of floats is: %\n", sum(arr2));
}
