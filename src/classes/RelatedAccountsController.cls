/*--------------------------------------------------------------------------------------------------
Author:      Ronald Mendoza
Description:  Controller for RelatedAccountsOutput VF Page to display CEC accounts on pricing agreement output
Tests Excecuted: Test_OpportunityTriggerHandler class


History:
<Date>      <Authors Name>    <Brief Description of Change>
02/21/2017  Ronald Mendoza     Initial Creation for US-000223- Automation of related accounts in output
---------------------------------------------------------------------------------------------------------*/
public with sharing class RelatedAccountsController {
    public List<Customer_Eligible_Contract__c> cecs {get; private set;}
    public RelatedAccountsController() {

        Id quoteId = (Id)ApexPages.currentPage().getParameters().get('qid');  
       
       
        cecs = [select Id, Customer_Account__r.Name, Customer_Account__r.Oracle_Customer_Number__c, Customer_Account__r.BillingStreet, Customer_Account__r.BillingState ,Customer_Account__r.BillingPostalCode ,Customer_Account__r.BillingCountry ,Customer_Account__r.BillingCity from  Customer_Eligible_Contract__c where Quote__c = :quoteId  order by Customer_Account__r.Name asc];
                

        /*if(cecs.getResultSize()==0)
              {
               ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'No Related Accounts found');
               ApexPages.addMessage(myMsg);
              }
            }*/
    }
}