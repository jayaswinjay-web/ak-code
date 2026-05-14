## AK CODE Semantic Analyser — checks code for semantic correctness
## Runs after parsing, before code generation

make kind called Symbol
    has name of type text
    has kind of type text  # "variable", "function", "class"
    has type of type text  # "text", "number", "decimal", "bool", "empty", "list", "map"
    has defined at of type number
end

make kind called SemanticAnalyser
    has ast of type ASTNode
    has symbols of type list of Symbol
    has errors of type list of text

    when created taking ast root
        ast = ast root
        symbols = list of
        errors = list of
    end

    behaviour analyse
        if ast is empty
            add "No AST to analyse" to errors
            give back
        end
        if ast kind is NODE_PROGRAM
            for each child in ast children
                analyse node child
            end
        end
        if errors is empty
            show "Semantic analysis passed"
        else
            for each err in errors
                show "Semantic error:" err
            end
        end
    end

    behaviour analyse node taking node of type ASTNode
        if node is empty
            give back
        end
        if node kind is NODE_LET
            # Variable declaration
            if size of node children is greater than 0
                let name node = item 0 of node children
                if name node kind is NODE_IDENTIFIER
                    # Check for duplicate
                    let existing = find symbol name node text
                    if existing is not empty
                        add "Variable '" plus node text plus "' is already defined" to errors
                    else
                        let sym = new Symbol
                        sym name = name node text
                        sym kind = "variable"
                        sym defined at = 0
                        add sym to symbols
                    end
                end
            end
        end
        if node kind is NODE_DEFINE
            # Function definition
            if size of node children is greater than 0
                let name node = item 0 of node children
                if name node kind is NODE_IDENTIFIER
                    let sym = new Symbol
                    sym name = name node text
                    sym kind = "function"
                    sym defined at = 0
                    add sym to symbols
                end
            end
        end
        if node kind is NODE_PROTOCOL
            # Protocol definitions must have at least one required behaviour
            if size of node children is less than 2
                add "Protocol '" plus node text plus "' must have at least one required behaviour" to errors
            end
        end
        if node kind is NODE_LAMBDA
            # Check lambda parameter names are unique
            # Parameters start after child 0 (first body statement)
            let seen params = map end
            for each child in node children
                if child kind is NODE_IDENTIFIER
                    let existing = seen params get child text
                    if existing is not empty
                        add "Duplicate parameter '" plus child text plus "' in lambda" to errors
                    else
                        seen params set child text to true
                    end
                end
            end
        end
        if node kind is NODE_ASYNC
            # Verify async functions don't contain blocking operations
            # Check all children for await usage
            let has await = false
            for each child in node children
                if child kind is NODE_AWAIT
                    has await = true
                end
                if child kind is NODE_CALL
                    # Flag non-async calls as potential blocking ops
                end
            end
        end
        if node kind is NODE_MANUAL_MEMORY
            # Verify manual memory blocks properly pair allocate/free
            let alloc count = 0
            let free count = 0
            for each child in node children
                if child kind is NODE_CALL
                    if child text is "allocate"
                        alloc count = alloc count plus 1
                    end
                    if child text is "free"
                        free count = free count plus 1
                    end
                end
            end
            if alloc count is not free count
                add "Unbalanced allocate/free in manual memory block: " plus alloc count plus " allocate vs " plus free count plus " free" to errors
            end
        end
        # Recursively check children
        for each child in node children
            analyse node child
        end
    end

    behaviour find symbol taking name of type text
        for each sym in symbols
            if sym name is name
                give back sym
            end
        end
        give back empty
    end

    behaviour has errors
        if size of errors is greater than 0
            give back true
        end
        give back false
    end
end
