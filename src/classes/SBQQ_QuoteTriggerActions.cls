/*------------------------------------------------------------
Author:     Kasmoor Reddy
Description:  Trigger framework for SBQQ__Quote__c object
Test Class:    SBQQ_QuoteTrigger_Test

History:
<Date>      <Authors Name>    <Brief Description of Change>
09/28/2017   Kasmoor Reddy    Initial Creation(US3470)
------------------------------------------------------------*/
public with sharing class SBQQ_QuoteTriggerActions {
    /*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Method which will reset the primary quote field on the opportunity object when
                 opportunity is changes on primary quote.
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    09/28/2017     Kasmoor Reddy       Initial Creation(US3470)
-----------------------------------------------------------------------------------*/
Public static void updatePrimaryQuote(List<SBQQ__Quote__c> quotelist, Map<Id, SBQQ__Quote__c> oldquote){
set<id> collectoldoppid =new set<Id>();
set<id> newcollectoldoppid =new set<Id>();    
List<Opportunity> opptylst = new List<Opportunity>();
List<Opportunity> lstopp = new List<Opportunity>();
id qoteid;
system.debug('quotelist:'+quotelist);    
for(SBQQ__Quote__c qote: quotelist){
    system.debug('qote.SBQQ__Primary__c:'+qote.SBQQ__Primary__c);
//check new quote is primary or not, if it is primary enter into if condition
    if(qote.SBQQ__Primary__c)
    {
        qoteid=qote.id;
        SBQQ__Quote__c oldqote = (SBQQ__Quote__c)Trigger.oldMap.get(qote.Id);
        system.debug('qote.SBQQ__Opportunity2__c:'+qote.SBQQ__Opportunity2__c);
        system.debug('oldqote.SBQQ__Opportunity2__c:'+oldqote.SBQQ__Opportunity2__c);
        //if new quote opp not equal to old quote opp or if quote opp is changed to null from existing.. then collect the old opp id.
        if(qote.SBQQ__Opportunity2__c != oldqote.SBQQ__Opportunity2__c && qote.SBQQ__Opportunity2__c != null && oldqote.SBQQ__Opportunity2__c != null){
           collectoldoppid.add(oldqote.SBQQ__Opportunity2__c);
           newcollectoldoppid.add(qote.SBQQ__Opportunity2__c);
           system.debug('collectoldoppid:'+collectoldoppid);
           system.debug('newcollectoldoppid:'+newcollectoldoppid);  
            
        }
                
        else if(qote.SBQQ__Opportunity2__c == null && oldqote.SBQQ__Opportunity2__c != null)
        {
           collectoldoppid.add(oldqote.SBQQ__Opportunity2__c);
           system.debug('collectoldoppid:'+collectoldoppid); 
            
        }
        
    }
}
    if(collectoldoppid.size()>0){
        for(id oppid:collectoldoppid){
               Opportunity opp = new Opportunity(id=oppid);
               opp.SBQQ__PrimaryQuote__c = null;
               opptylst.add(opp);
               system.debug('opptylst:'+opptylst);
          }
    }

    if(newcollectoldoppid.size()>0){    
        for(id oppid:newcollectoldoppid){
               Opportunity opp = new Opportunity(id=oppid);
               opp.SBQQ__PrimaryQuote__c = qoteid;
               opptylst.add(opp);
               system.debug('opptylst:'+opptylst);
          }
    }   
  
    if(opptylst.size()>0){
        Database.SaveResult[] lcr = Database.update(opptylst,false);
        for(Integer index = 0; index < lcr.size(); index++){
            if(!lcr[index].isSuccess()){
            quotelist[index].addError('Failed to update opportunity records: '+lcr[index].getErrors()[0].getMessage());
                
            }
        }
    }
   }
}