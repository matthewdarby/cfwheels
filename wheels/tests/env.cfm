<cfset application.wheels.modelPath = listprepend("wheels/tests", application.wheels.rootPath, "/")>
<cfset application.wheels.modelComponentPath = listchangedelims(listprepend("wheels.tests", application.wheels.rootcomponentPath, '.'), '.', '.')>
<cfset application.wheels.dataSourceName = "wheelstestdb">
<cfset application.wheels.dataSourceUserName = "wheelstestdb">
<cfset application.wheels.dataSourcePassword = "wheelstestdb">
<!--- unload all plugins before running core tests --->
<cfset application.wheels.plugins = {}>
<cfset application.wheels.mixins = {}>