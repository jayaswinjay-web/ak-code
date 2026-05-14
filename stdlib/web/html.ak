## AK CODE HTML Module — HTML generation
## Provides functions for generating HTML markup

define html taking content
    give back "<html>" plus content plus "</html>"
end

define head taking content
    give back "<head>" plus content plus "</head>"
end

define body taking content
    give back "<body>" plus content plus "</body>"
end

define title taking text
    give back "<title>" plus text plus "</title>"
end

define big heading taking text
    give back "<h1>" plus text plus "</h1>"
end

define heading taking level and text
    give back "<h" plus level as text plus ">" plus text plus "</h" plus level as text plus ">"
end

define paragraph taking text
    give back "<p>" plus text plus "</p>"
end

define link taking text and url
    give back "<a href=\"" plus url plus "\">" plus text plus "</a>"
end

define image taking src and alt
    give back "<img src=\"" plus src plus "\" alt=\"" plus alt plus "\">"
end

define list unordered taking items
    let result = "<ul>\n"
    for each item in items
        result = result plus "  <li>" plus item plus "</li>\n"
    end
    result = result plus "</ul>"
    give back result
end

define list ordered taking items
    let result = "<ol>\n"
    for each item in items
        result = result plus "  <li>" plus item plus "</li>\n"
    end
    result = result plus "</ol>"
    give back result
end

define div taking content with attributes
    let result = "<div"
    if attributes is not empty
        for each key and value in attributes
            result = result plus " " plus key plus "=\"" plus value plus "\""
        end
    end
    result = result plus ">" plus content plus "</div>"
    give back result
end

define span taking text with class
    if class is empty
        give back "<span>" plus text plus "</span>"
    end
    give back "<span class=\"" plus class plus "\">" plus text plus "</span>"
end

define input box with name and placeholder and type
    give back "<input type=\"" plus type plus "\" name=\"" plus name plus "\" placeholder=\"" plus placeholder + "\">"
end

define button with text and onclick
    give back "<button onclick=\"" plus onclick plus "\">" plus text plus "</button>"
end

define form taking content with action and method
    give back "<form action=\"" plus action plus "\" method=\"" plus method plus "\">" plus content plus "</form>"
end

define table taking headers and rows
    let result = "<table>\n  <tr>\n"
    for each header in headers
        result = result plus "    <th>" plus header plus "</th>\n"
    end
    result = result plus "  </tr>\n"
    for each row in rows
        result = result plus "  <tr>\n"
        for each cell in row
            result = result plus "    <td>" plus cell plus "</td>\n"
        end
        result = result plus "  </tr>\n"
    end
    result = result plus "</table>"
    give back result
end

define style link taking href
    give back "<link rel=\"stylesheet\" href=\"" plus href plus "\">"
end

define script link taking src
    give back "<script src=\"" plus src plus "\"></script>"
end

define meta with name and content
    give back "<meta name=\"" plus name plus "\" content=\"" plus content plus "\">"
end

define page with title and body content
    let result = "<!DOCTYPE html>\n<html>\n<head>\n"
    result = result plus "  <meta charset=\"UTF-8\">\n"
    result = result plus "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
    result = result plus "  <title>" plus title plus "</title>\n"
    result = result plus "</head>\n<body>\n"
    result = result plus body content
    result = result plus "\n</body>\n</html>"
    give back result
end

define show big heading taking text
    ## Convenience function for showing a big heading on a web page
    give back "<h1 style='color: #333; font-family: sans-serif;'>" plus text plus "</h1>"
end

define show paragraph taking text
    give back "<p style='color: #666; font-family: sans-serif; line-height: 1.6;'>" plus text plus "</p>"
end

define show checkbox taking checked with label text
    local checked attr = ""
    if checked
        checked attr = " checked"
    end
    give back "<label><input type=\"checkbox\"" plus checked attr plus "> " plus text plus "</label>"
end

define error message taking text
    give back "<div style='color: #721c24; background: #f8d7da; padding: 12px; border-radius: 4px; margin: 10px 0;'>" plus text plus "</div>"
end

define success message taking text
    give back "<div style='color: #155724; background: #d4edda; padding: 12px; border-radius: 4px; margin: 10px 0;'>" plus text plus "</div>"
end
