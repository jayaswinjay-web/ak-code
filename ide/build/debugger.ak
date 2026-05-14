## AK CODE IDE Debugger — source-level breakpoint debugging
## Provides breakpoints, call stack inspection, and step-through execution

make kind called Debugger
    has breakpoints of type list of map
    has call_stack of type list of text
    has variables of type list of map
    has is_paused of type bool
    has current_file of type text
    has current_line of type number

    when created
        ## Initialize the debugger with an empty state
        breakpoints = list of
        call_stack = list of
        variables = list of
        is_paused = false
        current_file = ""
        current_line = 0
    end

    behaviour set breakpoint at taking file_path and line_number
        ## Add a breakpoint at the given file and line
        let bp = map end
        bp set "file" to file_path
        bp set "line" to line_number
        bp set "enabled" to true
        add bp to breakpoints
        show "Breakpoint set at" file_path ":" line_number
    end

    behaviour remove breakpoint at taking file_path and line_number
        ## Remove the breakpoint at the given file and line
        let new_breakpoints = list of
        for each bp in breakpoints
            let bp_file = bp get "file"
            let bp_line = bp get "line"
            if bp_file is not file_path or bp_line is not line_number
                add bp to new_breakpoints
            end
        end
        breakpoints = new_breakpoints
        show "Breakpoint removed at" file_path ":" line_number
    end

    behaviour toggle breakpoint at taking file_path and line_number
        ## Add the breakpoint if absent, remove it if present
        let found = false
        for each bp in breakpoints
            let bp_file = bp get "file"
            let bp_line = bp get "line"
            if bp_file is file_path and bp_line is line_number
                found = true
            end
        end
        if found
            remove breakpoint at file_path and line_number
        else
            set breakpoint at file_path and line_number
        end
    end

    behaviour get breakpoints
        ## Return all breakpoints as a list of maps
        give back breakpoints
    end

    behaviour step over
        ## Execute the next line, staying within the current function
        if not is_paused
            show "Debugger is not paused. Start debugging first."
            give back
        end
        show "Step over: advancing to next line in" current_file
        current_line = current_line plus 1
        update variables from current context
    end

    behaviour step into
        ## Execute the next line, entering a function if the line is a call
        if not is_paused
            show "Debugger is not paused. Start debugging first."
            give back
        end
        show "Step into: entering function at" current_file ":" current_line
        let frame = current_file plus ":" plus current_line
        add frame to call_stack
        current_line = current_line plus 1
        update variables from current context
    end

    behaviour step out
        ## Complete the current function and return to the caller
        if not is_paused
            show "Debugger is not paused. Start debugging first."
            give back
        end
        if size of call_stack is 0
            show "No caller to return to"
            give back
        end
        let caller = last of call_stack
        let parts = split caller by ":"
        if size of parts is greater than 1
            current_file = item 0 of parts
            let line_str = item 1 of parts
            current_line = line_str as number
        end
        remove last item from call_stack
        update variables from current context
        show "Step out: returned to" current_file ":" current_line
    end

    behaviour continue
        ## Resume execution until the next breakpoint is hit
        if not is_paused
            show "Debugger is not paused. Start debugging first."
            give back
        end
        is_paused = false
        show "Continuing execution..."
        let hit = false
        let hit_file = ""
        let hit_line = 0
        repeat while not hit
            current_line = current_line plus 1
            for each bp in breakpoints
                let bp_enabled = bp get "enabled"
                if bp_enabled
                    let bp_file = bp get "file"
                    let bp_line = bp get "line"
                    if bp_file is current_file and bp_line is current_line
                        hit = true
                        hit_file = bp_file
                        hit_line = bp_line
                    end
                end
            end
        end
        if hit
            is_paused = true
            show "Breakpoint hit at" hit_file ":" hit_line
        else
            show "Execution completed (no more breakpoints)"
        end
    end

    behaviour get call stack
        ## Return the current call stack trace as a list of text
        give back call_stack
    end

    behaviour get variables
        ## Return local variables and their values as a list of maps
        give back variables
    end

    behaviour evaluate taking expression
        ## Evaluate an expression in the current debugging context
        if not is_paused
            show "Debugger is not paused. Cannot evaluate."
            give back empty
        end
        show "Evaluating:" expression
        let result = expression
        give back result
    end

    behaviour start debugging taking executable
        ## Launch the given executable under the debugger
        show "Starting debugger for:" executable
        is_paused = false
        current_file = executable
        current_line = 0
        call_stack = list of
        variables = list of
        let first_bp = true
        for each bp in breakpoints
            let bp_enabled = bp get "enabled"
            if bp_enabled and first_bp
                current_file = bp get "file"
                current_line = bp get "line"
                is_paused = true
                first_bp = false
                show "Paused at initial breakpoint" current_file ":" current_line
            end
        end
        if not is_paused
            is_paused = true
            current_line = 1
            show "Debugger started. Paused at" current_file ":" current_line
        end
    end

    behaviour stop debugging
        ## Terminate the debug session and reset state
        show "Stopping debug session..."
        is_paused = false
        current_file = ""
        current_line = 0
        call_stack = list of
        variables = list of
    end
end
