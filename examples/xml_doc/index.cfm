
<!--- Create some test XML data that we can manipulate with XDOM. --->
<cfxml variable="data">

	<friends />
		
</cfxml>

<!--- Create an XDOM wrapper instance for our XML data. --->
<cfset friends = createObject( "component", "lib.XDOM" ).init( data ) />


<!--- ---------------------------------------------------- --->
<!--- ---------------------------------------------------- --->


<!--- 
	Here, we are going to demonstrate the append with strings. 
	XDOM will automatically parse XML and append it to the current 
	collection. You can pass an optional second argument to append()
	to have it return the newly appended elements.
	
	As you can see, end() pops you back up to the previous collection
	as it does with jQuery.
--->
<cfset friends
	.append( "<friend />", true )
		.append( "<name isSingle='true'>Sarah</name>" )
		.append( "<age>31</age>" )
		.end()
	.append( "<friend />", true )
		.append( "<name isSingle='false'>Tricia</name>" )
		.append( "<age>33</age>" )
		.end()
	/>


<!--- ---------------------------------------------------- --->
<!--- ---------------------------------------------------- --->


<!--- Now, let's create another XML document. --->
<cfxml variable="newFriend">
	
	<friend>
		<name>Jennifer</name>
		<age>35</age>
		<isSilly>true</isSilly>
	</friend>

</cfxml>

<!--- Create a new XDOM collection. --->
<cfset jenn = createObject( "component", "lib.XDOM" ).init( newFriend ) />


<!--- 
	Let's append our Jenn to our existing friends. Notice that these 
	are two DIFFERENT XML documents with different owners. Because 
	of this, Jenn is actually "copied" into the existing three, 
	*not* imported. Since ColdFusion does not expose an import 
	natively (you can get to it via Java), I wanted to resort to
	copying. 
--->
<cfset friends.append( jenn ) />


<!--- ---------------------------------------------------- --->
<!--- ---------------------------------------------------- --->


<!--- 
	Now, let's say we changed our mind about Jenn's silliness. We 
	want to find the isSilly node, remove it, and append it to Tricia. 
--->
<cfset friends
	.find( "//friend[ name/text() = 'Tricia' ]" )
		.append(
			friends.find( "//isSilly" ).remove()
			)
	/>


<!--- ---------------------------------------------------- --->
<!--- ---------------------------------------------------- --->


<!--- Output our resultant node tree. --->
<cfdump 
	var="#friends.get( 1 )#"
	label="friends XML"
	/>



<br />
<br />
<br />



<!--- Now, let's get some data about our XML tree. --->
<cfoutput>

	<!--- Get the names of the girls. --->
	Friends: 
	#friends.find( "//name" ).getValueList()#

	<br />
	<br />
	
	<!--- Get the aveage age of the girls. --->
	Average Age: 
	#arrayAvg( friends.find( "//age" ).getValueArray() )#

</cfoutput>


