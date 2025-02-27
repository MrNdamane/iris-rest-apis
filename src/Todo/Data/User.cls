Class Todo.Data.AppUser Extends %Persistent
{

Property UserId As %Integer [ Identity, Required ];

Property Username As %String [ Required ];

Property Password As %String [ Required ];

Property AccessToken As %String(MAXLEN = 30);

Property ExpiryIn As %Float;

Index UsernameIndex On Username [ Unique ];

ClassMethod OpenByUsername(pUsername As %String) As Todo.Data.AppUser
{
    Quit ..UsernameIndexOpen(pUsername)
}

// Clear table data - Do ##class(Todo.Data.AppUser).%DeleteExtent()

// Clear table index - Do ##class(Todo.Data.AppUser).%PurgeIndices()

Storage Default
{
<Data name="AppUserDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Username</Value>
</Value>
<Value name="3">
<Value>Password</Value>
</Value>
<Value name="4">
<Value>AccessToken</Value>
</Value>
<Value name="5">
<Value>ExpiryIn</Value>
</Value>
</Data>
<DataLocation>^Todo.Data.AppUserD</DataLocation>
<DefaultData>AppUserDefaultData</DefaultData>
<IdLocation>^Todo.Data.AppUserD</IdLocation>
<IndexLocation>^Todo.Data.AppUserI</IndexLocation>
<StreamLocation>^Todo.Data.AppUserS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
