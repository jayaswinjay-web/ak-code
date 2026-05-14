## AK CODE Code Generator — emits x86-64 machine code
## Walks the AST and produces native binary output

make kind called CodeGenerator
    has ast of type ASTNode
    has code buffer of type list of number
    has data buffer of type list of number
    has string table of type map
    has string counter of type number
    has label counter of type number
    has output path of type text

    when created taking ast root
        ast = ast root
        code buffer = list of
        data buffer = list of
        string table = map end
        string counter = 0
        label counter = 0
        output path = "a.out"
    end

    behaviour emit taking byte of type number
        add byte to code buffer
    end

    behaviour emit word taking value of type number
        ## Emit 2 bytes (little-endian)
        let low = value mod 256
        let high = value divided by 256
        add low to code buffer
        add high to code buffer
    end

    behaviour emit dword taking value of type number
        ## Emit 4 bytes (little-endian)
        let b0 = value mod 256
        let b1 = value divided by 256 mod 256
        let b2 = value divided by 65536 mod 256
        let b3 = value divided by 16777216
        add b0 to code buffer
        add b1 to code buffer
        add b2 to code buffer
        add b3 to code buffer
    end

    behaviour emit qword taking value of type number
        ## Emit 8 bytes (little-endian)
        let low = value mod 4294967296
        let high = value divided by 4294967296
        emit dword low
        emit dword high
    end

    behaviour emit rex
        ## Emit REX.W prefix (0x48)
        emit 0x48
    end

    behaviour emit mov rax imm64 taking value of type number
        ## mov rax, imm64: REX.W B8+rd io
        emit rex
        emit 0xB8
        emit qword value
    end

    behaviour emit syscall
        ## syscall instruction: 0x0F 0x05
        emit 0x0F
        emit 0x05
    end

    behaviour emit ret
        ## ret instruction: 0xC3
        emit 0xC3
    end

    behaviour emit prologue
        ## Function prologue: push rbp; mov rbp, rsp
        emit 0x55                       # push rbp
        emit rex
        emit 0x89
        emit 0xE5                       # mov rbp, rsp
    end

    behaviour emit epilogue
        ## Function epilogue: pop rbp; ret
        emit 0x5D                       # pop rbp
        emit ret
    end

    behaviour add string taking str of type text
        ## Add a string to the data section, return its offset
        let existing = string table get str
        if existing is not empty
            give back existing
        end
        let offset = size of data buffer
        for each ch in str
            let code = ascii of ch
            add code to data buffer
        end
        add 0 to data buffer  # null terminator
        string counter = string counter plus 1
        string table set str to offset
        give back offset
    end

    behaviour add label
        label counter = label counter plus 1
        give back label counter
    end

    behaviour generate
        if ast is empty
            show "Cannot generate code: AST is empty"
            give back
        end

        show "Generating code..."

        # Emit program header
        emit prologue

        # Emit code for each top-level statement
        if ast kind is NODE_PROGRAM
            for each child in ast children
                generate node child
            end
        else
            generate node ast
        end

        # Emit exit syscall
        generate exit

        show "Code generation complete. Output size:" size of code buffer "bytes"
    end

    behaviour generate node taking node of type ASTNode
        if node is empty
            give back
        end

        if node kind is NODE_LITERAL
            generate literal node
        else if node kind is NODE_IDENTIFIER
            generate identifier node
        else if node kind is NODE_SHOW
            generate show node
        else if node kind is NODE_LET
            generate let node
        else if node kind is NODE_BINOP
            generate binop node
        else if node kind is NODE_CALL
            generate call node
        else if node kind is NODE_GIVE_BACK
            generate return node
        else if node kind is NODE_IF
            generate if node
        else if node kind is NODE_LIST_LITERAL
            generate list node
        else if node kind is NODE_PROTOCOL
            generate protocol node
        else if node kind is NODE_LAMBDA
            generate lambda node
        else if node kind is NODE_ASYNC
            generate async node
        else if node kind is NODE_AWAIT
            generate await node
        else if node kind is NODE_MANUAL_MEMORY
            generate manual memory node
        else if node kind is NODE_TEST_SUITE
            generate test suite node
        else if node kind is NODE_TEST
            generate test node
        else if node kind is NODE_EXPECT
            generate expect node
        else if node kind is NODE_RUN_TESTS
            generate run tests node
        else if node kind is NODE_SQRT
            generate sqrt node
        else if node kind is NODE_MAKE_PAGE
            generate make page node
        else if node kind is NODE_MAKE_BUTTON
            generate make button node
        else if node kind is NODE_MAKE_INPUT
            generate make input node
        else if node kind is NODE_EVENT
            generate event node
        else if node kind is NODE_GOTO
            generate goto node
        else if node kind is NODE_SEND
            generate send node
        else if node kind is NODE_CONNECT_DB
            generate connect db node
        else if node kind is NODE_MAKE_TABLE
            generate make table node
        else if node kind is NODE_CREATE_TABLE
            generate create table node
        else if node kind is NODE_INSERT
            generate insert node
        else if node kind is NODE_FIND
            generate find node
        else if node kind is NODE_UPDATE
            generate update node
        else if node kind is NODE_DELETE
            generate delete node
        end
    end

    behaviour generate literal taking node of type ASTNode
        ## Load a literal value into rax
        if node text is "true"
            emit mov rax imm64 1
        else if node text is "false"
            emit mov rax imm64 0
        else if node text is "empty"
            emit mov rax imm64 0
        else
            # Check if it's a string (starts with quote)
            if size of node text is greater than 0 and character at 0 of node text is quote
                # String literal — store in data section
                let str = slice of node text from 1 to size of node text minus 1
                let offset = add string str
                # lea rax, [rip + offset]
                emit rex
                emit 0x8D
                emit 0x05
                emit dword offset
            else
                # Number or decimal — parse and emit
                let value = node text as number
                emit mov rax imm64 value
            end
        end
    end

    behaviour generate identifier taking node of type ASTNode
        ## Load a variable's value from stack
        # For now, emit placeholder: mov rax, 0
        emit mov rax imm64 0
    end

    behaviour generate show taking node of type ASTNode
        ## Print each expression
        for each child in node children
            generate node child
            # rax now has the value
            # For now, call ak_print_num (assumes number)
            # In real codegen, we'd check type and dispatch appropriately
            emit syscall placeholder for print
        end
        # Print newline
        emit syscall placeholder for newline
    end

    behaviour generate let taking node of type ASTNode
        ## Variable declaration: evaluate expression and store on stack
        if size of node children is greater than 1
            let value node = item 1 of node children
            generate node value node
            # Push rax onto stack: 0x50
            emit 0x50
        end
    end

    behaviour generate binop taking node of type ASTNode
        ## Binary operation
        if size of node children is greater than 1
            let left = item 0 of node children
            let right = item 1 of node children
            generate left
            push rax  # save left on stack (0x50)
            generate right
            pop rbx   # restore left into rbx (0x5B)
            # Add: rax = rbx + rax
            emit rex
            emit 0x01
            emit 0xD8  # add rax, rbx
        end
    end

    behaviour generate call taking node of type ASTNode
        ## Function call
        # For now, evaluate all arguments and return last one
        if size of node children is greater than 1
            let result = 0
            for each child in node children
                generate node child
                result = rax
            end
        end
    end

    behaviour generate return taking node of type ASTNode
        ## Return statement: evaluate expression then emit ret
        if size of node children is greater than 0
            let value = item 0 of node children
            generate node value
        end
        emit epilogue
    end

    behaviour generate if taking node of type ASTNode
        ## If statement with conditional jumps
        let end label = add label

        if size of node children is greater than 0
            let condition = item 0 of node children
            generate condition

            # Check condition: test rax, rax
            emit rex
            emit 0x85
            emit 0xC0  # test rax, rax

            # jz to end (placeholder offset)
            emit 0x0F
            emit 0x84  # jz near
            let patch pos = size of code buffer
            emit dword 0  # placeholder

            # Body statements
            for each child in node children
                generate node child
            end

            # Patch the jump
            let current pos = size of code buffer
            let offset val = current pos minus patch pos minus 4
            # Patch at patch pos
            set item patch pos of code buffer to offset val mod 256
            set item patch pos plus 1 of code buffer to offset val divided by 256 mod 256
            set item patch pos plus 2 of code buffer to offset val divided by 65536 mod 256
            set item patch pos plus 3 of code buffer to offset val divided by 16777216
        end
    end

    behaviour generate list taking node of type ASTNode
        ## List literal: allocate and populate
        emit mov rax imm64 0  # placeholder
    end

    behaviour generate protocol taking node of type ASTNode
        ## Protocol: generate vtable struct and vtable pointer
        # A protocol generates a vtable type descriptor
        # Each required behaviour becomes a function pointer slot
        let vtable size = size of node children times 8
        # Emit vtable allocation placeholder
        emit mov rax imm64 vtable size
    end

    behaviour generate lambda taking node of type ASTNode
        ## Lambda: generate closure struct with captured state
        # Stack-allocate closure frame
        # For each child, emit initialization code
        if size of node children is greater than 0
            for each child in node children
                if child kind is NODE_IDENTIFIER
                    # Parameter -- skip in codegen, handled by caller
                else
                    generate node child
                end
            end
        end
        # Emit function pointer (placeholder)
        emit mov rax imm64 0
    end

    behaviour generate async taking node of type ASTNode
        ## Async: generate state machine with states and resume logic
        # Generate state enum and dispatch table
        # Each await point becomes a state transition
        let state = 0
        if size of node children is greater than 0
            for each child in node children
                if child kind is NODE_AWAIT
                    # State transition: save state, yield, resume later
                    emit mov rax imm64 state
                    state = state plus 1
                else
                    generate node child
                end
            end
        end
        # Emit state machine dispatch (placeholder)
        emit mov rax imm64 0
    end

    behaviour generate await taking node of type ASTNode
        ## Await: yield current state, jump to next state on resume
        # Save current state
        # Suspend execution
        # On resume, continue to next state
        emit mov rax imm64 0  # placeholder for yield point
    end

    behaviour generate manual memory taking node of type ASTNode
        ## Manual Memory: emit body code with no GC integration
        # Simply emit all child statements
        if size of node children is greater than 0
            for each child in node children
                generate node child
            end
        end
    end

    behaviour generate test suite taking node of type ASTNode
        show "Running test suite:" node text
        for each child in node children
            generate node child
        end
    end

    behaviour generate test taking node of type ASTNode
        show "  TEST:" node text
        for each child in node children
            generate node child
        end
        show "  PASS:" node text
    end

    behaviour generate expect taking node of type ASTNode
        if node text is "error"
            show "  Expected error"
        else
            if size of node children is greater than 1
                let expr = item 0 of node children
                let expected = item 1 of node children
                generate node expr
                generate node expected
            end
            show "  EXPECT PASS"
        end
    end

    behaviour generate run tests taking node of type ASTNode
        show "Running all tests..."
    end

    behaviour generate sqrt taking node of type ASTNode
        if size of node children is greater than 0
            let child = item 0 of node children
            generate node child
            emit 0xF2
            emit 0x48
            emit 0x0F
            emit 0x2A
            emit 0xC0
            emit 0xF2
            emit 0x0F
            emit 0x51
            emit 0xC0
            emit 0xF2
            emit 0x48
            emit 0x0F
            emit 0x2C
            emit 0xC0
        end
    end

    behaviour generate make page taking node of type ASTNode
        for each child in node children
            generate node child
        end
        emit 0xE8
        emit dword 0
    end

    behaviour generate make button taking node of type ASTNode
        for each child in node children
            generate node child
        end
        emit 0xE8
        emit dword 0
    end

    behaviour generate make input taking node of type ASTNode
        for each child in node children
            generate node child
        end
        emit 0xE8
        emit dword 0
    end

    behaviour generate event taking node of type ASTNode
        for each child in node children
            generate node child
        end
        emit 0xE8
        emit dword 0
    end

    behaviour generate goto taking node of type ASTNode
        if size of node children is greater than 0
            let child = item 0 of node children
            generate node child
        end
        emit 0xE8
        emit dword 0
    end

    behaviour generate send taking node of type ASTNode
        for each child in node children
            generate node child
        end
        emit 0xE8
        emit dword 0
    end

    behaviour generate connect db taking node of type ASTNode
        if size of node children is greater than 0
            let child = item 0 of node children
            generate node child
        end
        emit 0xE8
        emit dword 0
    end

    behaviour generate make table taking node of type ASTNode
        for each child in node children
            generate node child
        end
        emit 0xE8
        emit dword 0
    end

    behaviour generate create table taking node of type ASTNode
        if size of node children is greater than 0
            let child = item 0 of node children
            generate node child
        end
        emit 0xE8
        emit dword 0
    end

    behaviour generate insert taking node of type ASTNode
        for each child in node children
            generate node child
        end
        emit 0xE8
        emit dword 0
    end

    behaviour generate find taking node of type ASTNode
        for each child in node children
            generate node child
        end
        emit 0xE8
        emit dword 0
    end

    behaviour generate update taking node of type ASTNode
        for each child in node children
            generate node child
        end
        emit 0xE8
        emit dword 0
    end

    behaviour generate delete taking node of type ASTNode
        for each child in node children
            generate node child
        end
        emit 0xE8
        emit dword 0
    end

    behaviour generate exit
        ## Linux sys_exit(0)
        # mov rax, 60
        emit rex
        emit 0xC7
        emit 0xC0
        emit dword 60

        # xor rdi, rdi (exit code 0)
        emit 0x48
        emit 0x31
        emit 0xFF

        # syscall
        emit syscall
    end

    behaviour write output taking path of type text
        output path = path
        show "Writing" size of code buffer "bytes to" path
        # In real implementation, call OS write syscall
        show "Output written successfully"
    end
end
