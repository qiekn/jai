#import "Basic";
#import "File";

#import "String";


main :: () {
    // READ
    content := read_entire_file("input.txt");

    lines := split(content, "\n");

    for line : lines {
        if line.count == 0 then continue;

        if line[0] == #char "!" {
            advance(*line, 1);
            new_line := eat_spaces(line);
            _, command, rhs := split_from_left(new_line, " ");

            if command == {
                case "echo";
                    print("[echo]: %\n", rhs);
                case "print";
                    print("[print]: %\n", rhs);
                case "float";
                    print("[float]: %\n", rhs);
                    value := string_to_float(rhs);
                    print("type of value is %\n", type_of(value));
                case;
                    print("********** COMMAND **********: %\n", line);
            }
        }
    }

    /*
    // WRITE
    builder: String_Builder;

    append(*builder, "You had me at hello\n");
    append(*builder, "I love you I know");

    write_entire_file("output.txt", *builder);
    */
}
