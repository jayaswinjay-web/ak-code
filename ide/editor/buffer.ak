## buffer.ak - Gap Buffer Text Buffer
## Implements a gap buffer data structure for efficient text editing.
## Insertions and deletions near the cursor are O(1) amortized.
## The gap maintains an empty region in the character array and moves
## it to the edit location, avoiding large memory copies.

make kind called GapBuffer
  ## buffer: underlying character array as list of single-character text
  has buffer
  ## gap_start: index where the gap begins (first unused slot)
  has gap_start
  ## gap_end: index where the gap ends (first used slot after gap)
  has gap_end
  ## size: logical content length (total array size minus gap size)
  has size
  ## undo_stack: operation records for undo support
  has undo_stack
  ## redo_stack: operation records for redo support
  has redo_stack
  ## gap_minimum: minimum gap size preserved when expanding
  has gap_minimum

  ## Constructor: builds gap buffer populated with initial_text
  ## Allocates underlying array with initial_text.length + 16 slots,
  ## fills the leading slots with text characters, and places the gap after them
  when created taking initial_text
    let text_length = size of initial_text
    gap_minimum = 16
    let total = text_length plus gap_minimum

    buffer = list of total
    let i = 0
    repeat while i is less than text_length
      buffer set i to item i of initial_text
      i = i plus 1
    end

    let j = text_length
    repeat while j is less than total
      buffer set j to " "
      j = j plus 1
    end

    gap_start = text_length
    gap_end = total
    size = text_length
    undo_stack = list of 0
    redo_stack = list of 0

  ## Internal: moves the gap to a target logical position
  ## Shifts characters from one side of the gap to the other:
  ##   - target < gap_start: shift characters [target .. gap_start-1] rightward
  ##   - target > gap_start: shift characters [gap_end .. gap_end+move_count-1] leftward
  behaviour move_gap to taking position
    if position is equal to gap_start
      give back nothing
    end

    if position is less than gap_start
      let move_count = gap_start minus position
      let dest = gap_end minus move_count
      let i = 0
      repeat while i is less than move_count
        buffer set (dest plus i) to buffer at (position plus i)
        i = i plus 1
      end
      gap_end = gap_end minus move_count
      gap_start = position
    else
      let move_count = position minus gap_start
      let src = gap_end
      let i = 0
      repeat while i is less than move_count
        buffer set (gap_start plus i) to buffer at (src plus i)
        i = i plus 1
      end
      gap_start = position
      gap_end = src plus move_count
    end
  end

  ## Internal: ensures the gap has at least needed_space free slots
  ## Grows the underlying array by needed_space + gap_minimum when the gap is too small,
  ## then copies both sides around the enlarged gap
  behaviour ensure_gap taking needed_space
    let gap_size = gap_end minus gap_start
    if gap_size is greater than needed_space
      give back nothing
    end

    let current_capacity = size of buffer
    let extra = needed_space plus gap_minimum
    let new_capacity = current_capacity plus extra
    let new_buffer = list of new_capacity
    let right_len = current_capacity minus gap_end

    let i = 0
    repeat while i is less than gap_start
      new_buffer set i to buffer at i
      i = i plus 1
    end

    let new_gap_end = gap_start plus needed_space plus gap_minimum
    let j = 0
    repeat while j is less than right_len
      new_buffer set (new_gap_end plus j) to buffer at (gap_end plus j)
      j = j plus 1
    end

    let k = gap_start
    repeat while k is less than new_gap_end
      new_buffer set k to " "
      k = k plus 1
    end

    buffer = new_buffer
    gap_end = new_gap_end
  end

  ## Internal: converts a logical index to the physical array index
  ## Accounts for the gap offset: indices at or after gap_start are shifted
  ## by (gap_end - gap_start) to skip over the unused gap region
  behaviour logical to physical taking logical_index
    if logical_index is less than gap_start
      give back logical_index
    else
      give back logical_index plus (gap_end minus gap_start)
    end
  end

  ## Inserts text at the given logical position
  ## Moves the gap to the insertion point, expands if the gap is too small,
  ## then fills the gap with the new text and advances gap_start
  behaviour insert taking text and position
    let op = map
      op set "type" to "insert"
      op set "position" to position
      op set "text" to text
    end
    redo_stack = list of 0
    add op to undo_stack

    let text_len = size of text
    call move_gap to position
    call ensure_gap taking text_len

    let i = 0
    repeat while i is less than text_len
      buffer set (gap_start plus i) to item i of text
      i = i plus 1
    end

    gap_start = gap_start plus text_len
    size = size plus text_len
  end

  ## Deletes the range of text from start_pos to end_pos (exclusive)
  ## Moves the gap to start_pos and widens it to cover the deleted range,
  ## effectively removing those characters from the logical content
  behaviour delete from taking start_pos and end_pos
    let actual_start = start_pos
    let actual_end = end_pos

    if actual_start is greater than actual_end
      let temp = actual_start
      actual_start = actual_end
      actual_end = temp
    end

    if actual_start is less than 0
      actual_start = 0
    end
    if actual_end is greater than size
      actual_end = size
    end

    let delete_len = actual_end minus actual_start
    if delete_len is equal to 0
      give back nothing
    end

    let deleted_text = call get_text_between taking actual_start and actual_end
    let op = map
      op set "type" to "delete"
      op set "position" to actual_start
      op set "text" to deleted_text
    end
    redo_stack = list of 0
    add op to undo_stack

    call move_gap to actual_start
    gap_end = gap_end plus delete_len
    size = size minus delete_len
  end

  ## Returns the text content between two logical positions
  ## Reads from either side of the gap, translating logical indices
  ## to physical indices via logical_to_physical
  behaviour get text between taking start_pos and end_pos
    let result = ""
    let i = start_pos
    repeat while i is less than end_pos
      let phys = call logical_to_physical taking i
      result = result plus (buffer at phys)
      i = i plus 1
    end
    give back result
  end

  ## Returns the single character at the given logical position
  behaviour get char at taking position
    let phys = call logical_to_physical taking position
    give back buffer at phys
  end

  ## Returns the text of a specific line (1-indexed)
  ## Scans from the beginning of the buffer counting newline delimiters
  ## until it finds the requested line, then extracts its content
  behaviour get line at taking line_number
    if line_number is less than 1
      give back ""
    end

    let current_line = 1
    let line_start = 0
    let i = 0

    repeat while i is less than size and current_line is less than line_number
      let ch = call get_char_at taking i
      if ch is equal to "\n"
        current_line = current_line plus 1
        if current_line is equal to line_number
          line_start = i plus 1
        end
      end
      i = i plus 1
    end

    if current_line is less than line_number
      give back ""
    end

    let line_end = size
    let j = line_start
    repeat while j is less than size
      let ch = call get_char_at taking j
      if ch is equal to "\n"
        line_end = j
        break
      end
      j = j plus 1
    end

    give back call get_text_between taking line_start and line_end
  end

  ## Returns the total number of lines in the buffer
  ## Counts newline characters and adds one (the final line)
  behaviour get line count
    if size is equal to 0
      give back 1
    end

    let count = 1
    let i = 0
    repeat while i is less than size
      if call get_char_at taking i is equal to "\n"
        count = count plus 1
      end
      i = i plus 1
    end
    give back count
  end

  ## Returns the character length of the specified line
  behaviour get column count at taking line_number
    let line_text = call get_line_at taking line_number
    give back size of line_text
  end

  ## Loads file content from disk into the buffer
  ## Resets the gap buffer entirely: reads the file, allocates a fresh
  ## array with a gap at the end, and clears all undo/redo history
  behaviour load from file taking path
    try
      let handle = call file_open taking path and "r"
      let content = call file_read_all taking handle
      call file_close taking handle

      let text_length = size of content
      let total = text_length plus gap_minimum

      buffer = list of total
      let i = 0
      repeat while i is less than text_length
        buffer set i to item i of content
        i = i plus 1
      end

      let j = text_length
      repeat while j is less than total
        buffer set j to " "
        j = j plus 1
      end

      gap_start = text_length
      gap_end = total
      size = text_length
      undo_stack = list of 0
      redo_stack = list of 0
    catch any error as e
      show "Error loading file: " plus e
    end
  end

  ## Saves the current buffer content to the specified file path
  behaviour save to file taking path
    try
      let content = call get_text_between taking 0 and size
      let handle = call file_open taking path and "w"
      call file_write taking handle and content
      call file_close taking handle
    catch any error as e
      show "Error saving file: " plus e
    end
  end

  ## Searches for a query string starting from a logical position
  ## Performs a character-by-character comparison at each offset
  ## Returns the logical position of the first match, or -1 if not found
  behaviour search taking query and start_position
    let query_len = size of query
    if query_len is equal to 0
      give back -1
    end
    if start_position is greater than or equal to size
      give back -1
    end

    let i = start_position
    repeat while i is less than or equal to (size minus query_len)
      let match = true
      let j = 0
      repeat while j is less than query_len
        if call get_char_at taking (i plus j) is not item j of query
          match = false
          break
        end
        j = j plus 1
      end
      if match
        give back i
      end
      i = i plus 1
    end

    give back -1
  end

  ## Replaces all non-overlapping occurrences of old_text with new_text
  ## First collects every match position, then applies replacements
  ## from right to left so earlier positions stay valid
  behaviour replace taking old_text and new_text
    let positions = list of 0
    let search_pos = 0
    let old_len = size of old_text

    search_pos = call search taking old_text and 0
    repeat while search_pos is not -1
      add search_pos to positions
      search_pos = call search taking old_text and (search_pos plus old_len)
    end

    let pos_count = size of positions
    let idx = pos_count minus 1
    repeat while idx is greater than or equal to 0
      let p = item idx of positions
      call delete_from taking p and (p plus old_len)
      call insert taking new_text and p
      idx = idx minus 1
    end
  end

  ## Reverts the most recent insert or delete operation
  ## Pops the top of undo_stack, reverses it (insert becomes delete,
  ## delete becomes insert), and pushes the inverse onto redo_stack
  behaviour undo
    let stack_size = size of undo_stack
    if stack_size is equal to 0
      give back nothing
    end

    let op = last item of undo_stack
    let op_type = op get "type"
    let op_position = op get "position"
    let op_text = op get "text"

    let new_stack = list of 0
    let i = 0
    repeat while i is less than (stack_size minus 1)
      add item i of undo_stack to new_stack
      i = i plus 1
    end
    undo_stack = new_stack

    if op_type is equal to "insert"
      let text_len = size of op_text
      call delete_from taking op_position and (op_position plus text_len)
      let redo_op = map
        redo_op set "type" to "insert"
        redo_op set "position" to op_position
        redo_op set "text" to op_text
      end
      add redo_op to redo_stack
    else
      call insert taking op_text and op_position
      let redo_op = map
        redo_op set "type" to "delete"
        redo_op set "position" to op_position
        redo_op set "text" to op_text
      end
      add redo_op to redo_stack
    end
  end

  ## Re-applies the last undone operation
  ## Pops the top of redo_stack, applies it, and pushes the inverse
  ## onto undo_stack so it can be undone again
  behaviour redo
    let stack_size = size of redo_stack
    if stack_size is equal to 0
      give back nothing
    end

    let op = last item of redo_stack
    let op_type = op get "type"
    let op_position = op get "position"
    let op_text = op get "text"

    let new_stack = list of 0
    let i = 0
    repeat while i is less than (stack_size minus 1)
      add item i of redo_stack to new_stack
      i = i plus 1
    end
    redo_stack = new_stack

    if op_type is equal to "insert"
      call insert taking op_text and op_position
      let undo_op = map
        undo_op set "type" to "insert"
        undo_op set "position" to op_position
        undo_op set "text" to op_text
      end
      add undo_op to undo_stack
    else
      let text_len = size of op_text
      call delete_from taking op_position and (op_position plus text_len)
      let undo_op = map
        undo_op set "type" to "delete"
        undo_op set "position" to op_position
        undo_op set "text" to op_text
      end
      add undo_op to undo_stack
    end
  end
end
