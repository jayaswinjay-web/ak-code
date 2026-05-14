## AK CODE JSON Module — JSON serialization and deserialization
## Provides encode/decode for the JSON data format

define json serialize taking value
    ## Serializes a value to JSON string
    ## Handles: text, number, decimal, bool, empty, list, map
    give back json serialize value with indent 0
end

define json serialize with indent taking value and level
    let indent = ""
    let i = 0
    repeat while i is less than level
        indent = indent plus "  "
        i = i plus 1
    end

    # Check type of value
    if value is empty
        give back "null"
    end

    if value is true
        give back "true"
    end

    if value is false
        give back "false"
    end

    # Check if it's a number
    let str = value as text
    if is number str
        give back str
    end

    # Check if it's a list
    let is list = false
    try
        let s = size of value
        # Might be a list or text
        if str is not value as text  # It's not a simple text
            is list = true
        end
    catch any error
        is list = false
    end

    if is list
        if size of value is 0
            give back "[]"
        end
        let result = "[\n"
        let first = true
        for each item in value
            if first is not true
                result = result plus ",\n"
            end
            result = result plus indent plus "  "
            result = result plus json serialize with indent item and level plus 1
            first = false
        end
        result = result plus "\n" plus indent plus "]"
        give back result
    end

    # Otherwise treat as map/object
    let result = "{\n"
    let first = true
    for each key and val in value
        if first is not true
            result = result plus ",\n"
        end
        result = result plus indent plus "  "
        result = result plus json serialize key
        result = result plus ": "
        result = result plus json serialize with indent val and level plus 1
        first = false
    end
    result = result plus "\n" plus indent plus "}"
    give back result
end

define json parse taking text
    ## Parses a JSON string into AK CODE values
    ## Returns the parsed value (text, number, bool, empty, list, or map)
    let parser = new JSONParser with text
    give back parser parse value
end

make kind called JSONParser
    has input of type text
    has position of type number

    when created taking text
        input = text
        position = 0
    end

    behaviour current
        if position is less than size of input
            give back character at position of input
        end
        give back empty
    end

    behaviour advance
        position = position plus 1
    end

    behaviour skip whitespace
        repeat while current is not empty and (current is space or current is newline or current is carriage return or current is tab)
            advance
        end
    end

    behaviour parse value
        skip whitespace
        let ch = current
        if ch is empty
            give back empty
        end
        if ch is quote
            give back parse string
        end
        if ch is "{" or ch is "n"  # might be "null"
            # Check for null
            if ch is "n"
                give back parse nullish
            end
            give back parse object
        end
        if ch is "[" or ch is "t" or ch is "f"
            # Check for true/false
            if ch is "t" or ch is "f"
                give back parse boolean
            end
            give back parse array
        end
        # Must be number
        give back parse number
    end

    behaviour parse string
        advance  # skip opening quote
        let result = ""
        repeat while current is not empty and current is not quote
            if current is backslash
                advance
                if current is quote
                    result = result plus quote
                else if current is "n"
                    result = result plus newline
                else if current is "t"
                    result = result plus tab
                else if current is backslash
                    result = result plus backslash
                else
                    result = result plus current
                end
            else
                result = result plus current
            end
            advance
        end
        advance  # skip closing quote
        give back result
    end

    behaviour parse number
        let start = position
        if current is "-"
            advance
        end
        repeat while current is not empty and current is between "0" and "9"
            advance
        end
        if current is "."
            advance
            repeat while current is not empty and current is between "0" and "9"
                advance
            end
        end
        if current is "e" or current is "E"
            advance
            if current is "+" or current is "-"
                advance
            end
            repeat while current is not empty and current is between "0" and "9"
                advance
            end
        end
        let num text = slice of input from start to position
        give back num text as number
    end

    behaviour parse boolean
        if current is "t"
            advance  # t
            advance  # r
            advance  # u
            advance  # e
            give back true
        end
        # false
        advance  # f
        advance  # a
        advance  # l
        advance  # s
        advance  # e
        give back false
    end

    behaviour parse nullish
        # "null"
        advance  # n
        advance  # u
        advance  # l
        advance  # l
        give back empty
    end

    behaviour parse array
        advance  # skip [
        skip whitespace
        let result = list of
        if current is "]"
            advance
            give back result
        end
        repeat while current is not empty
            let val = parse value
            add val to result
            skip whitespace
            if current is ","
                advance
                skip whitespace
            else if current is "]"
                advance
                break
            end
        end
        give back result
    end

    behaviour parse object
        advance  # skip {
        skip whitespace
        let result = map end
        if current is "}"
            advance
            give back result
        end
        repeat while current is not empty
            skip whitespace
            let key = parse string
            skip whitespace
            if current is ":"
                advance
            end
            skip whitespace
            let val = parse value
            result set key to val
            skip whitespace
            if current is ","
                advance
            else if current is "}"
                advance
                break
            end
        end
        give back result
    end
end
