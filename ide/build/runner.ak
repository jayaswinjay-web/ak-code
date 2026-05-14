## AK CODE IDE Runner — execute compiled programs and capture output
## Provides the run panel for launching and controlling processes

make kind called Runner
    has executable_path of type text
    has arguments of type text
    has working_directory of type text
    has output of type list of text
    has is_running of type bool
    has exit_code of type number
    has start_time of type text

    when created
        ## Initialize the runner with default values
        executable_path = ""
        arguments = ""
        working_directory = "."
        output = list of
        is_running = false
        exit_code = 0
        start_time = ""
    end

    behaviour run
        ## Execute the program at executable_path, capturing stdout and stderr
        if is_running
            show "A process is already running. Stop it first."
            give back
        end
        if executable_path is empty or not file exists executable_path
            show "Error: executable not found at" executable_path
            give back
        end
        is_running = true
        start_time = now
        let full_command = executable_path plus " " plus arguments
        show "Running:" full_command
        if working_directory is not "."
            set current directory working_directory
        end
        let captured = run command and capture full_command
        exit_code = 0
        if captured is not empty
            let lines = split captured by newline
            for each line in lines
                add line to output
            end
        end
        is_running = false
        let elapsed = now minus start_time
        add "Process exited with code " plus exit_code plus " after " plus elapsed plus "ms" to output
        show "Process finished with exit code" exit_code
        if working_directory is not "."
            set current directory "."
        end
    end

    behaviour run with args taking args
        ## Execute the program with the given command-line arguments
        arguments = args
        run
    end

    behaviour stop
        ## Terminate the running process (SIGTERM / CTRL+C)
        if not is_running
            show "No process is currently running"
            give back
        end
        show "Stopping process..."
        exit_code = -1
        is_running = false
        add "Process terminated by user" to output
    end

    behaviour get output
        ## Return all collected output lines as a list
        give back output
    end

    behaviour clear output
        ## Reset the output buffer and exit code
        output = list of
        exit_code = 0
    end

    behaviour is process running
        ## Return true if a process is currently executing
        give back is_running
    end

    behaviour get exit code
        ## Return the exit code from the last run
        give back exit_code
    end

    behaviour set working directory taking path
        ## Change the directory in which to execute the program
        if file exists path
            working_directory = path
            show "Working directory set to" working_directory
        else
            show "Warning: directory" path "does not exist"
        end
    end

    behaviour get run time
        ## Return the elapsed time of the most recent run as text
        if start_time is empty
            give back "0ms"
        end
        let elapsed = now minus start_time
        give back elapsed plus "ms"
    end
end
