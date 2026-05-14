## AK CODE Coder Agent — writes AK CODE source files from natural language
## Analyzes requirements, generates code, and writes implementation files

make kind called AgentCoder extends AgentBase
    has output_files of type list of map

    when created
        ## Initialize as "Coder" agent with empty output list
        name = "Coder"
        description = "Writes AK CODE code based on natural language instructions"
        status = "idle"
        conversation = list of
        model = "default"
        temperature = 0.7
        output_files = list of
    end

    behaviour process taking task and context
        ## Analyze a task with context, generate AK CODE code, and write files
        set status "working"
        add message "user" to task
        add message "system" to context

        let requirements = analyze requirements taking task
        show name "analyzed task into" size of requirements "subtasks"

        let lang = "ak"
        let code = generate code taking task and lang

        if code is not empty
            write implementation
        end

        set status "done"
        give back output_files
    end

    behaviour generate code taking specification and language
        ## Produce AK CODE source text based on a specification
        set status "thinking"
        show name "generating" language "code for specification"

        let lines = split specification by newline
        let result = ""
        let indent = ""
        let in_kind = false

        for each line in lines
            let trimmed = trim line
            if trimmed is not empty
                if trimmed starts with "kind: "
                    let kind_name = replace "kind: " in trimmed with ""
                    result = result plus "\nmake kind called " plus kind_name plus "\n"
                    in_kind = true
                    indent = "    "
                else if trimmed starts with "behaviour " and in_kind
                    let beh = replace "behaviour " in trimmed with ""
                    result = result plus indent plus "behaviour " plus beh plus "\n"
                    result = result plus indent plus "    ## TODO: implement " plus beh plus "\n"
                    result = result plus indent plus "end\n"
                else if trimmed starts with "field: "
                    let field_def = replace "field: " in trimmed with ""
                    result = result plus indent plus "has " plus field_def plus "\n"
                else if trimmed is "end kind"
                    result = result plus "end\n"
                    in_kind = false
                    indent = ""
                else
                    result = result plus trimmed plus "\n"
                end
            end
        end

        let code_file = map end
        code_file set "content" to result
        code_file set "language" to language
        add code_file to output_files

        add message "system" to "Generated " plus language plus " code"
        give back result
    end

    behaviour analyze requirements taking task
        ## Break a task description into a list of subtask descriptions
        set status "thinking"
        let subtasks = list of
        let lines = split task by newline

        for each line in lines
            let trimmed = trim line
            if trimmed is not empty
                let lower = lowercase trimmed
                if lower starts with "create " or lower starts with "make " or lower starts with "add "
                    add trimmed to subtasks
                else if lower starts with "implement " or lower starts with "write "
                    add trimmed to subtasks
                else if lower starts with "define " or lower starts with "build "
                    add trimmed to subtasks
                end
            end
        end

        if size of subtasks is 0
            add task to subtasks
        end

        give back subtasks
    end

    behaviour write implementation
        ## Write the generated code files to disk
        set status "working"
        for each file in output_files
            let file_path = file get "path"
            let file_content = file get "content"
            if file_path is not empty and file_content is not empty
                write to file file_path and file_content
                show "Wrote" file_path
            end
        end
    end

    behaviour get relevant context
        ## Read currently open project files for context
        set status "thinking"
        let context = ""
        let project_files = list of
        let src_dir = "./src"

        if file exists src_dir
            project_files = list directory src_dir
            for each f in project_files
                if f ends with ".ak"
                    let full_path = src_dir plus "/" plus f
                    let content = read file full_path
                    context = context plus "=== " plus f plus " ===\n" plus content plus "\n\n"
                end
            end
        end

        add message "system" to "Read " plus size of project_files plus " context files"
        give back context
    end

    behaviour suggest changes taking file_path and issue
        ## Propose code changes to fix a given issue in a file
        set status "thinking"
        let content = read file file_path
        if content is empty
            show "Cannot suggest changes: file empty or not found"
            give back empty
        end

        show name "analyzing issue in" file_path ":" issue
        let suggestion = "## Suggestion for " plus file_path plus "\n"
        suggestion = suggestion plus "## Issue: " plus issue plus "\n"
        suggestion = suggestion plus "## Proposed changes:\n"

        let lines = split content by newline
        let i = 0
        repeat while i is less than size of lines
            let line = item i of lines
            let trimmed = trim line
            if trimmed contains issue or trimmed contains "TODO" or trimmed contains "FIXME"
                suggestion = suggestion plus "--- Line " plus (i plus 1) plus ": " plus trimmed plus "\n"
            end
            i = i plus 1
        end

        add message "system" to "Generated suggestions for " plus file_path
        give back suggestion
    end
end
