Class Services.REST.API.RestHandler Extends %CSP.REST
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <!--Route to login-->
    <Route Url="/Login" Method="POST" Call="Services.REST.API.Auth.Authentication:LoginUser" />
    <Route Url="/Create" Method="POST" Call="Services.REST.API.Auth.Authentication:CreateUser" />
    <Route Url="/Logout" Method="POST" Call="Services.REST.API.Auth.Authentication:LogoutUser" />
</Routes>
}

}
