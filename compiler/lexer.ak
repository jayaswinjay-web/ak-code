## AK CODE Lexer — written in AK CODE itself
## Tokenises AK CODE source code into a stream of tokens

make kind called Token
    has kind of type number
    has text of type text
    has line of type number
    has column of type number
    has doc_comment of type text
end

make kind called Lexer
    has source of type text
    has position of type number
    has line of type number
    has column of type number
    has tokens of type list of Token
    has pending_doc of type text

    when created taking source_text
        source = source_text
        position = 0
        line = 1
        column = 1
        tokens = list of
        pending_doc = ""
    end

    behaviour current character
        if position is less than size of source
            give back character at position of source
        end
        give back empty
    end

    behaviour advance
        position = position plus 1
        column = column plus 1
    end

    behaviour skip whitespace
        repeat while position is less than size of source and current character is space
            advance
        end
        repeat while position is less than size of source and current character is tab
            advance
            column = column plus 3
        end
    end

    behaviour read word
        let start = position
        repeat while position is less than size of source
            let ch = current character
            if ch is between "a" and "z" or ch is between "A" and "Z" or ch is between "0" and "9" or ch is "_"
                advance
            else
                break
            end
        end
        give back slice of source from start to position
    end

    behaviour read number
        let start = position
        let is decimal = false
        repeat while position is less than size of source
            let ch = current character
            if ch is between "0" and "9"
                advance
            else if ch is "." and is decimal is not true
                is decimal = true
                advance
            else
                break
            end
        end
        if is decimal
            give back token of type TOK_DECIMAL with text slice of source from start to position
        else
            give back token of type TOK_NUMBER with text slice of source from start to position
        end
    end

    behaviour read string
        let start = position
        advance  # skip opening quote
        repeat while position is less than size of source
            let ch = current character
            if ch is "\"
                advance  # skip backslash
                advance  # skip escaped char
            else if ch is quote
                advance  # skip closing quote
                give back token of type TOK_STRING with text slice of source from start plus 1 to position minus 1
            else
                advance
            end
        end
        give back token of type TOK_STRING with text slice of source from start to position
    end

    behaviour emit taking t
        ## Adds a token to the list, attaching any pending doc comment
        ## Doc comments are only attached to significant tokens (not newlines)
        if pending_doc is not "" and t kind is not TOK_NEWLINE and t kind is not TOK_EOF
            t doc_comment = pending_doc
            pending_doc = ""
        end
        add t to tokens
    end

    behaviour tokenize
        repeat while position is less than size of source
            skip whitespace
            let ch = current character
            if ch is empty
                break
            end
            if ch is "#"
                advance
                let next_ch = current character
                if next_ch is "#"
                    ## Doc comment — capture text after ##
                    advance
                    let doc_start = position
                    repeat while position is less than size of source and current character is not newline
                        advance
                    end
                    let doc_text = slice of source from doc_start to position
                    ## Trim leading space from doc text
                    if size of doc_text is greater than 0 and character at 0 of doc_text is space
                        doc_text = slice of doc_text from 1 to size of doc_text
                    end
                    ## Append to pending_doc (support multi-line ## blocks)
                    if pending_doc is not ""
                        pending_doc = pending_doc plus newline plus doc_text
                    else
                        pending_doc = doc_text
                    end
                else
                    ## Single # comment — skip rest of line
                    repeat while position is less than size of source and current character is not newline
                        advance
                    end
                end
            else if ch is quote
                self emit read string
            else if ch is between "0" and "9"
                self emit read number
            else if ch is between "a" and "z" or ch is between "A" and "Z" or ch is "_"
                let word = read word
                let tok type = classify word
                self emit token of type tok type with text word
            else if ch is ","
                self emit token of type TOK_COMMA with text ","
                advance
            else if ch is "."
                self emit token of type TOK_DOT with text "."
                advance
            else if ch is "("
                self emit token of type TOK_LPAREN with text "("
                advance
            else if ch is ")"
                self emit token of type TOK_RPAREN with text ")"
                advance
            else if ch is "["
                self emit token of type TOK_LBRACKET with text "["
                advance
            else if ch is "]"
                self emit token of type TOK_RBRACKET with text "]"
                advance
            else if ch is "="
                self emit token of type TOK_EQUALS with text "="
                advance
            else if ch is newline
                self emit token of type TOK_NEWLINE with text "newline"
                advance
                line = line plus 1
                column = 1
            else
                advance  # skip unknown
            end
        end
        self emit token of type TOK_EOF with text "eof"
        give back tokens
    end

    behaviour classify taking word
        ## Check if word is a keyword and return the appropriate token type
        if word is "let" give back TOK_KEYWORD end
        if word is "always" give back TOK_KEYWORD end
        if word is "show" give back TOK_KEYWORD end
        if word is "ask" give back TOK_KEYWORD end
        if word is "if" give back TOK_KEYWORD end
        if word is "else" give back TOK_KEYWORD end
        if word is "end" give back TOK_KEYWORD end
        if word is "repeat" give back TOK_KEYWORD end
        if word is "while" give back TOK_KEYWORD end
        if word is "for" give back TOK_KEYWORD end
        if word is "each" give back TOK_KEYWORD end
        if word is "count" give back TOK_KEYWORD end
        if word is "from" give back TOK_KEYWORD end
        if word is "to" give back TOK_KEYWORD end
        if word is "down" give back TOK_KEYWORD end
        if word is "define" give back TOK_KEYWORD end
        if word is "taking" give back TOK_KEYWORD end
        if word is "give" give back TOK_KEYWORD end
        if word is "back" give back TOK_KEYWORD end
        if word is "make" give back TOK_KEYWORD end
        if word is "kind" give back TOK_KEYWORD end
        if word is "called" give back TOK_KEYWORD end
        if word is "has" give back TOK_KEYWORD end
        if word is "behaviour" give back TOK_KEYWORD end
        if word is "when" give back TOK_KEYWORD end
        if word is "created" give back TOK_KEYWORD end
        if word is "new" give back TOK_KEYWORD end
        if word is "with" give back TOK_KEYWORD end
        if word is "try" give back TOK_KEYWORD end
        if word is "catch" give back TOK_KEYWORD end
        if word is "any" give back TOK_KEYWORD end
        if word is "error" give back TOK_KEYWORD end
        if word is "finally" give back TOK_KEYWORD end
        if word is "bring" give back TOK_KEYWORD end
        if word is "in" give back TOK_KEYWORD end
        if word is "match" give back TOK_KEYWORD end
        if word is "it" give back TOK_KEYWORD end
        if word is "is" give back TOK_IS end
        if word is "not" give back TOK_NOT end
        if word is "and" give back TOK_AND end
        if word is "or" give back TOK_OR end
        if word is "true" give back TOK_BOOL end
        if word is "false" give back TOK_BOOL end
        if word is "empty" give back TOK_EMPTY end
        if word is "plus" give back TOK_PLUS_WORD end
        if word is "minus" give back TOK_MINUS_WORD end
        if word is "times" give back TOK_TIMES_WORD end
        if word is "mod" give back TOK_MOD end
        if word is "list" give back TOK_KEYWORD end
        if word is "map" give back TOK_KEYWORD end
        if word is "of" give back TOK_KEYWORD end
        if word is "type" give back TOK_KEYWORD end
        if word is "maybe" give back TOK_KEYWORD end
        if word is "do" give back TOK_KEYWORD end
        if word is "background" give back TOK_KEYWORD end
        if word is "wait" give back TOK_KEYWORD end
        if word is "for" give back TOK_KEYWORD end
        if word is "all" give back TOK_KEYWORD end
        if word is "extends" give back TOK_KEYWORD end
        if word is "parent" give back TOK_KEYWORD end
        if word is "server" give back TOK_KEYWORD end
        if word is "port" give back TOK_KEYWORD end
        if word is "page" give back TOK_KEYWORD end
        if word is "plot" give back TOK_KEYWORD end
        if word is "solve" give back TOK_KEYWORD end
        if word is "train" give back TOK_KEYWORD end
        if word is "model" give back TOK_KEYWORD end
        if word is "layer" give back TOK_KEYWORD end
        if word is "predict" give back TOK_KEYWORD end
        if word is "test" give back TOK_KEYWORD end
        if word is "suite" give back TOK_KEYWORD end
        if word is "expect" give back TOK_KEYWORD end
        if word is "run" give back TOK_KEYWORD end
        if word is "async" give back TOK_KEYWORD end
        if word is "await" give back TOK_KEYWORD end
        if word is "implements" give back TOK_KEYWORD end
        if word is "interface" give back TOK_KEYWORD end
        if word is "manual" give back TOK_KEYWORD end
        if word is "mode" give back TOK_KEYWORD end
        if word is "protocol" give back TOK_KEYWORD end
        if word is "requires" give back TOK_KEYWORD end
        if word is "results" give back TOK_KEYWORD end
        if word is "add" give back TOK_KEYWORD end
        if word is "as" give back TOK_KEYWORD end
        if word is "button" give back TOK_KEYWORD end
        if word is "clicked" give back TOK_KEYWORD end
        if word is "column" give back TOK_KEYWORD end
        if word is "connect" give back TOK_KEYWORD end
        if word is "create" give back TOK_KEYWORD end
        if word is "data" give back TOK_KEYWORD end
        if word is "database" give back TOK_KEYWORD end
        if word is "default" give back TOK_KEYWORD end
        if word is "deviation" give back TOK_KEYWORD end
        if word is "find" give back TOK_KEYWORD end
        if word is "first" give back TOK_KEYWORD end
        if word is "go" give back TOK_KEYWORD end
        if word is "input" give back TOK_KEYWORD end
        if word is "placeholder" give back TOK_KEYWORD end
        if word is "remove" give back TOK_KEYWORD end
        if word is "required" give back TOK_KEYWORD end
        if word is "root" give back TOK_KEYWORD end
        if word is "send" give back TOK_KEYWORD end
        if word is "set" give back TOK_KEYWORD end
        if word is "square" give back TOK_KEYWORD end
        if word is "standard" give back TOK_KEYWORD end
        if word is "table" give back TOK_KEYWORD end
        if word is "the" give back TOK_KEYWORD end
        if word is "unique" give back TOK_KEYWORD end
        if word is "update" give back TOK_KEYWORD end
        if word is "values" give back TOK_KEYWORD end
        if word is "where" give back TOK_KEYWORD end
        give back TOK_IDENTIFIER
    end
end
