## AK CODE Documentation Generator
## Automatically generates HTML documentation from ## doc comments
## Provides DocGenerator kind with full pipeline: extract -> render -> write

make kind called DocComment
    ## Represents a single ## documentation comment with source location
    has text of type text
    has line of type number
    has column of type number

    when created taking comment_text and comment_line and comment_column
        text = comment_text
        line = comment_line
        column = comment_column
    end
end

make kind called DocSymbol
    ## Represents a documented symbol: define, make kind, always, let, behaviour
    has name of type text
    has kind of type text
    has doc_comments of type list of DocComment
    has children of type list of DocSymbol
    has signature of type text
    has file_path of type text
    has line of type number

    when created taking symbol_name and symbol_kind
        name = symbol_name
        kind = symbol_kind
        doc_comments = list of
        children = list of
        signature = ""
        file_path = ""
        line = 0
    end
end

make kind called DocGenerator
    ## Main documentation generator: extracts doc comments from .ak files,
    ## builds a symbol tree, and generates a complete HTML documentation site
    has symbols of type list of DocSymbol
    has output_dir of type text

    when created taking output_directory
        ## Initialise the generator with an output directory for HTML files
        output_dir = output_directory
        symbols = list of
    end

    behaviour extract from file taking path
        ## Reads an AK CODE source file, parses ## doc comments,
        ## and associates them with the next definition (define/make kind/always/let/behaviour)
        ## Returns a list of DocSymbol for the file
        let content = read file path
        if content is empty
            give back list of
        end

        let lines = split content by newline
        let doc_buffer = list of
        let file_symbols = list of
        let module_path = path

        let i = 0

        repeat while i is less than size of lines
            let line_text = item i of lines
            let trimmed = trim line_text

            ## Check for ## doc comment
            if starts with "##" in trimmed
                let comment_text = trimmed
                ## Strip the ## prefix and optional leading space
                let text_start = 2
                if size of comment_text is greater than 2
                    if character at 2 of comment_text is space
                        text_start = 3
                    end
                end
                let doc_text = slice of comment_text from text_start to size of comment_text
                let doc = new DocComment with doc_text and i plus 1 and text_start plus 1
                add doc to doc_buffer
            else if trimmed is not ""
                ## Check if this line starts a definition
                let first_word = ""
                let word_start = 0
                repeat while word_start is less than size of trimmed and character at word_start of trimmed is space
                    word_start = word_start plus 1
                end
                let word_end = word_start
                repeat while word_end is less than size of trimmed and character at word_end of trimmed is not space
                    word_end = word_end plus 1
                end
                if word_end is greater than word_start
                    first_word = slice of trimmed from word_start to word_end
                end

                let is_definition = false
                let symbol_name = ""
                let symbol_kind = ""
                let symbol_signature = ""

                if first_word is "define"
                    is_definition = true
                    symbol_kind = "function"
                    ## Find the name after 'define'
                    let after_define = slice of trimmed from word_end to size of trimmed
                    let after_trim = trim after_define
                    let name_end = 0
                    repeat while name_end is less than size of after_trim and character at name_end of after_trim is not space and character at name_end of after_trim is not "("
                        name_end = name_end plus 1
                    end
                    if name_end is greater than 0
                        symbol_name = slice of after_trim from 0 to name_end
                    end
                    let sig_line = trim line_text
                    symbol_kind = "function"
                    symbol_signature = sig_line
                else if first_word is "make"
                    is_definition = true
                    ## Check for 'make kind called X'
                    let after_make = slice of trimmed from word_end to size of trimmed
                    let after_make_trim = trim after_make
                    if starts with "kind" in after_make_trim
                        symbol_kind = "kind"
                        let after_kind = slice of after_make_trim from 4 to size of after_make_trim
                        let after_kind_trim = trim after_kind
                        if starts with "called" in after_kind_trim
                            let name_start = 6
                            let name_end = name_start
                            repeat while name_end is less than size of after_kind_trim and character at name_end of after_kind_trim is not space and character at name_end of after_kind_trim is not newline
                                name_end = name_end plus 1
                            end
                            symbol_name = slice of after_kind_trim from name_start to name_end
                        end
                    end
                    let sig_line = trim line_text
                    symbol_signature = sig_line
                else if first_word is "always"
                    is_definition = true
                    symbol_kind = "constant"
                    let after_always = slice of trimmed from word_end to size of trimmed
                    let after_always_trim = trim after_always
                    let name_end = 0
                    repeat while name_end is less than size of after_always_trim and character at name_end of after_always_trim is not space and character at name_end of after_always_trim is not "="
                        name_end = name_end plus 1
                    end
                    if name_end is greater than 0
                        symbol_name = slice of after_always_trim from 0 to name_end
                    end
                    let sig_line = trim line_text
                    symbol_signature = sig_line
                else if first_word is "let"
                    is_definition = true
                    symbol_kind = "variable"
                    let after_let = slice of trimmed from word_end to size of trimmed
                    let after_let_trim = trim after_let
                    let name_end = 0
                    repeat while name_end is less than size of after_let_trim and character at name_end of after_let_trim is not space and character at name_end of after_let_trim is not "="
                        name_end = name_end plus 1
                    end
                    if name_end is greater than 0
                        symbol_name = slice of after_let_trim from 0 to name_end
                    end
                    let sig_line = trim line_text
                    symbol_signature = sig_line
                else if first_word is "behaviour"
                    is_definition = true
                    symbol_kind = "behaviour"
                    let after_behaviour = slice of trimmed from word_end to size of trimmed
                    let after_behaviour_trim = trim after_behaviour
                    let name_end = 0
                    repeat while name_end is less than size of after_behaviour_trim and character at name_end of after_behaviour_trim is not space and character at name_end of after_behaviour_trim is not "("
                        name_end = name_end plus 1
                    end
                    if name_end is greater than 0
                        symbol_name = slice of after_behaviour_trim from 0 to name_end
                    end
                    let sig_line = trim line_text
                    symbol_signature = sig_line
                end

                if is_definition and symbol_name is not ""
                    let sym = new DocSymbol with symbol_name and symbol_kind
                    sym signature = symbol_signature
                    sym line = i plus 1
                    sym file_path = path
                    ## Attach buffered doc comments
                    for each doc in doc_buffer
                        add doc to sym doc_comments
                    end
                    add sym to file_symbols
                    ## Clear doc buffer after attaching
                    doc_buffer = list of
                end
            end

            i = i plus 1
        end

        give back file_symbols
    end

    behaviour extract from project taking root_path
        ## Recursively scans all .ak files in a project directory tree,
        ## calls extract_from_file on each, and collects all symbols
        let all_symbols = list of
        let files_to_scan = list of root_path

        repeat while size of files_to_scan is greater than 0
            let current = item 0 of files_to_scan
            remove item 0 from files_to_scan

            if is directory current
                let entries = list directory current
                for each entry in entries
                    if entry is not "." and entry is not ".."
                        let full_path = current plus "/" plus entry
                        if is directory full_path
                            add full_path to files_to_scan
                        else
                            let ext = get file extension full_path
                            if ext is ".ak"
                                let file_symbols = self extract from file taking full_path
                                for each sym in file_symbols
                                    add sym to all_symbols
                                end
                            end
                        end
                    end
                end
            else
                let ext = get file extension current
                if ext is ".ak"
                    let file_symbols = self extract from file taking current
                    for each sym in file_symbols
                        add sym to all_symbols
                    end
                end
            end
        end

        symbols = all_symbols
        self sort symbols
    end

    behaviour generate css
        ## Returns the embedded CSS styling for the documentation site
        ## Dark theme with monospace font, syntax highlighting colours
        let css = ""
        css = css plus "* { margin: 0; padding: 0; box-sizing: border-box; }" plus newline
        css = css plus "body { background: #1a1b26; color: #c9d1d9; font-family: 'Consolas', 'Courier New', monospace; line-height: 1.6; }" plus newline
        css = css plus "a { color: #7aa2f7; text-decoration: none; }" plus newline
        css = css plus "a:hover { color: #89b4fa; text-decoration: underline; }" plus newline
        css = css plus ".header { background: #16161e; border-bottom: 1px solid #2f3340; padding: 16px 24px; }" plus newline
        css = css plus ".header h1 { color: #bb9af7; font-size: 20px; font-weight: 600; }" plus newline
        css = css plus ".header span { color: #565f89; font-size: 12px; margin-left: 8px; }" plus newline
        css = css plus ".layout { display: flex; min-height: calc(100vh - 60px); }" plus newline
        css = css plus ".sidebar { width: 260px; background: #16161e; border-right: 1px solid #2f3340; overflow-y: auto; padding: 12px 0; flex-shrink: 0; }" plus newline
        css = css plus ".sidebar h2 { color: #7dcfff; font-size: 11px; text-transform: uppercase; letter-spacing: 1px; padding: 8px 16px; font-weight: 600; }" plus newline
        css = css plus ".sidebar .module { padding: 4px 0; }" plus newline
        css = css plus ".sidebar .module a { display: block; padding: 4px 16px; font-size: 13px; color: #c9d1d9; }" plus newline
        css = css plus ".sidebar .module a:hover { background: #1a1b26; }" plus newline
        css = css plus ".sidebar .symbol { display: block; padding: 2px 16px 2px 32px; font-size: 12px; color: #9aa5ce; }" plus newline
        css = css plus ".sidebar .symbol:hover { background: #1a1b26; color: #c9d1d9; }" plus newline
        css = css plus ".sidebar .kind-func { color: #a9b1d6; }" plus newline
        css = css plus ".sidebar .kind-kind { color: #bb9af7; }" plus newline
        css = css plus ".sidebar .kind-const { color: #ff9e64; }" plus newline
        css = css plus ".sidebar .kind-behaviour { color: #73daca; }" plus newline
        css = css plus ".sidebar .kind-var { color: #f7768e; }" plus newline
        css = css plus ".content { flex: 1; padding: 24px 32px; overflow-y: auto; }" plus newline
        css = css plus ".module-header { margin-bottom: 24px; }" plus newline
        css = css plus ".module-header h2 { color: #bb9af7; font-size: 24px; margin-bottom: 4px; }" plus newline
        css = css plus ".module-header p { color: #565f89; font-size: 13px; }" plus newline
        css = css plus ".symbol-card { background: #16161e; border: 1px solid #2f3340; border-radius: 8px; margin-bottom: 16px; overflow: hidden; }" plus newline
        css = css plus ".symbol-card .card-header { padding: 12px 16px; border-bottom: 1px solid #2f3340; cursor: pointer; }" plus newline
        css = css plus ".symbol-card .card-header:hover { background: #1f2133; }" plus newline
        css = css plus ".symbol-card .card-header .symbol-name { color: #7dcfff; font-size: 16px; font-weight: 600; }" plus newline
        css = css plus ".symbol-card .card-header .symbol-kind { display: inline-block; font-size: 10px; padding: 2px 6px; border-radius: 3px; margin-left: 8px; vertical-align: middle; }" plus newline
        css = css plus ".kind-function { background: #2d3f5e; color: #7aa2f7; }" plus newline
        css = css plus ".kind-kind { background: #3d2d5e; color: #bb9af7; }" plus newline
        css = css plus ".kind-constant { background: #3d3d2e; color: #ff9e64; }" + newline
        css = css plus ".kind-behaviour { background: #1d3d2e; color: #73daca; }" + newline
        css = css plus ".kind-variable { background: #3d1d2e; color: #f7768e; }" + newline
        css = css plus ".symbol-card .card-body { padding: 12px 16px; }" + newline
        css = css plus ".symbol-card .card-body .signature { background: #1a1b26; padding: 8px 12px; border-radius: 4px; font-family: 'Consolas', 'Courier New', monospace; font-size: 13px; color: #e0af68; margin-bottom: 12px; overflow-x: auto; border: 1px solid #2f3340; }" + newline
        css = css plus ".symbol-card .card-body .signature .kw { color: #bb9af7; }" + newline
        css = css plus ".symbol-card .card-body .signature .str { color: #9ece6a; }" + newline
        css = css plus ".symbol-card .card-body .signature .num { color: #ff9e64; }" + newline
        css = css plus ".symbol-card .card-body .signature .com { color: #565f89; }" + newline
        css = css plus ".symbol-card .card-body .meta { font-size: 11px; color: #565f89; margin-bottom: 8px; }" + newline
        css = css plus ".symbol-card .card-body .meta span { margin-right: 16px; }" + newline
        css = css plus ".symbol-card .card-body .meta .label { color: #7dcfff; }" + newline
        css = css plus ".symbol-card .card-body .children { margin-top: 12px; }" + newline
        css = css plus ".symbol-card .card-body .children h4 { color: #7dcfff; font-size: 12px; text-transform: uppercase; margin-bottom: 8px; }" + newline
        css = css plus ".symbol-card .card-body .children .child-card { background: #1a1b26; border: 1px solid #2f3340; border-radius: 4px; padding: 8px 12px; margin-bottom: 6px; }" + newline
        css = css plus ".symbol-card .card-body .children .child-card .child-name { color: #73daca; font-size: 13px; font-weight: 600; }" + newline
        css = css plus ".symbol-card .card-body .children .child-card .child-meta { font-size: 11px; color: #565f89; }" + newline
        css = css plus ".symbol-card .card-body .children .child-card .child-docs { font-size: 12px; color: #c9d1d9; margin-top: 4px; }" + newline
        css = css plus ".docs { font-size: 14px; color: #c9d1d9; margin-bottom: 12px; }" + newline
        css = css plus ".docs p { margin-bottom: 6px; }" + newline
        css = css plus ".docs code { background: #1a1b26; padding: 1px 4px; border-radius: 3px; font-family: 'Consolas', 'Courier New', monospace; font-size: 13px; color: #e0af68; }" + newline
        css = css plus ".docs .example { background: #1a1b26; border-left: 3px solid #7aa2f7; padding: 8px 12px; margin: 8px 0; font-family: 'Consolas', 'Courier New', monospace; font-size: 12px; color: #c9d1d9; }" + newline
        css = css plus ".docs ul, .docs ol { padding-left: 20px; margin-bottom: 6px; }" + newline
        css = css plus ".docs li { margin-bottom: 2px; }" + newline
        css = css plus "::-webkit-scrollbar { width: 6px; }" + newline
        css = css plus "::-webkit-scrollbar-track { background: #16161e; }" + newline
        css = css plus "::-webkit-scrollbar-thumb { background: #2f3340; border-radius: 3px; }" + newline
        css = css plus "::-webkit-scrollbar-thumb:hover { background: #3f4450; }" + newline
        css = css plus ".badge { display: inline-block; font-size: 10px; padding: 2px 6px; border-radius: 3px; margin-left: 6px; }" + newline
        css = css plus ".badge-line { background: #1f2133; color: #565f89; }" + newline
        css = css plus ".empty-state { text-align: center; padding: 48px; color: #565f89; }" + newline
        css = css plus ".empty-state h3 { color: #7dcfff; margin-bottom: 8px; }" + newline
        css = css plus "pre { font-family: 'Consolas', 'Courier New', monospace; }" + newline
        give back css
    end

    behaviour render doc comment taking doc
        ## Converts a DocComment's text to HTML paragraph elements
        ## Supports inline code markers (`text`) and basic formatting
        let text = doc text
        let result = ""

        ## Escape HTML special characters
        let escaped = ""
        let i = 0
        repeat while i is less than size of text
            let ch = character at i of text
            if ch is "<"
                escaped = escaped plus "&lt;"
            else if ch is ">"
                escaped = escaped plus "&gt;"
            else if ch is "&"
                escaped = escaped plus "&amp;"
            else if ch is "\""
                escaped = escaped plus "&quot;"
            else
                escaped = escaped plus ch
            end
            i = i plus 1
        end

        ## Handle inline code with backticks
        let in_code = false
        let paragraph = ""
        i = 0
        repeat while i is less than size of escaped
            let ch = character at i of escaped
            if ch is "`"
                if in_code
                    paragraph = paragraph plus "</code>"
                    in_code = false
                else
                    paragraph = paragraph plus "<code>"
                    in_code = true
                end
            else
                paragraph = paragraph plus ch
            end
            i = i plus 1
        end
        if in_code
            paragraph = paragraph plus "</code>"
        end

        result = "<p>" plus paragraph plus "</p>"
        give back result
    end

    behaviour sort symbols
        ## Sorts symbols alphabetically by file path (as module), then by name
        ## Uses bubble sort since AK CODE does not have built-in custom sort
        let n = size of symbols
        let i = 0
        repeat while i is less than n
            let j = 0
            repeat while j is less than n minus i minus 1
                let a = item j of symbols
                let b = item j plus 1 of symbols
                let a_key = a file_path plus "/" plus a name
                let b_key = b file_path plus "/" plus b name
                if a_key is greater than b_key
                    set item j of symbols to b
                    set item j plus 1 of symbols to a
                end
                j = j plus 1
            end
            i = i plus 1
        end
    end

    behaviour get module name taking path
        ## Extracts a human-readable module name from a file path
        ## e.g., "akcode/stdlib/core/string.ak" -> "core/string"
        let name = path
        ## Remove .ak extension if present
        if ends with ".ak" in name
            name = slice of name from 0 to size of name minus 3
        end
        give back name
    end

    behaviour group symbols by module
        ## Groups the symbols list into a map keyed by module name
        let grouped = map end
        for each sym in symbols
            let module = self get module name taking sym file_path
            if has key module in grouped is not true
                grouped set module to list of
            end
            let module_list = grouped get module
            add sym to module_list
            grouped set module to module_list
        end
        give back grouped
    end

    behaviour get module names
        ## Returns a sorted list of unique module names from the symbols
        let names = list of
        for each sym in symbols
            let module = self get module name taking sym file_path
            let found = false
            for each existing in names
                if existing is module
                    found = true
                    break
                end
            end
            if found is not true
                add module to names
            end
        end
        ## Sort module names
        let n = size of names
        let i = 0
        repeat while i is less than n
            let j = 0
            repeat while j is less than n minus i minus 1
                let a = item j of names
                let b = item j plus 1 of names
                if a is greater than b
                    set item j of names to b
                    set item j plus 1 of names to a
                end
                j = j plus 1
            end
            i = i plus 1
        end
        give back names
    end

    behaviour get kind class taking kind
        ## Returns the CSS class name for a symbol kind
        if kind is "function"
            give back "kind-function"
        else if kind is "kind"
            give back "kind-kind"
        else if kind is "constant"
            give back "kind-constant"
        else if kind is "behaviour"
            give back "kind-behaviour"
        else if kind is "variable"
            give back "kind-variable"
        end
        give back "kind-function"
    end

    behaviour get kind icon taking kind
        ## Returns an emoji icon for the symbol kind
        if kind is "function"
            give back "fn"
        else if kind is "kind"
            give back "kind"
        else if kind is "constant"
            give back "const"
        else if kind is "behaviour"
            give back "beh"
        else if kind is "variable"
            give back "let"
        end
        give back "?"
    end

    behaviour get sidebar kind class taking kind
        ## Returns the sidebar-specific CSS class for a symbol kind
        if kind is "function"
            give back "kind-func"
        else if kind is "kind"
            give back "kind-kind"
        else if kind is "constant"
            give back "kind-const"
        else if kind is "behaviour"
            give back "kind-behaviour"
        end
        give back "kind-func"
    end

    behaviour generate html for symbol taking sym
        ## Creates the full HTML content for a single symbol's documentation card
        let html = ""
        html = html plus "  <div class=\"symbol-card\">" plus newline
        html = html plus "    <div class=\"card-header\">" plus newline
        html = html plus "      <span class=\"symbol-name\">" plus sym name plus "</span>" plus newline
        html = html plus "      <span class=\"symbol-kind " plus self get kind class taking sym kind plus "\">" plus self get kind icon taking sym kind plus "</span>" plus newline
        html = html plus "    </div>" plus newline
        html = html plus "    <div class=\"card-body\">" plus newline

        ## Signature
        if sym signature is not ""
            html = html plus "      <div class=\"signature\">" plus esc_html sym signature plus "</div>" + newline
        end

        ## Meta info
        html = html plus "      <div class=\"meta\">" + newline
        html = html plus "        <span><span class=\"label\">file:</span> " plus esc_html sym file_path plus "</span>" + newline
        html = html plus "        <span><span class=\"label\">line:</span> " plus sym line as text plus "</span>" + newline
        html = html plus "      </div>" + newline

        ## Doc comments
        if size of sym doc_comments is greater than 0
            html = html plus "      <div class=\"docs\">" + newline
            for each doc in sym doc_comments
                html = html plus "        " plus self render doc comment taking doc plus newline
            end
            html = html plus "      </div>" + newline
        end

        ## Children (sub-symbols like kind behaviours)
        if size of sym children is greater than 0
            html = html plus "      <div class=\"children\">" + newline
            html = html plus "        <h4>Members</h4>" + newline
            for each child in sym children
                html = html plus "        <div class=\"child-card\">" + newline
                html = html plus "          <div class=\"child-name\">" plus child name plus "</div>" + newline
                html = html plus "          <div class=\"child-meta\">" plus child kind plus " | line " plus child line as text plus "</div>" + newline
                if size of child doc_comments is greater than 0
                    html = html plus "          <div class=\"child-docs\">" + newline
                    for each cd in child doc_comments
                        html = html plus "            " plus self render doc comment taking cd plus newline
                    end
                    html = html plus "          </div>" + newline
                end
                html = html plus "        </div>" + newline
            end
            html = html plus "      </div>" + newline
        end

        html = html plus "    </div>" + newline
        html = html plus "  </div>" + newline
        give back html
    end

    behaviour generate index
        ## Creates the main index.html page with sidebar navigation
        let module_names = self get module names
        let grouped = self group symbols by module

        let sidebar_html = ""
        sidebar_html = sidebar_html plus "  <nav class=\"sidebar\">" + newline
        sidebar_html = sidebar_html plus "    <h2>Modules</h2>" + newline
        for each mod_name in module_names
            let mod_slug = replace "/" in mod_name with "-"
            mod_slug = replace "." in mod_slug with "-"
            sidebar_html = sidebar_html plus "    <div class=\"module\">" + newline
            sidebar_html = sidebar_html plus "      <a href=\"" plus mod_slug plus ".html\">" plus esc_html mod_name plus "</a>" + newline

            let mod_symbols = grouped get mod_name
            for each sym in mod_symbols
                sidebar_html = sidebar_html plus "      <a class=\"symbol " plus self get sidebar kind class taking sym kind plus "\" href=\"" plus mod_slug plus ".html#" plus sym name plus "\">" plus esc_html sym name plus "</a>" + newline
            end
            sidebar_html = sidebar_html plus "    </div>" + newline
        end
        sidebar_html = sidebar_html plus "  </nav>" + newline

        let content_html = ""
        content_html = content_html plus "  <div class=\"content\">" + newline
        content_html = content_html plus "    <div class=\"module-header\">" + newline
        content_html = content_html plus "      <h2>AK CODE Documentation</h2>" + newline
        content_html = content_html plus "      <p>Auto-generated from source code " plus size of symbols as text plus " symbols across " plus size of module_names as text plus " modules</p>" + newline
        content_html = content_html plus "    </div>" + newline

        ## Summary stats per module
        for each mod_name in module_names
            let mod_symbols = grouped get mod_name
            content_html = content_html plus "    <h3 style=\"color: #7dcfff; margin-top: 20px; margin-bottom: 8px;\">" plus esc_html mod_name plus " (" plus size of mod_symbols as text plus ")" + "</h3>" + newline
            for each sym in mod_symbols
                content_html = content_html plus self generate html for symbol taking sym
            end
        end

        if size of symbols is 0
            content_html = content_html plus "    <div class=\"empty-state\">" + newline
            content_html = content_html plus "      <h3>No documentation found</h3>" + newline
            content_html = content_html plus "      <p>Run <code>akc docs</code> on a valid AK CODE project to generate documentation.</p>" + newline
            content_html = content_html plus "    </div>" + newline
        end

        content_html = content_html plus "  </div>" + newline

        let title = "AK CODE Documentation"
        let css = self generate css
        let page = "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n"
        page = page plus "  <meta charset=\"UTF-8\">\n"
        page = page plus "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
        page = page plus "  <title>" plus title + "</title>\n"
        page = page plus "  <style>\n" plus css + "\n  </style>\n"
        page = page plus "</head>\n<body>\n"
        page = page plus "  <div class=\"header\">\n"
        page = page plus "    <h1>AK CODE Documentation <span>auto-generated</span></h1>\n"
        page = page plus "  </div>\n"
        page = page plus "  <div class=\"layout\">\n"
        page = page plus sidebar_html
        page = page plus content_html
        page = page plus "  </div>\n"
        page = page plus "</body>\n</html>"
        give back page
    end

    behaviour generate module page taking module_name and module_symbols
        ## Creates an HTML page for a specific module listing all its symbols
        let sidebar_html = ""
        let module_names = self get module names
        let grouped = self group symbols by module

        sidebar_html = sidebar_html plus "  <nav class=\"sidebar\">" + newline
        sidebar_html = sidebar_html plus "    <h2>Modules</h2>" + newline
        for each mod_name in module_names
            let mod_slug = replace "/" in mod_name with "-"
            mod_slug = replace "." in mod_slug with "-"
            let active = ""
            if mod_name is module_name
                active = " style=\"background: #1a1b26; border-left: 2px solid #7aa2f7;\""
            end
            sidebar_html = sidebar_html plus "    <div class=\"module\">" + newline
            sidebar_html = sidebar_html plus "      <a href=\"" plus mod_slug plus ".html\"" plus active plus ">" plus esc_html mod_name plus "</a>" + newline
            for each sym in module_symbols
                sidebar_html = sidebar_html plus "      <a class=\"symbol " plus self get sidebar kind class taking sym kind plus "\" href=\"#" plus sym name + "\">" plus esc_html sym name + "</a>" + newline
            end
            sidebar_html = sidebar_html plus "    </div>" + newline
        end

        sidebar_html = sidebar_html plus "  </nav>" + newline

        let content_html = ""
        content_html = content_html plus "  <div class=\"content\">" + newline
        content_html = content_html plus "    <div class=\"module-header\">" + newline
        content_html = content_html plus "      <h2>" plus esc_html module_name plus "</h2>" + newline
        content_html = content_html plus "      <p>" plus size of module_symbols as text + " documented symbols</p>" + newline
        content_html = content_html plus "    </div>" + newline

        for each sym in module_symbols
            content_html = content_html plus self generate html for symbol taking sym
        end

        content_html = content_html plus "  </div>" + newline

        let title = module_name + " - AK CODE Documentation"
        let css = self generate css
        let page = "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n"
        page = page plus "  <meta charset=\"UTF-8\">\n"
        page = page plus "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
        page = page plus "  <title>" plus title + "</title>\n"
        page = page plus "  <style>\n" plus css + "\n  </style>\n"
        page = page plus "</head>\n<body>\n"
        page = page plus "  <div class=\"header\">\n"
        page = page plus "    <h1><a href=\"index.html\" style=\"color: #bb9af7;\">AK CODE</a> / " plus esc_html module_name + " <span>auto-generated docs</span></h1>\n"
        page = page plus "  </div>\n"
        page = page plus "  <div class=\"layout\">\n"
        page = page plus sidebar_html
        page = page plus content_html
        page = page plus "  </div>\n"
        page = page plus "</body>\n</html>"
        give back page
    end

    behaviour generate html
        ## Produces the complete HTML documentation site:
        ## index.html with sidebar navigation, per-module pages
        self sort symbols

        let module_names = self get module names
        let grouped = self group symbols by module

        ## Generate index.html
        let index_content = self generate index
        let index_output = output_dir plus "/index.html"
        write file index_output with index_content

        ## Generate per-module pages
        for each mod_name in module_names
            let mod_symbols = grouped get mod_name
            let mod_content = self generate module page taking mod_name and mod_symbols
            let mod_slug = replace "/" in mod_name with "-"
            mod_slug = replace "." in mod_slug with "-"
            let mod_output = output_dir plus "/" plus mod_slug plus ".html"
            write file mod_output with mod_content
        end
    end

    behaviour write output
        ## Writes all HTML files to the output directory
        ## This is an alias for generate_html for convenience
        self generate html
    end
end

define esc_html taking text
    ## Escapes HTML special characters in a string
    let result = ""
    let i = 0
    repeat while i is less than size of text
        let ch = character at i of text
        if ch is "<"
            result = result plus "&lt;"
        else if ch is ">"
            result = result plus "&gt;"
        else if ch is "&"
            result = result plus "&amp;"
        else if ch is "\""
            result = result plus "&quot;"
        else
            result = result plus ch
        end
        i = i plus 1
    end
    give back result
end

define ak_docs_generate taking path
    ## Top-level function called by the compiler's `akc docs` command
    ## Creates a DocGenerator, extracts all symbols from the project at path,
    ## and generates the HTML documentation site into a "docs" subdirectory
    let generator = new DocGenerator with path plus "/docs"
    generator extract from project taking path
    generator generate html
    show "Documentation generated at " plus path plus "/docs/index.html"
end
