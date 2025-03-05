Class Todo.Data.Item Extends %Persistent
{

Property ItemId As %Integer [ Identity, Required ];

Property UserId As %Integer [ Required ];

Property Title As %String [ Required ];

Property Description As %String [ Required ];

Property DueDate As %Date(FORMAT = 5) [ Required ];

Property IsComplete As %Boolean;

Property CreatedDate As %Date(FORMAT = 5);

Property CompletedDate As %Date(FORMAT = 5);

Property IsFavorite As %Boolean;

Index TitleIndex On Title [ Unique ];

ForeignKey UserFK(UserId) References Todo.Data.AppUser(UserIdIndex);

/// clear table data - Do ##class(Todo.Data.Item).%DeleteExtent()
/// clear table index - Do ##class(Todo.Data.Item).%PurgeIndices()
ClassMethod OpenByTitle(pTitle As %String) As Todo.Data.Item
{
    Quit ..TitleIndexOpen(pTitle)
}

Storage Default
{
<Data name="ItemDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>UserId</Value>
</Value>
<Value name="3">
<Value>Title</Value>
</Value>
<Value name="4">
<Value>Description</Value>
</Value>
<Value name="5">
<Value>DueDate</Value>
</Value>
<Value name="6">
<Value>IsComplete</Value>
</Value>
<Value name="7">
<Value>CreatedDate</Value>
</Value>
<Value name="8">
<Value>CompletedDate</Value>
</Value>
<Value name="9">
<Value>IsFavorite</Value>
</Value>
</Data>
<DataLocation>^Todo.Data.ItemD</DataLocation>
<DefaultData>ItemDefaultData</DefaultData>
<IdLocation>^Todo.Data.ItemD</IdLocation>
<IndexLocation>^Todo.Data.ItemI</IndexLocation>
<StreamLocation>^Todo.Data.ItemS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
