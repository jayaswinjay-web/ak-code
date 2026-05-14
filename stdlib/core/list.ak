## AK CODE List Module — dynamic array operations
## Provides list manipulation functions for the standard library

define is empty taking lst
    ## Checks if a list has no items
    ## Example: is empty list of gives true
    if size of lst is 0
        give back true
    end
    give back false
end

define has items taking lst
    ## Checks if a list has at least one item
    if size of lst is greater than 0
        give back true
    end
    give back false
end

define first of taking lst
    ## Returns the first item in a list
    ## Example: first of list of "a" "b" "c" gives "a"
    if size of lst is greater than 0
        give back item 0 of lst
    end
    give back empty
end

define last of taking lst
    ## Returns the last item in a list
    ## Example: last of list of "a" "b" "c" gives "c"
    if size of lst is greater than 0
        give back item size of lst minus 1 of lst
    end
    give back empty
end

define rest of taking lst
    ## Returns all items in a list except the first
    ## Example: rest of list of "a" "b" "c" gives list of "b" "c"
    if size of lst is less than 2
        give back list of
    end
    let result = list of
    let i = 1
    repeat while i is less than size of lst
        add item i of lst to result
        i = i plus 1
    end
    give back result
end

define push taking item to lst
    ## Adds an item to the end of a list (alias for add)
    ## Example: push "d" to my_list
    add item to lst
end

define pop from taking lst
    ## Removes and returns the last item from a list
    ## Example: let item = pop from my_list
    if size of lst is 0
        give back empty
    end
    let last = item size of lst minus 1 of lst
    remove last from lst
    give back last
end

define unshift taking item to lst
    ## Adds an item to the beginning of a list
    ## Example: unshift "first" to my_list
    let result = list of item
    for each existing in lst
        add existing to result
    end
    # Replace lst contents (in a real implementation, this modifies in place)
    give back result
end

define shift from taking lst
    ## Removes and returns the first item from a list
    ## Example: let item = shift from my_list
    if size of lst is 0
        give back empty
    end
    let first = item 0 of lst
    remove first from lst
    give back first
end

define contains taking value in lst
    ## Checks if a list contains a specific value
    ## Example: contains "b" in list of "a" "b" "c" gives true
    for each item in lst
        if item is value
            give back true
        end
    end
    give back false
end

define index of taking value in lst
    ## Returns the index of a value in a list, or -1 if not found
    ## Example: index of "b" in list of "a" "b" "c" gives 1
    let i = 0
    for each item in lst
        if item is value
            give back i
        end
        i = i plus 1
    end
    give back -1
end

define remove at index from lst
    ## Removes the item at a specific index from a list
    let result = list of
    let i = 0
    for each item in lst
        if i is not index
            add item to result
        end
        i = i plus 1
    end
    lst = result
end

define slice of lst from start to end
    ## Returns a slice of a list from start index (inclusive) to end index (exclusive)
    let result = list of
    let i = start
    repeat while i is less than end and i is less than size of lst
        add item i of lst to result
        i = i plus 1
    end
    give back result
end

define map taking fn over lst
    ## Creates a new list by applying a function to each element
    ## Example: map (behaviour taking n give back n times 2 end) over list of 1 2 3
    let result = list of
    for each item in lst
        let transformed = fn item
        add transformed to result
    end
    give back result
end

define filter taking predicate over lst
    ## Creates a new list with only elements that pass a test
    let result = list of
    for each item in lst
        if predicate item
            add item to result
        end
    end
    give back result
end

define reduce taking fn over lst with initial
    ## Reduces a list to a single value by applying a function cumulatively
    let result = initial
    for each item in lst
        result = fn result and item
    end
    give back result
end

define for each taking action in lst
    ## Calls a function for each element in a list
    for each item in lst
        action item
    end
end

define sort taking lst
    ## Sorts a list in ascending order (simple bubble sort)
    let n = size of lst
    let i = 0
    repeat while i is less than n
        let j = 0
        repeat while j is less than n minus i minus 1
            let a = item j of lst
            let b = item j plus 1 of lst
            if a is greater than b
                # Swap
                set item j of lst to b
                set item j plus 1 of lst to a
            end
            j = j plus 1
        end
        i = i plus 1
    end
    give back lst
end

define reverse order of lst
    ## Reverses the order of items in a list
    let result = list of
    let i = size of lst minus 1
    repeat while i is greater than or equal to 0
        add item i of lst to result
        i = i minus 1
    end
    give back result
end

define flatten taking lst
    ## Flattens a list of lists into a single list
    let result = list of
    for each item in lst
        if item kind is list
            let nested = flatten item
            for each subitem in nested
                add subitem to result
            end
        else
            add item to result
        end
    end
    give back result
end

define unique taking lst
    ## Removes duplicate values from a list
    let result = list of
    for each item in lst
        if contains item in result is not true
            add item to result
        end
    end
    give back result
end

define zip taking list a and list b
    ## Combines two lists into a list of pairs
    let result = list of
    let n = size of a
    if size of b is less than n
        n = size of b
    end
    let i = 0
    repeat while i is less than n
        add item i of a to result
        add item i of b to result
        i = i plus 1
    end
    give back result
end
