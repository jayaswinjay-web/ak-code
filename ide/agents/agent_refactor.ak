## AK CODE Refactor Agent — detects code smells and performs refactoring
## Analyzes complexity, duplication, and applies safe code transformations

make kind called AgentRefactor extends AgentBase

    when created
        ## Initialize as "Refactor" agent for code improvement
        name = "Refactor"
        description = "Refactors AK CODE to be cleaner, more maintainable, and faster"
        status = "idle"
        conversation = list of
        model = "default"
        temperature = 0.3
    end

    behaviour process taking task and context
        ## Analyze code, plan refactoring, and execute the transformation
        set status "working"
        add message "user" to task

        let analysis = analyze code taking task and context

        let suggestions = suggest refactoring taking task and context

        set status "done"
        let result = map end
        result set "analysis" to analysis
        result set "suggestions" to suggestions
        give back result
    end

    behaviour analyze code taking path and content
        ## Scan code for code smells, duplication, and excessive complexity
        set status "thinking"
        let smells = list of
        let lines = split content by newline
        let line_count = size of lines
        let function_bodies = map end
        let current_func = ""
        let func_lines = list of
        let i = 0

        ## Track all function/behaviour bodies for duplication check
        repeat while i is less than line_count
            let line = item i of lines
            let trimmed = trim line

            if trimmed starts with "define " or trimmed starts with "behaviour "
                if current_func is not empty and size of func_lines is greater than 0
                    function_bodies set current_func to func_lines
                end
                let parts = split trimmed by space
                current_func = item 1 of parts
                if current_func is "taking" and size of parts is greater than 2
                    current_func = item 2 of parts
                end
                func_lines = list of
            else if current_func is not empty
                if trimmed is "end"
                    function_bodies set current_func to func_lines
                    current_func = ""
                    func_lines = list of
                else
                    add trimmed to func_lines
                end
            end

            i = i plus 1
        end

        ## Check for long functions
        for each key and body in function_bodies
            if size of body is greater than 30
                let smell = map end
                smell set "type" to "long_function"
                smell set "target" to key
                smell set "detail" to "Function/behaviour has " plus size of body plus " lines (recommended max: 30)"
                add smell to smells
            end
        end

        ## Check for duplicate code across functions
        let func_names = list of
        for each key and body in function_bodies
            add key to func_names
        end

        let a = 0
        repeat while a is less than size of func_names
            let b = a plus 1
            repeat while b is less than size of func_names
                let name_a = item a of func_names
                let name_b = item b of func_names
                let body_a = function_bodies get name_a
                let body_b = function_bodies get name_b

                if size of body_a is size of body_b
                    let match_count = 0
                    let j = 0
                    repeat while j is less than size of body_a
                        if item j of body_a is item j of body_b
                            match_count = match_count plus 1
                        end
                        j = j plus 1
                    end
                    if match_count is greater than size of body_a times 0.7
                        let smell = map end
                        smell set "type" to "duplicate_code"
                        smell set "target" to name_a plus " and " plus name_b
                        smell set "detail" to "Functions share " plus match_count plus " of " plus size of body_a plus " lines"
                        add smell to smells
                    end
                end
                b = b plus 1
            end
            a = a plus 1
        end

        ## Check for commented-out code
        i = 0
        repeat while i is less than line_count
            let line = item i of lines
            let trimmed = trim line
            if trimmed starts with "##" or trimmed starts with "#"
                let content_stripped = replace "## " in trimmed with ""
                content_stripped = replace "# " in content_stripped with ""
                if content_stripped contains "let " or content_stripped contains "if " or content_stripped contains "show " or content_stripped contains "repeat "
                    let smell = map end
                    smell set "type" to "commented_code"
                    smell set "line" to (i plus 1)
                    smell set "detail" to "Commented-out code detected: " plus trimmed
                    add smell to smells
                end
            end
            i = i plus 1
        end

        let complexity = measure complexity of content
        let result = map end
        result set "line_count" to line_count
        result set "function_count" to size of func_names
        result set "complexity" to complexity
        result set "smells" to smells
        result set "smell_count" to size of smells

        add message "system" to "Analysis complete: " plus size of smells plus " code smells found"
        give back result
    end

    behaviour suggest refactoring
        ## Propose specific refactoring actions based on code analysis
        set status "thinking"
        let actions = list of
        let analysis = analyze code taking path and content
        let smells = analysis get "smells"

        for each smell in smells
            let smell_type = smell get "type"
            let target = smell get "target"

            if smell_type is "long_function"
                let action = map end
                action set "priority" to "high"
                action set "action" to "extract_function"
                action set "target" to target
                action set "description" to "Extract " plus target plus " into smaller helper behaviours"
                add action to actions
            end

            if smell_type is "duplicate_code"
                let action = map end
                action set "priority" to "high"
                action set "action" to "extract_common"
                action set "target" to target
                action set "description" to "Extract shared logic between " plus target plus " into a shared behaviour"
                add action to actions
            end

            if smell_type is "commented_code"
                let smell_line = smell get "line"
                let action = map end
                action set "priority" to "low"
                action set "action" to "remove_comment"
                action set "target" to "line " plus smell_line
                action set "description" to "Remove or uncomment dead code at line " plus smell_line
                add action to actions
            end
        end

        let complexity = measure complexity of content
        if complexity is greater than 10
            let action = map end
            action set "priority" to "medium"
            action set "action" to "simplify"
            action set "target" to "entire file"
            action set "description" to "Cyclomatic complexity is " plus complexity plus ". Consider simplifying control flow."
            add action to actions
        end

        if size of actions is 0
            let action = map end
            action set "priority" to "info"
            action set "action" to "no_refactoring_needed"
            action set "target" to path
            action set "description" to "Code looks clean — no refactoring suggested"
            add action to actions
        end

        give back actions
    end

    behaviour rename variable taking old_name and new_name in file
        ## Perform variable rename across an entire file
        set status "working"
        let content = read file file
        if content is empty
            show "Cannot rename: file not found" file
            give back false
        end

        let new_content = replace old_name in content with new_name
        write to file file and new_content

        add message "system" to "Renamed '" + old_name + "' to '" + new_name + "' in " + file
        show "Renamed" old_name "to" new_name "in" file
        give back true
    end

    behaviour extract function taking code_range and new_name
        ## Extract a range of code into a new behaviour function
        set status "working"
        let start_line = code_range get "start"
        let end_line = code_range get "end"
        let file_path = code_range get "file"

        let content = read file file_path
        if content is empty
            give back false
        end

        let lines = split content by newline
        let extracted_lines = list of
        let new_lines = list of
        let i = 0

        repeat while i is less than size of lines
            let line_num = i plus 1
            if line_num is greater than start_line and line_num is less than end_line
                add item i of lines to extracted_lines
            else
                add item i of lines to new_lines
            end
            i = i plus 1
        end

        let extraction = "    behaviour " plus new_name plus "\n"
        for each el in extracted_lines
            extraction = extraction plus "        " plus el plus "\n"
        end
        extraction = extraction plus "    end\n"

        let insert_pos = size of new_lines minus 1
        let final_lines = list of
        i = 0
        repeat while i is less than insert_pos
            add item i of new_lines to final_lines
            i = i plus 1
        end
        add extraction to final_lines
        i = insert_pos
        repeat while i is less than size of new_lines
            add item i of new_lines to final_lines
            i = i plus 1
        end

        let result = join final_lines with "\n"
        write to file file_path and result

        add message "system" to "Extracted function '" + new_name + "' from lines " + start_line + "-" + end_line
        show "Extracted" new_name "from" file_path
        give back true
    end

    behaviour inline function taking function_name
        ## Inline all calls to the given function by replacing with its body
        set status "working"
        let content = read file file
        if content is empty
            give back false
        end

        let lines = split content by newline
        let func_def_lines = list of
        let in_func = false
        let func_body = list of
        let i = 0

        repeat while i is less than size of lines
            let line = item i of lines
            let trimmed = trim line
            if trimmed is "define " plus function_name or trimmed is "behaviour " plus function_name
                in_func = true
            else if in_func
                if trimmed is "end"
                    in_func = false
                else
                    add trimmed to func_body
                end
            end
            i = i plus 1
        end

        if size of func_body is 0
            show "Function" function_name "not found or has empty body"
            give back false
        end

        let new_content = ""
        i = 0
        repeat while i is less than size of lines
            let line = item i of lines
            let trimmed = trim line

            if trimmed contains function_name and (trimmed contains "call " or trimmed contains function_name)
                let indent = ""
                let j = 0
                repeat while j is less than size of line and character at j of line is space
                    indent = indent plus " "
                    j = j plus 1
                end
                for each body_line in func_body
                    new_content = new_content plus indent plus body_line plus "\n"
                end
            else
                if not (trimmed is "define " plus function_name or trimmed is "behaviour " plus function_name or (in_func and trimmed is not "end"))
                    new_content = new_content plus line plus "\n"
                end
            end
            i = i plus 1
        end

        write to file file and new_content
        add message "system" to "Inlined function '" + function_name + "'"
        show "Inlined" function_name "in" file
        give back true
    end

    behaviour simplify expression taking expression
        ## Simplify a complex expression to a more readable form
        set status "thinking"
        let simplified = expression

        ## Pattern: x plus 0 -> x
        if expression ends with " plus 0"
            simplified = replace " plus 0" in expression with ""
        end

        ## Pattern: x times 1 -> x
        if expression ends with " times 1"
            simplified = replace " times 1" in expression with ""
        end

        ## Pattern: x divided by 1 -> x
        if expression ends with " divided by 1"
            simplified = replace " divided by 1" in expression with ""
        end

        ## Pattern: x times 0 -> 0
        if expression ends with " times 0"
            simplified = "0"
        end

        ## Pattern: not not x -> x
        if expression starts with "not not "
            simplified = replace "not not " in expression with ""
        end

        ## Pattern: x plus x -> 2 times x
        if size of expression is greater than 2
            let parts = split expression by " plus "
            if size of parts is 2
                let left = trim item 0 of parts
                let right = trim item 1 of parts
                if left is right
                    simplified = "2 times " plus left
                end
            end
        end

        if simplified is not expression
            show "Simplified: " plus expression plus " -> " plus simplified
        end

        give back simplified
    end

    behaviour measure complexity of content
        ## Calculate cyclomatic complexity based on control flow keywords
        set status "thinking"
        let complexity = 1
        let lines = split content by newline

        for each line in lines
            let trimmed = trim line

            ## Each conditional branch adds 1
            if trimmed starts with "if "
                complexity = complexity plus 1
            end
            if trimmed is "else" or trimmed starts with "else if "
                complexity = complexity plus 1
            end
            if trimmed starts with "else if "
                complexity = complexity plus 1
            end

            ## Each loop adds 1
            if trimmed starts with "repeat "
                complexity = complexity plus 1
            end
            if trimmed starts with "for "
                complexity = complexity plus 1
            end

            ## Each case/pattern adds 1
            if trimmed starts with "when "
                complexity = complexity plus 1
            end
            if trimmed starts with "catch "
                complexity = complexity plus 1
            end

            ## Boolean operators add complexity
            if trimmed contains " and " or trimmed contains " or "
                complexity = complexity plus 1
            end
        end

        give back complexity
    end
end
