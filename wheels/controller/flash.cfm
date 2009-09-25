<cffunction name="flash" returntype="any" access="public" output="false" hint="Gets the value of a specific key in the Flash (or the entire flash as a struct if no key is passed in).">
	<cfargument name="key" type="string" required="false" default="" hint="The key to get the value for">
	<cfreturn $namedReadLock(name="flash", object=this, method="$flash", args=arguments, timeout=5)>
</cffunction>

<cffunction name="$flash" returntype="any" access="public" output="false">
	<cfargument name="key" required="false" type="string" default="" />
	<cfscript>
		var returnValue = "";
		if (Len(arguments.key))
		{
			if (StructKeyExists(session.flash, arguments.key))
				returnValue = session.flash[arguments.key];
		}
		else
		{
			// we can just return session.flash since it is created at the beginning of the request
			// this way we always return what is expected - a struct
			returnValue = session.flash;
		}
	</cfscript>
	<cfreturn returnValue>
</cffunction>

<cffunction name="flashClear" returntype="void" access="public" output="false" hint="Deletes everything from the Flash.">
	<cfset $simpleLock(name="flash", type="exclusive", execute="$flashClear") />
</cffunction>

<cffunction name="$flashClear" returntype="void" access="public" output="false">
	<cfset session.flash = {} />
</cffunction>

<cffunction name="flashCount" returntype="numeric" access="public" output="false" hint="Checks how many keys exist in the Flash.">
	<cfreturn $namedReadLock(name="flash", object=this, method="$flashCount", timeout=5)>
</cffunction>

<cffunction name="$flashCount" returntype="numeric" access="public" output="false">
	<cfreturn StructCount(session.flash)>
</cffunction>

<cffunction name="flashDelete" returntype="boolean" access="public" output="false" hint="Deletes a specific key from the Flash.">
	<cfargument name="key" type="string" required="true" hint="The key to delete">
	<cfreturn $simpleLock(name="flash", type="exclusive", execute="$flashDelete", executeArgs=arguments)>
</cffunction>

<cffunction name="$flashDelete" returntype="boolean" access="public" output="false">
	<cfargument name="key" type="string" required="true">
	<cfreturn StructDelete(session.flash, arguments.key, true)>
</cffunction>

<cffunction name="flashInsert" returntype="void" access="public" output="false" hint="Inserts a new key/value to the Flash.">
	<cfset $simpleLock(name="flash", type="exclusive", execute="$flashInsert", executeArgs=arguments) />
</cffunction>

<cffunction name="$flashInsert" returntype="void" access="public">
	<cfset session.flash[StructKeyList(arguments)] = arguments[1] />
</cffunction>

<cffunction name="flashIsEmpty" returntype="boolean" access="public" output="false" hint="Checks if the Flash is empty.">
	<cfreturn NOT flashCount()>
</cffunction>

<cffunction name="flashKeyExists" returntype="boolean" access="public" output="false" hint="Checks if a specific key exists in the Flash.">
	<cfargument name="key" type="string" required="true" hint="The key to check if it exists">
	<cfreturn $namedReadLock(name="flash", object=this, method="$flashKeyExists", args=arguments, timeout=5)>
</cffunction>

<cffunction name="$flashKeyExists" returntype="boolean" access="public" output="false">
	<cfargument name="key" type="string" required="true">
	<cfreturn StructKeyExists(session.flash, arguments.key)>
</cffunction>
