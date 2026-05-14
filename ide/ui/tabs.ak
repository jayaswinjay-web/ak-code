## Tab: Represents a single open editor document in the IDE.
##
## Each Tab holds its own GapBuffer for text, a Cursor for navigation,
## a Highlighter for syntax colouring, and scroll state.  Modified tracking
## enables the "unsaved changes" prompt on close.

bring in "akcode/core/gap_buffer.ak"
bring in "akcode/core/cursor.ak"
bring in "akcode/core/highlighter.ak"
bring in "akcode/core/file_io.ak"

make kind called Tab
  ## Display name shown on the tab bar (usually the file name).
  has title is text

  ## Absolute or project-relative path to the file on disk.
  has file_path is text

  ## The underlying gap-buffer holding the document text.
  has buffer is GapBuffer

  ## The text cursor (position, selection anchor, visual column).
  has cursor is Cursor

  ## Syntax highlighter producing tokenised colour ranges.
  has highlighter is Highlighter

  ## True when the buffer has been edited since the last save.
  has is_modified is bool

  ## Horizontal scroll offset in pixels (for soft-wrapped lines).
  has scroll_x is number

  ## Vertical scroll offset in lines from the top of the buffer.
  has scroll_y is number

  ## Cached rendered lines to avoid re-highlighting on every paint.
  has cached_lines is list of text

  ## Construct a Tab by loading the file at `file_path` into the buffer.
  ##
  ## If the file does not exist an empty buffer is created with the given
  ## path as a placeholder for a new file.
  when created taking file
    let title = file
    let file_path = file
    let is_modified = false
    let scroll_x = 0
    let scroll_y = 0
    let buffer = GapBuffer created

    let content = read_file(file_path)
    if content is 0
      ## New file – empty buffer, title still shown.
      let title = "untitled"
      let file_path = ""
    end

    if content is not 0
      buffer insert taking content
    end

    let cursor = Cursor created
    let highlighter = Highlighter created

    let cached_lines = buffer get lines
    highlighter tokenise taking cached_lines

    give back self
  end

  ## Bring this tab into focus: the cursor becomes active and the
  ## highlighter re-checks the current line for semantic tokens.
  behaviour activate
    cursor set active to true
    highlighter rehighlight_line taking cursor get row
  end

  ## Close the tab, prompting if there are unsaved changes.
  ##
  ## give back true if the close was confirmed, false if cancelled.
  behaviour close
    if is_modified is true
      let msg = "Save changes to \"" plus title plus "\"?"
      let choice = os_dialog_yes_no_cancel(msg)
      if choice is "cancel"
        give back false
      end
      if choice is "yes"
        save
      end
    end

    buffer clear
    cursor reset
    give back true
  end

  ## Rename the tab and optionally update the file path.
  ##
  ## When `new_name` contains a path separator the file_path is replaced;
  ## otherwise only the display title changes.
  behaviour rename taking new_name
    if new_name contains "/" or new_name contains "\\"
      let file_path = new_name
      let title = os_file_name(new_name)
    end

    if new_name contains "/" is not true and new_name contains "\\" is not true
      let title = new_name
    end
  end

  ## Return a rendered preview of the visible lines for the display.
  ##
  ## Uses the cached highlighted lines to produce a single string
  ## suitable for drawing in the editor pane.
  behaviour get_preview
    if size of cached_lines is 0
      give back ""
    end

    let visible_count = 40  ## approximate lines that fit on screen
    let start_line = scroll_y
    let end_line = scroll_y plus visible_count

    if end_line is greater than (size of cached_lines)
      let end_line = size of cached_lines
    end

    let result = ""
    let i = start_line
    repeat while i is less than end_line

      let line = cached_lines get i
      if line is not 0
        let result = result plus line plus "\n"
      end
      let i = i plus 1
    end

    give back result
  end

  ## Return the modification flag.
  behaviour has_unsaved_changes
    give back is_modified
  end

  ## Mark the tab as saved (is_modified = false) and persist to disk.
  behaviour mark_saved
    let full_text = buffer get all text
    write_file(file_path, full_text)
    let is_modified = false
  end

  ## Mark the tab as modified (e.g. after an edit).
  behaviour mark_modified
    let is_modified = true
  end

  ## Save the current buffer contents to `file_path`.
  ##
  ## If file_path is empty (untitled) the caller should first call
  ## `rename` to assign a real path.
  behaviour save
    if file_path is ""
      show "WARNING: cannot save untitled tab – call rename first"
      give back
    end
    mark_saved
  end

  ## Insert text at the current cursor position.
  behaviour insert_text taking text
    buffer insert at taking text and (cursor get offset)
    cursor move_by taking (size of text)
    mark_modified

    let cached_lines = buffer get lines
    highlighter tokenise taking cached_lines
  end

  ## Delete the character before the cursor (backspace).
  behaviour backspace
    let pos = cursor get offset
    if pos is greater than 0
      buffer delete range taking (pos minus 1) and 1
      cursor move_to taking (pos minus 1)
      mark_modified

      let cached_lines = buffer get lines
      highlighter tokenise taking cached_lines
    end
  end

  ## Handle a keyboard event within this tab.
  ##
  ## Normal printable characters are inserted; special keys are mapped
  ## to cursor movement or editing commands.
  behaviour handle_key taking key_code and modifiers
    if key_code is 13  ## Enter
      insert_text taking "\n"
      give back
    end

    if key_code is 8  ## Backspace
      backspace
      give back
    end

    if key_code is 9  ## Tab
      insert_text taking "  "
      give back
    end

    if key_code is 37  ## Left arrow
      cursor move_left
      give back
    end

    if key_code is 38  ## Up arrow
      if scroll_y is greater than 0
        let scroll_y = scroll_y minus 1
      end
      cursor move_up
      give back
    end

    if key_code is 39  ## Right arrow
      cursor move_right
      give back
    end

    if key_code is 40  ## Down arrow
      let scroll_y = scroll_y plus 1
      cursor move_down
      give back
    end

    ## Printable character range (rough ASCII / Unicode).
    if key_code is greater than 31 and key_code is not 127
      let ch = os_code_point_to_string(key_code)
      insert_text taking ch
    end
  end
end

## TabBar: Manages an ordered list of open tabs.
##
## Provides tab-level operations: add, remove, reorder, activate.
## The MainWindow owns exactly one TabBar instance.

make kind called TabBar
  ## The ordered list of all open tabs.
  has tabs is list of Tab

  ## Index of the currently active (focused) tab.
  has active_index is number

  when created
    let tabs = list of Tab
    let active_index = 0
  end

  ## Append a new tab to the end of the list and activate it.
  behaviour add_tab taking tab
    add tab to tabs
    let active_index = size of tabs minus 1
  end

  ## Close and remove the tab at `index`, then adjust active_index.
  ##
  ## If the tab's `close` method returns false the removal is cancelled.
  behaviour close_tab_at taking index
    if index is less than 0 or index is greater than (size of tabs minus 1)
      give back false
    end

    let tab = tabs get index
    let confirmed = tab close
    if confirmed is not true
      give back false
    end

    ## Remove the tab from the list.
    let new_tabs = list of Tab
    let i = 0
    for each t in tabs
      if i is not index
        add t to new_tabs
      end
      let i = i plus 1
    end

    let tabs = new_tabs

    ## Adjust active_index to stay in bounds.
    if size of tabs is 0
      let active_index = 0
    end

    if active_index is greater than (size of tabs minus 1) and size of tabs is greater than 0
      let active_index = size of tabs minus 1
    end

    if active_index is index and index is greater than 0
      let active_index = index minus 1
    end

    give back true
  end

  ## Return the currently active tab, or 0 if no tabs are open.
  behaviour get_active_tab
    if size of tabs is 0
      give back 0
    end

    if active_index is greater than (size of tabs minus 1)
      let active_index = size of tabs minus 1
    end

    let tab = tabs get active_index
    give back tab
  end

  ## Switch the active tab to `index`.
  ##
  ## Calls `activate` on the newly selected tab.
  behaviour set_active_tab_at taking index
    if index is less than 0 or index is greater than (size of tabs minus 1)
      give back
    end

    let current = get_active_tab
    if current is not 0
      current cursor set active to false
    end

    let active_index = index
    let next = get_active_tab
    if next is not 0
      next activate
    end
  end

  ## Reorder tabs by moving the tab at `from_index` to `to_index`.
  ##
  ## All tabs between the two positions shift accordingly.
  behaviour move_tab_from taking from_index to to_index
    if from_index is to_index
      give back
    end

    if from_index is less than 0 or from_index is greater than (size of tabs minus 1)
      give back
    end

    if to_index is less than 0 or to_index is greater than (size of tabs minus 1)
      give back
    end

    let tab = tabs get from_index

    ## Build new list without `tab`.
    let intermediate = list of Tab
    let i = 0
    for each t in tabs
      if i is not from_index
        add t to intermediate
      end
      let i = i plus 1
    end

    ## Re-insert at the target position.
    let result = list of Tab
    let j = 0
    for each t in intermediate
      if j is to_index
        add tab to result
      end
      add t to result
      let j = j plus 1
    end

    ## If to_index is at the very end, append.
    if size of result is size of intermediate
      add tab to result
    end

    let tabs = result
    let active_index = to_index
  end

  ## Return a list of all tab titles (for menu display, etc.).
  behaviour get_all_titles
    let titles = list of text
    for each tab in tabs
      add (tab title) to titles
    end
    give back titles
  end

  ## Return the number of open tabs.
  behaviour size
    give back size of tabs
  end
end
