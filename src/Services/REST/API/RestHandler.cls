Class Services.REST.API.RestHandler Extends %CSP.REST
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <!--Auth Routes-->
    <Route Url="/login" Method="POST" Call="Services.REST.API.Auth.Authentication:LoginUser" />
    <Route Url="/createUser" Method="POST" Call="Services.REST.API.Auth.Authentication:CreateUser" />
    <Route Url="/logout" Method="POST" Call="Services.REST.API.Auth.Authentication:LogoutUser" />
    <!--Todo Routes-->
    <Route Url="/items" Method="GET" Call="Services.REST.API.Todo.Item:GetAllItems" />
    <Route Url="/item" Method="POST" Call="Services.REST.API.Todo.Item:AddItem" />
    <Route Url="/items" Method="POST" Call="Services.REST.API.Todo.Item:AddItems" /> <!-- New route for multiple items -->
    <Route Url="/item/:id" Method="DELETE" Call="Services.REST.API.Todo.Item:DeleteItemById" />
    <Route Url="/item/:id" Method="PUT" Call="Services.REST.API.Todo.Item:UpdateItemById" />
</Routes>
}

}
