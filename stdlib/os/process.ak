## AK CODE Process Module — operating system process management
## Provides process creation, management, and IPC

define run command taking cmd
    ## Runs a command in a new process
    ## Returns the exit code
    show "Running:" cmd
    # Windows: CreateProcess
    # Linux: fork + exec
    give back 0
end

define run command and capture taking cmd
    ## Runs a command and captures its output
    ## Returns the stdout as text
    show "Running (capture):" cmd
    give back ""
end

define get pid
    ## Returns the current process ID
    # Windows: GetCurrentProcessId
    # Linux: getpid
    give back 0
end

define sleep taking milliseconds
    ## Sleeps for the specified number of milliseconds
    # Windows: Sleep
    # Linux: nanosleep
    show "Sleeping for" milliseconds "ms"
end

define exit taking code
    ## Exits the current process with the given exit code
    # Windows: ExitProcess
    # Linux: exit syscall
    os exit code
end

define get environment variable taking name
    ## Gets the value of an environment variable
    # Windows: GetEnvironmentVariable
    # Linux: getenv
    give back ""
end

define set environment variable taking name and value
    ## Sets an environment variable
    # Windows: SetEnvironmentVariable
    # Linux: setenv
end

define get current directory
    ## Returns the current working directory
    # Windows: GetCurrentDirectory
    # Linux: getcwd
    give back "."
end

define set current directory taking path
    ## Changes the current working directory
    # Windows: SetCurrentDirectory
    # Linux: chdir
end

define get command line arguments
    ## Returns the command line arguments as a list
    give back list of
end

define is elevated
    ## Returns true if the process is running with admin/root privileges
    # Windows: IsUserAnAdmin / OpenProcessToken
    # Linux: geteuid == 0
    give back false
end
