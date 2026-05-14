## AK CODE Optimizer Module
## Provides optimization algorithms for neural network training

make kind called Optimizer
    has type of type text
    has learning rate of type decimal
    has beta1 of type decimal
    has beta2 of type decimal
    has epsilon of type decimal
    has momentum of type decimal
    has t of type number
    has m of type list of Tensor
    has v of type list of Tensor

    when created taking kind
        type = kind
        learning rate = 0.001
        beta1 = 0.9
        beta2 = 0.999
        epsilon = 0.00000001
        momentum = 0.9
        t = 0
        m = list of
        v = list of
    end

    behaviour initialize taking params
        ## Initialize optimizer state for given parameters
        if type is "adam" or type is "adamw"
            for each param in params
                let zero m = new Tensor with param shape
                zero m fill 0
                add zero m to m
                let zero v = new Tensor with param shape
                zero v fill 0
                add zero v to v
            end
        end
    end

    behaviour update taking params and gradients
        ## Update parameters using computed gradients
        t = t plus 1

        if type is "sgd"
            let i = 0
            for each param in params
                let grad = item i of gradients
                if momentum is not 0
                    # SGD with momentum
                    if size of m is less than or equal to i
                        let vel = new Tensor with param shape
                        vel fill 0
                        add vel to m
                    end
                    let velocity = item i of m
                    # v = momentum * v - lr * grad
                    let j = 0
                    repeat while j is less than param total size
                        let new v = momentum times item j of velocity data minus learning rate times item j of grad data
                        set item j of velocity data to new v
                        j = j plus 1
                    end
                    # param += v
                    let j = 0
                    repeat while j is less than param total size
                        let new p = item j of param data plus item j of velocity data
                        set item j of param data to new p
                        j = j plus 1
                    end
                else
                    # Plain SGD: param = param - lr * grad
                    let j = 0
                    repeat while j is less than param total size
                        let new p = item j of param data minus learning rate times item j of grad data
                        set item j of param data to new p
                        j = j plus 1
                    end
                end
                i = i plus 1
            end
        end

        if type is "adam"
            let i = 0
            for each param in params
                let grad = item i of gradients
                let m t = item i of m
                let v t = item i of v

                # Update biased first moment estimate
                let j = 0
                repeat while j is less than param total size
                    let new m = beta1 times item j of m t data plus (1 minus beta1) times item j of grad data
                    set item j of m t data to new m
                    j = j plus 1
                end

                # Update biased second moment estimate
                let j = 0
                repeat while j is less than param total size
                    let g = item j of grad data
                    let new v = beta2 times item j of v t data plus (1 minus beta2) times g times g
                    set item j of v t data to new v
                    j = j plus 1
                end

                # Bias correction
                let m hat = m t scale (1 divided by (1 minus beta1 to the power of t))
                let v hat = v t scale (1 divided by (1 minus beta2 to the power of t))

                # Update parameters
                let j = 0
                repeat while j is less than param total size
                    let update = learning rate times item j of m hat data divided by (square root of item j of v hat data plus epsilon)
                    let new p = item j of param data minus update
                    set item j of param data to new p
                    j = j plus 1
                end
                i = i plus 1
            end
        end

        if type is "rmsprop"
            let i = 0
            for each param in params
                let grad = item i of gradients
                if size of v is less than or equal to i
                    let cache = new Tensor with param shape
                    cache fill 0
                    add cache to v
                end
                let cache = item i of v

                # cache = decay * cache + (1-decay) * grad^2
                let j = 0
                repeat while j is less than param total size
                    let g = item j of grad data
                    let new c = 0.9 times item j of cache data plus 0.1 times g times g
                    set item j of cache data to new c
                    j = j plus 1
                end

                # param = param - lr * grad / sqrt(cache + eps)
                let j = 0
                repeat while j is less than param total size
                    let update = learning rate times item j of grad data divided by (square root of item j of cache data plus epsilon)
                    let new p = item j of param data minus update
                    set item j of param data to new p
                    j = j plus 1
                end
                i = i plus 1
            end
        end
    end
end

define SGD with learning rate taking lr
    ## Creates an SGD optimizer
    let opt = new Optimizer with "sgd"
    opt learning rate = lr
    give back opt
end

define Adam with learning rate taking lr
    ## Creates an Adam optimizer
    let opt = new Optimizer with "adam"
    opt learning rate = lr
    give back opt
end

define RMSProp with learning rate taking lr
    ## Creates an RMSProp optimizer
    let opt = new Optimizer with "rmsprop"
    opt learning rate = lr
    give back opt
end
