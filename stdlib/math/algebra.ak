## AK CODE Algebra Module — algebraic operations
## Provides equation solving and symbolic manipulation

define solve linear taking a and b
    ## Solves a linear equation: ax + b = 0
    ## Returns x = -b/a
    if a is 0
        give back empty  # No solution or infinite solutions
    end
    give back 0 minus b divided by a
end

define solve quadratic taking a and b and c
    ## Solves a quadratic equation: ax^2 + bx + c = 0
    ## Returns list of solutions (up to 2)
    let discriminant = b times b minus 4 times a times c
    if discriminant is less than 0
        give back list of  # No real solutions
    end
    if discriminant is 0
        let x = 0 minus b divided by (2 times a)
        give back list of x
    end
    let sqrt d = square root of discriminant
    let x1 = (0 minus b plus sqrt d) divided by (2 times a)
    let x2 = (0 minus b minus sqrt d) divided by (2 times a)
    give back list of x1 x2
end

define factorial taking n
    ## Computes n! (n factorial)
    ## Example: factorial 5 gives 120
    if n is less than 0
        give back empty
    end
    if n is 0 or n is 1
        give back 1
    end
    let result = 1
    let i = 2
    repeat while i is less than or equal to n
        result = result times i
        i = i plus 1
    end
    give back result
end

define fibonacci taking n
    ## Computes the nth Fibonacci number
    ## F(0) = 0, F(1) = 1, F(n) = F(n-1) + F(n-2)
    if n is 0
        give back 0
    end
    if n is 1
        give back 1
    end
    let a = 0
    let b = 1
    let i = 2
    repeat while i is less than or equal to n
        let temp = a plus b
        a = b
        b = temp
        i = i plus 1
    end
    give back b
end

define gcd taking a and b
    ## Computes the greatest common divisor of a and b
    ## Uses Euclidean algorithm
    repeat while b is not 0
        let temp = b
        b = a mod b
        a = temp
    end
    give back a
end

define lcm taking a and b
    ## Computes the least common multiple of a and b
    if a is 0 or b is 0
        give back 0
    end
    give back (a divided by gcd a and b) times b
end

define is prime taking n
    ## Checks if a number is prime
    if n is less than 2
        give back false
    end
    if n is 2
        give back true
    end
    if n mod 2 is 0
        give back false
    end
    let i = 3
    let limit = square root of n
    repeat while i is less than or equal to limit
        if n mod i is 0
            give back false
        end
        i = i plus 2
    end
    give back true
end

define prime factors taking n
    ## Returns a list of prime factors of n
    let result = list of
    let num = n
    let i = 2
    repeat while i times i is less than or equal to num
        repeat while num mod i is 0
            add i to result
            num = num divided by i
        end
        i = i plus 1
    end
    if num is greater than 1
        add num to result
    end
    give back result
end

define binomial taking n and k
    ## Computes the binomial coefficient C(n,k)
    if k is less than 0 or k is greater than n
        give back 0
    end
    if k is 0 or k is n
        give back 1
    end
    let result = 1
    let i = 1
    repeat while i is less than or equal to k
        result = result times (n minus k plus i) divided by i
        i = i plus 1
    end
    give back result
end

define absolute taking x
    ## Returns the absolute value of x
    if x is less than 0
        give back 0 minus x
    end
    give back x
end

define sign of taking x
    ## Returns -1 for negative, 0 for zero, 1 for positive
    if x is greater than 0
        give back 1
    end
    if x is less than 0
        give back -1
    end
    give back 0
end

define clamp taking x and min and max
    ## Clamps x between min and max
    if x is less than min
        give back min
    end
    if x is greater than max
        give back max
    end
    give back x
end

define lerp taking a and b and t
    ## Linear interpolation: a + t * (b - a)
    ## t should be between 0 and 1
    give back a plus t times (b minus a)
end

define map range taking value and from low and from high and to low and to high
    ## Maps a value from one range to another
    ## Example: map range 0.5 from 0 to 1 from 0 to 100 gives 50
    let percentage = (value minus from low) divided by (from high minus from low)
    give back to low plus percentage times (to high minus to low)
end

define evaluate polynomial taking coeffs at x
    ## Evaluates a polynomial at point x using Horner's method
    ## coeffs is a list [a0, a1, a2, ...] for a0 + a1*x + a2*x^2 + ...
    let result = 0
    let i = size of coeffs minus 1
    repeat while i is greater than or equal to 0
        result = result times x plus item i of coeffs
        i = i minus 1
    end
    give back result
end
