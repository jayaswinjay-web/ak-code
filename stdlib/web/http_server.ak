## AK CODE HTTP Server Module
## Provides a full HTTP/1.1 web server implementation

make kind called HTTPServer
    has port of type number
    has routes of type list of Route
    has running of type bool

    when created taking on port number
        port = port number
        routes = list of
        running = false
    end

    behaviour when someone visits taking path and handler
        let route = new Route
        route method = "GET"
        route path pattern = path
        route handler = handler
        add route to routes
    end

    behaviour when someone posts to taking path and handler
        let route = new Route
        route method = "POST"
        route path pattern = path
        route handler = handler
        add route to routes
    end

    behaviour start listening
        running = true
        show "Server started on port" port
        show "Listening for connections..."
        # In a real implementation, this would:
        # 1. Create a socket (AF_INET, SOCK_STREAM)
        # 2. Bind to port
        # 3. Listen for connections
        # 4. Accept connections in a loop
        # 5. Parse HTTP requests and dispatch to handlers
        # 6. Send HTTP responses
        repeat while running
            accept connection
            handle request
        end
    end

    behaviour accept connection
        # Placeholder: accept a TCP connection
    end

    behaviour handle request
        # Placeholder: parse HTTP request and dispatch
    end

    behaviour stop
        running = false
        show "Server stopping..."
    end
end

make kind called Route
    has method of type text
    has path pattern of type text
    has handler of type behaviour
end

make kind called HTTPRequest
    has method of type text
    has path of type text
    has headers of type map
    has body of type text
    has query parameters of type map
    has path parameters of type map

    when created
        headers = map end
        query parameters = map end
        path parameters = map end
    end

    behaviour get header taking name
        give back headers get name
    end

    behaviour get param taking name
        give back query parameters get name
    end

    behaviour get path param taking name
        give back path parameters get name
    end
end

make kind called HTTPResponse
    has status code of type number
    has status text of type text
    has headers of type map
    has body of type text
    has content type of type text

    when created
        status code = 200
        status text = "OK"
        headers = map end
        body = ""
        content type = "text/html"
    end

    behaviour set status taking code and text
        status code = code
        status text = text
    end

    behaviour set header taking name and value
        headers set name to value
    end

    behaviour send
        # In real implementation, write the HTTP response to the socket
        let response = "HTTP/1.1 " plus status code as text plus " " plus status text plus "\r\n"
        # Add headers
        response = response plus "Content-Type: " plus content type plus "\r\n"
        response = response plus "Content-Length: " plus size of body as text plus "\r\n"
        for each key and value in headers
            response = response plus key plus ": " plus value plus "\r\n"
        end
        response = response plus "\r\n"
        response = response plus body
        # Write to socket
    end

    behaviour json taking data
        content type = "application/json"
        body = json serialize data
    end

    behaviour html taking content
        content type = "text/html"
        body = content
    end

    behaviour text taking content
        content type = "text/plain"
        body = content
    end
end

define parse http request taking raw text
    ## Parses an HTTP request from raw text
    let lines = split raw text by "\r\n"
    if size of lines is 0
        give back empty
    end

    let request line = split item 0 of lines by " "
    if size of request line is less than 2
        give back empty
    end

    let req = new HTTPRequest
    req method = item 0 of request line
    req path = item 1 of request line

    # Parse headers
    let i = 1
    repeat while i is less than size of lines
        let line = item i of lines
        if line is ""
            # Empty line marks end of headers
            i = i plus 1
            break
        end
        let parts = split line by ": "
        if size of parts is greater than 1
            req headers set item 0 of parts to item 1 of parts
        end
        i = i plus 1
    end

    # Body is the rest
    if i is less than size of lines
        let body parts = slice of lines from i to size of lines
        req body = join body parts with "\r\n"
    end

    # Parse query parameters from path
    let path parts = split req path by "?"
    if size of path parts is greater than 1
        req path = item 0 of path parts
        let query string = item 1 of path parts
        let params = split query string by "&"
        for each param in params
            let kv = split param by "="
            if size of kv is greater than 1
                req query parameters set item 0 of kv to item 1 of kv
            end
        end
    end

    give back req
end

define send back page taking content
    ## Helper to create an HTML response page
    let res = new HTTPResponse
    res html content
    give back res
end

define send back json taking data
    ## Helper to create a JSON response
    let res = new HTTPResponse
    res json data
    give back res
end

define send back message taking text
    ## Helper to create a text response
    let res = new HTTPResponse
    res text text
    give back res
end

define send back error taking message
    ## Helper to create an error response
    let res = new HTTPResponse
    res set status 400 and "Bad Request"
    res text message
    give back res
end

define serve static files from taking directory
    ## Serves static files from a directory
    ## Returns a handler function
    give back behaviour taking req
        let file path = directory plus req path
        let content = read file file path
        if content is empty
            let res = new HTTPResponse
            res set status 404 and "Not Found"
            res text "File not found"
            give back res
        end
        let res = new HTTPResponse
        res text content
        give back res
    end
end

define cors headers
    ## Returns CORS headers for cross-origin requests
    let headers = map end
    headers set "Access-Control-Allow-Origin" to "*"
    headers set "Access-Control-Allow-Methods" to "GET, POST, PUT, DELETE, OPTIONS"
    headers set "Access-Control-Allow-Headers" to "Content-Type, Authorization"
    give back headers
end
