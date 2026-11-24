#!/bin/env jai

output_name :: "test";
output_path :: ".";

#run {
    defer log("first.jai exited gracefully!");

    set_build_options_dc(.{do_output=false});
    make_directory_if_it_does_not_exist(output_path);

    w := compiler_create_workspace("Target Program");

    options := get_build_options(w);
    options.output_executable_name = output_name;
    options.output_path            = output_path;
    options.text_output_flags      = 0;
    options.emit_debug_info        = .NONE;
    set_build_options(options, w);

    compiler_begin_intercept(w);
    add_build_file("main.jai", w);
    message_loop();
    compiler_end_intercept(w);
}

all_notes : [..] Note;

Note :: struct {
    name : string;
    decl : *Code_Declaration;
}

print_my_notes :: () {
    ignores := string.["NoProfile", "PrintLike"];

    max_length := 0;
    for all_notes { max_length = max(it.name.count, max_length); }

    quick_sort(all_notes, (a, b) => compare_strings(a.name, b.name));

    print("/* ------------------------ all my notes begin ------------------------ */\n");
    for note: all_notes {
        for ignores if note.name == it then continue note;
        print("@%", note.name);
        padding := max_length - note.name.count + 1;
        for 1..padding print(" ");
        print("➜ %\n", note.decl.name);
    }
    print("/* ------------------------ all my notes end   ------------------------ */\n");
}

message_loop :: () {
    while true {
        message := compiler_wait_for_message();
        if message.kind == {
            case .TYPECHECKED;
                typechecked := cast(*Message_Typechecked) message;
                for decl : typechecked.procedure_headers {
                    header := decl.expression;
                    notes  := header.notes;
                    if !notes.count continue;
                    for notes add_procedure_with_order(header.name, it.text, decl.expression);
                }

                // @TEST print all notes
                for decl : typechecked.declarations {
                    notes := decl.expression.notes;
                    if notes.count then for notes array_add(*all_notes, .{it.text, decl.expression});
                }

            case .PHASE;
                phase := cast(*Message_Phase) message;
                if phase.phase == .TYPECHECKED_ALL_WE_CAN {
                    if !generated_code {
                        generate_code(message.workspace);
                        generated_code = true;
                    }
                }
            case .COMPLETE;
                msg := cast(*Message_Complete) message;
                if msg.error_code == .NONE {
                    print_my_notes();

                    application := tprint("%%/%", #filepath, output_path, output_name);
                    run_command(application);
                }
                break;
        }
    }
}

// ----------------------------------------------------------------------------: gencode

generated_code := false;

Proc :: struct {
    name : string;
    order := S64_MAX;

    header : *Code_Procedure_Header;
}

procedures_run_once        : [..] Proc;
procedures_run_every_frame : [..] Proc;

add_procedure_with_order :: (name : string, text : string, header : *Code_Procedure_Header) {
    _, note, number := split_from_right(text, ":");

    proc : Proc;
    proc.name  = name;
    proc.order = to_integer(number);
    proc.header = header;

    if note == {
        case "define"; #through;
        case "init";
            array_add(*procedures_run_once, proc);
        case "simulate"; #through;
        case "update";
            array_add(*procedures_run_every_frame, proc);
    }
}


RUN_ONCE_STRING :: #string END
auto_run_once :: () {
    %1;
}
END

RUN_EVERY_FRAME_STRING :: #string END
auto_run_every_frame :: () {
    %1;
}
END

generate_code :: (w: Workspace) {
    Gen :: (procs : [..] Proc, $template : string) #expand {
        builder : String_Builder;

        quick_sort(procs, compare_procedure);
        for procs {
            print_to_builder(*builder, sprint("%();\n", it.name));
        }
        lines := builder_to_string(*builder);
        build_string := sprint(template, lines);
        add_build_string(build_string, `w);
    }

    Gen(procedures_run_once, RUN_ONCE_STRING);
    Gen(procedures_run_every_frame, RUN_EVERY_FRAME_STRING);
}

compare_procedure :: (a : Proc, b : Proc) -> int {
    if a.order == b.order {
        return compare_strings(a.name, b.name);
    } else {
        less := a.order < b.order;
        return ifx less then -1 else 1;
    }
}

#import "Compiler";
#import "Basic";
#import "File";
#import "Process";
#import "Math";
#import "String";
#import "Sort";
#import "Print_Vars";

#import "Program_Print";
