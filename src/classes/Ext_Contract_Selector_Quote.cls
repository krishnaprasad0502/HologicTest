/*------------------------------------------------------------------------------------------------------
Author: Salesforce CPQ
Company: Salesforce    
Description:  methods for quote assign contract functionality
Test Class:   test_Contract_selector

History:
<Date>      <Authors Name>    <Brief Description of Change>
07/25/2017  Kent Smith         uncommenting Mani's logic for the Contract_Update_Trigger__c functionality
07/04/2018  Ronald Mendoza     US-0003948 Updating Query Limit from 10 to 25
09/14/2018  Ronald Mendoza     US-0005303 - Updated Logic to disable Assign Contract functionality for Auto Contract Assignment quotes
---------------------------------------------------------------------------------------------------------*/


public with sharing class Ext_Contract_Selector_Quote {
    public class ContractWrapper {
        public Contract theContract {get; set; }
        public Integer precedence {get; set;}
        public ContractWrapper(Contract cont, Integer prec) {
            theContract = cont;
            precedence = prec;
        }
    }

  public SBQQ__Quote__c myQuote{get;set;}
    public Boolean canSelect{get;set;}
    public String selectedContract{get;set;}
    public List<ContractWrapper> contractList{get;set;}
    public Integer OffsetSize = 0;
    //private Integer QueryLimit = 10;
    private Integer QueryLimit = 25; //US-0003948 Updating Query Limit to 25
     public Integer CountTotalRecords{get;set;}
     public List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();

    public Ext_Contract_Selector_Quote(ApexPages.StandardController stdController) {
        this.myQuote = (SBQQ__Quote__c)stdController.getRecord();
    }

    //public List<SelectOption> contractList{get;set;}

    //public String getRecordName() {
        //return 'Hello ' + (String)mysObject.get('name') + ' (' + (Id)mysObject.get('Id') + ')';
    //}

    public void runThat(){
        //US-0005303 - Updated Logic to disable Assign Contract functionality for Auto Contract Assignment quotes
        if(myQuote.Opportunity_Record_Type__c == 'B&SH Sales Open Opportunity' && myQuote.Marketing_Program__c == 'Equipment Purchase'){
            canSelect = false;
        }
        else {
            canSelect = true;
        }
        //canSelect=!myQuote.Contract_Auto_Assigned__c;
        contractList = new List<ContractWrapper>();
       if(!myQuote.Contract_Auto_Assigned__c){

            List<Customer_Eligible_Contract__c> cecList=new List<Customer_Eligible_Contract__c>([Select Contract__c, Precedence_Value__c from Customer_Eligible_Contract__c where Customer_Account__c=:myQuote.SBQQ__Account__c and Agreement_Active__c=true and Selected__c=true and Active_Contract__c=1 ]);
            //contractList.add(new SelectOption('', '--None--'));
            Map<Id,Integer> precMap = new Map<Id,Integer>();
            if(!cecList.isEmpty()){
                List<String> contractIds=new List<String>();

                for(Customer_Eligible_Contract__c cec:cecList){
                    contractIds.add(cec.Contract__c);
                    precMap.put(cec.Contract__c,(Integer)cec.Precedence_Value__c);
                }

                for(Contract c : [Select id, StartDate, Contract_End_Date__c, Account.Name, Name, ContractNumber, Division__c from Contract where ID IN:contractIds Order by StartDate  limit :QueryLimit offset :OffsetSize]) {
                    contractList.add(new ContractWrapper(c,precMap.get(c.Id)));
                }
                countTotalRecords=[Select count() from Contract where ID IN:contractIds];
               

            }else{
                countTotalRecords=0;
                //for(Contract con:){
//                    contractList=new List<Contract>([Select id,StartDate, Contract_End_Date__c, Account.Name, Name, ContractNumber from Contract where Active_Contract__c=1 order by StartDate  limit :QueryLimit offset :OffsetSize]);
//                    countTotalRecords=[Select count() from Contract where Active_Contract__c=1];
                //}
            }

            
        }
        
    }

    public PageReference saveContract(){
        system.debug('selectedContract---'+selectedContract);
        List<Customer_Eligible_Contract__c> cecList=new List<Customer_Eligible_Contract__c>([Select Contract__c, Contract__r.ContractNumber from Customer_Eligible_Contract__c where Customer_Account__c=:myQuote.SBQQ__Account__c and Agreement_Active__c=true and Selected__c=true and Active_Contract__c=1 and Contract__c=:selectedContract ]);
        Boolean contractUpdate = false;
        if(myQuote != null)
            contractUpdate = [SELECT Contract_Update_Check__c from SBQQ__Quote__c where Id = :myQuote.Id].Contract_Update_Check__c;
        
        
        if(!cecList.isEmpty()){
            myQuote.Customer_Eligible_Contract__c=cecList.get(0).id;
        }
        
  /*---------ks 07/25 activated block of code to check or uncheck the Contract Update Check box used in validation------*/
        myQuote.Price_Agreement__c=selectedContract;
        if(contractUpdate == true)
        myQuote.Contract_Update_Check__c = false;
        else
        myQuote.Contract_Update_Check__c = true;
  
        
        quoteLines = [SELECT Id, SBQQ__AdditionalDiscountAmount__c, SBQQ__Discount__c from SBQQ__QuoteLine__c where SBQQ__Quote__c = :myQuote.Id];
        
        if(quoteLines.size() > 0){
            for(SBQQ__QuoteLine__c ql : quoteLines){
               ql.SBQQ__AdditionalDiscountAmount__c = null;
               ql.SBQQ__Discount__c = null;
            }
        }
        

        try{ 
                
                 update myQuote;
                
                 //01-25-2018 Commented by Krishna prasad as related to user story US-0003658.
                 if(quoteLines.size() > 0)
                 // uncommented quote lines
                 // Rich Varga 2-9-2018
                 // US-0003658
                 update quoteLines;
                   
                  
                  
                    
            }catch(DmlException d){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,d.getMessage());
                ApexPages.addMessage(myMsg);
                return null;
            }
        

        PageReference returnPage = new PageReference('/'+myQuote.id);  
        return returnPage;
        
    }

    public PageReference returnToPrevious()
    {
        PageReference returnPage = new PageReference('/'+myQuote.id);  
        return returnPage;
    }

    public Boolean getDisablePrevious(){
        if(OffsetSize>0){
            return false;
        }
        else return true;
    }

    public Boolean getDisableNext() {
        system.debug(QueryLimit);
        system.debug(OffsetSize);
        system.debug(countTotalRecords);
        Decimal total=OffsetSize + QueryLimit;
        if ( total < countTotalRecords){
            return false;
        }
        else return true;
    }

    public PageReference Next() {
        OffsetSize += QueryLimit;
        runThat();
        return null;
    }

    public PageReference Previous() {
        OffsetSize -= QueryLimit;
        system.debug(OffsetSize);
        system.debug(OffsetSize);
        runThat();
        return null;
    }
}