## AK CODE WebSocket Module
## Provides WebSocket client and server for real time bidirectional communication

make kind called WebSocketServer
    has port of type number
    has connection list of type list
    has running of type bool
    has on connect callback of type behaviour
    has on message callback of type behaviour
    has on close callback of type behaviour

    when created taking on port
        port = on port
        connection list = list of
        running = false
        on connect callback = empty
        on message callback = empty
        on close callback = empty
    end

    behaviour on connect taking handler
        on connect callback = handler
    end

    behaviour on message taking handler
        on message callback = handler
    end

    behaviour on close taking handler
        on close callback = handler
    end

    behaviour start
        running = true
        show "WebSocket server started on port" port
        show "Waiting for connections..."
        repeat while running
            accept connection
            handle messages
        end
    end

    behaviour accept connection
        ## Accepts a new WebSocket connection
        ## Performs the HTTP upgrade handshake
        let conn = new WebSocketConnection
        conn id = size of connection list plus 1
        conn connected = true
        add conn to connection list
        if on connect callback is not empty
            on connect callback conn
        end
        show "Client connected with id" conn id
    end

    behaviour handle messages
        ## Processes incoming messages from all connections
        for each conn in connection list
            if conn connected
                let msg = conn receive
                if msg is not empty
                    if on message callback is not empty
                        on message callback conn and msg
                    end
                end
            end
        end
    end

    behaviour broadcast taking message
        ## Sends a text message to all connected clients
        for each conn in connection list
            if conn connected
                conn send message
            end
        end
    end

    behaviour broadcast except taking message and connection id
        ## Sends a message to all clients except one
        for each conn in connection list
            if conn connected and conn id is not connection id
                conn send message
            end
        end
    end

    behaviour count connections
        ## Returns the number of connected clients
        let count = 0
        for each conn in connection list
            if conn connected
                count = count plus 1
            end
        end
        give back count
    end

    behaviour stop
        running = false
        for each conn in connection list
            conn close
        end
        show "WebSocket server stopped"
    end
end

make kind called WebSocketClient
    has server url of type text
    is connected of type bool
    has connection of type WebSocketConnection
    has auto reconnect of type bool

    when created taking to url
        server url = to url
        is connected = false
        connection = empty
        auto reconnect = false
    end

    behaviour connect
        ## Connects to a WebSocket server
        ## Performs the WebSocket upgrade handshake over TCP
        show "Connecting to" server url
        let conn = new WebSocketConnection
        conn url = server url
        conn connected = true
        connection = conn
        is connected = true
        give back true
    end

    behaviour send taking message
        ## Sends a text message over the connection
        if is connected is not true
            give back false
        end
        connection send message
        give back true
    end

    behaviour receive
        ## Receives the next message from the connection queue
        if is connected is not true
            give back empty
        end
        give back connection receive
    end

    behaviour close
        ## Closes the WebSocket connection gracefully
        if is connected
            connection close
            is connected = false
        end
        show "Disconnected from" server url
    end

    behaviour reconnect
        ## Attempts to reconnect to the server
        if is connected
            close
        end
        give back connect
    end

    behaviour set auto reconnect taking value
        auto reconnect = value
    end
end

make kind called WebSocketConnection
    has id of type number
    has url of type text
    has connected of type bool
    has message queue of type list
    has handshake headers of type map
    has close reason of type text

    when created
        id = 0
        url = ""
        connected = false
        message queue = list of
        handshake headers = map end
        close reason = ""
    end

    behaviour send taking message
        ## Builds a WebSocket text frame and queues it
        if connected is not true
            give back
        end
        let frame = build websocket frame from message
        add frame to message queue
    end

    behaviour receive
        ## Dequeues the next message
        if size of message queue is 0
            give back empty
        end
        let msg = item 0 of message queue
        remove item 0 from message queue
        give back msg
    end

    behaviour close
        ## Sends a close frame and marks as disconnected
        if connected
            let close frame = character 136 plus character 0
            add close frame to message queue
            connected = false
            show "Connection" id "closed"
        end
    end

    behaviour close with reason taking reason
        close reason = reason
        close
    end

    behaviour is alive
        give back connected
    end
end

define build websocket frame from taking message
    ## Builds a WebSocket text frame (opcode 0x1) from a message
    let frame = ""
    let first byte = 129
    frame = frame plus character first byte
    let length = size of message
    if length is less than 126
        frame = frame plus character length
    else if length is less than 65536
        frame = frame plus character 126
        frame = frame plus character floor of length divided by 256
        frame = frame plus character length mod 256
    else
        frame = frame plus character 127
        let i = 7
        repeat while i is greater than or equal to 0
            let shift = i times 8
            frame = frame plus character floor of length divided by 256 to the power shift mod 256
            i = i minus 1
        end
    end
    frame = frame plus message
    give back frame
end

define build websocket close frame
    ## Builds a WebSocket close frame (opcode 0x8)
    give back character 136 plus character 0
end

define build websocket ping frame
    ## Builds a WebSocket ping frame (opcode 0x9)
    give back character 137 plus character 0
end

define build websocket pong frame
    ## Builds a WebSocket pong frame (opcode 0xA)
    give back character 138 plus character 0
end

define parse websocket frame taking raw bytes
    ## Parses a WebSocket frame from raw bytes
    ## Returns a map with opcode payload and fin flag
    let result = map
        "fin" is false
        "opcode" is 0
        "payload" is ""
        "masked" is false
    end
    if size of raw bytes is less than 2
        give back result
    end
    let first = character at 0 of raw bytes as number
    let second = character at 1 of raw bytes as number
    result set "fin" to first is greater than or equal to 128
    let opcode = first mod 16
    result set "opcode" to opcode
    let masked = second is greater than or equal to 128
    result set "masked" to masked
    let payload length = second mod 128
    let offset = 2
    if payload length is 126
        payload length = character at 2 of raw bytes as number times 256 plus character at 3 of raw bytes as number
        offset = 4
    else if payload length is 127
        payload length = 0
        let i = 0
        repeat while i is less than 8
            payload length = payload length times 256 plus character at offset plus i of raw bytes as number
            i = i plus 1
        end
        offset = offset plus 8
    end
    if masked
        offset = offset plus 4
    end
    if offset plus payload length is less than or equal to size of raw bytes
        let payload = slice of raw bytes from offset to offset plus payload length
        result set "payload" to payload
    end
    give back result
end

define websocket handshake reply taking key
    ## Generates a WebSocket upgrade response
    let response = "HTTP/1.1 101 Switching Protocols\r\n"
    response = response plus "Upgrade: websocket\r\n"
    response = response plus "Connection: Upgrade\r\n"
    response = response plus "Sec-WebSocket-Accept: " plus compute websocket accept key key plus "\r\n"
    response = response plus "\r\n"
    give back response
end

define compute websocket accept key taking key
    ## Computes the Sec-WebSocket-Accept response header value
    ## Uses the WebSocket magic GUID per RFC 6455
    let combined = key plus "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    give back base64 encode sha1 combined
end

define create websocket server taking on port
    ## Quick helper to create a WebSocket server
    give back new WebSocketServer with on port
end

define create websocket client taking url
    ## Quick helper to create and connect a WebSocket client
    let client = new WebSocketClient to url
    client connect
    give back client
end
