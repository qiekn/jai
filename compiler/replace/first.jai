#!/bin/env jai

#import "Compiler";
#import "Basic";
#import "File";
#import "Process";
#import "Print_Vars";

OUTPUT_DIR  :: "bin";
OUTPUT_NAME :: "my_app";

#run {
    // Workspace
    w := compiler_create_workspace("My Target program");
    if !w {
        log_error("Hey, we failed to create our workspace '%'", w);
        return;
    }

    // Build Options
    options := get_build_options(w);

    options.output_executable_name = OUTPUT_NAME;
    options.backend                = .X64;
    options.output_path            = OUTPUT_DIR;
    options.text_output_flags      = 0;
    options.emit_debug_info        = .NONE;

    if !make_directory_if_it_does_not_exist(OUTPUT_DIR) {
        log_error("Hey, we failed to create a bin directory! You need to check it out!");
        return;
    }

    set_optimization(*options, .DEBUG);

    set_build_options(options, w);

    // Talk with compiler
    compiler_begin_intercept(w);
    add_build_file("main.jai", w);
    message_loop();
    compiler_end_intercept(w);

    // During Compile Time
    set_build_options_dc(.{do_output=false});
}

message_loop :: () #expand {
  while true {
    message := compiler_wait_for_message();
    if message.kind == {
      case .TYPECHECKED;
        tc_message := cast(*Message_Typechecked) message;
        for tc : tc_message.procedure_bodies {
          body := tc.expression;
          if body.body_flags & .ALREADY_MODIFIED continue;

          // Hello, Sailor!
          if body.header.name == "custom_string" {
            new_statements : [..] *Code_Node;
            array_add(*new_statements, make_return_node());

            body.block.statements = new_statements;
            compiler_modify_procedure(`w, body);
            break;
          }

          if body.header.name == "main" {
              new_statements : [..] *Code_Node;
              old_statements := body.block.statements;

              for 0..new_statements.count-1 {
                  array_add(*new_statements, old_statements[it]);
              }

              array_add(*new_statements, make_log_node("Qiekn!"));

              body.block.statements = new_statements;
          }
        }

      case .COMPLETE;
        complete := cast(*Message_Complete) message;
        if complete.error_code == .NONE {
            run_command(tprint("%/%/%", #filepath, OUTPUT_DIR, OUTPUT_NAME));
        }
        break;
    }
  }
}

// return "Hello, Sailor!\n";
make_return_node :: () -> *Code_Node {
    res := New(Code_Return);

    arg : Code_Argument;
    arg.expression = make_string_literal("Hello, Sailor!\n");
    arg.name = null;

    arguments : [..] Code_Argument;
    array_add(*arguments, arg);

    res.arguments_unsorted = arguments;
    return res;
}

// log("Qiekn!");
make_log_node :: (text : string) -> *Code_Node {
    res := New(Code_Procedure_Call);

    identity := New(Code_Ident);
    identity.name = "log";
    res.procedure_expression = identity;

    arg : Code_Argument;
    arg.expression = make_string_literal(text);
    arg.name = null;

    arguments : [..] Code_Argument;
    array_add(*arguments, arg);

    res.arguments_unsorted = arguments;
    return res;
}
