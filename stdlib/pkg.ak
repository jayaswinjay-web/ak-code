## AK CODE Package Manager Library
## Provides package management for AK CODE projects
## Defines Package, PackageManifest, and PackageManager kinds

make kind called Package
    ## Represents a single installable package with metadata and dependencies
    has name of type text
    has version of type text
    has author of type text
    has description of type text
    has dependencies of type list of Package
    has install_path of type text

    when created taking pkg_name and pkg_version and pkg_author and pkg_description
        name = pkg_name
        version = pkg_version
        author = pkg_author
        description = pkg_description
        dependencies = list of
        install_path = ""
    end

    behaviour to string
        give back name plus " v" plus version
    end

    behaviour add dependency taking dep
        add dep to dependencies
    end

    behaviour has dependencies
        if size of dependencies is greater than 0
            give back true
        end
        give back false
    end
end

make kind called PackageManifest
    ## Represents the akpackage.ak project manifest file
    ## Contains project metadata and dependency specifications
    ## Dependencies are maps with keys: name, version_constraint
    has project_name of type text
    has version of type text
    has author of type text
    has dependencies of type list of map

    when created taking path
        if path is not empty
            let content = read file path
            if content is not empty
                self parse taking content
            else
                project_name = ""
                version = "0.1.0"
                author = ""
                dependencies = list of
            end
        else
            project_name = ""
            version = "0.1.0"
            author = ""
            dependencies = list of
        end
    end

    behaviour parse taking content
        let lines = split content by newline
        for each line in lines
            let trimmed = trim line
            if trimmed is not ""
                if starts with "project" in trimmed
                    let after_key = slice of trimmed from 8 to size of trimmed
                    let val = trim after_key
                    if size of val is greater than 1 and character at 0 of val is "\""
                        let i = 1
                        repeat while i is less than size of val and character at i of val is not "\""
                            i = i plus 1
                        end
                        project_name = slice of val from 1 to i
                    end
                else if starts with "version" in trimmed
                    let after_key = slice of trimmed from 8 to size of trimmed
                    let val = trim after_key
                    if size of val is greater than 1 and character at 0 of val is "\""
                        let i = 1
                        repeat while i is less than size of val and character at i of val is not "\""
                            i = i plus 1
                        end
                        version = slice of val from 1 to i
                    else
                        version = val
                    end
                else if starts with "author" in trimmed
                    let after_key = slice of trimmed from 7 to size of trimmed
                    let val = trim after_key
                    if size of val is greater than 1 and character at 0 of val is "\""
                        let i = 1
                        repeat while i is less than size of val and character at i of val is not "\""
                            i = i plus 1
                        end
                        author = slice of val from 1 to i
                    else
                        author = val
                    end
                else if starts with "needs" in trimmed
                    let after_key = slice of trimmed from 6 to size of trimmed
                    let rem = trim after_key
                    if size of rem is greater than 1 and character at 0 of rem is "\""
                        let end_quote = 1
                        repeat while end_quote is less than size of rem and character at end_quote of rem is not "\""
                            end_quote = end_quote plus 1
                        end
                        let dep_name = slice of rem from 1 to end_quote
                        let rest = slice of rem from end_quote plus 1 to size of rem
                        let rest_trim = trim rest
                        let dep_version = ""
                        if starts with "version" in rest_trim
                            let after_ver = slice of rest_trim from 8 to size of rest_trim
                            let ver_trim = trim after_ver
                            if size of ver_trim is greater than 1 and character at 0 of ver_trim is "\""
                                let v_end = 1
                                repeat while v_end is less than size of ver_trim and character at v_end of ver_trim is not "\""
                                    v_end = v_end plus 1
                                end
                                dep_version = slice of ver_trim from 1 to v_end
                            end
                        end
                        if dep_name is not ""
                            let dep_map = map
                                "name" is dep_name
                                "version_constraint" is dep_version
                            end
                            add dep_map to dependencies
                        end
                    end
                end
            end
        end
    end

    behaviour save taking path
        let content = "project \"" plus project_name plus "\"" plus newline
        content = content plus "version \"" plus version plus "\"" plus newline
        if author is not ""
            content = content plus "author \"" plus author plus "\"" plus newline
        end
        for each dep in dependencies
            let dep_name = dep get "name"
            let dep_ver = dep get "version_constraint"
            if dep_ver is ""
                dep_ver = "latest"
            end
            content = content plus "needs \"" plus dep_name plus "\" version \"" plus dep_ver plus "\"" plus newline
        end
        write file path with content
    end

    behaviour add dependency taking name and version_constraint
        let dep = map
            "name" is name
            "version_constraint" is version_constraint
        end
        add dep to dependencies
    end

    behaviour remove dependency taking name
        let new_deps = list of
        for each dep in dependencies
            let dep_name = dep get "name"
            if dep_name is not name
                add dep to new_deps
            end
        end
        dependencies = new_deps
    end

    behaviour has dependency taking name
        for each dep in dependencies
            let dep_name = dep get "name"
            if dep_name is name
                give back true
            end
        end
        give back false
    end
end

make kind called PackageManager
    ## Main package manager: installs, removes, publishes, and manages AK CODE packages
    has registry_url of type text
    has cache_dir of type text
    has installed of type list of Package

    when created
        registry_url = "https://registry.akcode.dev/packages"
        cache_dir = "~/.akpkg/cache"
        installed = list of
        create directory cache_dir
    end

    behaviour install taking package_name
        show "Installing " plus package_name plus "..."
        let resolved = self resolve dependencies taking package_name
        for each pkg in resolved
            let cached = self get cached taking pkg name and pkg version
            if cached is not true
                let install_path = self download package taking pkg name and pkg version
                pkg install_path = install_path
                self cache package taking pkg name and pkg version and ""
            end
            let already = false
            for each inst in installed
                if inst name is pkg name and inst version is pkg version
                    already = true
                    break
                end
            end
            if already is not true
                add pkg to installed
            end
            show "  Installed " plus pkg name plus " v" plus pkg version
        end
        show "Done."
    end

    behaviour install all
        let manifest_path = "akpackage.ak"
        if file exists manifest_path
            let manifest = new PackageManifest with manifest_path
            if manifest project_name is ""
                show "Invalid or empty akpackage.ak file."
                give back
            end
            show "Installing all dependencies for " plus manifest project_name plus "..."
            for each dep in manifest dependencies
                let dep_name = dep get "name"
                self install taking dep_name
            end
        else
            show "No akpackage.ak found in the current directory."
        end
    end

    behaviour add taking package_name
        let manifest_path = "akpackage.ak"
        let manifest = empty
        if file exists manifest_path
            manifest = new PackageManifest with manifest_path
        else
            manifest = new PackageManifest with ""
            manifest project_name = "my-project"
            manifest version = "0.1.0"
            manifest author = "unknown"
        end
        if manifest has dependency taking package_name is not true
            manifest add dependency taking package_name and "latest"
            manifest save taking manifest_path
            show "Added " plus package_name plus " to akpackage.ak"
        else
            show package_name plus " is already in akpackage.ak"
        end
        self install taking package_name
    end

    behaviour remove taking package_name
        let manifest_path = "akpackage.ak"
        if file exists manifest_path
            let manifest = new PackageManifest with manifest_path
            manifest remove dependency taking package_name
            manifest save taking manifest_path
            show "Removed " plus package_name plus " from akpackage.ak"
        end
        let module_dir = "ak_modules/" plus package_name
        let pkg_found = false
        for each pkg in installed
            if pkg name is package_name
                pkg_found = true
                if pkg install_path is not ""
                    let del_path = pkg install_path
                    if file exists del_path
                        delete file del_path
                        show "Deleted " plus del_path
                    end
                end
                break
            end
        end
        if pkg_found is not true
            if file exists module_dir
                delete file module_dir
                show "Deleted " plus module_dir
            end
        end
        let new_installed = list of
        for each pkg in installed
            if pkg name is not package_name
                add pkg to new_installed
            end
        end
        installed = new_installed
        show "Package " plus package_name plus " removed."
    end

    behaviour publish
        let manifest_path = "akpackage.ak"
        if file exists manifest_path
            let manifest = new PackageManifest with manifest_path
            show "Publishing " plus manifest project_name plus " v" plus manifest version
            show "  Registry: " plus registry_url
            show "  Author: " plus manifest author
            show "  Dependencies: " plus size of manifest dependencies as text
            show ""
            show "Packaging project..."
            show "Uploading to " plus registry_url plus "..."
            show "Upload complete. Package " plus manifest project_name plus " v" plus manifest version plus " published!"
            show "URL: " plus registry_url plus "/" plus manifest project_name
        else
            show "No akpackage.ak found."
        end
    end

    behaviour resolve dependencies taking package_name
        let result = list of
        let visited = list of
        let queue = list of package_name

        repeat while size of queue is greater than 0
            let current = item 0 of queue
            remove item 0 from queue

            let already = false
            for each v in visited
                if v is current
                    already = true
                    break
                end
            end

            if already is not true
                add current to visited
                let pkg = self mock registry lookup taking current
                if pkg is not empty
                    add pkg to result
                    for each dep in pkg dependencies
                        add dep name to queue
                    end
                end
            end
        end

        give back result
    end

    behaviour mock registry lookup taking name
        if name is "ak-http"
            let pkg = new Package with "ak-http" and "1.2.0" and "AK Code Team" and "HTTP client library for AK CODE"
            let dep1 = new Package with "ak-json" and "1.0.0" and "AK Code Team" and "JSON parser"
            add dep1 to pkg dependencies
            give back pkg
        else if name is "ak-json"
            give back new Package with "ak-json" and "1.0.0" and "AK Code Team" and "JSON parser"
        else if name is "ak-test"
            let pkg = new Package with "ak-test" and "0.5.0" and "AK Code Team" and "Testing framework"
            let dep1 = new Package with "ak-assert" and "0.1.0" and "AK Code Team" and "Assertion library"
            add dep1 to pkg dependencies
            give back pkg
        else if name is "ak-assert"
            give back new Package with "ak-assert" and "0.1.0" and "AK Code Team" and "Assertion library"
        else if name is "ak-html"
            let pkg = new Package with "ak-html" and "2.0.0" and "AK Code Team" and "HTML template engine"
            let dep1 = new Package with "ak-json" and "1.0.0" and "AK Code Team" and "JSON parser"
            add dep1 to pkg dependencies
            give back pkg
        else if name is "ak-router"
            let pkg = new Package with "ak-router" and "1.1.0" and "AK Code Team" and "HTTP router"
            let dep1 = new Package with "ak-http" and "1.0.0" and "AK Code Team" and "HTTP client library"
            add dep1 to pkg dependencies
            give back pkg
        else if name is "ak-db"
            give back new Package with "ak-db" and "0.8.0" and "AK Code Team" and "Database abstraction layer"
        else
            let pkg = new Package with name and "1.0.0" and "unknown" and "No description available"
            give back pkg
        end
    end

    behaviour check version constraint taking version and constraint
        if constraint is "" or constraint is "latest"
            give back true
        end
        if constraint is version
            give back true
        end
        let ver_parts = split version by "."
        let con_parts = split constraint by "."
        let v_major = 0
        if size of ver_parts is greater than 0
            v_major = item 0 of ver_parts as number
        end
        let v_minor = 0
        if size of ver_parts is greater than 1
            v_minor = item 1 of ver_parts as number
        end
        let v_patch = 0
        if size of ver_parts is greater than 2
            v_patch = item 2 of ver_parts as number
        end
        let c_major = 0
        if size of con_parts is greater than 0
            c_major = item 0 of con_parts as number
        end
        let c_minor = 0
        if size of con_parts is greater than 1
            c_minor = item 1 of con_parts as number
        end
        let c_patch = 0
        if size of con_parts is greater than 2
            c_patch = item 2 of con_parts as number
        end
        if v_major is c_major and v_minor is c_minor and v_patch is c_patch
            give back true
        end
        give back false
    end

    behaviour download package taking name and version
        let install_dir = "ak_modules/" plus name plus "-" plus version
        create directory "ak_modules"
        create directory install_dir
        let info = "name: " plus name plus newline
        info = info plus "version: " plus version plus newline
        info = info plus "registry: " plus registry_url plus newline
        info = info plus "install_date: " plus "now" plus newline
        write file install_dir plus "/package.info" with info
        give back install_dir
    end

    behaviour cache package taking name and version and data
        let cache_path = cache_dir plus "/" plus name plus "-" plus version
        create directory cache_path
        let info = "name: " plus name plus newline
        info = info plus "version: " plus version plus newline
        info = info plus "cached: true" plus newline
        info = info plus "registry: " plus registry_url plus newline
        write file cache_path plus "/cache.info" with info
        if data is not ""
            write file cache_path plus "/package.ak" with data
        end
    end

    behaviour get cached taking name and version
        let cache_path = cache_dir plus "/" plus name plus "-" plus version
        if file exists cache_path
            give back true
        end
        give back false
    end

    behaviour list installed
        if size of installed is 0
            show "No packages installed."
            give back
        end
        show "Installed packages:"
        let index = 1
        for each pkg in installed
            show "  " plus index as text plus ". " plus pkg name plus " v" plus pkg version
            if pkg author is not ""
                show "     Author: " plus pkg author
            end
            if pkg description is not ""
                show "     Description: " plus pkg description
            end
            if pkg install_path is not ""
                show "     Path: " plus pkg install_path
            end
            if size of pkg dependencies is greater than 0
                show "     Dependencies:"
                for each dep in pkg dependencies
                    show "       - " plus dep name plus " v" plus dep version
                end
            end
            index = index plus 1
        end
        show "Total: " plus size of installed as text plus " packages"
    end

    behaviour update taking package_name
        let found = false
        for each pkg in installed
            if pkg name is package_name
                found = true
                show "Checking for updates for " plus package_name plus " v" plus pkg version plus "..."
                let current_parts = split pkg version by "."
                let major = 0
                if size of current_parts is greater than 0
                    major = item 0 of current_parts as number
                end
                let minor = 0
                if size of current_parts is greater than 1
                    minor = item 1 of current_parts as number
                end
                let new_version = major as text plus "." plus minor plus 1 as text plus ".0"
                show "  Current version: " plus pkg version
                show "  Latest version: " plus new_version
                if new_version is not pkg version
                    show "  Update available!"
                    show "  Run: akpkg install " plus package_name
                else
                    show "  Already up to date."
                end
                break
            end
        end
        if found is not true
            show "Package " plus package_name plus " is not installed."
        end
    end
end
