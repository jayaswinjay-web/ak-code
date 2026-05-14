## AK CODE IDE Build System — project compilation and artifact management
## Provides the build orchestrator for AK CODE projects

make kind called BuildSystem
    has project_root of type text
    has build_command of type text
    has output_path of type text
    has build_status of type text
    has errors of type list of map
    has build_history of type list of text

    when created taking root_path
        ## Scan for AK CODE project at root_path, detect project type, set defaults
        project_root = root_path
        errors = list of
        build_history = list of
        build_status = "idle"
        detect project type
        let default_cmd = "akc build " plus project_root
        build_command = default_cmd
        output_path = project_root plus "/build/output.akb"
    end

    behaviour build
        ## Run the AK CODE compiler on the project, capture stdout/stderr
        build_status = "building"
        let start_time = now
        let result = run command and capture build_command
        build_status = "done"
        let elapsed = now minus start_time
        let history_entry = "Build at " plus start_time plus ": " plus build_status plus " (" plus elapsed plus "ms)"
        add history_entry to build_history
        if result is not empty
            show "Build output:" result
        end
        if size of errors is greater than 0
            build_status = "error"
            show "Build completed with" size of errors "error(s)"
        end
    end

    behaviour build file taking file_path
        ## Compile a single AK CODE source file
        let single_cmd = "akc compile " plus file_path
        build_status = "building"
        let result = run command and capture single_cmd
        if result is not empty
            build_status = "error"
            let err_map = map end
            err_map set "file" to file_path
            err_map set "message" to result
            err_map set "line" to "0"
            add err_map to errors
            show "Error compiling" file_path ":" result
        else
            build_status = "done"
            show "Compiled" file_path "successfully"
        end
    end

    behaviour get errors
        ## Return build errors with line numbers as list of maps
        give back errors
    end

    behaviour clear errors
        ## Reset the error list to empty
        errors = list of
        build_status = "idle"
    end

    behaviour get build command
        ## Return the command string used for building
        give back build_command
    end

    behaviour set build command taking cmd
        ## Override the default build command with a custom one
        build_command = cmd
        show "Build command set to:" build_command
    end

    behaviour detect project type
        ## Check the project type: library, executable, web app, or unknown
        let manifest_path = project_root plus "/project.ak"
        let build_ak_path = project_root plus "/build.ak"
        let main_ak_path = project_root plus "/src/main.ak"
        let web_path = project_root plus "/src/web"

        if file exists manifest_path
            let manifest = read file manifest_path
            if manifest contains "type: executable"
                show "Detected project type: executable"
                output_path = project_root plus "/build/app.akb"
            else if manifest contains "type: library"
                show "Detected project type: library"
                output_path = project_root plus "/build/lib.akb"
            else if manifest contains "type: web"
                show "Detected project type: web app"
                output_path = project_root plus "/build/web.akb"
            else
                show "Detected project type: unknown (in manifest)"
                output_path = project_root plus "/build/output.akb"
            end
        else if file exists build_ak_path
            show "Detected project type: custom (build.ak found)"
            output_path = project_root plus "/build/custom.akb"
        else if file exists main_ak_path
            show "Detected project type: executable (src/main.ak found)"
            output_path = project_root plus "/build/app.akb"
        else if file exists web_path
            show "Detected project type: web app (src/web found)"
            output_path = project_root plus "/build/web.akb"
        else
            show "Detected project type: unknown"
            output_path = project_root plus "/build/output.akb"
        end
    end

    behaviour get output path
        ## Return the path to the compiled binary / output artifact
        give back output_path
    end

    behaviour clean
        ## Remove all build artifacts from the build directory
        let build_dir = project_root plus "/build"
        if file exists build_dir
            let entries = list directory build_dir
            for each entry in entries
                if entry is not "."
                    if entry is not ".."
                        let full_path = build_dir plus "/" plus entry
                        delete file full_path
                    end
                end
            end
            show "Cleaned build directory:" build_dir
        end
        build_status = "clean"
        errors = list of
    end

    behaviour rebuild
        ## Clean then build — a full fresh compilation
        clean
        show "Starting rebuild..."
        build
        if build_status is "done"
            show "Rebuild completed successfully"
        else
            show "Rebuild completed with errors"
        end
    end
end
