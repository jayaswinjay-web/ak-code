## AK CODE Neural Network Layers
## Provides the building blocks for neural networks

make kind called Layer
    has type of type text
    has input size of type number
    has output size of type number
    has weights of type Tensor
    has biases of type Tensor
    has activation of type text
    has drop rate of type number

    when created taking kind
        type = kind
        activation = "none"
        drop rate = 0
    end

    behaviour initialize
        if type is "dense" or type is "output"
            # Xavier/Glorot initialization
            let scale = square root of (2 divided by (input size plus output size))
            weights = random tensor list of input size output size with mean 0 and std scale
            biases = new Tensor with list of output size
            biases fill 0
        end
    end

    behaviour forward taking input of type Tensor
        if type is "input"
            give back input
        end
        if type is "dense" or type is "output"
            # z = W * x + b
            let z = input dot weights
            # Add biases
            if z shape is list of 1 output size or size of z shape is 1
                let i = 0
                repeat while i is less than output size
                    let val = item i of z data plus item i of biases data
                    set item i of z data to val
                    i = i plus 1
                end
            end
            # Apply activation
            if activation is "relu"
                give back apply relu z
            end
            if activation is "sigmoid"
                give back apply sigmoid z
            end
            if activation is "tanh"
                give back apply tanh z
            end
            if activation is "softmax"
                give back apply softmax z
            end
            give back z
        end
        if type is "dropout"
            if drop rate is greater than 0
                let scale = 1 divided by (1 minus drop rate)
                let result = new Tensor with input shape
                let i = 0
                repeat while i is less than input total size
                    if random is greater than drop rate
                        set item i of result data to item i of input data times scale
                    else
                        set item i of result data to 0
                    end
                    i = i plus 1
                end
                give back result
            end
            give back input
        end
        give back input
    end
end

define apply relu taking tensor
    ## ReLU activation: max(0, x)
    let result = new Tensor with tensor shape
    let i = 0
    repeat while i is less than result total size
        let val = item i of tensor data
        if val is less than 0
            set item i of result data to 0
        else
            set item i of result data to val
        end
        i = i plus 1
    end
    give back result
end

define apply sigmoid taking tensor
    ## Sigmoid activation: 1 / (1 + e^(-x))
    let result = new Tensor with tensor shape
    let i = 0
    repeat while i is less than result total size
        let x = item i of tensor data
        let sig = 1 divided by (1 plus (E to the power of (0 minus x)))
        set item i of result data to sig
        i = i plus 1
    end
    give back result
end

define apply tanh taking tensor
    ## Tanh activation: (e^x - e^(-x)) / (e^x + e^(-x))
    let result = new Tensor with tensor shape
    let i = 0
    repeat while i is less than result total size
        let x = item i of tensor data
        let e x = exp x
        let e neg x = exp (0 minus x)
        let t = (e x minus e neg x) divided by (e x plus e neg x)
        set item i of result data to t
        i = i plus 1
    end
    give back result
end

define apply softmax taking tensor
    ## Softmax activation: e^x_i / sum(e^x_j)
    let result = new Tensor with tensor shape
    # Find max for numerical stability
    let max val = item 0 of tensor data
    for each val in tensor data
        if val is greater than max val
            max val = val
        end
    end
    # Compute exponentials and sum
    let sum = 0
    let exps = list of
    for each val in tensor data
        let e val = exp (val minus max val)
        add e val to exps
        sum = sum plus e val
    end
    # Normalize
    let i = 0
    for each e val in exps
        set item i of result data to e val divided by sum
        i = i plus 1
    end
    give back result
end

define layer input of size taking n
    ## Creates an input layer
    let l = new Layer with "input"
    l output size = n
    give back l
end

define layer dense of size taking n with activation act
    ## Creates a dense (fully connected) layer
    let l = new Layer with "dense"
    l output size = n
    if act is not empty
        l activation = act
    end
    give back l
end

define layer dropout of rate taking r
    ## Creates a dropout layer
    let l = new Layer with "dropout"
    l drop rate = r
    give back l
end

define layer output of size taking n with activation act
    ## Creates an output layer
    let l = new Layer with "output"
    l output size = n
    if act is not empty
        l activation = act
    end
    give back l
end
