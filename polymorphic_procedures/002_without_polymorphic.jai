#import "Basic";

convert :: (arg: s32) {
    print("% of type %, cast to bool is %\n", arg, type_of(arg), cast(bool) arg);
}

convert :: (arg: float) {
    print("% of type %, cast to bool is %\n", arg, type_of(arg), cast(bool) arg);
}

convert :: (arg: string) {
    print("% of type %, cast to bool is %\n", arg, type_of(arg), cast(bool) arg);
}

convert :: (arg: []int) {
    print("% of type %, cast to bool is %\n", arg, type_of(arg), cast(bool) arg);
}

convert :: (arg: []bool) {
    print("% of type %, cast to bool is %\n", arg, type_of(arg), cast(bool) arg);
}

main :: () {
    convert(0);
    convert(1);
    convert(cast(s8) -37);

    convert(69105.33);
    convert("Hello, Sailor!");

    arr := int.[1, 2, 3, 4, 5];
    convert(arr);

    arr2 := bool.[true, false, true, false];
    convert(arr2);
}
