## linter.ak - Real-time Linter for Error Checking
## Analyzes AK CODE source code for syntax errors, bracket mismatches,
## indentation issues, and unclosed block statements.
## Provides per-line error and warning lists to the editor for display.

make kind called Linter
  ## errors: list of diagnostic maps with { line, col, message, severity }
  has errors
  ## warnings: list of diagnostic maps with lesser severity
  has warnings

  ## Constructor: initializes empty error and warning lists
  when created
    errors = list of 0
    warnings = list of 0

  ## Lints a range of lines in the buffer for syntax and style issues
  ## Runs syntax checking, indentation checking, and structural analysis
  ## (unclosed blocks, unmatched brackets) for the specified range
  behaviour lint taking buffer and start_line and end_line
    let i = start_line
    repeat while i is less than or equal to end_line
      let line_text = call buffer get_line_at taking (i plus 1)
      call check_syntax taking line_text and i
      let expected_indent = call compute_expected_indent taking buffer and i
      call check_indent taking line_text and i and expected_indent
      i = i plus 1
    end

    call check_unclosed_blocks taking buffer
    call check_unmatched_brackets taking buffer
  end

  ## Helper: trims leading and trailing whitespace from text
  behaviour trim taking text
    let len = size of text
    let start = 0
    repeat while start is less than len and (item start of text is " " or item start of text is "\t")
      start = start plus 1
    end

    let end_pos = len
    repeat while end_pos is greater than start and (item (end_pos minus 1) of text is " " or item (end_pos minus 1) of text is "\t")
      end_pos = end_pos minus 1
    end

    if start is greater than 0 or end_pos is less than len
      let result = ""
      let i = start
      repeat while i is less than end_pos
        result = result plus item i of text
        i = i plus 1
      end
      give back result
    end
    give back text
  end

  ## Helper: extracts the first word from a trimmed line of text
  behaviour first word taking text
    let trimmed = call trim taking text
    let len = size of trimmed
    let word = ""
    let i = 0
    repeat while i is less than len and item i of trimmed is not " "
      word = word plus item i of trimmed
      i = i plus 1
    end
    give back word
  end

  ## Checks a single line for syntax issues:
  ##   - unmatched brackets (parentheses, braces, brackets)
  ##   - bare "else" or "else if" without context
  ## Reports findings as warnings or informational diagnostics
  behaviour check syntax taking line_text and line_number
    let len = size of line_text
    let open_parens = 0
    let open_braces = 0
    let open_brackets = 0
    let in_string = false
    let string_char = ""

    let i = 0
    repeat while i is less than len
      let ch = item i of line_text

      if ch is equal to "\""
        if in_string is not true
          in_string = true
          string_char = ch
        else
          if string_char is equal to ch
            in_string = false
          end
        end
        i = i plus 1
        repeat while i is less than len
          if in_string is true
            if item i of line_text is "\\"
              i = i plus 1
            else
              if item i of line_text is string_char
                in_string = false
              end
            end
            i = i plus 1
          else
            break
          end
        end
      end

      if ch is equal to "#" and (i plus 1) is less than len and item (i plus 1) of line_text is equal to "#"
        break
      end

      if in_string is not true
        if ch is equal to "("
          open_parens = open_parens plus 1
        end
        if ch is equal to ")"
          open_parens = open_parens minus 1
        end
        if ch is equal to "{"
          open_braces = open_braces plus 1
        end
        if ch is equal to "}"
          open_braces = open_braces minus 1
        end
        if ch is equal to "["
          open_brackets = open_brackets plus 1
        end
        if ch is equal to "]"
          open_brackets = open_brackets minus 1
        end
      end

      i = i plus 1
    end

    if open_parens is less than 0
      let warn = map
        warn set "line" to line_number
        warn set "col" to 0
        warn set "message" to "Unmatched closing parenthesis ')'"
        warn set "severity" to "warning"
      end
      add warn to warnings
    end

    if open_braces is less than 0
      let warn = map
        warn set "line" to line_number
        warn set "col" to 0
        warn set "message" to "Unmatched closing brace '}'"
        warn set "severity" to "warning"
      end
      add warn to warnings
    end

    if open_brackets is less than 0
      let warn = map
        warn set "line" to line_number
        warn set "col" to 0
        warn set "message" to "Unmatched closing bracket ']'"
        warn set "severity" to "warning"
      end
      add warn to warnings
    end

    if open_parens is greater than 0 or open_braces is greater than 0 or open_brackets is greater than 0
      let info = map
        info set "line" to line_number
        info set "col" to 0
        info set "message" to "Unclosed bracket - expected closing delimiter later in the file"
        info set "severity" to "info"
      end
      add info to warnings
    end

    let first_word = call first_word taking line_text
    if first_word is equal to "else" or first_word is equal to "else if"
      let info = map
        info set "line" to line_number
        info set "col" to 0
        info set "message" to "'" plus first_word plus "' without preceding 'if' block"
        info set "severity" to "info"
      end
      add info to warnings
    end
  end

  ## Checks the line's leading whitespace against the expected indent level
  ## Expected indent is computed by compute_expected_indent based on nesting depth
  ## Reports a warning when the deviation exceeds 4 spaces in either direction
  behaviour check indent taking line_text and line_number and expected_indent
    let actual_indent = 0
    let i = 0
    let len = size of line_text
    repeat while i is less than len and (item i of line_text is " " or item i of line_text is "\t")
      if item i of line_text is "\t"
        actual_indent = actual_indent plus 4
      else
        actual_indent = actual_indent plus 1
      end
      i = i plus 1
    end

    let diff = actual_indent minus expected_indent
    if diff is not 0
      let severity = "info"
      if diff is less than -4 or diff is greater than 4
        severity = "warning"
      end

      let warn = map
        warn set "line" to line_number
        warn set "col" to 0
        warn set "message" to "Incorrect indentation: expected " plus expected_indent plus " spaces, got " plus actual_indent
        warn set "severity" to severity
      end
      add warn to warnings
    end
  end

  ## Computes the expected indentation (in spaces) for a given line
  ## Walks through every preceding line and tracks nesting depth:
  ##   block-openers: if, repeat, for, try, when, make, behaviour, define
  ##   block-closers: end, else, else if
  ## Each nesting level adds 2 spaces of indentation
  behaviour compute expected indent taking buffer and line_number
    let indent_level = 0
    let i = 0
    repeat while i is less than line_number
      let line_text = call buffer get_line_at taking (i plus 1)
      let first_word = call first_word taking line_text

      if first_word is equal to "if" or first_word is equal to "repeat" or first_word is equal to "for" or first_word is equal to "try" or first_word is equal to "when"
        indent_level = indent_level plus 1
      end

      if first_word is equal to "make" or first_word is equal to "behaviour" or first_word is equal to "define"
        indent_level = indent_level plus 1
      end

      if first_word is equal to "end"
        indent_level = indent_level minus 1
      end

      if first_word is equal to "else" or first_word is equal to "else if"
        if indent_level is greater than 0
          indent_level = indent_level minus 1
        end
      end

      i = i plus 1
    end

    if indent_level is less than 0
      indent_level = 0
    end

    give back indent_level times 2
  end

  ## Scans the entire buffer for unclosed block statements
  ## Tracks every block-opening keyword ("if", "repeat", "for", "try",
  ## "when", "make", "behaviour", "define") and its corresponding "end".
  ## Reports errors for any opening keyword without a matching "end".
  behaviour check unclosed blocks taking buffer
    let line_count = call buffer get line count
    let block_keywords = list of 0
    let block_lines = list of 0
    let block_count = 0

    let i = 0
    repeat while i is less than line_count
      let line_text = call buffer get_line_at taking (i plus 1)
      let first_word = call first_word taking line_text

      if first_word is equal to "if" or first_word is equal to "repeat" or first_word is equal to "for" or first_word is equal to "try" or first_word is equal to "when" or first_word is equal to "make" or first_word is equal to "behaviour" or first_word is equal to "define"
        add first_word to block_keywords
        add i to block_lines
        block_count = block_count plus 1
      end

      if first_word is equal to "end"
        if block_count is greater than 0
          let new_kw = list of 0
          let new_ln = list of 0
          let j = 0
          repeat while j is less than (block_count minus 1)
            add item j of block_keywords to new_kw
            add item j of block_lines to new_ln
            j = j plus 1
          end
          block_keywords = new_kw
          block_lines = new_ln
          block_count = block_count minus 1
        else
          let err = map
            err set "line" to i
            err set "col" to 0
            err set "message" to "Lone 'end' without a matching opening block keyword"
            err set "severity" to "error"
          end
          add err to errors
        end
      end

      if first_word is equal to "else" or first_word is equal to "else if"
        if block_count is greater than 0
          let top_kw = last item of block_keywords
          if top_kw is not "if"
            let warn = map
              warn set "line" to i
              warn set "col" to 0
              warn set "message" to "'" plus first_word plus "' without matching 'if' at line " plus (last item of block_lines plus 1)
              warn set "severity" to "warning"
            end
            add warn to warnings
          end
        else
          let warn = map
            warn set "line" to i
            warn set "col" to 0
            warn set "message" to "'" plus first_word plus "' without any enclosing block"
            warn set "severity" to "warning"
          end
          add warn to warnings
        end
      end

      i = i plus 1
    end

    let k = 0
    repeat while k is less than block_count
      let kw = item k of block_keywords
      let ln = (item k of block_lines) plus 1
      let err = map
        err set "line" to ln minus 1
        err set "col" to 0
        err set "message" to "Unclosed block: '" plus kw plus "' at line " plus ln plus " has no matching 'end'"
        err set "severity" to "error"
      end
      add err to errors
      k = k plus 1
    end
  end

  ## Scans the entire buffer for bracket pairs that are never closed
  ## Tracks every opening bracket and verifies a matching closing bracket exists
  behaviour check unmatched brackets taking buffer
    let line_count = call buffer get line count
    let open_paren_lines = list of 0
    let open_brace_lines = list of 0
    let open_bracket_lines = list of 0
    let paren_depth = 0
    let brace_depth = 0
    let bracket_depth = 0

    let i = 0
    repeat while i is less than line_count
      let line_text = call buffer get_line_at taking (i plus 1)
      let in_str = false
      let j = 0
      let len = size of line_text

      repeat while j is less than len
        let ch = item j of line_text

        if ch is equal to "\""
          if in_str is not true
            in_str = true
          else
            in_str = false
          end
        end

        if ch is equal to "#" and (j plus 1) is less than len and item (j plus 1) of line_text is equal to "#"
          break
        end

        if in_str is not true
          if ch is equal to "("
            paren_depth = paren_depth plus 1
            add i to open_paren_lines
          end
          if ch is equal to ")"
            paren_depth = paren_depth minus 1
            if paren_depth is less than 0
              paren_depth = 0
            end
            if size of open_paren_lines is greater than 0
              let new_list = list of 0
              let k = 0
              repeat while k is less than (size of open_paren_lines minus 1)
                add item k of open_paren_lines to new_list
                k = k plus 1
              end
              open_paren_lines = new_list
            end
          end
          if ch is equal to "{"
            brace_depth = brace_depth plus 1
            add i to open_brace_lines
          end
          if ch is equal to "}"
            brace_depth = brace_depth minus 1
            if brace_depth is less than 0
              brace_depth = 0
            end
            if size of open_brace_lines is greater than 0
              let new_list = list of 0
              let k = 0
              repeat while k is less than (size of open_brace_lines minus 1)
                add item k of open_brace_lines to new_list
                k = k plus 1
              end
              open_brace_lines = new_list
            end
          end
          if ch is equal to "["
            bracket_depth = bracket_depth plus 1
            add i to open_bracket_lines
          end
          if ch is equal to "]"
            bracket_depth = bracket_depth minus 1
            if bracket_depth is less than 0
              bracket_depth = 0
            end
            if size of open_bracket_lines is greater than 0
              let new_list = list of 0
              let k = 0
              repeat while k is less than (size of open_bracket_lines minus 1)
                add item k of open_bracket_lines to new_list
                k = k plus 1
              end
              open_bracket_lines = new_list
            end
          end
        end

        j = j plus 1
      end

      i = i plus 1
    end

    let p = 0
    repeat while p is less than size of open_paren_lines
      let ln = item p of open_paren_lines
      let err = map
        err set "line" to ln
        err set "col" to 0
        err set "message" to "Unclosed '(' starting at line " plus (ln plus 1)
        err set "severity" to "error"
      end
      add err to errors
      p = p plus 1
    end

    let q = 0
    repeat while q is less than size of open_brace_lines
      let ln = item q of open_brace_lines
      let err = map
        err set "line" to ln
        err set "col" to 0
        err set "message" to "Unclosed '{' starting at line " plus (ln plus 1)
        err set "severity" to "error"
      end
      add err to errors
      q = q plus 1
    end

    let r = 0
    repeat while r is less than size of open_bracket_lines
      let ln = item r of open_bracket_lines
      let err = map
        err set "line" to ln
        err set "col" to 0
        err set "message" to "Unclosed '[' starting at line " plus (ln plus 1)
        err set "severity" to "error"
      end
      add err to errors
      r = r plus 1
    end
  end

  ## Returns the complete list of error diagnostics
  behaviour get errors
    give back errors
  end

  ## Clears all stored errors and warnings for a fresh lint pass
  behaviour clear
    errors = list of 0
    warnings = list of 0
  end

  ## Returns all diagnostics (errors and warnings) for a given line number
  behaviour get error at taking line_number
    let line_errors = list of 0

    let i = 0
    repeat while i is less than size of errors
      let err = item i of errors
      if err get "line" is equal to line_number
        add err to line_errors
      end
      i = i plus 1
    end

    let j = 0
    repeat while j is less than size of warnings
      let warn = item j of warnings
      if warn get "line" is equal to line_number
        add warn to line_errors
      end
      j = j plus 1
    end

    give back line_errors
  end

  ## Returns the total count of warning diagnostics
  behaviour get warning count
    give back size of warnings
  end

  ## Returns the total count of error diagnostics
  behaviour get error count
    give back size of errors
  end
end
