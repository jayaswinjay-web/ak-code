## AK CODE Error Module — error types and handling
## Provides error types and utilities for robust error handling

make kind called Error
    has message of type text
    has code of type number
    has line of type number
    has column of type number
    has stack trace of type list of text

    when created taking msg
        message = msg
        code = 0
        line = 0
        column = 0
        stack trace = list of
    end

    behaviour with code taking num
        code = num
        give back self
    end

    behaviour with line taking line num and col num
        line = line num
        column = col num
        give back self
    end

    behaviour add to trace taking location
        add location to stack trace
        give back self
    end

    behaviour as text
        let result = "Error: " plus message
        if code is not 0
            result = result plus " (code: " plus code as text plus ")"
        end
        if line is not 0
            result = result plus " at line " plus line as text
            if column is not 0
                result = result plus ", column " plus column as text
            end
        end
        if size of stack trace is greater than 0
            result = result plus "\nStack trace:"
            for each frame in stack trace
                result = result plus "\n  " plus frame
            end
        end
        give back result
    end
end

define throw taking message
    ## Throws an error with the given message
    ## Example: throw "Something went wrong"
    let err = new Error with message
    raise err
end

define throw with code taking message and code
    ## Throws an error with a message and error code
    let err = new Error with message
    err code = code
    raise err
end

define try operation taking action and error handler
    ## Safely executes an operation with error handling
    ## Returns the result or calls the error handler
    try
        let result = action
        give back result
    catch any error as e
        error handler e
        give back empty
    end
end

define assert taking condition and message
    ## Asserts that a condition is true, throwing an error if not
    ## Example: assert x is greater than 0 "x must be positive"
    if condition is not true
        let err = new Error with message
        err line = 0  # In real impl, capture call site
        err column = 0
        raise err
    end
end

define assert equal taking expected and actual and message
    ## Asserts that two values are equal
    if expected is not actual
        let msg = message
        if msg is empty
            msg = "Expected " plus expected as text plus " but got " plus actual as text
        end
        throw msg
    end
end

define assert not error taking result and message
    ## Asserts that a result is not an error
    if result is empty
        let msg = message
        if msg is empty
            msg = "Unexpected error (empty result)"
        end
        throw msg
    end
end

define try parse taking text
    ## Safely parses a number from text, returning a result
    try
        let num = text as number
        give back num
    catch any error
        give back empty
    end
end

define wrap error taking operation
    ## Wraps an operation in consistent error handling
    try
        let result = operation
        give back result
    catch division by zero
        show "Error: Division by zero"
        give back empty
    catch index out of bounds
        show "Error: Index out of bounds"
        give back empty
    catch any error as e
        show "Error:" e message
        give back empty
    end
end
