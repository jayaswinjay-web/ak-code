## AK CODE SQL Module — relational database operations
## Provides SQL database creation, querying, and management

make kind called SQLDatabase
    has path of type text
    has tables of type map
    has connected of type bool

    when created taking db path
        path = db path
        tables = map end
        connected = false
    end

    behaviour connect
        connected = true
        show "Connected to database:" path
    end

    behaviour disconnect
        connected = false
        show "Disconnected from database:" path
    end

    behaviour create table taking name and columns
        let table = new SQLTable
        table name = name
        table columns = columns
        tables set name to table
        show "Created table:" name
    end

    behaviour table exists taking name
        if tables get name is not empty
            give back true
        end
        give back false
    end

    behaviour execute taking query
        show "Executing SQL:" query
        # Parse and execute SQL query
        give back empty
    end

    behaviour query taking sql
        show "Querying:" sql
        give back list of
    end
end

make kind called SQLColumn
    has name of type text
    has type of type text
    has constraints of type list of text

    when created taking col name and col type
        name = col name
        type = col type
        constraints = list of
    end

    behaviour add constraint taking constraint
        add constraint to constraints
    end

    behaviour is unique
        for each c in constraints
            if c is "unique"
                give back true
            end
        end
        give back false
    end

    behaviour is required
        for each c in constraints
            if c is "required"
                give back true
            end
        end
        give back false
    end
end

make kind called SQLTable
    has name of type text
    has columns of type list of SQLColumn
    has rows of type list of map

    when created
        columns = list of
        rows = list of
    end

    behaviour add column taking col of type SQLColumn
        add col to columns
    end

    behaviour insert taking values
        add values to rows
    end

    behaviour select all
        give back rows
    end

    behaviour select where taking condition
        let result = list of
        for each row in rows
            if condition row
                add row to result
            end
        end
        give back result
    end

    behaviour update set taking updates where condition
        for each row in rows
            if condition row
                for each key and value in updates
                    row set key to value
                end
            end
        end
    end

    behaviour delete where taking condition
        let result = list of
        for each row in rows
            if condition row is not true
                add row to result
            end
        end
        rows = result
    end

    behaviour count
        give back size of rows
    end
end

define connect to database taking path
    ## Connect to a database
    let db = new SQLDatabase with path
    db connect
    give back db
end

define make table called taking name
    ## Start a table definition
    let table = new SQLTable
    table name = name
    give back table
end

define column taking name as type
    ## Define a column in a table
    let col = new SQLColumn with name and type
    give back col
end

define find all from taking table where condition
    ## Find all rows matching a condition
    give back table select where condition
end

define find first from taking table where condition
    ## Find the first row matching a condition
    let results = table select where condition
    if size of results is greater than 0
        give back item 0 of results
    end
    give back empty
end

define add to taking table the values
    ## Insert a row into a table
    table insert values
end

define update taking table set values where condition
    ## Update rows in a table
    table update set values where condition
end

define remove from taking table where condition
    ## Delete rows from a table
    table delete where condition
end
