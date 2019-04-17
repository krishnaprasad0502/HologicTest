public with sharing class addScheduleToAccount {

    public List<String> errors {get; set;}
    public ID accountId;
    public Account theAccount;
    public Set<ID> selectedIdSet;
    public Set<ID> RelAccountIdSet;
    public List<Account_Relationships__c> relatedAccountsList;
    public List<Account> selectedAccountsList;
    public List<Contract> selectedContractsList;
    //public Integer pageNumber=0;
    //public Integer pageSize=20;
    //public Integer pageNumber2=0;
    //public Integer pageSize2=20;
    public String accountName {get;set;}
    public List<schedule> scheduleList {get;set;}
    //public List<prioritizer> selectedList {get;set;}
    public List<Customer_Eligible_Contract__c> SelectedCECList {get;set;}
    public List<CECWrapper> SelectedCECWrapper {get;set;}
    
    
    public class schedule
    {
        public Contract relatedContract {get; set;}
        public Boolean selected {get; set;}
        public String contractName {
            get {
                if(String.isBlank(relatedContract.Name))
                    return relatedContract.ContractNumber;
                return relatedContract.Name;
            }
            
        }

        public schedule(Contract cntrct, Boolean IsSelected)
        { 
            this.relatedContract = cntrct;
            this.selected = IsSelected;
        }
    }
    
    public class CECWrapper
    {
        public Customer_Eligible_Contract__c theCEC {get;set;}
        public String AccountName {get;set;}
        public String ContractNumber {get;set;}
        public Date ContractEffDate {get;set;}
        public Date ContractExpDate {get;set;}
        public Boolean displayMe {get;set;}
        
        public CECWrapper(Customer_Eligible_Contract__c cec, String AcctName, String contractNum, Date contractEff, Date contractExp, Boolean DoDisplay) {
            this.theCEC = cec;
            this.AccountName = AcctName;
            this.ContractNumber = contractNum;
            if(system.today() >= contractEff && system.today() <= contractEff)
                this.ContractEffDate = system.today();
            else
                this.ContractEffDate = contractEff;
            this.ContractExpDate = contractExp;
            this.theCEC.Effective_Date__c=this.ContractEffDate;
            this.theCEC.Expiration_Date__c=this.ContractExpDate;
            this.displayMe = DoDisplay;
       
        }
        
    }
    /*
    public class prioritizer
    {
        public Contract relatedContract {get; set;}
        public integer order {get; set;}
        public integer Tier {get;set;}
        public Date EffDate {get;set;}
        public Date ExpDate {get;set;}
        
        public prioritizer(Contract cntrct, Integer preOrder, Integer preTier, Date preEffDate, Date preExpDate)
        { 
            this.relatedContract = cntrct;
            this.order = preOrder;
            this.Tier = preTier;
            this.EffDate = preEffDate;
            this.ExpDate = preExpDate; 
        }
    }
    */
    public addScheduleToAccount(ApexPages.StandardController controller) {
    
        errors = new List<String>();
        
        boolean preSelected = false;
        
        accountId = controller.getId();
        theAccount= [SELECT id, Name FROM Account WHERE id = :accountId LIMIT 1];
        accountName = theAccount.Name;
        
        //Before anything else, determine if any Customer Eligible Contract already exist for this account - to preselect and pre order
        Map<Id, Customer_Eligible_Contract__c> preSelectedCECMap = new Map<Id, Customer_Eligible_Contract__c>();
       
        for (Customer_Eligible_Contract__c CEC : [Select Id, Name, Customer_Account__c, Contract__c, Precedence_Value__c, Tier__c, Effective_Date__c, Expiration_Date__c, Selected__c, ContractNumber__c FROM Customer_Eligible_Contract__c where Customer_Account__c = :accountId AND Selected__c = true]) {
            if (!preSelectedCECMap.containsKey(CEC.Contract__c)) preSelectedCECMap.put(CEC.Contract__c, CEC); 
        }
        System.debug('$$$$$$$$$$ preSelectedCECMap '+preSelectedCECMap);
            scheduleList = new List<schedule>();
            //First, find any schedules/contract related to the account itself
            for (Contract c1 : [SELECT Id, Name, AccountId, Account.Name, ContractNumber, ContractTerm, Active_Contract__c, StartDate, Contract_End_Date__c FROM Contract WHERE AccountId = :accountId AND Active_Contract__c = 1 ORDER BY Contract_End_Date__c DESC]) {
                System.debug('$$$$$$$$$$ c1.Id '+c1.Id);
                if (preSelectedCECMap.containsKey(c1.Id)) preSelected = true;
                else preSelected = false;
                scheduleList.add(new schedule(c1,preSelected));
            }
            
            //next find any GPO (related accounts)
            relatedAccountsList = [SELECT Id, Name, Account__c, Related_Entity__c, Status__c FROM Account_Relationships__c WHERE Account__c = :accountId];
            System.debug('$$$$$$$$$$ relatedAccountsList '+relatedAccountsList);
            RelAccountIdSet = new Set<ID>();
            for (Account_Relationships__c r : relatedAccountsList) {
                RelAccountIdSet.add(r.Related_Entity__c);
            }
            //now add any active Contract for any GPO account that is related
            for (Contract c1 : [SELECT Id, Name, AccountId, Account.Name, ContractNumber, ContractTerm, Active_Contract__c, StartDate, Contract_End_Date__c FROM Contract WHERE AccountId IN :RelAccountIdSet AND Active_Contract__c = 1 ORDER BY Contract_End_Date__c DESC]) {
                System.debug('$$$$$$$$$$ c1.Id '+c1.Id);
                if (preSelectedCECMap.containsKey(c1.Id)) preSelected = true;
                else preSelected = false;
                scheduleList.add(new schedule(c1,preSelected));
            }
        
    }


    public PageReference selectSchedules() {
      
        errors = new List<String>();
        
        /*
        Integer preOrder = null;
        Integer preTier = null;
        Date preEffDate = null;
        Date preExpDate = null;
        */
        
        //Customer_Eligible_Contract__c theCEC;
        String AccountName = null;
        String ContractNumber = null;
        Date ContractEffDate = null;
        Date ContractExpDate = null;
                
        List<Customer_Eligible_Contract__c> tempCECList = new List<Customer_Eligible_Contract__c>();  
        List<CECWrapper> tempCECWrapper = new List<CECWrapper>();  

        Map<String, Customer_Eligible_Contract__c> ContractToCECMap = new Map<String, Customer_Eligible_Contract__c>(); 
        Map<String, CECWrapper> ContractToWrapperMap = new Map<String, CECWrapper>(); 
            
        selectedIdSet = new Set<ID>();
        for (schedule s : scheduleList) {
            if (s.selected) {
                System.debug('$$$$$$$$$$ '+s.relatedContract.Id);
                selectedIdSet.add(s.relatedContract.Id);
                //tempCECList.add(new Customer_Eligible_Contract__c(Customer_Account__c=s.RelatedContract.AccountId, Contract__c=s.RelatedContract.id, Selected__c=true));
                //tempCECList.add(new Customer_Eligible_Contract__c(Customer_Account__c=s.RelatedContract.AccountId, Contract__c=s.RelatedContract.id, Selected__c=true));
                Customer_Eligible_Contract__c CEC = new Customer_Eligible_Contract__c(Customer_Account__c=accountId, Contract__c=s.RelatedContract.id,  Selected__c=true);
                
                CECWrapper CECWrapper = new CECWrapper(CEC,s.RelatedContract.Account.Name,s.RelatedContract.ContractNumber,s.RelatedContract.StartDate,s.RelatedContract.Contract_End_Date__c,true);
                //tempCECWrapper.add(new CECWrapper(CEC,s.RelatedContract.AccountId,s.RelatedContract.ContractNumber,s.RelatedContract.StartDate,s.RelatedContract.Contract_End_Date__c));
                ContractToCECMap.put(CEC.Contract__c, CEC);
                ContractToWrapperMap.put(CEC.Contract__c, CECWrapper);
                //selectedList.add(new prioritizer(s.relatedAccount));
            }           
        }
        system.debug('$$$$$$$$$$ ContractToCECMap' + ContractToCECMap);
        system.debug('$$$$$$$$$$ ContractToWrapperMap' + ContractToWrapperMap);
        /*
        //determine if any Customer Eligible Contract already exist for this account - to preselect and pre order
        Map<Id, Integer> preSelectedCECMap = new Map<Id, Integer>();
        Map<Id, Integer> preTierCECMap = new Map<Id, Integer>();
        Map<id, Customer_Eligible_Contract__c> preSelectedOBJMap = new Map<id, Customer_Eligible_Contract__c>();
        
        for (Customer_Eligible_Contract__c CEC : [Select Id, Name, Customer_Account__c, Contract__c, Precedence_Value__c, Tier__c, Effective_Date__c, Expiration_Date__c, Selected__c FROM Customer_Eligible_Contract__c where Customer_Account__c = :accountId]) {
            if (!preSelectedCECMap.containsKey(CEC.Contract__c)) preSelectedCECMap.put(CEC.Contract__c, CEC.Precedence_Value__c.IntValue());
            if (!preTierCECMap.containsKey(CEC.Contract__c)) preTierCECMap.put(CEC.Contract__c, CEC.Tier__c.IntValue());
            if (!preSelectedOBJMap.containsKey(CEC.Contract__c)) preSelectedOBJMap.put(CEC.Contract__c, CEC); 
        }
        */
  
        
        SelectedCECList = new List<Customer_Eligible_Contract__c>();
        SelectedCECWrapper = new List<CECWrapper>();
        for (Customer_Eligible_Contract__c CECsel : [Select Id, Name, Customer_Account__c, Contract__c, Precedence_Value__c, Tier__c, Effective_Date__c, Expiration_Date__c, Selected__c, Contract__r.AccountId, Contract__r.ContractNumber, Contract__r.StartDate, Contract__r.Contract_End_Date__c, Contract__r.Account.Name FROM Customer_Eligible_Contract__c where Customer_Account__c = :accountId]) {
            /*
            if(ContractToCECMap.containsKey(CECsel.Contract__c)) {
                Customer_Eligible_Contract__c CEC = CECsel;
                CEC.Selected__c = true;
                ContractToCECMap.put(CEC.Contract__c, CEC);
            }
            */
            if(ContractToWrapperMap.containsKey(CECsel.Contract__c)) {
                Customer_Eligible_Contract__c CEC = CECsel;
                CEC.Selected__c = true;
                CECWrapper CECWrapper = new CECWrapper(CEC,CECsel.Contract__r.Account.Name,CECsel.Contract__r.ContractNumber,CECsel.Contract__r.StartDate,CECsel.Contract__r.Contract_End_Date__c,true);
                ContractToWrapperMap.put(CEC.Contract__c, CECWrapper);
            } else {
                Customer_Eligible_Contract__c CEC = CECsel;
                CEC.Selected__c = false;
                CECWrapper CECWrapper = new CECWrapper(CEC,CECsel.Contract__r.Account.Name,CECsel.Contract__r.ContractNumber,CECsel.Contract__r.StartDate,CECsel.Contract__r.Contract_End_Date__c,false);
                ContractToWrapperMap.put(CEC.Contract__c, CECWrapper);            
            }
        }

 

        SelectedCECList.addall(ContractToCECMap.Values());
        SelectedCECWrapper.addall(ContractToWrapperMap.Values());
        System.debug('$$$$$$$$$$ SelectedCECWrapper'+SelectedCECWrapper);

        if (SelectedCECWrapper.size() == 0) {
            errors.add('Please select one or more Schedule before continuing to Next page.');
        }
                 
        /*
        selectedList = new List<prioritizer>();     
        selectedContractsList = [SELECT Id, Name, AccountId, ContractNumber, ContractTerm, Active_Contract__c, StartDate, Contract_End_Date__c FROM Contract where ID IN: selectedIdSet];
        for (Contract selC : selectedContractsList) {
            if (preSelectedCECMap.containsKey(selC.Id)) preOrder = preSelectedCECMap.get(selC.Id);
            else preOrder = null;
            if (preTierCECMap.containsKey(selC.Id)) preTier = preTierCECMap.get(selC.Id);
            else preTier = null;            
            if (preSelectedOBJMap.containsKey(selC.Id)) {
                preEffDate = preSelectedOBJMap.get(selC.Id).Effective_Date__c;
                preExpDate = preSelectedOBJMap.get(selC.Id).Expiration_Date__c;
                //Add the Customer Selected Cntract to SelectedCECList here?
                //SelectedCECList.add(preSelectedOBJMap.get(selC.Id));

            }
            else {
                preTier = null;            
            }
            selectedList.add(new prioritizer(selC,preOrder,preTier,preEffDate,preExpDate));
        }        
        */
        
        
        PageReference pr = Page.PrioritizeSchedulesForAccount;
        pr.getParameters().put('id', '' + accountId);
        pr.setRedirect(false);
        
        if (errors.size() > 0) return null;
        else return pr;        
        //return Page.PrioritizeSchedulesForAccount;
    }
    
    public List<schedule> getCurrentPage() {
    
        errors = new List<String>();
        return scheduleList;
        
        /*
        List<schedule> showPage = new List<schedule>();
        Integer start = pageNumber * pageSize;
        Integer lastItem = ((start+pageSize) > (scheduleList.size())) ? scheduleList.size() : (start+pageSize);
        System.debug('start: '+start+', lastItem: '+lastItem+', scheduleList: '+scheduleList);
        for (Integer i = start;i < lastItem; i++) {
            showPage.add(scheduleList[i]);
        }
        return showPage;
        */
    }
    
    public List<CECWrapper> getPrioritizerPage() {
    
        errors = new List<String>();
        return SelectedCECWrapper;
        /*
        List<CECWrapper> showPage = new List<CECWrapper>();
        Integer start = pageNumber2 * pageSize2;
        Integer lastItem = ((start+pageSize2) > (SelectedCECWrapper.size())) ? SelectedCECWrapper.size() : (start+pageSize2);
        System.debug('start: '+start+', lastItem: '+lastItem+', SelectedCECWrapper: '+SelectedCECWrapper);
        for (Integer i = start;i < lastItem; i++) {
            showPage.add(SelectedCECWrapper[i]);
        }
        return showPage;
        */
    }
    /*
    public PageReference nextPage() {
    
        errors = new List<String>();
        
        Integer lastPage = Integer.valueOf(Math.ceil(SelectedCECWrapper.size()/pageSize));
        pageNumber = (pageNumber+1 > lastPage) ? lastPage : pageNumber+1;
        return null;
    }

    public PageReference prevPage() {
    
        errors = new List<String>();
        
        pageNumber = (pageNumber-1 < 0) ? 0 : pageNumber-1;
        return null;
    }
    */
    
    public List<schedule> getSelectedSchedules() {
        List<schedule> selected = new List<schedule>();
        for (schedule s : scheduleList) {
            if (s.selected) {
                selected.add(s);
            }
        }
        return selected;
    }

    public PageReference SaveAll() {
        //commit the Eligible Contracts and return the user back to the Account...

        errors = new List<String>();
        
        //First, purge all existing records for this account.  May want to revisit this.
        //Set<Id> SelectedIdSet = new Set<Id>();
        
        //List<Customer_Eligible_Contract__c> AllCECList = [SELECT Id, Contract__c, Selected__c FROM Customer_Eligible_Contract__c WHERE Customer_Account__c = :accountId];      
       
        List<Customer_Eligible_Contract__c> upsertList = new List<Customer_Eligible_Contract__c>();      
       
        //validate the List to insert
        errors = Validate(SelectedCECWrapper);
        if (errors.size() > 0) return null;

        /*
        List<Customer_Eligible_Contract__c> celToUpsert = new List<Customer_Eligible_Contract__c>();
        Map<String, Customer_Eligible_Contract__c> celToValidateMap = new Map<String, Customer_Eligible_Contract__c>();

        
        for (prioritizer p : selectedList ) {
            Customer_Eligible_Contract__c c = new Customer_Eligible_Contract__c();
            c.Contract__c = p.RelatedContract.Id;
            c.Customer_Account__c = accountId;
            c.Precedence_Value__c = p.order;
            c.Tier__c = p.Tier;
            c.Effective_Date__c = p.EffDate;
            c.Expiration_Date__c = p.ExpDate;
            c.Selected__c = true;
            System.debug('$$$$$$$$$$ c.Precedence_Value__c '+c.Precedence_Value__c);
            //if (c.Precedence_Value__c < 1) {
            //    errors.add('Please enter a Precendence Value GREATER THAN 0 for Contract Number ' + p.RelatedContract.ContractNumber  + ' and try again.');
            //}    
            c.GPO__c = p.RelatedContract.AccountId;//(p.RelatedContract.AccountId == accountId) ? null : p.RelatedContract.AccountId;
            celToValidateMap.put(c.Contract__c, c);
        }
        
        for (Customer_Eligible_Contract__c full : AllCECList) {
            Customer_Eligible_Contract__c CEC;
            if (celToValidateMap.containsKey(full.Contract__c)) {
                CEC = celToValidateMap.get(full.Contract__c);
                CEC.id = full.id;
                celToValidateMap.put(full.Contract__c, CEC);
            } else {
                full.Selected__c = false;
                celToValidateMap.put(full.Contract__c, full);
            }
        }
        
        //List<Customer_Eligible_Contract__c> unSelectList = [SELECT Id FROM Customer_Eligible_Contract__c WHERE Customer_Account__c = :accountId AND id NOT IN :SelectedIdSet];
        //for (Customer_Eligible_Contract__c u : unSelectList) {
        //    u.Selected__c = false;
        //    celToInsert.add(u);
        //}
        */
        
        for (CECWrapper pp : SelectedCECWrapper) {
            upsertList.add(pp.theCEC);
        }
        system.debug('$$$$$$$$$$ upsertList' + upsertList);
        try{
            upsert upsertList;
            PageReference pr = new PageReference('/'+accountId);
            pr.setRedirect(true); 
            return pr; 
        }catch(DmlException d){
             ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,d.getMessage()));
             return null;
        }
    
    }   
    public PageReference cancel() {
        PageReference pr = new PageReference('/'+accountId);
        pr.setRedirect(true); 
        return pr;
    }

    public List<String> Validate(List<CECWrapper> ListToValidate) {
        //reset the error collection...
        List<string> AllErrors = new List<String>();         
        integer iTypeCnt = 0;
        
        Set<Integer> allOrderNums = new Set<Integer>();
        
        for (CECWrapper p : ListToValidate ) {
            /* - allow for duplicates - to check for duplicates, uncomment these lines - 6/14/2016 - MBergman
            if (!allOrderNums.contains(p.order)) {
                allOrderNums.add(p.order);
            }
            else AllErrors.add('A duplicate Precendence Value of ' + p.order + ' has been entered for more than one Schedule.  Please verify your entries and try again.');
            */
            if (p.theCEC.Precedence_Value__c < 1) {
                AllErrors.add('Please enter a Precendence Value GREATER THAN 0 for Contract Number ' + p.theCEC.Contract__r.ContractNumber  + ' and try again.');
            }    
            if (p.theCEC.Tier__c < 1) {
                AllErrors.add('Please enter a TierValue GREATER THAN 0 for Contract Number ' + p.theCEC.Contract__r.ContractNumber  + ' and try again.');
            }
            system.debug('$$$$$$$$$$ - p.theCEC.Effective_Date__c + p.ContractEffDate ' + p.theCEC.Effective_Date__c + ' ' +  p.ContractEffDate);
            if (p.theCEC.Effective_Date__c < p.ContractEffDate ) {
                AllErrors.add('The Eff. Date entered for Contract Number ' + p.theCEC.Contract__r.ContractNumber  + ' is prior to the Contract Effective Date.  Please correct and try again.');
            }
            if (p.theCEC.Effective_Date__c > p.ContractExpDate ) {
                AllErrors.add('The Eff. Date entered for Contract Number ' + p.theCEC.Contract__r.ContractNumber  + ' is after the Contract Expiration Date.  Please correct and try again.');
            }
            if (p.theCEC.Expiration_Date__c < p.ContractEffDate ) {
                AllErrors.add('The Exp. Date entered for Contract Number ' + p.theCEC.Contract__r.ContractNumber  + ' is prior to the Contract Expiration Date.  Please correct and try again.');
            }
            if (p.theCEC.Expiration_Date__c > p.ContractExpDate ) {
                AllErrors.add('The Exp. Date entered for Contract Number ' + p.theCEC.Contract__r.ContractNumber  + ' is after the Contract Expiration Date.  Please correct and try again.');
            }
            if (p.theCEC.Expiration_Date__c < p.theCEC.Effective_Date__c ) {
                AllErrors.add('The Exp. Date entered for Contract Number ' + p.theCEC.Contract__r.ContractNumber  + ' can not be prior to Eff. Date.  Please correct and try again.');
            }
            
        }
        
        return AllErrors;

    } 
    
    

}