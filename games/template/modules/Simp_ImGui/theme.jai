// ----------------------------------------------------------------------------: ImGui theme

IMGUI_FONT_PATH :: "data/fonts/NotoSans-Regular.ttf";
IMGUI_BASE_FONT_SIZE :: 18.0;

load_fonts :: (ui_scale: float) {
  io := ImGui.GetIO();

  io.Fonts.Clear(io.Fonts);
  io.FontGlobalScale = 1.0;

  font_config: ImGui.ImFontConfig;
  font_config.Constructor(*font_config);
  font_config.OversampleH = 3;
  font_config.OversampleV = 1;
  font_config.PixelSnapH = true;
  font_config.RasterizerMultiply = 1.10;

  font_size := IMGUI_BASE_FONT_SIZE * ui_scale;
  font: *ImGui.ImFont;
  if file_exists(IMGUI_FONT_PATH) {
    font = io.Fonts.AddFontFromFileTTF(io.Fonts, temp_c_string(IMGUI_FONT_PATH), font_size, *font_config);
  } else {
    font = io.Fonts.AddFontDefault(io.Fonts, *font_config);
  }
  assert(font != null, "Failed to load ImGui font.");
  io.FontDefault = font;
}

apply_theme :: (ui_scale: float) {
  ImGui.StyleColorsDark();

  style := ImGui.GetStyle();
  style.WindowRounding = 8.0;
  style.FrameRounding = 8.0;
  style.GrabRounding = 8.0;
  style.TabRounding = 8.0;
  style.ScrollbarRounding = 8.0;
  style.WindowBorderSize = 1.0;
  style.FrameBorderSize = 0.0;
  style.WindowMenuButtonPosition = .None;
  style.ScaleAllSizes(style, ui_scale);

  style.Colors[ImGui.Col.WindowBg]           = .{0.10, 0.105,  0.11,  1.0};
  style.Colors[ImGui.Col.Header]             = .{0.20, 0.205,  0.21,  1.0};
  style.Colors[ImGui.Col.HeaderHovered]      = .{0.30, 0.305,  0.31,  1.0};
  style.Colors[ImGui.Col.HeaderActive]       = .{0.15, 0.1505, 0.151, 1.0};
  style.Colors[ImGui.Col.Button]             = .{0.20, 0.205,  0.21,  1.0};
  style.Colors[ImGui.Col.ButtonHovered]      = .{0.30, 0.305,  0.31,  1.0};
  style.Colors[ImGui.Col.ButtonActive]       = .{0.15, 0.1505, 0.151, 1.0};
  style.Colors[ImGui.Col.FrameBg]            = .{0.20, 0.205,  0.21,  1.0};
  style.Colors[ImGui.Col.FrameBgHovered]     = .{0.30, 0.305,  0.31,  1.0};
  style.Colors[ImGui.Col.FrameBgActive]      = .{0.15, 0.1505, 0.151, 1.0};
  style.Colors[ImGui.Col.Tab]                = .{0.15, 0.1505, 0.151, 1.0};
  style.Colors[ImGui.Col.TabHovered]         = .{0.38, 0.3805, 0.381, 1.0};
  style.Colors[ImGui.Col.TabActive]          = .{0.28, 0.2805, 0.281, 1.0};
  style.Colors[ImGui.Col.TabUnfocused]       = .{0.15, 0.1505, 0.151, 1.0};
  style.Colors[ImGui.Col.TabUnfocusedActive] = .{0.20, 0.205,  0.21,  1.0};
  style.Colors[ImGui.Col.TitleBg]            = .{0.15, 0.1505, 0.151, 1.0};
  style.Colors[ImGui.Col.TitleBgActive]      = .{0.15, 0.1505, 0.151, 1.0};
  style.Colors[ImGui.Col.TitleBgCollapsed]   = .{0.15, 0.1505, 0.151, 1.0};
}
