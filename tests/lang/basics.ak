## Language basics test suite
test suite "Language Basics"
    test "string equality"
        expect "hello" to be "hello"
    end
    test "number arithmetic"
        let result = 2 plus 3
        expect result to be 5
    end
    test "list creation"
        let items = list of 1 2 3
        expect size of items to be 3
    end
    test "if condition"
        let x = 10
        if x is greater than 5
            expect true to be true
        end
    end
end
run all tests
