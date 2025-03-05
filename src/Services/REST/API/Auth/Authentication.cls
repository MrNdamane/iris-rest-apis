Class Services.REST.API.Auth.Authentication Extends %RegisteredObject
{

/// Description
ClassMethod LoginUser() As %Status
{
    Set sc = $$$OK

    Try {
        Set %response.ContentType = "application/json"

        Set tRequest = ##class(%DynamicObject).%FromJSON(%request.Content)
        Set tUsername = tRequest.username
        Set tPassword = tRequest.password

        // Input validation
        If (tUsername = "") || (tPassword = "") {
            Do ..ThrowErrorResponse("Username and password are required", "400 Bad Request")
        }

        // Simulate user lookup
        //&sql(SELECT %ID INTO :userId FROM Todo_Data.AppUser WHERE Username = :tUsername)
        
        //If (SQLCODE = 0) {
        //        Set tUser = ##class(Todo.Data.AppUser).%OpenId(userId)
        //    } Else {
        //        Set tUser = ""
        //}
        Set tUser = ##class(Todo.Data.AppUser).OpenByUsername(tUsername)
        If '$ISOBJECT(tUser) {
            Do ..ThrowErrorResponse("Invalid username or password", "401 Unauthorized")
        }

        // Check password
        set tHashedPassword = $System.Encryption.SHAHash(256,tPassword)
        If tUser.Password '= tHashedPassword {
            Do ..ThrowErrorResponse("Incorrect password", "401 Unauthorized")
        }

        // Check if user is already logged in with an unexpired token
        If $ISOBJECT(tUser.ExpiryIn) && ($ZDATETIMEH(tUser.ExpiryIn, 3) > $H) {
            Do ..ThrowErrorResponse("User is already signed in", "403 Forbidden")
        }

        // Generate JWT token
        Set tToken = ..GenerateToken(tUser.UserId, tUsername)
        Set tExpiration = +..GetTokenExpiration()
        Set now = $ZTIMESTAMP
        Set nowFloat = $Piece(now, ",", 1) + ($Piece(now, ",", 2) / 86400)
        Set tUser.AccessToken = tToken
        Set tUser.ExpiryIn = nowFloat + (tExpiration / 86400)
        Write "Saving Token: ", tToken, " Expires: ", tUser.ExpiryIn, " Now: ", nowFloat, !
        Set tStatus = tUser.%Save()
        If $$$ISERR(tStatus) {
            Set sc = tStatus
            Do ..ThrowErrorResponse("Failed to save token: "_$System.Status.GetErrorText(tStatus), "500 Internal Server Error")
        }

        // Successfull login
        Set tResponse = ##class(%DynamicObject).%New()
        Set tResponse.status = "success"
        Set tResponse.message = "Login successful"
        Set tResponse.userId = tUser.UserId
        Set tResponse."access_token" = tToken
        Set tResponse."expires_in" = tExpiration
        Set %response.Status = "200 OK"
        do tResponse.%ToJSON()
        //Quit 
        
    } Catch ex {
        Do ..ThrowErrorResponse("Internal server error: "_ex.DisplayString(), "500 Internal Server Error")
        set sc = $$$ERROR($$$GeneralError, ex.DisplayString())
    }
    Return sc
}

ClassMethod CreateUser() As %Status
{
    Set sc = $$$OK
    Try {
        Set %response.ContentType = "application/json"
        Set tRequest = ##class(%DynamicObject).%FromJSON(%request.Content)
        Set tUsername = tRequest.username
        Set tPassword = tRequest.password

        // Input validation
        If (tUsername = "") || (tPassword = "") {
            Do ..ThrowErrorResponse("Username and password are required", "400 Bad Request")
        }

        // Check if user already exists
       // &sql(SELECT %ID INTO :userId FROM Todo_Data.AppUser WHERE Username = :tUsername)
        
       // If (SQLCODE = 0) {
        //        Set tUser = ##class(Todo.Data.AppUser).%OpenId(userId)
        //    } Else {
        //        Set tUser = ""
        //}
        Set tExistingUser = ##class(Todo.Data.AppUser).OpenByUsername(tUsername)
        If $ISOBJECT(tExistingUser) {
            Do ..ThrowErrorResponse("User already exists, UserId: "_tExistingUser.UserId_", Username: "_tExistingUser.Username, "409 Conflict")
        }
   
        // Create new user
        Set tUser = ##class(Todo.Data.AppUser).%New()
        Set tUser.Username = tUsername
        Set tUser.Password = $System.Encryption.SHAHash(256,tPassword)
        Set tStatus = tUser.%Save()
        
        // check error
        If $$$ISERR(tStatus) {
            Do ..ThrowErrorResponse("Failed to create user: "_$System.Status.GetErrorText(tStatus), "500 Internal Server Error")
        }

        // Successfull user creation
        Set tResponse = ##class(%DynamicObject).%New()
        Set tResponse.status = "success"
        Set tResponse.message = "User created successfully"
        Set tResponse.userId = tUser.UserId
        Set %response.Status = "201 Created"
        do tResponse.%ToJSON()
        //Quit
    }
    Catch ex {
        Do ..ThrowErrorResponse("Internal server error: "_ex.DisplayString(), "500 Internal Server Error")
        set sc = $$$ERROR($$$GeneralError, ex.DisplayString())
    }
    Return sc
}

ClassMethod LogoutUser() As %Status
{
    Set sc = $$$OK
    Try {
        Set %response.ContentType = "application/json"
        Set tRequest = ##class(%DynamicObject).%FromJSON(%request.Content)
        Set tUsername = tRequest.username

        If tUsername = "" {
            Do ..ThrowErrorResponse("Username is required", "400 Bad Request")
        }

        Set user = ##class(Todo.Data.AppUser).OpenByUsername(tUsername)
        If '$ISOBJECT(user) {
            Do ..ThrowErrorResponse("User not found", "404 Not Found")
        }

        // Clear token and expiration
        Set user.AccessToken = ""
        Set user.ExpiryIn = ""
        Set tStatus = user.%Save()
        If $$$ISERR(tStatus) {
            Do ..ThrowErrorResponse("Failed to logout: "_$System.Status.GetErrorText(tStatus), "500 Internal Server Error")
        }

        Set tResponse = ##class(%DynamicObject).%New()
        Set tResponse.status = "success"
        Set tResponse.message = "User logged out successfully"
        Set %response.Status = "200 OK"
        Do tResponse.%ToJSON()
    }
    Catch ex {
        Do ..ThrowErrorResponse("Internal server error: "_ex.DisplayString(), "500 Internal Server Error")
        Set sc = $$$ERROR($$$GeneralError, ex.DisplayString())
    }
    Return sc
}

ClassMethod GenerateToken(pUserId As %Integer, pUsername As %String) As %String
{
    // Generate a random string, max 30 characters
    Set tChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    Set tToken = ""
    For i=1:1:30 {
        Set tToken = tToken_$Extract(tChars, $Random($Length(tChars)) + 1)
    }
    Quit tToken
}

ClassMethod GetTokenExpiration() As %String
{
    // Return expiration in seconds (1 hour = 3600 seconds)
    Quit "3600"
}

/*
**Might use this later**
ClassMethod GenerateToken(pUserId As %Integer, pUsername As %String) As %String
{
    Set tHeader = {"alg":"HS256", "typ":"JWT"}
    Set tHeaderEncoded = ..ToBase64Url($System.Encryption.Base64Encode(tHeader.%ToJSON()))

    Set tIssuedAt = $ZTIMESTAMP
    Set tExpiration = ..GetTokenExpiration()
    Set tPayload = {
        "userId": (pUserId),
        "username": (pUsername),
        "iat": ($Piece(tIssuedAt, ",", 1) * 86400 + $Piece(tIssuedAt, ",", 2)),
        "exp": ($Piece(tExpiration, ",", 1) * 86400 + $Piece(tExpiration, ",", 2))
    }
    Set tPayloadEncoded = ..ToBase64Url($System.Encryption.Base64Encode(tPayload.%ToJSON()))

    Set tSecret = "api-key"
    Set tSignatureInput = tHeaderEncoded_"."_tPayloadEncoded
    Set tSignature = $System.Encryption.HMACSHA(256, tSignatureInput, tSecret)
    Set signatureEncoded = ..ToBase64Url($System.Encryption.Base64Encode(tSignature))

    // Combine into JWT: tHeader.payload.signature
    Quit tHeaderEncoded_"."_tPayloadEncoded_"."_signatureEncoded
}*/
ClassMethod ToBase64Url(pEncoded As %String) As %String
{
    // Convert standard Base64 to Base64URL: replace + with -, / with _, remove =
    Set pEncoded = $Translate(pEncoded, "+/", "-_")
    Set pEncoded = $Replace(pEncoded, "=", "")
    Quit pEncoded
}

/*
**Might use this later**
ClassMethod GetTokenExpiration() As %String
{
    Set tNow = $H
    Set tDays = $Piece(tNow, ",", 1)
    Set tSeconds = $Piece(tNow, ",", 2)
    Set tNewSeconds = tSeconds + 3600
    If tNewSeconds >= 86400 {
        Set tDays = tDays + 1
        Set tNewSeconds = tNewSeconds - 86400
    }
    // Combine back into $H format
    Set tExpirationH = tDays_","_tNewSeconds
    // Convert to ISO 8601 string
    Quit $ZDATETIME(tExpirationH, 3)
}*/
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
