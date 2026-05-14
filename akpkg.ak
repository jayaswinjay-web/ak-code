## AK CODE Package Manager — CLI Entry Point
## Provides the command-line interface for the akpkg package manager
## Usage: akpkg <command> [package]

bring in stdlib pkg

define main taking args
    if size of args is less than 2
        show "AK Package Manager v1.0"
        show "Usage: akpkg <command> [package]"
        show ""
        show "Commands:"
        show "  install [package]  Install a package or all dependencies"
        show "  add <package>      Add and install a package dependency"
        show "  remove <package>   Remove a package dependency"
        show "  publish            Publish the current project"
        show "  list               List installed packages"
        show "  update <package>   Check for package updates"
        give back 1
    end

    let cmd = item 1 of args
    let manager = new PackageManager

    if cmd is "install"
        if size of args is greater than 2
            let pkg_name = item 2 of args
            manager install taking pkg_name
        else
            manager install all
        end
    else if cmd is "add"
        if size of args is greater than 2
            let pkg_name = item 2 of args
            manager add taking pkg_name
        else
            show "Usage: akpkg add <package-name>"
        end
    else if cmd is "remove"
        if size of args is greater than 2
            let pkg_name = item 2 of args
            manager remove taking pkg_name
        else
            show "Usage: akpkg remove <package-name>"
        end
    else if cmd is "publish"
        manager publish
    else if cmd is "list"
        manager list installed
    else if cmd is "update"
        if size of args is greater than 2
            let pkg_name = item 2 of args
            manager update taking pkg_name
        else
            show "Usage: akpkg update <package-name>"
        end
    else
        show "Unknown command: " plus cmd
        show "Usage: akpkg <command> [package]"
        give back 1
    end

    give back 0
end
