
<cfcomponent
	output="false"
	hint="I provide a utility wrapper for XML objects.">
	
	
	<!--- A flag to help XDom find other XDom collections. --->
	<cfset this.XDOMVersion = "1.0" />
	
	
	<cffunction
		name="init"
		access="public"
		returntype="any"
		output="false"
		hint="I initialize the component.">
		
		<!--- Define arguments. --->
		<cfargument
			name="collection"
			type="any"
			required="false"
			default="#arrayNew( 1 )#"
			hint="I am either a ColdFusion XML object or an array of XML nodes from a given object."
			/>
			
		<!--- Define the local scope. --->
		<cfset var local = {} />
			
		<!--- Start out with an empty collection. We will add to it if we can. --->
		<cfset variables.collection = [] />
			
		<!--- 
			Check to see if this is an XML document or an array. We want to store an array; so, 
			if it is an XML document, we want to get the root element. 
		--->
		<cfif this.isXDOMCollection( arguments.collection )>
		
			<!--- Copy over the collection to this instance. --->
			<cfset variables.collection = arguments.collection.get() />
		
		<cfelseif isArray( arguments.collection )>
		
			<!--- Loop over the elements in the array and add any that are XML elements. --->
			<cfloop
				index="local.collectionItem"
				array="#arguments.collection#">
				
				<!--- Check for XML node. --->
				<cfif isXmlNode( local.collectionItem )>
					
					<!--- Move this node into the collection. --->
					<cfset arrayAppend( variables.collection, local.collectionItem ) />
				
				</cfif>
				
			</cfloop>
		
		<cfelseif isSimpleValue( arguments.collection )>
		
			<!--- 
				Check to see if the incoming string starts with a bracket. If it does, 
				then it's likely XML. If it does not, then we'll try to read it in as
				a file (assuming it is a file-path). 
			--->
			<cfif !reFind( "^\s*<", arguments.collection )>
				
				<!--- 
					The incoming value does not appear to be valid XML. Let's try to 
					read it in as file data and overwrite the string value with the 
					file content.
				--->
				<cfset arguments.collection = fileRead( arguments.collection ) />
			
			</cfif>
			
			<!--- 
				Parse the xml document and store it. When parsing, let's first wrap 
				the incoming XML with a single root node so that we can accomdate 
				malformed XML trees.
			--->
			<cfset variables.collection = xmlParse( "<xdomRootNodeForParsing>#arguments.collection#</xdomRootNodeForParsing>" ).xmlRoot.xmlChildren />
		
		<cfelseif isXmlDoc( arguments.collection )>
		
			<!--- Import the root node. --->
			<cfset variables.collection = [ arguments.collection.xmlRoot ] />
		 
		<cfelseif isXmlNode( arguments.collection )>
		
			<!--- Store the root node as a single-item collection. --->
			<cfset variables.collection = [ arguments.collection ] />	
		
		</cfif>
			
		<!--- Store the previous collection. --->
		<cfset variables.prevCollection = "" />
			
		<!--- Return this object reference. --->
		<cfreturn this />
	</cffunction>
	
	
	<cffunction
		name="append"
		access="public"
		returntype="any"
		output="false"
		hint="I append the given collection to all elements of the current collection.">
		
		<!--- Define arguments. --->
		<cfargument
			name="collection"
			type="any"
			required="true"
			hint="I am the collection being merged into the current collection."
			/>
			
		<cfargument
			name="returnAppendedElements"
			type="boolean"
			required="false"
			default="false"
			hint="By default, this function will return the current collection. However, with this argument, we can get it to return the collection of newly appended elements."
			/>
		
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- Normalize the incoming collection to be an XDom collection. --->
		<cfset local.incomingCollection = this.normalizeXDOMCollection( arguments.collection ) />
		
		<!--- 
			Keep track of the newly appended elements in case we need to return them.
			This will only be the ELEMENT nodes, no attributes.
		--->
		<cfset local.appendedElements = [] />
		
		<!--- Loop over the nodes in the current collection. --->
		<cfloop
			index="local.collectionItem"
			array="#variables.collection#">
			
			<!--- Now, loop over the incoming collection to add it to the current collection item. --->
			<cfloop
				index="local.incomingCollectionItem"
				array="#local.incomingCollection.get()#">
				
				<!--- 
					Check to see if this is an attribute and the local node is an element. 
					If so, we can just add the attribute to the existing node.
				--->
				<cfif (
					isXmlAttribute( local.incomingCollectionItem ) &&
					isXmlElem( local.collectionItem )
					)>
					
					<!--- Copy attribute over. --->
					<cfset local.collectionItem.xmlAttributes[ local.incomingCollectionItem.xmlName ] = local.incomingCollectionItem.xmlValue /> 
					
				<!--- 
					Check to see if both nodes are attributes. If so, then the incoming 
					attribute will be appending to the current parent node.
				--->
				<cfelseif (
					isXmlAttribute( local.incomingCollectionItem ) &&
					isXmlAttribute( local.collectionItem )
					)>
					
					<!--- Get the parent node of the current attribute. --->
					<cfset local.parentNodes = xmlSearch( local.collectionItem, ".." ) />
					
					<!--- Copy attribute over. --->
					<cfset local.parentNodes[ 1 ].xmlAttributes[ local.incomingCollectionItem.xmlName ] = local.incomingCollectionItem.xmlValue /> 
					
				<!--- 
					Check to see if the incoming collection item is an element. If so,
					then we need to create it and copy it over. 
				--->
				<cfelseif (
					isXmlElem( local.incomingCollectionItem ) &&
					isXmlElem( local.collectionItem )
					)>
					
					<!--- Import the incoming node and then attach it to the current node. --->
					<cfset arrayAppend(
						local.collectionItem.xmlChildren,
						this.importXmlTree( 
							this.getXmlDoc( local.collectionItem ), 
							local.incomingCollectionItem
							)
						) />
						
					<!--- 
						Add the imported node to the appended collection. We have to pull 
						this off the tree since nodes are added by value. 
					--->
					<cfset arrayAppend(
						local.appendedElements,
						local.collectionItem.xmlChildren[ arrayLen( local.collectionItem.xmlChildren ) ]
						) />
					
				</cfif>
				
			</cfloop>
			
		</cfloop>	
		
		<!--- Check to see if we are returning the newly appended elements. --->	
		<cfif arguments.returnAppendedElements>
		
			<!--- Create a new collection, push "this" as the previous collection. --->
			<cfreturn this
				.normalizeXDOMCollection( local.appendedElements )
				.setPrevCollection( this ) 
				/>
		
		</cfif>
		
		<!--- Return this object reference for method chaining. --->
		<cfreturn this />
	</cffunction>
	
	
	<cffunction
		name="end"
		access="public"
		returntype="any"
		output="false"
		hint="I return the previous collection or void.">
		
		<!--- Check to see if we have a previous collection. --->
		<cfif this.isXDOMCollection( variables.prevCollection )>
		
			<!--- Return the previous collection. --->
			<cfreturn variables.prevCollection />
		
		<cfelse>
		
			<!--- No previous collection has been found. --->
			<cfreturn />
		
		</cfif>		
	</cffunction>
	
	
	<cffunction
		name="flattenCompoundCollection"
		access="public"
		returntype="array"
		output="false"
		hint="I take an array of arrays (of nodes) and flatten it into a single array.">
		
		<!--- Define arguments --->
		<cfargument
			name="compoundCollection" 
			type="array"
			required="true"
			hint="I am the array of arrays being flattened."
			/>
		
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- Create a collection object to hold the flattened collection. --->
		<cfset local.flattenedCollection = [] />
		
		<!--- Create our unique-node flag. --->
		<cfset local.inUseFlag = "xdomNodeBeingMerged" />
		
		<!--- Loop over the collection parts. --->
		<cfloop
			index="local.collection"
			array="#arguments.compoundCollection#">
			
			<!--- 
				Loop over the current collection to merge it into the flattened 
				collection. As we do this, we will need to check for "unique" 
				nodes. Since we don't want to merge duplicate nodes, we are going 
				to mark them as we get them.
			--->
			<cfloop
				index="local.collectionItem"
				array="#local.collection#">
				
				<!--- 
					Check to see what kind of element we are dealing with. Since 
					attributes cannot be altered, we'll have to add some special logic 
					for the attributes. 
				--->
				<cfif isXmlElem( local.collectionItem )>
				
					<!--- We are dealing with an element. --->
				
					<!--- Make sure that this node is not currently being used. --->
					<cfif !structKeyExists( local.collectionItem.xmlAttributes, local.inUseFlag )>
					
						<!--- Flag this node as being part of the merge operation. --->
						<cfset local.collectionItem.xmlAttributes[ local.inUseFlag ] = "true" />
					
						<!--- Append the node to the flattended collection. --->
						<cfset arrayAppend( 
							local.flattenedCollection,
							local.collectionItem
							) />
					
					</cfif>				
				
				<cfelse>
					
					<!--- We are dealing with an attribute. --->
					
					<!--- 
						Make sure that the attribute is not currently being used. For this,
						we will have to check the parent attributes. Since we might have 
						multiple attributes being pulled back from the same element, we need 
						to build the flag using the hash() of the attribute name. 
					--->
					<cfset local.parentNodes = xmlSearch( local.collectionItem, ".." ) />
					
					<!--- See if the in use flag exists. --->
					<cfif !structKeyExists( local.parentNodes[ 1 ].xmlAttributes, "#local.inUseFlag##hash( local.collectionItem.xmlName )#" )>
					
						<!--- Flag this node as being poart of the merge operation. --->
						<cfset local.parentNodes[ 1 ].xmlAttributes[ "#local.inUseFlag##hash( local.collectionItem.xmlName )#" ] = "true" />
					
						<!--- Append the node to the flattened collection. --->
						<cfset arrayAppend( 
							local.flattenedCollection,
							local.collectionItem
							) />
					
					</cfif>
				
				</cfif>
				
			</cfloop>
			
		</cfloop>
		
		<!--- 
			Now that we have merged all of the items into one collection, remove 
			the inUse flag to leave the DOM unaltered.
		--->
		<cfloop
			index="local.collectionItem"
			array="#local.flattenedCollection#">
			
			<!--- Check to see what kind of node we are looking at. --->
			<cfif isXmlElem( local.collectionItem )>
			
				<!--- Remove the flag directly from the current element. --->
				<cfset structDelete( local.collectionItem.xmlAttributes, local.inUseFlag ) />
				
			<cfelse>
			
				<!--- Get the attribute's containing node. --->
				<cfset local.parentNodes = xmlSearch( local.collectionItem, ".." ) />
				
				<!--- Remove the flag from the attribute's parent element. --->
				<cfset structDelete( local.parentNodes[ 1 ].xmlAttributes, "#local.inUseFlag##hash( local.collectionItem.xmlName )#" ) />
				
			</cfif>
			
		</cfloop>
		
		<!--- Return the flattened node collection. --->
		<cfreturn local.flattenedCollection />
	</cffunction>
	
	
	<cffunction
		name="get"
		access="public"
		returntype="any"
		output="false"
		hint="I return the nodes in the current collection.">
		
		<!--- Define arguments. --->
		<cfargument
			name="index"
			type="numeric"
			required="false"
			default="0"
			hint="I am the index of the node to return. If zero, the entire collection will be returned."
			/>
		
		<!--- Check to see if we want a specific node. --->
		<cfif arguments.index>
		
			<!--- Return a node. --->
			<cfreturn variables.collection[ arguments.index ] />
		
		<cfelse>
		
			<!--- Return the entire collection. --->
			<cfreturn variables.collection />
		
		</cfif>
	</cffunction>
	
	
	<cffunction
		name="getAttributeArray"
		access="public"
		returntype="array"
		output="false"
		hint="I return an array of the values held in the given attribute accross the collection.">
		
		<!--- Define arguments. --->
		<cfargument
			name="attribute"
			type="string"
			required="true"
			hint="I am the attribute for which we are collecting values."
			/>
		
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- Create the array to hold our aggregated attribute values. --->
		<cfset local.values = [] />
		
		<!--- Loop over all the elements in the collection to check for attribute values. --->
		<cfloop
			index="local.collectionItem"
			array="#variables.collection#">
			
			<!--- Check to make sure the attribute exists. --->
			<cfif structKeyExists( local.collectionItem.xmlAttributes, arguments.attribute )>
			
				<!--- Append to the value collection. --->
				<cfset arrayAppend( 
					local.values,
					local.collectionItem.xmlAttributes[ arguments.attribute ]
					) />
			
			</cfif>
			
		</cfloop>
		
		<!--- Return the attribute values. --->
		<cfreturn local.values />
	</cffunction>
	
	
	<cffunction
		name="getAttributeList"
		access="public"
		returntype="string"
		output="false"
		hint="I return a list of the values held in the given attribute accross the collection.">
		
		<!--- Define arguments. --->
		<cfargument
			name="attribute"
			type="string"
			required="true"
			hint="I am the attribute for which we are collecting values."
			/>
			
		<cfargument
			name="delimiter"
			type="string"
			required="false"
			default=","
			hint="I am the delimiter used in the attribute value list."
			/>
		
		<!--- Gather the attribute values as an array and then return them as a list. --->
		<cfreturn arrayToList(
			this.getAttributeArray( arguemnts.attribute ),
			arguments.delimiter
			) />
	</cffunction>
	
	
	<cffunction
		name="getValueArray"
		access="public"
		returntype="array"
		output="false"
		hint="I return an array of the value of the nodes aggregated in the collection. If the nodes are attributes, it returns the value. If the nodes are elements, it returns the text.">
		
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- Define an array to hold the aggregated values. --->
		<cfset local.values = [] />
		
		<!--- Loop over all the elements in the collection to check for attribute values. --->
		<cfloop
			index="local.collectionItem"
			array="#variables.collection#">
			
			<!--- 
				Check to see what kind of node we are dealing with so we know how to 
				access the "Value".
			--->
			<cfif isXmlElem( local.collectionItem )>
				
				<!--- We are dealing with an element node. --->
				<cfset arrayAppend( 
					local.values,
					local.collectionItem.xmlText
					) />
			
			<cfelse>
			
				<!--- We are dealing with an attribute node. --->
				<cfset arrayAppend( 
					local.values,
					local.collectionItem.xmlValue
					) />
			
			</cfif>
			
		</cfloop>
		
		<!--- Return the values. --->
		<cfreturn local.values />
	</cffunction>
	
	
	<cffunction
		name="getValueList"
		access="public"
		returntype="string"
		output="false"
		hint="I return a list of the value of the nodes aggregated in the collection. If the nodes are attributes, it returns the value. If the nodes are elements, it returns the text.">
		
		<!--- Define arguments. --->
		<cfargument
			name="delimiter"
			type="string"
			required="false"
			default=","
			hint="I am the delimiter used in the value list."
			/>
		
		<!--- Gather the values as an array and then return them as a list. --->
		<cfreturn arrayToList(
			this.getValueArray(),
			arguments.delimiter
			) />
	</cffunction>
	
	
	<cffunction
		name="getXmlDoc"
		access="public"
		returntype="any"
		output="false"
		hint="I get the XML document for the given XML node.">
		
		<!--- Define arguments. --->
		<cfargument
			name="node"
			type="any"
			required="true"
			hint="I am the node for which we are getting the XML document object."
			/>
			
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- Get the document nodes. --->
		<cfset local.docNodes = xmlSearch( arguments.node, "/*/.." ) />
		
		<!--- Return the first (only) doc node. --->
		<cfreturn local.docNodes[ 1 ] />		
	</cffunction>
	
	
	<cffunction
		name="find_"
		access="public"
		returntype="any"
		output="false"
		hint="I look for the given XPath on each of the nodes in the current collection.">
		
		<!--- Define arguments. --->
		<cfargument
			name="xpath"
			type="string"
			required="true"
			hint="I am the XPath query to apply to each node in the current collection."
			/>
		
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- Create an array to hold the aggregration of all the matching nodes. --->
		<cfset local.compoundCollection = [] />
		
		<!--- Loop over each node in the collection to start searching for nodes. --->
		<cfloop 
			index="local.collectionItem"
			array="#variables.collection#">
			
			<!--- Get the target nodes from this collection item (if there are any). --->
			<cfset local.nodes = xmlSearch( local.collectionItem, arguments.xpath ) />
			
			<!--- Add all the located nodes to the ongoing collection. --->
			<cfset arrayAppend( 
				local.compoundCollection, 
				local.nodes
				) />
			
		</cfloop>
		
		<!--- Create the new collection. --->
		<cfset local.newCollection = this.normalizeXDOMCollection( 
			this.flattenCompoundCollection( local.compoundCollection )
			) />
			
		<!--- Push "this" as the previous collection. --->
		<cfset local.newCollection.setPrevCollection( this ) />
		
		<!--- Return a new XQuery instance for the new collection. --->
		<cfreturn local.newCollection />
	</cffunction>
	
	
	<cffunction
		name="importXmlTree"
		access="public"
		returntype="any"
		output="false"
		hint="I import the given tree into the given node.">
		
		<!--- Define arguments. --->
		<cfargument
			name="xmlDoc"
			type="any"
			required="true"
			hint="I am a node of tree into which the other tree is being imported."
			/>
			
		<cfargument
			name="xmlTree"
			type="any"
			required="true"
			hint="I am the XML tree being imported."
			/>
			
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- Create a new node based on the incoming node. --->
		<cfset local.node = xmlElemNew( arguments.xmlDoc, arguments.xmlTree.xmlName ) />
		
		<!--- Copy over all the attributes. --->
		<cfset structAppend( local.node.xmlAttributes, arguments.xmlTree.xmlAttributes ) />
		
		<!--- Copy over the node text. --->
		<cfset local.node.xmlText = arguments.xmlTree.xmlText />
		
		<!--- Import all the children. --->
		<cfloop
			index="local.xmlTreeChild"
			array="#arguments.xmlTree.xmlChildren#">
			
			<!--- Import this child recursively and add it to the current node. --->
			<cfset arrayAppend(
				local.node.xmlChildren,
				this.importXmlTree( arguments.xmlDoc, local.xmlTreeChild )
				) />
			
		</cfloop>
		
		<!--- Return the new node. --->
		<cfreturn local.node />
	</cffunction>
	
	
	<cffunction
		name="isXDOMCollection"
		access="public"
		returntype="boolean"
		output="false"
		hint="I determine if the given value is an XDom collection.">
		
		<!--- Define arguments. --->
		<cfargument
			name="value"
			type="any"
			required="true"
			hint="I am the value being tested."
			/>
		
		<!--- Return XDOM'ness. --->
		<cfreturn (
			isStruct( arguments.value ) &&
			structKeyExists( arguments.value, "XDOMVersion" ) &&
			structKeyExists( arguments.value, "isXDomCollection" ) &&
			structKeyExists( arguments.value, "get" )
			) />
	</cffunction>
	
	
	<cffunction
		name="normalizeXDOMCollection"
		access="public"
		returntype="any"
		output="false"
		hint="I take a collection and convert it to an XDom collection if it is not already.">
		
		<!--- Define arguments. --->
		<cfargument
			name="collection"
			type="any"
			required="true"
			hint="I am the collection being normalized."
			/>
		
		<!--- If this is already an XDom collection, then just return it. --->
		<cfif this.isXDOMCollection( arguments.collection )>
			
			<!--- Return as-is. --->
			<cfreturn arguments.collection />
		
		<cfelse>
		
			<!--- Convert to an XDom collection. --->
			<cfreturn createObject( "component", "XDOM" ).init( arguments.collection ) />
		
		</cfif>		
	</cffunction>
	
	
	<cffunction
		name="remove"
		access="public"
		returntype="any"
		output="false"
		hint="I remove all the node in the current collection from their parent document.">
		
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- Define the delete flag. --->
		<cfset local.deleteFlag = "xdomDeleteFlag" />
		
		<!--- Loop over the current collection. --->
		<cfloop
			index="local.collectionItem"
			array="#variables.collection#">
			
			<!--- 
				Get the parent node. We need to do this regardless of the type of node
				we are removing. 
			--->
			<cfset local.parentNodes = xmlSearch( local.collectionItem, ".." ) />
			
			<!--- Check to see what kind of node we are dealing with. --->
			<cfif isXmlAttribute( local.collectionItem )>
			
				<!--- Delete this attribute from the parent node. --->
				<cfset structDelete( 
					local.parentNodes[ 1 ].xmlAttributes,
					local.collectionItem.xmlName
					) />
			
			<cfelseif isXmlElem( local.collectionItem )>
			
				<!--- 
					Since we don't know the position of this node in the parent sibling set,
					we have to apply the delete flag and then seach for it. 
				--->
				<cfset local.collectionItem.xmlAttributes[ local.deleteFlag ] = "true" />
			
				<!--- Loop over the parent's children to find the location. --->
				<cfloop
					index="local.childIndex"
					from="1"
					to="#arrayLen( local.parentNodes[ 1 ].xmlChildren )#"
					step="1">
					
					<!--- Check to see if this is the node we are deleting. --->
					<cfif structKeyExists( local.parentNodes[ 1 ].xmlChildren[ local.childIndex ].xmlAttributes, local.deleteFlag )>
					
						<!--- Delete the node. --->
						<cfset arrayDeleteAt( 
							local.parentNodes[ 1 ].xmlChildren,
							local.childIndex
							) />
							
						<!--- Remove the delete flag. --->
						<cfset structDelete( local.collectionItem.xmlAttributes, local.deleteFlag ) /> 
					
						<!--- Break out of the loop - no more items to delete on this pass. --->
						<cfbreak />
						
					</cfif> 
					
				</cfloop>
			
			</cfif>
			
		</cfloop>		
		
		<!--- Return this object reference for method chaining. --->
		<cfreturn this />		
	</cffunction>
	
	
	<cffunction
		name="setPrevCollection"
		access="public"
		returntype="any"
		output="false"
		hint="I set the previous collection (for use with end()).">
		
		<!--- Define arguments. --->
		<cfargument
			name="collection"
			type="any"
			required="true"
			hint="I am the previous collection."
			/>
			
		<!--- Store the previous collection. --->
		<cfset variables.prevCollection = arguments.collection />
		
		<!--- Return this object reference for method chaining. --->
		<cfreturn this />
	</cffunction>
	
	
	<!--- ------------------------------------------------- --->
	<!--- ------------------------------------------------- --->
	<!--- ------------------------------------------------- --->
	<!--- ------------------------------------------------- --->
	
	
	<!--- 
		Replace the "native" methods that we were not allowed to define at 
		compile time.
	--->
	<cfset this.find = this.find_ />
	
	<!--- Delete the old references. ---> 
	<cfset structDelete( this, "find_" ) />
	
</cfcomponent>
