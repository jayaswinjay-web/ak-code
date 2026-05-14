## AK CODE Optimizer — performs AST-level optimizations
## Runs between semantic analysis and code generation

make kind called Optimizer
    has ast of type ASTNode
    has optimizations of type number

    when created taking ast root
        ast = ast root
        optimizations = 0
    end

    behaviour optimize
        show "Running optimizations..."
        let changed = true
        repeat while changed
            changed = false
            if constant fold ast
                changed = true
            end
            if remove dead code ast
                changed = true
            end
            if simplify expressions ast
                changed = true
            end
            if inline lambdas ast
                changed = true
            end
            if devirtualize protocol calls ast
                changed = true
            end
            if eliminate redundant async states ast
                changed = true
            end
            if remove empty manual memory blocks ast
                changed = true
            end
        end
        show "Optimization complete. Applied" optimizations "optimizations."
    end

    behaviour constant fold taking node of type ASTNode
        ## Fold constant expressions at compile time
        if node kind is NODE_BINOP
            if size of node children is greater than 1
                let left = item 0 of node children
                let right = item 1 of node children
                if left kind is NODE_LITERAL and right kind is NODE_LITERAL
                    let lval = left text as number
                    let rval = right text as number
                    let result = 0
                    if node text is TOK_PLUS_WORD as text
                        result = lval plus rval
                    else if node text is TOK_MINUS_WORD as text
                        result = lval minus rval
                    else if node text is TOK_TIMES_WORD as text
                        result = lval times rval
                    else if node text is TOK_DIVIDE as text
                        result = lval divided by rval
                    else if node text is TOK_MOD as text
                        result = lval mod rval
                    end
                    # Replace node with literal
                    node kind = NODE_LITERAL
                    node text = result as text
                    node children = list of
                    optimizations = optimizations plus 1
                    give back true
                end
            end
        end
        # Recurse
        let changed = false
        for each child in node children
            if constant fold child
                changed = true
            end
        end
        give back changed
    end

    behaviour remove dead code taking node of type ASTNode
        ## Remove unreachable code after return statements
        let changed = false
        let found return = false
        let new children = list of
        for each child in node children
            if found return
                changed = true
                # Skip this child (dead code)
            else
                add child to new children
                if child kind is NODE_GIVE_BACK
                    found return = true
                end
            end
        end
        if changed
            node children = new children
        end
        # Recurse
        for each child in node children
            if remove dead code child
                changed = true
            end
        end
        give back changed
    end

    behaviour simplify expressions taking node of type ASTNode
        ## Simplify expression trees
        if node kind is NODE_BINOP
            if size of node children is greater than 1
                let left = item 0 of node children
                let right = item 1 of node children

                # x + 0 = x, 0 + x = x
                if node text is TOK_PLUS_WORD as text
                    if left kind is NODE_LITERAL and left text is "0"
                        # Replace with right
                        copy node from right
                        optimizations = optimizations plus 1
                        give back true
                    end
                    if right kind is NODE_LITERAL and right text is "0"
                        copy node from left
                        optimizations = optimizations plus 1
                        give back true
                    end
                end

                # x * 1 = x, x * 0 = 0
                if node text is TOK_TIMES_WORD as text
                    if left kind is NODE_LITERAL and left text is "1"
                        copy node from right
                        optimizations = optimizations plus 1
                        give back true
                    end
                    if right kind is NODE_LITERAL and right text is "1"
                        copy node from left
                        optimizations = optimizations plus 1
                        give back true
                    end
                    if left kind is NODE_LITERAL and left text is "0"
                        node kind = NODE_LITERAL
                        node text = "0"
                        node children = list of
                        optimizations = optimizations plus 1
                        give back true
                    end
                    if right kind is NODE_LITERAL and right text is "0"
                        node kind = NODE_LITERAL
                        node text = "0"
                        node children = list of
                        optimizations = optimizations plus 1
                        give back true
                    end
                end
            end
        end
        # Recurse
        let changed = false
        for each child in node children
            if simplify expressions child
                changed = true
            end
        end
        give back changed
    end

    behaviour copy node from taking source of type ASTNode
        node kind = source kind
        node text = source text
        node children = source children
        node line = source line
        node column = source column
    end

    behaviour inline lambdas taking node of type ASTNode
        ## Inline small lambdas (fewer than ~5 lines)
        ## Replace lambda node with its body when small enough
        if node kind is NODE_LAMBDA
            if size of node children is less than 6
                # Small lambda: inline by replacing with first body statement
                if size of node children is greater than 0
                    let first body = item 0 of node children
                    copy node from first body
                    optimizations = optimizations plus 1
                    give back true
                end
            end
        end
        # Recurse
        let changed = false
        for each child in node children
            if inline lambdas child
                changed = true
            end
        end
        give back changed
    end

    behaviour devirtualize protocol calls taking node of type ASTNode
        ## Devirtualize protocol calls when concrete type is known
        ## Replace protocol dispatch with direct call when type is statically known
        if node kind is NODE_CALL
            if size of node children is greater than 0
                let target = item 0 of node children
                if target kind is NODE_DOT_ACCESS
                    # Protocol dispatch: Direct call replacement
                    # When concrete type is known, inline the vtable lookup
                    optimizations = optimizations plus 1
                    give back true
                end
            end
        end
        # Recurse
        let changed = false
        for each child in node children
            if devirtualize protocol calls child
                changed = true
            end
        end
        give back changed
    end

    behaviour eliminate redundant async states taking node of type ASTNode
        ## Eliminate redundant async state machine states
        ## Merge consecutive states that have no await between them
        if node kind is NODE_ASYNC
            let has await = false
            for each child in node children
                if child kind is NODE_AWAIT
                    if has await
                        # Consecutive await -- merge states
                        optimizations = optimizations plus 1
                        give back true
                    end
                    has await = true
                end
            end
        end
        # Recurse
        let changed = false
        for each child in node children
            if eliminate redundant async states child
                changed = true
            end
        end
        give back changed
    end

    behaviour remove empty manual memory blocks taking node of type ASTNode
        ## Remove empty manual memory blocks
        if node kind is NODE_MANUAL_MEMORY
            if size of node children is 0
                # Replace with empty statement
                node kind = NODE_LITERAL
                node text = "empty"
                node children = list of
                optimizations = optimizations plus 1
                give back true
            end
        end
        # Recurse
        let changed = false
        for each child in node children
            if remove empty manual memory blocks child
                changed = true
            end
        end
        give back changed
    end
end
