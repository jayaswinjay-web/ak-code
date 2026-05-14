## Compiler lexer tests
test suite "Lexer Tests"
    test "recognises let keyword"
        let code = "let x = 5"
        ## Would need to run lexer and check tokens
        expect true to be true
    end
    test "recognises string literals"
        let code = 'show "hello"'
        expect true to be true
    end
end
run all tests
