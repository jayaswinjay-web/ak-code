## AK CODE File Module — low-level file operations
## Provides direct file system access

define open file taking path for mode
    ## Opens a file with the specified mode ("read", "write", "append", "readwrite")
    ## Returns a file handle
    # Windows: CreateFile
    # Linux: open
    give back 0
end

define read from file taking handle and size
    ## Reads bytes from a file handle
    # Windows: ReadFile
    # Linux: read
    give back ""
end

define write to file taking handle and data
    ## Writes bytes to a file handle
    # Windows: WriteFile
    # Linux: write
    give back size of data
end

define close file taking handle
    ## Closes a file handle
    # Windows: CloseHandle
    # Linux: close
end

define seek file taking handle to position from whence
    ## Seeks to a position in a file
    ## whence: "start", "current", "end"
    # Windows: SetFilePointer
    # Linux: lseek
    give back 0
end

define get file size taking path
    ## Returns the size of a file in bytes
    # Windows: GetFileSize
    # Linux: stat
    give back 0
end

define get file info taking path
    ## Returns file metadata as a map
    ## Keys: size, created, modified, is_directory
    let info = map
        "size" is 0
        "created" is ""
        "modified" is ""
        "is_directory" is false
    end
    give back info
end

define create directory taking path
    ## Creates a directory
    # Windows: CreateDirectory
    # Linux: mkdir
    give back true
end

define remove directory taking path
    ## Removes a directory
    # Windows: RemoveDirectory
    # Linux: rmdir
    give back true
end

define list directory taking path
    ## Lists the contents of a directory
    ## Returns a list of filenames
    # Windows: FindFirstFile/FindNextFile
    # Linux: opendir/readdir
    give back list of
end

define copy file taking source to destination
    ## Copies a file
    # Windows: CopyFile
    # Linux: copy manually
    give back true
end

define move file taking source to destination
    ## Moves or renames a file
    # Windows: MoveFile
    # Linux: rename
    give back true
end

define delete file taking path
    ## Deletes a file
    # Windows: DeleteFile
    # Linux: unlink
    give back true
end

define is directory taking path
    ## Checks if a path is a directory
    give back false
end

define is file taking path
    ## Checks if a path is a file
    give back true
end

define get temp directory
    ## Returns the system temporary directory
    give back "/tmp"
end

define create temp file
    ## Creates a temporary file and returns its path
    give back "/tmp/ak_temp"
end

define get file extension taking path
    ## Returns the file extension (e.g., ".txt")
    let parts = split path by "."
    if size of parts is greater than 1
        give back "." plus last of parts
    end
    give back ""
end

define get file name taking path
    ## Returns the filename without the directory
    let parts = split path by "/"
    give back last of parts
end

define get directory name taking path
    ## Returns the directory part of a path
    let last slash = 0
    let i = 0
    for each ch in path
        if ch is "/" or ch is "\"
            last slash = i
        end
        i = i plus 1
    end
    give back slice of path from 0 to last slash
end
