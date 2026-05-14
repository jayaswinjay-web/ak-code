## AK CODE Tensor Module — multi-dimensional arrays for ML
## Core data structure for neural network computations

make kind called Tensor
    has shape of type list of number
    has data of type list of number
    has total size of type number

    when created taking dimensions
        shape = dimensions
        total size = 1
        for each dim in dimensions
            total size = total size times dim
        end
        data = list of
        let i = 0
        repeat while i is less than total size
            add 0 to data
            i = i plus 1
        end
    end

    behaviour fill taking value
        let i = 0
        repeat while i is less than total size
            set item i of data to value
            i = i plus 1
        end
    end

    behaviour get at taking indices
        let index = compute index indices
        give back item index of data
    end

    behaviour set at taking indices and value
        let index = compute index indices
        set item index of data to value
    end

    behaviour compute index taking indices
        let idx = 0
        let stride = 1
        let i = size of indices minus 1
        repeat while i is greater than or equal to 0
            idx = idx plus stride times item i of indices
            if i is greater than 0
                stride = stride times item i of shape
            end
            i = i minus 1
        end
        give back idx
    end

    behaviour add taking other of type Tensor
        if size of shape is not size of other shape
            show "Error: Tensor shapes must match for addition"
            give back empty
        end
        let result = new Tensor with shape
        let i = 0
        repeat while i is less than total size
            set item i of result data to (item i of data) plus (item i of other data)
            i = i plus 1
        end
        give back result
    end

    behaviour multiply taking other of type Tensor
        if size of shape is not size of other shape
            show "Error: Tensor shapes must match for element-wise multiplication"
            give back empty
        end
        let result = new Tensor with shape
        let i = 0
        repeat while i is less than total size
            set item i of result data to (item i of data) times (item i of other data)
            i = i plus 1
        end
        give back result
    end

    behaviour dot taking other of type Tensor
        if size of shape is not 2 or size of other shape is not 2
            show "Error: Dot product requires 2D tensors (matrices)"
            give back empty
        end
        let m = item 0 of shape
        let n = item 1 of shape
        let other m = item 0 of other shape
        let other n = item 1 of other shape
        if n is not other m
            show "Error: Incompatible dimensions for matrix multiplication"
            give back empty
        end
        let result = new Tensor with list of m other n
        let i = 0
        repeat while i is less than m
            let j = 0
            repeat while j is less than other n
                let sum = 0
                let k = 0
                repeat while k is less than n
                    let a = item i times n plus k of data
                    let b = item k times other n plus j of other data
                    sum = sum plus a times b
                    k = k plus 1
                end
                set item i times other n plus j of result data to sum
                j = j plus 1
            end
            i = i plus 1
        end
        give back result
    end

    behaviour scale taking factor
        let result = new Tensor with shape
        let i = 0
        repeat while i is less than total size
            set item i of result data to (item i of data) times factor
            i = i plus 1
        end
        give back result
    end

    behaviour apply taking fn
        let result = new Tensor with shape
        let i = 0
        repeat while i is less than total size
            set item i of result data to fn (item i of data)
            i = i plus 1
        end
        give back result
    end

    behaviour sum
        let result = 0
        for each value in data
            result = result plus value
        end
        give back result
    end

    behaviour mean
        if total size is 0
            give back 0
        end
        give back sum divided by total size
    end

    behaviour reshape taking new shape
        let new total = 1
        for each dim in new shape
            new total = new total times dim
        end
        if new total is not total size
            show "Error: Cannot reshape tensor, size mismatch"
            give back empty
        end
        let result = new Tensor with new shape
        result data = data
        give back result
    end

    behaviour transpose
        if size of shape is not 2
            show "Error: Transpose requires a 2D tensor"
            give back empty
        end
        let rows = item 0 of shape
        let cols = item 1 of shape
        let result = new Tensor with list of cols rows
        let i = 0
        repeat while i is less than rows
            let j = 0
            repeat while j is less than cols
                set item j times rows plus i of result data to item i times cols plus j of data
                j = j plus 1
            end
            i = i plus 1
        end
        give back result
    end

    behaviour as text
        if size of shape is 1
            let result = "["
            let i = 0
            repeat while i is less than total size
                if i is greater than 0
                    result = result plus ", "
                end
                result = result plus item i of data as text
                i = i plus 1
            end
            result = result plus "]"
            give back result
        end
        if size of shape is 2
            let result = "["
            let rows = item 0 of shape
            let cols = item 1 of shape
            let i = 0
            repeat while i is less than rows
                if i is greater than 0
                    result = result plus ",\n "
                end
                result = result plus "["
                let j = 0
                repeat while j is less than cols
                    if j is greater than 0
                        result = result plus ", "
                    end
                    result = result plus item i times cols plus j of data as text
                    j = j plus 1
                end
                result = result plus "]"
                i = i plus 1
            end
            result = result plus "]"
            give back result
        end
        give back "<Tensor shape=" plus shape as text plus ">"
    end
end

define tensor of taking data list
    ## Creates a 1D tensor from a list of values
    let t = new Tensor with list of size of data list
    let i = 0
    for each val in data list
        set item i of t data to val
        i = i plus 1
    end
    give back t
end

define random tensor taking shape with mean and std
    ## Creates a tensor filled with random values (normal distribution)
    let t = new Tensor with shape
    let i = 0
    repeat while i is less than t total size
        let u1 = random
        let u2 = random
        let r = sqrt(0 minus 2 times ln u1)
        let theta = 2 times PI times u2
        let normal = mean plus std times r times cos theta
        set item i of t data to normal
        i = i plus 1
    end
    give back t
end

define zeros tensor taking shape
    ## Creates a tensor filled with zeros
    give back new Tensor with shape
end

define ones tensor taking shape
    ## Creates a tensor filled with ones
    let t = new Tensor with shape
    t fill 1
    give back t
end
