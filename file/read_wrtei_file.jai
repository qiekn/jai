#import "Basic";
#import "File";

main :: () {
    // READ
    text := read_entire_file("input.txt");
    print("%\n", text);

    // WRITE
    builder: String_Builder;

    append(*builder, "You had me at hello\n");
    append(*builder, "I love you I know");

    write_entire_file("output.txt", *builder);
}
