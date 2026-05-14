## AK CODE Loss Functions — for neural network training
## Provides loss computation and gradient calculation

define mean squared error taking prediction and target
    ## Computes Mean Squared Error loss
    let loss = 0
    let n = prediction total size
    let i = 0
    repeat while i is less than n
        let diff = item i of prediction data minus item i of target data
        loss = loss plus diff times diff
        i = i plus 1
    end
    give back loss divided by n
end

define cross entropy loss taking prediction and target
    ## Computes Cross-Entropy loss for classification
    let loss = 0
    let i = 0
    repeat while i is less than prediction total size
        let p = item i of prediction data
        let t = item i of target data
        if t is greater than 0
            if p is greater than 0.0000001
                loss = loss minus t times ln p
            else
                loss = loss minus t times ln 0.0000001
            end
        end
        i = i plus 1
    end
    give back loss
end

define binary cross entropy loss taking prediction and target
    ## Computes Binary Cross-Entropy loss for binary classification
    let loss = 0
    let i = 0
    repeat while i is less than prediction total size
        let p = item i of prediction data
        let t = item i of target data
        if p is greater than 0.0000001
            loss = loss minus t times ln p
        end
        if p is less than 0.9999999
            loss = loss minus (1 minus t) times ln (1 minus p)
        end
        i = i plus 1
    end
    give back loss
end

define mse gradient taking prediction and target
    ## Computes the gradient of MSE loss with respect to prediction
    let grad = new Tensor with prediction shape
    let n = prediction total size
    let i = 0
    repeat while i is less than n
        set item i of grad data to 2 times (item i of prediction data minus item i of target data) divided by n
        i = i plus 1
    end
    give back grad
end

define cross entropy gradient taking prediction and target
    ## Computes the gradient of Cross-Entropy loss with respect to prediction
    let grad = new Tensor with prediction shape
    let i = 0
    repeat while i is less than prediction total size
        let p = item i of prediction data
        let t = item i of target data
        if p is greater than 0.0000001
            set item i of grad data to 0 minus t divided by p
        else
            set item i of grad data to 0
        end
        i = i plus 1
    end
    give back grad
end

define hinge loss taking prediction and target
    ## Computes Hinge loss for SVM-style classification
    let loss = 0
    let i = 0
    repeat while i is less than prediction total size
        let margin = 1 minus item i of target data times item i of prediction data
        if margin is greater than 0
            loss = loss plus margin
        end
        i = i plus 1
    end
    give back loss divided by prediction total size
end

define huber loss taking prediction and target and delta
    ## Computes Huber loss, which is less sensitive to outliers than MSE
    if delta is empty
        delta = 1
    end
    let loss = 0
    let i = 0
    repeat while i is less than prediction total size
        let diff = item i of prediction data minus item i of target data
        let abs diff = absolute diff
        if abs diff is less than or equal to delta
            loss = loss plus 0.5 times diff times diff
        else
            loss = loss plus delta times (abs diff minus 0.5 times delta)
        end
        i = i plus 1
    end
    give back loss divided by prediction total size
end
