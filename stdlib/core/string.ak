## AK CODE String Module — text manipulation
## Provides string operations for the standard library

define length of taking str
    ## Returns the number of characters in a string
    ## Example: length of "Hello" gives 5
    give back size of str
end

define uppercase taking str
    ## Converts all characters in a string to uppercase
    ## Example: uppercase "hello" gives "HELLO"
    let result = ""
    for each ch in str
        if ch is between "a" and "z"
            let code = ascii of ch
            code = code minus 32
            result = result plus character of code
        else
            result = result plus ch
        end
    end
    give back result
end

define lowercase taking str
    ## Converts all characters in a string to lowercase
    ## Example: lowercase "HELLO" gives "hello"
    let result = ""
    for each ch in str
        if ch is between "A" and "Z"
            let code = ascii of ch
            code = code plus 32
            result = result plus character of code
        else
            result = result plus ch
        end
    end
    give back result
end

define trim taking str
    ## Removes leading and trailing whitespace from a string
    ## Example: trim "  hello  " gives "hello"
    let start = 0
    let end = size of str

    # Trim leading whitespace
    repeat while start is less than end and character at start of str is space
        start = start plus 1
    end

    # Trim trailing whitespace
    repeat while end is greater than start and character at end minus 1 of str is space
        end = end minus 1
    end

    give back slice of str from start to end
end

define split taking str by delimiter
    ## Splits a string into a list of substrings by a delimiter
    ## Example: split "a,b,c" by "," gives list of "a" "b" "c"
    let result = list of
    let current = ""
    for each ch in str
        if ch is delimiter
            add current to result
            current = ""
        else
            current = current plus ch
        end
    end
    add current to result
    give back result
end

define join taking parts with separator
    ## Joins a list of strings into a single string with a separator
    ## Example: join list of "a" "b" "c" with "," gives "a,b,c"
    let result = ""
    let first = true
    for each part in parts
        if first is not true
            result = result plus separator
        end
        result = result plus part
        first = false
    end
    give back result
end

define replace taking search in text with replacement
    ## Replaces all occurrences of a substring with another string
    ## Example: replace "world" in "Hello world" with "there" gives "Hello there"
    let result = ""
    let i = 0
    let len = size of text
    let slen = size of search

    repeat while i is less than len
        # Check if search matches at position i
        let matches = true
        let j = 0
        repeat while j is less than slen
            if i plus j is greater than len or character at i plus j of text is not character at j of search
                matches = false
                break
            end
            j = j plus 1
        end
        if matches
            result = result plus replacement
            i = i plus slen
        else
            result = result plus character at i of text
            i = i plus 1
        end
    end
    give back result
end

define contains taking substr in text
    ## Checks if a string contains a substring
    ## Example: contains "world" in "Hello world" gives true
    let result = find substr in text
    if result is not empty
        give back true
    end
    give back false
end

define starts with taking prefix in text
    ## Checks if a string starts with a given prefix
    ## Example: starts with "Hello" in "Hello world" gives true
    if size of text is less than size of prefix
        give back false
    end
    let i = 0
    repeat while i is less than size of prefix
        if character at i of text is not character at i of prefix
            give back false
        end
        i = i plus 1
    end
    give back true
end

define ends with taking suffix in text
    ## Checks if a string ends with a given suffix
    ## Example: ends with "world" in "Hello world" gives true
    let text len = size of text
    let suffix len = size of suffix
    if text len is less than suffix len
        give back false
    end
    let i = 0
    repeat while i is less than suffix len
        let text pos = text len minus suffix len plus i
        if character at text pos of text is not character at i of suffix
            give back false
        end
        i = i plus 1
    end
    give back true
end

define substring of text from start to length
    ## Extracts a substring from a string
    ## Example: substring of "Hello world" from 0 to 5 gives "Hello"
    let end = start plus length
    if end is greater than size of text
        end = size of text
    end
    give back slice of text from start to end
end

define reverse taking str
    ## Reverses a string
    ## Example: reverse "hello" gives "olleh"
    let result = ""
    let i = size of str minus 1
    repeat while i is greater than or equal to 0
        result = result plus character at i of str
        i = i minus 1
    end
    give back result
end

define repeat of str count times
    ## Repeats a string a given number of times
    ## Example: repeat of "ab" 3 times gives "ababab"
    let result = ""
    let i = 0
    repeat while i is less than count
        result = result plus str
        i = i plus 1
    end
    give back result
end

define pad left taking str to length with char
    ## Pads a string on the left to reach a specified length
    ## Example: pad left "5" to 3 with "0" gives "005"
    let current = size of str
    if current is greater than or equal to length
        give back str
    end
    let result = ""
    let i = 0
    let needed = length minus current
    repeat while i is less than needed
        result = result plus char
        i = i plus 1
    end
    result = result plus str
    give back result
end

define pad right taking str to length with char
    ## Pads a string on the right to reach a specified length
    let current = size of str
    if current is greater than or equal to length
        give back str
    end
    let result = str
    let i = 0
    let needed = length minus current
    repeat while i is less than needed
        result = result plus char
        i = i plus 1
    end
    give back result
end

define is empty taking str
    ## Checks if a string is empty
    if size of str is 0
        give back true
    end
    give back false
end

define is number taking str
    ## Checks if a string represents a valid number
    if str is empty or str is ""
        give back false
    end
    let i = 0
    if character at 0 of str is "-" or character at 0 of str is "+"
        i = 1
    end
    let has dot = false
    repeat while i is less than size of str
        let ch = character at i of str
        if ch is "."
            if has dot
                give back false
            end
            has dot = true
        else if ch is not between "0" and "9"
            give back false
        end
        i = i plus 1
    end
    give back true
end

define to number taking str
    ## Converts a string to a number
    ## Returns 0 if the string is not a valid number
    let result = 0
    let sign = 1
    let i = 0
    let is decimal = false
    let decimal place = 1

    if size of str is 0
        give back 0
    end

    if character at 0 of str is "-"
        sign = -1
        i = 1
    else if character at 0 of str is "+"
        i = 1
    end

    repeat while i is less than size of str
        let ch = character at i of str
        if ch is "."
            is decimal = true
            decimal place = 10
        else if ch is between "0" and "9"
            if is decimal
                result = result plus (ch as number) divided by decimal place
                decimal place = decimal place times 10
            else
                result = result times 10 plus (ch as number)
            end
        end
        i = i plus 1
    end

    result = result times sign
    give back result
end
