#import "Basic";

Audio_Buffer :: struct {
    samples: [256] float #align 64;
    sample_count: s32;
} #no_padding

Object :: struct {
  member: int #align 64;
}

global_var: [100] int #align 64;

main :: () {
    assert(cast(int)(*global_var) % 64 == 0); // 验证指针地址是否能被 64 整除

    object := New(Object);
    assert(cast(int)(object) % 64 == 0); // 同理
    free(object);

    big : [16] u8 #align 64;
    big[0] = 10;
    big[1] = 20;
    print("size = %, value = %\n", size_of(type_of(big)), formatInt(big[0], base = 2));
    // => size = 16, value = 1010
}
