## AK CODE ORM Module — object-relational mapping
## Provides table mapping, query building, relationships, and migrations

make kind called ColumnMapping
    has column name of type text
    has field name of type text
    has type of type text
    has primary key of type bool
    has auto increment of type bool
    has nullable of type bool
    has default value

    when created taking col name and col type
        column name = col name
        field name = col name
        type = col type
        primary key = false
        auto increment = false
        nullable = true
        default value = empty
    end

    behaviour as primary key
        primary key = true
        nullable = false
        give back this
    end

    behaviour as auto increment
        auto increment = true
        primary key = true
        nullable = false
        give back this
    end

    behaviour as not null
        nullable = false
        give back this
    end

    behaviour default taking value
        default value = value
        give back this
    end

    behaviour map to taking name
        field name = name
        give back this
    end
end

make kind called Relationship
    has type of type text
    has target model of type text
    has foreign key of type text
    has local key of type text

    when created taking rel type and target and fk and lk
        type = rel type
        target model = target
        foreign key = fk
        local key = lk
    end
end

make kind called Model
    has table name of type text
    has columns of type list of ColumnMapping
    has relationships of type map
    has data of type map
    has is new of type bool

    when created taking name
        table name = name
        columns = list of
        relationships = map end
        data = map end
        is new = true
    end

    behaviour column taking col name as col type
        let mapping = new ColumnMapping with col name and col type
        add mapping to columns
        give back mapping
    end

    behaviour has one taking target and fk and lk
        let rel = new Relationship with "has_one" and target and fk and lk
        relationships set target to rel
    end

    behaviour has many taking target and fk and lk
        let rel = new Relationship with "has_many" and target and fk and lk
        relationships set target to rel
    end

    behaviour belongs to taking target and fk and lk
        let rel = new Relationship with "belongs_to" and target and fk and lk
        relationships set target to rel
    end

    behaviour set taking field and value
        data set field to value
    end

    behaviour get taking field
        give back data get field
    end

    behaviour primary key column
        for each col in columns
            if col primary key
                give back col
            end
        end
        give back empty
    end

    behaviour primary key value
        let pk = this primary key column
        if pk is not empty
            give back data get pk field name
        end
        give back empty
    end
end

make kind called QueryBuilder
    has model of type Model
    has conditions of type list of map
    has order field of type text
    has order direction of type text
    has limit count of type number
    has offset count of type number
    has selected fields of type list of text

    when created taking target model
        model = target model
        conditions = list of
        order field = ""
        order direction = "asc"
        limit count = 0
        offset count = 0
        selected fields = list of
    end

    behaviour where taking field and op and value
        let condition = map end
        condition set "field" to field
        condition set "op" to op
        condition set "value" to value
        add condition to conditions
        give back this
    end

    behaviour where equal taking field and value
        give back this where field and "=" and value
    end

    behaviour where not taking field and value
        give back this where field and "!=" and value
    end

    behaviour where greater taking field and value
        give back this where field and ">" and value
    end

    behaviour where less taking field and value
        give back this where field and "<" and value
    end

    behaviour where in taking field and values
        give back this where field and "in" and values
    end

    behaviour where like taking field and pattern
        give back this where field and "like" and pattern
    end

    behaviour order by taking field and direction
        order field = field
        order direction = direction
        give back this
    end

    behaviour limit taking n
        limit count = n
        give back this
    end

    behaviour offset taking n
        offset count = n
        give back this
    end

    behaviour select taking fields
        selected fields = fields
        give back this
    end

    behaviour to sql
        let sql = "SELECT "
        if size of selected fields is greater than 0
            let first = true
            for each f in selected fields
                if first is not true
                    sql = sql plus ", "
                end
                sql = sql plus f
                first = false
            end
        else
            sql = sql plus "*"
        end
        sql = sql plus " FROM " plus model table name
        if size of conditions is greater than 0
            sql = sql plus " WHERE "
            let first = true
            for each cond in conditions
                if first is not true
                    sql = sql plus " AND "
                end
                let field = cond get "field"
                let op = cond get "op"
                let value = cond get "value"
                sql = sql plus field plus " " plus op
                if value kind is text
                    sql = sql plus " '" plus value plus "'"
                else
                    sql = sql plus " " plus value as text
                end
                first = false
            end
        end
        if order field is not ""
            sql = sql plus " ORDER BY " plus order field plus " " plus order direction
        end
        if limit count is greater than 0
            sql = sql plus " LIMIT " plus limit count as text
        end
        if offset count is greater than 0
            sql = sql plus " OFFSET " plus offset count as text
        end
        give back sql
    end

    behaviour build insert taking values
        let sql = "INSERT INTO " plus model table name plus " ("
        let fields list = list of
        let values list = list of
        for each key and val in values
            add key to fields list
            if val kind is text
                add "'" plus val plus "'" to values list
            else
                add val as text to values list
            end
        end
        let first = true
        for each f in fields list
            if first is not true
                sql = sql plus ", "
            end
            sql = sql plus f
            first = false
        end
        sql = sql plus ") VALUES ("
        first = true
        for each v in values list
            if first is not true
                sql = sql plus ", "
            end
            sql = sql plus v
            first = false
        end
        sql = sql plus ")"
        give back sql
    end

    behaviour build update taking values
        let sql = "UPDATE " plus model table name plus " SET "
        let first = true
        for each key and val in values
            if first is not true
                sql = sql plus ", "
            end
            sql = sql plus key plus " = "
            if val kind is text
                sql = sql plus "'" plus val plus "'"
            else
                sql = sql plus val as text
            end
            first = false
        end
        if size of conditions is greater than 0
            sql = sql plus " WHERE "
            first = true
            for each cond in conditions
                if first is not true
                    sql = sql plus " AND "
                end
                let field = cond get "field"
                let op = cond get "op"
                let value = cond get "value"
                sql = sql plus field plus " " plus op
                if value kind is text
                    sql = sql plus " '" plus value plus "'"
                else
                    sql = sql plus " " plus value as text
                end
                first = false
            end
        end
        give back sql
    end

    behaviour build delete
        let sql = "DELETE FROM " plus model table name
        if size of conditions is greater than 0
            sql = sql plus " WHERE "
            let first = true
            for each cond in conditions
                if first is not true
                    sql = sql plus " AND "
                end
                let field = cond get "field"
                let op = cond get "op"
                let value = cond get "value"
                sql = sql plus field plus " " plus op
                if value kind is text
                    sql = sql plus " '" plus value plus "'"
                else
                    sql = sql plus " " plus value as text
                end
                first = false
            end
        end
        give back sql
    end
end

make kind called Migration
    has name of type text
    has up actions of type list of map
    has down actions of type list of map

    when created taking migration name
        name = migration name
        up actions = list of
        down actions = list of
    end

    behaviour create table taking table name and columns
        let action = map end
        action set "type" to "create_table"
        action set "table" to table name
        action set "columns" to columns
        add action to up actions

        let undo = map end
        undo set "type" to "drop_table"
        undo set "table" to table name
        add undo to down actions
    end

    behaviour add column taking table name and column def
        let action = map end
        action set "type" to "add_column"
        action set "table" to table name
        action set "column" to column def
        add action to up actions

        let undo = map end
        undo set "type" to "drop_column"
        undo set "table" to table name
        undo set "column" to column def get "name"
        add undo to down actions
    end

    behaviour drop table taking table name
        let action = map end
        action set "type" to "drop_table"
        action set "table" to table name
        add action to up actions
    end

    behaviour rename table taking old name and new name
        let action = map end
        action set "type" to "rename_table"
        action set "old" to old name
        action set "new" to new name
        add action to up actions
    end

    behaviour create index taking table name and column name and unique
        let action = map end
        action set "type" to "create_index"
        action set "table" to table name
        action set "column" to column name
        action set "unique" to unique
        add action to up actions
    end

    behaviour run up
        show "Running migration up:" name
        for each action in up actions
            let type = action get "type"
            if type is "create_table"
                show "  Creating table:" action get "table"
            else if type is "add_column"
                show "  Adding column:" action get "column" get "name" to action get "table"
            else if type is "drop_table"
                show "  Dropping table:" action get "table"
            else if type is "rename_table"
                show "  Renaming table:" action get "old" to action get "new"
            else if type is "create_index"
                show "  Creating index on:" action get "table" "." action get "column"
            end
        end
    end

    behaviour run down
        show "Running migration down:" name
        for each action in down actions
            let type = action get "type"
            if type is "drop_table"
                show "  Dropping table:" action get "table"
            else if type is "drop_column"
                show "  Dropping column:" action get "column" from action get "table"
            end
        end
    end
end

make kind called MigrationManager
    has migrations of type list of Migration
    has applied of type list of text
    has history of type list of map

    when created
        migrations = list of
        applied = list of
        history = list of
    end

    behaviour register taking migration
        add migration to migrations
    end

    behaviour migrate
        show "Running pending migrations..."
        for each migration in migrations
            if contains migration name in applied is not true
                migration run up
                add migration name to applied
                let entry = map end
                entry set "name" to migration name
                entry set "timestamp" to now
                add entry to history
                show "Applied:" migration name
            end
        end
    end

    behaviour rollback taking count
        if count is 0
            count = 1
        end
        let i = 0
        let reversed = list of
        for each m in migrations
            add m to reversed
        end
        # Reverse the list
        let n = size of reversed
        let j = 0
        repeat while j is less than n divided by 2
            let temp = item j of reversed
            let last idx = n minus j minus 1
            set item j of reversed to item last idx of reversed
            set item last idx of reversed to temp
            j = j plus 1
        end
        for each migration in reversed
            if i is less than count and contains migration name in applied
                migration run down
                remove migration name from applied
                i = i plus 1
            end
        end
    end

    behaviour status
        show "Migration Status:"
        for each migration in migrations
            let status = "pending"
            if contains migration name in applied
                status = "applied"
            end
            show "  " migration name " [" status "]"
        end
    end
end

make kind called ORM
    has models of type map
    has connection of type text
    has migrations of type MigrationManager

    when created taking db connection
        connection = db connection
        models = map end
        migrations = new MigrationManager
    end

    behaviour register taking model
        models set model table name to model
    end

    behaviour get model taking name
        let model = models get name
        if model is empty
            show "Error: Model not found:" name
            give back empty
        end
        give back model
    end

    behaviour query on taking model name
        let model = this get model model name
        if model is empty
            give back empty
        end
        give back new QueryBuilder with model
    end

    behaviour save taking model and values
        let builder = new QueryBuilder with model
        let sql = builder build insert values
        show "Executing:" sql
        if model is new is not true
            let pk = model primary key column
            if pk is not empty
                let pk val = model primary key value
                if pk val is not empty
                    let update builder = new QueryBuilder with model
                    update builder where equal pk column name and pk val
                    sql = update builder build update values
                    show "Executing:" sql
                end
            end
        end
    end

    behaviour delete taking model where conditions
        let builder = new QueryBuilder with model
        for each key and value in conditions
            builder where equal key and value
        end
        let sql = builder build delete
        show "Executing:" sql
    end

    behaviour create migration taking name
        let migration = new Migration with name
        migrations register migration
        give back migration
    end

    behaviour run migrations
        migrations migrate
    end

    behaviour rollback taking count
        migrations rollback count
    end

    behaviour migration status
        migrations status
    end

    behaviour load related taking model and relation name
        let rel = model relationships get relation name
        if rel is empty
            show "Error: Relationship not found:" relation name
            give back empty
        end
        let target model = models get rel target model
        if target model is empty
            show "Error: Target model not found:" rel target model
            give back empty
        end
        let local val = model get rel local key
        if local val is empty
            give back empty
        end
        let builder = new QueryBuilder with target model
        builder where equal rel foreign key and local val
        if rel type is "has_one"
            builder limit 1
            give back builder
        end
        give back builder
    end
end

define define model taking table name
    ## Create a new model definition
    give back new Model with table name
end

define define migration taking name
    ## Create a new migration
    give back new Migration with name
end

define create orm taking connection
    ## Create a new ORM instance
    give back new ORM with connection
end

define query taking model name in orm
    ## Start a query on a model
    give back orm query on model name
end
