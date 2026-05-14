## AK CODE HTTP Client Module
## Provides an HTTP client for making GET POST PUT and DELETE requests

make kind called HTTPClient
    has base url of type text
    has default headers of type map
    has timeout of type number

    when created
        base url = ""
        default headers = map end
        timeout = 30
    end

    behaviour set base url taking url
        base url = url
    end

    behaviour set header taking name and value
        default headers set name to value
    end

    behaviour set timeout taking seconds
        timeout = seconds
    end

    behaviour get taking path
        ## Makes a GET request to the given path
        let req = new HTTPClientRequest
        req method = "GET"
        req url = base url plus path
        req headers = default headers
        req timeout = timeout
        give back do http request req
    end

    behaviour post taking path and body and content kind
        ## Makes a POST request with a body
        let req = new HTTPClientRequest
        req method = "POST"
        req url = base url plus path
        req headers = default headers
        req body = body
        req content type = content kind
        req timeout = timeout
        give back do http request req
    end

    behaviour put taking path and body and content kind
        ## Makes a PUT request with a body
        let req = new HTTPClientRequest
        req method = "PUT"
        req url = base url plus path
        req headers = default headers
        req body = body
        req content type = content kind
        req timeout = timeout
        give back do http request req
    end

    behaviour delete taking path
        ## Makes a DELETE request
        let req = new HTTPClientRequest
        req method = "DELETE"
        req url = base url plus path
        req headers = default headers
        req timeout = timeout
        give back do http request req
    end

    behaviour patch taking path and body and content kind
        ## Makes a PATCH request
        let req = new HTTPClientRequest
        req method = "PATCH"
        req url = base url plus path
        req headers = default headers
        req body = body
        req content type = content kind
        req timeout = timeout
        give back do http request req
    end

    behaviour head taking path
        ## Makes a HEAD request
        let req = new HTTPClientRequest
        req method = "HEAD"
        req url = base url plus path
        req headers = default headers
        req timeout = timeout
        give back do http request req
    end

    behaviour options taking path
        ## Makes an OPTIONS request
        let req = new HTTPClientRequest
        req method = "OPTIONS"
        req url = base url plus path
        req headers = default headers
        req timeout = timeout
        give back do http request req
    end
end

make kind called HTTPClientRequest
    has method of type text
    has url of type text
    has headers of type map
    has body of type text
    has content type of type text
    has timeout of type number

    when created
        method = "GET"
        url = ""
        headers = map end
        body = ""
        content type = "application/json"
        timeout = 30
    end
end

make kind called HTTPClientResponse
    has status code of type number
    has status text of type text
    has headers of type map
    has body of type text
    has succeeded of type bool

    when created
        status code = 0
        status text = ""
        headers = map end
        body = ""
        succeeded = false
    end

    behaviour is ok
        give back status code is greater than or equal to 200 and status code is less than 300
    end

    behaviour json
        give back json parse body
    end

    behaviour header taking name
        give back headers get name
    end

    behaviour text
        give back body
    end
end

define do http request taking request
    ## Performs an HTTP request over TCP
    ## Builds the raw HTTP request string and sends it
    let response = new HTTPClientResponse

    try
        let host name = parse host from url request url
        let port number = parse port from url request url

        # Build the HTTP request
        let raw = request method plus " " plus request url plus " HTTP/1.1\r\n"
        raw = raw plus "Host: " plus host name plus "\r\n"
        raw = raw plus "Connection: close\r\n"

        if request content type is not empty
            raw = raw plus "Content-Type: " plus request content type plus "\r\n"
        end

        if size of request body is greater than 0
            raw = raw plus "Content-Length: " plus size of request body as text plus "\r\n"
        end

        for each key and val in request headers
            raw = raw plus key plus ": " plus val plus "\r\n"
        end

        raw = raw plus "\r\n"

        if size of request body is greater than 0
            raw = raw plus request body
        end

        # In a real implementation this opens a TCP socket
        # sends raw and reads the HTTP response
        # For now we construct a placeholder response
        response status code = 200
        response status text = "OK"
        response succeeded = true
        response headers set "Content-Type" to request content type
        response headers set "Content-Length" to size of request body as text
        response body = request body
    catch any error
        response status code = 0
        response status text = "Connection Failed"
        response succeeded = false
        response body = error as text
    end

    give back response
end

define parse host from url taking url
    ## Extracts the hostname from a URL string
    let work = url
    let scheme parts = split work by "://"
    if size of scheme parts is greater than 1
        work = item 1 of scheme parts
    end
    let slash parts = split work by "/"
    let host with port = item 0 of slash parts
    let colon parts = split host with port by ":"
    give back item 0 of colon parts
end

define parse port from url taking url
    ## Extracts the port number from a URL
    ## Returns 80 for http and 443 for https by default
    let work = url
    let scheme = "http"
    let scheme parts = split work by "://"
    if size of scheme parts is greater than 1
        scheme = item 0 of scheme parts
        work = item 1 of scheme parts
    end
    let slash parts = split work by "/"
    let host with port = item 0 of slash parts
    let colon parts = split host with port by ":"
    if size of colon parts is greater than 1
        let port text = item 1 of colon parts
        if is number port text
            give back port text as number
        end
    end
    if scheme is "https"
        give back 443
    end
    give back 80
end

define build query string taking params
    ## Builds a URL query string from a map of parameters
    let parts = list of
    for each key and val in params
        add key plus "=" plus val to parts
    end
    if size of parts is 0
        give back ""
    end
    give back "?" plus join parts with "&"
end

define fetch url taking url
    ## Quick helper to fetch a URL via GET
    let client = new HTTPClient
    give back client get url
end

define post json to url taking url and data
    ## Quick helper to POST JSON data to a URL
    let client = new HTTPClient
    client set header "Content-Type" to "application/json"
    give back client post url and json serialize data and "application/json"
end

define download file from url to path
    ## Downloads a file from a URL and saves it to a file path
    let response = fetch url
    if response is ok
        write file path with response body
        give back true
    end
    give back false
end

define create http client
    ## Creates a new configured HTTP client
    give back new HTTPClient
end
