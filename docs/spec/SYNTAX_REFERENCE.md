# AK CODE Syntax Reference — Quick Reference Card

## Comments
```
# line comment
## doc comment
```

## Variables
```
let name = value
always NAME = value
let name of type text = value
let name of type number = value
```

## Output / Input
```
show expr1 expr2 ...
ask "prompt" and store in var
ask "prompt" and store in var as number
```

## Arithmetic Operators
```
a plus b             # addition
a minus b            # subtraction
a times b            # multiplication
a divided by b       # division
a mod b              # modulo
a to the power of b  # exponentiation
square root of a     # square root
```

## Comparisons
```
x is value
x is not value
x is greater than y
x is less than y
x is between a and b
list has items
list is empty
text contains "substring"
text starts with "prefix"
text ends with "suffix"
```

## Conditionals
```
if condition
    ...
else if condition
    ...
else
    ...
end
```

## Loops
```
repeat N times
    ...
end

repeat while condition
    ...
end

for each item in list
    ...
end

for each key and value in map
    ...
end

count from start to end
    ...
end

count from start down to end
    ...
end
```

## Functions
```
define name taking param1 and param2
    ...
    give back value
end
```

## Classes
```
make kind called Name
    has property
    when created taking args
        ...
    end
    behaviour name taking args
        ...
    end
end
```

## Lists
```
list of item1 item2 item3
add item to list
remove item from list
first item of list
last item of list
size of list
item N of list
```

## Maps
```
map
    key is value
    key is value
end
map get key
map set key to value
```

## Error Handling
```
try
    ...
catch error_type
    ...
catch any error as e
    ...
finally
    ...
end
```

## Pattern Matching
```
match expr
    when it is value
        ...
    when it is between a and b
        ...
    otherwise
        ...
end
```

## Modules & Imports
```
bring in module_name
bring in module_name as alias
bring in "path/to/module"
```

## Concurrency
```
do in background
    ...
end

wait for expr
wait for all of task1 and task2
```

## Math
```
formula "expression"
simplify expr
solve for x when "equation"
differentiate expr with respect to x
integrate expr from a to b
mean of data
median of data
standard deviation of data
plot "function" from a to b
```

## AI/ML
```
make model called Name
    layer type of size N [with params]
end

train Model using data with labels for N rounds
Model predict on input
```

## Web (Backend)
```
make web server called Name on port N
Name when someone visits "/path"
    send back page "..."
end
Name start listening
```

## Web (Frontend)
```
make page called Name
    title is "..."
    show big heading "..."
    make button called name with text "..."
    when name is clicked
        ...
    end
end
show page Name
```

## Database
```
connect to database "path"
make table called Name
    column name as type [constraints]
end
create table Name in database
add to Name values key is value end
find all from Name where condition
```

## Testing
```
test suite "name"
    test "description"
        expect expr to be value
        expect error when expr
    end
end
run all tests
```
