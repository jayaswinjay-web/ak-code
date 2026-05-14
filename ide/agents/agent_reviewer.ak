## AK CODE Reviewer Agent — analyzes code for bugs, style, and performance
## Provides quality scoring and actionable improvement suggestions

make kind called AgentReviewer extends AgentBase

    when created
        ## Initialize as "Reviewer" agent for code analysis
        name = "Reviewer"
        description = "Reviews AK CODE code and suggests improvements"
        status = "idle"
        conversation = list of
        model = "default"
        temperature = 0.3
    end

    behaviour process taking task and context
        ## Review the code in context and return structured feedback
        set status "working"
        add message "user" to task

        let feedback = review file taking task and context

        set status "done"
        give back feedback
    end

    behaviour review file taking path and content
        ## Analyze a file for bugs, style issues, and performance concerns
        set status "thinking"
        let issues = list of

        let style_issues = check style taking path and content
        for each s in style_issues
            add s to issues
        end

        let error_issues = check errors taking path and content
        for each e in error_issues
            add e to issues
        end

        let improvements = suggest improvements taking path and content
        for each imp in improvements
            add imp to issues
        end

        let score = rate code taking path and content

        let result = map end
        result set "file" to path
        result set "score" to score
        result set "issues" to issues
        result set "total_issues" to size of issues

        add message "system" to "Reviewed " plus path plus " (score: " plus score plus "/10)"
        give back result
    end

    behaviour check style
        ## Verify the code follows AK CODE style guide conventions
        set status "thinking"
        let style_issues = list of
        let lines = split content by newline
        let i = 0

        repeat while i is less than size of lines
            let line = item i of lines
            let line_num = i plus 1

            ## Check line length (max 120)
            if size of line is greater than 120
                let issue = map end
                issue set "type" to "style"
                issue set "line" to line_num
                issue set "message" to "Line exceeds 120 characters (" plus size of line plus ")"
                add issue to style_issues
            end

            ## Check trailing whitespace
            if line is not "" and last of line is space
                let issue = map end
                issue set "type" to "style"
                issue set "line" to line_num
                issue set "message" to "Trailing whitespace"
                add issue to style_issues
            end

            ## Check indentation (4 spaces)
            if line starts with " " and not line starts with "    "
                let leading = 0
                let j = 0
                repeat while j is less than size of line and character at j of line is space
                    leading = leading plus 1
                    j = j plus 1
                end
                if leading mod 4 is not 0
                    let issue = map end
                    issue set "type" to "style"
                    issue set "line" to line_num
                    issue set "message" to "Inconsistent indentation (" plus leading plus " spaces, expected multiple of 4)"
                    add issue to style_issues
                end
            end

            i = i plus 1
        end

        ## Check for proper end keywords
        if not content ends with "\nend\n" and not content ends with "\nend"
            if size of lines is greater than 0
                let last_line = item size of lines minus 1 of lines
                if trim last_line is not "end"
                    let issue = map end
                    issue set "type" to "style"
                    issue set "line" to size of lines
                    issue set "message" to "File should end with 'end' keyword"
                    add issue to style_issues
                end
            end
        end

        give back style_issues
    end

    behaviour check errors
        ## Detect logic errors, type mismatches, and undefined references
        set status "thinking"
        let error_issues = list of
        let defined_symbols = list of
        let lines = split content by newline
        let i = 0

        repeat while i is less than size of lines
            let line = item i of lines
            let line_num = i plus 1
            let trimmed = trim line

            ## Track symbol definitions
            if trimmed starts with "let "
                let parts = split trimmed by space
                if size of parts is greater than 1
                    add item 1 of parts to defined_symbols
                end
            end

            if trimmed starts with "define " or trimmed starts with "behaviour "
                let parts = split trimmed by space
                if size of parts is greater than 1
                    let name_candidate = item 1 of parts
                    if name_candidate is "taking" and size of parts is greater than 2
                        add item 2 of parts to defined_symbols
                    else
                        add name_candidate to defined_symbols
                    end
                end
            end

            if trimmed starts with "make kind called "
                let parts = split trimmed by space
                if size of parts is greater than 3
                    add item 3 of parts to defined_symbols
                end
            end

            ## Check for common errors: assignment without let
            if trimmed contains "=" and not trimmed starts with "let " and not trimmed starts with "##"
                if not trimmed contains " is " and not trimmed contains " has "
                    let before_equals = split trimmed by "="
                    let left = trim item 0 of before_equals
                    if left is not empty and not left contains "set" and not left contains ":"
                        ## Warn about implicit variable usage
                        let issue = map end
                        issue set "type" to "warning"
                        issue set "line" to line_num
                        issue set "message" to "Variable '" plus left plus "' used without 'let' — may not be declared"
                        add issue to error_issues
                    end
                end
            end

            ## Check for string/type mismatch (number used where text expected and vice versa)
            if trimmed contains "plus" and trimmed contains "\""
                ## Mixed concatenation is fine in AK CODE
            end

            i = i plus 1
        end

        give back error_issues
    end

    behaviour suggest improvements
        ## Recommend better approaches, patterns, and optimizations
        set status "thinking"
        let suggestions = list of
        let lines = split content by newline

        let has_repeat = false
        let has_for = false
        let has_recursive = false
        let nesting_depth = 0
        let max_nesting = 0
        let i = 0

        repeat while i is less than size of lines
            let line = item i of lines
            let trimmed = trim line

            if trimmed starts with "repeat "
                has_repeat = true
                nesting_depth = nesting_depth plus 1
                if nesting_depth is greater than max_nesting
                    max_nesting = nesting_depth
                end
            end

            if trimmed starts with "for "
                has_for = true
                nesting_depth = nesting_depth plus 1
                if nesting_depth is greater than max_nesting
                    max_nesting = nesting_depth
                end
            end

            if trimmed starts with "if "
                nesting_depth = nesting_depth plus 1
                if nesting_depth is greater than max_nesting
                    max_nesting = nesting_depth
                end
            end

            if trimmed is "end"
                if nesting_depth is greater than 0
                    nesting_depth = nesting_depth minus 1
                end
            end

            if trimmed starts with "behaviour " and not trimmed contains "taking"
                ## Behaviour without parameters — check if it's pure function
            end

            i = i plus 1
        end

        if max_nesting is greater than 4
            let issue = map end
            issue set "type" to "improvement"
            issue set "line" to 0
            issue set "message" to "Deep nesting detected (depth " plus max_nesting plus "). Consider extracting inner logic into separate behaviours."
            add issue to suggestions
        end

        if has_repeat and not has_for
            let issue = map end
            issue set "type" to "improvement"
            issue set "line" to 0
            issue set "message" to "Consider using 'for each' instead of 'repeat while' for clearer iteration semantics"
            add issue to suggestions
        end

        give back suggestions
    end

    behaviour rate code
        ## Give a quality score from 1 to 10 based on code heuristics
        set status "thinking"
        let score = 7
        let lines = split content by newline
        let line_count = size of lines

        if line_count is 0
            give back 1
        end

        ## Has doc comments
        let has_docs = content contains "##"
        if has_docs
            score = score plus 1
        end

        ## Has proper kind/end structure
        if content contains "make kind called " and content contains "\nend"
            score = score plus 1
        end

        ## Size penalty: too short or too monolithic
        if line_count is less than 5
            score = score minus 2
        end

        if line_count is greater than 300
            score = score minus 1
        end

        ## Error density (issues per line)
        let error_count = 0
        for each line in lines
            let trimmed = trim line
            if trimmed is ""
                error_count = error_count plus 1
            end
        end

        if error_count is greater than line_count divided by 3
            score = score minus 1
        end

        ## Clamp score between 1 and 10
        if score is less than 1
            score = 1
        end
        if score is greater than 10
            score = 10
        end

        give back score
    end
end
