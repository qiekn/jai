//
// It makes sense to look at add_global_data before looking at this example.
//
// add_data_segment is for use when you would like to create an actual named segment of data
// in the output executable. You create the segment, then you can use add_global_data
// to put data into the segment.
//
// The signature of the procedure is:
//
//     add_data_segment :: (section_name: string, characteristics := Data_Segment_Characteristics.READ | .WRITE, alignment: s32 = 16, w: Workspace = -1) -> (segment: *Data_Segment, actual_segment_will_be_created: bool) #compiler;
//
// On some platforms there may be weird complications when dealing with certain
// configurations. For example, due to Linux's very unfortunate dynamic linking, you can't
// really have a readonly data segment that contains pointers inside a dynamic library.
// (Right now add_global_data does not let you designate pointers but we plan to add this).
//
// For these reasons, add_data_segment returns the actual_data_segment_will_be_created value.
// If this value is false, then you can expect that there will not be an actual separate
// data segment inside the object file with the exact characteristics you chose.
// You will still be able to put the data into the executable, but it will not be as
// clearly delineated and analyzable with external tools. The compiler will still pack
// all data within one Data_Segment contiguously, so you can still use add_data_segment
// to control data locality, and if you want to detect a contiguous range of data inside
// an executable without a specific named section, you could store a pattern at the beginning
// and end of the Data_Segment and scan for that pattern from external tools.
//
// Data segment information is tranditionally stored in object files in "sections", and
// each operating system's executable format has different constraints on the name of
// a section. In the backend we do our best to translate the section_name argument
// into something that is acceptable on the target platform. It would be a good idea
// for a future version of add_data_segment to return the remapped section name, but
// we don't do that at this time.
//

numbers :: #run make_the_numbers();
pointer :: #run numbers.data;

main :: () {
    N :: numbers.count;
    print("There are % numbers.\n", N);

    sum := 0;
    for numbers  sum += it;

    print("Their sum is %.\n", sum);
    print("Mr. Gauss says the sum should be %.\n", (N * (N+1)) / 2);


    // Ensure that pointer constant 'pointer' stays mapped to the same
    // location as numbers.data, even after the executable is written.
    print("numbers.data is %\n", numbers.data);
    print("pointer is %\n",      pointer);

    assert(pointer == numbers.data);

    print("numbers: %\n", numbers);
}

just_return :: (x: $T) -> T { return x; }

make_the_numbers :: () -> [] u8 {
    // Let's make some data we want to put into the target program.
    numbers: [100] u8;
    for 1..numbers.count  numbers[it-1] = cast(u8) it;

    // Let's create a read-only segment to contain this data.
    segment_name := "our_numbers";
    segment, actually := add_data_segment(segment_name, .READ);

    if actually {
        log("Data segment '%' will be present as expected in the target program.", segment_name);
    } else {
        log("Data segment '%' will not be present in the target program, or will not have the requested characteristics.", segment_name);
    }

    // We use .USER_SEGMENT and pass the pointer to the segment we created.
    result := add_global_data(numbers, .USER_SEGMENT, segment);

    // add_global_data copied the values from 'numbers' into the result memory,
    // so we can return the result memory, which exists globally.
    return result;
}


#import "Basic";
#import "Compiler";
