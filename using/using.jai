#!/bin/env jai

#import "Basic";
#import "String";
#import "Print_Vars";

Vector2   :: struct { x, y : float;       }
Vector4   :: struct { x, y, z, w : float; }
Rectangle :: struct { x, y, w, h : float; }

Data :: struct {
    a, b, c, d : float;

    #overlay (a) using pos : Vector2;
    #overlay (a)      rect : Rectangle;
    #overlay (a) component : [4] float;

    #overlay (c) w : float;
    #overlay (d) h : float;
}

prefix :: (members : [] string, name : string) {
    log("data: %", members); // log original member names

    prefix := name;
    for * members {
        name := copy_string(it.*,,temp);

        // if name.count > 4 continue; // this will ignore 'component'

        if name == {
            case "w"; name = "width";
            case "h"; name = "height";
        }

        it.* = tprint("%_%", prefix, name);
        log("new name: %\n", it.*);
    }
}

main :: () {
    log("\n-------------runtime-------------");

    data : Data;
    using,map(#bake_arguments prefix(name="qiekn")) data;
    using,map(#bake_arguments prefix(name="hello")) data;
    using,only(x,y)   data;
    using,except(x,y) data;

    print_vars(qiekn_x, qiekn_y, qiekn_width, qiekn_height);
    print_vars(hello_width, hello_height);
    print_vars(hello_rect);

    print("rect: %\n\n", formatStruct(qiekn_rect,1,true));
    print("data: %\n", formatStruct(data, 1, true));
}

#run log("-----------compile-time----------");

