## AK CODE NoSQL Module — document database operations
## Provides MongoDB-like document database with collections, queries, and indexing

make kind called ObjectId
    has value of type text

    when created
        value = ""
        let i = 0
        repeat while i is less than 24
            let hex chars = "0123456789abcdef"
            let index = random times 16
            value = value plus character at index of hex chars
            i = i plus 1
        end
    end
end

make kind called Document
    has data of type map
    has id of type text

    when created taking values
        data = values
        let oid = new ObjectId
        id = oid value
        data set "_id" to id
    end

    behaviour get taking key
        give back data get key
    end

    behaviour set taking key and value
        data set key to value
    end

    behaviour has taking key
        if data get key is not empty
            give back true
        end
        give back false
    end

    behaviour keys
        give back data keys
    end

    behaviour to json
        give back data
    end
end

make kind called Index
    has field name of type text
    has unique of type bool
    has entries of type map

    when created taking field and is unique
        field name = field
        unique = is unique
        entries = map end
    end

    behaviour add taking doc id and field value
        let existing = entries get field value
        if existing is empty
            entries set field value to list of doc id
        else
            if unique and size of existing is greater than 0
                show "Duplicate key error on:" field name
                give back false
            end
            add doc id to existing
        end
        give back true
    end

    behaviour remove taking doc id and field value
        let existing = entries get field value
        if existing is not empty
            remove doc id from existing
            if size of existing is 0
                entries delete field value
            end
        end
    end

    behaviour lookup taking value
        give back entries get value
    end
end

make kind called Collection
    has name of type text
    has documents of type list of Document
    has indexes of type map

    when created taking collection name
        name = collection name
        documents = list of
        indexes = map end
    end

    behaviour insert taking data
        let doc = new Document with data
        add doc to documents
        for each key and idx in indexes
            let field val = doc get key
            if field val is not empty
                idx add doc id and field val
            end
        end
        give back doc id
    end

    behaviour insert many taking docs
        let ids = list of
        for each doc data in docs
            let id = this insert doc data
            add id to ids
        end
        give back ids
    end

    behaviour find taking query
        let results = list of
        for each doc in documents
            if matches query with doc
                add doc to results
            end
        end
        give back results
    end

    behaviour find one taking query
        for each doc in documents
            if matches query with doc
                give back doc
            end
        end
        give back empty
    end

    behaviour find by id taking doc id
        for each doc in documents
            if doc id is doc id
                give back doc
            end
        end
        give back empty
    end

    behaviour update taking query with changes
        let count = 0
        for each doc in documents
            if matches query with doc
                for each key and value in changes
                    doc set key to value
                end
                count = count plus 1
            end
        end
        give back count
    end

    behaviour update one taking query with changes
        for each doc in documents
            if matches query with doc
                for each key and value in changes
                    doc set key to value
                end
                give back 1
            end
        end
        give back 0
    end

    behaviour delete taking query
        let remaining = list of
        let count = 0
        for each doc in documents
            if matches query with doc
                count = count plus 1
            else
                add doc to remaining
            end
        end
        documents = remaining
        give back count
    end

    behaviour delete one taking query
        let remaining = list of
        let found = false
        for each doc in documents
            if matches query with doc and found is not true
                found = true
            else
                add doc to remaining
            end
        end
        documents = remaining
        if found
            give back 1
        end
        give back 0
    end

    behaviour delete all
        let count = size of documents
        documents = list of
        give back count
    end

    behaviour count
        give back size of documents
    end

    behaviour count where taking query
        let count = 0
        for each doc in documents
            if matches query with doc
                count = count plus 1
            end
        end
        give back count
    end

    behaviour create index taking field and is unique
        let idx = new Index with field and is unique
        indexes set field to idx
        for each doc in documents
            let field val = doc get field
            if field val is not empty
                idx add doc id and field val
            end
        end
    end

    behaviour drop index taking field
        indexes delete field
    end

    behaviour list indexes
        give back indexes keys
    end

    behaviour aggregate taking pipeline
        let results = documents
        for each stage in pipeline
            let stage type = stage get "type"
            if stage type is "match"
                let query = stage get "query"
                results = filter results with query
            else if stage type is "sort"
                let field = stage get "field"
                let order = stage get "order"
                results = sort results by field and order
            else if stage type is "limit"
                let n = stage get "count"
                results = slice results to n
            else if stage type is "project"
                let fields = stage get "fields"
                results = project results to fields
            end
        end
        give back results
    end
end

make kind called NoSQLDatabase
    has name of type text
    has collections of type map
    has connected of type bool

    when created taking db name
        name = db name
        collections = map end
        connected = false
    end

    behaviour connect
        connected = true
        show "Connected to NoSQL database:" name
    end

    behaviour disconnect
        connected = false
        show "Disconnected from NoSQL database:" name
    end

    behaviour create collection taking collection name
        if connected is not true
            show "Error: Not connected to database"
            give back empty
        end
        let col = new Collection with collection name
        collections set collection name to col
        show "Created collection:" collection name
        give back col
    end

    behaviour get collection taking collection name
        let col = collections get collection name
        if col is empty
            show "Error: Collection not found:" collection name
            give back empty
        end
        give back col
    end

    behaviour drop collection taking collection name
        collections delete collection name
        show "Dropped collection:" collection name
    end

    behaviour list collections
        give back collections keys
    end

    behaviour collection exists taking collection name
        if collections get collection name is not empty
            give back true
        end
        give back false
    end
end

define matches query with doc
    ## Check if a document matches a query map
    if query is empty
        give back true
    end
    for each key and expected in query
        let value = doc get key
        if expected kind is map
            for each op and operand in expected
                if op is "$gt"
                    if value is not greater than operand
                        give back false
                    end
                else if op is "$gte"
                    if value is not greater than or equal to operand
                        give back false
                    end
                else if op is "$lt"
                    if value is not less than operand
                        give back false
                    end
                else if op is "$lte"
                    if value is not less than or equal to operand
                        give back false
                    end
                else if op is "$ne"
                    if value is operand
                        give back false
                    end
                else if op is "$in"
                    if contains value in operand is not true
                        give back false
                    end
                else if op is "$nin"
                    if contains value in operand
                        give back false
                    end
                else if op is "$exists"
                    if operand
                        if doc has key is not true
                            give back false
                        end
                    else
                        if doc has key
                            give back false
                        end
                    end
                else if op is "$regex"
                    if value is not match operand
                        give back false
                    end
                end
            end
        else
            if value is not expected
                give back false
            end
        end
    end
    give back true
end

define filter results with query
    ## Filter a list of documents by query
    let filtered = list of
    for each doc in results
        if matches query with doc
            add doc to filtered
        end
    end
    give back filtered
end

define sort results by field and order
    ## Sort documents by a field
    let sorted = results
    let n = size of sorted
    let i = 0
    repeat while i is less than n
        let j = 0
        repeat while j is less than n minus i minus 1
            let doc a = item j of sorted
            let doc b = item j plus 1 of sorted
            let val a = doc a get field
            let val b = doc b get field
            if order is 1
                if val a is greater than val b
                    set item j of sorted to doc b
                    set item j plus 1 of sorted to doc a
                end
            else
                if val a is less than val b
                    set item j of sorted to doc b
                    set item j plus 1 of sorted to doc a
                end
            end
            j = j plus 1
        end
        i = i plus 1
    end
    give back sorted
end

define slice results to n
    ## Limit results to n documents
    if size of results is less than or equal to n
        give back results
    end
    let sliced = list of
    let i = 0
    repeat while i is less than n
        add item i of results to sliced
        i = i plus 1
    end
    give back sliced
end

define project results to fields
    ## Project only specified fields from documents
    let projected = list of
    for each doc in results
        let new data = map end
        for each field in fields
            let value = doc get field
            if value is not empty
                new data set field to value
            end
        end
        let new doc = new Document with new data
        add new doc to projected
    end
    give back projected
end

define connect to nosql taking name
    ## Connect to a NoSQL database by name
    let db = new NoSQLDatabase with name
    db connect
    give back db
end

define create collection named taking name in db
    ## Create a new collection in the database
    give back db create collection name
end

define insert into taking collection the doc
    ## Insert a document into a collection
    give back collection insert doc
end

define find in taking collection where query
    ## Find documents matching a query
    give back collection find query
end

define find one in taking collection where query
    ## Find a single document matching a query
    give back collection find one query
end

define update in taking collection where query set changes
    ## Update documents matching a query
    give back collection update query with changes
end

define delete from taking collection where query
    ## Delete documents matching a query
    give back collection delete query
end
