## AK CODE Basic Language Tests
## Tests basic language features

test suite "Variable Declarations"
    test "let binds a string"
        let name = "Alice"
        expect name to be "Alice"
    end

    test "let binds a number"
        let age = 30
        expect age to be 30
    end

    test "let binds a decimal"
        let score = 95.5
        expect score to be 95.5
    end

    test "let binds a boolean"
        let active = true
        expect active to be true
    end

    test "let binds empty"
        let nothing = empty
        expect nothing to be empty
    end
end

test suite "Arithmetic"
    test "addition"
        let result = 5 plus 3
        expect result to be 8
    end

    test "subtraction"
        let result = 10 minus 4
        expect result to be 6
    end

    test "multiplication"
        let result = 6 times 7
        expect result to be 42
    end

    test "division"
        let result = 20 divided by 4
        expect result to be 5
    end

    test "modulo"
        let result = 17 mod 5
        expect result to be 2
    end
end

test suite "Comparisons"
    test "is equals"
        expect 5 is 5 to be true
    end

    test "is not"
        expect 5 is not 3 to be true
    end

    test "greater than"
        expect 10 is greater than 5 to be true
    end

    test "less than"
        expect 3 is less than 7 to be true
    end

    test "between"
        expect 5 is between 1 and 10 to be true
    end
end

test suite "String Operations"
    test "string concatenation"
        let hello = "Hello" plus " " plus "World"
        expect hello to be "Hello World"
    end

    test "string length"
        let len = size of "Hello"
        expect len to be 5
    end
end

test suite "Lists"
    test "create list"
        let items = list of 1 2 3
        expect size of items to be 3
    end

    test "list access"
        let items = list of "a" "b" "c"
        expect item 1 of items to be "b"
    end

    test "add to list"
        let items = list of 1 2
        add 3 to items
        expect size of items to be 3
    end
end

test suite "Functions"
    test "simple function"
        define double taking x
            give back x times 2
        end
        expect double 5 to be 10
    end

    test "function with multiple args"
        define add taking a and b
            give back a plus b
        end
        expect add 3 and 4 to be 7
    end
end

test suite "Conditionals"
    test "if true"
        let result = "no"
        if true
            result = "yes"
        end
        expect result to be "yes"
    end

    test "if else"
        let result = ""
        if false
            result = "true branch"
        else
            result = "false branch"
        end
        expect result to be "false branch"
    end
end

test suite "Loops"
    test "repeat while"
        let count = 0
        let i = 0
        repeat while i is less than 5
            i = i plus 1
            count = count plus 1
        end
        expect count to be 5
    end

    test "for each"
        let items = list of 10 20 30
        let sum = 0
        for each item in items
            sum = sum plus item
        end
        expect sum to be 60
    end
end

test suite "Constants"
    test "always declaration"
        always PI = 3.14159
        expect PI to be 3.14159
    end
end

run all tests
show "All basic language tests completed!"
