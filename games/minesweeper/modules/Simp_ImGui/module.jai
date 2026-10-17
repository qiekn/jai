#scope_module

#import "Basic";
#import "File_Utilities";
#import "GL";
#import "Math";
#import "Window_Creation";

ImGui :: #import "ImGui";
Input :: #import "Input";

#load "theme.jai";

#if OS == .WINDOWS {
  imgui_user32 :: #system_library "user32";
  GetDpiForWindow :: (hwnd: Window_Type) -> u32 #foreign imgui_user32;
}

// ----------------------------------------------------------------------------: ImGui state

IMGUI_BASE_DPI :: 96.0;
IMGUI_DEFAULT_SCALE :: 1.6;

imgui_context: *ImGui.ImGuiContext;
imgui_time: float64;
imgui_ui_scale: float;
imgui_font_texture: GLuint;
imgui_shader_handle: GLuint;
imgui_vert_handle: GLuint;
imgui_frag_handle: GLuint;
imgui_attrib_location_tex: GLint;
imgui_attrib_location_proj_mtx: GLint;
imgui_attrib_location_position: GLuint;
imgui_attrib_location_uv: GLuint;
imgui_attrib_location_color: GLuint;
imgui_vbo_handle: GLuint;
imgui_vao_handle: GLuint;
imgui_elements_handle: GLuint;

// ----------------------------------------------------------------------------: Public API

#scope_export

using ImGui;

init :: () {
  imgui_context = ImGui.CreateContext();

  io := ImGui.GetIO();
  io.IniFilename = null;
  io.BackendPlatformName = "dooots_in_jai_input";
  io.BackendRendererName = "dooots_in_jai_simp_gl";
  io.ConfigFlags_ |= ImGui.ConfigFlags.NavEnableKeyboard;

  imgui_configure_scale(IMGUI_DEFAULT_SCALE, force=true);
}

shutdown :: () {
  imgui_invalidate_device_objects();

  if imgui_context {
    ImGui.DestroyContext(imgui_context);
    imgui_context = null;
  }
}

process_event :: (event: Input.Event) {
  if !imgui_context return;

  io := ImGui.GetIO();

  if event.type == {
    case .MOUSE_WHEEL;
    wheel := 0.0;
    if event.typical_wheel_delta != 0 {
      wheel = cast(float) event.wheel_delta / cast(float) event.typical_wheel_delta;
    } else if event.wheel_delta != 0 {
      wheel = ifx event.wheel_delta > 0 then 1.0 else -1.0;
    }
    io.AddMouseWheelEvent(io, 0.0, wheel);

    case .KEYBOARD;
    down := event.key_pressed != 0;

    if event.key_code == .MOUSE_BUTTON_LEFT {
      io.AddMouseButtonEvent(io, 0, down);
    } else if event.key_code == .MOUSE_BUTTON_RIGHT {
      io.AddMouseButtonEvent(io, 1, down);
    } else if event.key_code == .MOUSE_BUTTON_MIDDLE {
      io.AddMouseButtonEvent(io, 2, down);
    } else {
      key := imgui_key_from_input(event.key_code);
      if key != .None {
        io.AddKeyEvent(io, key, down);
      }
    }

    imgui_update_modifier_keys();

    case .TEXT_INPUT;
    if event.utf32 != 0 {
      io.AddInputCharacter(io, event.utf32);
    }
  }
}

new_frame :: (window: Window_Type, width: s32, height: s32) {
  target_scale := imgui_get_ui_scale(window, width, height);
  imgui_configure_scale(target_scale);

  if !imgui_font_texture {
    imgui_create_device_objects();
  }

  io := ImGui.GetIO();
  io.DisplaySize = .{xx width, xx height};
  io.DisplayFramebufferScale = .{1, 1};

  now := seconds_since_init();
  if imgui_time > 0 {
    io.DeltaTime = cast(float)(now - imgui_time);
    if io.DeltaTime <= 0.0 io.DeltaTime = 1.0 / 60.0;
  } else {
    io.DeltaTime = 1.0 / 60.0;
  }
  imgui_time = now;

  mx, my, mouse_success := get_mouse_pointer_position(window, false);
  if mouse_success {
    io.AddMousePosEvent(io, xx mx, xx my);
  } else {
    io.AddMousePosEvent(io, -FLOAT32_MAX, -FLOAT32_MAX);
  }

  imgui_update_modifier_keys();

  ImGui.NewFrame();
}

render :: () {
  ImGui.Render();
  imgui_render_draw_lists(ImGui.GetDrawData());
}

get_ui_scale :: () -> float {
  return imgui_ui_scale;
}

wants_default_cursor :: () -> bool {
  return ImGui.IsWindowHovered(.AnyWindow);
}

// ----------------------------------------------------------------------------: Frame scale

#scope_module

imgui_get_ui_scale :: (window: Window_Type, width: s32, height: s32) -> float {
  #if OS == .WINDOWS {
    dpi := GetDpiForWindow(window);
    if dpi >= cast(u32) IMGUI_BASE_DPI {
      return max(IMGUI_DEFAULT_SCALE, cast(float) dpi / IMGUI_BASE_DPI);
    }
  }

  width_scale  := cast(float) width  / 1920.0;
  height_scale := cast(float) height / 1080.0;
  scale := min(width_scale, height_scale);
  return clamp(scale, IMGUI_DEFAULT_SCALE, 3.0);
}

imgui_configure_scale :: (ui_scale: float, force := false) {
  ui_scale = clamp(ui_scale, IMGUI_DEFAULT_SCALE, 3.0);

  if !force && imgui_ui_scale > 0.0 && abs(imgui_ui_scale - ui_scale) < 0.01 {
    return;
  }

  imgui_ui_scale = ui_scale;
  load_font(ui_scale);
  apply_theme(ui_scale);
  imgui_invalidate_device_objects();
}

// ----------------------------------------------------------------------------: Input mapping

imgui_key_from_input :: (key_code: Input.Key_Code) -> ImGui.Key {
  if key_code == {
    case .TAB;         return .Tab;
    case .ARROW_LEFT;  return .LeftArrow;
    case .ARROW_RIGHT; return .RightArrow;
    case .ARROW_UP;    return .UpArrow;
    case .ARROW_DOWN;  return .DownArrow;
    case .PAGE_UP;     return .PageUp;
    case .PAGE_DOWN;   return .PageDown;
    case .HOME;        return .Home;
    case .END;         return .End;
    case .INSERT;      return .Insert;
    case .DELETE;      return .Delete;
    case .BACKSPACE;   return .Backspace;
    case .SPACEBAR;    return .Space;
    case .ENTER;       return .Enter;
    case .ESCAPE;      return .Escape;
    case .CTRL;        return .LeftCtrl;
    case .SHIFT;       return .LeftShift;
    case .ALT;         return .LeftAlt;
    case .CMD;         return .LeftSuper;
    case .F1;          return .F1;
    case .F2;          return .F2;
    case .F3;          return .F3;
    case .F4;          return .F4;
    case .F5;          return .F5;
    case .F6;          return .F6;
    case .F7;          return .F7;
    case .F8;          return .F8;
    case .F9;          return .F9;
    case .F10;         return .F10;
    case .F11;         return .F11;
    case .F12;         return .F12;
  }

  value := cast(s32) key_code;
  if value >= #char "A" && value <= #char "Z" {
    return cast(ImGui.Key)(cast(s32) ImGui.Key.A + value - #char "A");
  }

  if value >= #char "0" && value <= #char "9" {
    return cast(ImGui.Key)(cast(s32) ImGui.Key._0 + value - #char "0");
  }

  return .None;
}

imgui_update_modifier_keys :: () {
  io := ImGui.GetIO();

  ctrl  := (Input.input_button_states[Input.Key_Code.CTRL]  & .DOWN) != 0;
  shift := (Input.input_button_states[Input.Key_Code.SHIFT] & .DOWN) != 0;
  alt   := (Input.input_button_states[Input.Key_Code.ALT]   & .DOWN) != 0;
  super := (Input.input_button_states[Input.Key_Code.CMD]   & .DOWN) != 0;

  io.AddKeyEvent(io, .ModCtrl, ctrl);
  io.AddKeyEvent(io, .ModShift, shift);
  io.AddKeyEvent(io, .ModAlt, alt);
  io.AddKeyEvent(io, .ModSuper, super);

  io.KeyCtrl = ctrl;
  io.KeyShift = shift;
  io.KeyAlt = alt;
  io.KeySuper = super;
}

// ----------------------------------------------------------------------------: Renderer

imgui_render_draw_lists :: (draw_data: *ImGui.ImDrawData) #c_call {
  if !draw_data return;

  io := ImGui.GetIO();
  fb_width := io.DisplaySize.x * io.DisplayFramebufferScale.x;
  fb_height := io.DisplaySize.y * io.DisplayFramebufferScale.y;
  if fb_width <= 0 || fb_height <= 0 return;

  draw_data.ScaleClipRects(draw_data, *io.DisplayFramebufferScale);

  last_active_texture: GLenum;        glGetIntegerv(GL_ACTIVE_TEXTURE, xx *last_active_texture);
  last_program: GLuint;               glGetIntegerv(GL_CURRENT_PROGRAM, xx *last_program);
  last_texture: GLuint;               glGetIntegerv(GL_TEXTURE_BINDING_2D, xx *last_texture);
  last_sampler: GLuint;               glGetIntegerv(GL_SAMPLER_BINDING, xx *last_sampler);
  last_array_buffer: GLuint;          glGetIntegerv(GL_ARRAY_BUFFER_BINDING, xx *last_array_buffer);
  last_element_array_buffer: GLuint;  glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, xx *last_element_array_buffer);
  last_vertex_array: GLuint;          glGetIntegerv(GL_VERTEX_ARRAY_BINDING, xx *last_vertex_array);
  last_polygon_mode: [2]GLuint;       glGetIntegerv(GL_POLYGON_MODE, xx last_polygon_mode.data);
  last_viewport: [4]GLint;            glGetIntegerv(GL_VIEWPORT, last_viewport.data);
  last_scissor_box: [4]GLint;         glGetIntegerv(GL_SCISSOR_BOX, last_scissor_box.data);
  last_blend_src_rgb: GLenum;         glGetIntegerv(GL_BLEND_SRC_RGB, xx *last_blend_src_rgb);
  last_blend_dst_rgb: GLenum;         glGetIntegerv(GL_BLEND_DST_RGB, xx *last_blend_dst_rgb);
  last_blend_src_alpha: GLenum;       glGetIntegerv(GL_BLEND_SRC_ALPHA, xx *last_blend_src_alpha);
  last_blend_dst_alpha: GLenum;       glGetIntegerv(GL_BLEND_DST_ALPHA, xx *last_blend_dst_alpha);
  last_blend_equation_rgb: GLenum;    glGetIntegerv(GL_BLEND_EQUATION_RGB, xx *last_blend_equation_rgb);
  last_blend_equation_alpha: GLenum;  glGetIntegerv(GL_BLEND_EQUATION_ALPHA, xx *last_blend_equation_alpha);
  last_enable_blend :=                glIsEnabled(GL_BLEND);
  last_enable_cull_face :=            glIsEnabled(GL_CULL_FACE);
  last_enable_depth_test :=           glIsEnabled(GL_DEPTH_TEST);
  last_enable_scissor_test :=         glIsEnabled(GL_SCISSOR_TEST);

  glActiveTexture(GL_TEXTURE0);
  glEnable(GL_BLEND);
  glBlendEquation(GL_FUNC_ADD);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glDisable(GL_CULL_FACE);
  glDisable(GL_DEPTH_TEST);
  glEnable(GL_SCISSOR_TEST);
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
  glViewport(0, 0, xx fb_width, xx fb_height);

  push_context {
    ortho_projection := orthographic_projection_matrix(0, io.DisplaySize.x, io.DisplaySize.y, 0, 0, 1);
    ortho_projection = transpose(ortho_projection);

    glUseProgram(imgui_shader_handle);
    glUniform1i(imgui_attrib_location_tex, 0);
    glUniformMatrix4fv(imgui_attrib_location_proj_mtx, 1, GL_FALSE, xx *ortho_projection);
    glBindVertexArray(imgui_vao_handle);
    glBindSampler(0, 0);

    for n: 0..draw_data.CmdListsCount - 1 {
      cmd_list := draw_data.CmdLists[n];
      idx_buffer_offset: *ImGui.ImDrawIdx;

      glBindBuffer(GL_ARRAY_BUFFER, imgui_vbo_handle);
      glBufferData(GL_ARRAY_BUFFER, cmd_list.VtxBuffer.Size * size_of(ImGui.ImDrawVert), cmd_list.VtxBuffer.Data, GL_STREAM_DRAW);

      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, imgui_elements_handle);
      glBufferData(GL_ELEMENT_ARRAY_BUFFER, cmd_list.IdxBuffer.Size * size_of(ImGui.ImDrawIdx), cmd_list.IdxBuffer.Data, GL_STREAM_DRAW);

      for cmd_i: 0..cmd_list.CmdBuffer.Size - 1 {
        pcmd := *cmd_list.CmdBuffer.Data[cmd_i];
        if pcmd.UserCallback {
          pcmd.UserCallback(cmd_list, pcmd);
        } else {
          glBindTexture(GL_TEXTURE_2D, xx pcmd.TextureId);
          glScissor(xx pcmd.ClipRect.x,
                    xx (fb_height - pcmd.ClipRect.w),
                    xx (pcmd.ClipRect.z - pcmd.ClipRect.x),
                    xx (pcmd.ClipRect.w - pcmd.ClipRect.y));
          glDrawElements(GL_TRIANGLES, pcmd.ElemCount, GL_UNSIGNED_SHORT, idx_buffer_offset);
        }

        idx_buffer_offset += pcmd.ElemCount;
      }
    }
  }

  glUseProgram(last_program);
  glBindTexture(GL_TEXTURE_2D, last_texture);
  glBindSampler(0, last_sampler);
  glActiveTexture(last_active_texture);
  glBindVertexArray(last_vertex_array);
  glBindBuffer(GL_ARRAY_BUFFER, last_array_buffer);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, last_element_array_buffer);
  glBlendEquationSeparate(last_blend_equation_rgb, last_blend_equation_alpha);
  glBlendFuncSeparate(last_blend_src_rgb, last_blend_dst_rgb, last_blend_src_alpha, last_blend_dst_alpha);
  if last_enable_blend        glEnable(GL_BLEND);         else glDisable(GL_BLEND);
  if last_enable_cull_face    glEnable(GL_CULL_FACE);     else glDisable(GL_CULL_FACE);
  if last_enable_depth_test   glEnable(GL_DEPTH_TEST);    else glDisable(GL_DEPTH_TEST);
  if last_enable_scissor_test glEnable(GL_SCISSOR_TEST);  else glDisable(GL_SCISSOR_TEST);
  glPolygonMode(GL_FRONT_AND_BACK, last_polygon_mode[0]);
  glViewport(last_viewport[0], last_viewport[1], xx last_viewport[2], xx last_viewport[3]);
  glScissor(last_scissor_box[0], last_scissor_box[1], xx last_scissor_box[2], xx last_scissor_box[3]);
}

imgui_create_fonts_texture :: () -> bool {
  io := ImGui.GetIO();
  pixels: *u8;
  width, height: s32;
  bytes_per_pixel: s32;
  io.Fonts.GetTexDataAsAlpha8(io.Fonts, *pixels, *width, *height, *bytes_per_pixel);

  last_texture: GLuint;
  last_unpack_alignment: GLint;
  last_unpack_row_length: GLint;
  glGetIntegerv(GL_TEXTURE_BINDING_2D, xx *last_texture);
  glGetIntegerv(GL_UNPACK_ALIGNMENT, *last_unpack_alignment);
  glGetIntegerv(GL_UNPACK_ROW_LENGTH, *last_unpack_row_length);

  glGenTextures(1, *imgui_font_texture);
  glBindTexture(GL_TEXTURE_2D, imgui_font_texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, xx width, xx height, 0, GL_RED, GL_UNSIGNED_BYTE, pixels);

  io.Fonts.TexID = xx imgui_font_texture;

  glBindTexture(GL_TEXTURE_2D, last_texture);
  glPixelStorei(GL_UNPACK_ALIGNMENT, last_unpack_alignment);
  glPixelStorei(GL_UNPACK_ROW_LENGTH, last_unpack_row_length);

  return true;
}

imgui_create_device_objects :: () -> bool {
  last_texture, last_array_buffer, last_vertex_array: GLuint;
  glGetIntegerv(GL_TEXTURE_BINDING_2D, xx *last_texture);
  glGetIntegerv(GL_ARRAY_BUFFER_BINDING, xx *last_array_buffer);
  glGetIntegerv(GL_VERTEX_ARRAY_BINDING, xx *last_vertex_array);

  vertex_shader := #string END
    #version 330
    uniform mat4 ProjMtx;
    in vec2 Position;
    in vec2 UV;
    in vec4 Color;
    out vec2 Frag_UV;
    out vec4 Frag_Color;
    void main() {
      Frag_UV = UV;
      Frag_Color = Color;
      gl_Position = ProjMtx * vec4(Position.xy, 0, 1);
    }
  END

  fragment_shader := #string END
    #version 330
    uniform sampler2D Texture;
    in vec2 Frag_UV;
    in vec4 Frag_Color;
    out vec4 Out_Color;
    void main() {
      Out_Color = Frag_Color * texture(Texture, Frag_UV.st).r;
    }
  END

  imgui_shader_handle = glCreateProgram();
  imgui_vert_handle = glCreateShader(GL_VERTEX_SHADER);
  imgui_frag_handle = glCreateShader(GL_FRAGMENT_SHADER);
  _glShaderSource(imgui_vert_handle, vertex_shader);
  _glShaderSource(imgui_frag_handle, fragment_shader);
  glCompileShader(imgui_vert_handle);
  glCompileShader(imgui_frag_handle);
  glAttachShader(imgui_shader_handle, imgui_vert_handle);
  glAttachShader(imgui_shader_handle, imgui_frag_handle);
  glLinkProgram(imgui_shader_handle);

  imgui_attrib_location_tex = glGetUniformLocation(imgui_shader_handle, "Texture");
  imgui_attrib_location_proj_mtx = glGetUniformLocation(imgui_shader_handle, "ProjMtx");
  imgui_attrib_location_position = xx glGetAttribLocation(imgui_shader_handle, "Position");
  imgui_attrib_location_uv = xx glGetAttribLocation(imgui_shader_handle, "UV");
  imgui_attrib_location_color = xx glGetAttribLocation(imgui_shader_handle, "Color");

  glGenBuffers(1, *imgui_vbo_handle);
  glGenBuffers(1, *imgui_elements_handle);

  glGenVertexArrays(1, *imgui_vao_handle);
  glBindVertexArray(imgui_vao_handle);
  glBindBuffer(GL_ARRAY_BUFFER, imgui_vbo_handle);
  glEnableVertexAttribArray(imgui_attrib_location_position);
  glEnableVertexAttribArray(xx imgui_attrib_location_uv);
  glEnableVertexAttribArray(xx imgui_attrib_location_color);

  glVertexAttribPointer(imgui_attrib_location_position, 2, GL_FLOAT, GL_FALSE, size_of(ImGui.ImDrawVert), xx 0);
  glVertexAttribPointer(imgui_attrib_location_uv, 2, GL_FLOAT, GL_FALSE, size_of(ImGui.ImDrawVert), xx 8);
  glVertexAttribPointer(imgui_attrib_location_color, 4, GL_UNSIGNED_BYTE, GL_TRUE, size_of(ImGui.ImDrawVert), xx 16);

  imgui_create_fonts_texture();

  glBindTexture(GL_TEXTURE_2D, last_texture);
  glBindBuffer(GL_ARRAY_BUFFER, last_array_buffer);
  glBindVertexArray(last_vertex_array);

  return true;
}

imgui_invalidate_device_objects :: () {
  if imgui_font_texture {
    glDeleteTextures(1, *imgui_font_texture);
    ImGui.GetIO().Fonts.TexID = null;
    imgui_font_texture = 0;
  }

  if imgui_vbo_handle {
    glDeleteBuffers(1, *imgui_vbo_handle);
    imgui_vbo_handle = 0;
  }

  if imgui_elements_handle {
    glDeleteBuffers(1, *imgui_elements_handle);
    imgui_elements_handle = 0;
  }

  if imgui_vao_handle {
    glDeleteVertexArrays(1, *imgui_vao_handle);
    imgui_vao_handle = 0;
  }

  if imgui_vert_handle {
    glDetachShader(imgui_shader_handle, imgui_vert_handle);
    glDeleteShader(imgui_vert_handle);
    imgui_vert_handle = 0;
  }

  if imgui_frag_handle {
    glDetachShader(imgui_shader_handle, imgui_frag_handle);
    glDeleteShader(imgui_frag_handle);
    imgui_frag_handle = 0;
  }

  if imgui_shader_handle {
    glDeleteProgram(imgui_shader_handle);
    imgui_shader_handle = 0;
  }
}
