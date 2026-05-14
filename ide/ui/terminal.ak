## Terminal: Embedded terminal emulator panel docked at the bottom of
## the IDE window.  Manages an OS child process (shell), captures its
## stdout/stderr, and provides a scrollback buffer with input editing.

bring in "akcode/core/os_bindings.ak"
bring in "akcode/core/os_process.ak"

make kind called Terminal
  ## Whether the terminal panel is currently visible.
  has visible is bool

  ## Height of the terminal panel in pixels.
  has height is number

  ## History of previously executed commands (up-arrow recall).
  has command_history is list of text

  ## The command string currently being edited.
  has current_command is text

  ## Scrollback buffer: each entry is a line of output.
  has output_lines is list of text

  ## Scroll offset for viewing output history (0 = bottom).
  has scroll_offset is number

  ## OS process ID of the running shell, or 0 if no process.
  has process_id is number

  ## True while the child process is alive.
  has is_running is bool

  ## Index into command_history for up-arrow navigation.
  has history_index is number

  ## Cursor position within current_command (for inline editing).
  has edit_cursor is number

  ## Construct a terminal with default geometry and an empty buffer.
  when created
    let visible = false
    let height = 200
    let current_command = ""
    let scroll_offset = 0
    let process_id = 0
    let is_running = false
    let history_index = 0
    let edit_cursor = 0
    let command_history = list of text
    let output_lines = list of text
  end

  ## Show or hide the terminal panel.
  behaviour toggle
    if visible is true
      let visible = false
    end

    if visible is not true
      let visible = true
      if is_running is not true
        start_shell
      end
    end
  end

  ## Start the default system shell as a child process.
  ##
  ## On Windows this spawns cmd.exe; on POSIX it spawns /bin/bash.
  ## Stdout and stderr pipes are captured asynchronously.
  behaviour start_shell
    if is_running is true
      give back
    end

    let shell_path = os_get_shell_path
    let process_id = os_spawn_process(shell_path)
    if process_id is not 0
      let is_running = true
      write_output taking "Terminal: " plus shell_path plus " started."
    end

    if process_id is 0
      write_error taking "ERROR: failed to start " plus shell_path
    end
  end

  ## Execute a command string in the running shell.
  ##
  ## Appends the command to the output as "> <cmd>", sends it to the
  ## child process stdin, and adds it to the history.
  behaviour execute_command taking cmd
    if is_running is not true
      write_error taking "ERROR: terminal process is not running."
      give back
    end

    write_output taking "> " plus cmd

    let ok = os_process_write_stdin(process_id, cmd plus "\n")
    if ok is not true
      write_error taking "ERROR: failed to write to process stdin."
    end

    add cmd to command_history
    let history_index = size of command_history

    let current_command = ""
    let edit_cursor = 0
  end

  ## Append a line of normal output (stdout) to the scrollback buffer.
  behaviour write_output taking text
    add text to output_lines

    ## Cap scrollback at 10 000 lines to avoid unbounded memory.
    if size of output_lines is greater than 10000
      let trimmed = list of text
      let i = size of output_lines minus 10000
      repeat while i is less than size of output_lines
        add (output_lines get i) to trimmed
        let i = i plus 1
      end
      let output_lines = trimmed
    end

    let scroll_offset = 0  ## auto-scroll to bottom on new output
  end

  ## Append a line of error output (stderr) to the scrollback buffer.
  ##
  ## Errors are visually distinct in the output (the renderer uses
  ## a different colour for these lines).
  behaviour write_error taking text
    let tagged = "[ERROR] " plus text
    add tagged to output_lines
    if size of output_lines is greater than 10000
      let trimmed = list of text
      let i = size of output_lines minus 10000
      repeat while i is less than size of output_lines
        add (output_lines get i) to trimmed
        let i = i plus 1
      end
      let output_lines = trimmed
    end
    let scroll_offset = 0
  end

  ## Clear all output from the terminal.
  behaviour clear
    let output_lines = list of text
    let scroll_offset = 0
  end

  ## Scroll the output view upward by one line.
  behaviour scroll_up
    let max_offset = size of output_lines
    if scroll_offset is less than max_offset
      let scroll_offset = scroll_offset plus 1
    end
  end

  ## Scroll the output view downward by one line.
  behaviour scroll_down
    if scroll_offset is greater than 0
      let scroll_offset = scroll_offset minus 1
    end
  end

  ## Return the subset of output_lines visible in the panel.
  ##
  ## Based on the panel height (in pixels) and the current scroll_offset.
  behaviour get_visible_lines
    let lines_per_page = height divided by 18  ## 18px line height
    let total = size of output_lines

    let start = total minus lines_per_page minus scroll_offset
    if start is less than 0
      let start = 0
    end

    let end_line = start plus lines_per_page
    if end_line is greater than total
      let end_line = total
    end

    let visible = list of text
    let i = start
    repeat while i is less than end_line
      add (output_lines get i) to visible
      let i = i plus 1
    end

    give back visible
  end

  ## Handle a key press for command-line editing.
  ##
  ## Enter executes the command; Backspace deletes the previous char;
  ## Up/Down navigate command history; other printable chars append.
  behaviour handle_input taking key_code
    ## Enter.
    if key_code is 13
      if current_command is not ""
        execute_command taking current_command
      end
      give back
    end

    ## Backspace.
    if key_code is 8
      if edit_cursor is greater than 0
        let before = current_command slice 0 to (edit_cursor minus 1)
        let after = current_command slice edit_cursor to (size of current_command)
        let current_command = before plus after
        let edit_cursor = edit_cursor minus 1
      end
      give back
    end

    ## Up arrow – recall previous command from history.
    if key_code is 38
      if history_index is greater than 0
        let history_index = history_index minus 1
        let current_command = command_history get history_index
        let edit_cursor = size of current_command
      end
      give back
    end

    ## Down arrow – recall next command from history.
    if key_code is 40
      let max_idx = size of command_history minus 1
      if history_index is less than max_idx
        let history_index = history_index plus 1
        let current_command = command_history get history_index
        let edit_cursor = size of current_command
      end

      if history_index is max_idx
        let current_command = ""
        let edit_cursor = 0
      end
      give back
    end

    ## Left arrow.
    if key_code is 37
      if edit_cursor is greater than 0
        let edit_cursor = edit_cursor minus 1
      end
      give back
    end

    ## Right arrow.
    if key_code is 39
      if edit_cursor is less than (size of current_command)
        let edit_cursor = edit_cursor plus 1
      end
      give back
    end

    ## Home key.
    if key_code is 36
      let edit_cursor = 0
      give back
    end

    ## End key.
    if key_code is 35
      let edit_cursor = size of current_command
      give back
    end

    ## Printable characters.
    if key_code is greater than 31 and key_code is not 127
      let ch = os_code_point_to_string(key_code)
      let before = current_command slice 0 to edit_cursor
      let after = current_command slice edit_cursor to (size of current_command)
      let current_command = before plus ch plus after
      let edit_cursor = edit_cursor plus 1
    end
  end

  ## Resize the terminal panel to a new height in pixels.
  behaviour change_height taking new_height
    if new_height is less than 60
      let new_height = 60  ## minimum height
    end

    if new_height is greater than 800
      let new_height = 800  ## maximum height
    end

    let height = new_height
  end

  ## Kill the currently running child process.
  ##
  ## Sends SIGTERM (POSIX) or TerminateProcess (Windows).  The process
  ## handle is closed afterwards.
  behaviour kill_process
    if is_running is not true and process_id is 0
      give back
    end

    os_process_terminate(process_id)
    os_process_close(process_id)
    let is_running = false
    let process_id = 0
    write_output taking "Terminal: process terminated."
  end

  ## Render visible terminal lines and the input prompt at (x, y).
  behaviour render_at taking x and y and render_width
    let bg = theme_get_colour("terminal_bg")
    let fg = theme_get_colour("terminal_fg")
    let err_col = theme_get_colour("terminal_error")
    let prompt_col = theme_get_colour("terminal_prompt")

    os_fill_rect(x, y, render_width, height, bg)

    let line_h = 18
    let visible = get_visible_lines
    let draw_y = y plus 4

    for each line in visible
      if line starts_with "[ERROR]"
        os_draw_text_at(x plus 4, draw_y, line, err_col)
      end

      if line starts_with "[ERROR]" is not true
        os_draw_text_at(x plus 4, draw_y, line, fg)
      end

      let draw_y = draw_y plus line_h
    end

    ## Prompt line.
    let prompt = "$ " plus current_command
    let prompt_y = (y plus height) minus line_h minus 4
    os_draw_text_at(x plus 4, prompt_y, prompt, prompt_col)
  end
end
