## AK CODE Calculus Module — differentiation and integration
## Provides calculus operations for mathematical analysis

define derivative of taking f at x with h
    ## Computes the numerical derivative of f at point x
    ## Uses central difference: f'(x) ≈ (f(x+h) - f(x-h)) / (2h)
    if h is empty
        h = 0.0001
    end
    let fx plus = f (x plus h)
    let fx minus = f (x minus h)
    give back (fx plus minus fx minus) divided by (2 times h)
end

define integrate from a to b with n steps taking f
    ## Computes the definite integral of f from a to b
    ## Uses Simpson's rule for better accuracy
    if n is empty
        n = 100
    end
    let h = (b minus a) divided by n
    let result = f a plus f b
    let i = 1
    repeat while i is less than n
        let x = a plus i times h
        if i mod 2 is 0
            result = result plus 2 times f x
        else
            result = result plus 4 times f x
        end
        i = i plus 1
    end
    result = result times h divided by 3
    give back result
end

define trapezoidal integrate from a to b with n steps taking f
    ## Computes the definite integral using the trapezoidal rule
    if n is empty
        n = 100
    end
    let h = (b minus a) divided by n
    let result = (f a plus f b) divided by 2
    let i = 1
    repeat while i is less than n
        let x = a plus i times h
        result = result plus f x
        i = i plus 1
    end
    result = result times h
    give back result
end

define limit of f at x from direction
    ## Computes the limit of f as the input approaches x
    ## direction: "left" for left-hand limit, "right" for right-hand, default "both"
    let h = 0.0001
    if direction is "left"
        give back f (x minus h)
    end
    if direction is "right"
        give back f (x plus h)
    end
    # Both sides: average
    let left = f (x minus h)
    let right = f (x plus h)
    if absolute (left minus right) is less than 0.0001
        give back (left plus right) divided by 2
    end
    give back empty  # Limit does not exist
end

define taylor series of f at a up to n terms
    ## Computes the Taylor series expansion of f around point a
    ## Returns a list of coefficients [c0, c1, c2, ...]
    ## where the series is c0 + c1*(x-a) + c2*(x-a)^2 + ...
    let coeffs = list of
    let i = 0
    repeat while i is less than n
        let deriv = f
        let j = 0
        repeat while j is less than i
            # Compute ith derivative numerically
            let current deriv = deriv
            deriv = behaviour taking x give back derivative of current deriv at x with 0.0001 end
            j = j plus 1
        end
        let val = deriv a
        let fact = factorial i
        add val divided by fact to coeffs
        i = i plus 1
    end
    give back coeffs
end

define root find taking f and guess
    ## Finds a root of f(x) = 0 using Newton's method
    let x = guess
    let i = 0
    repeat while i is less than 100
        let fx = f x
        if absolute fx is less than 0.0000001
            give back x
        end
        let df = derivative of f at x with 0.0001
        if df is 0
            give back x  # Can't improve further
        end
        x = x minus fx divided by df
        i = i plus 1
    end
    give back x
end

define bisection root find taking f and a and b
    ## Finds a root of f(x) = 0 in the interval [a,b] using bisection
    let fa = f a
    let fb = f b
    if fa times fb is greater than 0
        give back empty  # No root in interval
    end
    let left = a
    let right = b
    let i = 0
    repeat while i is less than 100
        let mid = (left plus right) divided by 2
        let fmid = f mid
        if absolute fmid is less than 0.0000001
            give back mid
        end
        if fa times fmid is less than 0
            right = mid
            fb = fmid
        else
            left = mid
            fa = fmid
        end
        i = i plus 1
    end
    give back (left plus right) divided by 2
end

define sum from a to b of f
    ## Computes the sum of f(i) for integer i from a to b
    let result = 0
    let i = a
    repeat while i is less than or equal to b
        result = result plus f i
        i = i plus 1
    end
    give back result
end

define product from a to b of f
    ## Computes the product of f(i) for integer i from a to b
    let result = 1
    let i = a
    repeat while i is less than or equal to b
        result = result times f i
        i = i plus 1
    end
    give back result
end
