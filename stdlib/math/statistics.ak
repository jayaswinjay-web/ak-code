## AK CODE Statistics Module — data analysis and statistical operations
## Provides functions for numerical data analysis and descriptive statistics

define sort list taking data
    ## Sorts a list in ascending order using bubble sort
    ## Returns a new sorted list
    let result = list of
    for each val in data
        add val to result
    end
    let n = size of result
    let i = 0
    repeat while i is less than n
        let j = i plus 1
        repeat while j is less than n
            if item j of result is less than item i of result
                let temp = item i of result
                set item i of result to item j of result
                set item j of result to temp
            end
            j = j plus 1
        end
        i = i plus 1
    end
    give back result
end

define sum of list taking data
    ## Computes the sum of all elements in a list
    if data is empty
        give back 0
    end
    let result = 0
    for each val in data
        result = result plus val
    end
    give back result
end

define min of list taking data
    ## Returns the minimum value in a list
    if data is empty
        give back empty
    end
    let result = item 0 of data
    let i = 1
    repeat while i is less than size of data
        let val = item i of data
        if val is less than result
            result = val
        end
        i = i plus 1
    end
    give back result
end

define max of list taking data
    ## Returns the maximum value in a list
    if data is empty
        give back empty
    end
    let result = item 0 of data
    let i = 1
    repeat while i is less than size of data
        let val = item i of data
        if val is greater than result
            result = val
        end
        i = i plus 1
    end
    give back result
end

define range of list taking data
    ## Computes the range (max minus min) of a list
    let min val = min of list taking data
    let max val = max of list taking data
    if min val is empty or max val is empty
        give back 0
    end
    give back max val minus min val
end

define mean taking data
    ## Computes the arithmetic mean of a list
    if data is empty
        give back empty
    end
    let total = sum of list taking data
    give back total divided by size of data
end

define median taking data
    ## Computes the median of a list
    if data is empty
        give back empty
    end
    let sorted = sort list taking data
    let n = size of sorted
    if n mod 2 is 1
        give back item (n divided by 2) of sorted
    end
    let mid = n divided by 2
    let a = item (mid minus 1) of sorted
    let b = item mid of sorted
    give back (a plus b) divided by 2
end

define mode taking data
    ## Returns a list of the most frequent value in a list
    if data is empty
        give back empty
    end
    let values = list of
    let counts = list of
    let max count = 0
    for each val in data
        let found = false
        let i = 0
        repeat while i is less than size of values
            if item i of values is val
                let new count = item i of counts plus 1
                set item i of counts to new count
                if new count is greater than max count
                    max count = new count
                end
                found = true
            end
            i = i plus 1
        end
        if found is false
            add val to values
            add 1 to counts
            if 1 is greater than max count
                max count = 1
            end
        end
    end
    let result = list of
    let j = 0
    repeat while j is less than size of values
        if item j of counts is max count
            add item j of values to result
        end
        j = j plus 1
    end
    give back result
end

define variance taking data
    ## Computes the population variance of a list
    let n = size of data
    if n is less than 2
        give back 0
    end
    let avg = mean taking data
    let sum sq = 0
    for each val in data
        let diff = val minus avg
        sum sq = sum sq plus diff times diff
    end
    give back sum sq divided by n
end

define sample variance taking data
    ## Computes the sample variance of a list (divides by n minus 1)
    let n = size of data
    if n is less than 2
        give back 0
    end
    let avg = mean taking data
    let sum sq = 0
    for each val in data
        let diff = val minus avg
        sum sq = sum sq plus diff times diff
    end
    give back sum sq divided by (n minus 1)
end

define standard deviation taking data
    ## Computes the population standard deviation of a list
    give back square root of variance taking data
end

define sample standard deviation taking data
    ## Computes the sample standard deviation of a list
    give back square root of sample variance taking data
end

define covariance taking x and y
    ## Computes the population covariance between two lists
    let n = size of x
    if n is not size of y or n is less than 2
        give back 0
    end
    let mean x = mean taking x
    let mean y = mean taking y
    let total = 0
    let i = 0
    repeat while i is less than n
        total = total plus (item i of x minus mean x) times (item i of y minus mean y)
        i = i plus 1
    end
    give back total divided by n
end

define sample covariance taking x and y
    ## Computes the sample covariance between two lists
    let n = size of x
    if n is not size of y or n is less than 2
        give back 0
    end
    let mean x = mean taking x
    let mean y = mean taking y
    let total = 0
    let i = 0
    repeat while i is less than n
        total = total plus (item i of x minus mean x) times (item i of y minus mean y)
        i = i plus 1
    end
    give back total divided by (n minus 1)
end

define correlation taking x and y
    ## Computes the Pearson correlation coefficient between two lists
    let n = size of x
    if n is not size of y or n is less than 2
        give back 0
    end
    let cov = covariance taking x and y
    let sd x = standard deviation taking x
    let sd y = standard deviation taking y
    if sd x is 0 or sd y is 0
        give back 0
    end
    give back cov divided by (sd x times sd y)
end

define percentile taking data and p
    ## Computes the p-th percentile of a list using nearest rank
    if data is empty or p is less than 0 or p is greater than 100
        give back empty
    end
    let sorted = sort list taking data
    let n = size of sorted
    let rank = (p times n plus 50) divided by 100
    if rank is 0
        rank = 1
    end
    if rank is greater than n
        rank = n
    end
    give back item (rank minus 1) of sorted
end

define quartile taking data and q
    ## Computes quartiles: q 1 for Q1 q 2 for Q2 q 3 for Q3
    if data is empty
        give back empty
    end
    if q is 2
        give back median taking data
    end
    if q is 1
        give back percentile taking data and 25
    end
    if q is 3
        give back percentile taking data and 75
    end
    give back empty
end

define iqr taking data
    ## Computes the interquartile range Q3 minus Q1
    let q1 = quartile taking data and 1
    let q3 = quartile taking data and 3
    if q1 is empty or q3 is empty
        give back 0
    end
    give back q3 minus q1
end

define z score taking value and data
    ## Computes the z score of a value relative to a data set
    let avg = mean taking data
    let sd = standard deviation taking data
    if avg is empty or sd is 0
        give back 0
    end
    give back (value minus avg) divided by sd
end

define weighted mean taking values and weights
    ## Computes the weighted mean of values with given weights
    let n = size of values
    if n is 0 or n is not size of weights
        give back empty
    end
    let sum weighted = 0
    let sum weights = 0
    let i = 0
    repeat while i is less than n
        sum weighted = sum weighted plus (item i of values) times (item i of weights)
        sum weights = sum weights plus item i of weights
        i = i plus 1
    end
    if sum weights is 0
        give back 0
    end
    give back sum weighted divided by sum weights
end

define geometric mean taking data
    ## Computes the geometric mean of a list
    let n = size of data
    if n is 0
        give back empty
    end
    for each val in data
        if val is less than or equal to 0
            give back empty
        end
    end
    let product = 1
    for each val in data
        product = product times val
    end
    give back product raised to (1 divided by n)
end

define harmonic mean taking data
    ## Computes the harmonic mean of a list
    let n = size of data
    if n is 0
        give back empty
    end
    let sum recip = 0
    for each val in data
        if val is 0
            give back empty
        end
        sum recip = sum recip plus 1 divided by val
    end
    if sum recip is 0
        give back 0
    end
    give back n divided by sum recip
end

define root mean square taking data
    ## Computes the root mean square of a list
    if data is empty
        give back empty
    end
    let sum sq = 0
    for each val in data
        sum sq = sum sq plus val times val
    end
    give back square root of (sum sq divided by size of data)
end

define skewness taking data
    ## Computes the sample skewness of a list
    let n = size of data
    if n is less than 3
        give back 0
    end
    let avg = mean taking data
    let sd = standard deviation taking data
    if sd is 0
        give back 0
    end
    let sum cubed = 0
    for each val in data
        let diff = (val minus avg) divided by sd
        sum cubed = sum cubed plus diff times diff times diff
    end
    let factor = n divided by ((n minus 1) times (n minus 2))
    give back factor times sum cubed
end

define kurtosis taking data
    ## Computes the excess kurtosis of a list
    let n = size of data
    if n is less than 4
        give back 0
    end
    let avg = mean taking data
    let sd = standard deviation taking data
    if sd is 0
        give back 0
    end
    let sum fourth = 0
    for each val in data
        let diff = (val minus avg) divided by sd
        sum fourth = sum fourth plus diff times diff times diff times diff
    end
    let num = n times (n plus 1) times sum fourth
    let den = (n minus 1) times (n minus 2) times (n minus 3)
    let term1 = num divided by den
    let term2 = 3 times (n minus 1) times (n minus 1) divided by ((n minus 2) times (n minus 3))
    give back term1 minus term2
end

define frequency taking data
    ## Computes the frequency distribution of a list
    ## Returns a list of pairs where each pair is value and count
    let keys = list of
    let counts = list of
    for each val in data
        let found = false
        let i = 0
        repeat while i is less than size of keys
            if item i of keys is val
                set item i of counts to (item i of counts) plus 1
                found = true
            end
            i = i plus 1
        end
        if found is false
            add val to keys
            add 1 to counts
        end
    end
    let result = list of
    let j = 0
    repeat while j is less than size of keys
        let pair = list of item j of keys item j of counts
        add pair to result
        j = j plus 1
    end
    give back result
end

define sum of squares taking data
    ## Computes the sum of squared deviations from the mean
    let avg = mean taking data
    if avg is empty
        give back 0
    end
    let result = 0
    for each val in data
        let diff = val minus avg
        result = result plus diff times diff
    end
    give back result
end

define central moment taking data and k
    ## Computes the k-th central moment of a list
    let n = size of data
    if n is 0
        give back empty
    end
    let avg = mean taking data
    let sum = 0
    for each val in data
        let diff = val minus avg
        let power = diff
        let i = 1
        repeat while i is less than k
            power = power times diff
            i = i plus 1
        end
        sum = sum plus power
    end
    give back sum divided by n
end

define standardized moment taking data and k
    ## Computes the k-th standardized moment of a list
    let sd = standard deviation taking data
    if sd is 0
        give back 0
    end
    let moment = central moment taking data and k
    if moment is empty
        give back 0
    end
    give back moment divided by (sd raised to k)
end

define covariance matrix taking columns
    ## Computes the covariance matrix from a list of columns
    ## Each column is a list of values
    let num cols = size of columns
    if num cols is 0
        give back empty
    end
    let result = new Matrix with num cols and num cols
    let i = 0
    repeat while i is less than num cols
        let j = i
        repeat while j is less than num cols
            let cov val = covariance taking item i of columns and item j of columns
            result set i and j and cov val
            result set j and i and cov val
            j = j plus 1
        end
        i = i plus 1
    end
    give back result
end

define correlation matrix taking columns
    ## Computes the correlation matrix from a list of columns
    let num cols = size of columns
    if num cols is 0
        give back empty
    end
    let result = new Matrix with num cols and num cols
    let i = 0
    repeat while i is less than num cols
        let j = i
        repeat while j is less than num cols
            let corr val = correlation taking item i of columns and item j of columns
            result set i and j and corr val
            result set j and i and corr val
            j = j plus 1
        end
        i = i plus 1
    end
    give back result
end
