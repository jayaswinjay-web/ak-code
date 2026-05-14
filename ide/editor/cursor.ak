## cursor.ak - Cursor Management
## Manages cursor position, line-based movement, and text selection
## within a GapBuffer. All positions are 0-indexed (row, col).

make kind called Cursor
  ## buffer: the GapBuffer being edited
  has buffer
  ## row: current line number (0-indexed)
  has row
  ## col: current column position on the line
  has col
  ## selection_start_row: row where the active selection began
  has selection_start_row
  ## selection_start_col: col where the active selection began
  has selection_start_col
  ## selection_active: whether a selection is in progress
  has selection_active

  ## Constructor: initializes cursor at top-left (0, 0) of the given buffer
  when created taking buf
    buffer = buf
    row = 0
    col = 0
    selection_start_row = 0
    selection_start_col = 0
    selection_active = false

  ## Moves the cursor to an absolute (row, col), clamped to valid bounds
  ## row is clamped to [0, line_count - 1], col to [0, line_length]
  behaviour move to taking new_row and new_col
    let line_count = call buffer get line count
    let clamped_row = new_row
    if clamped_row is less than 0
      clamped_row = 0
    end
    if clamped_row is greater than or equal to line_count
      clamped_row = line_count minus 1
    end

    let line_len = call buffer get column count at taking (clamped_row plus 1)
    let clamped_col = new_col
    if clamped_col is less than 0
      clamped_col = 0
    end
    if clamped_col is greater than line_len
      clamped_col = line_len
    end

    row = clamped_row
    col = clamped_col
  end

  ## Moves the cursor up one line
  ## If col exceeds the target line's length, it is clamped to the line end
  behaviour move up
    if row is equal to 0
      give back nothing
    end

    let target_row = row minus 1
    let target_len = call buffer get column count at taking (target_row plus 1)
    row = target_row
    if col is greater than target_len
      col = target_len
    end
  end

  ## Moves the cursor down one line
  ## If col exceeds the target line's length, it is clamped to the line end
  behaviour move down
    let line_count = call buffer get line count
    if row is greater than or equal to (line_count minus 1)
      give back nothing
    end

    let target_row = row plus 1
    let target_len = call buffer get column count at taking (target_row plus 1)
    row = target_row
    if col is greater than target_len
      col = target_len
    end
  end

  ## Moves the cursor left one character
  ## At column 0, wraps to the end of the previous line (if any)
  behaviour move left
    if col is greater than 0
      col = col minus 1
    else
      if row is greater than 0
        row = row minus 1
        col = call buffer get column count at taking (row plus 1)
      end
    end
  end

  ## Moves the cursor right one character
  ## At the end of a line, wraps to column 0 of the next line (if any)
  behaviour move right
    let line_len = call buffer get column count at taking (row plus 1)
    if col is less than line_len
      col = col plus 1
    else
      let line_count = call buffer get line count
      if row is less than (line_count minus 1)
        row = row plus 1
        col = 0
      end
    end
  end

  ## Moves the cursor to column 0 of the current line
  behaviour move to start of line
    col = 0
  end

  ## Moves the cursor to the last column of the current line
  behaviour move to end of line
    col = call buffer get column count at taking (row plus 1)
  end

  ## Returns the current position as a map with keys "row" and "col"
  behaviour get position
    let pos = map
      pos set "row" to row
      pos set "col" to col
    end
    give back pos
  end

  ## Begins a selection at the current cursor position
  ## Marks the anchor point so extend_selection can track the range
  behaviour start selection
    selection_start_row = row
    selection_start_col = col
    selection_active = true
  end

  ## Extends the current selection to the cursor's current position
  ## If no selection is active, starts a new one at the current position
  behaviour extend selection
    if selection_active is not true
      call start_selection
    end
  end

  ## Ends the selection without clearing its anchor
  ## has_selection will return false until a new selection begins
  behaviour end selection
    selection_active = false
  end

  ## Returns the text enclosed by the selection anchor and cursor position
  ## Works regardless of which end comes first in the document
  behaviour get selected text
    if selection_active is not true
      give back ""
    end

    let start_offset = call get_absolute_offset taking selection_start_row and selection_start_col
    let end_offset = call get_absolute_offset taking row and col

    let actual_start = start_offset
    let actual_end = end_offset
    if start_offset is greater than end_offset
      actual_start = end_offset
      actual_end = start_offset
    end

    give back call buffer get_text_between taking actual_start and actual_end
  end

  ## Returns true if a selection is active and the anchor differs from cursor
  behaviour has selection
    if selection_active is true
      if selection_start_row is not row or selection_start_col is not col
        give back true
      end
    end
    give back false
  end

  ## Converts (row, col) to a 0-based absolute character offset in the buffer
  ## Sums the length of each preceding line plus one newline per line
  behaviour get absolute offset taking row_param and col_param
    let offset = 0
    let i = 0
    repeat while i is less than row_param
      offset = offset plus (call buffer get_column_count_at taking (i plus 1))
      offset = offset plus 1
      i = i plus 1
    end
    offset = offset plus col_param
    give back offset
  end
end
