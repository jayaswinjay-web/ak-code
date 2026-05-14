## AgentsPanel: Right-side panel for interacting with AI coding agents.
##
## Supports multiple registered agents (e.g. chat, edit, architect),
## a conversation-style message history, input box, and orchestration
## mode where all agents collaborate on a single task.  Modeled after
## Cursor's Composer / Agent panels.

bring in "akcode/core/os_bindings.ak"
bring in "akcode/core/llm_client.ak"

## AgentBase: Abstract representation of an AI agent.
##
## Concrete agent kinds (ChatAgent, EditAgent, ArchitectAgent) would
## extend this with their own behaviour implementations.  Agents_panel
## holds a list of these and delegates to the active one.

make kind called AgentBase
  ## Human-readable name shown in the agent selector.
  has name is text

  ## Short description of what this agent does.
  has description is text

  ## Unique identifier for routing messages.
  has id is text

  ## Current status: "idle", "running", "done", "error".
  has status is text

  ## Construct a new agent base record.
  when created taking agent_name and agent_id and agent_description
    let name = agent_name
    let id = agent_id
    let description = agent_description
    let status = "idle"
  end

  ## Execute a prompt against this agent's underlying model.
  ##
  ## Returns the response text (or an error message on failure).
  behaviour execute taking prompt and context
    give back "[AgentBase.execute] not implemented – override in subkind"
  end

  ## Cancel the current execution if running.
  behaviour cancel
    let status = "idle"
  end
end

## AgentsPanel: Panel managing multiple agents and their conversation.
make kind called AgentsPanel
  ## Whether the panel is visible.
  has visible is bool

  ## Panel width in pixels.
  has width is number

  ## List of registered agent instances.
  has agents is list of AgentBase

  ## Index into `agents` indicating the currently selected agent.
  has active_agent_index is number

  ## Ordered conversation history.  Each entry is a map with keys:
  ##   "sender"   (text) – agent id or "user"
  ##   "text"     (text) – the message body
  ##   "timestamp" (number) – epoch ms
  has conversation is list of map

  ## The text currently typed in the input box.
  has input_text is text

  ## Cursor position within input_text for inline editing.
  has input_cursor is number

  ## True while an agent request is in-flight.
  has is_processing is bool

  ## Construct a default agents panel: hidden, 350px wide, two starter
  ## agents registered.
  when created
    let visible = false
    let width = 350
    let input_text = ""
    let input_cursor = 0
    let is_processing = false
    let active_agent_index = 0

    let conversation = list of map
    let agents = list of AgentBase

    ## Register default agents.
    let chat = AgentBase created taking "Chat Agent" and "chat" and "Conversational assistant"
    add chat to agents

    let edit = AgentBase created taking "Edit Agent" and "edit" and "Code editing & refactoring"
    add edit to agents

    let arch = AgentBase created taking "Architect Agent" and "architect" and "Design & planning"
    add arch to agents
  end

  ## Show or hide the agents panel.
  behaviour toggle
    if visible is true
      let visible = false
    end

    if visible is not true
      let visible = true
    end
  end

  ## Register a new agent into the panel.
  ##
  ## The agent is appended after the existing agents.  If it is the
  ## first agent, it becomes active immediately.
  behaviour add_agent taking agent
    add agent to agents
    if size of agents is 1
      let active_agent_index = 0
    end
  end

  ## Switch the active agent to the one at `index`.
  behaviour set_active_agent_at taking index
    if index is less than 0 or index is greater than (size of agents minus 1)
      give back
    end
    let active_agent_index = index
    display_message taking "system" and ("Switched to " plus (agents get index) get name) and os_epoch_ms
  end

  ## Send the current input text to the active agent and record the
  ## response in the conversation history.
  ##
  ## While processing, the input is cleared and the panel enters a
  ## busy state.  The agent's `execute` method is called with the
  ## full conversation context for continuity.
  behaviour send_message taking text
    if is_processing is true
      show "AgentsPanel: already processing a request – ignoring"
      give back
    end

    if text is "" or text is "\n"
      give back
    end

    let now = os_epoch_ms

    display_message taking "user" and text and now

    let active_agent = agents get active_agent_index
    if active_agent is 0
      display_message taking "system" and "ERROR: no active agent selected" and os_epoch_ms
      give back
    end

    let is_processing = true
    active_agent status = "running"
    show_agent_status

    ## Build a context string from the recent conversation history.
    let context = ""
    for each msg in conversation
      let sender = msg get "sender"
      let body = msg get "text"
      let context = context plus sender plus ": " plus body plus "\n"
    end

    let response = active_agent execute taking text and context

    let is_processing = false
    active_agent status = "done"
    show_agent_status

    display_message taking (active_agent id) and response and os_epoch_ms
  end

  ## Add a message to the conversation display and store it.
  ##
  ## `sender` is either a user identifier or an agent id.
  behaviour display_message taking sender and text and timestamp
    let entry = map
    entry set "sender" to sender
    entry set "text" to text
    entry set "timestamp" to timestamp
    add entry to conversation

    ## Cap conversation at 500 messages for memory.
    if size of conversation is greater than 500
      let trimmed = list of map
      let i = size of conversation minus 500
      repeat while i is less than size of conversation
        add (conversation get i) to trimmed
        let i = i plus 1
      end
      let conversation = trimmed
    end

    render_conversation
  end

  ## Draw the chat-like conversation history in the panel.
  ##
  ## Each message is rendered as a bubble: user messages right-aligned
  ## in one colour, agent messages left-aligned in another.  System
  ## messages (switches, errors) are centred and muted.
  behaviour render_conversation
    let panel_x = 0  ## relative to the panel's own coordinate space
    let panel_y = 0
    let bubble_margin = 8
    let line_height = 20
    let current_y = panel_y plus 8

    let bg = theme_get_colour("agents_bg")
    let user_bubble = theme_get_colour("agents_user_bubble")
    let agent_bubble = theme_get_colour("agents_agent_bubble")
    let system_col = theme_get_colour("agents_system")
    let text_fg = theme_get_colour("agents_text")

    os_fill_rect(panel_x, panel_y, width, 10000, bg)  ## clear entire panel

    for each msg in conversation
      let sender = msg get "sender"
      let body = msg get "text"
      let is_user = sender is "user"
      let is_system = sender is "system"

      ## Wrap long messages to fit the panel width.
      let max_text_w = width minus (bubble_margin times 4)
      let lines = wrap_text(body, max_text_w)

      let bubble_h = (size of lines times line_height) plus 12

      if is_system is true
        ## System messages are drawn centred in muted colour.
        os_draw_text_centred(panel_x plus (width divided by 2),
                             current_y plus 4, body, system_col)
        let current_y = current_y plus line_height plus 4
      end

      if is_system is not true
        if is_user is true
          let bx = width minus max_text_w minus bubble_margin
          os_fill_rounded_rect(bx, current_y,
                               max_text_w plus (bubble_margin times 2),
                               bubble_h, 4, user_bubble)

          let text_x = bx plus bubble_margin
          let line_y = current_y plus 6
          for each line in lines
            os_draw_text_at(text_x, line_y, line, text_fg)
            let line_y = line_y plus line_height
          end
        end

        if is_user is not true
          let bx = bubble_margin
          os_fill_rounded_rect(bx, current_y,
                               max_text_w plus (bubble_margin times 2),
                               bubble_h, 4, agent_bubble)

          let text_x = bx plus bubble_margin
          let line_y = current_y plus 6
          for each line in lines
            ## Prefix with agent name in bold colour.
            let prefix = sender plus ": "
            os_draw_text_at(text_x, line_y, prefix, theme_get_colour("agents_name"))
            os_draw_text_at(text_x plus os_text_width(prefix), line_y, line, text_fg)
            let line_y = line_y plus line_height
          end
        end

        let current_y = current_y plus bubble_h plus 4
      end
    end

    ## Draw input box at the bottom of the panel.
    let input_y = 10000 minus 36  ## placeholder – real Y from layout
    os_fill_rect(panel_x plus 4, input_y, width minus 8, 32,
                 theme_get_colour("agents_input_bg"))
    os_draw_text_at(panel_x plus 10, input_y plus 6, input_text, text_fg)
  end

  ## Run all registered agents on the same task, collecting each
  ## response into the conversation.
  ##
  ## Agents run sequentially; each sees the previous agent's output
  ## as additional context.
  behaviour orchestrate taking task
    if is_processing is true
      show "AgentsPanel: already processing – ignoring orchestrate"
      give back
    end

    display_message taking "system" and "=== Orchestration: " plus task plus " ===" and os_epoch_ms

    let accumulated_context = task
    let i = 0

    for each agent in agents
      agent status = "running"
      show_agent_status

      let response = agent execute taking accumulated_context and ""
      display_message taking (agent id) and response and os_epoch_ms

      agent status = "done"
      show_agent_status

      let accumulated_context = accumulated_context plus "\n" plus (agent id) plus ": " plus response
      let i = i plus 1
    end

    display_message taking "system" and "=== Orchestration complete ===" and os_epoch_ms
  end

  ## Render a small status indicator for each agent (running/idle/done).
  ##
  ## Displayed near the top of the panel as coloured dots or labels.
  behaviour show_agent_status
    let x = 8
    let y = 4
    let dot_size = 8
    let gap = 16

    for each agent in agents
      let colour = theme_get_colour("agents_idle_dot")
      if agent status is "running"
        let colour = theme_get_colour("agents_running_dot")
      end
      if agent status is "done"
        let colour = theme_get_colour("agents_done_dot")
      end
      if agent status is "error"
        let colour = theme_get_colour("agents_error_dot")
      end

      os_fill_circle(x plus (dot_size divided by 2),
                     y plus (dot_size divided by 2),
                     dot_size divided by 2, colour)
      os_draw_text_at(x plus dot_size plus 4, y, agent name,
                      theme_get_colour("agents_fg"))
      let x = x plus gap plus os_text_width(agent name)
    end
  end

  ## Reset the conversation history and input text.
  behaviour clear_conversation
    let conversation = list of map
    let input_text = ""
    let input_cursor = 0
  end

  ## Handle a key event in the input box.
  ##
  ## Enter sends the message; Backspace deletes the previous character;
  ## Left/Right move the cursor; other printable chars are inserted.
  behaviour handle_input_key taking key_code
    ## Enter.
    if key_code is 13
      send_message taking input_text
      let input_text = ""
      let input_cursor = 0
      give back
    end

    ## Backspace.
    if key_code is 8
      if input_cursor is greater than 0
        let before = input_text slice 0 to (input_cursor minus 1)
        let after = input_text slice input_cursor to (size of input_text)
        let input_text = before plus after
        let input_cursor = input_cursor minus 1
      end
      give back
    end

    ## Left arrow.
    if key_code is 37
      if input_cursor is greater than 0
        let input_cursor = input_cursor minus 1
      end
      give back
    end

    ## Right arrow.
    if key_code is 39
      if input_cursor is less than (size of input_text)
        let input_cursor = input_cursor plus 1
      end
      give back
    end

    ## Home.
    if key_code is 36
      let input_cursor = 0
      give back
    end

    ## End.
    if key_code is 35
      let input_cursor = size of input_text
      give back
    end

    ## Printable characters.
    if key_code is greater than 31 and key_code is not 127
      let ch = os_code_point_to_string(key_code)
      let before = input_text slice 0 to input_cursor
      let after = input_text slice input_cursor to (size of input_text)
      let input_text = before plus ch plus after
      let input_cursor = input_cursor plus 1
    end
  end
end
