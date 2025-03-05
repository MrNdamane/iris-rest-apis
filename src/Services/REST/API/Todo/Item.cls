Class Services.REST.API.Todo.Item Extends %RegisteredObject
{

ClassMethod GetAllItems() As %Status
{
    Set sc = $$$OK
    Try {
        Set %response.ContentType = "application/json"
        Set user = ..ValidateToken()
        If '$ISOBJECT(user) {
            $$$ThrowOnError(sc)
        }

        // Create %SQL.Statement instance
        Set stmt = ##class(%SQL.Statement).%New()
        Set tStatus = stmt.%Prepare("SELECT ItemId, Title, Description, DueDate, IsComplete, CreatedDate, CompletedDate, IsFavorite FROM Todo_Data.Item WHERE UserId = ?")
        If $$$ISERR(tStatus) {
            Set sc = tStatus
            Do ..ThrowErrorResponse("Failed to prepare query: "_$System.Status.GetErrorText(tStatus), "500 Internal Server Error")
        }

        // Execute query with UserId parameter
        Set rs = stmt.%Execute(user.UserId)
        If rs.%SQLCODE < 0 {
            Set sc = $$$ERROR($$$SQLError, rs.%SQLCODE, rs.%Message)
            Do ..ThrowErrorResponse("Failed to execute query: "_rs.%Message, "500 Internal Server Error")
        }

        // Build array of items
        Set items = []
        While rs.Next() {
            Set item = ##class(Todo.Data.Item).%OpenId(rs.Get("ID"))
            If $ISOBJECT(item) && (item.UserId = user.UserId) {
                Set itemObj = ##class(%DynamicObject).%New()
                Set itemObj.ItemId = item.ItemId
                Set itemObj.Title = item.Title
                Set itemObj.Description = item.Description
                Set itemObj.DueDate = $ZDATE(item.DueDate, 5)  // Format as yyyy-mm-dd
                Set itemObj.IsComplete = item.IsComplete
                Set itemObj.CreatedDate = $ZDATE(item.CreatedDate, 5)  // Format as yyyy-mm-dd
                Set itemObj.CompletedDate = $S(item.CompletedDate="":"", 1:$ZDATE(item.CompletedDate, 5))  // Format as yyyy-mm-dd or empty
                Set itemObj.IsFavorite = item.IsFavorite
                Do items.%Push(itemObj)
            }
        }

        // Return the array of items
        Set tResponse = ##class(%DynamicObject).%New()
        Set tResponse.status = "success"
        Set tResponse.message = "Items retrieved successfully"
        Set tResponse.items = items
        Set %response.Status = "200 OK"
        Do tResponse.%ToJSON()
    }
    Catch ex {
        Set sc = $$$ERROR($$$GeneralError, ex.DisplayString())
        Do ..ThrowErrorResponse("Internal server error: "_ex.DisplayString(), "500 Internal Server Error")
    }
    Return sc
}

ClassMethod GetItemById(id As %Integer) As %Status
{
    Set sc = $$$OK
    Try {
        Set %response.ContentType = "application/json"
        Set user = ..ValidateToken()
        If '$ISOBJECT(user) {
            $$$ThrowOnError(sc)
        }

        // Use %SQL.Statement to fetch the item by ItemId and UserId
        Set stmt = ##class(%SQL.Statement).%New()
        Set tStatus = stmt.%Prepare("SELECT ItemId, Title, Description, DueDate, IsComplete, CreatedDate, CompletedDate, IsFavorite FROM Todo_Data.Item WHERE ItemId = ? AND UserId = ?")
        If $$$ISERR(tStatus) {
            Set sc = tStatus
            Do ..ThrowErrorResponse("Failed to prepare query: "_$System.Status.GetErrorText(tStatus), "500 Internal Server Error")
        }

        // Execute query with ItemId and UserId parameters
        Set rs = stmt.%Execute(id, user.UserId)
        If rs.%SQLCODE < 0 {
            Set sc = $$$ERROR($$$SQLError, rs.%SQLCODE, rs.%Message)
            Do ..ThrowErrorResponse("Failed to execute query: "_rs.%Message, "500 Internal Server Error")
        }

        // Check if item exists
        If 'rs.%Next() {
            Do ..ThrowErrorResponse("Item not found or unauthorized", "404 Not Found")
        }

        // Build response object
        Set itemObj = ##class(%DynamicObject).%New()
        Set itemObj.ItemId = rs.%Get("ItemId")
        Set itemObj.Title = rs.%Get("Title")
        Set itemObj.Description = rs.%Get("Description")
        Set itemObj.DueDate = $ZDATE(rs.%Get("DueDate"), 5)  // Format as yyyy-mm-dd
        Set itemObj.IsComplete = rs.%Get("IsComplete")
        Set itemObj.CreatedDate = $ZDATE(rs.%Get("CreatedDate"), 5)  // Format as yyyy-mm-dd
        Set itemObj.CompletedDate = $S(rs.%Get("CompletedDate")="":"", 1:$ZDATE(rs.%Get("CompletedDate"), 5))  // Format as yyyy-mm-dd or empty
        Set itemObj.IsFavorite = rs.%Get("IsFavorite")

        // Return the item
        Set tResponse = ##class(%DynamicObject).%New()
        Set tResponse.status = "success"
        Set tResponse.message = "Item retrieved successfully"
        Set tResponse.item = itemObj
        Set %response.Status = "200 OK"
        Do tResponse.%ToJSON()
    }
    Catch ex {
        Set sc = $$$ERROR($$$GeneralError, ex.DisplayString())
        Do ..ThrowErrorResponse("Internal server error: "_ex.DisplayString(), "500 Internal Server Error")
    }
    Return sc
}

ClassMethod AddItem() As %Status
{
    Set sc = $$$OK
    Try {
        Set %response.ContentType = "application/json"
        Set user = ..ValidateToken()
        If '$ISOBJECT(user) {
            $$$ThrowOnError(sc)
        }

        Set tRequest = ##class(%DynamicObject).%FromJSON(%request.Content)
        Set tTitle = tRequest.title
        Set tDescription = tRequest.description
        Set tDueDate = tRequest.dueDate

        If (tTitle = "") || (tDescription = "") || (tDueDate = "") {
            Do ..ThrowErrorResponse("Title, description, and due date are required", "400 Bad Request")
        }

        Set item = ##class(Todo.Data.Item).OpenByTitle(tTitle)
        If $ISOBJECT(item) {
            Do ..ThrowErrorResponse("Item with title '"_tTitle_"' already exists", "409 Conflict")
        }

        Set item = ##class(Todo.Data.Item).%New()
        If '$ISOBJECT(item) {
            Do ..ThrowErrorResponse("Failed to create new item instance", "500 Internal Server Error")
        }

        Set item.UserId = user.UserId
        Set item.Title = tTitle
        Set item.Description = tDescription
        // Validate and set DueDate
        Try {
            Set item.DueDate = $ZDATEH(tDueDate, 5)  // yyyy-mm-dd
        } Catch ex {
            Do ..ThrowErrorResponse("Invalid due date format: "_ex.DisplayString(), "400 Bad Request")
        }
        Set item.IsComplete = 0
        Set item.CreatedDate = $Piece($H, ",", 1)
        Set item.IsFavorite = 0

        Set tStatus = item.%Save()
        If $$$ISERR(tStatus) {
            Set sc = tStatus
            Do ..ThrowErrorResponse("Failed to add item: "_$System.Status.GetErrorText(tStatus), "500 Internal Server Error")
        }

        // Ensure ItemId is set after save
        If item.ItemId = "" {
            Do ..ThrowErrorResponse("Item saved but ItemId not generated", "500 Internal Server Error")
        }

        Set tResponse = ##class(%DynamicObject).%New()
        Set tResponse.status = "success"
        Set tResponse.message = "Item added successfully"
        Set tResponse.itemId = item.ItemId
        Set %response.Status = "201 Created"
        Do tResponse.%ToJSON()
    }
    Catch ex {
        Do ..ThrowErrorResponse("Internal server error: "_ex.DisplayString(), "500 Internal Server Error")
        Set sc = $$$ERROR($$$GeneralError, ex.DisplayString())
    }
    Return sc
}

ClassMethod AddItems() As %Status
{
    Set sc = $$$OK
    Try {
        Set %response.ContentType = "application/json"
        Set user = ..ValidateToken()
        If '$ISOBJECT(user) {
            $$$ThrowOnError(sc)
        }

        // Parse the JSON payload as an array
        Set tRequest = ##class(%DynamicArray).%FromJSON(%request.Content)
        If '$ISOBJECT(tRequest) || 'tRequest.%IsA("%Library.DynamicArray") {
            Set sc = $$$ERROR($$$GeneralError, "Expected an array of items")
            Do ..ThrowErrorResponse("Expected an array of items", "400 Bad Request")
        }

        // Process each item
        Set results = []
        For i=0:1:tRequest.%Size()-1 {
            Set itemData = tRequest.%Get(i)
            Set tTitle = itemData.title
            Set tDescription = itemData.description
            Set tDueDate = itemData.dueDate

            // Validate required fields
            Set resultObj = ##class(%DynamicObject).%New()
            Set resultObj.title = tTitle
            If (tTitle = "") || (tDescription = "") || (tDueDate = "") {
                Set resultObj.status = "error"
                Set resultObj.message = "Title, description, and due date are required"
                Do results.%Push(resultObj)
                Continue
            }

            // Check for duplicate title
            Set existingItem = ##class(Todo.Data.Item).OpenByTitle(tTitle)
            If $ISOBJECT(existingItem) {
                Set resultObj.status = "error"
                Set resultObj.message = "Item with title '"_tTitle_"' already exists"
                Do results.%Push(resultObj)
                Continue
            }

            // Create and save new item
            Set item = ##class(Todo.Data.Item).%New()
            If '$ISOBJECT(item) {
                Set resultObj.status = "error"
                Set resultObj.message = "Failed to create new item instance"
                Do results.%Push(resultObj)
                Continue
            }

            Set item.UserId = user.UserId
            Set item.Title = tTitle
            Set item.Description = tDescription
            Try {
                Set item.DueDate = $ZDATEH(tDueDate, 5)
            } Catch ex {
                Set resultObj.status = "error"
                Set resultObj.message = "Invalid due date format, expected yyyy-mm-dd: "_ex.DisplayString()
                Do results.%Push(resultObj)
                Continue
            }
            Set item.IsComplete = 0
            Set item.CreatedDate = $Piece($H, ",", 1)
            Set item.IsFavorite = 0

            Set tStatus = item.%Save()
            If $$$ISERR(tStatus) {
                set sc = tStatus
                Set resultObj.status = "error"
                Set resultObj.message = "Failed to add item: "_$System.Status.GetErrorText(tStatus)
                Do results.%Push(resultObj)
                Continue
            }

            If item.ItemId = "" {
                Set resultObj.status = "error"
                Set resultObj.message = "Item saved but ItemId not generated"
                Do results.%Push(resultObj)
                Continue
            }

            Set resultObj.status = "success"
            Set resultObj.itemId = item.ItemId
            Do results.%Push(resultObj)
        }

        // Return the results of all operations
        Set tResponse = ##class(%DynamicObject).%New()
        Set tResponse.status = "success"
        Set tResponse.message = "Processed "_tRequest.%Size()_" items"
        Set tResponse.results = results
        Set %response.Status = "201 Created"
        Do tResponse.%ToJSON()
    }
    Catch ex {
        Set sc = $$$ERROR($$$GeneralError, ex.DisplayString())
        Do ..ThrowErrorResponse("Internal server error: "_ex.DisplayString(), "500 Internal Server Error")
    }
    Return sc
}

ClassMethod DeleteItemById(id As %Integer) As %Status
{
    Set sc = $$$OK
    Try {
        Set %response.ContentType = "application/json"
        Set user = ..ValidateToken()
        If '$ISOBJECT(user) {
            $$$ThrowOnError(sc)
        }

        Set item = ##class(Todo.Data.Item).%OpenId(id)
        If '$ISOBJECT(item) {
            Do ..ThrowErrorResponse("Item not found", "404 Not Found")
        }

        If item.UserId '= user.UserId {
            Do ..ThrowErrorResponse("Unauthorized to delete this item", "403 Forbidden")
        }

        Set tStatus = ##class(Todo.Data.Item).%DeleteId(id)
        If $$$ISERR(tStatus) {
            Set sc = tStatus
            Do ..ThrowErrorResponse("Failed to delete item: "_$System.Status.GetErrorText(tStatus), "500 Internal Server Error")
        }

        Set tResponse = ##class(%DynamicObject).%New()
        Set tResponse.status = "success"
        Set tResponse.message = "Item deleted successfully"
        Set %response.Status = "200 OK"
        Do tResponse.%ToJSON()
    }
    Catch ex {
        Do ..ThrowErrorResponse("Internal server error: "_ex.DisplayString(), "500 Internal Server Error")
        Set sc = $$$ERROR($$$GeneralError, ex.DisplayString())
    }
    Return sc
}

ClassMethod UpdateItemById(id As %Integer) As %Status
{
    Set sc = $$$OK
    Try {
        Set %response.ContentType = "application/json"
        Set user = ..ValidateToken()
        If '$ISOBJECT(user) {
            $$$ThrowOnError(sc)
        }

        Set item = ##class(Todo.Data.Item).%OpenId(id)
        If '$ISOBJECT(item) {
            Do ..ThrowErrorResponse("Item not found", "404 Not Found")
        }

        If item.UserId '= user.UserId {
            Do ..ThrowErrorResponse("Unauthorized to update this item", "403 Forbidden")
        }

        Set tRequest = ##class(%DynamicObject).%FromJSON(%request.Content)

        // Update properties if they exist in the request
        If tRequest.%IsDefined("title") && (tRequest.title '= "") {
            Set item.Title = tRequest.title
        }
        If tRequest.%IsDefined("description") && (tRequest.description '= "") {
            Set item.Description = tRequest.description
        }
        If tRequest.%IsDefined("dueDate") && (tRequest.dueDate '= "") {
            Try {
                Set item.DueDate = $ZDATEH(tRequest.dueDate, 5)  // yyyy-mm-dd
            } Catch ex {
                Do ..ThrowErrorResponse("Invalid due date format, expected yyyy-mm-dd: "_ex.DisplayString(), "400 Bad Request")
            }
        }
        If tRequest.%IsDefined("isComplete") {
            Set item.IsComplete = tRequest.isComplete
            If tRequest.isComplete && (item.CompletedDate = "") {  // Use = "" for %Date check
                Set item.CompletedDate = $Piece($H, ",", 1)  // Internal %Date format
            } ElseIf 'tRequest.isComplete {
                Set item.CompletedDate = ""
            }
        }
        If tRequest.%IsDefined("isFavorite") {
            Set item.IsFavorite = tRequest.isFavorite
        }

        Set tStatus = item.%Save()
        If $$$ISERR(tStatus) {
            Set sc = tStatus
            Do ..ThrowErrorResponse("Failed to update item: "_$System.Status.GetErrorText(tStatus), "500 Internal Server Error")
        }

        Set tResponse = ##class(%DynamicObject).%New()
        Set tResponse.status = "success"
        Set tResponse.message = "Item updated successfully"
        Set %response.Status = "200 OK"
        Do tResponse.%ToJSON()
    }
    Catch ex {
        Do ..ThrowErrorResponse("Internal server error: "_ex.DisplayString(), "500 Internal Server Error")
        Set sc = $$$ERROR($$$GeneralError, ex.DisplayString())
    }
    Return sc
}

ClassMethod ValidateToken() As Todo.Data.AppUser
{
    Set authHeader = %request.GetCgiEnv("HTTP_AUTHORIZATION")
    Write "Auth Header: ", authHeader, !
    If authHeader="" || ($Extract(authHeader, 1, 7) '= "Bearer ") {
        Do ..ThrowErrorResponse("Bearer token required", "401 Unauthorized")
        Quit ""
    }

    Set token = $Extract(authHeader, 8, *)
     Write "Token: ", token, !
    Set user = ""
    Set user = ""
    Set now = $ZTIMESTAMP
    // Convert $ZTIMESTAMP to float for comparison
    Set nowFloat = $Piece(now, ",", 1) + ($Piece(now, ",", 2) / 86400)
    &sql(SELECT %ID INTO :userId FROM Todo_Data.AppUser WHERE AccessToken = :token AND ExpiryIn > :nowFloat)
    Write "SQLCODE: ", SQLCODE, " UserId: ", $Get(userId), !
    If SQLCODE = 0 {
        Set user = ##class(Todo.Data.AppUser).%OpenId(userId)
        If '$ISOBJECT(user) {
            Do ..ThrowErrorResponse("User object invalid after valid token", "500 Internal Server Error")
            Quit ""
        }
    }
    If '$ISOBJECT(user) {
        Do ..ThrowErrorResponse("Invalid or expired token", "401 Unauthorized")
        Quit ""
    }
    Quit user
}

ClassMethod ThrowErrorResponse(pMessage As %String, pHttpStatus As %String) As %Status
{
    Set tResponse = ##class(%DynamicObject).%New()
    Set tResponse.status = "error"
    Set tResponse.message = pMessage
    Set %response.Status = pHttpStatus
    Do tResponse.%ToJSON()
    Quit $$$OK
}

}
