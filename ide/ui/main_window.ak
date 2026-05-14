## MainWindow: Top-level application window manager for the AK IDE.
##
## Owns all child panels (tabs, sidebar, statusbar, terminal, agents panel)
## and dispatches OS-level events (keyboard, mouse, paint, resize, close)
## to the appropriate component. Coordinates lifecycle: init, run, render, shutdown.

bring in "akcode/core/os_bindings.ak"
bring in "akcode/ui/renderer.ak"
bring in "akcode/ide/ui/tabs.ak"
bring in "akcode/ide/ui/sidebar.ak"
bring in "akcode/ide/ui/statusbar.ak"
bring in "akcode/ide/ui/terminal.ak"
bring in "akcode/ide/ui/agents_panel.ak"

make kind called MainWindow
  ## The native OS window handle (HWND on Win32, Window on X11).
  has window_handle is number

  ## Current window dimensions in device pixels.
  has width is number
  has height is number

  ## Title displayed in the window title bar / task bar.
  has title is text

  ## Ordered list of open editor tabs.
  has tabs is list of Tab

  ## Left sidebar (file explorer, search, git, extensions).
  has sidebar is Sidebar

  ## Bottom status bar showing cursor position, language, mode, messages.
  has statusbar is Statusbar

  ## Bottom-terminal panel for shell commands.
  has terminal is Terminal

  ## Right-side AI agents panel for multi-agent chat / orchestration.
  has agents_panel is AgentsPanel

  ## Index into `tabs` indicating which tab is currently focused.
  has active_tab_index is number

  ## Active colour theme name, e.g. "dark-default", "light-default".
  has theme is text

  ## Whether the window is in fullscreen mode (no decorations).
  has is_fullscreen is bool

  ## Internal flag set when a close has been requested.
  has close_requested is bool

  ## Internal flag set after initialization is complete.
  has initialized is bool

  ## Construct a new MainWindow with the given title and sensible defaults.
  ##
  ## Calls create_native_window to register with the OS, then initialises
  ## all child panels to their default state.
  when created taking title_text
    let title = title_text
    let width = 1280
    let height = 800
    let active_tab_index = 0
    let theme = "dark-default"
    let is_fullscreen = false
    let close_requested = false
    let initialized = false

    let sidebar = Sidebar created
    let statusbar = Statusbar created
    let terminal = Terminal created
    let agents_panel = AgentsPanel created
    let tabs = list of Tab

    give back initialize
  end

  ## Initialize the native OS window and mark the manager as ready.
  ##
  ## Platform-specific: on Windows this calls CreateWindowEx; on X11
  ## it calls XCreateWindow.  The returned handle is stored in
  ## window_handle for later event dispatch.
  behaviour initialize
    ## Attempt to open the OS window.
    let handle = os_create_window(width, height, title)
    if handle is 0
      show "FATAL: failed to create OS window"
      give back false
    end

    let window_handle = handle

    let sidebar_height = statusbar get height

    ## Lay out child panels now that we know the real dimensions.
    sidebar width = 250
    sidebar visible = true
    agents_panel width = 350
    agents_panel visible = false
    terminal visible = false
    terminal height = 200

    let initialized = true

    show "MainWindow initialized (" plus title plus ")"
    give back true
  end

  ## Run the OS-level event loop until the window is closed.
  ##
  ## Dispatches paint, resize, keyboard, mouse, and close events
  ## to the appropriate handler.  Returns when close_requested is true.
  behaviour run_event_loop
    if initialized is not true
      show "ERROR: run_event_loop called before initialize"
      give back
    end

    repeat while close_requested is not true
      let event = os_poll_event(window_handle)

      if event is not 0
        let event_type = event get "type"

        if event_type is "close"
          handle close
        end

        if event_type is "resize"
          let new_w = event get "width"
          let new_h = event get "height"
          handle resize taking new_w and new_h
        end

        if event_type is "paint"
          render
        end

        if event_type is "key_down"
          let key_code = event get "key_code"
          let modifiers = event get "modifiers"
          handle key taking key_code and modifiers
        end

        if event_type is "mouse_down"
          let mx = event get "x"
          let my = event get "y"
          let button = event get "button"
          handle mouse_click taking mx and my and button
        end

        if event_type is "mouse_move"
          ## Future: hover tracking, cursor updates.
        end
      end

      ## Yield to avoid busy-wait.  Platform provides a small sleep.
      os_yield
    end

    show "Event loop ended"
  end

  ## Full redraw of every visible component in Z-order.
  ##
  ## Order: sidebar -> tabs (editor area) -> terminal -> agents panel ->
  ## statusbar (topmost).  This follows a painter's-algorithm approach.
  behaviour render
    if initialized is not true
      give back
    end

    os_begin_paint(window_handle)

    let sb_height = statusbar get height
    let term_height = 0
    if terminal visible is true
      let term_height = terminal height
    end

    let sidebar_w = 0
    if sidebar visible is true
      let sidebar_w = sidebar width
    end

    let agents_w = 0
    if agents_panel visible is true
      let agents_w = agents_panel width
    end

    let editor_x = sidebar_w
    let editor_y = 0
    let editor_w = width minus sidebar_w minus agents_w
    let editor_h = height minus sb_height minus term_height

    ## Draw background for the editor area.
    os_fill_rect(window_handle, editor_x, editor_y, editor_w, editor_h,
                  theme_get_colour(theme, "editor_bg"))

    ## Sidebar (drawn beneath the editor area when visible).
    if sidebar visible is true
      sidebar render file tree at taking 0 and 0 and sidebar_w
    end

    ## Active tab content.
    let active_tab = get_active_tab
    if size of tabs is greater than 0 and active_tab is not 0
      let preview = active_tab get preview
      os_draw_text(window_handle, editor_x plus 8, editor_y plus 8,
                   preview, theme_get_colour(theme, "editor_fg"))
    end

    ## Terminal panel docked at the bottom.
    if terminal visible is true
      let term_y = height minus sb_height minus term_height
      os_fill_rect(window_handle, 0, term_y, width, term_height,
                    theme_get_colour(theme, "terminal_bg"))
      terminal render at taking 0 and term_y and width
    end

    ## Agents panel docked on the right.
    if agents_panel visible is true
      let ap_x = width minus agents_w
      os_fill_rect(window_handle, ap_x, 0, agents_w, height minus sb_height,
                    theme_get_colour(theme, "agents_bg"))
    end

    ## Statusbar at the very bottom.
    statusbar render at taking 0 and (height minus sb_height) and width

    os_end_paint(window_handle)
  end

  ## Dispatch a keyboard event to the active editor tab's input handler.
  ##
  ## If no tab is open the key is ignored.  Modifiers are passed through
  ## for chord detection (Ctrl+S, etc.).
  behaviour handle_key taking key_code and modifiers
    let active_tab = get_active_tab
    if active_tab is not 0
      active_tab handle_key taking key_code and modifiers
    end

    ## Check for global shortcuts regardless of active tab.
    if key_code is 83 and (modifiers and 2) is 2  ## Ctrl+S
      if active_tab is not 0
        active_tab mark saved
      end
    end

    if key_code is 81 and (modifiers and 2) is 2  ## Ctrl+Q
      handle close
    end
  end

  ## Dispatch a mouse click to the correct child panel based on (x,y).
  ##
  ## Hit-testing order (topmost first): statusbar, terminal, agents panel,
  ## sidebar, then the editor / tab content area.
  behaviour handle_mouse_click taking x and y and button
    let sb_height = statusbar get height
    let hit_statusbar = y is greater than (height minus sb_height)
    let term_height = 0
    if terminal visible is true
      let term_height = terminal height
    end

    if hit_statusbar is true
      ## Statusbar clicks: maybe switch mode, clear message, etc.
      show "statusbar clicked at " plus x
      give back
    end

    if terminal visible is true and y is greater than (height minus sb_height minus term_height)
      terminal handle input taking button  ## forward click as input focus
      give back
    end

    let sidebar_w = 0
    if sidebar visible is true
      let sidebar_w = sidebar width
    end

    if sidebar visible is true and x is less than sidebar_w
      sidebar select item taking "browser"
      give back
    end

    let agents_w = 0
    if agents_panel visible is true
      let agents_w = agents_panel width
    end

    if agents_panel visible is true and x is greater than (width minus agents_w)
      agents_panel render conversation
      give back
    end

    ## Otherwise the click is in the editor area – focus the active tab.
    let active_tab = get_active_tab
    if active_tab is not 0
      active_tab activate
    end
  end

  ## Handle a window resize event: update dimensions and re-layout.
  ##
  ## Invalidates the whole window so the next paint cycle redraws
  ## everything at the new size.
  behaviour handle_resize taking new_width and new_height
    let width = new_width
    let height = new_height

    ## Mark window as needing a full redraw.
    os_invalidate_rect(window_handle, 0, 0, width, height)
  end

  ## Update the window title displayed in the title bar.
  behaviour set_title taking new_title
    let title = new_title
    os_set_window_title(window_handle, title)
  end

  ## Switch the colour theme for every UI component.
  ##
  ## Themes are loaded from "akcode/themes/<name>.ak".  Each child panel
  ## re-reads its colours on the next render cycle.
  behaviour set_theme taking theme_name
    let theme = theme_name
    os_invalidate_rect(window_handle, 0, 0, width, height)
    show "Theme switched to " plus theme_name
  end

  ## Toggle between fullscreen and windowed mode.
  ##
  ## On Windows this uses SetWindowLong + SetWindowPos to remove the
  ## title bar.  On X11 it sends _NET_WM_STATE_FULLSCREEN.
  behaviour toggle_fullscreen
    if is_fullscreen is true
      os_set_fullscreen(window_handle, false)
      let is_fullscreen = false
    end

    if is_fullscreen is not true
      os_set_fullscreen(window_handle, true)
      let is_fullscreen = true
    end

    os_invalidate_rect(window_handle, 0, 0, width, height)
  end

  ## Gracefully shut down the application.
  ##
  ## Steps: prompt save on modified tabs, destroy child panels, release
  ## the native window, and signal the event loop to exit.
  behaviour close
    if close_requested is true
      give back
    end

    let unsaved = list of Tab
    for each tab in tabs
      if tab has unsaved changes
        add tab to unsaved
      end
    end

    if size of unsaved is greater than 0
      let confirm = os_message_box(window_handle,
                     "You have " plus (size of unsaved) plus
                     " unsaved file(s). Close anyway?",
                     "Unsaved Changes")
      if confirm is not 1
        give back  ## User cancelled close.
      end
    end

    if terminal is_running is true
      terminal kill process
    end

    show "Saving session state..."
    os_destroy_window(window_handle)
    let close_requested = true
    show "MainWindow closed."
  end

  ## ------------------------------------------------------------------
  ##  Private helpers
  ## ------------------------------------------------------------------

  ## Return the tab at active_tab_index, or 0 if no tabs exist.
  behaviour get_active_tab
    if size of tabs is 0
      give back 0
    end

    if active_tab_index is greater than (size of tabs minus 1)
      let active_tab_index = size of tabs minus 1
    end

    let active = tabs get active_tab_index
    give back active
  end

  ## Convenience: get a colour from the active theme by key.
  behaviour theme_get_colour taking key
    let colours = os_load_theme(theme)
    let value = colours get key
    if value is 0
      give back "#1E1E1E"
    end
    give back value
  end
end
