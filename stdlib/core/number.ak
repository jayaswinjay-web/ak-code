## AK CODE Number Module — numerical operations
## Provides extended mathematical functions for numbers

always PI = 3.141592653589793
always E = 2.718281828459045
always GOLDEN_RATIO = 1.618033988749895

define to the power of taking base and exponent
    ## Computes base raised to the exponent
    ## Uses exponentiation by squaring for integers
    if exponent is 0
        give back 1
    end
    if exponent is 1
        give back base
    end
    if exponent is less than 0
        give back 1 divided by (to the power of base and (0 minus exponent))
    end
    if exponent mod 2 is 0
        let half = to the power of base and (exponent divided by 2)
        give back half times half
    end
    give back base times to the power of base and (exponent minus 1)
end

define square root of taking x
    ## Computes the square root of x using Newton's method
    if x is less than 0
        give back empty
    end
    if x is 0
        give back 0
    end
    let guess = x
    let i = 0
    repeat while i is less than 50
        let next = (guess plus x divided by guess) divided by 2
        if absolute (next minus guess) is less than 0.0000000001
            give back next
        end
        guess = next
        i = i plus 1
    end
    give back guess
end

define absolute taking x
    ## Returns the absolute value of x
    if x is less than 0
        give back 0 minus x
    end
    give back x
end

define floor taking x
    ## Returns the largest integer less than or equal to x
    let int part = x as integer
    if x is less than int part
        give back int part minus 1
    end
    give back int part
end

define ceiling taking x
    ## Returns the smallest integer greater than or equal to x
    let int part = x as integer
    if x is greater than int part
        give back int part plus 1
    end
    give back int part
end

define round taking x
    ## Rounds x to the nearest integer
    let int part = x as integer
    let frac = x minus int part
    if frac is greater than or equal to 0.5
        give back int part plus 1
    end
    if frac is less than -0.5
        give back int part minus 1
    end
    give back int part
end

define round to taking x and decimals
    ## Rounds x to a specified number of decimal places
    let factor = 10 to the power of decimals
    give back round (x times factor) divided by factor
end

define sin taking x
    ## Computes the sine of x (x in radians)
    ## Uses Taylor series: sin(x) = x - x^3/3! + x^5/5! - ...
    let result = 0
    let term = x
    let n = 1
    let i = 0
    repeat while i is less than 20
        result = result plus term
        term = 0 minus term times x times x divided by ((n plus 1) times (n plus 2))
        n = n plus 2
        i = i plus 1
    end
    give back result
end

define cos taking x
    ## Computes the cosine of x (x in radians)
    ## Uses Taylor series: cos(x) = 1 - x^2/2! + x^4/4! - ...
    let result = 0
    let term = 1
    let n = 0
    let i = 0
    repeat while i is less than 20
        result = result plus term
        term = 0 minus term times x times x divided by ((n plus 1) times (n plus 2))
        n = n plus 2
        i = i plus 1
    end
    give back result
end

define tan taking x
    ## Computes the tangent of x
    give back sin x divided by cos x
end

define exp taking x
    ## Computes e^x using Taylor series
    let result = 0
    let term = 1
    let n = 1
    let i = 0
    repeat while i is less than 30
        result = result plus term
        term = term times x divided by n
        n = n plus 1
        i = i plus 1
    end
    give back result
end

define ln taking x
    ## Computes the natural logarithm of x
    if x is less than or equal to 0
        give back empty
    end
    if x is 1
        give back 0
    end
    let guess = x divided by 2
    let i = 0
    repeat while i is less than 50
        let next = guess plus (x divided by exp guess minus 1)  # Newton iteration
        if absolute (next minus guess) is less than 0.0000000001
            give back next
        end
        guess = next
        i = i plus 1
    end
    give back guess
end

define log taking base and x
    ## Computes the logarithm of x with given base
    give back ln x divided by ln base
end

define degrees to radians taking deg
    ## Converts degrees to radians
    give back deg times PI divided by 180
end

define radians to degrees taking rad
    ## Converts radians to degrees
    give back rad times 180 divided by PI
end

define min taking a and b
    ## Returns the smaller of two values
    if a is less than b
        give back a
    end
    give back b
end

define max taking a and b
    ## Returns the larger of two values
    if a is greater than b
        give back a
    end
    give back b
end

define clamp taking value and min val and max val
    ## Clamps a value between a minimum and maximum
    if value is less than min val
        give back min val
    end
    if value is greater than max val
        give back max val
    end
    give back value
end

define is even taking n
    ## Returns true if n is even
    give back n mod 2 is 0
end

define is odd taking n
    ## Returns true if n is odd
    give back n mod 2 is not 0
end

define random
    ## Returns a random number between 0 and 1
    give back os random
end

define random between taking min and max
    ## Returns a random number between min and max
    give back min plus (max minus min) times random
end

define random integer taking max
    ## Returns a random integer between 0 and max-1
    let r = random
    give back floor (r times max)
end
