## Sidebar: Left-side panel providing file explorer, search, git, and
## extension browsing.  Each "mode" swaps the rendered view while keeping
## the sidebar geometry stable.

bring in "akcode/core/file_io.ak"
bring in "akcode/core/os_bindings.ak"
bring in "akcode/core/search.ak"

make kind called Sidebar
  ## Width of the sidebar panel in pixels.
  has width is number

  ## Whether the sidebar is currently shown.
  has visible is bool

  ## Current mode: "files", "search", "git", "extensions".
  has mode is text

  ## Root directory for the file tree (project root).
  has file_tree_root is text

  ## Set of expanded folder paths for the file explorer tree.
  has expanded_folders is list of text

  ## Path of the currently selected (highlighted) item.
  has selected_item is text

  ## Cached list of file entries at the root level (rebuilt on refresh).
  has cached_entries is list of map

  ## Construct a sidebar with the default width and file mode.
  when created
    let width = 250
    let visible = true
    let mode = "files"
    let file_tree_root = os_get_current_directory
    let selected_item = ""
    let expanded_folders = list of text
    let cached_entries = list of map
  end

  ## Show or hide the sidebar (toggle).
  behaviour toggle
    if visible is true
      let visible = false
    end

    if visible is not true
      let visible = true
    end
  end

  ## Switch the sidebar to a different tool mode.
  ##
  ## Valid modes: "files", "search", "git", "extensions".
  ## Invalid modes are silently ignored.
  behaviour set_mode taking mode_name
    if mode_name is "files" or mode_name is "search"
        or mode_name is "git" or mode_name is "extensions"
      let mode = mode_name
      refresh
    end
  end

  ## Draw the file explorer tree at the given screen coordinates.
  ##
  ## Renders a top-down list of the project root, recursing into
  ## expanded folders.  Each item is drawn with an icon (folder/file)
  ## and the selected item is highlighted.
  behaviour render_file_tree_at taking x and y and width
    let line_height = 22
    let current_y = y plus 4

    ## Header: project root name.
    let root_name = os_file_name(file_tree_root)
    os_draw_text_at(x plus 8, current_y, root_name,
                    theme_get_colour("sidebar_header"))
    let current_y = current_y plus line_height plus 4

    os_draw_line(x, current_y, x plus width, current_y,
                 theme_get_colour("sidebar_separator"))
    let current_y = current_y plus 4

    ## Render each top-level entry recursively.
    for each entry in cached_entries
      let entry_path = entry get "path"
      let entry_type = entry get "type"
      let is_dir = entry_type is "directory"

      let expanded = false
      for each f in expanded_folders
        if f is entry_path
          let expanded = true
        end
      end

      let prefix = ""
      if is_dir is true
        if expanded is true
          let prefix = "▼ "
        end
        if expanded is not true
          let prefix = "▶ "
        end
      end

      let label = prefix plus (entry get "name")

      if entry_path is selected_item
        os_fill_rect(x, current_y, width, line_height,
                     theme_get_colour("sidebar_selection"))
      end

      os_draw_text_at(x plus 16, current_y plus 3, label,
                      theme_get_colour("sidebar_fg"))
      let current_y = current_y plus line_height

      ## If expanded, render children inline.
      if is_dir is true and expanded is true
        let children = os_list_directory(entry_path)
        for each child in children
          let child_path = child get "path"
          let child_label = "    " plus (child get "name")

          if child_path is selected_item
            os_fill_rect(x, current_y, width, line_height,
                         theme_get_colour("sidebar_selection"))
          end

          os_draw_text_at(x plus 16, current_y plus 3, child_label,
                          theme_get_colour("sidebar_fg"))
          let current_y = current_y plus line_height
        end
      end
    end
  end

  ## Mark a folder as expanded in the file tree.
  ##
  ## Duplicates are ignored (no-op if already present).
  behaviour expand_folder taking path
    for each f in expanded_folders
      if f is path
        give back  ## Already expanded.
      end
    end

    add path to expanded_folders
  end

  ## Mark a folder as collapsed in the file tree.
  behaviour collapse_folder taking path
    let updated = list of text
    for each f in expanded_folders
      if f is not path
        add f to updated
      end
    end
    let expanded_folders = updated
  end

  ## Set the currently selected (highlighted) item by path.
  behaviour select_item taking path
    let selected_item = path
  end

  ## Return the path of the currently selected item.
  behaviour get_selected_path
    give back selected_item
  end

  ## Create a new file at `parent_path / name` and refresh the tree.
  behaviour create_file taking name and parent_path
    let full = parent_path plus "/" plus name
    let ok = os_create_file(full)
    if ok is true
      refresh
      select_item taking full
    end
    give back ok
  end

  ## Create a new folder at `parent_path / name` and refresh the tree.
  behaviour create_folder taking name and parent_path
    let full = parent_path plus "/" plus name
    let ok = os_create_directory(full)
    if ok is true
      refresh
      select_item taking full
    end
    give back ok
  end

  ## Delete the item at `path` (file or empty directory) and refresh.
  ##
  ## Non-empty directories are not removed; the caller must empty them
  ## first.  give back true on success.
  behaviour delete_item taking path
    let type = os_get_file_type(path)
    let ok = false

    if type is "file"
      let ok = os_delete_file(path)
    end

    if type is "directory"
      let contents = os_list_directory(path)
      if size of contents is 0
        let ok = os_delete_directory(path)
      end

      if size of contents is greater than 0
        show "Cannot delete non-empty directory: " plus path
        let ok = false
      end
    end

    if ok is true
      if selected_item is path
        let selected_item = ""
      end
      refresh
    end

    give back ok
  end

  ## Rename a file or folder from `old_path` to `new_name` in the same
  ## parent directory.  Refreshes the tree on success.
  behaviour rename_item taking old_path and new_name
    let parent = os_parent_directory(old_path)
    let new_path = parent plus "/" plus new_name
    let ok = os_rename(old_path, new_path)
    if ok is true
      if selected_item is old_path
        let selected_item = new_path
      end
      refresh
    end
    give back ok
  end

  ## Re-read the file tree from disk into the cache.
  behaviour refresh
    let cached_entries = os_list_directory(file_tree_root)
  end

  ## Recursively search for `query` under `root_path` and populate
  ## the sidebar with results in a flat list.
  ##
  ## Each result map contains "path", "line", and "column".
  behaviour search_in_files taking query and root_path
    let results = list of map

    let entries = os_list_directory(root_path)

    for each entry in entries
      let entry_path = entry get "path"
      let entry_type = entry get "type"

      if entry_type is "file"
        let matches = search_in_file(entry_path, query)
        for each m in matches
          let result = map
            result set "path" to entry_path
            result set "line" to (m get "line")
            result set "column" to (m get "column")
          end
          add result to results
        end
      end

      if entry_type is "directory"
        let sub_results = search_in_files(query, entry_path)
        for each sr in sub_results
          add sr to results
        end
      end
    end

    give back results
  end
end
