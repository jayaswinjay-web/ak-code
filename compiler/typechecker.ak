## AK CODE Type Checker — verifies type correctness
## Ensures operations are performed on compatible types

make kind called TypeChecker
    has ast of type ASTNode
    has type map of type map  # maps variable names to types
    has errors of type list of text

    when created taking ast root
        ast = ast root
        type map = map end
        errors = list of
    end

    behaviour check
        if ast is empty
            add "No AST to type-check" to errors
            give back
        end
        check node ast
        if size of errors is greater than 0
            show "Type checking found" size of errors "error(s):"
            for each err in errors
                show err
            end
        else
            show "Type checking passed"
        end
    end

    behaviour check node taking node of type ASTNode
        if node is empty
            give back
        end

        if node kind is NODE_LET
            if size of node children is greater than 1
                let name node = item 0 of node children
                let value node = item 1 of node children
                let value type = get type of value node
                type map set name node text to value type
            end
        end

        if node kind is NODE_BINOP
            if size of node children is greater than 1
                let left = item 0 of node children
                let right = item 1 of node children
                let left type = get type of left
                let right type = get type of right
                if left type is not right type
                    if left type is "number" and right type is "decimal"
                        # Compatible: number can be promoted to decimal
                    else if left type is "decimal" and right type is "number"
                        # Compatible
                    else
                        add "Type mismatch: cannot use '" plus left type plus "' and '" plus right type plus "' in same operation" to errors
                    end
                end
            end
        end

        if node kind is NODE_SHOW
            # Any type can be shown
        end

        if node kind is NODE_DEFINE
            # Check function body
            if size of node children is greater than 1
                for each child in node children
                    check node child
                end
            end
        end

        if node kind is NODE_PROTOCOL
            # Protocol definition is a type contract -- validate its required behaviours
            if size of node children is greater than 0
                # First child is the protocol name, rest are required behaviours
                let protocol name = item 0 of node children
                if protocol name kind is NODE_IDENTIFIER
                    # Register protocol name as a type
                    type map set node text to "protocol"
                end
            end
        end

        if node kind is NODE_LAMBDA
            # Infer return type from body statements
            let inferred type = "unknown"
            if size of node children is greater than 0
                # Last child might be a return expression
                let last child = item size of node children minus 1 of node children
                if last child kind is NODE_GIVE_BACK and size of last child children is greater than 0
                    let return val = item 0 of last child children
                    inferred type = get type of return val
                end
            end
        end

        if node kind is NODE_ASYNC
            # Async functions implicitly return a future/promise type
            # The actual return type wraps the declared return type
            if size of node children is greater than 0
                let name node = item 0 of node children
                if name node kind is NODE_IDENTIFIER
                    type map set name node text to "future"
                end
            end
        end

        if node kind is NODE_AWAIT
            # Await unwraps the future/promise type to its contained type
            if size of node children is greater than 0
                let expr = item 0 of node children
                # The awaited expression should be a future type
            end
        end

        if node kind is NODE_MANUAL_MEMORY
            # Manual memory blocks bypass normal GC -- type check children as usual
            for each child in node children
                check node child
            end
            # Don't recursively check below -- we already did
        end

        # Recursively check all children
        for each child in node children
            check node child
        end
    end

    behaviour get type of taking node of type ASTNode
        if node is empty
            give back "empty"
        end
        if node kind is NODE_LITERAL
            if node text is "true" or node text is "false"
                give back "bool"
            end
            if node text is "empty"
                give back "empty"
            end
            # Check if it starts with quote
            if size of node text is greater than 0 and character at 0 of node text is quote
                give back "text"
            end
            # Check if contains decimal point
            let has dot = false
            for each ch in node text
                if ch is "."
                    has dot = true
                end
            end
            if has dot
                give back "decimal"
            end
            give back "number"
        end
        if node kind is NODE_IDENTIFIER
            let found = type map get node text
            if found is not empty
                give back found
            end
            give back "unknown"
        end
        if node kind is NODE_BINOP
            give back "number"
        end
        if node kind is NODE_CALL
            give back "unknown"
        end
        if node kind is NODE_LIST_LITERAL
            give back "list"
        end
        if node kind is NODE_MAP_LITERAL
            give back "map"
        end
        if node kind is NODE_LAMBDA
            give back "function"
        end
        if node kind is NODE_ASYNC
            give back "future"
        end
        if node kind is NODE_AWAIT
            give back "unknown"
        end
        if node kind is NODE_PROTOCOL
            give back "protocol"
        end
        if node kind is NODE_MANUAL_MEMORY
            give back "empty"
        end
        give back "unknown"
    end

    behaviour has errors
        if size of errors is greater than 0
            give back true
        end
        give back false
    end
end
