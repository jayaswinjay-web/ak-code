## AK CODE Layout Module — layout management
## Provides VBox, HBox, Grid, and Flex layout managers

make kind called Layout
    has children of type list
    has spacing of type number
    has padding of type number
    has x of type number
    has y of type number
    has width of type number
    has height of type number
    has visible of type bool

    when created
        children = list of
        spacing = 4
        padding = 8
        x = 0
        y = 0
        width = 0
        height = 0
        visible = true
    end

    behaviour add taking child
        add child to children
        this arrange
    end

    behaviour add at taking child and index
        if index is greater than or equal to size of children
            add child to children
        else
            let before = list of
            let after = list of
            let i = 0
            for each existing in children
                if i is less than index
                    add existing to before
                else
                    add existing to after
                end
                i = i plus 1
            end
            children = before
            add child to children
            for each remaining in after
                add remaining to children
            end
        end
        this arrange
    end

    behaviour remove taking child
        remove child from children
        this arrange
    end

    behaviour remove at taking index
        if index is greater than or equal to 0 and index is less than size of children
            remove at index from children
            this arrange
        end
    end

    behaviour clear
        children = list of
    end

    behaviour count
        give back size of children
    end

    behaviour get child taking index
        if index is greater than or equal to 0 and index is less than size of children
            give back item index of children
        end
        give back empty
    end

    behaviour set spacing taking value
        spacing = value
        this arrange
    end

    behaviour set padding taking value
        padding = value
        this arrange
    end

    behaviour arrange
        ## Override in subclasses
    end

    behaviour render
        show "  [Layout] children: " size of children
        for each child in children
            child render
        end
    end
end

make kind called VBox from Layout
    has align of type text

    when created
        parent Layout
        align = "left"
    end

    behaviour set align taking alignment
        align = alignment
        this arrange
    end

    behaviour arrange
        let current y = y plus padding
        for each child in children
            child x = x plus padding
            child y = current y
            if align is "center"
                child x = x plus (width minus child width) divided by 2
            else if align is "right"
                child x = x plus width minus child width minus padding
            end
            current y = current y plus child height plus spacing
        end
        height = current y minus spacing minus y
    end

    behaviour render
        show "[VBox] " "x:" x " y:" y " w:" width " h:" height " spacing:" spacing " align:" align
        for each child in children
            child render
        end
    end
end

make kind called HBox from Layout
    has valign of type text

    when created
        parent Layout
        valign = "top"
    end

    behaviour set valign taking alignment
        valign = alignment
        this arrange
    end

    behaviour arrange
        let current x = x plus padding
        for each child in children
            child x = current x
            child y = y plus padding
            if valign is "center"
                child y = y plus (height minus child height) divided by 2
            else if valign is "bottom"
                child y = y plus height minus child height minus padding
            end
            current x = current x plus child width plus spacing
        end
        width = current x minus spacing minus x
    end

    behaviour render
        show "[HBox] " "x:" x " y:" y " w:" width " h:" height " spacing:" spacing " valign:" valign
        for each child in children
            child render
        end
    end
end

make kind called Grid from Layout
    has columns of type number
    has col widths of type list of number
    has row heights of type list of number

    when created taking num cols
        parent Layout
        columns = num cols
        col widths = list of
        row heights = list of
    end

    behaviour set columns taking num cols
        if num cols is greater than 0
            columns = num cols
            this arrange
        end
    end

    behaviour set column width taking col index and width value
        repeat while size of col widths is less than col index plus 1
            add 0 to col widths
        end
        set item col index of col widths to width value
        this arrange
    end

    behaviour set row height taking row index and height value
        repeat while size of row heights is less than row index plus 1
            add 0 to row heights
        end
        set item row index of row heights to height value
        this arrange
    end

    behaviour arrange
        if columns is 0
            give back
        end
        let cell width = (width minus padding times 2 minus (columns minus 1 times spacing)) divided by columns
        let current row = 0
        let current col = 0
        let max row height = 0
        let start y = y plus padding
        let current y = start y

        for each child in children
            child x = x plus padding plus current col times (cell width plus spacing)
            child y = current y

            if current col is less than size of col widths
                child width = item current col of col widths
            else
                child width = cell width
            end

            if current row is less than size of row heights
                child height = item current row of row heights
            end

            if child height is greater than max row height
                max row height = child height
            end

            current col = current col plus 1
            if current col is greater than or equal to columns
                current col = 0
                current y = current y plus max row height plus spacing
                max row height = 0
                current row = current row plus 1
            end
        end
        height = current y plus max row height minus y
    end

    behaviour render
        show "[Grid] " "x:" x " y:" y " w:" width " h:" height " cols:" columns " spacing:" spacing
        for each child in children
            child render
        end
    end
end

make kind called Flex from Layout
    has direction of type text
    has wrap of type bool
    has justify of type text
    has items align of type text
    has wrap spacing of type number

    when created
        parent Layout
        direction = "row"
        wrap = false
        justify = "start"
        items align = "stretch"
        wrap spacing = spacing
    end

    behaviour set direction taking dir
        if dir is "row" or dir is "column"
            direction = dir
            this arrange
        end
    end

    behaviour set wrap taking should wrap
        wrap = should wrap
        this arrange
    end

    behaviour set justify taking justification
        justify = justification
        this arrange
    end

    behaviour set items align taking alignment
        items align = alignment
        this arrange
    end

    behaviour get total child size in direction
        let total = 0
        for each child in children
            if direction is "row"
                total = total plus child width plus spacing
            else
                total = total plus child height plus spacing
            end
        end
        if total is greater than 0
            total = total minus spacing
        end
        give back total
    end

    behaviour get max child size in cross
        let max size = 0
        for each child in children
            if direction is "row"
                if child height is greater than max size
                    max size = child height
                end
            else
                if child width is greater than max size
                    max size = child width
                end
            end
        end
        give back max size
    end

    behaviour arrange
        if direction is "row"
            this arrange row
        else
            this arrange column
        end
    end

    behaviour arrange row
        let available width = width minus padding times 2
        let total used = this get total child size in direction

        let start x = x plus padding
        if justify is "center"
            start x = x plus (width minus total used) divided by 2
        else if justify is "end"
            start x = x plus width minus total used minus padding
        else if justify is "between"
            # Distribute children evenly with space between
            let child count = size of children
            if child count is greater than 1
                let space = (available width minus total used plus (child count minus 1 times spacing)) divided by (child count minus 1)
                let current x = x plus padding
                for each child in children
                    child x = current x
                    child y = y plus padding
                    if items align is "center"
                        child y = y plus (height minus child height) divided by 2
                    else if items align is "end"
                        child y = y plus height minus child height minus padding
                    else if items align is "stretch"
                        child height = height minus padding times 2
                    end
                    current x = current x plus child width plus space
                end
                give back
            end
        end

        let current x = start x
        for each child in children
            child x = current x
            child y = y plus padding
            if items align is "center"
                child y = y plus (height minus child height) divided by 2
            else if items align is "end"
                child y = y plus height minus child height minus padding
            else if items align is "stretch"
                child height = height minus padding times 2
            end
            current x = current x plus child width plus spacing
        end
        height = this get max child size in cross plus padding times 2
    end

    behaviour arrange column
        let available height = height minus padding times 2
        let total used = this get total child size in direction

        let start y = y plus padding
        if justify is "center"
            start y = y plus (height minus total used) divided by 2
        else if justify is "end"
            start y = y plus height minus total used minus padding
        else if justify is "between"
            let child count = size of children
            if child count is greater than 1
                let space = (available height minus total used plus (child count minus 1 times spacing)) divided by (child count minus 1)
                let current y = y plus padding
                for each child in children
                    child x = x plus padding
                    child y = current y
                    if items align is "center"
                        child x = x plus (width minus child width) divided by 2
                    else if items align is "end"
                        child x = x plus width minus child width minus padding
                    else if items align is "stretch"
                        child width = width minus padding times 2
                    end
                    current y = current y plus child height plus space
                end
                give back
            end
        end

        let current y = start y
        for each child in children
            child x = x plus padding
            child y = current y
            if items align is "center"
                child x = x plus (width minus child width) divided by 2
            else if items align is "end"
                child x = x plus width minus child width minus padding
            else if items align is "stretch"
                child width = width minus padding times 2
            end
            current y = current y plus child height plus spacing
        end
        width = this get max child size in cross plus padding times 2
    end

    behaviour render
        show "[Flex] " "x:" x " y:" y " w:" width " h:" height " dir:" direction " justify:" justify
        for each child in children
            child render
        end
    end
end

define create vbox
    ## Create a new vertical box layout
    give back new VBox
end

define create hbox
    ## Create a new horizontal box layout
    give back new HBox
end

define create grid taking columns
    ## Create a new grid layout with the given number of columns
    give back new Grid with columns
end

define create flex
    ## Create a new flex layout
    give back new Flex
end

define add taking child to parent
    ## Add a widget to a layout
    parent add child
end

define set spacing of taking layout to value
    ## Set the spacing of a layout
    layout set spacing value
end

define set padding of taking layout to value
    ## Set the padding of a layout
    layout set padding value
end
