/*---------------------------------------------------------------------------------------------------------------------------------------------
Author:     N/A
Description:  Contract Controller Extension to Manage Renewals and Amendments on the Contract buttons

Test Class:   Ext_ContractNewAnR_Test
History:
<Date>      <Authors Name>    <Brief Description of Change>
02/14/2017   Ronald Mendoza     US-0002196 - Manual Renewals
02/16/2017   Ronald Mendoza     US-0002197 - Contract Amendments
12/01/2017   Krishnaprasad      US-0003566 - Adding custom metadata
12/21/2017   Mani Sundaresan    US-0003784 - Update logic to not create Amended quote when invoked from contract related to Diagnostic Lab Open opporunity
------------------------------------------------------------------------------------------------------------------------------------------------*/
public with sharing class Ext_ContractNewAnR {

    private final Contract contract;
    public Boolean showButtonQuote{get;set;}
    public Boolean showButtonOpp{get;set;}
    public String quoteId{get;set;}
    public String oppType{get;set;}
    public Opportunity opp {get;set;}
    public String marketprogram {get;set;}
    public String metadatamarketprogram {get;set;}
    public Boolean amendcheck {get;set;}
    public Boolean renewcheck {get;set;}
    
    public Opportunity myOpp {get;set;}
    public Boolean issuccessful{get;set;}
    //public String oppType{get;set;}
    //public Boolean showButtonQuote{get;set;}
    //public String quoteId{get;set;}
    public Contract currentContract {get;set;}
    
    public Boolean isContract = false;
    public Boolean isOppty = false;
    
    //public list<Marketing_Program__mdt> MP {get;set;}
    //public String oppId {get;set;}
    
    //Using same Extension Controller on different VF pages related to different objects
    public Ext_ContractNewAnR(ApexPages.StandardController stdController){
        
        sObjectType sot = stdController.getRecord().getsObjectType();
                
        if(sot == Schema.Contract.sObjectType){
            contract = (Contract)stdController.getRecord();
            isContract = true;
        }
        else if(sot == Schema.Opportunity.sObjectType){
            myOpp = (Opportunity)stdController.getRecord();    
            isOppty = true;
        }
    }
    public Contract returnContract(){
        Contract rc = [Select Id, Active_Contract__c,Automatic_Renewal__c, Contract_End_Date__c, AccountId,Marketing_Program__c, Account.Name, StartDate, ContractNumber, SBQQ__Opportunity__r.Pricebook2Id, ContractTerm, EndDate,
                         SBQQ__RenewalOpportunity__c, SBQQ__Opportunity__c, SBQQ__Opportunity__r.Opportunity_RecordType__c, SBQQ__Opportunity__r.RecordTypeId, SBQQ__Quote__c, Owner.Profile.Name, Division__c,
                         (SELECT Id from SBQQ__RenewalOpportunities__r WHERE StageName != 'Closed Lost'), (SELECT Id from SBQQ__AmendmentOpportunities__r WHERE StageName != 'Closed Lost')
                        FROM Contract Where Id = :contract.Id];
        system.debug('rc---'+rc);
        return rc;
    }
    public void RunThat(){
        oppType = ApexPages.currentPage().getParameters().get('type');
        String successmessage = oppType+' Opportunity has been created.';
        showButtonOpp = false;
        showButtonQuote = false;
        Contract currentContract = returnContract();
        system.debug('currentContract----'+currentContract);
        Diagnostic_Opportunity_Record_Type_IDs__c diagnosticRecordTypes = Diagnostic_Opportunity_Record_Type_IDs__c.getOrgDefaults();

        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        String profileName = PROFILE[0].Name;
        Boolean BSHContract = false;
        Boolean DiagContract = false;
        Boolean SurgicalContract = false;
        // Added by Krishna as part of US-0003566
        marketprogram = currentContract.Marketing_Program__c;
        system.debug('marketprogram----'+marketprogram);
        
        
        // Added by krishna as part of US-0003566
        list<Marketing_Program__mdt> MP = new list<Marketing_Program__mdt>();
        
        MP=[SELECT id,MasterLabel,Marketing_Program_value__c,Run_Amendment__c,Run_Renewal__c  FROM Marketing_Program__mdt where Marketing_Program_value__c =:marketprogram];
        system.debug('MP.size----'+MP.size());
        if(MP.size() > 0){
            for(Marketing_Program__mdt mpr : MP){
            metadatamarketprogram = mpr.Marketing_Program_value__c;
            amendcheck = mpr.Run_Amendment__c;
            renewcheck = mpr.Run_Renewal__c;
            system.debug('metadatamarketprogram----'+metadatamarketprogram);
            system.debug('amendcheck----'+amendcheck);
            system.debug('renewcheck----'+renewcheck);
            
            }   
        }
        // End of code as part of US-0003566
        
        
        system.debug('oppType----'+oppType);

        if(currentContract.Division__c != null && currentContract.Division__c.contains('Surgical')){
            SurgicalContract = true;
        }
        if(currentContract.Division__c != null && currentContract.Division__c.contains('BSH')){
            BSHContract = true;
        }
        if(currentContract.Division__c != null && currentContract.Division__c.contains('Diagnostics')){
            DiagContract = true;
        }
        
        if(currentContract.Contract_End_Date__c == null && oppType == 'Amendment')
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Cannot Amend a Contract without an End Date. ');
            ApexPages.addMessage(myMsg);
        }
        
             // Added by krishna as part of US-0003566
             
       else if((!string.isEmpty(marketprogram) && marketprogram == metadatamarketprogram && ((amendcheck != true  && oppType == 'Amendment') ))){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You may not Amend  Contracts for this marketing programs');
            ApexPages.addMessage(myMsg);
        }
         else if((!string.isEmpty(marketprogram) && marketprogram == metadatamarketprogram && ( (renewcheck != true  && oppType == 'Renewal')))){
            system.debug('marketprogram----'+marketprogram);
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You may not Renew Contracts for this marketing programs');
            ApexPages.addMessage(myMsg);
        }
        // End of code as part of US-0003566
          else if(currentContract.Active_Contract__c == 0 && oppType == 'Amendment'){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Inactive Contracts can not be Amended. ');
            ApexPages.addMessage(myMsg);
        }
        else if((currentContract.getSObjects('SBQQ__AmendmentOpportunities__r') != null && currentContract.getSObjects('SBQQ__AmendmentOpportunities__r').size() > 0) || ( currentContract.getSObjects('SBQQ__RenewalOpportunities__r') != null && currentContract.getSObjects('SBQQ__RenewalOpportunities__r').size() > 0)){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'an open Amendment/Renewal for this Contract is already active.');
            ApexPages.addMessage(myMsg);
        }
        else if((profileName.contains('Diagnostic') && DiagContract == false) || (profileName.contains('Surgical') && SurgicalContract == false) || (profileName.contains('B&SH') && BSHContract == false)){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You may not Amend or Renew Contracts from other Divisions');
            ApexPages.addMessage(myMsg);
        }
        
        
        else{
            try{
                //US-0002196 - If Manual Renewal Create Renewal Oppty and Renewal Quote or Amendment Quote
                opp = CreateAmendRenewalHelper.CreateOpp(currentContract, oppType);
                
                //System.debug('Opp RecordType:' + opp.RecordTypeId);
                System.debug('Custom setting val:'+diagnosticRecordTypes.Diagnostic_Lab_Open_Opportunity__c);
                System.debug('OppSBQQ'+opp);
                System.debug('OppRectypidSBQQ'+opp.RecordTypeId);
                String currentContractId = currentContract.Id;
               if(Test.isRunningTest() || (opp != null && !String.valueOf(opp.RecordTypeId).contains(diagnosticRecordTypes.Diagnostic_Lab_Open_Opportunity__c) && oppType == 'Amendment')){
                    quoteId = CreateAmendRenewalHelper.CreateQuote(opp);
                    //Boolean linesCreated = CreateAmendRenewalHelper.CreateRenewalQL(currentContract, quoteId);
                    //Boolean linesCreated = CreateAmendRenewalHelper.CreateQL(currentContract, quoteId, oppType);
                    CreateAmendRenewalHelper.CreateQL(currentContractId, quoteId, oppType);
                }
                else if(Test.isRunningTest() || oppType == 'Renewal'){
                    quoteId = CreateAmendRenewalHelper.CreateQuote(opp);
                    //Boolean linesCreated = CreateAmendRenewalHelper.CreateRenewalQL(currentContract, quoteId);
                    //Boolean linesCreated = CreateAmendRenewalHelper.CreateQL(currentContract, quoteId, oppType);
                    CreateAmendRenewalHelper.CreateQL(currentContractId, quoteId, oppType);        
                }
                
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.info,successmessage);
                ApexPages.addMessage(myMsg);
                if(quoteId != null)
                    showButtonQuote = true;
                showButtonOpp = true;
            }
            catch (Exception e){
                System.debug('Ext_ContractNewAnR Debug: '+ e.getMessage());
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
                ApexPages.addMessage(myMsg);
            }
        }
    }
    
    
    public void RunThatOpp()
    {   showButtonQuote = false;
        oppType = ApexPages.currentPage().getParameters().get('type');

        //Used to Create Amendment Quote for Diagnostic Opportunities so that Agreed Prices/Groups will be Merged with any Opportunity Products before quote has been created
        if(oppType == 'DiagnosticAmendment'){
            //Use SOQL to fetch opportunity fields and check for amended contract
            myOpp = [Select SBQQ__RenewedContract__c, RecordTypeId ,SBQQ__AmendedContract__r.Id, Price_Agreement_Contract__c, Account.Id, Pricebook2Id, Renewal_Contract_End_Date__c from Opportunity where id=:myOpp.id];
            
            if(myOpp.SBQQ__AmendedContract__r.Id != null){
                try{
                    //Initialize List and Fields to be used                    
                    LIST<SBQQ__QuoteLine__c> updatedLines = new LIST<SBQQ__QuoteLine__c>();
                    SBQQ__QuoteLineGroup__c opportunityProductGroup = new SBQQ__QuoteLineGroup__c();
                    showButtonQuote = true;
                    Integer groupCount = 1;

                    //Fetch Amended Contract using SOQL
                    currentContract = [Select Id from Contract where id=:myOpp.SBQQ__AmendedContract__r.Id];
                    String currentContractId2 = currentContract.Id;
                    //Use Helper Class to Create Quote using Agreed Prices and Groups from the Contract
                    SBQQ.TriggerControl.disable();
                    quoteId = CreateAmendRenewalHelper.CreateQuote(myOpp);
                    //Boolean linesCreated = CreateAmendRenewalHelper.CreateQL(currentContract, quoteId, 'Amendment');
                    
                    CreateAmendRenewalHelper.CreateQL(currentContractId2, quoteId, 'Amendment');
                    SBQQ.TriggerControl.enable();

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

               // try
                //{
                    myOpp.Pricing_Agreement_Created__c = true;
                    myOpp.StageName = 'Closed Won';
                    update myOpp;

                    myOpp=[Select SBQQ__RenewedContract__c, SBQQ__AmendedContract__c, Price_Agreement_Contract__c from Opportunity where id=:myOpp.id];
                    if(myOpp.Price_Agreement_Contract__c!=null){
                        issuccessful=true;
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Pricing Agreement Created Successfully');
                        ApexPages.addMessage(myMsg);
                    }
                /*}
                catch (Exception e)
                {
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
                    ApexPages.addMessage(myMsg);
                }*/

            }       
    }
    
    
    public PageReference returnToPrevious(){
        PageReference returnPage = new PageReference('/'+contract.id);  
        return returnPage;
    }
     public PageReference gotoOpp(){
         
         PageReference returntoOpp;
         
         if(isContract)
            returntoOpp = new PageReference('/'+ opp.Id);  
         else if(isOppty)
            returntoOpp = new PageReference('/'+ myOpp.id); 
        return returntoOpp;
    }
     public PageReference gotoQuote(){
        PageReference returntoQuote = new PageReference('/'+ quoteId);  
        return returntoQuote;
    }
     public PageReference goToContract(){
        PageReference p=new PageReference('/' + myOpp.Price_Agreement_Contract__c);
        p.setRedirect(true);
        return p;
    }
   
}