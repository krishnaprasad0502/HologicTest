/*------------------------------------------------------------
Author:			Denise Bacher
Company:		Salesforce.com
Description:	Generic container for objects displayed in a Hierarchy
Test Class:		

History:
<Date>			<Authors Name>		<Brief Description of Change>
03/25/2016		Denise Bacher		Initial Creation
04/07/2016		Denise Bacher		Update to allow nodes to be collapsed by default (US539)
------------------------------------------------------------*/
global class ObjectNode {
	public String nodeId {get; set;}				// ID of the SObject
	public String nodeName {get; set;}				// Name or Label correspidning to the SObject
	public Integer nodeLevel {get; set;}			// Level of the node
	public String nodeParentId {get; set;}			// ID of the Parent SObject
	public Boolean isSelectedObject {get; set;}		// Is this the object that was initially selected
	public Boolean isTopNode {get; set;}			// Is this the upper most object in the hierarchy
	public Boolean hasMissingParent {get; set;}		// Does this node have a parent that is not being displayed
	public Boolean hasMissingChildren {get; set;}	// Does this node have children that are not being displayed
	public Boolean defaultCollapsed {get; set;}		// Does this node default to being expanded
	public List<ObjectNode> nodeChildren {get; set;}// List of the current node's children
	
	public ObjectNode(String nId, String nName, Integer nLevel, String nParentId, Boolean nMissingParent, Boolean nSelected, Boolean nTopNode){
		nodeId = nId;
		nodeName = nName;
		nodeLevel = nLevel;
		nodeParentId = nParentId;
		hasMissingParent = nMissingParent;
		isSelectedObject = nSelected;
		isTopNode = nTopNode;
		nodeChildren = new List<ObjectNode>();
		
		hasMissingChildren = false;
		defaultCollapsed = false;
	}
}