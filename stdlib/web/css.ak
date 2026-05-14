## AK CODE CSS Module — stylesheet generation
## Provides functions for generating CSS styles

define style rule taking selector and properties
    let result = selector plus " {\n"
    for each key and value in properties
        result = result plus "  " plus key plus ": " plus value plus ";\n"
    end
    result = result plus "}\n"
    give back result
end

define global style
    let props = map
        "margin" is "0"
        "padding" is "0"
        "box-sizing" is "border-box"
    end
    give back style rule "*" with props
end

define flexbox with direction and wrap and justify and align
    let props = map
        "display" is "flex"
        "flex-direction" is direction
        "flex-wrap" is wrap
        "justify-content" is justify
        "align-items" is align
    end
    give back props
end

define grid with columns and gap
    let props = map
        "display" is "grid"
        "grid-template-columns" is "repeat(" plus columns as text plus ", 1fr)"
        "gap" is gap
    end
    give back props
end

define button style with background and color and padding
    let props = map
        "background-color" is background
        "color" is color
        "padding" is padding
        "border" is "none"
        "border-radius" is "4px"
        "cursor" is "pointer"
        "font-size" is "16px"
    end
    give back props
end

define card with shadow radius and padding
    let props = map
        "background" is "#fff"
        "border-radius" is radius
        "padding" is padding
        "box-shadow" is "0 2px 4px rgba(0,0,0,0.1)"
    end
    give back props
end

define dark theme
    let props = map
        "background-color" is "#1e1e2e"
        "color" is "#cdd6f4"
        "font-family" is "sans-serif"
    end
    give back props
end

define light theme
    let props = map
        "background-color" is "#ffffff"
        "color" is "#333333"
        "font-family" is "sans-serif"
    end
    give back props
end

define responsive container with max width
    let props = map
        "max-width" is max width
        "margin" is "0 auto"
        "padding" is "0 20px"
    end
    give back props
end

define animation with name and duration and timing
    let rules = map
        "animation-name" is name
        "animation-duration" is duration
        "animation-timing-function" is timing
    end
    give back rules
end

define media query with condition and rules
    let result = "@media " plus condition plus " {\n"
    for each selector and props in rules
        result = result plus "  " plus selector plus " {\n"
        for each key and value in props
            result = result plus "    " plus key plus ": " plus value plus ";\n"
        end
        result = result plus "  }\n"
    end
    result = result plus "}\n"
    give back result
end

define keyframes with name and steps
    let result = "@keyframes " plus name plus " {\n"
    for each percentage and props in steps
        result = result plus "  " plus percentage as text plus "% {\n"
        for each key and value in props
            result = result plus "    " plus key plus ": " plus value plus ";\n"
        end
        result = result plus "  }\n"
    end
    result = result plus "}\n"
    give back result
end

define compile styles taking rules
    ## Compiles a map of style rules into a complete CSS string
    let result = ""
    for each selector and properties in rules
        result = result plus style rule selector with properties
    end
    give back result
end
