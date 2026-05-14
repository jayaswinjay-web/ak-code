# Building a Web App with AK CODE

This tutorial shows how to build a simple web application with AK CODE.

## What You'll Build

A todo list web application with:
- A web page to view tasks
- Ability to add new tasks
- Tasks stored in a database

## Prerequisites

- AK CODE compiler installed
- Basic familiarity with AK CODE syntax (see Hello World tutorial)

## Step 1: Import Modules

```
bring in web server
bring in database
```

## Step 2: Set Up the Database

```
connect to database "todos.akdb"

make table called Todos
    column id as unique number auto increment
    column task as text required
    column done as true or false default false
    column created at as timestamp default now
end

create table Todos in database
```

## Step 3: Create the Web Server

```
make web server called TodoApp on port 3000

TodoApp when someone visits "/"
    let todos = find all from Todos
    send back page
        show big heading "My Todo List"
        for each todo in todos
            show checkbox todo done with label todo task
        end
        make input called new_task with placeholder "Add a task"
        make button called add_btn with text "Add"
        when add_btn is clicked
            send to server "/add" the data task is new_task value
        end
    end
end
```

## Step 4: Handle Adding Tasks

```
TodoApp when someone posts to "/add"
    let task = received data get "task"
    add to Todos the values
        task is task
    end
    send back message "Task added"
end
```

## Step 5: Handle Task Completion

```
TodoApp when someone posts to "/complete"
    let todo id = received data get "id"
    find first from Todos where id is todo id
    update Todos set done to true where id is todo id
    send back message "Task completed"
end
```

## Step 6: Start the Server

```
TodoApp start listening
show "Todo app running on port 3000"
```

## Full Program

Here's the complete program:

```
bring in web server
bring in database

connect to database "todos.akdb"

make table called Todos
    column id as unique number auto increment
    column task as text required
    column done as true or false default false
    column created at as timestamp default now
end

create table Todos in database

make web server called TodoApp on port 3000

TodoApp when someone visits "/"
    let todos = find all from Todos
    send back page
        show big heading "My Todo List"
        for each todo in todos
            show checkbox todo done with label todo task
        end
        make input called new_task with placeholder "Add a task"
        make button called add_btn with text "Add"
        when add_btn is clicked
            send to server "/add" the data task is new_task value
        end
    end
end

TodoApp when someone posts to "/add"
    let task = received data get "task"
    add to Todos the values task is task end
    send back message "Task added"
end

TodoApp start listening
show "Todo app running on port 3000"
```

## Running the App

```bash
akc todo_app.ak -o todo_app
./todo_app
```

Then open your browser to `http://localhost:3000`.

## What's Next

- Add user authentication
- Style your pages with CSS
- Connect to a real database
- Try the [AI Training Tutorial](train_ai.md)
