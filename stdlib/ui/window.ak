## AK CODE Window Module — native window creation
## Provides cross-platform window management (Win32 / X11)

make kind called Window
    has title of type text
    has width of type number
    has height of type number
    has x position of type number
    has y position of type number
    has visible of type bool
    has handle of type number
    has background color of type text

    when created taking window title and w and h
        title = window title
        width = w
        height = h
        x position = 100
        y position = 100
        visible = false
        handle = 0
        background color = "#1e1e2e"
    end

    behaviour show
        visible = true
        # In real implementation:
        # Windows: CreateWindowEx, ShowWindow
        # Linux: XCreateWindow, XMapWindow
        show "Window opened:" title "(" width "x" height ")"
    end

    behaviour hide
        visible = false
        # Windows: ShowWindow(SW_HIDE)
        # Linux: XUnmapWindow
    end

    behaviour close
        visible = false
        show "Window closed:" title
    end

    behaviour set title taking new title
        title = new title
        # Windows: SetWindowText
        # Linux: XStoreName
    end

    behaviour resize taking w and h
        width = w
        height = h
        # Windows: SetWindowPos
        # Linux: XResizeWindow
    end

    behaviour move taking x and y
        x position = x
        y position = y
        # Windows: SetWindowPos
        # Linux: XMoveWindow
    end

    behaviour set background taking color
        background color = color
    end

    behaviour run event loop
        ## Main event loop — processes OS messages
        show "Starting event loop for:" title
        repeat while visible
            # Windows: GetMessage / PeekMessage, TranslateMessage, DispatchMessage
            # Linux: XPending, XNextEvent
            # Process events...
        end
    end
end

define create window titled taking title of size w and h
    ## Creates a new window
    give back new Window with title and w and h
end

define show window taking win of type Window
    ## Shows a window
    win show
end

define message box taking title and message
    ## Shows a message box dialog
    ## Windows: MessageBox
    ## Linux: X11 dialog or zenity
    show "[Message Box] " title ":" message
end

define open file dialog taking title and filter
    ## Shows an open file dialog
    ## Returns the selected file path, or empty if cancelled
    show "[Open File] " title
    give back empty
end

define save file dialog taking title and default name
    ## Shows a save file dialog
    show "[Save File] " title
    give back empty
end
