## AK CODE Router Module
## URL router with path matching query parsing and middleware support

make kind called Router
    has route list of type list
    has middleware chain of type list
    has fallback handler of type behaviour

    when created
        route list = list of
        middleware chain = list of
        fallback handler = empty
    end

    behaviour get taking path and handler
        ## Registers a GET route
        let entry = new RouteEntry
        entry method = "GET"
        entry path pattern = path
        entry handler = handler
        add entry to route list
    end

    behaviour post taking path and handler
        ## Registers a POST route
        let entry = new RouteEntry
        entry method = "POST"
        entry path pattern = path
        entry handler = handler
        add entry to route list
    end

    behaviour put taking path and handler
        ## Registers a PUT route
        let entry = new RouteEntry
        entry method = "PUT"
        entry path pattern = path
        entry handler = handler
        add entry to route list
    end

    behaviour delete taking path and handler
        ## Registers a DELETE route
        let entry = new RouteEntry
        entry method = "DELETE"
        entry path pattern = path
        entry handler = handler
        add entry to route list
    end

    behaviour patch taking path and handler
        ## Registers a PATCH route
        let entry = new RouteEntry
        entry method = "PATCH"
        entry path pattern = path
        entry handler = handler
        add entry to route list
    end

    behaviour all taking path and handler
        ## Registers a route that matches any HTTP method
        let entry = new RouteEntry
        entry method = "ANY"
        entry path pattern = path
        entry handler = handler
        add entry to route list
    end

    behaviour use taking middleware
        ## Adds a middleware function to the chain
        ## Middleware receives the context and returns true to continue or false to stop
        add middleware to middleware chain
    end

    behaviour on not found taking handler
        ## Sets a fallback handler for when no route matches
        fallback handler = handler
    end

    behaviour match taking method and raw path
        ## Tries to match a method and path against registered routes
        ## Returns a RoutingContext with matched params or a 404 context
        let context = new RoutingContext
        context request method = method
        context request path = raw path
        context matched route = false

        let path parts = split raw path by "?"
        let clean path = item 0 of path parts
        context request path = clean path

        if size of path parts is greater than 1
            context query parameters = parse query string item 1 of path parts
        end

        # Run middleware chain
        for each mw in middleware chain
            let proceed = mw context
            if proceed is false
                give back context
            end
        end

        # Find matching route
        for each entry in route list
            if entry method is not "ANY" and entry method is not method
                continue
            end
            let match result = match path against pattern taking clean path and entry path pattern
            if match result is not empty
                context matched route = true
                context path parameters = match result
                context matched entry = entry
                give back context
            end
        end

        # No route matched
        context matched route = false
        give back context
    end

    behaviour route taking entry and context
        ## Dispatches a request to a route handler
        if entry is not empty
            entry handler context
        else if fallback handler is not empty
            fallback handler context
        end
    end

    behaviour dispatch taking method and raw path
        ## Matches and dispatches in one call
        let context = match method and raw path
        if context matched route
            route context matched entry and context
        else if fallback handler is not empty
            fallback handler context
        end
        give back context
    end
end

make kind called RouteEntry
    has method of type text
    has path pattern of type text
    has handler of type behaviour

    when created
        method = "GET"
        path pattern = "/"
        handler = empty
    end
end

make kind called RoutingContext
    has request method of type text
    has request path of type text
    has query parameters of type map
    has path parameters of type map
    has matched route of type bool
    has matched entry of type RouteEntry
    has store of type map
    has response data of type any

    when created
        request method = "GET"
        request path = "/"
        query parameters = map end
        path parameters = map end
        matched route = false
        matched entry = empty
        store = map end
        response data = empty
    end

    behaviour param taking name
        give back path parameters get name
    end

    behaviour query taking name
        give back query parameters get name
    end

    behaviour get taking key
        give back store get key
    end

    behaviour set taking key and value
        store set key to value
    end
end

define match path against pattern taking path and pattern
    ## Matches a URL path against a route pattern
    ## Supports :param segments and *wildcard capture
    ## Returns a map of captured parameters or empty if no match
    if path is "/" and pattern is "/"
        give back map end
    end

    let path segs = split path by "/"
    let pattern segs = split pattern by "/"

    if size of path segs is not size of pattern segs
        if size of pattern segs is 0
            give back empty
        end
        let last pattern = item size of pattern segs minus 1 of pattern segs
        if last pattern is not "*"
            give back empty
        end
    end

    let params = map end
    let min len = size of pattern segs
    if size of path segs is less than min len
        min len = size of path segs
    end

    let i = 0
    repeat while i is less than min len
        let pseg = item i of path segs
        let rseg = item i of pattern segs

        if rseg is "*"
            let wild = ""
            let j = i
            repeat while j is less than size of path segs
                if j is greater than i
                    wild = wild plus "/"
                end
                wild = wild plus item j of path segs
                j = j plus 1
            end
            params set "*" to wild
            give back params
        end

        if size of rseg is greater than 0 and character at 0 of rseg is ":"
            let param name = slice of rseg from 1 to size of rseg
            params set param name to pseg
        else if pseg is not rseg
            give back empty
        end
        i = i plus 1
    end

    give back params
end

define parse query string taking query text
    ## Parses a URL query string into a map of key value pairs
    let result = map end
    if query text is empty
        give back result
    end
    let pairs = split query text by "&"
    for each pair in pairs
        let kv = split pair by "="
        if size of kv is greater than 1
            let key = percent decode text item 0 of kv
            let value = percent decode text item 1 of kv
            result set key to value
        else if size of kv is 1
            let key = percent decode text item 0 of kv
            result set key to ""
        end
    end
    give back result
end

define percent decode text taking text
    ## Decodes percent encoded URL characters
    let result = ""
    let i = 0
    let len = size of text
    repeat while i is less than len
        let ch = character at i of text
        if ch is "%" and i plus 2 is less than len
            let high = character at i plus 1 of text
            let low = character at i plus 2 of text
            let hex val = hex digit value high times 16 plus hex digit value low
            if hex val is greater than 0
                result = result plus character hex val
                i = i plus 3
            else
                result = result plus ch
                i = i plus 1
            end
        else if ch is "+"
            result = result plus " "
            i = i plus 1
        else
            result = result plus ch
            i = i plus 1
        end
    end
    give back result
end

define hex digit value taking digit
    ## Converts a hex digit character to its numeric value
    if digit is between "0" and "9"
        give back digit as number
    end
    if digit is between "a" and "f"
        give back 10 plus (character to code digit) minus (character to code "a")
    end
    if digit is between "A" and "F"
        give back 10 plus (character to code digit) minus (character to code "A")
    end
    give back 0
end

define character to code taking ch
    ## Converts a character to its ASCII code number
    give back ch as number
end

define create route group taking prefix
    ## Creates a new router that groups routes under a prefix
    let group = new Router
    give back behaviour taking subrouter
        for each entry in subrouter route list
            let new entry = new RouteEntry
            new entry method = entry method
            new entry path pattern = prefix plus entry path pattern
            new entry handler = entry handler
            add new entry to group route list
        end
        for each mw in subrouter middleware chain
            add mw to group middleware chain
        end
        give back group
    end
end

define create router
    ## Quick helper to create a new router
    give back new Router
end

define serve static directory taking base path and directory
    ## Creates a handler that serves static files from a directory
    give back behaviour taking context
        let file path = directory plus context request path
        let content = read file file path
        if content is empty
            context response data = "File not found"
            give back
        end
        context response data = content
    end
end
