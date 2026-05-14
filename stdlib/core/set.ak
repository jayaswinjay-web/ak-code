## AK CODE Set Module — set data structure
## Provides set operations for unique collections

make kind called Set
    has items of type map

    when created
        items = map end
    end

    behaviour add taking element
        items set element to true
    end

    behaviour remove taking element
        items set element to empty
    end

    behaviour has taking element
        if items get element is true
            give back true
        end
        give back false
    end

    behaviour size
        let count = 0
        for each key and value in items
            if value is true
                count = count plus 1
            end
        end
        give back count
    end

    behaviour to list
        let result = list of
        for each key and value in items
            if value is true
                add key to result
            end
        end
        give back result
    end

    behaviour union taking other of type Set
        let result = new Set
        for each key and value in items
            if value is true
                result add key
            end
        end
        let other items = other to list
        for each item in other items
            result add item
        end
        give back result
    end

    behaviour intersection taking other of type Set
        let result = new Set
        for each key and value in items
            if value is true and other has key
                result add key
            end
        end
        give back result
    end

    behaviour difference taking other of type Set
        let result = new Set
        for each key and value in items
            if value is true and other has key is not true
                result add key
            end
        end
        give back result
    end

    behaviour is subset of taking other of type Set
        for each key and value in items
            if value is true and other has key is not true
                give back false
            end
        end
        give back true
    end
end

define set from list taking lst
    ## Creates a set from a list
    let result = new Set
    for each item in lst
        result add item
    end
    give back result
end

define set of
    ## Creates a set from given elements
    let result = new Set
    for each item in the_args
        result add item
    end
    give back result
end
