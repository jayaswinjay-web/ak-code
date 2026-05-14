# AK CODE Language Specification

## 1. Core Philosophy

AK CODE reads like a natural English conversation. No prior programming knowledge required. No semicolons. No curly braces. Symbols are minimized.

## 2. Comments

```ak
# This is a single line comment
## This is a documentation comment for the item below it
```

## 3. Variables

```ak
let name = "Alice"          # String
let age = 30                 # Integer
let score = 98.5             # Decimal
let is_active = true         # Boolean
let nothing = empty          # Null/None
```

### Explicit Types

```ak
let name of type text = "Alice"
let age of type number = 25
let height of type decimal = 5.9
let scores of type list of numbers = list of 90 85 78
let middle_name of type maybe text = empty
```

### Constants

```ak
always PI = 3.14159265358979
always MAX_USERS = 1000
```

## 4. Output

```ak
show "Hello world"
show "My name is" name
show "Score is" score "out of 100"
```

## 5. Input

```ak
ask "What is your name" and store in name
ask "Enter a number" and store in value as number
```

## 6. Arithmetic

```ak
let result = 5 plus 3                    # Addition
let difference = 10 minus 4              # Subtraction
let product = 6 times 7                  # Multiplication
let quotient = 20 divided by 4           # Division
let remainder = 17 mod 5                 # Modulo
let squared = 4 to the power of 2        # Exponentiation
let root = square root of 81             # Square root
```

## 7. Conditions

```ak
if age is greater than 18
    show "You are an adult"
else if age is equal to 18
    show "You just became an adult"
else
    show "You are a minor"
end
```

### Comparisons

```ak
if name is "Alice"
if score is not 0
if count is greater than 10
if value is less than 100
if x is between 5 and 10
if list has items
if list is empty
if text contains "hello"
if text starts with "A"
if text ends with "ing"
```

## 8. Loops

```ak
repeat 5 times
    show "Looping"
end

repeat while count is less than 10
    count = count plus 1
end

for each item in my_list
    show item
end

for each key and value in my_map
    show key "maps to" value
end

count from 1 to 10
    show current
end

count from 10 down to 1
    show current
end
```

## 9. Functions

```ak
define greet taking name
    show "Hello" name
end

define add taking a and b
    give back a plus b
end

define is_even taking number
    if number mod 2 is equal to 0
        give back true
    end
    give back false
end
```

### Calling Functions

```ak
greet "Alice"
let sum = add 3 and 5
let result = is_even 4
```

## 10. Lists

```ak
let fruits = list of "apple" "banana" "mango"
add "orange" to fruits
remove "banana" from fruits
let first = first item of fruits
let last = last item of fruits
let count = size of fruits
show item 2 of fruits
```

## 11. Maps

```ak
let person = map
    "name" is "Alice"
    "age" is 30
    "city" is "New York"
end

show person get "name"
person set "email" to "alice@example.com"
```

## 12. Classes

```ak
make kind called Animal
    has name
    has sound
    has age

    when created taking given_name and given_sound
        name = given_name
        sound = given_sound
        age = 0
    end

    behaviour speak
        show name "says" sound
    end

    behaviour grow older
        age = age plus 1
    end
end

make kind called Dog extends Animal
    has breed

    when created taking given_name and given_breed
        parent created with given_name and "Woof"
        breed = given_breed
    end

    behaviour fetch taking item
        show name "fetches the" item
    end
end

let my_dog = new Dog called with "Rex" and "Labrador"
my_dog speak
my_dog fetch "ball"
my_dog grow older
show my_dog age
```

## 13. Error Handling

```ak
try
    let result = divide 10 by user_input
    show result
catch division by zero
    show "Cannot divide by zero"
catch any error as e
    show "Something went wrong:" e message
finally
    show "Done trying"
end
```

## 14. Modules

```ak
bring in math
bring in web server
bring in ai model as AI
bring in my own module called "utils"
```

## 15. Concurrency

```ak
do in background
    let result = fetch data from "https://api.example.com"
    show result
end

wait for all of task1 and task2 and task3
let data = wait for fetch "https://api.example.com"
```

## 16. Generics

```ak
make kind called Box holding type T
    has contents of type T

    behaviour put in taking item of type T
        contents = item
    end

    behaviour take out
        give back contents
    end
end

let my_box = new Box of numbers
my_box put in 42
```

## 17. Pattern Matching

```ak
match score
    when it is 100
        show "Perfect score"
    when it is between 90 and 99
        show "Excellent"
    when it is between 70 and 89
        show "Good"
    when it is less than 70
        show "Needs improvement"
    otherwise
        show "Unknown score"
end
```

## 18. Operator Overloading

```ak
make kind called Vector2D
    has x of type decimal
    has y of type decimal

    behaviour plus taking other of type Vector2D
        give back new Vector2D with x plus other x and y plus other y
    end

    behaviour as text
        give back "(" plus x as text plus "," plus y as text plus ")"
    end
end
```

## 19. Web Development

```ak
make web server called MyApp on port 8080

MyApp when someone visits "/"
    send back page "Welcome to AK WEB"
end

MyApp when someone posts to "/login"
    let username = received data get "username"
    # ... handle login
end

MyApp start listening
```

## 20. AI/ML

```ak
make model called MyClassifier
    layer input of size 784
    layer dense of size 128 with activation "relu"
    layer dropout of rate 0.2
    layer output of size 10 with activation "softmax"
end

train MyClassifier
    using data training_data
    with labels training_labels
    for 50 rounds
    using optimizer "adam"
end

let prediction = MyClassifier predict on my_input
```

## 21. Mathematics

```ak
let expr = formula "x squared plus 2 times x plus 1"
let simplified = simplify expr
solve for x when "x squared minus 4 equals 0"

let data = list of 10 20 30 40 50
show mean of data
show standard deviation of data

plot "x squared" from -10 to 10
```

## 22. Testing

```ak
test suite "Math operations"
    test "addition works"
        let result = 2 plus 2
        expect result to be 4
    end

    test "division by zero raises error"
        expect error when divide 10 by 0
    end
end

run all tests
show test results
```

## 23. Grammar Summary

```
program     = statement*
statement   = let | always | show | ask | if | loop | define
            | give_back | make_kind | new | try | match
            | bring_in | do_bg | wait | plot | train
            | expression

let         = "let" identifier "=" expression
always      = "always" identifier "=" expression
show        = "show" expression+
ask         = "ask" string "and" "store" "in" identifier
if          = "if" expression statement* ("else" "if" expression statement*)*
              ("else" statement*)? "end"
loop        = "repeat" (expression "times" | "while" expression)
              statement* "end"
            | "for" "each" identifier ("and" identifier)?
              "in" expression statement* "end"
            | "count" "from" expression ("to" | "down" "to")
              expression statement* "end"
define      = "define" identifier "taking" (identifier ("and" identifier)*)?
              statement* "end"
make_kind   = "make" "kind" "called" identifier
              ("extends" identifier)?
              ("has" identifier)*
              ("when" "created" "taking" ... )?
              ("behaviour" ...)*
              "end"
```
