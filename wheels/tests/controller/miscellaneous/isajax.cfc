<cfcomponent extends="wheels.test">

	<cfset global.controller = createobject("component", "wheels.controller") />

	<cffunction name="test_isAjax_valid">
		<cfset loc.scope = {http_x_requested_with="XMLHTTPRequest"}>
		<cfset assert('global.controller.isAjax(loc.scope) eq true')>
	</cffunction>

	<cffunction name="test_isAjax_invalid">
		<cfset loc.scope = {http_x_requested_with=""}>
		<cfset assert('global.controller.isAjax(loc.scope) eq false')>
	</cffunction>

	<cffunction name="test_isAjax_scope_empty_invalid">
		<cfset loc.scope = {}>
		<cfset assert('global.controller.isAjax(loc.scope) eq false')>
	</cffunction>

</cfcomponent>