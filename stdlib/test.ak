## AK CODE Test Framework Module
## Provides test runner infrastructure: kinds, assertions, and suite management

make kind called TestResult
    has name of type text
    has passed of type boolean
    has message of type text
    has duration of type number

    when created taking result_name
        name = result_name
        passed = true
        message = ""
        duration = 0
    end

    behaviour fail taking fail_message
        ## Marks this test result as failed with a message
        passed = false
        message = fail_message
    end

    behaviour set duration taking ms
        ## Records the duration of the test in milliseconds
        duration = ms
    end

    behaviour summary
        ## Returns a one-line summary string for this test result
        if passed
            give back name plus " PASSED (" plus duration as text plus "ms)"
        end
        give back name plus " FAILED: " plus message plus " (" plus duration as text plus "ms)"
    end
end

make kind called TestRunner
    has results of type list of TestResult
    has suite_count of type number
    has test_count of type number
    has passed_count of type number
    has failed_count of type number

    when created
        results = list of
        suite_count = 0
        test_count = 0
        passed_count = 0
        failed_count = 0
    end

    behaviour add result taking result
        ## Records a single test result and updates pass/fail counts
        add result to results
        test_count = test_count plus 1
        if result passed
            passed_count = passed_count plus 1
        else
            failed_count = failed_count plus 1
        end
    end

    behaviour run suite taking suite_name and tests
        ## Executes a named test suite containing multiple test blocks
        ## Prints progress for each test and collects results
        suite_count = suite_count plus 1
        show ""
        show "=== Suite: " plus suite_name plus " ==="
        for each test in tests
            let test_name = item 0 of test
            let test_fn = item 1 of test
            let result = new TestResult with test_name
            let start_time = os clock
            try
                test_fn
            catch any error as e
                result fail e
            end
            let end_time = os clock
            let elapsed = end_time minus start_time
            result set duration taking elapsed
            self add result taking result
            show "  " plus result summary
        end
    end

    behaviour run all
        ## Runs all test suites that have been registered
        ## This is the main entry point invoked by test files
        show "========================================"
        show "  AK CODE Test Runner"
        show "========================================"
        let start_all = os clock
        for each suite in suites
            self run suite taking item 0 of suite and item 1 of suite
        end
        let end_all = os clock
        show ""
        show "========================================"
        show "  All suites completed in " plus (end_all minus start_all) as text plus "ms"
        show "========================================"
        self show results
    end

    behaviour show results
        ## Prints the final summary of all test results
        ## Shows pass/fail counts, durations, and details of any failures
        show ""
        show "========================================"
        show "  Test Results Summary"
        show "========================================"
        show "  Suites:   " plus suite_count as text
        show "  Tests:    " plus test_count as text
        show "  Passed:   " plus passed_count as text
        show "  Failed:   " plus failed_count as text
        show "  Duration: " plus self total duration as text plus "ms"
        show "----------------------------------------"
        if failed_count is greater than 0
            show ""
            show "  FAILURE DETAILS:"
            for each result in results
                if result passed is not true
                    show "    - " plus result name
                    show "      " plus result message
                end
            end
        end
        show "========================================"
        if failed_count is 0
            show "  ALL TESTS PASSED"
        else
            show "  " plus failed_count as text plus " TEST(S) FAILED"
        end
        show "========================================"
    end

    behaviour total duration
        ## Computes the total elapsed duration across all recorded results
        let total = 0
        for each result in results
            total = total plus result duration
        end
        give back total
    end
end

make kind called Assertions
    ## Collection of assertion behaviours used within tests

    behaviour assert equal taking expected and actual and message
        ## Asserts that expected and actual values are equal
        ## Produces a readable failure message showing both values
        if expected is not actual
            let detail = "Expected [" plus expected as text plus "] but got [" plus actual as text plus "]"
            if message is not empty
                detail = message plus ": " plus detail
            end
            raise detail
        end
    end

    behaviour assert true taking value and message
        ## Asserts that a value is truthy
        if value is not true
            let detail = "Expected true but got " plus value as text
            if message is not empty
                detail = message plus ": " plus detail
            end
            raise detail
        end
    end

    behaviour assert error taking block
        ## Runs a block and verifies that it raises an error
        ## The test passes only if an error is thrown
        let threw = false
        try
            block
        catch any error
            threw = true
        end
        if threw is not true
            raise "Expected an error to be thrown but none was raised"
        end
    end

    behaviour assert contains taking haystack and needle
        ## Asserts that a string or list contains a specific value
        if haystack kind is list
            let found = false
            for each item in haystack
                if item is needle
                    found = true
                    break
                end
            end
            if found is not true
                raise "Expected list to contain [" plus needle as text plus "] but it did not"
            end
        else
            let pos = find needle in haystack
            if pos is empty
                raise "Expected string to contain [" plus needle as text plus "] but it did not"
            end
        end
    end
end

make kind called Expectation
    ## Wraps a value for fluent assertion chains
    ## Used by the expect keyword to provide to be / to contain / to be true / to throw
    has actual of type any

    when created taking val
        actual = val
    end

    behaviour to be taking expected
        ## Asserts that the wrapped value equals the expected value
        if actual is not expected
            raise "Expected [" plus expected as text plus "] but got [" plus actual as text plus "]"
        end
    end

    behaviour to contain taking value
        ## Asserts that the wrapped string or list contains the given value
        if actual kind is list
            let found = false
            for each item in actual
                if item is value
                    found = true
                    break
                end
            end
            if found is not true
                raise "Expected list to contain [" plus value as text plus "] but it did not"
            end
        else
            let pos = find value in actual
            if pos is empty
                raise "Expected string to contain [" plus value as text plus "] but it did not"
            end
        end
    end

    behaviour to be true
        ## Asserts that the wrapped value is truthy
        if actual is not true
            raise "Expected true but got " plus actual as text
        end
    end

    behaviour to throw
        ## Asserts that the wrapped block raises an error when called
        let threw = false
        try
            actual
        catch any error
            threw = true
        end
        if threw is not true
            raise "Expected an error to be thrown but none was raised"
        end
    end
end

## Global test runner instance used by the test DSL
let __test_runner = new TestRunner

define test suite taking name
    ## Declares a test suite with a name. Collects test blocks nested inside.
    ## Returns a list of the suite name and its tests for registration.
    give back list of name and list of
end

define test taking name
    ## Declares a single test case. Must be nested inside a test suite.
    ## Returns a pair of the test name and the test block.
    give back list of name and empty
end

define expect taking actual
    ## Begins a fluent assertion chain.
    ## Returns an Expectation that provides: to be, to contain, to be true, to throw
    give back new Expectation with actual
end

define run all tests
    ## Runs all registered test suites and prints the final results summary.
    __test_runner run all
end

define show test results
    ## Prints the test results summary at any point during execution.
    __test_runner show results
end
