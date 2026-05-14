## AK CODE Memory Module — memory management
## Provides allocation, deallocation, and garbage collection

define allocate taking size
    ## Allocates a block of memory of the given size (in bytes)
    ## Returns a pointer to the allocated memory
    ## Example: let buffer = allocate 1024
    give back os allocate memory size
end

define free taking ptr
    ## Frees a previously allocated memory block
    ## Example: free buffer
    os free memory ptr
end

define copy memory taking source to destination of size
    ## Copies memory from source to destination
    ## Example: copy memory src to dst of 100
    let i = 0
    repeat while i is less than size
        set byte at destination plus i to byte at source plus i
        i = i plus 1
    end
end

define set memory taking ptr to value for size
    ## Sets a block of memory to a specific byte value
    ## Example: set memory buffer to 0 for 1024
    let i = 0
    repeat while i is less than size
        set byte at ptr plus i to value
        i = i plus 1
    end
end

define read byte at taking address
    ## Reads a single byte from a memory address
    give back byte at address
end

define write byte at taking address and value
    ## Writes a single byte to a memory address
    set byte at address to value
end

define stack allocate taking size
    ## Allocates memory on the stack (faster, but limited)
    ## Use for small, temporary allocations
    give back os stack allocate size
end

define reference count of taking ptr
    ## Returns the reference count of a managed object
    ## Used for reference counting GC
    give back os get refcount ptr
end

define retain taking ptr
    ## Increments the reference count of an object
    os retain ptr
end

define release taking ptr
    ## Decrements the reference count of an object
    ## Frees the object if count reaches zero
    os release ptr
end

define garbage collect
    ## Forces a garbage collection cycle
    os run gc
end

define enable gc
    ## Enables automatic garbage collection
    os set gc enabled true
end

define disable gc
    ## Disables automatic garbage collection
    ## Use in performance-critical sections
    os set gc enabled false
end

define in manual memory mode
    ## Placeholder for manual memory management block
    ## Usage: in manual memory mode ... end
end
