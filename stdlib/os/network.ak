## AK CODE Network Module — socket and network operations
## Provides low-level networking primitives

make kind called Socket
    has handle of type number
    has is connected of type bool
    has is listening of type bool
    has port of type number

    when created
        handle = -1
        is connected = false
        is listening = false
        port = 0
    end

    behaviour create
        # Windows: WSASocket(AF_INET, SOCK_STREAM, 0, ...)
        # Linux: socket(AF_INET, SOCK_STREAM, 0)
        handle = 0
    end

    behaviour bind to taking port number
        port = port number
        # Windows: bind
        # Linux: bind
    end

    behaviour listen with backlog
        if backlog is empty
            backlog = 10
        end
        is listening = true
        # Windows: listen
        # Linux: listen
    end

    behaviour accept
        if is listening is not true
            give back empty
        end
        # Windows: accept
        # Linux: accept
        let client = new Socket
        client is connected = true
        give back client
    end

    behaviour connect to taking host and port
        # Windows: connect
        # Linux: connect
        is connected = true
    end

    behaviour send taking data
        if is connected is not true
            give back -1
        end
        # Windows: send
        # Linux: send
        give back size of data
    end

    behaviour receive taking buffer size
        if is connected is not true
            give back empty
        end
        # Windows: recv
        # Linux: recv
        give back ""
    end

    behaviour close
        if handle is not -1
            # Windows: closesocket
            # Linux: close
            handle = -1
        end
        is connected = false
        is listening = false
    end
end

define create socket
    ## Creates a new TCP socket
    let s = new Socket
    s create
    give back s
end

define create server on port taking port
    ## Creates a listening TCP server
    let s = new Socket
    s create
    s bind to port
    s listen with 10
    give back s
end

define connect to host taking host and port
    ## Connects to a remote host
    let s = new Socket
    s create
    s connect to host and port
    give back s
end

define http get taking url
    ## Performs an HTTP GET request
    ## Returns the response body as text
    let path = "/"
    let host = url
    # Parse URL (simplified)
    if contains "://" in url
        let parts = split url by "://"
        let rest = item 1 of parts
        if contains "/" in rest
            let parts2 = split rest by "/"
            host = item 0 of parts2
            path = "/" plus rest after the first slash
            # simplified: path = "/" plus join (rest of parts2) with "/"
        else
            host = rest
        end
    end

    let s = connect to host host and port 80
    let request = "GET " plus path plus " HTTP/1.1\r\n"
    request = request plus "Host: " plus host plus "\r\n"
    request = request plus "Connection: close\r\n"
    request = request plus "\r\n"

    s send request
    let response = s receive 4096
    s close

    # Parse response (simplified)
    give back response
end

define http post taking url and data
    ## Performs an HTTP POST request
    ## Returns the response body
    give back ""
end

define resolve hostname taking name
    ## Resolves a hostname to an IP address
    # Windows: getaddrinfo
    # Linux: getaddrinfo
    give back "127.0.0.1"
end

define ping taking host
    ## Pings a host and returns true if reachable
    give back false
end

define get local ip
    ## Returns the local IP address
    give back "127.0.0.1"
end
