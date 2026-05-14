## AK CODE Tokenizer Module — text tokenization for LLMs
## Converts text to token IDs for neural network processing

make kind called Tokenizer
    has vocab of type map
    has reverse vocab of type map
    has vocab size of type number

    when created
        vocab = map end
        reverse vocab = map end
        vocab size = 0
    end

    behaviour add token taking token
        if vocab has token is not true
            vocab set token to vocab size
            reverse vocab set vocab size to token
            vocab size = vocab size plus 1
        end
    end

    behaviour encode taking text
        ## Converts text to list of token IDs
        let tokens = list of
        let words = split text by " "
        for each word in words
            let cleaned = trim word
            if cleaned is not ""
                let id = vocab get cleaned
                if id is empty
                    # Unknown token — use special <UNK> token
                    id = vocab get "<UNK>"
                    if id is empty
                        id = 0
                    end
                end
                add id to tokens
            end
        end
        give back tokens
    end

    behaviour decode taking ids
        ## Converts token IDs back to text
        let result = ""
        let first = true
        for each id in ids
            if first is not true
                result = result plus " "
            end
            let token = reverse vocab get id
            if token is empty
                token = "<UNK>"
            end
            result = result plus token
            first = false
        end
        give back result
    end

    behaviour train on taking texts and max size
        ## Build vocabulary from a corpus of texts
        let freq = map end
        for each text in texts
            let words = split text by " "
            for each word in words
                let cleaned = trim word
                if cleaned is not ""
                    let count = freq get cleaned
                    if count is empty
                        freq set cleaned to 1
                    else
                        freq set cleaned to count plus 1
                    end
                end
            end
        end

        # Add special tokens
        add token "<PAD>"
        add token "<UNK>"
        add token "<BOS>"  # Beginning of sequence
        add token "<EOS>"  # End of sequence

        # Add most frequent tokens
        # Sort by frequency (simplified)
        let sorted = list of
        for each word and count in freq
            let entry = list of count word
            add entry to sorted
        end

        # Simple selection without full sort
        let added = 0
        let max to add = max size minus 4  # leave room for special tokens
        if max to add is less than 0
            max to add = 0
        end

        # Add tokens in order of frequency
        repeat while added is less than max to add and size of sorted is greater than 0
            # Find the most frequent item
            let best idx = 0
            let best count = item 0 of item 0 of sorted
            let i = 1
            repeat while i is less than size of sorted
                let entry = item i of sorted
                let count = item 0 of entry
                if count is greater than best count
                    best count = count
                    best idx = i
                end
                i = i plus 1
            end
            let best entry = item best idx of sorted
            add token item 1 of best entry
            remove item best idx from sorted
            added = added plus 1
        end

        show "Vocabulary built:" vocab size "tokens"
    end

    behaviour encode batch taking texts
        ## Encode multiple texts with padding to same length
        let all ids = list of
        let max len = 0

        for each text in texts
            let ids = encode text
            add ids to all ids
            if size of ids is greater than max len
                max len = size of ids
            end
        end

        # Pad sequences
        let pad id = vocab get "<PAD>"
        if pad id is empty
            pad id = 0
        end

        let result = list of
        for each ids in all ids
            let padded = ids
            repeat while size of padded is less than max len
                add pad id to padded
            end
            add padded to result
        end

        give back result
    end

    behaviour save to taking path
        ## Save tokenizer vocabulary to file
        show "Saving tokenizer to" path
        # Serialize vocab to file
    end

    behaviour load from taking path
        ## Load tokenizer vocabulary from file
        show "Loading tokenizer from" path
        # Deserialize vocab from file
    end
end

define create tokenizer from taking texts
    ## Convenience function to create and train a tokenizer
    let t = new Tokenizer
    t train on texts with 10000
    give back t
end

define split taking text by delimiter
    ## Split text by delimiter (local implementation)
    let result = list of
    let current = ""
    for each ch in text
        if ch is delimiter
            add current to result
            current = ""
        else
            current = current plus ch
        end
    end
    add current to result
    give back result
end

define trim taking str
    ## Trim whitespace from string ends
    let start = 0
    let end = size of str
    repeat while start is less than end and character at start of str is space
        start = start plus 1
    end
    repeat while end is greater than start and character at end minus 1 of str is space
        end = end minus 1
    end
    give back slice of str from start to end
end
