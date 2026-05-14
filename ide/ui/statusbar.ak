## StatusBar: Bottom bar displaying editor state information.
##
## Sections (left-to-right): cursor position | language | encoding |
## line ending | mode | temporary/permanent message.  Each section is
## separated by a thin vertical line.

bring in "akcode/core/os_bindings.ak"
bring in "akcode/core/theme.ak"

make kind called StatusBar
  ## Height of the status bar in pixels.  Fixed at construction.
  has height is number

  ## Formatted text: "Ln <row>, Col <col>".
  has cursor_position is text

  ## Language identifier shown in the bar (e.g. "AK", "Python", "JSON").
  has language is text

  ## File encoding label (e.g. "UTF-8", "ISO-8859-1").
  has encoding is text

  ## Line ending style: "LF", "CRLF", or "CR".
  has line_ending is text

  ## Editor mode indicator: "INSERT", "NORMAL", "VISUAL", "CMD".
  has mode is text

  ## Temporary message shown for `message_timeout` ms then cleared.
  has message is text

  ## Timer (ms) remaining before `message` is cleared.  0 means no
  ## temporary message.
  has message_timeout is number

  ## Persistent message shown at the rightmost edge of the bar.
  has permanent_message is text

  ## Timestamp of the last render for timeout tracking.

  ## Construct a default status bar with standard initial values.
  when created
    let height = 24
    let cursor_position = "Ln 1, Col 1"
    let language = "Plain Text"
    let encoding = "UTF-8"
    let line_ending = "LF"
    let mode = "INSERT"
    let message = ""
    let message_timeout = 0
    let permanent_message = ""
  end

  ## Update the cursor position display.
  ##
  ## Formats as "Ln <row>, Col <col>" where both are 1-based.
  behaviour update_cursor_position taking row and col
    let cursor_position = "Ln " plus row plus ", Col " plus col
  end

  ## Set the language label shown in the status bar.
  behaviour set_language taking lang
    let language = lang
  end

  ## Set the editor mode label (INSERT / NORMAL / VISUAL / CMD).
  behaviour set_mode taking mode_text
    let mode = mode_text
  end

  ## Show a temporary message that auto-clears after `timeout` ms.
  ##
  ## If another temporary message is already showing, it is replaced.
  behaviour show_message taking msg and timeout
    let message = msg
    let message_timeout = timeout
  end

  ## Set a persistent message (e.g. "Saving...", "Build complete").
  ##
  ## Persistent messages are not auto-cleared; call `clear_message`
  ## or `set_permanent_message` with "" to remove.
  behaviour set_permanent_message taking msg
    let permanent_message = msg
  end

  ## Clear any temporary message immediately.
  behaviour clear_message
    let message = ""
    let message_timeout = 0
  end

  ## Draw the full status bar from left to right at (x, y).
  ##
  ## Layout:
  ##   [cursor_position] | [language] | [encoding] | [line_ending] |
  ##   [mode] | ... gap ... | [temporary or permanent message]
  ##
  ## The bar background is "statusbar_bg" from the theme; text is
  ## "statusbar_fg".  Section separators are drawn with a slightly
  ## lighter colour.
  behaviour render_at taking x and y and render_width
    let bg = theme_get_colour("statusbar_bg")
    let fg = theme_get_colour("statusbar_fg")
    let sep = theme_get_colour("statusbar_separator")

    os_fill_rect(x, y, render_width, height, bg)

    let section_gap = 12
    let current_x = x plus 8

    ## Cursor position (leftmost).
    os_draw_text_at(current_x, y plus 4, cursor_position, fg)
    let current_x = current_x plus (os_text_width(cursor_position) plus section_gap)
    os_draw_line(current_x, y plus 4, current_x, y plus height minus 4, sep)
    let current_x = current_x plus section_gap

    ## Language.
    os_draw_text_at(current_x, y plus 4, language, fg)
    let current_x = current_x plus (os_text_width(language) plus section_gap)
    os_draw_line(current_x, y plus 4, current_x, y plus height minus 4, sep)
    let current_x = current_x plus section_gap

    ## Encoding.
    os_draw_text_at(current_x, y plus 4, encoding, fg)
    let current_x = current_x plus (os_text_width(encoding) plus section_gap)
    os_draw_line(current_x, y plus 4, current_x, y plus height minus 4, sep)
    let current_x = current_x plus section_gap

    ## Line ending.
    os_draw_text_at(current_x, y plus 4, line_ending, fg)
    let current_x = current_x plus (os_text_width(line_ending) plus section_gap)
    os_draw_line(current_x, y plus 4, current_x, y plus height minus 4, sep)
    let current_x = current_x plus section_gap

    ## Mode.
    os_draw_text_at(current_x, y plus 4, mode, fg)
    let current_x = current_x plus (os_text_width(mode) plus section_gap)

    ## Right-aligned message area.
    let display_msg = ""
    if message is not "" and message_timeout is greater than 0
      let display_msg = message
      let message_timeout = message_timeout minus 16  ## ~1 frame at 60 fps
      if message_timeout is less than 1
        clear_message
      end
    end

    if display_msg is "" and permanent_message is not ""
      let display_msg = permanent_message
    end

    if display_msg is not ""
      let msg_w = os_text_width(display_msg)
      let msg_x = (x plus render_width) minus msg_w minus 8
      os_draw_text_at(msg_x, y plus 4, display_msg, fg)
    end
  end

  ## Return the fixed height of the status bar.
  behaviour get_height
    give back height
  end
end
