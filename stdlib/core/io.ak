## AK CODE IO Module — reading and writing
## Provides input/output operations for the standard library

define print taking message
    ## Prints a message to stdout followed by a newline
    ## Example: print "Hello World"
    show message
end

define print many
    ## Prints multiple items separated by spaces
    ## Example: print many "The answer is" 42
    for each item in the list
        show item
    end
end

define print line
    ## Prints an empty line
    show ""
end

define read line
    ## Reads one line of text from stdin
    ## Returns the text entered by the user (without newline)
    ask " " and store in input
    give back input
end

define read file taking path
    ## Reads the entire contents of a file into a text string
    ## Example: let content = read file "data.txt"
    ## Opens the file, reads all bytes, and returns as text
    let handle = open file path for reading
    if handle is empty
        show "Error: Cannot open file" path
        give back empty
    end
    let content = read all from handle
    close handle
    give back content
end

define write file taking path and content
    ## Writes text content to a file, overwriting if it exists
    ## Example: write file "output.txt" with "Hello World"
    let handle = open file path for writing
    if handle is empty
        show "Error: Cannot write file" path
        give back false
    end
    write content to handle
    close handle
    give back true
end

define append to file taking path and content
    ## Appends text content to the end of a file
    ## Example: append to file "log.txt" with "New entry"
    let handle = open file path for appending
    if handle is empty
        show "Error: Cannot open file" path "for appending"
        give back false
    end
    write content to handle
    close handle
    give back true
end

define file exists taking path
    ## Checks if a file exists at the given path
    ## Returns true if the file exists, false otherwise
    let handle = open file path for reading
    if handle is not empty
        close handle
        give back true
    end
    give back false
end

define delete file taking path
    ## Deletes a file from the filesystem
    ## Example: delete file "temp.txt"
    ## Returns true if deletion was successful
    let result = os delete file path
    give back result
end

define copy file taking source and destination
    ## Copies a file from source path to destination path
    ## Example: copy file "original.txt" to "backup.txt"
    let content = read file source
    if content is empty
        give back false
    end
    let written = write file destination with content
    give back written
end

define format taking template and values
    ## Formats a string with placeholder values
    ## Example: format "Hello {name}" with map "name" is "Alice" end
    let result = template
    for each key and value in values
        let placeholder = "{" plus key plus "}"
        result = replace placeholder in result with value
    end
    give back result
end

define prompt taking message
    ## Shows a message and waits for user input
    ## Returns the input text
    show message
    ask "> " and store in input
    give back input
end

define confirm taking message
    ## Asks the user for yes/no confirmation
    ## Returns true if the user says yes
    show message "(yes/no)"
    ask "> " and store in answer
    if answer is "yes" or answer is "y"
        give back true
    end
    give back false
end

define choose taking prompt text and options
    ## Shows a numbered list of options and lets the user choose
    ## Returns the selected option text
    show prompt text
    let index = 1
    for each option in options
        show index ". " option
        index = index plus 1
    end
    ask "Enter your choice (1-" plus size of options as text plus "): " and store in choice
    let num = choice as number
    if num is between 1 and size of options
        give back item num minus 1 of options
    end
    give back empty
end
