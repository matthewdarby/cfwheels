<cffunction name="$setDefaultValues" returntype="any" access="public" output="false">
	<cfscript>
		var loc = {};
		loc.iEnd = ListLen(variables.wheels.class.propertyList);
		for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
		{
			loc.iItem = ListGetAt(variables.wheels.class.propertyList, loc.i);
			if (Len(variables.wheels.class.properties[loc.iItem].defaultValue) && (!StructKeyExists(this, loc.iItem) || !Len(this[loc.iItem])))
			{
				// set the default value unless it is blank or a value already exists for that property on the object
				this[loc.iItem] = variables.wheels.class.properties[loc.iItem].defaultValue;
			}
		}
	</cfscript>
</cffunction>

<cffunction name="table" returntype="void" access="public" output="false" hint="Use this method to tell Wheels what database table to connect to for this model. You only need to use this method when your table naming does not follow the standard Wheels conventions of a singular object name mapping to a plural table name (i.e. `User.cfc` mapping to the table `users` for example).">
	<cfargument name="name" type="string" required="true" hint="Name of the table to map this model to">
	<cfscript>
		variables.wheels.class.tableName = arguments.name;
	</cfscript>
</cffunction>

<cffunction name="tableName" returntype="string" access="public" output="false" hint="Returns the name of the database table that this model is mapped to.">
	<cfreturn variables.wheels.class.tableName>
</cffunction>

<cffunction name="property" returntype="void" access="public" output="false" hint="Use this method to map an object property to either a table column with a different name than the property, to a specific SQL calculation or to a ColdFusion method. You only need to use this method when you want to override the default mapping that Wheels performs (i.e. `user.firstName` mapping to `users.firstname` for example).">
	<cfargument name="name" type="string" required="true" hint="Name of the property">
	<cfargument name="column" type="string" required="false" default="" hint="Name of the column to map the property to">
	<cfargument name="sql" type="string" required="false" default="" hint="SQL to use to calculate property value">
	<cfscript>
		variables.wheels.class.mapping[arguments.name] = {};
		if (Len(arguments.column))
		{
			variables.wheels.class.mapping[arguments.name].type = "column";
			variables.wheels.class.mapping[arguments.name].value = arguments.column;
		}
		else if (Len(arguments.sql))
		{
			variables.wheels.class.mapping[arguments.name].type = "sql";
			variables.wheels.class.mapping[arguments.name].value = arguments.sql;
		}
	</cfscript>
</cffunction>

<cffunction name="onMissingMethod" returntype="any" access="public" output="false">
	<cfargument name="missingMethodName" type="string" required="true">
	<cfargument name="missingMethodArguments" type="struct" required="true">
	<cfscript>
		var loc = {};
		if (Right(arguments.missingMethodName, 10) == "hasChanged")
			loc.returnValue = hasChanged(property=ReplaceNoCase(arguments.missingMethodName, "hasChanged", ""));
		else if (Right(arguments.missingMethodName, 11) == "changedFrom")
			loc.returnValue = changedFrom(property=ReplaceNoCase(arguments.missingMethodName, "changedFrom", ""));
		else if (Left(arguments.missingMethodName, 9) == "findOneBy" || Left(arguments.missingMethodName, 9) == "findAllBy")
		{
			if (StructKeyExists(server, "railo"))
				loc.finderProperties = ListToArray(LCase(ReplaceNoCase(ReplaceNoCase(ReplaceNoCase(arguments.missingMethodName, "And", "|"), "findAllBy", ""), "findOneBy", "")), "|"); // since Railo passes in the method name in all upper case we have to do this here
			else
				loc.finderProperties = ListToArray(ReplaceNoCase(ReplaceNoCase(Replace(arguments.missingMethodName, "And", "|"), "findAllBy", ""), "findOneBy", ""), "|");
			loc.firstProperty = loc.finderProperties[1];
			loc.secondProperty = IIf(ArrayLen(loc.finderProperties) == 2, "loc.finderProperties[2]", "");
			if (StructCount(arguments.missingMethodArguments) == 1)
				loc.firstValue = Trim(ListFirst(arguments.missingMethodArguments[1]));
			else if (StructKeyExists(arguments.missingMethodArguments, "value"))
				loc.firstValue = arguments.missingMethodArguments.value;
			else if (StructKeyExists(arguments.missingMethodArguments, "values"))
				loc.firstValue = Trim(ListFirst(arguments.missingMethodArguments.values));
			loc.addToWhere = "#loc.firstProperty# = '#loc.firstValue#'";
			if (Len(loc.secondProperty))
			{
				if (StructCount(arguments.missingMethodArguments) == 1)
					loc.secondValue = Trim(ListLast(arguments.missingMethodArguments[1]));
				else if (StructKeyExists(arguments.missingMethodArguments, "values"))
					loc.secondValue = Trim(ListLast(arguments.missingMethodArguments.values));
				loc.addToWhere = loc.addToWhere & " AND #loc.secondProperty# = '#loc.secondValue#'";
			}
			arguments.missingMethodArguments.where = IIf(StructKeyExists(arguments.missingMethodArguments, "where"), "'(' & arguments.missingMethodArguments.where & ') AND (' & loc.addToWhere & ')'", "loc.addToWhere");
			StructDelete(arguments.missingMethodArguments, "1");
			StructDelete(arguments.missingMethodArguments, "value");
			StructDelete(arguments.missingMethodArguments, "values");
			loc.returnValue = IIf(Left(arguments.missingMethodName, 9) == "findOneBy", "findOne(argumentCollection=arguments.missingMethodArguments)", "findAll(argumentCollection=arguments.missingMethodArguments)");
		}
		else
		{
			for (loc.key in variables.wheels.class.associations)
			{
				loc.method = "";
				if (StructKeyExists(variables.wheels.class.associations[loc.key], "shortcut") && arguments.missingMethodName == variables.wheels.class.associations[loc.key].shortcut)
				{
					loc.method = "findAll";
					loc.joinAssociation = $expandedAssociations(include=loc.key);
					loc.joinAssociation = loc.joinAssociation[1];
					loc.joinClass = loc.joinAssociation.class;
					loc.info = model(loc.joinClass).$expandedAssociations(include=ListFirst(variables.wheels.class.associations[loc.key].through));
					loc.info = loc.info[1];
					loc.include = ListLast(variables.wheels.class.associations[loc.key].through);
					if (StructKeyExists(arguments.missingMethodArguments, "include"))
						loc.include = "#loc.include#(#arguments.missingMethodArguments.include#)";
					arguments.missingMethodArguments.include = loc.include;
					loc.where = $keyWhereString(properties=loc.joinAssociation.foreignKey, keys=variables.wheels.class.keys);
					if (StructKeyExists(arguments.missingMethodArguments, "where"))
						loc.where = "(#loc.where#) AND (#arguments.missingMethodArguments.where#)";
					arguments.missingMethodArguments.where = loc.where;
					if (!StructKeyExists(arguments.missingMethodArguments, "returnIncluded"))
						arguments.missingMethodArguments.returnIncluded = false;
				}
				else if (ListFindNoCase(variables.wheels.class.associations[loc.key].methods, arguments.missingMethodName))
				{
					loc.name = ReplaceNoCase(ReplaceNoCase(arguments.missingMethodName, pluralize(loc.key), "objects"), singularize(loc.key), "object"); // set name from "posts" to "objects", for example, so we can use it in the switch below
					loc.info = $expandedAssociations(include=loc.key);
					loc.info = loc.info[1];
					loc.where = $keyWhereString(properties=loc.info.foreignKey, keys=variables.wheels.class.keys);
					if (StructKeyExists(arguments.missingMethodArguments, "where"))
						loc.where = "(#loc.where#) AND (#arguments.missingMethodArguments.where#)";
					if (loc.info.type == "hasOne")
					{
						if (loc.name == "object")
						{
							loc.method = "findOne";
							arguments.missingMethodArguments.where = loc.where;
						}
						else if (loc.name == "hasObject")
						{
							loc.method = "exists";
							arguments.missingMethodArguments.where = loc.where;
						}
						else if (loc.name == "newObject")
						{
							loc.method = "new";
							$setForeignKeyValues(missingMethodArguments=arguments.missingMethodArguments, keys=loc.info.foreignKey);
						}
						else if (loc.name == "createObject")
						{
							loc.method = "create";
							$setForeignKeyValues(missingMethodArguments=arguments.missingMethodArguments, keys=loc.info.foreignKey);
						}
						else if (loc.name == "removeObject")
						{
							loc.method = "updateOne";
							arguments.missingMethodArguments.where = loc.where;
							$setForeignKeyValues(missingMethodArguments=arguments.missingMethodArguments, keys=loc.info.foreignKey, setToNull=true);
						}
						else if (loc.name == "deleteObject")
						{
							loc.method = "deleteOne";
							arguments.missingMethodArguments.where = loc.where;
						}
						else if (loc.name == "setObject")
						{
							loc.method = "updateByKey";
							$setForeignKeyValues(missingMethodArguments=arguments.missingMethodArguments, keys=loc.info.foreignKey);
							$setObjectOrNumberToKey(arguments.missingMethodArguments);
						}
					}
					else if (loc.info.type == "hasMany")
					{
						if (loc.name == "objects")
						{
							loc.method = "findAll";
							arguments.missingMethodArguments.where = loc.where;
						}
						else if (loc.name == "addObject")
						{
							loc.method = "updateByKey";
							$setForeignKeyValues(missingMethodArguments=arguments.missingMethodArguments, keys=loc.info.foreignKey);
							$setObjectOrNumberToKey(arguments.missingMethodArguments);
						}
						else if (loc.name == "removeObject")
						{
							loc.method = "updateByKey";
							$setForeignKeyValues(missingMethodArguments=arguments.missingMethodArguments, keys=loc.info.foreignKey, setToNull=true);
							$setObjectOrNumberToKey(arguments.missingMethodArguments);
						}
						else if (loc.name == "deleteObject")
						{
							loc.method = "deleteByKey";
							$setObjectOrNumberToKey(arguments.missingMethodArguments);
						}
						else if (loc.name == "hasObjects")
						{
							loc.method = "exists";
							arguments.missingMethodArguments.where = loc.where;
						}
						else if (loc.name == "newObject")
						{
							loc.method = "new";
							$setForeignKeyValues(missingMethodArguments=arguments.missingMethodArguments, keys=loc.info.foreignKey);
						}
						else if (loc.name == "createObject")
						{
							loc.method = "create";
							$setForeignKeyValues(missingMethodArguments=arguments.missingMethodArguments, keys=loc.info.foreignKey);
						}
						else if (loc.name == "objectCount")
						{
							loc.method = "count";
							arguments.missingMethodArguments.where = loc.where;
						}
						else if (loc.name == "findOneObject")
						{
							loc.method = "findOne";
							arguments.missingMethodArguments.where = loc.where;
						}
						else if (loc.name == "removeAllObjects")
						{
							loc.method = "updateAll";
							arguments.missingMethodArguments.where = loc.where;
							$setForeignKeyValues(missingMethodArguments=arguments.missingMethodArguments, keys=loc.info.foreignKey, setToNull=true);
						}
						else if (loc.name == "deleteAllObjects")
						{
							loc.method = "deleteAll";
							arguments.missingMethodArguments.where = loc.where;
						}
					}
					else if (loc.info.type == "belongsTo")
					{
						if (loc.name == "object")
						{
							loc.method = "findByKey";
							arguments.missingMethodArguments.key = $propertyValue(name=loc.info.foreignKey);
						}
						else if (loc.name == "hasObject")
						{
							loc.method = "exists";
							arguments.missingMethodArguments.key = $propertyValue(name=loc.info.foreignKey);
						}
					}
				}
				if (Len(loc.method))
					loc.returnValue = $invoke(componentReference=model(loc.info.class), method=loc.method, argumentCollection=arguments.missingMethodArguments);
			}
		}
		if (!StructKeyExists(loc, "returnValue"))
			$throw(type="Wheels.MethodNotFound", message="The method #arguments.missingMethodName# was not found in this model.", extendedInfo="Check your spelling or add the method to the model CFC file.");
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="columnNames" returntype="string" access="public" output="false" hint="Returns a list of column names (ordered by their position in the database table).">
	<cfreturn variables.wheels.class.columnList>
</cffunction>

<cffunction name="propertyNames" returntype="string" access="public" output="false" hint="Returns a list of property names (ordered by their respective column's position in the database table).">
	<cfreturn variables.wheels.class.propertyList>
</cffunction>

<cffunction name="dataSource" returntype="void" access="public" output="false" hint="Use this method to override the data source connection information for a particular model.">
	<cfargument name="datasource" type="string" required="true" hint="the data source name to connect to">
	<cfargument name="username" type="string" required="false" default="" hint="the username for the data source">
	<cfargument name="password" type="string" required="false" default="" hint="the password for the data source">
	<cfscript>
		StructAppend(variables.wheels.class.connection, arguments, true);
	</cfscript>
</cffunction>

<cffunction name="$setObjectOrNumberToKey" returntype="void" access="public" output="false">
	<cfargument name="missingMethodArguments" type="struct" required="true">
	<cfscript>
		var loc = {};
		loc.keyOrObject = arguments.missingMethodArguments[ListFirst(StructKeyList(arguments.missingMethodArguments))];
		StructDelete(arguments.missingMethodArguments, ListFirst(StructKeyList(arguments.missingMethodArguments)));
		if (IsObject(loc.keyOrObject))
			arguments.missingMethodArguments.key = loc.keyOrObject.key();
		else
			arguments.missingMethodArguments.key = loc.keyOrObject;
	</cfscript>
</cffunction>

<cffunction name="$propertyValue" returntype="string" access="public" output="false">
	<cfargument name="name" type="string" required="true">
	<cfscript>
		var loc = {};
		loc.returnValue = "";
		loc.iEnd = ListLen(arguments.name);
		for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
		{
			loc.returnValue = ListAppend(loc.returnValue, this[ListGetAt(arguments.name, loc.i)]);
		}
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$setForeignKeyValues" returntype="void" access="public" output="false">
	<cfargument name="missingMethodArguments" type="struct" required="true">
	<cfargument name="keys" type="string" required="true">
	<cfargument name="setToNull" type="boolean" required="false" default="false">
	<cfscript>
		var loc = {};
		loc.iEnd = ListLen(arguments.keys);
		for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
		{
			if (arguments.setToNull)
				arguments.missingMethodArguments[ListGetAt(arguments.keys, loc.i)] = "";
			else
				arguments.missingMethodArguments[ListGetAt(arguments.keys, loc.i)] = this[ListGetAt(variables.wheels.class.keys, loc.i)];
		}
	</cfscript>
</cffunction>

<cffunction name="properties" returntype="any" access="public" output="false">
	<cfargument name="values" type="any" required="false" default="">
	<cfscript>
	var loc = {};

	// when a structure is passed in, set the properties of the object to values within the structure
	if(isStruct(arguments.values))
	{
		for(loc.key in arguments.values)
		{
			if(ListFindNoCase(variables.wheels.class.propertyList, loc.key))
			{
				this[loc.key] = arguments.values[loc.key];
			}
		}
		return;
	}

	// by default we will return a structure containing the properties and their current values
	loc.returnvalue = {};
	loc.properties = ListToArray(variables.wheels.class.propertyList);
	loc.iEnd = ArrayLen(loc.properties);
	for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
	{
		loc.property = loc.properties[loc.i];
		loc.returnvalue[loc.property] = "";
		if(structkeyexists(this, loc.property))
		{
			loc.returnvalue[loc.property] = this[loc.property];
		}
		else
		{
			loc.returnvalue[loc.property] = variables.wheels.class.properties[loc.property].defaultValue;
		}
	}
	return loc.returnvalue;
	</cfscript>
</cffunction>