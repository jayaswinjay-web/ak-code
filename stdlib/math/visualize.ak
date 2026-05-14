## AK CODE Visualization Module — chart rendering to text and HTML
## Provides chart types for data visualization with ASCII and HTML output

make kind called BarChart
    has labels of type list of text
    has values of type list of number
    has title of type text
    has bar char of type text

    when created taking lbls and vals and ttl
        labels = lbls
        values = vals
        title = ttl
        bar char = "█"
    end

    behaviour set bar character taking c
        bar char = c
    end

    behaviour max value
        if values is empty
            give back 1
        end
        let result = item 0 of values
        let i = 1
        repeat while i is less than size of values
            if item i of values is greater than result
                result = item i of values
            end
            i = i plus 1
        end
        give back result
    end

    behaviour bar width taking max val and max pixels
        if max val is 0
            give back 0
        end
        give back (value divided by max val) times max pixels
    end

    behaviour as text
        let result = ""
        if title is not empty
            result = title plus "\n"
        end
        let max val = max value
        let max pixels = 40
        let n = size of values
        let i = 0
        repeat while i is less than n
            let label = item i of labels
            let val = item i of values
            let width = bar width taking val and max val and max pixels
            let bar line = label plus " "
            let j = 0
            repeat while j is less than width
                bar line = bar line plus bar char
                j = j plus 1
            end
            bar line = bar line plus " " plus val as text
            if i is less than n minus 1
                result = result plus bar line plus "\n"
            else
                result = result plus bar line
            end
            i = i plus 1
        end
        give back result
    end

    behaviour as html
        let result = "<div class=\"bar-chart\">"
        if title is not empty
            result = result plus "<h3>" plus title plus "</h3>"
        end
        let max val = max value
        let max pixels = 300
        result = result plus "<div style=\"display:flex;flex-direction:column;gap:8px;padding:16px;background:#f8f9fa;border-radius:8px;font-family:sans-serif;\">"
        let i = 0
        repeat while i is less than size of values
            let label = item i of labels
            let val = item i of values
            let width = bar width taking val and max val and max pixels
            result = result plus "<div style=\"display:flex;align-items:center;gap:12px;\">"
            result = result plus "<span style=\"width:80px;text-align:right;font-size:14px;color:#495057;\">" plus label plus "</span>"
            result = result plus "<div style=\"height:24px;width:" plus width as text plus "px;background:#4263eb;border-radius:4px;transition:width 0.3s;min-width:4px;\"></div>"
            result = result plus "<span style=\"font-size:14px;color:#868e96;\">" plus val as text plus "</span>"
            result = result plus "</div>"
            i = i plus 1
        end
        result = result plus "</div></div>"
        give back result
    end
end

make kind called LineChart
    has x values of type list of number
    has y values of type list of number
    has title of type text
    has width of type number
    has height of type number

    when created taking xs and ys and ttl
        x values = xs
        y values = ys
        title = ttl
        width = 60
        height = 20
    end

    behaviour set dimensions taking w and h
        width = w
        height = h
    end

    behaviour min of list taking data
        if data is empty
            give back 0
        end
        let result = item 0 of data
        let i = 1
        repeat while i is less than size of data
            if item i of data is less than result
                result = item i of data
            end
            i = i plus 1
        end
        give back result
    end

    behaviour max of list taking data
        if data is empty
            give back 1
        end
        let result = item 0 of data
        let i = 1
        repeat while i is less than size of data
            if item i of data is greater than result
                result = item i of data
            end
            i = i plus 1
        end
        give back result
    end

    behaviour as text
        let result = ""
        if title is not empty
            result = title plus "\n"
        end
        let n = size of y values
        if n is 0
            give back result plus "(no data)"
        end
        let y min = min of list taking y values
        let y max = max of list taking y values
        let y range = y max minus y min
        if y range is 0
            y range = 1
        end
        let h = height
        let w = width
        let grid = list of
        let row = 0
        repeat while row is less than h
            let line = list of
            let col = 0
            repeat while col is less than w
                add " " to line
                col = col plus 1
            end
            add line to grid
            row = row plus 1
        end
        let i = 0
        repeat while i is less than n
            let x frac = i divided by (n minus 1)
            let col = x frac times (w minus 1)
            let y norm = (item i of y values minus y min) divided by y range
            let row = (1 minus y norm) times (h minus 1)
            set item col of item row of grid to "●"
            if i is less than n minus 1
                let x frac2 = (i plus 1) divided by (n minus 1)
                let col2 = x frac2 times (w minus 1)
                let y norm2 = (item (i plus 1) of y values minus y min) divided by y range
                let row2 = (1 minus y norm2) times (h minus 1)
                let steps = max of list taking list of absolute (col2 minus col) absolute (row2 minus row)
                if steps is 0
                    steps = 1
                end
                let s = 1
                repeat while s is less than steps
                    let t = s divided by steps
                    let inter col = col plus t times (col2 minus col)
                    let inter row = row plus t times (row2 minus row)
                    let c = inter col
                    let r = inter row
                    if c is less than w and r is less than h and c is greater than or equal to 0 and r is greater than or equal to 0
                        let existing = item c of item r of grid
                        if existing is " "
                            set item c of item r of grid to "─"
                        end
                    end
                    s = s plus 1
                end
            end
            i = i plus 1
        end
        let r = 0
        repeat while r is less than h
            let row data = item r of grid
            let line = ""
            let c = 0
            repeat while c is less than w
                line = line plus item c of row data
                c = c plus 1
            end
            if r is less than h minus 1
                result = result plus line plus "\n"
            else
                result = result plus line
            end
            r = r plus 1
        end
        give back result
    end

    behaviour as html
        let result = "<div class=\"line-chart\">"
        if title is not empty
            result = result plus "<h3>" plus title plus "</h3>"
        end
        result = result plus "<div style=\"padding:16px;background:#f8f9fa;border-radius:8px;font-family:sans-serif;\">"
        result = result plus "<svg viewBox=\"0 0 500 300\" style=\"width:100%;height:auto;\">"
        let n = size of y values
        if n is greater than 1
            let y min = min of list taking y values
            let y max = max of list taking y values
            let y range = y max minus y min
            if y range is 0
                y range = 1
            end
            let padding = 40
            let svg w = 460
            let svg h = 240
            let points = ""
            let i = 0
            repeat while i is less than n
                let px = padding plus (i divided by (n minus 1)) times svg w
                let py = padding plus svg h minus ((item i of y values minus y min) divided by y range) times svg h
                if i is 0
                    points = points plus px as text plus "," plus py as text
                else
                    points = points plus " " plus px as text plus "," plus py as text
                end
                result = result plus "<circle cx=\"" plus px as text plus "\" cy=\"" plus py as text plus "\" r=\"4\" fill=\"#4263eb\"/>"
                i = i plus 1
            end
            result = result plus "<polyline points=\"" plus points plus "\" fill=\"none\" stroke=\"#4263eb\" stroke-width=\"2\" stroke-linejoin=\"round\"/>"
            result = result plus "<line x1=\"" plus padding as text plus "\" y1=\"" plus padding as text plus "\" x2=\"" plus padding as text plus "\" y2=\"" plus (padding plus svg h) as text plus "\" stroke=\"#dee2e6\" stroke-width=\"1\"/>"
            result = result plus "<line x1=\"" plus padding as text plus "\" y1=\"" plus (padding plus svg h) as text plus "\" x2=\"" plus (padding plus svg w) as text plus "\" y2=\"" plus (padding plus svg h) as text plus "\" stroke=\"#dee2e6\" stroke-width=\"1\"/>"
            result = result plus "<text x=\"" plus padding as text plus "\" y=\"" plus (padding minus 8) as text plus "\" font-size=\"12\" fill=\"#868e96\">" plus y max as text plus "</text>"
            result = result plus "<text x=\"" plus padding as text plus "\" y=\"" plus (padding plus svg h plus 16) as text plus "\" font-size=\"12\" fill=\"#868e96\">" plus y min as text plus "</text>"
        end
        result = result plus "</svg></div></div>"
        give back result
    end
end

make kind called PieChart
    has labels of type list of text
    has values of type list of number
    has title of type text

    when created taking lbls and vals and ttl
        labels = lbls
        values = vals
        title = ttl
    end

    behaviour total
        let sum = 0
        for each val in values
            sum = sum plus val
        end
        give back sum
    end

    behaviour as text
        let result = ""
        if title is not empty
            result = title plus "\n"
        end
        let tot = total
        if tot is 0
            give back result plus "(no data)"
        end
        let n = size of values
        let max label len = 0
        let i = 0
        repeat while i is less than n
            let l = size of item i of labels
            if l is greater than max label len
                max label len = l
            end
            i = i plus 1
        end
        let shades = list of "@" "#" "O" "+" "-" "." " " ":" "~" "*"
        let i = 0
        repeat while i is less than n
            let label = item i of labels
            let val = item i of values
            let pct = (val divided by tot) times 100
            let bar len = pct divided by 5
            if bar len is less than 1 and pct is greater than 0
                bar len = 1
            end
            let shade = item (i mod size of shades) of shades
            let bar = ""
            let j = 0
            repeat while j is less than bar len
                bar = bar plus shade
                j = j plus 1
            end
            let padded = label
            let k = size of label
            repeat while k is less than max label len
                padded = padded plus " "
                k = k plus 1
            end
            let line = padded plus " " plus bar plus " " plus pct as text plus "%"
            if i is less than n minus 1
                result = result plus line plus "\n"
            else
                result = result plus line
            end
            i = i plus 1
        end
        give back result
    end

    behaviour as html
        let result = "<div class=\"pie-chart\">"
        if title is not empty
            result = result plus "<h3>" plus title plus "</h3>"
        end
        result = result plus "<div style=\"padding:16px;background:#f8f9fa;border-radius:8px;font-family:sans-serif;\">"
        let tot = total
        if tot is not 0
            let colors = list of "#4263eb" "#fa5252" "#40c057" "#fab005" "#7950f2" "#fd7e14" "#15aabf" "#e64980" "#82c91e" "#868e96"
            let cumulative = 0
            let i = 0
            repeat while i is less than size of values
                let pct = (item i of values divided by tot) times 100
                let angle = cumulative times 3.6
                let sweep = pct times 3.6
                let color = item (i mod size of colors) of colors
                let label = item i of labels
                result = result plus "<div style=\"display:flex;align-items:center;gap:8px;margin:4px 0;\">"
                result = result plus "<span style=\"display:inline-block;width:12px;height:12px;background:" plus color plus ";border-radius:50%;\"></span>"
                result = result plus "<span style=\"font-size:14px;color:#495057;\">" plus label plus "</span>"
                result = result plus "<span style=\"font-size:14px;color:#868e96;\">" plus pct as text plus "%</span>"
                result = result plus "</div>"
                cumulative = cumulative plus pct
                i = i plus 1
            end
        end
        result = result plus "</div></div>"
        give back result
    end
end

make kind called ScatterPlot
    has x values of type list of number
    has y values of type list of number
    has title of type text
    has width of type number
    has height of type number

    when created taking xs and ys and ttl
        x values = xs
        y values = ys
        title = ttl
        width = 50
        height = 20
    end

    behaviour set dimensions taking w and h
        width = w
        height = h
    end

    behaviour min of list taking data
        if data is empty
            give back 0
        end
        let result = item 0 of data
        let i = 1
        repeat while i is less than size of data
            if item i of data is less than result
                result = item i of data
            end
            i = i plus 1
        end
        give back result
    end

    behaviour max of list taking data
        if data is empty
            give back 1
        end
        let result = item 0 of data
        let i = 1
        repeat while i is less than size of data
            if item i of data is greater than result
                result = item i of data
            end
            i = i plus 1
        end
        give back result
    end

    behaviour as text
        let result = ""
        if title is not empty
            result = title plus "\n"
        end
        let n = size of x values
        if n is 0
            give back result plus "(no data)"
        end
        let x min = min of list taking x values
        let x max = max of list taking x values
        let y min = min of list taking y values
        let y max = max of list taking y values
        let x range = x max minus x min
        let y range = y max minus y min
        if x range is 0
            x range = 1
        end
        if y range is 0
            y range = 1
        end
        let h = height
        let w = width
        let grid = list of
        let row = 0
        repeat while row is less than h
            let line = list of
            let col = 0
            repeat while col is less than w
                add " " to line
                col = col plus 1
            end
            add line to grid
            row = row plus 1
        end
        let i = 0
        repeat while i is less than n
            let px = (item i of x values minus x min) divided by x range
            let py = (item i of y values minus y min) divided by y range
            let col = px times (w minus 1)
            let row = (1 minus py) times (h minus 1)
            if col is greater than or equal to 0 and col is less than w and row is greater than or equal to 0 and row is less than h
                set item col of item row of grid to "•"
            end
            i = i plus 1
        end
        let r = 0
        repeat while r is less than h
            let row data = item r of grid
            let line = ""
            let c = 0
            repeat while c is less than w
                line = line plus item c of row data
                c = c plus 1
            end
            if r is less than h minus 1
                result = result plus line plus "\n"
            else
                result = result plus line
            end
            r = r plus 1
        end
        give back result
    end

    behaviour as html
        let result = "<div class=\"scatter-plot\">"
        if title is not empty
            result = result plus "<h3>" plus title plus "</h3>"
        end
        result = result plus "<div style=\"padding:16px;background:#f8f9fa;border-radius:8px;font-family:sans-serif;\">"
        result = result plus "<svg viewBox=\"0 0 500 300\" style=\"width:100%;height:auto;\">"
        let n = size of x values
        if n is greater than 0
            let x min = min of list taking x values
            let x max = max of list taking x values
            let y min = min of list taking y values
            let y max = max of list taking y values
            let x range = x max minus x min
            let y range = y max minus y min
            if x range is 0
                x range = 1
            end
            if y range is 0
                y range = 1
            end
            let padding = 40
            let svg w = 420
            let svg h = 220
            let i = 0
            repeat while i is less than n
                let px = padding plus ((item i of x values minus x min) divided by x range) times svg w
                let py = padding plus svg h minus ((item i of y values minus y min) divided by y range) times svg h
                result = result plus "<circle cx=\"" plus px as text plus "\" cy=\"" plus py as text plus "\" r=\"4\" fill=\"#4263eb\" opacity=\"0.7\"/>"
                i = i plus 1
            end
            result = result plus "<line x1=\"" plus padding as text plus "\" y1=\"" plus padding as text plus "\" x2=\"" plus padding as text plus "\" y2=\"" plus (padding plus svg h) as text plus "\" stroke=\"#dee2e6\" stroke-width=\"1\"/>"
            result = result plus "<line x1=\"" plus padding as text plus "\" y1=\"" plus (padding plus svg h) as text plus "\" x2=\"" plus (padding plus svg w) as text plus "\" y2=\"" plus (padding plus svg h) as text plus "\" stroke=\"#dee2e6\" stroke-width=\"1\"/>"
            result = result plus "<text x=\"" plus padding as text plus "\" y=\"" plus (padding plus svg h plus 16) as text plus "\" font-size=\"12\" fill=\"#868e96\">" plus x min as text plus "</text>"
            result = result plus "<text x=\"" plus (padding plus svg w) as text plus "\" y=\"" plus (padding plus svg h plus 16) as text plus "\" font-size=\"12\" fill=\"#868e96\" text-anchor=\"end\">" plus x max as text plus "</text>"
            result = result plus "<text x=\"" plus padding as text plus "\" y=\"" plus (padding minus 8) as text plus "\" font-size=\"12\" fill=\"#868e96\">" plus y max as text plus "</text>"
            result = result plus "<text x=\"" plus padding as text plus "\" y=\"" plus (padding plus svg h plus 4) as text plus "\" font-size=\"12\" fill=\"#868e96\">" plus y min as text plus "</text>"
        end
        result = result plus "</svg></div></div>"
        give back result
    end
end

make kind called Histogram
    has data of type list of number
    has bins of type number
    has title of type text

    when created taking d and b and ttl
        data = d
        bins = b
        title = ttl
    end

    behaviour min of list taking data
        if data is empty
            give back 0
        end
        let result = item 0 of data
        let i = 1
        repeat while i is less than size of data
            if item i of data is less than result
                result = item i of data
            end
            i = i plus 1
        end
        give back result
    end

    behaviour max of list taking data
        if data is empty
            give back 1
        end
        let result = item 0 of data
        let i = 1
        repeat while i is less than size of data
            if item i of data is greater than result
                result = item i of data
            end
            i = i plus 1
        end
        give back result
    end

    behaviour as text
        let result = ""
        if title is not empty
            result = title plus "\n"
        end
        let n = size of data
        if n is 0
            give back result plus "(no data)"
        end
        let d min = min of list taking data
        let d max = max of list taking data
        let d range = d max minus d min
        if d range is 0
            d range = 1
        end
        let bin width = d range divided by bins
        let counts = list of
        let i = 0
        repeat while i is less than bins
            add 0 to counts
            i = i plus 1
        end
        let i = 0
        repeat while i is less than n
            let val = item i of data
            let bin idx = (val minus d min) divided by bin width
            if bin idx is bins
                bin idx = bins minus 1
            end
            let current = item bin idx of counts
            set item bin idx of counts to current plus 1
            i = i plus 1
        end
        let max count = max of list taking counts
        if max count is 0
            max count = 1
        end
        let max bar = 30
        let i = 0
        repeat while i is less than bins
            let low = d min plus i times bin width
            let high = low plus bin width
            let count = item i of counts
            let bar len = (count divided by max count) times max bar
            let bar = ""
            let j = 0
            repeat while j is less than bar len
                bar = bar plus "█"
                j = j plus 1
            end
            let line = bar plus " " plus count as text
            if i is less than bins minus 1
                result = result plus line plus "\n"
            else
                result = result plus line
            end
            i = i plus 1
        end
        give back result
    end

    behaviour as html
        let result = "<div class=\"histogram\">"
        if title is not empty
            result = result plus "<h3>" plus title plus "</h3>"
        end
        result = result plus "<div style=\"padding:16px;background:#f8f9fa;border-radius:8px;font-family:sans-serif;\">"
        let n = size of data
        if n is greater than 0
            let d min = min of list taking data
            let d max = max of list taking data
            let d range = d max minus d min
            if d range is 0
                d range = 1
            end
            let bin width = d range divided by bins
            let counts = list of
            let i = 0
            repeat while i is less than bins
                add 0 to counts
                i = i plus 1
            end
            let i = 0
            repeat while i is less than n
                let val = item i of data
                let bin idx = (val minus d min) divided by bin width
                if bin idx is bins
                    bin idx = bins minus 1
                end
                let current = item bin idx of counts
                set item bin idx of counts to current plus 1
                i = i plus 1
            end
            let max count = max of list taking counts
            if max count is 0
                max count = 1
            end
            let svg w = 460
            let svg h = 240
            let padding = 40
            let plot w = svg w minus padding
            let bar w = plot w divided by bins
            result = result plus "<svg viewBox=\"0 0 500 300\" style=\"width:100%;height:auto;\">"
            let i = 0
            repeat while i is less than bins
                let count = item i of counts
                let bar h = (count divided by max count) times svg h
                let x = padding plus i times bar w
                let y = padding plus svg h minus bar h
                result = result plus "<rect x=\"" plus x as text plus "\" y=\"" plus y as text plus "\" width=\"" plus (bar w minus 2) as text plus "\" height=\"" plus bar h as text plus "\" fill=\"#4263eb\" opacity=\"0.8\" rx=\"2\"/>"
                i = i plus 1
            end
            result = result plus "</svg>"
        end
        result = result plus "</div></div>"
        give back result
    end
end

define bar chart taking labels and values with title
    ## Creates a bar chart and renders it as text
    let chart = new BarChart with labels and values and title
    give back chart as text
end

define line chart taking x and y with title
    ## Creates a line chart and renders it as text
    let chart = new LineChart with x and y and title
    give back chart as text
end

define pie chart taking labels and values with title
    ## Creates a pie chart and renders it as text
    let chart = new PieChart with labels and values and title
    give back chart as text
end

define scatter plot taking x and y with title
    ## Creates a scatter plot and renders it as text
    let chart = new ScatterPlot with x and y and title
    give back chart as text
end

define render bar chart html taking labels and values with title
    ## Creates a bar chart and renders it as HTML
    let chart = new BarChart with labels and values and title
    give back chart as html
end

define render line chart html taking x and y with title
    ## Creates a line chart and renders it as HTML
    let chart = new LineChart with x and y and title
    give back chart as html
end

define render pie chart html taking labels and values with title
    ## Creates a pie chart and renders it as HTML
    let chart = new PieChart with labels and values and title
    give back chart as html
end

define render scatter plot html taking x and y with title
    ## Creates a scatter plot and renders it as HTML
    let chart = new ScatterPlot with x and y and title
    give back chart as html
end
