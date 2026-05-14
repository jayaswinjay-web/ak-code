# AK CODE Standard Library API Reference

## Core Modules

### io.ak — Input/Output

| Function | Description | Example |
|----------|-------------|---------|
| `print message` | Print with newline | `print "Hello"` |
| `read line` | Read from stdin | `let input = read line` |
| `read file path` | Read entire file | `let content = read file "data.txt"` |
| `write file path with content` | Write to file | `write file "out.txt" with "data"` |
| `append to file path with content` | Append to file | `append to file "log.txt" with "entry"` |
| `file exists path` | Check file existence | `if file exists "test.txt"` |
| `delete file path` | Delete a file | `delete file "temp.txt"` |
| `prompt message` | Show and read input | `let name = prompt "Name?"` |
| `confirm message` | Yes/no question | `if confirm "Continue?"` |

### string.ak — Text Manipulation

| Function | Description | Example |
|----------|-------------|---------|
| `length of str` | Get string length | `length of "hello"` |
| `uppercase str` | Convert to uppercase | `uppercase "hello"` |
| `lowercase str` | Convert to lowercase | `lowercase "HELLO"` |
| `trim str` | Remove whitespace | `trim "  hi  "` |
| `split str by delim` | Split into list | `split "a,b" by ","` |
| `join parts with sep` | Join list into string | `join list with ","` |
| `replace search in text with rep` | Replace substring | `replace "old" in text with "new"` |
| `contains substr in text` | Check substring | `contains "hi" in "hello hi"` |
| `starts with prefix in text` | Check prefix | `starts with "he" in "hello"` |
| `ends with suffix in text` | Check suffix | `ends with "lo" in "hello"` |
| `substring of text from i to len` | Extract substring | `substring of "hello" from 1 to 3` |
| `reverse str` | Reverse string | `reverse "hello"` |
| `is empty str` | Check empty string | `if is empty str` |
| `is number str` | Check numeric string | `if is number "42"` |
| `to number str` | Convert to number | `let n = to number "42"` |

### list.ak — Dynamic Arrays

| Function | Description | Example |
|----------|-------------|---------|
| `is empty lst` | Check empty list | `if is empty my_list` |
| `has items lst` | Check non-empty | `if has items my_list` |
| `first of lst` | First element | `let f = first of items` |
| `last of lst` | Last element | `let l = last of items` |
| `rest of lst` | All but first | `let r = rest of items` |
| `push item to lst` | Add to end | `push "x" to my_list` |
| `pop from lst` | Remove from end | `let x = pop from my_list` |
| `contains value in lst` | Check membership | `if contains "x" in list` |
| `index of value in lst` | Find index | `let i = index of "x" in list` |
| `map fn over lst` | Transform | `map double over numbers` |
| `filter pred over lst` | Filter | `filter is_even over numbers` |
| `reduce fn over lst with init` | Aggregate | `reduce add over numbers with 0` |
| `sort lst` | Sort in place | `sort my_list` |
| `unique lst` | Remove duplicates | `let u = unique my_list` |
| `flatten lst` | Flatten nested | `let f = flatten nested_list` |

### number.ak — Mathematics

| Function | Description |
|----------|-------------|
| `to the power of base and exp` | Exponentiation |
| `square root of x` | Square root |
| `absolute x` | Absolute value |
| `floor x` | Round down |
| `ceiling x` | Round up |
| `round x` | Round to integer |
| `round to x and decimals` | Round to decimal places |
| `sin x` | Sine (radians) |
| `cos x` | Cosine (radians) |
| `tan x` | Tangent |
| `exp x` | e^x |
| `ln x` | Natural logarithm |
| `log base and x` | Logarithm with base |
| `min a and b` | Minimum |
| `max a and b` | Maximum |
| `clamp value and min and max` | Clamp value |
| `random` | Random 0-1 |
| `random between min and max` | Random in range |

### map.ak — Dictionaries

| Function | Description |
|----------|-------------|
| `map get key` | Get value by key |
| `map set key to value` | Set value |
| `map has key` | Check key existence |
| `map remove key` | Remove entry |
| `map keys` | List of keys |
| `map values` | List of values |
| `map size` | Number of entries |

### error.ak — Error Handling

| Function | Description |
|----------|-------------|
| `throw message` | Throw error |
| `throw with code message and code` | Throw with error code |
| `try operation action and handler` | Safe execution |
| `assert condition and message` | Assertion |
| `assert equal expected and actual` | Equality assertion |

## Math Modules

### algebra.ak

| Function | Description |
|----------|-------------|
| `solve linear a and b` | Solve ax+b=0 |
| `solve quadratic a and b and c` | Solve ax^2+bx+c=0 |
| `factorial n` | n! |
| `fibonacci n` | nth Fibonacci |
| `gcd a and b` | Greatest common divisor |
| `lcm a and b` | Least common multiple |
| `is prime n` | Primality test |
| `binomial n and k` | C(n,k) |

### calculus.ak

| Function | Description |
|----------|-------------|
| `derivative of f at x` | Numerical derivative |
| `integrate from a to b of f` | Definite integral |
| `limit of f at x` | Limit |
| `root find f and guess` | Newton's method |

### matrix.ak

| Type | Description |
|------|-------------|
| `Matrix(rows, cols)` | Matrix type |
| `matrix add other` | Matrix addition |
| `matrix multiply other` | Matrix multiplication |
| `matrix scale factor` | Scalar multiplication |
| `matrix transpose` | Transpose |
| `matrix determinant` | Determinant |
| `matrix inverse` | Matrix inverse |

## Web Modules

### http_server.ak

| Type/Function | Description |
|---------------|-------------|
| `HTTPServer(port)` | Create server |
| `server when someone visits path handler` | GET route |
| `server when someone posts to path handler` | POST route |
| `server start listening` | Start server |
| `HTTPRequest` | Request object |
| `HTTPResponse` | Response object |
| `send back page content` | HTML response |
| `send back json data` | JSON response |
| `send back message text` | Text response |

### json.ak

| Function | Description |
|----------|-------------|
| `json serialize value` | Encode to JSON |
| `json parse text` | Decode from JSON |

## AI Modules

### tensor.ak

| Type/Function | Description |
|---------------|-------------|
| `Tensor(shape)` | Multi-dimensional array |
| `tensor fill value` | Fill with value |
| `tensor add other` | Element-wise add |
| `tensor multiply other` | Element-wise multiply |
| `tensor dot other` | Matrix multiply |
| `tensor reshape new_shape` | Reshape tensor |

### model.ak

| Construct | Description |
|-----------|-------------|
| `make model called Name` | Define model |
| `layer input of size N` | Input layer |
| `layer dense of size N` | Dense layer |
| `layer dropout of rate R` | Dropout layer |
| `layer output of size N with activation A` | Output layer |

### optimizer.ak

| Type | Description |
|------|-------------|
| `SGD(learning_rate)` | Stochastic Gradient Descent |
| `Adam(learning_rate)` | Adam optimizer |
| `AdaGrad(learning_rate)` | AdaGrad optimizer |
| `RMSProp(learning_rate)` | RMSProp optimizer |

## OS Modules

### thread.ak

| Function | Description |
|----------|-------------|
| `create thread fn` | Create thread |
| `join thread t` | Wait for thread |
| `mutex create` | Create mutex |
| `mutex lock m` | Lock mutex |
| `mutex unlock m` | Unlock mutex |

### process.ak

| Function | Description |
|----------|-------------|
| `run command` | Execute command |
| `get pid` | Current process ID |
| `sleep ms` | Sleep milliseconds |
| `exit code` | Exit with code |
