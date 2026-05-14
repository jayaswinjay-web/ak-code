## AK CODE Matrix Module — linear algebra operations
## Provides matrix and vector operations for scientific computing

make kind called Matrix
    has data of type list of list of number
    has rows of type number
    has columns of type number

    when created taking num rows and num cols
        rows = num rows
        columns = num cols
        data = list of
        let i = 0
        repeat while i is less than rows
            let row = list of
            let j = 0
            repeat while j is less than columns
                add 0 to row
                j = j plus 1
            end
            add row to data
            i = i plus 1
        end
    end

    behaviour set taking row and col and value
        let target row = item row of data
        set item col of target row to value
    end

    behaviour get taking row and col
        let target row = item row of data
        give back item col of target row
    end

    behaviour add taking other of type Matrix
        if rows is not other rows or columns is not other columns
            show "Error: Matrix dimensions must match for addition"
            give back empty
        end
        let result = new Matrix with rows and columns
        let i = 0
        repeat while i is less than rows
            let j = 0
            repeat while j is less than columns
                let val = get i and j plus other get i and j
                result set i and j and val
                j = j plus 1
            end
            i = i plus 1
        end
        give back result
    end

    behaviour multiply taking other of type Matrix
        if columns is not other rows
            show "Error: Matrix dimensions incompatible for multiplication"
            give back empty
        end
        let result = new Matrix with rows and other columns
        let i = 0
        repeat while i is less than rows
            let j = 0
            repeat while j is less than other columns
                let sum = 0
                let k = 0
                repeat while k is less than columns
                    sum = sum plus (get i and k) times (other get k and j)
                    k = k plus 1
                end
                result set i and j and sum
                j = j plus 1
            end
            i = i plus 1
        end
        give back result
    end

    behaviour scale taking factor
        let result = new Matrix with rows and columns
        let i = 0
        repeat while i is less than rows
            let j = 0
            repeat while j is less than columns
                result set i and j and (get i and j) times factor
                j = j plus 1
            end
            i = i plus 1
        end
        give back result
    end

    behaviour transpose
        let result = new Matrix with columns and rows
        let i = 0
        repeat while i is less than rows
            let j = 0
            repeat while j is less than columns
                result set j and i and get i and j
                j = j plus 1
            end
            i = i plus 1
        end
        give back result
    end

    behaviour determinant
        if rows is not columns
            show "Error: Determinant requires a square matrix"
            give back 0
        end
        if rows is 1
            give back get 0 and 0
        end
        if rows is 2
            let a = get 0 and 0
            let b = get 0 and 1
            let c = get 1 and 0
            let d = get 1 and 1
            give back a times d minus b times c
        end
        # For larger matrices, use Laplace expansion (recursive)
        let det = 0
        let j = 0
        repeat while j is less than columns
            let sign = 1
            if j mod 2 is 1
                sign = -1
            end
            let sub = get minor 0 and j
            det = det plus sign times (get 0 and j) times (sub determinant)
            j = j plus 1
        end
        give back det
    end

    behaviour get minor taking row and col
        let result = new Matrix with rows minus 1 and columns minus 1
        let r = 0
        let i = 0
        repeat while i is less than rows
            if i is not row
                let c = 0
                let j = 0
                repeat while j is less than columns
                    if j is not col
                        result set r and c and get i and j
                        c = c plus 1
                    end
                    j = j plus 1
                end
                r = r plus 1
            end
            i = i plus 1
        end
        give back result
    end

    behaviour inverse
        let det = determinant
        if det is 0
            show "Error: Matrix is singular, cannot invert"
            give back empty
        end
        # Using adjugate method for small matrices
        if rows is 2
            let result = new Matrix with 2 and 2
            result set 0 and 0 and get 1 and 1 divided by det
            result set 0 and 1 and (0 minus get 0 and 1) divided by det
            result set 1 and 0 and (0 minus get 1 and 0) divided by det
            result set 1 and 1 and get 0 and 0 divided by det
            give back result
        end
        # For larger matrices, use cofactor method
        let result = new Matrix with rows and columns
        let i = 0
        repeat while i is less than rows
            let j = 0
            repeat while j is less than columns
                let sign = 1
                if (i plus j) mod 2 is 1
                    sign = -1
                end
                let minor = get minor i and j
                let cofactor = sign times (minor determinant)
                result set j and i and cofactor divided by det  # transpose here
                j = j plus 1
            end
            i = i plus 1
        end
        give back result
    end

    behaviour as text
        let result = "["
        let i = 0
        repeat while i is less than rows
            if i is greater than 0
                result = result plus "; "
            end
            result = result plus "["
            let j = 0
            repeat while j is less than columns
                if j is greater than 0
                    result = result plus ", "
                end
                result = result plus get i and j as text
                j = j plus 1
            end
            result = result plus "]"
            i = i plus 1
        end
        result = result plus "]"
        give back result
    end
end

define identity matrix of size n
    ## Creates an n x n identity matrix
    let result = new Matrix with n and n
    let i = 0
    repeat while i is less than n
        result set i and i and 1
        i = i plus 1
    end
    give back result
end

define zero matrix of rows and cols
    ## Creates a rows x cols zero matrix
    give back new Matrix with rows and cols
end

define dot product of vector a and vector b
    ## Computes the dot product of two vectors
    if size of a is not size of b
        show "Error: Vectors must have same length"
        give back 0
    end
    let result = 0
    let i = 0
    repeat while i is less than size of a
        result = result plus (item i of a) times (item i of b)
        i = i plus 1
    end
    give back result
end

define cross product of vector a and vector b
    ## Computes the cross product of two 3D vectors
    if size of a is not 3 or size of b is not 3
        show "Error: Cross product requires 3D vectors"
        give back list of 0 0 0
    end
    let x = (item 1 of a) times (item 2 of b) minus (item 2 of a) times (item 1 of b)
    let y = (item 2 of a) times (item 0 of b) minus (item 0 of a) times (item 2 of b)
    let z = (item 0 of a) times (item 1 of b) minus (item 1 of a) times (item 0 of b)
    give back list of x y z
end

define vector norm of v
    ## Computes the Euclidean norm (magnitude) of a vector
    let sum = 0
    for each component in v
        sum = sum plus component times component
    end
    give back square root of sum
end

define normalize vector v
    ## Normalizes a vector to unit length
    let norm = vector norm of v
    if norm is 0
        give back v
    end
    let result = list of
    for each component in v
        add component divided by norm to result
    end
    give back result
end
