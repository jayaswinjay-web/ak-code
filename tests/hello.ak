## Hello World test
test suite "Hello World"
    test "print hello"
        show "Hello from AK CODE"
        let name = "World"
        show "Hello" name
        expect true to be true
    end
    test "math works"
        let sum = 2 plus 2
        show "2 plus 2 is" sum
        expect sum to be 4
    end
end
run all tests
show test results
