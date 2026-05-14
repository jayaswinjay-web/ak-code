## AK CODE AI Agent Base — abstract foundation for all AI agents
## Provides conversation history, status tracking, and file I/O capabilities

make kind called AgentBase
    has name of type text
    has description of type text
    has status of type text
    has conversation of type list of map
    has model of type text
    has temperature of type number

    when created taking agent_name and agent_description
        ## Initialize the agent with name, description, and defaults
        name = agent_name
        description = agent_description
        status = "idle"
        conversation = list of
        model = "default"
        temperature = 0.7
    end

    behaviour process taking task and context
        ## Abstract: override in subclasses to handle a task with context
        ## Subclasses should analyze task, use context, and return results
        show name "processing task with context"
        give back empty
    end

    behaviour add message taking role and content
        ## Add a message to the conversation history
        let msg = map end
        msg set "role" to role
        msg set "content" to content
        msg set "timestamp" to now
        add msg to conversation
    end

    behaviour get conversation
        ## Return the full conversation history as a list of maps
        give back conversation
    end

    behaviour clear conversation
        ## Reset the conversation history to empty
        conversation = list of
    end

    behaviour set status taking new_status
        ## Update the agent's current status
        ## Valid statuses: "idle", "thinking", "working", "done", "error"
        status = new_status
    end

    behaviour get status
        ## Return the agent's current status text
        give back status
    end

    behaviour read file taking path
        ## Read and return the contents of a file at the given path
        if not file exists path
            show "Error: file not found -" path
            give back empty
        end
        let content = read file path
        add message "system" to "Read file: " plus path
        give back content
    end

    behaviour write to file taking path and content
        ## Write content to the given file path, creating or overwriting
        let result = write file path with content
        if result
            add message "system" to "Wrote file: " plus path
        else
            show "Error: could not write to" path
        end
        give back result
    end
end
