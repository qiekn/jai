#import "Basic";

add :: (p: $T, q: $T) -> T {
    return p + q;
}

main :: () {
    integer_1: int = 1;
    integer_2: int = 2;
    integer_3 := add(integer_1, integer_2);

    print("integer_3 is %\n", integer_3);
    proc :: #procedure_of_call add(integer_1, integer_2);
    print("type_of(proc) is %\n", type_of(proc)); // => type_of(proc) is procedure (s64, s64) -> s64

    print("\n");

    float_1: float = 1;
    float_2: float = 2;
    float_3 := add(float_1, float_2);

    print("float_3 is %\n", float_3);
    proc2 :: #procedure_of_call add(float_1, float_2);
    print("type_of(proc2) is %\n", type_of(proc2)); // => type_of(proc2) is procedure (float32, float32) -> float32
}
