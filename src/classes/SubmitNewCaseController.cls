/***************************************************************************
Author:Vrushabh Kataria
Company:Hexaware Technologies
Description: This controller class is used to create new case.

TestClass: SubmitNewCaseController_Test
Code Coverage: 100%

History:
<Date>              <Author Name>        	<Brief description of change >         <Copa.do US#>
16/08/2018          Vrushabh Kataria     	Initial Creation                       	US-0005701
19/10/2018          Nomita Walke        	Updated SOQL in fetchLookUpValues()
02/11/2018          Nomita Walke        	Added fetchConfigData()                	US-0006062
30/11/2018          Nikhil Mutyam  	    	Commented out assignment email          US-0006370
18/12/2018          Vrushabh Katariya   	Schedule PM Future and Historic data    US-0006345
02/01/2019          Vrushabh Katariya   	Set Case SystemStatus default to Up     US-0006454
01/11/2019     		Nomita Walke            Updated code for third party users. 	US-0006454
01/20/2019			Vrushabh Katariya		PM Schedule new filter and changed 
											time span to 20 months 					US-0006553
01/21/2019			Vrushabh Katariya		Code change for Disposable Product 		US-0006553
****************************************************************************/
public with sharing class SubmitNewCaseController {
    
    public static User currentUser = [SELECT id,Name,ContactId,AccountId,Username,Email,
                                      FirstName,LastName,IsActive,Profile.Name 
                                      FROM User 
                                      Where id =: userInfo.getUserId()];
    /*
     * Method Name: fetchUser()
     * Input Param: none
     * Return: User reference 
     * Description: This method is created to return current user record details.
     */
    @auraEnabled
    public static user fetchUser(){
        User oUser = currentUser;
        
        return oUser;
    }
    
    /*
     * Method Name: fetchUserContact()
     * Input Param: none
     * Return: Contact object reference 
     * Description: This method is created to return current user related contact details.
     */
    @auraEnabled
    public static Contact fetchUserContact(){
        if(currentUser.contactId != null){
            contact contactName = [SELECT id, Name, FirstName, Phone, AccountId, Account.ParentId, Account.Parent.Name FROM contact WHERE id=: currentUser.contactId] ;
            return contactName;
        }else{
            return null ;
        }
    }
    
    /*
     * Method Name: fetchUserAccount()
     * Input Param: none
     * Return: Account object reference 
     * Description: This method is created to return current user related account details.
     */
    @auraEnabled
    public static Account fetchUserAccount(){
        if(currentUser.AccountId != null){
            Account accountName = [SELECT id,name,ParentId,Parent.Name
                                   FROM account 
                                   WHERE id=: currentUser.AccountId] ;
            return accountName;
        }else{
            return null ;
        }
    }
    
    /*
     * Method Name: getSelectOptions()
     * Input Param: Object API name,Field API name
     * Return: List <String>
     * Description: This method is created to return picklist values based on oject name and field value input.
     */
    @AuraEnabled
     public static List < String > getSelectOptions(sObject objObject, string fld) {
         List<String> priorityList = new list<String>{'None','Sev 1','Sev 2','Sev 3','NA'};
          List < String > allOpts = new list < String > ();
          // Get the object type of the SObject.
          Schema.sObjectType objType = objObject.getSObjectType();
          // Describe the SObject using its object type.
          Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
          // Get a map of fields for the SObject
          map < String, Schema.SObjectField > fieldMap = objDescribe.fields.getMap();
         
          // Get the list of picklist values for this field.
          list < Schema.PicklistEntry > values =
           fieldMap.get(fld).getDescribe().getPickListValues();
         
          // Add these values to the selectoption list.
         if(fld=='Priority'){
           for (Schema.PicklistEntry a: values) {
               for(string s: priorityList){
                   if(a.getValue() == s)
                    allOpts.add(a.getValue());
               }
          }  
         }else{
             for (Schema.PicklistEntry a: values) {
               allOpts.add(a.getValue());
              }
         }
          allOpts.sort();
          return allOpts;
     }
         
    
    /*
     * Method Name: fetchLookUpValues()
     * Input Param: String,Object API Name
     * Return: List <sObject>
     * Description: This method is created to return object records based on the search in look up field.
     */
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName) {
        String searchKey = '%' + searchKeyWord + '%';
        List < sObject > returnList = new List < sObject > ();
        String sQuery;
        System.debug(ObjectName);
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5  
        if(ObjectName == 'Asset' && searchKeyWord != null && searchKeyWord != '') {
            sQuery = 'SELECT id, Name, AccountId, Customer_Account__c,Customer_Account__r.Name, SerialNumber,status, Community_Product_Description__c, Install_Location_Label__c,Community_Visible__c FROM ' 
                +ObjectName + ' WHERE status=\'Installed\' AND Community_Visible__c = TRUE AND (SerialNumber LIKE: searchKey OR Community_Product_Description__c LIKE: searchKey OR Install_Location_Label__c LIKE: searchKey) order by Community_Favorite_Asset__c,Name DESC ';
        }else if(ObjectName == 'Asset' && (searchKeyWord == null || searchKeyWord == '')){
            sQuery = 'SELECT id, Name, AccountId, Customer_Account__c,Customer_Account__r.Name, SerialNumber,status, Community_Product_Description__c, Install_Location_Label__c,Community_Visible__c,Community_Favorite_Asset__c FROM ' 
                +ObjectName + ' WHERE status=\'Installed\' AND Community_Visible__c = TRUE order by Community_Favorite_Asset__c desc,Name asc LIMIT 5';
        }else if (ObjectName == 'Product2' && searchKeyWord != null && searchKeyWord != ''){
            sQuery = 'SELECT id, Name, Community_Product_Description__c, Community_Family_Name__c,Community_Visible__c FROM ' 
                +ObjectName + ' WHERE Community_Visible__c = TRUE AND (Name LIKE: searchKey OR Community_Product_Description__c LIKE: searchKey) order by createdDate DESC ';
        }else if(ObjectName == 'Product2' && (searchKeyWord == null || searchKeyWord == '')){
            sQuery = 'SELECT id, Name, Community_Product_Description__c, Community_Family_Name__c,Community_Visible__c FROM ' 
                +ObjectName + ' WHERE Community_Visible__c = TRUE order by createdDate DESC LIMIT 5';
        }
        System.debug(sQuery);
        List < sObject > lstOfRecords = Database.query(sQuery);
        System.debug(lstOfRecords);
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }
    
    /*
     * Method Name: fetchAssetRecord()
     * Input Param: ID
     * Return: Asset object reference
     * Description: This method is created to return Asset record based on the input id parameter.
     */
    @auraEnabled
    public static Asset fetchAssetRecord(Id AssetId){
        system.debug('The Asset id is: '+AssetId);
        Asset assetRecord = [SELECT id, Name, AccountId, Customer_Account__c,Customer_Account__r.Name,SerialNumber,Community_Product_Description__c,Install_Location_Label__c 
                             FROM Asset WHERE id =: AssetId];   
        return assetRecord;
    }
    
    /*
     * Method Name: fetchProductRecord()
     * Input Param: ID
     * Return: Asset object reference
     * Description: This method is created to return Product record based on the input id parameter.
     */
    @auraEnabled
    public static Product2 fetchProductRecord(Id ProductId){
        Product2 productRecord = [SELECT id,Name,Community_Product_Description__c FROM Product2 WHERE id =: ProductId];   
        return productRecord;
    }
    
    /*
     * Method Name: fetchAssetProduct()
     * Input Param: Id
     * Return: Product object reference
     * Description: This method is created to return Product records based on the asset id.
     */
    @auraEnabled
    public static Product2 fetchAssetProduct(Id AssetId){
        List<Asset> assetList = new List<Asset>([SELECT id,Name,Product2.Id,Product2.name,Product2.Description FROM Asset WHERE id =: AssetId]);
        if(assetList.size() > 0){
            Product2 assetProduct = assetList[0].Product2;
            return assetProduct;
        }else{
            return null ;
        }
        
    }
    
    @auraEnabled
    public static Result createCase(string priority, string ctype, string subType, string origin, string subject, string description, string productId, string assetId, string AssetAccountId, 
                                    string customerAccountId, string casePhoneNumber){
        system.debug('priority : '+priority);
        system.debug('ctype : '+ctype);
        system.debug('subType : '+subType);
        system.debug('origin : '+origin);
        system.debug('subject : '+subject);
        system.debug('description : '+description);
        system.debug('productId : '+productId);
        system.debug('assetId : '+assetId);
        system.debug('AssetAccountId : '+AssetAccountId);
        system.debug('customerAccountId : '+customerAccountId);
        system.debug('casePhoneNumber : '+casePhoneNumber);                                
        list<Asset> Assets = new list<Asset>();
        User loggedInUser = new User();
        loggedInUser = [SELECT Id, AccountId, Account.ParentId FROM User WHERE Id =: Userinfo.getUserId()];
        system.debug('The sub Type is: '+subType);
        system.debug('The Asset Account Id is: '+AssetAccountId);
        
        Case cs = new Case();
        cs.Priority = priority;
        cs.Type = ctype;
        if(cs.Sub_Type__c != Null && cs.Sub_Type__c != '' && cs.Sub_Type__c != 'None'){
            cs.Sub_Type__c = subType;
        }   
        cs.Origin = 'Web';
        cs.System_Status__c = 'Up';
        cs.subject = subject;
        cs.Description = description;
        
        if(AssetAccountId == Null || AssetAccountId == ''){
            AssetAccountId = loggedInUser.AccountId;
        }   
        cs.AccountId = AssetAccountId;
        system.debug('Logged In User Account: '+loggedInUser.AccountId);
        system.debug('Asset Account: '+AssetAccountId);
        
        if(AssetAccountId != loggedInUser.AccountId){
            cs.Allow_Contacts_Outside_Account__c = true;
        }
        
        
        if(productId != Null && productId != ''){
            cs.ProductId = productId;
        }
        if(assetId != Null && assetId != ''){
            cs.AssetId = assetId;
            Assets = [SELECT Id, Product2Id FROM Asset WHERE Id =: assetId];
            system.debug('The Assets are: '+Assets);
            if(Assets != Null && Assets.size() > 0){
                cs.ProductId = Assets[0].Product2Id;
            }
        }
        
        cs.Status = 'Open';
        cs.Case_Phone_Number__c = casePhoneNumber;
        if(customerAccountId != Null && customerAccountId != ''){
            cs.Customer_Name__c = customerAccountId;
        }else{
            if(loggedInUser != Null && loggedInUser.Account.ParentId != Null){
                cs.Customer_Name__c = loggedInUser.Account.ParentId;
            }
        }   
        
        /*Assignment Rule on Case Creation*/        
        AssignmentRule AR = new AssignmentRule();
        AR = SubmitNewCaseHelper.fetchAssignmentRule(); 
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
        //dmlOpts.EmailHeader.triggerUserEmail = true;
        cs.setOptions(dmlOpts);
        
        Result res = new Result();
        try{
            insert cs;    
            res.caseStatus = 'Success';
            res.caseId = cs.Id;
        }catch(exception e){
            res.caseStatus = 'Fail : '+e.getMessage();
            res.caseId = null;
            system.debug('The case id is: '+res.caseId);
        }
        system.debug('The case id is: '+res);
        return res;
    }
        
    @auraEnabled
    public static Result insertServiceRequestComments(boolean isCreateComments, string qa1, string qa2, string qa3, string caseId, string ctype){
        system.debug('The isCreateComments is: '+isCreateComments);
        system.debug('The string is: '+qa1);
        system.debug('The string is: '+qa2);
        system.debug('The string is: '+qa3);
        system.debug('The string is: '+caseId);
        system.debug('The string is: '+ctype);
        Result res = new Result();
        if(qa1 != null && qa1 != '' && isCreateComments == true && ctype == 'Web'){
            string ComplianceString = qa1 + '\n';
            if(qa2 != null && qa2 != ''){
                ComplianceString += qa2 + '\n';
            }
            if(qa3 != null && qa3 != ''){
                ComplianceString += qa3;
            }
            if(ComplianceString != Null && ComplianceString != ''){
                system.debug('The comment is: '+qa1);
                CaseComment cc1 = new CaseComment();
                cc1.parentId = caseId;
                cc1.CommentBody = ComplianceString;
                cc1.IsPublished = true;
                try{
                    insert cc1;
                    res.caseStatus = 'Success';
                    res.caseId = caseId;
                }catch(exception e){
                    res.caseStatus = 'Fail : '+e.getMessage();
                    res.caseId = null;
                    system.debug('The case id is: '+res.caseId);
                }   
            }
        }
        system.debug('The case id is: '+res);
        return res;
    }
    
    @auraEnabled
    public static string assignCase(Id CaseId){
        //Fetching the assignment rules on case
        AssignmentRule AR = new AssignmentRule();
        //AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
        AR = SubmitNewCaseHelper.fetchAssignmentRule(); 
        system.debug('Assignment RULE'+AR);
        //Creating the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
        dmlOpts.EmailHeader.triggerUserEmail = true;
        Case newCase = new Case(Id= CaseId) ;
        system.debug('newCase'+newCase);
        //Setting the DMLOption on Case instance
        newCase.setOptions(dmlOpts);
        upsert newCase ;
        system.debug('newCase.Id'+newCase.Id);
        return newCase.Id;
        
    }
    
    /*
     * Method Name: insertCaseComments
     * Input Param: comment1, comment2, comment3 and Case Id
     * Return: void
     * Description: This method creates case comments under the case record.
     */
    @auraEnabled
    public static void insertCaseComments(string qa1, string qa2, string qa3, string CaseId){
        system.debug('The string is: '+qa1);
        system.debug('The string is: '+qa2);
        system.debug('The string is: '+qa3);
        system.debug('The string is: '+CaseId);
        
        string ComplianceString = qa1 + '\n' + qa2 + '\n' + qa3;
        
        if(ComplianceString != Null && ComplianceString != ''){
            system.debug('The comment is: '+qa1);
            CaseComment cc1 = new CaseComment();
            cc1.parentId = CaseId;
            cc1.CommentBody = ComplianceString;
            cc1.IsPublished = true;
            insert cc1;
        }
    }
    /*
    * Method Name: fetchConfigData()
    * Input Param: No inputs required
    * Return: Service_Community_Config__c 
    * Description: fetch Global Menu from Custom Setting
    */
    @AuraEnabled
    public static Service_Community_Config__c fetchConfigData(){
       Service_Community_Config__c config = Service_Community_Config__c.getOrgDefaults();
       return config;
    }
    
    /*
     * Method Name: fetchServiceAppointment()
     * Input Param: Object Name, Fieldset Name, Asset Id
     * Return: List<ServiceAppointment>
     * Description: This method is created to return Service Appointment records based on the asset id.
     * 
     * PM Schedule data while case creation 
     * US-0006345 START 
     */
        
    @AuraEnabled
    public static List<ServiceAppointment> fetchServiceAppointment(String strObjectName, String strFieldSetName, Id AssetId){                
        
        //Get the fields from FieldSet
        Schema.SObjectType SObjectTypeObj = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();            
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(strFieldSetName);
        
        List<ServiceAppointment> lstServiceAppointment = new List<ServiceAppointment>();
        //Field to be queried - fetched from fieldset
        List<String> lstFieldsToQuery = new List<String>();
        
        for( Schema.FieldSetMember eachFieldSetMember : fieldSetObj.getFields() ){
            lstFieldsToQuery.add(String.valueOf(eachFieldSetMember.getFieldPath()));
        }
        
        //Form an SOQL to fetch the data - Set the wrapper instance and return as response
        //PM Schedule new filter and changed time span to 20 months	US-0006553
        if(! lstFieldsToQuery.isEmpty()){  
            String WorkTypeName = '\'PM%\'' ;
            String StatusCompleted = '\'Completed\'';
            String StatusInProgress = '\'In Progress\'';
            String StatusDispatched = '\'Dispatched\'';
            String query = 'SELECT Id, WorkType.Name, ' + String.join(lstFieldsToQuery, ', ') + ' FROM ServiceAppointment WHERE WorkType.Name LIKE ' + WorkTypeName + ' AND Related_Work_Order__r.Asset.Id =: AssetId AND ((SchedStartTime = LAST_N_MONTHS:20 AND Status = ' + StatusCompleted + ' ) OR (SchedStartTime = NEXT_N_MONTHS:20 AND (Status = ' + StatusCompleted + ' OR Status =  ' + StatusInProgress + '  OR Status =  ' + StatusDispatched + ' ))) ORDER BY status ASC';
            System.debug(query);
            lstServiceAppointment = Database.query(query);
        }
        return lstServiceAppointment;
    }
    
    // * US-0006345 END 
    
    /*
     * Method Name: fetchTimeframe()
     * Input Param: 
     * Return:DateResult 
     * Description: This method is created to return Current Date, Past Date and Future Date.
     * 
     * PM Schedule data while case creation 
     * US-0006345 START 
     */
    
    @AuraEnabled
    public static DateResult fetchTimeframe(){                
        
        DateResult result = new DateResult();
        Date CurrentDate = date.today();
        
        result.CurrentDate = CurrentDate;
        //PM Schedule new filter and changed time span to 20 months	US-0006553
        result.PastDate = CurrentDate.addMonths(-20);
        result.FutureDate = CurrentDate.addMonths(20);
        
        return result;
    }
    // * US-0006345 END
    
    
    @auraEnabled
    public static Result createDisposableCase(string priority, string ctype, string subType, string origin, string subject,  string productId, 
                                              string customerAccountId, String LotNo, String description ){
        User loggedInUser = new User();
        loggedInUser = [SELECT Id, AccountId, Account.ParentId FROM User WHERE Id =: Userinfo.getUserId()];
        
        Case cs = new Case();
        cs.Priority = priority;
        cs.Type = ctype;
        if(cs.Sub_Type__c != Null && cs.Sub_Type__c != '' && cs.Sub_Type__c != 'None'){
            cs.Sub_Type__c = subType;
        }   
        cs.Origin = 'Web';
        cs.System_Status__c = 'Up';
		cs.Lot_Number__c = LotNo ;
        cs.subject = subject;
        //cs.Description = concatResult.unescapeHtml3();
        cs.Description = description;
        if(productId != Null && productId != ''){
            cs.ProductId = productId;
        }
        cs.Status = 'Open';
        if(customerAccountId != Null && customerAccountId != ''){
            cs.Customer_Name__c = customerAccountId;
        }else{
            if(loggedInUser != Null && loggedInUser.Account.ParentId != Null){
                cs.Customer_Name__c = loggedInUser.Account.ParentId;
            }
        }   
        
        /*Assignment Rule on Case Creation*/        
        AssignmentRule AR = new AssignmentRule();
        AR = SubmitNewCaseHelper.fetchAssignmentRule(); 
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
        //dmlOpts.EmailHeader.triggerUserEmail = true;
        cs.setOptions(dmlOpts);
        
        Result res = new Result();
        try{
            insert cs;    
            res.caseStatus = 'Success';
            res.caseId = cs.Id;
        }catch(exception e){
            res.caseStatus = 'Fail : '+e.getMessage();
            res.caseId = null;
            system.debug('The case id is: '+res.caseId);
        }
        system.debug('The case id is: '+res);
        return res;
    }
    
    @auraEnabled
    public static Result insertDisposableCaseComments(string ComplianceString, string CaseId){
        Result res = new Result();
        
            if(ComplianceString != Null && ComplianceString != ''){
                CaseComment cc1 = new CaseComment();
                cc1.parentId = CaseId;
                cc1.CommentBody = ComplianceString;
                cc1.IsPublished = true;
                try{
                    insert cc1;
                    res.caseStatus = 'Success';
                    res.caseId = CaseId;
                }catch(exception e){
                    res.caseStatus = 'Fail : '+e.getMessage();
                    res.caseId = null;
                    system.debug('The case id is: '+res.caseId);
                }   
            }
        
        system.debug('The case id is: '+res);
        return res;
    }
    
    
    
    public class Result{
        @auraEnabled public string caseStatus;
        @auraEnabled public string caseId;
        public Result(){
            caseStatus = '';
            caseId = '';
        }
    }
    
    public class DateResult{
        @auraEnabled public Date CurrentDate;
        @auraEnabled public Date PastDate;
        @auraEnabled public Date FutureDate;
        public DateResult(){
            CurrentDate = CurrentDate;
            PastDate = PastDate;
            FutureDate = FutureDate;
        }
    }
    
    
    
}