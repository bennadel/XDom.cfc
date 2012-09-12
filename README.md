
# XDom.cfc - XML Traversal And Manipulation ColdFuion Component

by Ben Nadel ([www.bennadel.com][1])

The XDom.cfc is a ColdFusion component that facilitates the traversal and 
manipulation of ColdFusion XML documents. It acts a wrapper to an XML document 
or XML node and provides methods to navigate, access, and update the underlying
Document Object Model (DOM).

## Constructor

The XDom.cfc can be instantiated with a number of constructor arguments:

* XDOM.init( xmlString )
* XDOM.init( xmlFilePath )
* XDOM.init( xmlDoc )
* XDOM.init( xmlNode )
* XDOM.init( arrayOfNodes )
* XDOM.init( XDOM )

## Public Methods:

* XDOM.append( collection [, returnAppendedNodes ] )
* XDOM.end()
* XDOM.find( xPath )
* XDOM.get( [index] )
* XDOM.getAttributeArray( attribute )
* XDOM.getAttributeList( attribute [, delimiter ] )
* XDOM.getValueArray()
* XDOM.getValueList( [ delimiter ] )
* XDOM.remove()



### XDOM.append( collection [, returnAppendedNodes ] )

Adds the given to each top-level node in the current collection. By default, this returns the current collection. If the optional second parameter is passed in, the appended nodes are returned in a new collection. 

### XDOM.end()

This returns the previous collection.

### XDOM.find( xPath )

Applies the given xPath query to each top-level node in the current collection. Returns the unique collection of results.

### XDOM.get( [index] )

Gets the composed collection of nodes. If the optional index is supplied, only that node is returned.

### XDOM.getAttributeArray( attribute )

Returns an array that contains the value of the given attribute extracted from each top-level node in the collection.

### XDOM.getAttributeList( attribute [, delimiter ] )

Returns the attribute array as a list.

### XDOM.getValueArray()

Returns an array that contains the xmlText of the top-level nodes in the collection.

### XDOM.getValueList( [ delimiter ] )

Returns the value array as a list.

### XDOM.remove()

Removes all the top-level nodes in the collection from their respective documents.



[1]: http://www.bennadel.com
