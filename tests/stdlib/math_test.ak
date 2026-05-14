## Math module tests
test suite "Math Operations"
    test "addition"
        let result = 10 plus 5
        expect result to be 15
    end
    test "subtraction"
        let result = 10 minus 3
        expect result to be 7
    end
    test "multiplication"
        let result = 6 times 7
        expect result to be 42
    end
end
run all tests
