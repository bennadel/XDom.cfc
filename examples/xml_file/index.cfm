
<!--- Create an XDOM wrapper instance for our XML data. --->
<cfset friends = createObject( "component", "lib.XDOM" ).init( 
	expandPath( "./friends.xml" )
	) />
	
<cfdump var="#friends.get()#">