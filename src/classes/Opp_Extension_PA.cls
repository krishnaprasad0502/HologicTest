/*---------------------------------------------------------------------------------------------------------------------------------------------
Author:     N/A
Description:  Extension to CreatePA_Opp

Test Class:   Test_OpportunityTriggerHandler

History:
<Date>      <Authors Name>    <Brief Description of Change>
04/6/2017   Ronald Mendoza     US-0002366 - Diagnostic Create Amendment Quote Functionality
------------------------------------------------------------------------------------------------------------------------------------------------*/
public with sharing class Opp_Extension_PA {

    public Opportunity myOpp {get;set;}
    public Boolean issuccessful{get;set;}
    public String oppType{get;set;}
    public Boolean showButtonQuote{get;set;}
    public String quoteId{get;set;}
    public Contract currentContract {get;set;}
    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public Opp_Extension_PA(ApexPages.StandardController stdController) {
        myOpp = (Opportunity)stdController.getRecord();
    }
    public void RunThatOpp()
    {   showButtonQuote = false;
        oppType = ApexPages.currentPage().getParameters().get('type');

        //Used to Create Amendment Quote for Diagnostic Opportunities so that Agreed Prices/Groups will be Merged with any Opportunity Products before quote has been created
        if(oppType == 'DiagnosticAmendment'){
            //Use SOQL to fetch opportunity fields and check for amended contract
            myOpp = [Select SBQQ__RenewedContract__c, SBQQ__AmendedContract__r.Id, Price_Agreement_Contract__c, Account.Id, Pricebook2Id, Renewal_Contract_End_Date__c from Opportunity where id=:myOpp.id];
            
            if(myOpp.SBQQ__AmendedContract__r.Id != null){
                try{
                    //Initialize List and Fields to be used                    
                    LIST<SBQQ__QuoteLine__c> updatedLines = new LIST<SBQQ__QuoteLine__c>();
                    SBQQ__QuoteLineGroup__c opportunityProductGroup = new SBQQ__QuoteLineGroup__c();
                    showButtonQuote = true;
                    Integer groupCount = 1;
                    
                    //Fetch Amended Contract using SOQL
                    currentContract = [Select Id from Contract where id=:myOpp.SBQQ__AmendedContract__r.Id];
                    
                    //Use Helper Class to Create Quote using Agreed Prices and Groups from the Contract
                    quoteId = CreateAmendRenewalHelper.CreateQuote(myOpp);
                    Boolean linesCreated = CreateAmendRenewalHelper.CreateQL(currentContract, quoteId, 'Amendment');

                    //Use SOQL to fetch opportunity products from oppty to create group for opportunity products
                    /*LIST<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, SBQQ__Group__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =:quoteId AND SBQQ__Group__c = NULL];
                    LIST<SBQQ__QuoteLineGroup__c> currentQuoteLineGroups  = [SELECT Id from SBQQ__QuoteLineGroup__c where SBQQ__Quote__c =: quoteId];                    
                
                    if (currentQuoteLineGroups.size() > 0 && quoteLines.size() > 0){
                        //Populate Field Values for new Opportunity Product Group and insert
                        groupCount = currentQuoteLineGroups.size()+1;
                        opportunityProductGroup.Name = 'Opportunity Products';
                        opportunityProductGroup.SBQQ__Quote__c = quoteId;
                        opportunityProductGroup.SBQQ__Number__c = groupCount;
                        
                        insert opportunityProductGroup;

                        //Set all Opportunity Product lines to be associated to newly created Quote Line Group and update those lines
                        for (SBQQ__QuoteLine__c quoteLine : quoteLines){
                            quoteLine.SBQQ__Group__c = opportunityProductGroup.Id;
                            updatedLines.add(quoteLine);
                        }

                        update updatedLines;
                    }*/
                    
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.info,'Amendment Quote Created Successfully');
                    ApexPages.addMessage(myMsg);
                }
                catch (Exception e){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
                    ApexPages.addMessage(myMsg);
                }
            }
            else{
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Must have Amendment Contract on Opportunity in order to create Amendment Quote');
                ApexPages.addMessage(myMsg);
            }
        }
        else if(myOpp.Pricing_Agreement_Created__c==true && myOpp.StageName=='Closed Won'){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Pricing Agreement has Already Been Created for this Opportunity');
            ApexPages.addMessage(myMsg);
        }else if(myOpp.SBQQ__PrimaryQuote__c==null){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'No Primary Quote on this Opportunity, Please create before continuing');
            ApexPages.addMessage(myMsg);
            }else if( (myOpp.SBQQ__AmendedContract__c!=null || myOpp.SBQQ__RenewedContract__c!=null) && oppType=='New'){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'This Opportunity was generated from an Amendment or a Renewal, you may not create a new Pricing Agreement');
                    ApexPages.addMessage(myMsg);
                }else if(myOpp.SBQQ__AmendedContract__c==null && oppType=='Amendment'){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You may not Amend this Opportunity/Pricing Agreement.  This Opportunity was not generated from an Amended Contract');
                    ApexPages.addMessage(myMsg);
                }else if(myOpp.SBQQ__RenewedContract__c==null && oppType=='Renewal'){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You may not Renew this Opportunity/Pricing Agreement.  This Opportunity was not generated from a Renewal Contract');
                    ApexPages.addMessage(myMsg);

                }else{

                try
                {
                    myOpp.Pricing_Agreement_Created__c = true;
                    myOpp.StageName = 'Closed Won';
                    update myOpp;

                    myOpp=[Select SBQQ__RenewedContract__c, SBQQ__AmendedContract__c, Price_Agreement_Contract__c from Opportunity where id=:myOpp.id];
                    if(myOpp.Price_Agreement_Contract__c!=null){
                        issuccessful=true;
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Pricing Agreement Created Successfully');
                        ApexPages.addMessage(myMsg);
                    }
                }
                catch (Exception e)
                {
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
                    ApexPages.addMessage(myMsg);
                }

            }       
    }

    public PageReference goToContract(){
        PageReference p=new PageReference('https://hologic--dev.cs51.my.salesforce.com/' + myOpp.Price_Agreement_Contract__c);
        p.setRedirect(true);
        return p;
    }

    public PageReference returnToOpp(){
        PageReference p=new PageReference('/' + myOpp.id);
        p.setRedirect(true);
        return p;

    }

    public PageReference gotoQuote(){
        PageReference p=new PageReference('/'+ quoteId);  
        return p;
    }

}