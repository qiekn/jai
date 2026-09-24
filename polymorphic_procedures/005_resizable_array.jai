Basic :: #import "Basic";
print :: Basic.print;

main :: () {
    array_add :: (array: *[..] $T, item: T) {
        // Make sure we have enough room to add at least one more item.
        Basic.maybe_grow(xx array, size_of(T));
        // Put the item into memory.
        (array.data + array.count).* = item;
        // Increase the count of the number of items held by this array.
        array.count += 1;
    }

    numbers: [..] int;

    array_add(*numbers, 22);
    array_add(*numbers, 105);

    print("numbers: %\n", numbers);
}
