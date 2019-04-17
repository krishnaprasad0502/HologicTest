/*------------------------------------------------------------
  Author: Yogi     
  Company: Salesforce   
  Description:  Prevent pricing batch job from getting triggered when fields from PricingCalcByPass fieldset on QL object is updated 
                Runs before update
  Inputs:      Quote Lines - The list of Quote Line records to bypass
  Returns:    N/A
  
  History:
  <Date>      <Authors Name>    <Brief Description of Change>
  05/11/2017   Yogi              Initial Creation (HD-4290)
  25/09/2018   krishna           US-0005533--Apex CPU time limit exceeded
  ------------------------------------------------------------*/
public with sharing class QuoteLineTriggerActions {
  
  /*------------------------------------------------------------
  Author: Yogi     
  Company: Salesforce   
  Description:  Prevent pricing batch job from getting triggered when fields from PricingCalcByPass fieldset on QL object is updated 
                Runs before update
  Inputs:      Quote Lines - The list of Quote Line records to bypass
  Returns:    N/A
  
  History:
  <Date>      <Authors Name>    <Brief Description of Change>
  05/11/2017   Yogi              Initial Creation (HD-4290)
  ------------------------------------------------------------*/
  public static void checkFieldsAndDisableTrigger(List<SBQQ__QuoteLine__c> oldQuoteLines, List<SBQQ__QuoteLine__c> newQuoteLines){
    
    boolean relevantFieldUpdated = false; //tracks if fields outside Field set have been updated
    
    //get all Quote Line fields
    Schema.DescribeSObjectResult r = SBQQ__QuoteLine__c.sObjectType.getDescribe();
    Set<String>quoteLineFields =  new Set<String>();
    for(string apiName : r.fields.getMap().keySet()){
       quoteLineFields.add(apiName);  
    }
    System.debug('quoteLineFields: ' + quoteLineFields);
    
    
    //Get all fields in Field set for trigger bypass
    Schema.FieldSet fs = Schema.SObjectType.SBQQ__QuoteLine__c.fieldSets.PricingCalcByPass;
    //system.debug(fs);

    Set<String> quoteLineFieldSetFields = new Set<String>();
    for(Schema.FieldSetMember fsm : fs.getFields()) {
            quoteLineFieldSetFields.add(fsm.getFieldPath().toLowerCase()); // converting to lowercase as DescribeSObjectResult returns lower case
    }

    system.debug('quoteLineFieldSetFields: ' + quoteLineFieldSetFields);
    
    //Remove the Field set fields from the full quote line fields
    quoteLineFields.removeAll(quoteLineFieldSetFields);
    system.debug('quoteLineFieldSetFields after FS removal: ' + quoteLineFields);
    
    //25/09/2018   krishna           US-0005533--Apex CPU time limit exceeded
    //check if any of the remaining fields have changed
    /*for(Integer i=0;i<newQuoteLines.size();i++){
        
        system.debug('checking quote line Id :' + oldQuoteLines[i].Id);
        
        for (String field: quoteLineFields){
            //system.debug('checking field :' + field);
            if (oldQuoteLines[i].get(field) != newQuoteLines[i].get(field)){
                relevantFieldUpdated = true;
                system.debug('Field updated: ' + field);
                break;
            }
        }
        
        if (relevantFieldUpdated){
            break;
        }
    }*/
    //****************//
    //25/09/2018   krishna           US-0005533--Apex CPU time limit exceeded
    
    Integer count = 0;
    for (String field: quoteLineFields){
        if (oldQuoteLines[count].get(field) != newQuoteLines[count].get(field)){
            relevantFieldUpdated = true;
            system.debug('Field updated: ' + field);
            count ++;
            break;
        }
    
    }
     //****************//
    system.debug('relevantFieldUpdated? : ' + relevantFieldUpdated);
    
    //Disable trigger for transation context only if relevant fields are not updated
    if (!relevantFieldUpdated){
        SBQQ.TriggerControl.getInstance().setDisabled();
        system.debug('TriggerControl method called');
    }
  }
}