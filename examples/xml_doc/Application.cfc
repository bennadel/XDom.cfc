<cfcomponent
	output="false"
	hint="I define the application settings and event handlers.">


	<!--- Define the application settings. --->
	<cfset this.name = hash( getCurrentTemplatePath() ) />
	<cfset this.applicationTimeout = createTimeSpan( 0, 0, 5, 0 ) />
	<cfset this.sessionManagement = false />

	<!--- Get the current directory. --->
	<cfset this.appDirectory = getDirectoryFromPath( getCurrentTemplatePath() ) />

	<!--- Get the project directory. --->
	<cfset this.projectDirectory = (this.appDirectory & "../../") />

	<!--- Map the lib folder so we can load our XDom.cfc. --->
	<cfset this.mappings[ "/lib" ] = (this.projectDirectory & "lib/") />


	<!--- Turn off all debugging output. --->
	<cfsetting showdebugoutput="false" />


</cfcomponent>