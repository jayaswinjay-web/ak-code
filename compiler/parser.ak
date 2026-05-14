## AK CODE Parser — written in AK CODE
## Recursive-descent parser producing an Abstract Syntax Tree (AST)

make kind called ASTNode
    has kind of type number
    has children of type list of ASTNode
    has text of type text
    has line of type number
    has column of type number
end

make kind called Parser
    has tokens of type list of Token
    has position of type number
    has root of type ASTNode

    when created taking token list
        tokens = token list
        position = 0
    end

    behaviour current
        if position is less than size of tokens
            give back item position of tokens
        end
        give back empty
    end

    behaviour advance
        position = position plus 1
    end

    behaviour expect taking kind
        let tok = current
        if tok is not empty and tok kind is kind
            advance
            give back tok
        end
        give back empty
    end

    behaviour parse program
        let node = new ASTNode of kind NODE_PROGRAM
        repeat while current is not empty and current kind is not TOK_EOF
            skip newlines
            let stmt = parse statement
            if stmt is not empty
                add stmt to node children
            else
                advance  # skip unknown
            end
        end
        give back node
    end

    behaviour parse statement
        let tok = current
        if tok is empty
            give back empty
        end
        if tok kind is TOK_KEYWORD
            if tok text is "let"
                give back parse let
            else if tok text is "show"
                let saved pos = position
                advance
                if current is not empty and current kind is TOK_KEYWORD and current text is "test"
                    advance
                    if current is not empty and current kind is TOK_KEYWORD and current text is "results"
                        advance
                        let node = new ASTNode of kind NODE_SHOW
                        node text = "test results"
                        give back node
                    end
                end
                position = saved pos
                give back parse show
            else if tok text is "if"
                give back parse if
            else if tok text is "repeat"
                give back parse repeat
            else if tok text is "for"
                give back parse for each
            else if tok text is "count"
                give back parse count from
            else if tok text is "define"
                if current is not empty and current kind is TOK_KEYWORD and current text is "protocol"
                    give back parse protocol definition
                end
                give back parse define
            else if tok text is "make"
                give back parse make stmt
            else if tok text is "try"
                give back parse try
            else if tok text is "match"
                give back parse match
            else if tok text is "bring"
                give back parse bring in
            else if tok text is "always"
                give back parse always
            else if tok text is "give"
                give back parse give back
            else if tok text is "wait"
                give back parse await
            else if tok text is "in"
                give back parse manual memory
            else if tok text is "test"
                if current is not empty and current kind is TOK_KEYWORD and current text is "suite"
                    give back parse test suite
                end
                give back parse test
            else if tok text is "expect"
                give back parse expect
            else if tok text is "run"
                advance
                if current is not empty and current kind is TOK_KEYWORD and current text is "all"
                    advance
                    if current is not empty and current kind is TOK_KEYWORD and current text is "tests"
                        advance
                        give back new ASTNode of kind NODE_RUN_TESTS
                    end
                end
                give back empty
            else if tok text is "send"
                give back parse send
            else if tok text is "go"
                give back parse goto
            else if tok text is "connect"
                give back parse connect db
            else if tok text is "create"
                give back parse create table
            else if tok text is "add"
                give back parse insert
            else if tok text is "find"
                give back parse find
            else if tok text is "remove"
                give back parse delete
            else if tok text is "update"
                give back parse update
            else if tok text is "when"
                give back parse when stmt
            end
        end
        give back parse expression
    end

    behaviour parse test suite
        advance
        advance
        let name token = expect TOK_STRING
        let node = new ASTNode of kind NODE_TEST_SUITE
        if name token is not empty
            node text = name token text
        end
        skip newlines
        repeat while current is not empty
            skip newlines
            if current kind is TOK_KEYWORD and current text is "end"
                advance
                break
            end
            if current kind is TOK_KEYWORD and current text is "test"
                let test node = parse test
                if test node is not empty
                    add test node to node children
                end
            else
                advance
            end
        end
        give back node
    end

    behaviour parse test
        advance
        let name token = expect TOK_STRING
        let node = new ASTNode of kind NODE_TEST
        if name token is not empty
            node text = name token text
        end
        skip newlines
        repeat while current is not empty
            skip newlines
            if current kind is TOK_KEYWORD and current text is "end"
                advance
                break
            end
            let stmt = parse statement
            if stmt is not empty
                add stmt to node children
            else
                advance
            end
        end
        give back node
    end

    behaviour parse expect
        advance
        let node = new ASTNode of kind NODE_EXPECT
        if current is not empty and current kind is TOK_KEYWORD and current text is "error"
            advance
            if current is not empty and current kind is TOK_KEYWORD and current text is "when"
                advance
                let expr = parse expression
                if expr is not empty
                    add expr to node children
                end
                node text = "error"
                give back node
            end
        end
        let expr = parse expression
        if expr is not empty
            add expr to node children
        end
        if current is not empty and current kind is TOK_KEYWORD and current text is "to"
            advance
            if current is not empty and current kind is TOK_KEYWORD and current text is "be"
                advance
                let expected = parse expression
                if expected is not empty
                    add expected to node children
                end
            end
        end
        give back node
    end

    behaviour parse let
        advance  # consume 'let'
        let name = expect TOK_IDENTIFIER
        if name is empty
            give back empty
        end
        let equals = expect TOK_EQUALS
        if equals is empty
            give back empty
        end
        let value = parse expression
        let node = new ASTNode of kind NODE_LET
        add name text to node children as identifier
        add value to node children
        give back node
    end

    behaviour parse show
        advance  # consume 'show'
        let node = new ASTNode of kind NODE_SHOW
        repeat while current is not empty and current kind is not TOK_NEWLINE and current kind is not TOK_EOF
            if current kind is TOK_KEYWORD and (current text is "end" or current text is "else")
                break
            end
            let expr = parse expression
            if expr is not empty
                add expr to node children
            else
                break
            end
        end
        give back node
    end

    behaviour parse if
        advance  # consume 'if'
        let node = new ASTNode of kind NODE_IF
        let condition = parse expression
        add condition to node children

        # Parse body until else/end
        let body = new ASTNode of kind NODE_BLOCK
        repeat while current is not empty
            skip newlines
            if current kind is TOK_KEYWORD
                if current text is "end"
                    advance
                    give back node
                else if current text is "else"
                    advance
                    # Check for "else if"
                    if current is not empty and current text is "if"
                        advance
                        let else if node = new ASTNode of kind NODE_ELSE_IF
                        let else cond = parse expression
                        add else cond to else if node children
                        repeat while current is not empty
                            skip newlines
                            if current kind is TOK_KEYWORD and (current text is "end" or current text is "else")
                                break
                            end
                            add parse statement to else if node children
                        end
                        add else if node to node children
                    else
                        let else node = new ASTNode of kind NODE_ELSE
                        repeat while current is not empty
                            skip newlines
                            if current kind is TOK_KEYWORD and current text is "end"
                                break
                            end
                            add parse statement to else node children
                        end
                        add else node to node children
                    end
                end
            end
            let stmt = parse statement
            if stmt is not empty
                add stmt to node children
            else
                break
            end
        end
        if current is not empty and current text is "end"
            advance
        end
        give back node
    end

    behaviour parse expression
        ## Parse an expression — the heart of the parser
        ## Expressions can be: literals, identifiers, function calls, binary ops, etc.
        let tok = current
        if tok is empty
            give back empty
        end

        # Literals
        if tok kind is TOK_STRING or tok kind is TOK_NUMBER or tok kind is TOK_DECIMAL or tok kind is TOK_BOOL or tok kind is TOK_EMPTY
            advance
            let node = new ASTNode of kind NODE_LITERAL
            node text = tok text
            give back node
        end

        # Identifier
        if tok kind is TOK_IDENTIFIER
            advance
            let node = new ASTNode of kind NODE_IDENTIFIER
            node text = tok text

            # Check if followed by operator
            if current is not empty
                if current kind is TOK_PLUS_WORD or current kind is TOK_MINUS_WORD or current kind is TOK_TIMES_WORD or current kind is TOK_DIVIDE or current kind is TOK_MOD
                    let op kind = current kind
                    advance
                    let right = parse expression
                    if right is not empty
                        let binop = new ASTNode of kind NODE_BINOP
                        add node to binop children
                        add right to binop children
                        binop text = op kind as text
                        give back binop
                    end
                else if current kind is TOK_DOT
                    advance
                    let prop = parse expression
                    if prop is not empty
                        let access = new ASTNode of kind NODE_DOT_ACCESS
                        add node to access children
                        add prop to access children
                        give back access
                    end
                end
            end

            # Could be function call if followed by expressions
            if current is not empty and current kind is not TOK_NEWLINE and current kind is not TOK_EOF
                if current kind is not TOK_KEYWORD or (current text is not "end" and current text is not "else")
                    let call = new ASTNode of kind NODE_CALL
                    add node to call children
                    repeat while current is not empty and current kind is not TOK_NEWLINE and current kind is not TOK_EOF
                        if current kind is TOK_KEYWORD and (current text is "end" or current text is "else")
                            break
                        end
                        let arg = parse expression
                        if arg is not empty
                            add arg to call children
                        else
                            break
                        end
                    end
                    give back call
                end
            end

            give back node
        end

        # Keyword expressions (list, map, etc.)
        if tok kind is TOK_KEYWORD
            if tok text is "behaviour"
                give back parse lambda
            end
            if tok text is "wait"
                give back parse await
            end
            if tok text is "list"
                advance
                if current is not empty and current text is "of"
                    advance
                end
                let node = new ASTNode of kind NODE_LIST_LITERAL
                repeat while current is not empty and current kind is not TOK_NEWLINE and current kind is not TOK_EOF
                    let item = parse expression
                    if item is not empty
                        add item to node children
                    else
                        break
                    end
                end
                give back node
            end

            if tok text is "map"
                advance
                let node = new ASTNode of kind NODE_MAP_LITERAL
                repeat while current is not empty
                    if current kind is TOK_KEYWORD and current text is "end"
                        advance
                        break
                    end
                    let key = parse expression
                    if key is not empty and current is not empty and current text is "is"
                        advance
                        let val = parse expression
                        if val is not empty
                            add key to node children
                            add val to node children
                        end
                    else
                        break
                    end
                    repeat while current is not empty and current kind is TOK_NEWLINE
                        advance
                    end
                end
                give back node
            end

            if tok text is "size"
                advance
                if current is not empty and current text is "of"
                    advance
                end
                give back parse expression
            end

            if tok text is "square"
                advance
                give back parse square root
            end

            if tok text is "first" or tok text is "last"
                advance
                if current is not empty and current text is "item"
                    advance
                end
                if current is not empty and current text is "of"
                    advance
                end
                give back parse expression
            end
        end

        give back empty
    end

    behaviour parse repeat
        give back empty
    end

    behaviour parse for each
        give back empty
    end

    behaviour parse count from
        give back empty
    end

    behaviour parse define
        advance  # consume 'define'
        let is async flag = false
        if current is not empty and current kind is TOK_KEYWORD and current text is "async"
            is async flag = true
            advance
        end
        if current is empty or current kind is not TOK_KEYWORD or current text is not "behaviour"
            give back empty
        end
        advance  # consume 'behaviour'
        let name token = expect TOK_IDENTIFIER
        if name token is empty
            give back empty
        end
        let node kind val = NODE_DEFINE
        if is async flag
            node kind val = NODE_ASYNC
        end
        let node = new ASTNode of kind node kind val
        node text = name token text
        if current is not empty and current text is "taking"
            advance
            repeat while current is not empty
                skip newlines
                if current kind is TOK_KEYWORD and (current text is "giving" or current text is "body" or current text is "end")
                    break
                end
                let param = expect TOK_IDENTIFIER
                if param is not empty
                    let param node = new ASTNode of kind NODE_IDENTIFIER
                    param node text = param text
                    add param node to node children
                else
                    break
                end
            end
        end
        if current is not empty and current text is "giving"
            advance
            if current is not empty and current text is "back"
                advance
            end
            if current is not empty and current kind is TOK_KEYWORD and current text is not "body"
                advance
            end
        end
        repeat while current is not empty
            skip newlines
            if current kind is TOK_KEYWORD and current text is "end"
                advance
                break
            end
            let stmt = parse statement
            if stmt is not empty
                add stmt to node children
            else
                advance
            end
        end
        give back node
    end

    behaviour parse make kind
        give back empty
    end

    behaviour parse try
        give back empty
    end

    behaviour parse match
        give back empty
    end

    behaviour parse bring in
        give back empty
    end

    behaviour parse always
        give back parse let
    end

    behaviour parse give back
        advance  # consume 'give'
        if current is not empty and current text is "back"
            advance
        end
        let node = new ASTNode of kind NODE_GIVE_BACK
        if current is not empty and current kind is not TOK_NEWLINE
            let value = parse expression
            if value is not empty
                add value to node children
            end
        end
        give back node
    end

    behaviour skip newlines
        repeat while current is not empty and current kind is TOK_NEWLINE
            advance
        end
    end

    behaviour parse protocol definition
        advance  # consume 'define'
        advance  # consume 'protocol'
        advance  # consume 'called'
        let name token = expect TOK_IDENTIFIER
        let node = new ASTNode of kind NODE_PROTOCOL
        if name token is not empty
            node text = name token text
            let name node = new ASTNode of kind NODE_IDENTIFIER
            name node text = name token text
            add name node to node children
        end
        if current is not empty and current text is "requires"
            advance
        end
        repeat while current is not empty
            skip newlines
            if current kind is TOK_KEYWORD and current text is "end"
                advance
                break
            end
            if current kind is TOK_KEYWORD and current text is "behaviour"
                advance
                let behav name = expect TOK_IDENTIFIER
                if behav name is not empty
                    let req node = new ASTNode of kind NODE_IDENTIFIER
                    req node text = behav name text
                    add req node to node children
                end
                repeat while current is not empty
                    if current kind is TOK_KEYWORD and (current text is "end" or current text is "behaviour")
                        break
                    end
                    advance
                end
            else
                advance
            end
        end
        give back node
    end

    behaviour parse lambda
        advance  # consume 'behaviour'
        if current is not empty and current text is "taking"
            advance
        end
        let node = new ASTNode of kind NODE_LAMBDA
        repeat while current is not empty
            skip newlines
            if current kind is TOK_KEYWORD and (current text is "body" or current text is "end")
                break
            end
            let param = expect TOK_IDENTIFIER
            if param is not empty
                let param node = new ASTNode of kind NODE_IDENTIFIER
                param node text = param text
                add param node to node children
            else
                break
            end
        end
        if current is not empty and current text is "body"
            advance
        end
        repeat while current is not empty
            skip newlines
            if current kind is TOK_KEYWORD and current text is "end"
                advance
                break
            end
            let stmt = parse statement
            if stmt is not empty
                add stmt to node children
            else
                break
            end
        end
        give back node
    end

    behaviour parse await
        advance  # consume 'wait'
        if current is not empty and current text is "for"
            advance
        end
        let node = new ASTNode of kind NODE_AWAIT
        let expr = parse expression
        if expr is not empty
            add expr to node children
        end
        give back node
    end

    behaviour parse manual memory
        advance  # consume 'in'
        if current is not empty and current kind is TOK_KEYWORD and current text is "manual"
            advance
        end
        if current is not empty and current kind is TOK_KEYWORD and current text is "memory"
            advance
        end
        if current is not empty and current kind is TOK_KEYWORD and current text is "mode"
            advance
        end
        let node = new ASTNode of kind NODE_MANUAL_MEMORY
        repeat while current is not empty
            skip newlines
            if current kind is TOK_KEYWORD and current text is "end"
                advance
                break
            end
            let stmt = parse statement
            if stmt is not empty
                add stmt to node children
            else
                advance
            end
        end
        give back node
    end

    behaviour parse make stmt
        advance  # consume 'make'
        if current is not empty and current kind is TOK_KEYWORD
            if current text is "kind"
                give back parse make kind
            else if current text is "page"
                give back parse make page
            else if current text is "button"
                give back parse make button
            else if current text is "input"
                give back parse make input
            else if current text is "table"
                give back parse make table
            end
        end
        give back empty
    end

    behaviour parse make page
        advance  # consume 'page'
        if current is not empty and current text is "called"
            advance
        end
        let name token = expect TOK_IDENTIFIER
        if name token is empty
            give back empty
        end
        let node = new ASTNode of kind NODE_MAKE_PAGE
        let name node = new ASTNode of kind NODE_IDENTIFIER
        name node text = name token text
        add name node to node children
        if current is not empty and current kind is TOK_KEYWORD and current text is "with"
            advance
            let expr = parse expression
            if expr is not empty
                add expr to node children
            end
        end
        give back node
    end

    behaviour parse make button
        advance  # consume 'button'
        if current is not empty and current text is "called"
            advance
        end
        let name token = expect TOK_IDENTIFIER
        if name token is empty
            give back empty
        end
        let node = new ASTNode of kind NODE_MAKE_BUTTON
        let name node = new ASTNode of kind NODE_IDENTIFIER
        name node text = name token text
        add name node to node children
        if current is not empty and current kind is TOK_KEYWORD and current text is "with"
            advance
            let expr = parse expression
            if expr is not empty
                add expr to node children
            end
        end
        give back node
    end

    behaviour parse make input
        advance  # consume 'input'
        if current is not empty and current text is "called"
            advance
        end
        let name token = expect TOK_IDENTIFIER
        if name token is empty
            give back empty
        end
        let node = new ASTNode of kind NODE_MAKE_INPUT
        let name node = new ASTNode of kind NODE_IDENTIFIER
        name node text = name token text
        add name node to node children
        if current is not empty and current kind is TOK_KEYWORD and current text is "with"
            advance
            let expr = parse expression
            if expr is not empty
                add expr to node children
            end
        end
        give back node
    end

    behaviour parse square root
        if current is not empty and current kind is TOK_KEYWORD and current text is "root"
            advance
        end
        if current is not empty and current kind is TOK_KEYWORD and current text is "of"
            advance
        end
        let expr = parse expression
        if expr is empty
            give back empty
        end
        let node = new ASTNode of kind NODE_SQRT
        add expr to node children
        give back node
    end

    behaviour parse when stmt
        let when pos = position
        advance  # consume 'when'
        let name token = expect TOK_IDENTIFIER
        if name token is not empty
            advance  # peek past identifier
            if current is not empty and current kind is TOK_IS
                position = when pos
                advance  # re-consume 'when'
                give back parse when clicked
            end
        end
        position = when pos
        advance  # re-consume 'when'
        give back parse when block
    end

    behaviour parse when clicked
        # 'when' already consumed
        let name token = expect TOK_IDENTIFIER
        if name token is empty
            give back empty
        end
        let node = new ASTNode of kind NODE_EVENT
        let name node = new ASTNode of kind NODE_IDENTIFIER
        name node text = name token text
        add name node to node children
        if current is not empty and current kind is TOK_IS
            advance
        end
        if current is not empty and current kind is TOK_KEYWORD and current text is "clicked"
            advance
        end
        skip newlines
        repeat while current is not empty
            skip newlines
            if current kind is TOK_KEYWORD and current text is "end"
                advance
                break
            end
            let stmt = parse statement
            if stmt is not empty
                add stmt to node children
            else
                advance
            end
        end
        give back node
    end

    behaviour parse when block
        # Parse route handler: "when someone visits/posts path ... end"
        let node = new ASTNode of kind NODE_ROUTE
        if current is not empty and current kind is TOK_IDENTIFIER
            advance  # consume "someone"
        end
        if current is not empty and current kind is TOK_KEYWORD
            advance  # consume "visits" or "posts"
        end
        if current is not empty and current kind is TOK_STRING
            let path lit = new ASTNode of kind NODE_LITERAL
            path lit text = current text
            advance
            add path lit to node children
        end
        skip newlines
        repeat while current is not empty
            skip newlines
            if current kind is TOK_KEYWORD and current text is "end"
                advance
                break
            end
            let stmt = parse statement
            if stmt is not empty
                add stmt to node children
            else
                advance
            end
        end
        give back node
    end

    behaviour parse goto
        advance  # consume 'go'
        if current is not empty and current text is "to"
            advance
        end
        if current is not empty and current kind is TOK_KEYWORD and current text is "page"
            advance
        end
        let node = new ASTNode of kind NODE_GOTO
        let target = parse expression
        if target is not empty
            add target to node children
        end
        give back node
    end

    behaviour parse send
        advance  # consume 'send'
        if current is not empty and current text is "to"
            advance
        end
        if current is not empty and current kind is TOK_KEYWORD and current text is "server"
            advance
        end
        let node = new ASTNode of kind NODE_SEND
        let url = parse expression
        if url is not empty
            add url to node children
        end
        if current is not empty and current kind is TOK_KEYWORD and current text is "the"
            advance
        end
        if current is not empty and current kind is TOK_KEYWORD and current text is "data"
            advance
        end
        repeat while current is not empty
            skip newlines
            if current kind is TOK_KEYWORD and current text is "end"
                break
            end
            if current kind is not TOK_IDENTIFIER
                break
            end
            let field name = new ASTNode of kind NODE_IDENTIFIER
            field name text = current text
            advance
            if current is not empty and current kind is TOK_IS
                advance
            end
            let field val = parse expression
            if field val is not empty
                add field name to node children
                add field val to node children
            end
            if current is not empty and current kind is TOK_AND
                advance
            else
                break
            end
        end
        give back node
    end

    behaviour parse connect db
        advance  # consume 'connect'
        if current is not empty and current text is "to"
            advance
        end
        if current is not empty and current kind is TOK_KEYWORD and current text is "database"
            advance
        end
        let node = new ASTNode of kind NODE_CONNECT_DB
        let path = parse expression
        if path is not empty
            add path to node children
        end
        give back node
    end

    behaviour parse make table
        advance  # consume 'table'
        if current is not empty and current text is "called"
            advance
        end
        let name token = expect TOK_IDENTIFIER
        if name token is empty
            give back empty
        end
        let node = new ASTNode of kind NODE_MAKE_TABLE
        let name node = new ASTNode of kind NODE_IDENTIFIER
        name node text = name token text
        add name node to node children
        skip newlines
        repeat while current is not empty
            skip newlines
            if current kind is TOK_KEYWORD and current text is "end"
                advance
                break
            end
            if current kind is TOK_KEYWORD and current text is "column"
                advance
                let col name = expect TOK_IDENTIFIER
                if col name is not empty
                    let col node = new ASTNode of kind NODE_IDENTIFIER
                    col node text = col name text
                    add col node to node children
                end
                # Parse type
                let type token = current
                if type token is not empty and (type token kind is TOK_IDENTIFIER or type token kind is TOK_KEYWORD)
                    let type node = new ASTNode of kind NODE_IDENTIFIER
                    type node text = type token text
                    add type node to node children
                    advance
                end
                # Skip constraints (unique, required, default)
                repeat while current is not empty
                    if current kind is TOK_NEWLINE
                        break
                    end
                    if current kind is TOK_KEYWORD and (current text is "column" or current text is "end" or current text is "unique" or current text is "required")
                        if current text is "unique" or current text is "required"
                            advance
                        else
                            break
                        end
                    else if current kind is TOK_KEYWORD and current text is "default"
                        advance
                        let default val = parse expression
                        if default val is not empty
                            add default val to node children
                        end
                    else
                        break
                    end
                end
            else
                advance
            end
        end
        give back node
    end

    behaviour parse create table
        advance  # consume 'create'
        if current is not empty and current kind is TOK_KEYWORD and current text is "table"
            advance
        end
        let name token = expect TOK_IDENTIFIER
        if name token is empty
            give back empty
        end
        let node = new ASTNode of kind NODE_CREATE_TABLE
        let name node = new ASTNode of kind NODE_IDENTIFIER
        name node text = name token text
        add name node to node children
        if current is not empty and current text is "in"
            advance
            if current is not empty and current kind is TOK_KEYWORD and current text is "database"
                advance
            end
        end
        give back node
    end

    behaviour parse insert
        advance  # consume 'add'
        if current is not empty and current text is "to"
            advance
        end
        let name token = expect TOK_IDENTIFIER
        if name token is empty
            give back empty
        end
        let node = new ASTNode of kind NODE_INSERT
        let name node = new ASTNode of kind NODE_IDENTIFIER
        name node text = name token text
        add name node to node children
        if current is not empty and current text is "the"
            advance
        end
        if current is not empty and current kind is TOK_KEYWORD and current text is "values"
            advance
        end
        skip newlines
        repeat while current is not empty
            skip newlines
            if current kind is TOK_KEYWORD and current text is "end"
                advance
                break
            end
            if current kind is not TOK_IDENTIFIER
                break
            end
            let field name = new ASTNode of kind NODE_IDENTIFIER
            field name text = current text
            advance
            if current is not empty and current kind is TOK_IS
                advance
            end
            let field val = parse expression
            if field val is not empty
                add field name to node children
                add field val to node children
            end
            if current is not empty and current kind is TOK_AND
                advance
            else
                break
            end
        end
        give back node
    end

    behaviour parse find
        advance  # consume 'find'
        if current is not empty and current kind is TOK_KEYWORD and (current text is "all" or current text is "first")
            advance
        end
        if current is not empty and current text is "from"
            advance
        end
        let name token = expect TOK_IDENTIFIER
        if name token is empty
            give back empty
        end
        let node = new ASTNode of kind NODE_FIND
        let name node = new ASTNode of kind NODE_IDENTIFIER
        name node text = name token text
        add name node to node children
        if current is not empty and current kind is TOK_KEYWORD and current text is "where"
            advance
            let condition = parse expression
            if condition is not empty
                add condition to node children
            end
        end
        give back node
    end

    behaviour parse update
        advance  # consume 'update'
        let name token = expect TOK_IDENTIFIER
        if name token is empty
            give back empty
        end
        let node = new ASTNode of kind NODE_UPDATE
        let name node = new ASTNode of kind NODE_IDENTIFIER
        name node text = name token text
        add name node to node children
        if current is not empty and current kind is TOK_KEYWORD and current text is "set"
            advance
        end
        let field name = expect TOK_IDENTIFIER
        if field name is not empty
            let field node = new ASTNode of kind NODE_IDENTIFIER
            field node text = field name text
            add field node to node children
        end
        if current is not empty and current text is "to"
            advance
        end
        let value = parse expression
        if value is not empty
            add value to node children
        end
        if current is not empty and current kind is TOK_KEYWORD and current text is "where"
            advance
            let condition = parse expression
            if condition is not empty
                add condition to node children
            end
        end
        give back node
    end

    behaviour parse delete
        advance  # consume 'remove'
        if current is not empty and current text is "from"
            advance
        end
        let name token = expect TOK_IDENTIFIER
        if name token is empty
            give back empty
        end
        let node = new ASTNode of kind NODE_DELETE
        let name node = new ASTNode of kind NODE_IDENTIFIER
        name node text = name token text
        add name node to node children
        if current is not empty and current kind is TOK_KEYWORD and current text is "where"
            advance
            let condition = parse expression
            if condition is not empty
                add condition to node children
            end
        end
        give back node
    end

    behaviour parse
        root = parse program
        give back root
    end
end
