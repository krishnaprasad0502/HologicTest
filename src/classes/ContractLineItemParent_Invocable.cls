/*------------------------------------------------------------
Author:			Denise Bacher
Company:		Salesforce.com
Description:	Invocable Method to set the Parent Contract Line on a Contract Line via it's Quote Line
Test Class:		ContractLineItemParent_Invocable_Test

History:
<Date>			<Authors Name>		<Brief Description of Change>
08/04/2016		Denise Bacher		Initial Creation (US164)
------------------------------------------------------------*/
public with sharing class ContractLineItemParent_Invocable {
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Invocable Method to set the parent contract line item on a contract line
	Inputs:			requests - list of ContractLineItemRequest (represents the contract line item record)
	Returns:		N/A
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	08/04/2016		Denise Bacher		Initial Creation (US164)
	------------------------------------------------------------*/
	@InvocableMethod(label='Set the Parent Contract Line Item' description='Using the Contract Line Item\'s Quote line, find the Parent Contract Line Item.')
	public static void setParentContractLineItem(List<ContractLineItem> contractLineItems){
		// collect the contract line's related quotes
		Map<Id, ContractLineItem> quoteLineToContractLine = new Map<Id, ContractLineItem>();
		for(ContractLineItem cli : contractLineItems){
			if(cli.SBQQSC__QuoteLine__c != null && cli.ParentContractLineItemId == null){
				quoteLineToContractLine.put(cli.SBQQSC__QuoteLine__c, cli);
			}
		}
		
		// query to see if the quote line is required by another quote line
		Map<Id, SBQQ__QuoteLine__c> relatedQuoteLines = new Map<Id, SBQQ__QuoteLine__c>(
			[Select Id, SBQQ__RequiredBy__c, SBQQ__RequiredBy__r.SBQQSC__UpgradedContractLine__c 
			From SBQQ__QuoteLine__c 
			Where Id IN: quoteLineToContractLine.keySet()]
		);
		
		Set<Id> requiredByQuoteLineIds = new Set<Id>();
		for(SBQQ__QuoteLine__c ql : relatedQuoteLines.values()){
			// if the quote line is required by another quote, add it to the set
			if(ql.SBQQ__RequiredBy__c != null){
				requiredByQuoteLineIds.add(ql.SBQQ__RequiredBy__c);
			}
			// else remove the quoteLine and contract line from the map
			else{
				quoteLineToContractLine.remove(ql.Id);
			}
		}
		
		// query contract lines related to the required quote lines
		List<ContractLineItem> parentContractLines = [
			Select Id, SBQQSC__QuoteLine__c 
			From ContractLineItem 
			Where SBQQSC__QuoteLine__c IN: requiredByQuoteLineIds];
		
		Map<Id, ContractLineItem> requiredQuoteLineToParentContractLine = new Map<Id, ContractLineItem>();
		for(ContractLineItem cli : parentContractLines){
			requiredQuoteLineToParentContractLine.put(cli.SBQQSC__QuoteLine__c, cli);
		}
		
		// match the parerent contract line back up to the child contract line
		List<ContractLineItem> linesToUpdate = new List<ContractLineItem>();
		for(Id qlId : quoteLineToContractLine.keySet()){
			// need to clone the ContractLineItem otherwise in the PB we get a "An Apex error occurred: System.FinalException: Record is read-only" error 
			ContractLineItem cli = quoteLineToContractLine.get(qlId).clone(true, true, true, true);
			SBQQ__QuoteLine__c quoteLine = relatedQuoteLines.get(qlId);
			
			if(requiredQuoteLineToParentContractLine.containsKey(quoteLine.SBQQ__RequiredBy__c)){
				cli.ParentContractLineItemId = requiredQuoteLineToParentContractLine.get(quoteLine.SBQQ__RequiredBy__c).Id;
			}
			else{
				cli.ParentContractLineItemId = quoteLine.SBQQ__RequiredBy__r.SBQQSC__UpgradedContractLine__c;
			}
		}
		
		upsert linesToUpdate;
	}
}