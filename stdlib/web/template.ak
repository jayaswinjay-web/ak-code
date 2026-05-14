## AK CODE Template Engine Module
## Text template engine with variable interpolation conditionals and loops

make kind called Template
    has source of type text
    has parsed blocks of type list
    has ready of type bool

    when created taking source text
        source = source text
        parsed blocks = list of
        ready = false
    end

    behaviour compile
        if ready
            give back
        end
        parsed blocks = tokenize template source
        ready = true
    end

    behaviour render taking data
        if ready is not true
            compile
        end
        let collector = new RenderCollector
        render blocks parsed blocks from 0 with data and collector
        give back collector result
    end

    behaviour render escaped taking data
        let raw = render data
        give back html escape raw
    end
end

make kind called RenderCollector
    has pieces of type list

    when created
        pieces = list of
    end

    behaviour add taking text
        add text to pieces
    end

    behaviour result
        give back join pieces with ""
    end
end

define tokenize template taking source
    let blocks = list of
    let len = size of source
    let i = 0
    let text buf = ""

    repeat while i is less than len
        let ch = character at i of source
        if ch is "{" and i plus 1 is less than len and character at i plus 1 of source is "{"
            if size of text buf is greater than 0
                let tb = new TextBlock
                tb content = text buf
                add tb to blocks
                text buf = ""
            end
            i = i plus 2
            let tag = ""
            repeat while i is less than len
                if character at i of source is "}" and i plus 1 is less than len and character at i plus 1 of source is "}"
                    i = i plus 2
                    break
                end
                tag = tag plus character at i of source
                i = i plus 1
            end
            let parsed = parse tag text tag
            if parsed is not empty
                add parsed to blocks
            end
        else
            text buf = text buf plus ch
            i = i plus 1
        end
    end

    if size of text buf is greater than 0
        let tb = new TextBlock
        tb content = text buf
        add tb to blocks
    end

    give back blocks
end

define parse tag text taking tag
    let trimmed = trim tag
    if size of trimmed is 0
        give back empty
    end

    let first = character at 0 of trimmed
    if first is "#"
        give back new CommentBlock
    end

    let words = split trimmed by " "
    if size of words is 0
        give back empty
    end

    let keyword = item 0 of words

    if keyword is "if"
        let ib = new IfBlock
        ib condition = trim slice of trimmed from 3 to size of trimmed
        give back ib
    end

    if keyword is "for"
        let fb = new ForBlock
        let inner = trim slice of trimmed from 4 to size of trimmed
        let inner words = split inner by " "
        if size of inner words is greater than 2 and item 1 of inner words is "and"
            fb item name = item 0 of inner words
            fb key name = item 2 of inner words
            fb iterate map = true
            let src = ""
            let j = 4
            repeat while j is less than size of inner words
                if j is greater than 4
                    src = src plus " "
                end
                src = src plus item j of inner words
                j = j plus 1
            end
            fb source = src
        else if size of inner words is greater than 1
            fb item name = item 0 of inner words
            fb key name = ""
            fb iterate map = false
            let src = ""
            let j = 2
            repeat while j is less than size of inner words
                if j is greater than 2
                    src = src plus " "
                end
                src = src plus item j of inner words
                j = j plus 1
            end
            fb source = src
        end
        give back fb
    end

    if keyword is "else"
        give back new ElseBlock
    end

    if keyword is "end"
        give back new EndBlock
    end

    let vb = new VariableBlock
    vb expression = trimmed
    give back vb
end

define render blocks taking blocks from start with data and collector
    let i = start
    let len = size of blocks
    repeat while i is less than len
        let block = item i of blocks

        if block is TextBlock
            collector add block content

        else if block is VariableBlock
            let val = resolve expression block expression in data
            if val is not empty
                collector add val as text
            end

        else if block is CommentBlock

        else if block is IfBlock
            let cond = resolve expression block condition in data
            if is truthy cond
                let next = render blocks from i plus 1 with data and collector
                i = next
            else
                let next = skip to else or end in blocks from i plus 1
                if next is not empty and next is not -1
                    let else block = item next of blocks
                    if else block is ElseBlock
                        let after = render blocks from next plus 1 with data and collector
                        i = after
                    else
                        i = next plus 1
                    end
                else
                    i = len
                end
            end
            repeat while i is less than len
                let next block = item i of blocks
                if next block is EndBlock
                    i = i plus 1
                    break
                end
                i = i plus 1
            end

        else if block is ForBlock
            let source = resolve expression block source in data
            if source is not empty
                if block iterate map
                    for each map key and map val in source
                        let loop data = data
                        if size of block key name is greater than 0
                            loop data set block key name to map key
                        end
                        if size of block item name is greater than 0
                            loop data set block item name to map val
                        end
                        let after = render blocks from i plus 1 with loop data and collector
                    end
                else
                    for each list item in source
                        let loop data = data
                        if size of block item name is greater than 0
                            loop data set block item name to list item
                        end
                        let after = render blocks from i plus 1 with loop data and collector
                    end
                end
            end
            let end pos = find matching end in blocks from i plus 1
            i = end pos

        else if block is ElseBlock
            give back i minus 1

        else if block is EndBlock
            give back i
        end

        i = i plus 1
    end

    give back i
end

define skip to else or end in blocks from start
    let i = start
    let len = size of blocks
    let depth = 1
    repeat while i is less than len and depth is greater than 0
        let block = item i of blocks
        if block is IfBlock or block is ForBlock
            depth = depth plus 1
        else if block is EndBlock
            depth = depth minus 1
        else if block is ElseBlock and depth is 1
            give back i
        end
        i = i plus 1
    end
    give back -1
end

define find matching end in blocks from start
    let i = start
    let len = size of blocks
    let depth = 1
    repeat while i is less than len and depth is greater than 0
        let block = item i of blocks
        if block is IfBlock or block is ForBlock
            depth = depth plus 1
        else if block is EndBlock
            depth = depth minus 1
        end
        if depth is 0
            give back i
        end
        i = i plus 1
    end
    give back len
end

make kind called TextBlock
    has content of type text
end

make kind called VariableBlock
    has expression of type text
end

make kind called IfBlock
    has condition of type text
end

make kind called ForBlock
    has item name of type text
    has key name of type text
    has source of type text
    has iterate map of type bool

    when created
        item name = ""
        key name = ""
        source = ""
        iterate map = false
    end
end

make kind called ElseBlock
end

make kind called EndBlock
end

make kind called CommentBlock
end

define resolve expression taking expr in data
    let trimmed = trim expr
    if size of trimmed is 0
        give back empty
    end

    let not eq parts = split trimmed by " is not "
    if size of not eq parts is greater than 1
        let left = resolve path trim item 0 of not eq parts in data
        let right = resolve path trim item 1 of not eq parts in data
        if left is empty and right is empty
            give back false
        end
        if left is not right
            give back true
        end
        give back false
    end

    let eq parts = split trimmed by " is "
    if size of eq parts is greater than 1
        let left = resolve path trim item 0 of eq parts in data
        let right = resolve path trim item 1 of eq parts in data
        if left is right
            give back true
        end
        give back false
    end

    give back resolve path trimmed in data
end

define resolve path taking name in data
    if data has name
        give back data get name
    end
    let parts = split name by "."
    if size of parts is greater than 1
        let current = data
        for each part in parts
            if current is map
                if current has part
                    current = current get part
                else
                    give back empty
                end
            else
                give back empty
            end
        end
        give back current
    end
    give back empty
end

define is truthy taking value
    if value is empty
        give back false
    end
    if value is false
        give back false
    end
    if value as text is "false"
        give back false
    end
    if value as text is "0"
        give back false
    end
    give back true
end

define trim taking text
    let len = size of text
    if len is 0
        give back ""
    end
    let s = 0
    let e = len minus 1
    repeat while s is less than len and (character at s of text is space or character at s of text is tab or character at s of text is newline or character at s of text is carriage return)
        s = s plus 1
    end
    repeat while e is greater than s and (character at e of text is space or character at e of text is tab or character at e of text is newline or character at e of text is carriage return)
        e = e minus 1
    end
    give back slice of text from s to e plus 1
end

define html escape taking text
    let result = ""
    let i = 0
    let len = size of text
    repeat while i is less than len
        let ch = character at i of text
        if ch is "&"
            result = result plus "&amp;"
        else if ch is "<"
            result = result plus "&lt;"
        else if ch is ">"
            result = result plus "&gt;"
        else if ch is double quote
            result = result plus "&quot;"
        else if ch is "'"
            result = result plus "&#39;"
        else
            result = result plus ch
        end
        i = i plus 1
    end
    give back result
end

define render template taking template text and data
    let tpl = new Template with template text
    give back tpl render data
end

define render file taking file path and data
    let content = read file file path
    if content is empty
        give back ""
    end
    let tpl = new Template with content
    give back tpl render data
end

define create template taking source text
    give back new Template with source text
end
