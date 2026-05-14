## AK CODE Canvas Module — drawing and graphics
## Provides a drawing canvas with shapes, paths, gradients, and colors

make kind called Color
    has red of type number
    has green of type number
    has blue of type number
    has alpha of type number

    when created taking r and g and b
        red = r
        green = g
        blue = b
        alpha = 255
    end

    behaviour with alpha taking a
        alpha = a
        give back this
    end

    behaviour to hex
        let hex = "#"
        let channels = list of red green blue alpha
        for each ch in channels
            let first = ch divided by 16
            let second = ch mod 16
            let chars = "0123456789abcdef"
            hex = hex plus character at first of chars
            hex = hex plus character at second of chars
        end
        give back hex
    end

    behaviour to rgba
        give back "rgba(" plus red as text plus "," plus green as text plus "," plus blue as text plus "," plus (alpha divided by 255) as text plus ")"
    end
end

define rgb taking r and g and b
    ## Create a color from red, green, blue values (0-255)
    give back new Color with r and g and b
end

define rgba taking r and g and b and a
    ## Create a color with alpha
    let c = new Color with r and g and b
    c alpha = a
    give back c
end

define hex color taking hex value
    ## Create a color from a hex string like "#ff0000"
    if size of hex value is less than 7
        give back new Color with 0 and 0 and 0
    end
    let r = 0
    let g = 0
    let b = 0
    if character at 0 of hex value is "#"
        let r high = character at 1 of hex value
        let r low = character at 2 of hex value
        let g high = character at 3 of hex value
        let g low = character at 4 of hex value
        let b high = character at 5 of hex value
        let b low = character at 6 of hex value
        r = hex digit r high times 16 plus hex digit r low
        g = hex digit g high times 16 plus hex digit g low
        b = hex digit b high times 16 plus hex digit b low
    end
    give back new Color with r and g and b
end

define hex digit taking ch
    ## Convert a hex character to its numeric value
    if ch is between "0" and "9"
        give back ch as number
    else if ch is "a" or ch is "A"
        give back 10
    else if ch is "b" or ch is "B"
        give back 11
    else if ch is "c" or ch is "C"
        give back 12
    else if ch is "d" or ch is "D"
        give back 13
    else if ch is "e" or ch is "E"
        give back 14
    else if ch is "f" or ch is "F"
        give back 15
    end
    give back 0
end

define named color taking name
    ## Return a common named color
    if name is "red"
        give back new Color with 255 and 0 and 0
    else if name is "green"
        give back new Color with 0 and 255 and 0
    else if name is "blue"
        give back new Color with 0 and 0 and 255
    else if name is "white"
        give back new Color with 255 and 255 and 255
    else if name is "black"
        give back new Color with 0 and 0 and 0
    else if name is "gray" or name is "grey"
        give back new Color with 128 and 128 and 128
    else if name is "yellow"
        give back new Color with 255 and 255 and 0
    else if name is "cyan"
        give back new Color with 0 and 255 and 255
    else if name is "magenta"
        give back new Color with 255 and 0 and 255
    else if name is "orange"
        give back new Color with 255 and 165 and 0
    else if name is "purple"
        give back new Color with 128 and 0 and 128
    else if name is "pink"
        give back new Color with 255 and 192 and 203
    else if name is "brown"
        give back new Color with 165 and 42 and 42
    else if name is "navy"
        give back new Color with 0 and 0 and 128
    else if name is "teal"
        give back new Color with 0 and 128 and 128
    end
    give back new Color with 0 and 0 and 0
end

make kind called Gradient
    has type of type text
    has stops of type list of map
    has x1 of type number
    has y1 of type number
    has x2 of type number
    has y2 of type number
    has radius of type number

    when created taking gradient type
        type = gradient type
        stops = list of
        x1 = 0
        y1 = 0
        x2 = 0
        y2 = 0
        radius = 0
    end

    behaviour from taking x and y
        x1 = x
        y1 = y
        give back this
    end

    behaviour to taking x and y
        x2 = x
        y2 = y
        give back this
    end

    behaviour at radius taking r
        radius = r
        give back this
    end

    behaviour add stop taking offset and color
        let stop = map end
        stop set "offset" to offset
        stop set "color" to color
        add stop to stops
        give back this
    end
end

define linear gradient from x1 and y1 to x2 and y2
    ## Create a linear gradient
    let g = new Gradient with "linear"
    g from x1 and y1
    g to x2 and y2
    give back g
end

define radial gradient at cx and cy with radius r
    ## Create a radial gradient
    let g = new Gradient with "radial"
    g from cx and cy
    g at radius r
    give back g
end

make kind called PathCommand
    has type of type text
    has points of type list of number

    when created taking cmd type and point list
        type = cmd type
        points = point list
    end
end

make kind called Path
    has commands of type list of PathCommand
    has closed of type bool

    when created
        commands = list of
        closed = false
    end

    behaviour move to taking x and y
        let cmd = new PathCommand with "move" and list of x y
        add cmd to commands
        give back this
    end

    behaviour line to taking x and y
        let cmd = new PathCommand with "line" and list of x y
        add cmd to commands
        give back this
    end

    behaviour curve to taking cp1x and cp1y and cp2x and cp2y and x and y
        let cmd = new PathCommand with "curve" and list of cp1x cp1y cp2x cp2y x y
        add cmd to commands
        give back this
    end

    behaviour quad to taking cpx and cpy and x and y
        let cmd = new PathCommand with "quad" and list of cpx cpy x y
        add cmd to commands
        give back this
    end

    behaviour arc to taking x and y and radius
        let cmd = new PathCommand with "arc" and list of x y radius
        add cmd to commands
        give back this
    end

    behaviour close
        closed = true
        let cmd = new PathCommand with "close" and list of
        add cmd to commands
        give back this
    end

    behaviour rect taking x and y and w and h
        this move to x and y
        this line to x plus w and y
        this line to x plus w and y plus h
        this line to x and y plus h
        this close
        give back this
    end
end

make kind called Canvas
    has width of type number
    has height of type number
    has background color of type Color
    has fill color of type Color
    has stroke color of type Color
    has stroke width of type number
    has font family of type text
    has font size of type number
    has opacity of type number
    has transform matrix of type list of number
    has clip region

    when created taking w and h
        width = w
        height = h
        background color = new Color with 255 and 255 and 255
        fill color = new Color with 0 and 0 and 0
        stroke color = new Color with 0 and 0 and 0
        stroke width = 1
        font family = "sans-serif"
        font size = 16
        opacity = 1
        transform matrix = list of 1 0 0 1 0 0
        clip region = empty
    end

    behaviour set fill taking color
        fill color = color
    end

    behaviour set stroke taking color
        stroke color = color
    end

    behaviour set stroke width taking value
        stroke width = value
    end

    behaviour set font taking family and size
        font family = family
        font size = size
    end

    behaviour set opacity taking value
        if value is between 0 and 1
            opacity = value
        end
    end

    behaviour clear
        show "  Clear canvas to background: " background color to hex
    end

    behaviour fill rect taking x and y and w and h
        show "  FillRect at " x "," y " size " w "x" h " color " fill color to hex
    end

    behaviour stroke rect taking x and y and w and h
        show "  StrokeRect at " x "," y " size " w "x" h " color " stroke color to hex
    end

    behaviour fill circle taking cx and cy and r
        show "  FillCircle at " cx "," cy " radius " r " color " fill color to hex
    end

    behaviour stroke circle taking cx and cy and r
        show "  StrokeCircle at " cx "," cy " radius " r " color " stroke color to hex
    end

    behaviour fill ellipse taking cx and cy and rx and ry
        show "  FillEllipse at " cx "," cy " rx " rx " ry " ry " color " fill color to hex
    end

    behaviour stroke ellipse taking cx and cy and rx and ry
        show "  StrokeEllipse at " cx "," cy " rx " rx " ry " ry " color " stroke color to hex
    end

    behaviour fill path taking path
        show "  FillPath with " size of path commands " commands"
        for each cmd in path commands
            show "    " cmd type
        end
    end

    behaviour stroke path taking path
        show "  StrokePath with " size of path commands " commands"
        for each cmd in path commands
            show "    " cmd type
        end
    end

    behaviour draw line taking x1 and y1 and x2 and y2
        show "  Line from " x1 "," y1 " to " x2 "," y2 " color " stroke color to hex " width " stroke width
    end

    behaviour draw text taking text and x and y
        show "  Text \"" text "\" at " x "," y " font " font family " " font size " color " fill color to hex
    end

    behaviour measure text taking text
        let estimated width = size of text times font size times 0.6
        give back estimated width
    end

    behaviour draw rounded rect taking x and y and w and h and r
        show "  RoundedRect at " x "," y " size " w "x" h " radius " r " fill " fill color to hex
    end

    behaviour draw polygon taking points
        show "  Polygon with " size of points " points"
        for each pt in points
            show "    point at " item 0 of pt "," item 1 of pt
        end
    end

    behaviour draw image taking path and x and y and w and h
        show "  Image \"" path "\" at " x "," y " size " w "x" h
    end

    behaviour save
        show "  Save canvas state"
    end

    behaviour restore
        show "  Restore canvas state"
    end

    behaviour translate taking dx and dy
        show "  Translate by " dx "," dy
    end

    behaviour rotate taking angle
        show "  Rotate by " angle " degrees"
    end

    behaviour scale taking sx and sy
        show "  Scale by " sx "," sy
    end

    behaviour clip taking path
        clip region = path
        show "  Set clip region"
    end

    behaviour fill gradient rect taking x and y and w and h and gradient
        show "  FillGradientRect at " x "," y " size " w "x" h " gradient " gradient type
        for each stop in gradient stops
            let color = stop get "color"
            show "    stop at " stop get "offset" " color " color to hex
        end
    end

    behaviour fill gradient circle taking cx and cy and r and gradient
        show "  FillGradientCircle at " cx "," cy " radius " r " gradient " gradient type
    end

    behaviour clear rect taking x and y and w and h
        show "  ClearRect at " x "," y " size " w "x" h
    end

    behaviour draw pixel taking x and y
        show "  Pixel at " x "," y " color " fill color to hex
    end

    behaviour get pixel taking x and y
        show "  GetPixel at " x "," y
        give back background color
    end

    behaviour resize taking w and h
        width = w
        height = h
        show "  Resize canvas to " width "x" height
    end

    behaviour to image
        show "  Export canvas as image (" width "x" height ")"
        give back empty
    end

    behaviour render
        show "[Canvas] " width "x" height
        show "  Background: " background color to hex
        show "  Fill: " fill color to hex
        show "  Stroke: " stroke color to hex " Width: " stroke width
    end
end

define create canvas taking width and height
    ## Create a new drawing canvas
    give back new Canvas with width and height
end

define draw circle on canvas taking cx and cy and r
    ## Draw a filled circle on a canvas
    canvas fill circle cx and cy and r
end

define draw rect on canvas taking x and y and w and h
    ## Draw a filled rectangle on a canvas
    canvas fill rect x and y and w and h
end

define draw line on canvas from x1 and y1 to x2 and y2
    ## Draw a line on a canvas
    canvas draw line x1 and y1 and x2 and y2
end

define draw text on canvas taking text at x and y
    ## Draw text on a canvas
    canvas draw text text and x and y
end

define create path
    ## Create a new path for drawing
    give back new Path
end
