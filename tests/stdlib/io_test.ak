## IO module tests
test suite "IO Operations"
    test "print does not crash"
        show "Testing print"
        expect true to be true
    end
    test "string can be read"
        let msg = "Hello"
        expect msg to be "Hello"
    end
end
run all tests
