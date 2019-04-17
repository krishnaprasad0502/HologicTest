/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Provides functions for the creation of test records for unit testing

History:
<Date>          <Authors Name>      <Brief Description of Change>
03/25/2016      Denise Bacher       Initial Creation
04/05/2016      Denise Bacher       Adding case creation functions
04/19/2016      Denise Bacher       Adding work order creation functions
05/25/2016      Denise Bacher       Adding data quality creation functions
06/21/2016      Marc Goldstein      Adding sales order line item creation functions
07/01/2016      Sumit Gupta         Adding account skills creation functions
07/26/2016      Ramkumar Pitchai    Added new method to create Site Location

06/20/2018      Ryan Lambert        Remove all code / reference to FSLIS
07/22/2018      Mani Sundaresan     Added methods to create Payment and PaymentCard records
09/21/2018      Nikhil Mutyam       Added bulk creation methods for Cases
------------------------------------------------------------*/
@isTest
public class TestUtility {
    public static Configuration_Settings__c setupConfigurationSettings(){
        Configuration_Settings__c orgDefaults = new Configuration_Settings__c();
        orgDefaults.Account_Creation_Exception__c = true;
        orgDefaults.Account_Hierarchy_Depth__c = 5;
        orgDefaults.Case_List_Column_01__c = 'CaseNumber';
        orgDefaults.Case_List_Records_Per_Page__c = 5;
        orgDefaults.Override_Entitlement_on_Case__c = true;
        orgDefaults.Auto_Close_Case_B_SH_Applications__c = true;
        orgDefaults.Auto_Close_Case_B_SH_Install__c = true;
        orgDefaults.Auto_Close_Case_B_SH_PM__c = true;
        orgDefaults.Auto_Close_Case_Billable_B_SH_Service__c = true;
        orgDefaults.Auto_Close_Case_NonBillable_B_SH_Service__c = true;
        orgDefaults.Diagnostic_Install_Upgrade_Case_Queue_Id__c = NULL;
        
        insert orgDefaults;
        
        insertAllTriggerCustSettings();
        
        /******* Logic to add the default account in Configuration Settings custom setting for assets created w/o install location in test methods ***************/
        Account custAccountDefault = TestUtility.newAccount('Customer Account Default', 'testCustDefault', 'Line 1', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        custAccountDefault.BillingCountryCode = 'US';
        custAccountDefault.BillingStateCode = 'NY';    
        custAccountDefault.BillingPostalCode = '12345';
        insert custAccountDefault;
        
        
        orgDefaults.Return_Default_Account__c = custAccountDefault.id;
        update orgDefaults;
        /********************************************************************************************************************************************************/
        
        return orgDefaults;
    }
    
    public static Record_Type_IDs__c setupRecordTypeIds(){
        Record_Type_IDs__c rtIds = new Record_Type_IDs__c();
        rtIds.Case_B_SH_Applications__c = '01261000000MEID';
        rtIds.Case_B_SH_Connectivity__c = '01261000000MEIE';
        rtIds.Case_B_SH_Install__c = '01261000000MEIF';
        rtIds.Case_B_SH_PM__c = '01261000000MEIG';
        rtIds.Case_B_SH_Pre_Sales__c = '01261000000MEIH';
        rtIds.Case_B_SH_Service__c = '01261000000MEII';
        rtIds.Case_B_SH_Tech_Support__c = '01261000000MEIJ';
        rtIds.Work_Order_B_SH_Applications__c = '01261000000MEIr';
        rtIds.Work_Order_B_SH_Billable_PM__c = '0124C000000LApQ';
        rtIds.Work_Order_B_SH_Cares__c = '01261000000MEIs';
        rtIds.Work_Order_B_SH_Connectivity__c = '01261000000MEIt';
        rtIds.Work_Order_B_SH_FE_Install_Upgrade_Move__c = '01261000000MEIu';
        rtIds.Work_Order_B_SH_FE_Service__c = '01261000000MEIv';
        rtIds.Work_Order_B_SH_PM__c = '01261000000MEIw';
        rtIds.Order_B_SH_Service_Order__c = '01261000000MEIj';
        rtIds.Order_B_SH_Parts_Order__c = '01261000000MEIg';
        rtIds.WOLI_Add_a_Part__c = '01261000000SRAR';
        rtIds.WOLI_B_SH_Add_a_Part_Labor_Travel__c = '01261000000SRAR';
        rtIds.WOLI_B_SH_Add_Labor_Travel__c = '01261000000SRAP';
        rtIds.WOLI_B_SH_RMA__c = '01261000000MEJ1';
        rtIds.Case_Site_Assessment__c = '0122F000000CgJL';
        rtIds.Service_Contract_B_SH_Purchase_Order__c = '01261000000MEIo';
        rtIds.Coverage_Template_B_SH_PM__c = '01261000000MEIMAA4';
        rtIds.Coverage_Template_B_SH_SLA__c = '01261000000MEINAA4';
        //rtIds.WOL_Professional_Services_Reco__c = '0120x0000004KHoAAM';
        
     
        
        
        
        insert rtIds;
        return rtIds;
        
    }
    
     
    public static Case_Effort_Validation_Status__c caseEffortVR(){
        return new Case_Effort_Validation_Status__c(Case_Status__c='Dispatch Required;Dispatched',Case_Status_Ext__c='After Hours Dispatch Required');
    }
    
    public static InternalAccounts__c newInternalAccount(String oracleId){
        return new InternalAccounts__c(
            Name = oracleId
        );
    }
    
    public static User newUser(ID profileID, String unique){
        return new User(
            ProfileId = profileID
            , LastName = 'test'+unique
            , Email = unique+'@hologictest.com'
            , Username = unique+'@hologictest.com'
            , Alias = unique
            , CompanyName = 'Hologic'
            , TimeZoneSidKey='America/New_York'
            , EmailEncodingKey='UTF-8'
            , LanguageLocaleKey='en_US' 
            , LocaleSidKey='en_US'
        );
    }
    
    public static Account newAccount(String name, String oraclePartyId, String billingStreet, ID parentId, ID recordTypeId) {
        return new Account(
            Name = name
            , Oracle_Party_Id__c = oraclePartyId
            , ParentId = parentId
            , RecordTypeId = recordTypeId
            , BillingStreet = billingStreet
            , Website = name+'.com'
        );
    }
    
    public static Account newAccount(String name, String oraclePartyId, ID parentId) {
        return newAccount(name, oraclePartyId, null, parentId, GlobalUtility.getRecordTypeId('Account', 'Customer'));
    }
    
    public static Account newAccount(String name, String oraclePartyId) {
        return new Account(
            Name = name
            , Oracle_Party_Id__c = oraclePartyId
            , RecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Customer')
            , Website = name+'.com'
        );
    }
    
    public static Account newAccountWithAddresses(String name, ID parentId, ID recordTypeId, 
        String billingStreet, String billingCity, String billingState, String billingCountry, String billingPostalCode, 
        String shippingStreet, String shippingCity, String shippingState, String shippingCountry, String shippingPostalCode) 
    {
        return new Account(
            Name = name
            , ParentId = parentId
            , RecordTypeId = recordTypeId
            , BillingStreet = billingStreet
            , BillingCity = billingCity
            , BillingState = billingState
            , BillingCountry = billingCountry
            , BillingPostalCode = billingPostalCode
            , ShippingStreet = shippingStreet
            , ShippingCity = shippingCity
            , ShippingState = shippingState
            , ShippingCountry = shippingCountry
            , ShippingPostalCode = shippingPostalCode
            , Website = name+'.com'
        );
    }
    
    public static AccountShare newAccountShare(Id accountId, Id groupUserId){
        return new AccountShare(
            AccountId = accountId
            , UserOrGroupId = groupUserId
            , AccountAccessLevel = 'Read'
            , CaseAccessLevel = 'Edit'
            , OpportunityAccessLevel = 'None'
        );
    }
    
    public static Site_Location__c newSiteLocation(String name, String addr1, String addr2, String addr3, String addr4,
        String city, String state, String zipCode, String country, String parentOraclePartyId, Id accountId, Boolean isActive)
    {
        return new Site_Location__c(
            Name = name
            , Address_Line_1__c = addr1
            , Address_Line_2__c = addr2
            , Address_Line_3__c = addr3
            , Address_Line_4__c = addr4
            , City__c = city
            , State__c = state
            , Zip_Code__c = zipCode
            , Country__c = country
            , Parent_Oracle_Party_ID__c = parentOraclePartyId
            , Account__c = accountId
            , Active__c = isActive
        );
    }
    
    public static Site_Location__c newSiteLocation(String name, String addr1, String parentOraclePartyId, Id accountId){
        return newSiteLocation(name, addr1, null, null, null, null, null, null, null, parentOraclePartyId, accountId, true);
    }
    
    public static Site_Location__c newSiteLocation(String name, Id accountId, String addressLine1){
        return newSiteLocation(name, addressLine1, null, null, null, null, null, null, null, null, accountId, true);
    }
    
    public static Contact newContact(String firstName, String lastName, Id accountId){
        return new Contact(
            FirstName = firstName
            , LastName = lastName
            , AccountId = accountId
        );
    }
    
     public static Session_Time__c newSessionTime(Id agentid, Id caseid, String comments,Integer duration,String type){
        return new Session_Time__c(
            Agent__c = agentid
            , Case__c = caseid
            , Comments__c = comments
            ,Duration__c = duration
            ,Type__c = type
        );
    }
    
    public static Case newCase(Id accountId, Id contactId, Id assetId, Id productId, Id recordTypeId, String caseType, String status, String priority, String origin){
        return new Case(
            AccountId = accountId
            , ContactId = contactId
            , AssetId = assetId
            , ProductId = productId
            , RecordTypeId = recordTypeId
            , Type = caseType
            , Status = status
            , Priority = priority
            , Origin = origin
            , Billable__c = false
        );
    }
    
    public static Lead newLead(String Company, String LastName, String CurrencyIsoCode, String Phone, String Status, String POI){
        return new Lead(
            Company = Company
            , LastName = LastName
            , CurrencyIsoCode = CurrencyIsoCode
            , Status = Status
            , Phone = Phone
            , Product_of_Interest__c = POI
            
        );
    }
    
    
    
    public static Asset newAsset(String name, Id siteAccountId, Id customerAccountId, Id productId){
        return new Asset(
            Name = name
            , AccountId = siteAccountId
            , Customer_Account__c = customerAccountId
            , Product2Id = productId
        );
    }
    
    public static Asset newAsset(Id siteAccountId, Id customerAccountId, Id parentAssetId, Id recordTypeId, String name, String hologicDivision, String serialNum){
        return new Asset(
            Name = name
            , AccountId = siteAccountId
            , Customer_Account__c = customerAccountId
            , ParentId = parentAssetId
            , RecordTypeId = recordTypeId
            , Hologic_Division__c = hologicDivision
            , SerialNumber = serialNum
        );
    }
    
    public static Asset newAsset(String oraclePartyId, Id installSiteLocation, String name){
        return new Asset(
            Name = name
            , Oracle_Party_ID__c = oraclePartyId
            , Install_Location__c = installSiteLocation
        );
    }

    public static Asset newAsset(String oraclePartyId, Id installSiteLocation, String name, Id orderItemId){
        return new Asset(
            Name = name
            , Oracle_Party_ID__c = oraclePartyId
            , Install_Location__c = installSiteLocation
            , Order_Line_Item__c = orderItemId
        );
    }
    
    public static WorkOrder newWorkOrder(Id accountId, Id caseId, String status){
        return newWorkOrder(accountId, caseId, null, status);
    }
    
    public static WorkOrder newWorkOrder(Id accountId, Id caseId, Id assetId, String status){
        return new WorkOrder(
            AccountId = accountId
            , CaseId = caseId
            , AssetId = assetId
            , Status = status
        );
    }
    
    public static WorkOrder newWorkOrderWithAddress(Id accountId, Id caseId, Id assetId, String street, String city, String postalCode, String stateCode, String countryCode){
        return new WorkOrder(
            AccountId = accountId
            , CaseId = caseId
            , AssetId = assetId         
            , Street = street
            , City = city
            , PostalCode = postalCode
            , StateCode = stateCode
            , CountryCode = countryCode
        );
    }

    public static WorkOrder newWorkOrder(Id accountId, Id caseId, Id assetId, Id recordTypeId, String status){
        return new WorkOrder(
            AccountId = accountId
            , CaseId = caseId
            , AssetId = assetId
            , RecordTypeId = recordTypeId
            , Status = status
        );
    }

    public static WorkOrder newWorkOrderWithAddressAndTerritory(Id serviceterritoryId, Id ownerId, String street, String city, String postalCode, String stateCode, String countryCode){
        return new WorkOrder(
            Street = street
            , City = city
            , PostalCode = postalCode
            , StateCode = stateCode
            , CountryCode = countryCode
            , ServiceTerritoryId = serviceterritoryId
            , OwnerId = ownerId
        );
    }
    
    public static WorkOrderLineItem newWorkOrderLineItem(Id workOrderId, Id assetId, Id recordTypeId, String status){
        return new WorkOrderLineItem(
            WorkOrderId = workOrderId
            , AssetId = assetId
            , RecordTypeId = recordTypeId
            , Status = status
        );
    }

    public static Order newOrder(Id accountId, Id pricebookId, String status, Date startDate){
        return newOrder(accountId, pricebookId, null, status, startDate);
    }

    public static Order newOrder(Id accountId, Id pricebookId, Id quoteId, String status, Date startDate){
        return newOrder(accountId, pricebookId, null, GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order'), status, null, startDate);
    }

    public static Order newOrder(Id accountId, Id pricebookId, Id caseId, Id recordTypeId, String status, String orderType, Date startDate){
        return new Order(
            AccountId = accountId
            , Pricebook2Id = pricebookId
            , Case__c = caseId
            , RecordTypeId = recordTypeId
            , Type = orderType
            , Status = status
            , EffectiveDate = startDate
        );
    }

    public static Order newOrderwithAddress(Id accountId, Id pricebookId, String status, Date startDate, String shippingStreet, String shippingCity, String shippingState, String shippingCountry, String shippingPostalCode){
        return new Order(
            AccountId = accountId
            , Pricebook2Id = pricebookId
            , Status = status
            , EffectiveDate = startDate
            , ShippingStreet = shippingStreet
            , ShippingCity = shippingCity
            , ShippingState = shippingState
            , ShippingCountry = shippingCountry
            , ShippingPostalCode = shippingPostalCode
        );
    }
    
    public static OrderItem newOrderItem(Id orderId, Id quoteLineId, Id pricebookEntryId, Decimal quantity, Decimal unitPrice){
        return new OrderItem(
            OrderId = orderId
            , Quote_Line__c= quoteLineId
            , PricebookEntryId = pricebookEntryId
            , Quantity = quantity
            , UnitPrice = unitPrice
        );
    }
    
    public static SBQQ__Quote__c newQuote(Id accountId, Id opportunityId){
        return new SBQQ__Quote__c(
            SBQQ__Account__c = accountId
            , SBQQ__Opportunity2__c = opportunityId
            , SBQQ__StartDate__c = System.today().addDays(-1)
            , SBQQ__EndDate__c = System.today().addYears(1)
            , Operating_Unit__c = 'HOLX_US_OU'
        );
    }
    
    public static SBQQ__QuoteLine__c newQuoteLine(Id quoteId, Id productId, Decimal listPrice, Decimal quantity){
        return new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quoteId 
            , SBQQ__Product__c = productId  
            , SBQQ__ListPrice__c = listPrice 
            , SBQQ__Quantity__c = quantity
            , SBQQ__StartDate__c = System.today().addDays(-1)
            , SBQQ__EndDate__c = System.today().addYears(1)
        );
    }
    
    public static Data_Quality__c newDataQuality_NewSiteLocation(String addr1, String addr2, String addr3, String addr4, String city, String state, String zip, String country,
        Id accountId, String accountOraclePartyId, Id assetId)
    {
        return new Data_Quality__c(
            CDQ_Status__c = 'New'
            , Type__c = 'New Site Location'
            , RecordTypeId = GlobalUtility.getRecordTypeId('Data_Quality__c', 'Site_Location')
            , Installed_At__c = true
            , Address_Line_1__c = addr1
            , Address_Line_2__c = addr2
            , Address_Line_3__c = addr3
            , Address_Line_4__c = addr4
            , City__c = city
            , State_Code__c = state
            , Zip_Code__c = zip
            , Country_Code__c = country
            , Account__c = accountId
            , Oracle_Party_Id__c = accountOraclePartyId
            , Asset__c = assetId
        );
    }
    
    public static Account_Resource__c newAccountResource(Id accountId, Id resourceId, String role, Boolean isActive, Boolean isRequired, Boolean isPreferred, Boolean isExcluded){
        return new Account_Resource__c(
            Account__c = accountId
            //, Resource__c = resourceId
            , Resource_Role__c = role
            , IsActive__c = isActive
            , IsRequired__c = isRequired
            , IsPreferred__c = isPreferred
            , IsExcluded__c = isExcluded
        );
    }
        
    public static Account_Skill__c newAccountSkill(Id accountId, Id skillId, String type, Boolean active){
        return new Account_Skill__c(
            Account__c = accountId, 
            //Skill__c = skillId,
            Type__c = type,
            IsActive__c = active
        );
    }
        
    public static Group newGroup(String devName, String name){
        return new Group(
            DeveloperName = devName
            , Name = name
            , Type = 'Regular' 
        );
    }
    
    public static GroupMember newGroupMember(Id groupId, Id userId){
        return new GroupMember(
            GroupId = groupId
            , UserOrGroupId = userId
        );
    }
    
    public static Opportunity newOpportunity(String name, Id accountId, Date closedDate, String stage, String forecastCategory){
        return newOpportunity(name, accountId, closedDate, stage, forecastCategory, UserInfo.getUserId());
    }
    
    public static Opportunity newOpportunity(String name, Id accountId, Date closedDate, String stage, String forecastCategory, Id ownerId){
        return new Opportunity(
            Name = name
            , AccountId = accountId
            , CloseDate = closedDate
            , StageName = stage
            , ForecastCategoryName = forecastCategory
            , OwnerId = ownerId
        );
    }
    
    public static Product_Source_Division__c newProductsourcedivision(String Hologic,String sourcedivision){
        return new Product_Source_Division__c(
            Name = Hologic
            ,Source_Division__c = sourcedivision
        );
    }
    
    public static Product2 newProduct(String name){
        return new Product2(
            Name = name
            , IsActive = true
            , Quotable__c = true
        );
    }
    
    public static Pricebook2 newPricebook(String name){
        return new Pricebook2(
            Name = name
            , IsActive = true
        );
    }
    
    public static PricebookEntry newPricebookEntry(Id pricebookId, Id productId, Double unitPrice){
        return new PricebookEntry(
            Pricebook2Id = pricebookId
            , Product2Id = productId
            , UnitPrice = unitPrice 
            , IsActive = true
        );
    }
    
    public static Coverage_Group__c newCoverageGroup(String name){
        return new Coverage_Group__c(
            Name = name
        );
    }
    
    public static Coverage_Group_Product__c newCoverageGroupProduct(Id coverageGroupId, Id productId){
        return new Coverage_Group_Product__c(
            Coverage_Group_Name__c = coverageGroupId
            , Product__c = productId
        );
    }
    
    public static Coverage_Template__c newCoverageTemplate(String name, Id coverageGroupId, Id recordTypeId, Id productId,
        Double discount, Double maxCoverageAmount, String priority, String caseEntitlementProcessName, String workorderEntitlementProcessName, String uniqueId)
    {
        return new Coverage_Template__c(
            Name = name
            , Coverage_Group__c = coverageGroupId
            , RecordTypeId = recordTypeId
            , Service_Contract_Product__c = productId
            , Discount__c = discount
            , Max_Covered_Amount__c = maxCoverageAmount
            , Priority__c = priority
            , Case_Entitlement_Process_Name__c = caseEntitlementProcessName
            , Work_Order_Entitlement_Process_Name__c = workorderEntitlementProcessName
            , Unique_SLA_Id__c = uniqueId
        );
    }
    
    public static Entitlement newEntitlement(String name, Id businessHoursId, Id slaProcessId, Id accountId, Id assetId, Id coverageTemplateId, Date startDate, Date endDate){
        return new Entitlement(
            Name = name
            , BusinessHoursId = businessHoursId
            , SlaProcessId = slaProcessId
            , AccountId = accountId
            , AssetId = assetId
            , Coverage_Template__c = coverageTemplateId
            , StartDate = startDate
            , EndDate = endDate
        );
    }
    
    public static Entitlement newEntitlement(String name, Id businessHoursId, Id slaProcessId, Id accountId, Id assetId, Id coverageGroupId, Id coverageTemplateId, Id recordTypeId, 
        Date startDate, Date endDate, Double discount, Double maxCoverageAmount)
    {
        return new Entitlement(
            Name = name
            , BusinessHoursId = businessHoursId
            , SlaProcessId = slaProcessId
            , AccountId = accountId
            , AssetId = assetId
            , Coverage_Group__c = coverageGroupId
            , Coverage_Template__c = coverageTemplateId
            , RecordTypeId = recordTypeId
            , StartDate = startDate
            , EndDate = endDate
            , Discount__c = discount
            , Max_Covered_Amount__c = maxCoverageAmount
        );
    }
    
    public static ServiceContract newServiceContract(String name, Id accountId, Id recordTypeId, Id pricebookId, Date startDate, Date endDate){
        return new ServiceContract(
            Name = name
            , AccountId = accountId
            , RecordTypeId = recordTypeId
            , Pricebook2Id = pricebookId
            , StartDate = startDate
            , EndDate = endDate
            , Description = 'test service contract description'
            , Contract_Group__c = 'Contracts'
            , Payment_Term__c = 'DUE ON RECEIPT'
            , Transaction_Type__c = 'DAN SRV CONT INV'
            , PO_Number__c = 'grabage'
            , Internal_Contact__c = UserInfo.getUserId()
        );
    }
    
    public static ContractLineItem newContractLineItem(Id serviceContractId, Id pricebookEntryId, Double quantity, Double unitPrice, Id assetId){
        return new ContractLineItem(
            ServiceContractId = serviceContractId
            , PricebookEntryId = pricebookEntryId
            , Quantity = quantity
            , UnitPrice = unitPrice
            , AssetId = assetId
        );
    }

    public static Service_Billing_Schedule__c newservicebilling(String name,Id contractlineitemId, Double ammount){
            return new Service_Billing_Schedule__c(
                Name = name
                ,Contract_Line_Item__c = contractlineitemId
                , Amount__c = ammount
            );
        }        
       
    public static Task newTask(String subject, Id whatId){
        return new Task(
            Subject = subject,
            WhatId = whatId
        );
    }   

     public static Email_Communication__c  newEmailcommunication(Id Caseid,string fromaddress,string fromname,Date messagedate,string status,string toaddress,string subject){
        return new Email_Communication__c(
            case__c = Caseid
            ,From_Address__c=fromaddress
            ,From_Name__c=fromname
            ,Message_Date__c=messagedate
            ,status__c = status
            ,To_Address__c=toaddress
            ,Subject__c=subject
        );
    }
    
    public static EmailMessage newemailmessage(Id parentid,string fromaddress,string toaddress,string subject,string textbody,id emailcommid){
        return new EmailMessage(
            FromAddress   = fromaddress
            ,ToAddress =toaddress
            ,Subject  =subject
            ,TextBody =textbody
            ,ParentId =parentid
            ,Email_Communication_Id__c  =emailcommid
            
        );
    }
    
     public static Attachment  newattachement(Id parentid,string name){
        return new Attachment (
            ParentId    = parentid
            ,Name=name
            
            
            
        );
    }
    
    public static void insertCustSetting(String triggerName){
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = triggerName;
        ts.Active__c = true;
        insert ts;
    }
    
    public static void insertAllTriggerCustSettings(){
        List<Trigger_Switch__c> switches = new List<Trigger_Switch__c>();
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'OpportunityTeamMemberTrg'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'AssetTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'CaseTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'CaseSummaryTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'ContentDocumentLinkTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'ContentVersionTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'ContractLineItemTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'DemoRequestTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'EmailMessageTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'EntitlementTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'OpportunityTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'OrderItemTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'OrderTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'ProductConsumedTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'ProductRequestTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'ProductRequestLineItemTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'ProductRequiredTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'SBQQ_QuoteTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'ServiceAppointmentTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'ShipmentTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'sitelocTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'WorkOrderLineItemTrigger'));
        switches.add(new Trigger_Switch__c(Active__c = true, Name = 'WorkOrderTrigger'));
        insert switches;
    }

    public static ServiceAppointment newServiceAppointment(Id parentrecordId, String status, Id relatedworkorderid, Datetime schedendtime, Datetime schedstarttime){
        return new ServiceAppointment(
            ParentRecordId = parentrecordId
            , Status = status
            , SchedEndTime = schedendtime
            , SchedStartTime = schedstarttime
            , Related_Work_Order__c = relatedworkorderid

        );
    }
    
    public static Payment__c newPayment(Id accId, Integer amt, Id billToSite, String authCode, Id ordId, Id payCard, Id quote, Id svcContract, Id wo){
        return new Payment__c(
            Account__c = accId,
            Amount__c = amt,
            Bill_To_Site_Location__c = billToSite,
            Credit_Card_Authorization_Code__c = authCode,
            Credit_Card_Authorization_Date__c = Date.Today(),
            Order__c = ordId,
            Payment_Card__c = payCard,
            Quote__c = quote,
            Service_Contract__c = svcContract,
            Work_Order__c = wo
        );
    }
    
    public static Payment_Card__c newPaymentCard(String name, Id accId, Id billToSite, String ccExpMonth, String ccExpYear, String nameOnCard, String ccToken, String ccType){
        return new Payment_Card__c(
            Name = name,
            Account__c = accId,
            Bill_To_Site_Location__c = billToSite,
            Credit_Card_Expiration_Month__c = ccExpMonth,
            Credit_Card_Expiration_Year__c = ccExpYear,
            Credit_Card_Name_on_Card__c = nameOnCard,
            Credit_Card_Status__c = 'Active',
            Credit_Card_Token__c = ccToken,
            Credit_Card_Type__c = ccType
            
        );
    }
    
    /*Bulk create records*/   
    /*
     * Method Name: getAccounts()
     * Input Param: Integer
     * Return: List<Account> 
     * Description: This method is used to create test accounts references.
     */
    public static list<Account> getAccounts(integer count){
        list<Account> Accounts = new list<Account>();
        for(integer i=0;i<count;i++){
            Account Act = new Account();
            Act.Name = 'Sample Account' + i;
            Act.Phone = '9898989898';
            Act.BillingCity = 'Sample City' + i;
            Act.BillingCity = 'Sample Country' + i;
            Accounts.add(Act);
        }
        return Accounts;
    }
    
    /*
     * Method Name: getContacts()
     * Input Param: List<Id>
     * Return: List<Contact> 
     * Description: This method is used to create test contacts references.
     */
    public static list<Contact> getContacts(integer count){
        list<Contact> Contacts = new list<Contact>();
        for(integer i=0;i<count;i++){
            Contact Cnt = new Contact();
            Cnt.FirstName = 'Contact';
            Cnt.LastName = 'Sample' + i;
            Cnt.Phone = '9898989898';
            Cnt.OtherCity = 'Sample City' + i;
            Cnt.OtherCountry = 'India';
            Contacts.add(Cnt);
        }
        return Contacts;
    }
    
    /*
     * Method Name: getProducts()
     * Input Param: Integer
     * Return: List<Case> 
     * Description: This method is used to create test cases references.
     */
    public static list<Case> getCases(integer count){
        list<Case> Cases = new list<Case>();
        for(integer i=0;i<count;i++){
            Case cas = new Case();
            cas.Subject = 'Sample Case' + i;
            cas.Description = 'Sample Case';
            cas.Origin = 'web';
            cas.System_Status__c = 'Down';
            cas.Priority = 'Low';
            Cases.add(cas);
        }
        return Cases;
    }
    
    /*
     * Method Name: getAssets()
     * Input Param: Integer
     * Return: List<Asset> 
     * Description: This method is used to create test asset references.
     */
    public static list<Asset> getAssets(integer count){
        list<Asset> Assets = new list<Asset>();
        for(integer i=0;i<count;i++){
            Asset ast = new Asset();
            ast.Name = 'Test New Asset';
            Assets.add(ast);
        } 
        return Assets;
    }
    
    public static list<Product2> getProducts(integer count){
        list<Product2> Products = new list<Product2>();
        for(integer i=0;i<count;i++){
            Product2 pd2 = new Product2();
            pd2.Name = 'Test New Asset';
            Products.add(pd2);
        } 
        return Products;
    }
    
    public static list<Knowledge__kav> getArticles(integer count){
        list<Knowledge__kav> Articles = new list<Knowledge__kav>();
        for(integer i=0;i<count;i++){
            Knowledge__kav A1 = new Knowledge__kav();
            A1.Title='test article'+ i;
            A1.UrlName='testarticleurl'+ i;
            A1.Language='en_US';
            Articles.add(A1);
        } 
        return Articles;
    }
    
    public static list<Box_Mapper__c> getBoxArticleMappers(integer count, string AId){
        list<Box_Mapper__c> BoxMappers = new list<Box_Mapper__c>();
        for(integer i=0;i<count;i++){
            Box_Mapper__c BM = new Box_Mapper__c();
            BM.Article_ID__c = AId;
            BoxMappers.add(BM);
        }
        return BoxMappers;
    }
    
    public static list<Box_Auth__c> getBoxCredentials(integer count){
        list<Box_Auth__c> Credentials = new list<Box_Auth__c>();
        for(integer i=0;i<count;i++){
            Box_Auth__c BA1 = new Box_Auth__c();
            BA1.Access_Token__c = 'Test Access Token';
            BA1.Article_ID__c = 'Test Article Id';
            BA1.Client_ID__c = 'Test Client Id';
            BA1.Client_Secret__c = 'Test Client Secret';
            BA1.Enterprise_ID__c = 'Test Enterprise Id';
            BA1.Private_Key_ID__c = 'Test Private Id';
            BA1.Public_Key_ID__c = 'Test Public Key Id';
            BA1.User_Type__c = 'Standard';
            BA1.Folder_URL__c = 'https://test-url.com';
            Credentials.add(BA1);
            
            Box_Auth__c BA2 = new Box_Auth__c();
            BA2.Access_Token__c = 'Test Access Token';
            BA2.Article_ID__c = 'Test Article Id';
            BA2.Client_ID__c = 'Test Client Id';
            BA2.Client_Secret__c = 'Test Client Secret';
            BA2.Enterprise_ID__c = 'Test Enterprise Id';
            BA2.Private_Key_ID__c = 'Test Private Id';
            BA2.Public_Key_ID__c = 'Test Public Key Id';
            BA2.User_Type__c = 'Community';
            BA2.Folder_URL__c = 'https://test-url.com';   
            Credentials.add(BA2);
        }  
        return Credentials;
    }
}