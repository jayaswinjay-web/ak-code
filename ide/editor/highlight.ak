## highlight.ak - Syntax Highlighting Engine
## Tokenizes AK CODE source lines into colored segments for rendering.
## Recognizes keywords, strings, numbers, comments, and operators.

make kind called Highlighter
  ## keywords: list of reserved words in AK CODE
  has keywords
  ## token_colors: maps token type names to numeric color codes
  has token_colors
  ## line_styles: cache of { line_number, segments } for previously highlighted lines
  has line_styles
  ## operators: list of AK CODE operator tokens
  has operators
  ## theme_name: current color theme identifier ("dark" or "light")
  has theme_name

  ## Constructor: populates keyword and operator lists from the AK CODE spec,
  ## sets up default dark theme color assignments
  when created
    keywords = list of 0
    operators = list of 0
    line_styles = list of 0

    add "if" to keywords
    add "else" to keywords
    add "end" to keywords
    add "repeat" to keywords
    add "while" to keywords
    add "for" to keywords
    add "each" to keywords
    add "in" to keywords
    add "try" to keywords
    add "catch" to keywords
    add "make" to keywords
    add "kind" to keywords
    add "called" to keywords
    add "has" to keywords
    add "behaviour" to keywords
    add "when" to keywords
    add "created" to keywords
    add "taking" to keywords
    add "define" to keywords
    add "let" to keywords
    add "bring" to keywords
    add "show" to keywords
    add "give" to keywords
    add "back" to keywords
    add "is" to keywords
    add "not" to keywords
    add "and" to keywords
    add "or" to keywords
    add "greater" to keywords
    add "less" to keywords
    add "equal" to keywords
    add "than" to keywords
    add "to" to keywords
    add "list" to keywords
    add "map" to keywords
    add "of" to keywords
    add "any" to keywords
    add "error" to keywords
    add "as" to keywords

    add "plus" to operators
    add "minus" to operators
    add "times" to operators
    add "divided" to operators
    add "by" to operators

    token_colors = map
    end
    token_colors set "keyword" to 1
    token_colors set "string" to 2
    token_colors set "number" to 3
    token_colors set "comment" to 4
    token_colors set "operator" to 5
    token_colors set "type" to 6
    token_colors set "function" to 7

    theme_name = "dark"

  ## Helper: extracts a substring from text between start_pos and end_pos
  behaviour get text slice taking text and start_pos and end_pos
    let result = ""
    let i = start_pos
    repeat while i is less than end_pos
      result = result plus item i of text
      i = i plus 1
    end
    give back result
  end

  ## Tokenizes a line of source text into color-coded segments
  ## Each segment is a map: { start, length, color }
  ##   color 0 = default text
  ##   color 1 = keyword
  ##   color 2 = string literal
  ##   color 3 = numeric literal
  ##   color 4 = comment
  ##   color 5 = operator
  ## Scans left to right, identifying comments, strings, numbers,
  ## identifiers/keywords, and operators via look-ahead
  behaviour highlight line taking line_text
    let segments = list of 0
    let len = size of line_text
    let i = 0

    repeat while i is less than len
      let ch = item i of line_text

      if ch is equal to "#" and (i plus 1) is less than len and item (i plus 1) of line_text is equal to "#"
        let comment_start = i
        repeat while i is less than len
          i = i plus 1
        end
        let seg = map
          seg set "start" to comment_start
          seg set "length" to (len minus comment_start)
          seg set "color" to 4
        end
        add seg to segments
        break
      end

      if ch is equal to "\""
        let str_start = i
        i = i plus 1
        repeat while i is less than len and item i of line_text is not "\""
          if item i of line_text is "\\"
            i = i plus 1
          end
          i = i plus 1
        end
        if i is less than len
          i = i plus 1
        end
        let seg = map
          seg set "start" to str_start
          seg set "length" to (i minus str_start)
          seg set "color" to 2
        end
        add seg to segments
      end

      if ch is greater than or equal to "0" and ch is less than or equal to "9"
        let num_start = i
        repeat while i is less than len and item i of line_text is greater than or equal to "0" and item i of line_text is less than or equal to "9"
          i = i plus 1
        end
        let seg = map
          seg set "start" to num_start
          seg set "length" to (i minus num_start)
          seg set "color" to 3
        end
        add seg to segments
      end

      if (ch is greater than or equal to "a" and ch is less than or equal to "z") or (ch is greater than or equal to "A" and ch is less than or equal to "Z") or ch is equal to "_"
        let word_start = i
        repeat while i is less than len
          let c = item i of line_text
          if (c is greater than or equal to "a" and c is less than or equal to "z") or (c is greater than or equal to "A" and c is less than or equal to "Z") or (c is greater than or equal to "0" and c is less than or equal to "9") or c is equal to "_"
            i = i plus 1
          else
            break
          end
        end
        let word_len = i minus word_start
        let word = call get_text_slice taking line_text and word_start and i

        let color_val = 0
        if call is_keyword taking word
          color_val = 1
        end
        if call is_operator taking word
          color_val = 5
        end

        let seg = map
          seg set "start" to word_start
          seg set "length" to word_len
          seg set "color" to color_val
        end
        add seg to segments
      end

      if i is less than len
        let c = item i of line_text
        if c is not " " and c is not "\t" and c is not "\""
          i = i plus 1
        end
        if c is " " or c is "\t"
          i = i plus 1
        end
      end
    end

    give back segments
  end

  ## Returns the complete identifier or keyword token at a given position
  ## within a line. Expands left and right to capture the full alphanumeric word.
  behaviour get token at taking line_text and position
    let len = size of line_text
    if position is less than 0 or position is greater than or equal to len
      give back ""
    end

    let start_pos = position
    repeat while start_pos is greater than 0
      let c = item (start_pos minus 1) of line_text
      if (c is greater than or equal to "a" and c is less than or equal to "z") or (c is greater than or equal to "A" and c is less than or equal to "Z") or (c is greater than or equal to "0" and c is less than or equal to "9") or c is equal to "_"
        start_pos = start_pos minus 1
      else
        break
      end
    end

    let end_pos = position
    repeat while end_pos is less than len
      let c = item end_pos of line_text
      if (c is greater than or equal to "a" and c is less than or equal to "z") or (c is greater than or equal to "A" and c is less than or equal to "Z") or (c is greater than or equal to "0" and c is less than or equal to "9") or c is equal to "_"
        end_pos = end_pos plus 1
      else
        break
      end
    end

    give back call get_text_slice taking line_text and start_pos and end_pos
  end

  ## Checks whether a word is in the reserved keyword list
  behaviour is keyword taking word
    let i = 0
    let kw_count = size of keywords
    repeat while i is less than kw_count
      if item i of keywords is equal to word
        give back true
      end
      i = i plus 1
    end
    give back false
  end

  ## Checks whether a word is in the operator token list
  behaviour is operator taking word
    let i = 0
    let op_count = size of operators
    repeat while i is less than op_count
      if item i of operators is equal to word
        give back true
      end
      i = i plus 1
    end
    give back false
  end

  ## Returns the numeric color code for a given token type string
  ## Color codes: 0=default, 1=keyword, 2=string, 3=number,
  ##              4=comment, 5=operator, 6=type, 7=function
  behaviour get color for taking token_type
    if token_colors has token_type
      give back token_colors get token_type
    end
    give back 0
  end

  ## Highlights a range of lines from the buffer and stores results in line_styles
  ## Processes every line between start_line and end_line (inclusive),
  ## producing a segment list for each and caching it
  behaviour highlight document taking buffer and start_line and end_line
    let i = start_line
    repeat while i is less than or equal to end_line
      let line_text = call buffer get_line_at taking (i plus 1)
      let segments = call highlight_line taking line_text

      let style_entry = map
        style_entry set "line" to i
        style_entry set "segments" to segments
      end
      add style_entry to line_styles
      i = i plus 1
    end
  end

  ## Switches the color scheme to the named theme
  ## Currently supports "dark" and "light"; defaults to dark
  ## Updates token_colors with appropriate values for the theme
  behaviour set theme taking theme_name_param
    theme_name = theme_name_param

    if theme_name_param is equal to "light"
      token_colors set "keyword" to 1
      token_colors set "string" to 2
      token_colors set "number" to 3
      token_colors set "comment" to 4
      token_colors set "operator" to 5
      token_colors set "type" to 6
      token_colors set "function" to 7
    else
      token_colors set "keyword" to 1
      token_colors set "string" to 2
      token_colors set "number" to 3
      token_colors set "comment" to 4
      token_colors set "operator" to 5
      token_colors set "type" to 6
      token_colors set "function" to 7
    end
  end
end
