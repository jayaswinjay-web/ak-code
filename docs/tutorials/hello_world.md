# Hello, World! — Your First AK CODE Program

Welcome to AK CODE! In this tutorial, you'll write and run your first program.

## What You'll Learn

- How to write a simple AK CODE program
- How to compile it with the AK CODE compiler
- How to run the compiled binary

## Step 1: Write the Program

Create a file called `hello.ak`:

```
# My first AK CODE program
## This program says hello to the world

let name = "World"
show "Hello" name

let age = 30
show "You are" age "years old"

let score = 95.5
show "Your score is" score
```

## Step 2: Compile

If you've built the bootstrap compiler:

```bash
./build/akc hello.ak -o hello
```

Or if using the self-hosted compiler:

```bash
akc hello.ak -o hello
```

## Step 3: Run

**Linux:**
```bash
./hello
```

**Windows:**
```cmd
hello.exe
```

## Expected Output

```
Hello World
You are 30 years old
Your score is 95.5
```

## Understanding the Code

- `#` starts a comment — it's ignored by the compiler
- `##` is a documentation comment
- `let name = "World"` creates a variable called `name` with the value `"World"`
- `show "Hello" name` prints "Hello" followed by the value of `name`
- Numbers like `30` and `95.5` don't need quotes
- Multiple values in `show` are printed with spaces between them

## Next Steps

- Try changing the values and see what happens
- Add a second `show` statement
- Try the [Web App Tutorial](../tutorials/web_app.md) to build a web server
