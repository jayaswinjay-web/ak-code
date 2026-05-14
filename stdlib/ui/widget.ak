## AK CODE Widget Module — UI widget primitives
## Provides Button, Label, TextBox, Dropdown, Checkbox, and RadioGroup widgets

make kind called Event
    has type of type text
    has target
    has data of type map

    when created taking event type and event target
        type = event type
        target = event target
        data = map end
    end

    behaviour set data taking key and value
        data set key to value
    end

    behaviour get data taking key
        give back data get key
    end
end

make kind called EventHandler
    has handlers of type map

    when created
        handlers = map end
    end

    behaviour on taking event type and callback
        let existing = handlers get event type
        if existing is empty
            handlers set event type to list of callback
        else
            add callback to existing
        end
    end

    behaviour off taking event type and callback
        let existing = handlers get event type
        if existing is not empty
            remove callback from existing
        end
    end

    behaviour emit taking event type and event data
        let callbacks = handlers get event type
        if callbacks is not empty
            let event = new Event with event type and event data
            for each cb in callbacks
                cb event
            end
        end
    end

    behaviour clear
        handlers = map end
    end
end

make kind called Widget
    has id of type text
    has x of type number
    has y of type number
    has width of type number
    has height of type number
    has visible of type bool
    has enabled of type bool
    has parent
    has events of type EventHandler
    has style of type map

    when created taking widget id
        id = widget id
        x = 0
        y = 0
        width = 100
        height = 30
        visible = true
        enabled = true
        parent = empty
        events = new EventHandler
        style = map end
    end

    behaviour set position taking x pos and y pos
        x = x pos
        y = y pos
        events emit "move" and this
    end

    behaviour set size taking w and h
        width = w
        height = h
        events emit "resize" and this
    end

    behaviour show
        visible = true
        events emit "show" and this
    end

    behaviour hide
        visible = false
        events emit "hide" and this
    end

    behaviour disable
        enabled = false
        events emit "disable" and this
    end

    behaviour enable
        enabled = true
        events emit "enable" and this
    end

    behaviour on taking event type and callback
        events on event type and callback
    end

    behaviour set style taking key and value
        style set key to value
        events emit "style_change" and this
    end

    behaviour get style taking key
        give back style get key
    end

    behaviour contains point taking px and py
        if px is greater than or equal to x and px is less than or equal to x plus width
            if py is greater than or equal to y and py is less than or equal to y plus height
                give back true
            end
        end
        give back false
    end

    behaviour render
        ## Override in subclasses
        show "Rendering widget: " id
    end
end

make kind called Button from Widget
    has text of type text
    has pressed of type bool

    when created taking button id and button text
        parent Widget with button id
        text = button text
        pressed = false
        width = 120
        height = 36
    end

    behaviour set text taking new text
        text = new text
        events emit "text_change" and this
    end

    behaviour click
        pressed = true
        events emit "click" and this
        pressed = false
    end

    behaviour render
        show "  [Button] " id " : " text
        show "    Position: " x ", " y
        show "    Size: " width " x " height
    end
end

make kind called Label from Widget
    has text of type text
    has text align of type text
    has font size of type number
    has auto size of type bool

    when created taking label id and label text
        parent Widget with label id
        text = label text
        text align = "left"
        font size = 14
        auto size = true
        height = 24
    end

    behaviour set text taking new text
        text = new text
        if auto size
            width = size of text times 8
        end
        events emit "text_change" and this
    end

    behaviour set align taking alignment
        text align = alignment
        events emit "style_change" and this
    end

    behaviour set font size taking size
        font size = size
        height = size plus 10
        events emit "style_change" and this
    end

    behaviour render
        show "  [Label] " id " : " text
        show "    Align: " text align " Font Size: " font size
    end
end

make kind called TextBox from Widget
    has value of type text
    has placeholder of type text
    has readonly of type bool
    has max length of type number
    has has focus of type bool
    has cursor pos of type number

    when created taking input id
        parent Widget with input id
        value = ""
        placeholder = ""
        readonly = false
        max length = 0
        has focus = false
        cursor pos = 0
        width = 200
        height = 30
    end

    behaviour set value taking new value
        if max length is greater than 0 and size of new value is greater than max length
            new value = substring of new value from 0 to max length
        end
        value = new value
        cursor pos = size of value
        events emit "input" and this
    end

    behaviour append taking text
        let new value = value plus text
        if max length is greater than 0 and size of new value is greater than max length
            new value = substring of new value from 0 to max length
        end
        value = new value
        cursor pos = size of value
        events emit "input" and this
    end

    behaviour clear
        value = ""
        cursor pos = 0
        events emit "input" and this
    end

    behaviour set placeholder taking text
        placeholder = text
    end

    behaviour set readonly
        readonly = true
    end

    behaviour focus
        has focus = true
        events emit "focus" and this
    end

    behaviour blur
        has focus = false
        events emit "blur" and this
    end

    behaviour render
        show "  [TextBox] " id
        show "    Value: \"" value "\""
        if placeholder is not ""
            show "    Placeholder: \"" placeholder "\""
        end
        if readonly
            show "    Readonly: true"
        end
    end
end

make kind called Dropdown from Widget
    has options of type list of text
    has selected index of type number
    has selected value of type text
    has is open of type bool

    when created taking dropdown id
        parent Widget with dropdown id
        options = list of
        selected index = -1
        selected value = ""
        is open = false
        width = 200
        height = 36
    end

    behaviour add option taking option text
        add option text to options
        if selected index is -1
            selected index = 0
            if size of options is greater than 0
                selected value = item 0 of options
            end
        end
        events emit "options_change" and this
    end

    behaviour remove option taking index
        if index is greater than or equal to 0 and index is less than size of options
            remove at index from options
            if selected index is index
                selected index = -1
                selected value = ""
            else if selected index is greater than index
                selected index = selected index minus 1
            end
            events emit "options_change" and this
        end
    end

    behaviour set options taking option list
        options = option list
        if size of options is greater than 0
            selected index = 0
            selected value = item 0 of options
        else
            selected index = -1
            selected value = ""
        end
        events emit "options_change" and this
    end

    behaviour select index taking index
        if index is greater than or equal to 0 and index is less than size of options
            selected index = index
            selected value = item index of options
            events emit "change" and this
        end
    end

    behaviour select value taking value
        let i = 0
        for each opt in options
            if opt is value
                selected index = i
                selected value = value
                events emit "change" and this
                give back true
            end
            i = i plus 1
        end
        give back false
    end

    behaviour open
        is open = true
        events emit "open" and this
    end

    behaviour close
        is open = false
        events emit "close" and this
    end

    behaviour render
        show "  [Dropdown] " id
        show "    Selected: " selected value " (index " selected index ")"
        if is open
            show "    Options:"
            for each opt in options
                show "      - " opt
            end
        end
    end
end

make kind called Checkbox from Widget
    has checked of type bool
    has label of type text

    when created taking checkbox id
        parent Widget with checkbox id
        checked = false
        label = ""
        width = 24
        height = 24
    end

    behaviour set label taking text
        label = text
    end

    behaviour toggle
        checked = not checked
        if checked
            events emit "check" and this
        else
            events emit "uncheck" and this
        end
        events emit "change" and this
    end

    behaviour check
        if checked is not true
            checked = true
            events emit "check" and this
            events emit "change" and this
        end
    end

    behaviour uncheck
        if checked
            checked = false
            events emit "uncheck" and this
            events emit "change" and this
        end
    end

    behaviour render
        let status = "unchecked"
        if checked
            status = "checked"
        end
        show "  [Checkbox] " id " [" status "]"
        if label is not ""
            show "    Label: " label
        end
    end
end

make kind called RadioGroup from Widget
    has options of type list of map
    has selected value of type text
    has orientation of type text

    when created taking group id
        parent Widget with group id
        options = list of
        selected value = ""
        orientation = "vertical"
    end

    behaviour add option taking value and label
        let option = map end
        option set "value" to value
        option set "label" to label
        add option to options
        events emit "options_change" and this
    end

    behaviour remove option taking value
        let remaining = list of
        for each opt in options
            if opt get "value" is not value
                add opt to remaining
            end
        end
        options = remaining
        if selected value is value
            selected value = ""
        end
        events emit "options_change" and this
    end

    behaviour select taking value
        for each opt in options
            if opt get "value" is value
                selected value = value
                events emit "change" and this
                give back true
            end
        end
        give back false
    end

    behaviour get selected label
        for each opt in options
            if opt get "value" is selected value
                give back opt get "label"
            end
        end
        give back ""
    end

    behaviour set orientation taking dir
        if dir is "horizontal" or dir is "vertical"
            orientation = dir
        end
    end

    behaviour render
        show "  [RadioGroup] " id
        show "    Selected: " selected value
        show "    Orientation: " orientation
        for each opt in options
            let marker = "  "
            if opt get "value" is selected value
                marker = "->"
            end
            show "    " marker " " opt get "label" " (" opt get "value" ")"
        end
    end
end

define create button taking id and text
    ## Create a new Button widget
    give back new Button with id and text
end

define create label taking id and text
    ## Create a new Label widget
    give back new Label with id and text
end

define create textbox taking id
    ## Create a new TextBox widget
    give back new TextBox with id
end

define create dropdown taking id
    ## Create a new Dropdown widget
    give back new Dropdown with id
end

define create checkbox taking id
    ## Create a new Checkbox widget
    give back new Checkbox with id
end

define create radio group taking id
    ## Create a new RadioGroup widget
    give back new RadioGroup with id
end
