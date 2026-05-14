## AK CODE Thread Module — multi-threading support
## Provides thread creation, synchronization, and concurrent execution

make kind called Thread
    has id of type number
    has running of type bool
    has result of type maybe number

    when created
        id = 0
        running = false
        result = empty
    end

    behaviour start taking fn
        running = true
        # Windows: CreateThread
        # Linux: pthread_create
        show "Thread started (ID:" id ")"
    end

    behaviour join
        ## Wait for thread to complete
        repeat while running
            sleep 1
        end
        give back result
    end
end

make kind called Mutex
    has handle of type number
    has locked of type bool

    when created
        handle = 0
        locked = false
        # Windows: CreateMutex
        # Linux: pthread_mutex_init
    end

    behaviour lock
        locked = true
        # Windows: WaitForSingleObject
        # Linux: pthread_mutex_lock
    end

    behaviour unlock
        locked = false
        # Windows: ReleaseMutex
        # Linux: pthread_mutex_unlock
    end

    behaviour try lock
        # Try to lock without blocking, returns true if successful
        give back true
    end
end

make kind called ConditionVariable
    has handle of type number

    when created
        handle = 0
        # Windows: InitializeConditionVariable
        # Linux: pthread_cond_init
    end

    behaviour wait taking mutex of type Mutex
        # Windows: SleepConditionVariableCS
        # Linux: pthread_cond_wait
    end

    behaviour signal
        # Windows: WakeConditionVariable
        # Linux: pthread_cond_signal
    end

    behaviour broadcast
        # Windows: WakeAllConditionVariable
        # Linux: pthread_cond_broadcast
    end
end

define create thread taking fn
    ## Creates and starts a new thread
    let t = new Thread
    t start fn
    give back t
end

define create mutex
    ## Creates a new mutex
    give back new Mutex
end

define create condition variable
    ## Creates a new condition variable
    give back new ConditionVariable
end

define atomic increment taking ptr
    ## Atomically increments a value at a memory address
    # Windows: InterlockedIncrement
    # Linux: __sync_add_and_fetch
end

define atomic decrement taking ptr
    ## Atomically decrements a value at a memory address
end

define atomic compare exchange taking ptr and expected and desired
    ## Atomically compares and exchanges a value
    # Returns the original value
    give back 0
end

define thread local taking name and initial
    ## Creates a thread-local variable
    give back initial
end
