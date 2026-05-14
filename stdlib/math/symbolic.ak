## AK CODE Symbolic Math Module — expression trees and symbolic manipulation
## Provides symbolic differentiation simplification and evaluation of expressions

make kind called Expression
    has type of type text
    has value of type number
    has name of type text
    has left of type Expression
    has right of type Expression
    has operand of type Expression

    when created taking expr type and val and nm and l and r and op
        type = expr type
        value = val
        name = nm
        left = l
        right = r
        operand = op
    end

    behaviour evaluate taking bindings
        if type is "number"
            give back value
        end
        if type is "variable"
            for each pair in bindings
                if item 0 of pair is name
                    give back item 1 of pair
                end
            end
            give back 0
        end
        if type is "add"
            let lv = left evaluate bindings
            let rv = right evaluate bindings
            give back lv plus rv
        end
        if type is "subtract"
            let lv = left evaluate bindings
            let rv = right evaluate bindings
            give back lv minus rv
        end
        if type is "multiply"
            let lv = left evaluate bindings
            let rv = right evaluate bindings
            give back lv times rv
        end
        if type is "divide"
            let lv = left evaluate bindings
            let rv = right evaluate bindings
            if rv is 0
                show "Error: Division by zero"
                give back 0
            end
            give back lv divided by rv
        end
        if type is "power"
            let lv = left evaluate bindings
            let rv = right evaluate bindings
            give back lv raised to rv
        end
        if type is "negate"
            let ov = operand evaluate bindings
            give back 0 minus ov
        end
        if type is "sin"
            let ov = operand evaluate bindings
            give back sine of ov
        end
        if type is "cos"
            let ov = operand evaluate bindings
            give back cosine of ov
        end
        if type is "ln"
            let ov = operand evaluate bindings
            if ov is less than or equal to 0
                show "Error: Natural log of non-positive number"
                give back 0
            end
            give back natural log of ov
        end
        if type is "exp"
            let ov = operand evaluate bindings
            give back e raised to ov
        end
        give back 0
    end

    behaviour differentiate taking variable
        if type is "number"
            give back number expr 0
        end
        if type is "variable"
            if name is variable
                give back number expr 1
            end
            give back number expr 0
        end
        if type is "add"
            let dl = left differentiate variable
            let dr = right differentiate variable
            give back add expr dl dr
        end
        if type is "subtract"
            let dl = left differentiate variable
            let dr = right differentiate variable
            give back subtract expr dl dr
        end
        if type is "multiply"
            let u = left
            let v = right
            let du = u differentiate variable
            let dv = v differentiate variable
            let term1 = multiply expr du v
            let term2 = multiply expr u dv
            give back add expr term1 term2
        end
        if type is "divide"
            let u = left
            let v = right
            let du = u differentiate variable
            let dv = v differentiate variable
            let num = subtract expr (multiply expr du v) (multiply expr u dv)
            let den = power expr v (number expr 2)
            give back divide expr num den
        end
        if type is "power"
            let u = left
            let n = right
            if n type is "number"
                let coeff = number expr n value
                let new power = number expr (n value minus 1)
                let du = u differentiate variable
                give back multiply expr coeff (multiply expr (power expr u new power) du)
            end
            give back multiply expr this (add expr (ln expr u) (multiply expr n (divide expr (u differentiate variable) u)))
        end
        if type is "negate"
            let d = operand differentiate variable
            give back negate expr d
        end
        if type is "sin"
            let d = operand differentiate variable
            give back multiply expr d (cos expr operand)
        end
        if type is "cos"
            let d = operand differentiate variable
            give back negate expr (multiply expr d (sin expr operand))
        end
        if type is "ln"
            let d = operand differentiate variable
            give back divide expr d operand
        end
        if type is "exp"
            let d = operand differentiate variable
            give back multiply expr d this
        end
        give back number expr 0
    end

    behaviour simplify
        if type is "number"
            give back this
        end
        if type is "variable"
            give back this
        end
        if type is "add"
            let sl = left simplify
            let sr = right simplify
            if sl type is "number" and sr type is "number"
                give back number expr (sl value plus sr value)
            end
            if sl type is "number" and sl value is 0
                give back sr
            end
            if sr type is "number" and sr value is 0
                give back sl
            end
            give back add expr sl sr
        end
        if type is "subtract"
            let sl = left simplify
            let sr = right simplify
            if sl type is "number" and sr type is "number"
                give back number expr (sl value minus sr value)
            end
            if sr type is "number" and sr value is 0
                give back sl
            end
            if sl type is "variable" and sr type is "variable" and sl name is sr name
                give back number expr 0
            end
            give back subtract expr sl sr
        end
        if type is "multiply"
            let sl = left simplify
            let sr = right simplify
            if sl type is "number" and sr type is "number"
                give back number expr (sl value times sr value)
            end
            if sl type is "number" and sl value is 0
                give back number expr 0
            end
            if sr type is "number" and sr value is 0
                give back number expr 0
            end
            if sl type is "number" and sl value is 1
                give back sr
            end
            if sr type is "number" and sr value is 1
                give back sl
            end
            give back multiply expr sl sr
        end
        if type is "divide"
            let sl = left simplify
            let sr = right simplify
            if sl type is "number" and sr type is "number" and sr value is not 0
                give back number expr (sl value divided by sr value)
            end
            if sl type is "number" and sl value is 0
                give back number expr 0
            end
            if sr type is "number" and sr value is 1
                give back sl
            end
            if sl type is "variable" and sr type is "variable" and sl name is sr name
                give back number expr 1
            end
            give back divide expr sl sr
        end
        if type is "power"
            let sl = left simplify
            let sr = right simplify
            if sl type is "number" and sr type is "number"
                give back number expr (sl value raised to sr value)
            end
            if sr type is "number" and sr value is 0
                give back number expr 1
            end
            if sr type is "number" and sr value is 1
                give back sl
            end
            if sl type is "number" and sl value is 0
                give back number expr 0
            end
            if sl type is "number" and sl value is 1
                give back number expr 1
            end
            give back power expr sl sr
        end
        if type is "negate"
            let so = operand simplify
            if so type is "number"
                give back number expr (0 minus so value)
            end
            if so type is "negate"
                give back so operand
            end
            give back negate expr so
        end
        if type is "sin"
            let so = operand simplify
            if so type is "number" and so value is 0
                give back number expr 0
            end
            give back sin expr so
        end
        if type is "cos"
            let so = operand simplify
            if so type is "number" and so value is 0
                give back number expr 1
            end
            give back cos expr so
        end
        if type is "ln"
            let so = operand simplify
            if so type is "number" and so value is 1
                give back number expr 0
            end
            if so type is "exp"
                give back so operand
            end
            give back ln expr so
        end
        if type is "exp"
            let so = operand simplify
            if so type is "number" and so value is 0
                give back number expr 1
            end
            if so type is "ln"
                give back so operand
            end
            give back exp expr so
        end
        give back this
    end

    behaviour as text
        if type is "number"
            give back value as text
        end
        if type is "variable"
            give back name
        end
        if type is "add"
            give back "(" plus (left as text) plus " + " plus (right as text) plus ")"
        end
        if type is "subtract"
            give back "(" plus (left as text) plus " - " plus (right as text) plus ")"
        end
        if type is "multiply"
            give back "(" plus (left as text) plus " * " plus (right as text) plus ")"
        end
        if type is "divide"
            give back "(" plus (left as text) plus " / " plus (right as text) plus ")"
        end
        if type is "power"
            give back "(" plus (left as text) plus "^" plus (right as text) plus ")"
        end
        if type is "negate"
            give back "(-" plus (operand as text) plus ")"
        end
        if type is "sin"
            give back "sin(" plus (operand as text) plus ")"
        end
        if type is "cos"
            give back "cos(" plus (operand as text) plus ")"
        end
        if type is "ln"
            give back "ln(" plus (operand as text) plus ")"
        end
        if type is "exp"
            give back "exp(" plus (operand as text) plus ")"
        end
        give back "?"
    end
end

define number expr taking v
    ## Creates an expression representing a constant number
    give back new Expression with "number" and v and "" and empty and empty and empty
end

define variable expr taking nm
    ## Creates an expression representing a variable
    give back new Expression with "variable" and 0 and nm and empty and empty and empty
end

define add expr taking l and r
    ## Creates an expression representing addition of two expressions
    give back new Expression with "add" and 0 and "" and l and r and empty
end

define subtract expr taking l and r
    ## Creates an expression representing subtraction of two expressions
    give back new Expression with "subtract" and 0 and "" and l and r and empty
end

define multiply expr taking l and r
    ## Creates an expression representing multiplication of two expressions
    give back new Expression with "multiply" and 0 and "" and l and r and empty
end

define divide expr taking l and r
    ## Creates an expression representing division of two expressions
    give back new Expression with "divide" and 0 and "" and l and r and empty
end

define power expr taking base and exp
    ## Creates an expression representing base raised to exponent
    give back new Expression with "power" and 0 and "" and base and exp and empty
end

define negate expr taking op
    ## Creates an expression representing negation of an expression
    give back new Expression with "negate" and 0 and "" and empty and empty and op
end

define sin expr taking op
    ## Creates an expression representing the sine of an expression
    give back new Expression with "sin" and 0 and "" and empty and empty and op
end

define cos expr taking op
    ## Creates an expression representing the cosine of an expression
    give back new Expression with "cos" and 0 and "" and empty and empty and op
end

define ln expr taking op
    ## Creates an expression representing the natural log of an expression
    give back new Expression with "ln" and 0 and "" and empty and empty and op
end

define exp expr taking op
    ## Creates an expression representing e raised to an expression
    give back new Expression with "exp" and 0 and "" and empty and empty and op
end

define derivative of expr taking expr with respect to var
    ## Computes the symbolic derivative of an expression
    let result = expr differentiate var
    give back result simplify
end

define evaluate expr taking expr with bindings
    ## Evaluates an expression with given variable bindings
    ## bindings is a list of [name value] pairs
    give back expr evaluate bindings
end

define simplify expr taking expr
    ## Simplifies an expression using algebraic rules
    give back expr simplify
end

define expression as latex taking expr
    ## Converts an expression to LaTeX format
    if expr type is "number"
        give back expr value as text
    end
    if expr type is "variable"
        give back expr name
    end
    if expr type is "add"
        give back (expression as latex taking expr left) plus " + " plus (expression as latex taking expr right)
    end
    if expr type is "subtract"
        give back (expression as latex taking expr left) plus " - " plus (expression as latex taking expr right)
    end
    if expr type is "multiply"
        let l = expression as latex taking expr left
        let r = expression as latex taking expr right
        if expr left type is "add" or expr left type is "subtract"
            l = "(" plus l plus ")"
        end
        if expr right type is "add" or expr right type is "subtract"
            r = "(" plus r plus ")"
        end
        give back l plus " \\cdot " plus r
    end
    if expr type is "divide"
        give back "\\frac{" plus (expression as latex taking expr left) plus "}{" plus (expression as latex taking expr right) plus "}"
    end
    if expr type is "power"
        let base = expression as latex taking expr left
        if expr left type is "add" or expr left type is "subtract" or expr left type is "multiply" or expr left type is "divide"
            base = "(" plus base plus ")"
        end
        give back base plus "^{" plus (expression as latex taking expr right) plus "}"
    end
    if expr type is "negate"
        give back "-" plus (expression as latex taking expr operand)
    end
    if expr type is "sin"
        give back "\\sin(" plus (expression as latex taking expr operand) plus ")"
    end
    if expr type is "cos"
        give back "\\cos(" plus (expression as latex taking expr operand) plus ")"
    end
    if expr type is "ln"
        give back "\\ln(" plus (expression as latex taking expr operand) plus ")"
    end
    if expr type is "exp"
        give back "e^{" plus (expression as latex taking expr operand) plus "}"
    end
    give back "?"
end

define substitute expr taking expr and var and replacement
    ## Substitutes a variable with an expression throughout an expression tree
    let ne = copy expr
    if ne type is "variable" and ne name is var
        give back replacement
    end
    if ne type is "number" or ne type is "variable"
        give back ne
    end
    if ne type is "add" or ne type is "subtract" or ne type is "multiply" or ne type is "divide" or ne type is "power"
        ne left = substitute expr taking ne left and var and replacement
        ne right = substitute expr taking ne right and var and replacement
        give back ne
    end
    if ne type is "negate" or ne type is "sin" or ne type is "cos" or ne type is "ln" or ne type is "exp"
        ne operand = substitute expr taking ne operand and var and replacement
        give back ne
    end
    give back ne
end

define is expression equal taking a and b
    ## Checks if two expressions are structurally equal
    if a type is not b type
        give back false
    end
    if a type is "number"
        give back a value is b value
    end
    if a type is "variable"
        give back a name is b name
    end
    if a type is "add" or a type is "subtract" or a type is "multiply" or a type is "divide" or a type is "power"
        give back is expression equal taking a left and b left and is expression equal taking a right and b right
    end
    if a type is "negate" or a type is "sin" or a type is "cos" or a type is "ln" or a type is "exp"
        give back is expression equal taking a operand and b operand
    end
    give back false
end

define parse expression taking text
    ## Parses a simple expression string into an expression tree
    ## Supports numbers variables and basic operators
    let tokens = tokenize taking text
    let result = parse addition taking tokens and 0
    give back item 0 of result
end

define tokenize taking text
    ## Splits an expression string into tokens
    let result = list of
    let current = ""
    let i = 1
    repeat while i is less than or equal to size of text
        let ch = item (i minus 1) of text
        if ch is " " or ch is "\t"
            if current is not ""
                add current to result
                current = ""
            end
        else
            if ch is "+" or ch is "-" or ch is "*" or ch is "/" or ch is "^" or ch is "(" or ch is ")"
                if current is not ""
                    add current to result
                    current = ""
                end
                add ch to result
            else
                current = current plus ch
            end
        end
        i = i plus 1
    end
    if current is not ""
        add current to result
    end
    give back result
end

define parse addition taking tokens and pos
    let left result = parse multiplication taking tokens and pos
    let left expr = item 0 of left result
    let p = item 1 of left result
    repeat while p is less than size of tokens
        let op = item p of tokens
        if op is "+" or op is "-"
            let right result = parse multiplication taking tokens and (p plus 1)
            let right expr = item 0 of right result
            p = item 1 of right result
            if op is "+"
                left expr = add expr left expr right expr
            else
                left expr = subtract expr left expr right expr
            end
        else
            repeat while false
            end
        end
    end
    give back list of left expr p
end

define parse multiplication taking tokens and pos
    let left result = parse power taking tokens and pos
    let left expr = item 0 of left result
    let p = item 1 of left result
    repeat while p is less than size of tokens
        let op = item p of tokens
        if op is "*" or op is "/"
            let right result = parse power taking tokens and (p plus 1)
            let right expr = item 0 of right result
            p = item 1 of right result
            if op is "*"
                left expr = multiply expr left expr right expr
            else
                left expr = divide expr left expr right expr
            end
        else
            repeat while false
            end
        end
    end
    give back list of left expr p
end

define parse power taking tokens and pos
    let left result = parse atom taking tokens and pos
    let left expr = item 0 of left result
    let p = item 1 of left result
    if p is less than size of tokens and item p of tokens is "^"
        let right result = parse power taking tokens and (p plus 1)
        let right expr = item 0 of right result
        p = item 1 of right result
        left expr = power expr left expr right expr
    end
    give back list of left expr p
end

define parse atom taking tokens and pos
    if pos is greater than or equal to size of tokens
        give back list of number expr 0 pos
    end
    let token = item pos of tokens
    if token is "("
        let inner result = parse addition taking tokens and (pos plus 1)
        let inner expr = item 0 of inner result
        let p = item 1 of inner result
        give back list of inner expr (p plus 1)
    end
    if token is "-"
        let next result = parse atom taking tokens and (pos plus 1)
        let next expr = item 0 of next result
        let p = item 1 of next result
        give back list of negate expr next expr p
    end
    if token is "sin"
        let inner result = parse atom taking tokens and (pos plus 1)
        let inner expr = item 0 of inner result
        let p = item 1 of inner result
        give back list of sin expr inner expr p
    end
    if token is "cos"
        let inner result = parse atom taking tokens and (pos plus 1)
        let inner expr = item 0 of inner result
        let p = item 1 of inner result
        give back list of cos expr inner expr p
    end
    if token is "ln"
        let inner result = parse atom taking tokens and (pos plus 1)
        let inner expr = item 0 of inner result
        let p = item 1 of inner result
        give back list of ln expr inner expr p
    end
    if token is "exp"
        let inner result = parse atom taking tokens and (pos plus 1)
        let inner expr = item 0 of inner result
        let p = item 1 of inner result
        give back list of exp expr inner expr p
    end
    if token is "pi"
        give back list of number expr 3.14159 (pos plus 1)
    end
    if token is "e"
        give back list of variable expr "e" (pos plus 1)
    end
    let is num = true
    let i = 1
    repeat while i is less than or equal to size of token
        let ch = item (i minus 1) of token
        if ch is "."
            do nothing
        else
            if ch is less than "0" or ch is greater than "9"
                is num = false
            end
        end
        i = i plus 1
    end
    if is num is true
        give back list of number expr (token as number) (pos plus 1)
    end
    give back list of variable expr token (pos plus 1)
end
