## autocomplete.ak - Autocompletion Engine
## Provides real-time code completion by matching a prefix against
## AK CODE keywords and user-defined symbols extracted from open files.
## Candidates are scored and sorted by relevance for display.

make kind called Autocomplete
  ## completions: list of candidate maps { text, score, kind, file } sorted by score
  has completions
  ## keywords: all reserved words of the AK CODE language
  has keywords
  ## open_file_symbols: map from file path to list of symbol maps
  has open_file_symbols
  ## current_index: index into completions for cycling through suggestions
  has current_index
  ## best_completion: text of the currently selected best completion
  has best_completion

  ## Constructor: populates keyword list from the AK CODE spec
  when created
    completions = list of 0
    open_file_symbols = map
    end
    current_index = 0
    best_completion = ""

    keywords = list of 0
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
    add "in" to keywords
    add "if" to keywords
    add "else" to keywords
    add "end" to keywords
    add "repeat" to keywords
    add "while" to keywords
    add "for" to keywords
    add "each" to keywords
    add "show" to keywords
    add "give" to keywords
    add "back" to keywords
    add "try" to keywords
    add "catch" to keywords
    add "any" to keywords
    add "error" to keywords
    add "as" to keywords
    add "is" to keywords
    add "not" to keywords
    add "and" to keywords
    add "or" to keywords
    add "plus" to keywords
    add "minus" to keywords
    add "times" to keywords
    add "divided" to keywords
    add "by" to keywords
    add "list" to keywords
    add "map" to keywords
    add "of" to keywords
    add "to" to keywords
    add "greater" to keywords
    add "less" to keywords
    add "equal" to keywords
    add "than" to keywords

  ## Helper: extracts a substring between start_pos and end_pos
  behaviour get text slice taking text and start_pos and end_pos
    let result = ""
    let i = start_pos
    repeat while i is less than end_pos
      result = result plus item i of text
      i = i plus 1
    end
    give back result
  end

  ## Finds all completion candidates matching the given prefix
  ## Searches keywords and all symbols from open files. Each candidate
  ## is scored via the score behaviour, then results are sorted descending.
  ## Sets completions, current_index, and best_completion as side effects.
  behaviour get completions for taking prefix and context
    let results = list of 0
    let prefix_len = size of prefix

    if prefix_len is equal to 0
      completions = results
      current_index = 0
      best_completion = ""
      give back results
    end

    let i = 0
    let kw_count = size of keywords
    repeat while i is less than kw_count
      let kw = item i of keywords
      let kw_prefix = call get_text_slice taking kw and 0 and prefix_len
      if kw_prefix is equal to prefix
        let score_val = call score taking kw and prefix
        let entry = map
          entry set "text" to kw
          entry set "score" to score_val
          entry set "kind" to "keyword"
        end
        add entry to results
      end
      i = i plus 1
    end

    let file_names = list of 0
    for each fn in open_file_symbols
      add fn to file_names
    end

    let fn_count = size of file_names
    let j = 0
    repeat while j is less than fn_count
      let symbols = open_file_symbols get item j of file_names
      let s = 0
      let sym_count = size of symbols
      repeat while s is less than sym_count
        let sym = item s of symbols
        let sym_name = sym get "name"
        let sym_prefix = call get_text_slice taking sym_name and 0 and prefix_len
        if sym_prefix is equal to prefix
          let score_val = call score taking sym_name and prefix
          let entry = map
            entry set "text" to sym_name
            entry set "score" to score_val
            entry set "kind" to sym get "kind"
            entry set "file" to sym get "file"
          end
          add entry to results
        end
        s = s plus 1
      end
      j = j plus 1
    end

    let r_count = size of results
    let a = 0
    repeat while a is less than r_count
      let b = a plus 1
      repeat while b is less than r_count
        let score_a = (item a of results) get "score"
        let score_b = (item b of results) get "score"
        if score_b is greater than score_a
          let temp = item a of results
          results set a to item b of results
          results set b to temp
        end
        b = b plus 1
      end
      a = a plus 1
    end

    completions = results
    current_index = 0
    if size of completions is greater than 0
      best_completion = (first item of completions) get "text"
    else
      best_completion = ""
    end

    give back results
  end

  ## Registers a symbol (variable, function, type, etc.) in the database
  ## Symbols are stored per-file in open_file_symbols for context-aware suggestions
  behaviour add symbol taking name and kind and file
    let symbol = map
      symbol set "name" to name
      symbol set "kind" to kind
      symbol set "file" to file
    end

    if open_file_symbols has file
      let symbols = open_file_symbols get file
      add symbol to symbols
      open_file_symbols set file to symbols
    else
      let new_list = list of 0
      add symbol to new_list
      open_file_symbols set file to new_list
    end
  end

  ## Scans file content to extract declarations and add them to the database
  ## Recognizes patterns:
  ##   "make kind called X"  -> type symbol
  ##   "behaviour X"         -> function/behaviour symbol
  ##   "define X"            -> function symbol
  ##   "let X"               -> variable symbol
  behaviour learn from file taking path and content
    let lines = list of 0
    let current_line = ""
    let i = 0
    let content_len = size of content

    repeat while i is less than content_len
      let ch = item i of content
      if ch is equal to "\n"
        add current_line to lines
        current_line = ""
      else
        current_line = current_line plus ch
      end
      i = i plus 1
    end
    if size of current_line is greater than 0
      add current_line to lines
    end

    let line_num = 0
    let line_count = size of lines
    repeat while line_num is less than line_count
      let line = item line_num of lines

      if size of line is greater than 16
        let mk_prefix = call get_text_slice taking line and 0 and 16
        if mk_prefix is equal to "make kind called"
          let name_start = 17
          let name_end = name_start
          let line_len = size of line
          repeat while name_end is less than line_len and item name_end of line is not " " and item name_end of line is not "\t"
            name_end = name_end plus 1
          end
          if name_end is greater than name_start
            let type_name = call get_text_slice taking line and name_start and name_end
            call add_symbol taking type_name and "type" and path
          end
        end
      end

      if size of line is greater than 10
        let bh_prefix = call get_text_slice taking line and 0 and 10
        if bh_prefix is equal to "behaviour "
          let name_start = 10
          let line_len = size of line
          let name_end = name_start
          repeat while name_end is less than line_len and item name_end of line is not " " and item name_end of line is not "\t"
            name_end = name_end plus 1
          end
          if name_end is greater than name_start
            let func_name = call get_text_slice taking line and name_start and name_end
            call add_symbol taking func_name and "behaviour" and path
          end
        end
      end

      if size of line is greater than 7
        let df_prefix = call get_text_slice taking line and 0 and 7
        if df_prefix is equal to "define "
          let name_start = 7
          let line_len = size of line
          let name_end = name_start
          repeat while name_end is less than line_len and item name_end of line is not " " and item name_end of line is not "\t"
            name_end = name_end plus 1
          end
          if name_end is greater than name_start
            let func_name = call get_text_slice taking line and name_start and name_end
            call add_symbol taking func_name and "function" and path
          end
        end
      end

      if size of line is greater than 4
        if item 0 of line is "l" and item 1 of line is "e" and item 2 of line is "t" and item 3 of line is " "
          let name_start = 4
          let line_len = size of line
          let name_end = name_start
          repeat while name_end is less than line_len and item name_end of line is not " " and item name_end of line is not "\t" and item name_end of line is not "="
            name_end = name_end plus 1
          end
          if name_end is greater than name_start
            let var_name = call get_text_slice taking line and name_start and name_end
            call add_symbol taking var_name and "variable" and path
          end
        end
      end

      line_num = line_num plus 1
    end
  end

  ## Scores a completion candidate against the prefix
  ##   exact match     -> 100
  ##   starts with     -> 50
  ##   contains        -> 10
  ##   no match        -> 0
  behaviour score taking completion and prefix
    if completion is equal to prefix
      give back 100
    end

    let prefix_len = size of prefix
    let comp_prefix = call get_text_slice taking completion and 0 and prefix_len
    if comp_prefix is equal to prefix
      give back 50
    end

    let comp_len = size of completion
    let i = 0
    repeat while i is less than (comp_len minus prefix_len plus 1)
      let slice = call get_text_slice taking completion and i and (i plus prefix_len)
      if slice is equal to prefix
        give back 10
      end
      i = i plus 1
    end

    give back 0
  end

  ## Returns the highest-scored completion from the last query
  ## Resets current_index to 0 (first candidate)
  behaviour complete
    if size of completions is greater than 0
      best_completion = (first item of completions) get "text"
      current_index = 0
      give back best_completion
    end
    give back ""
  end

  ## Cycles to the next completion suggestion
  ## Wraps around to index 0 when reaching the end of the list
  behaviour cycle next
    let count = size of completions
    if count is equal to 0
      give back ""
    end

    current_index = current_index plus 1
    if current_index is greater than or equal to count
      current_index = 0
    end

    let candidate = item current_index of completions
    best_completion = candidate get "text"
    give back best_completion
  end

  ## Accepts the currently selected completion and returns its text
  ## Falls back to the first candidate if current_index is out of range
  behaviour accept
    if size of completions is equal to 0
      give back ""
    end

    if current_index is less than size of completions
      let candidate = item current_index of completions
      best_completion = candidate get "text"
    else
      best_completion = (first item of completions) get "text"
    end

    give back best_completion
  end
end
