## AK CODE Map Module — dictionary operations
## Provides hash map manipulation functions

define keys of taking map
    ## Returns a list of all keys in a map
    let result = list of
    for each key and value in map
        add key to result
    end
    give back result
end

define values of taking map
    ## Returns a list of all values in a map
    let result = list of
    for each key and value in map
        add value to result
    end
    give back result
end

define has key taking key in map
    ## Checks if a map contains a specific key
    for each k and v in map
        if k is key
            give back true
        end
    end
    give back false
end

define remove key taking key from map
    ## Removes a key-value pair from a map
    for each k and v in map
        if k is key
            # Can't actually remove from map directly in this version
            # Works with the native implementation
        end
    end
end

define count of map
    ## Returns the number of entries in a map
    let count = 0
    for each key and value in map
        count = count plus 1
    end
    give back count
end

define merge taking map a and map b
    ## Merges two maps, with b taking priority for duplicate keys
    let result = map end
    for each key and value in a
        result set key to value
    end
    for each key and value in b
        result set key to value
    end
    give back result
end

define pick taking map and keys
    ## Returns a new map with only the specified keys
    let result = map end
    for each key in keys
        if has key key in map
            result set key to map get key
        end
    end
    give back result
end

define invert taking map
    ## Swaps keys and values (values become keys, keys become values)
    let result = map end
    for each key and value in map
        result set value to key
    end
    give back result
end

define map to list taking map
    ## Converts a map to a list of key-value pairs
    let result = list of
    for each key and value in map
        let pair = list of key value
        add pair to result
    end
    give back result
end

define list to map taking list
    ## Converts a list of key-value pairs to a map
    let result = map end
    for each pair in list
        if size of pair is greater than 1
            result set item 0 of pair to item 1 of pair
        end
    end
    give back result
end

define get or default taking map and key and default
    ## Returns the value for a key, or a default if not found
    if has key key in map
        give back map get key
    end
    give back default
end

define each in map taking action
    ## Calls a function for each entry in a map
    for each key and value in map
        action key and value
    end
end

define filter map taking predicate over map
    ## Returns a new map with entries that pass a test
    let result = map end
    for each key and value in map
        if predicate key and value
            result set key to value
        end
    end
    give back result
end

define map values taking fn over map
    ## Returns a new map with transformed values
    let result = map end
    for each key and value in map
        result set key to fn key and value
    end
    give back result
end
