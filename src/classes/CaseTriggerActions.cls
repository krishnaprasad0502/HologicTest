/*------------------------------------------------------------
Author:        Denise Bacher
Company:       Salesforce.com
Description:   Case Trigger functions
Test Class:    CaseTrigger_Test

History:
<Date>        <Authors Name>    <Brief Description of Change>
06/24/2016    Denise Bacher     Initial Creation (US1311)
08/08/2016    Marc Goldstein    Updated triggering conditions/record types (US1446)
05/01/2017    Raj Sharan        Update for Logic for Diagnostic and Surigical (US 2505)
12/06/2017    Mani Sundaresan   Validation to prevent case status from being updated without Case Efforts (US 3657) 
12/18/2017    Mani Sundaresan   Updated static variables to fetch recordtypeids from custom setting
12/18/2017    Mani Sundaresan   Added CalculateBusinessHoursAges trigger functionality

06/20/2018   Ryan Lambert    Remove all code / reference to FSLIS 
------------------------------------------------------------*/
public with sharing class CaseTriggerActions {
  private static final Boolean ORG_DEFAULT_OVERRIDE_ENTITLEMENT = (Boolean)Configuration_Settings__c.getOrgDefaults().Override_Entitlement_on_Case__c;
  
  /***** Updated static variables to fetch recordtypeids from custom setting - Mani Sundaresan*********/
  private static Record_Type_IDs__c recordTypeIds = Record_Type_IDs__c.getOrgDefaults();
  
  //Get the Validation Rule Exception custom setting value
  private static Validation_Rule_Exception__c bypassValidation = Validation_Rule_Exception__c.getOrgDefaults();
  
  private static Case_Effort_Validation_Status__c caseStatus = Case_Effort_Validation_Status__c.getOrgDefaults();
  
  private static final ID RECORD_TYPE_ID_DIAGNOSTIC_CASE_SERVICE = recordTypeIds.Case_Diagnostic_Service__c;
  private static final ID RECORD_TYPE_ID_CASE_SUPPORT = recordTypeIds.Case_Support__c;
  private static final ID RECORD_TYPE_ID_CASE_SERVICE = recordTypeIds.Case_B_SH_Service__c;
  private static final ID RECORD_TYPE_ID_CASE_INSTALL = recordTypeIds.Case_B_SH_Install__c;
  private static final ID RECORD_TYPE_ID_CASE_PM = recordTypeIds.Case_B_SH_PM__c;
  private static final ID RECORD_TYPE_ID_CT_SLA = recordTypeIds.Coverage_Template_B_SH_SLA__c;
  private static final ID RECORD_TYPE_ID_CT_PM = recordTypeIds.Coverage_Template_B_SH_PM__c;
  private static final ID RECORD_TYPE_ID_SC_PURCHASE_ORDER = recordTypeIds.Service_Contract_B_SH_Purchase_Order__c;   
  
  private static final List<Stop_Status__c> stopStatusList = [Select Name From Stop_Status__c];
  private static final List<BusinessHours> defaultHoursList = [select Id from BusinessHours where IsDefault=true];
  private static final List<CaseStatus> statusList = [Select MasterLabel From CaseStatus where IsClosed=true];   

 static Boolean reviewCasesFlag = false;

    /*------------------------------------------------------------
    Author:         Raj Sharan 
    Company:        AppsAssociates 
    Description:    Review the Cases being inserted or updated
    Inputs:         List of Cases being updated
                    Map of Old Cases 
    Returns:        N/A
    Test Class:     CaseTrigger_Test


    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/1/2017       Raj Sharan          Update for Logic for Diagnostic and Surigical (US 2505)  
    ------------------------------------------------------------*/
    public static void reviewCases(List<Case> allCases, Map<Id, Case> oldCases){
      List<Case> casesWithAssets = new List<Case>();
      List<Id> assetIds = new List<Id>();

      List<Case> casesWithProductOnly = new List<Case>();
      List<Id> productIds = new List<Id>();

      List<Case> casesNeedEntitlement = new List<Case>();
      List<Id> rootAssetIds = new List<Id>();
      List<String> accountPostalCodes = new List<String>();

      String postalCode = '';
      Date createdDate; 
      Date minDate = System.today();
      Date maxDate = System.today();

      // Determine the Cases that require updates for Entitlement, Service Location, update of fields based on Asset
      // if(!reviewCasesFlag){
  
        for(Case cs1 : allCases){

        Case oldCase = oldCases != null && oldCases.containsKey(cs1.Id) ? oldCases.get(cs1.Id) : null;

        // Check to see if Case has an Asset, so fields can be updated accordingly

          if(cs1.AssetId != NULL && (oldCase == NULL || oldCase.AssetId != cs1.AssetId || oldCase.ProductId != cs1.ProductId)){

          casesWithAssets.add(cs1);
          assetIds.add(cs1.AssetId);
          postalCode = cs1.Account_Postal_Code__c;
          if(!String.isEmpty(postalCode)) accountPostalCodes.add((cs1.Account_Postal_Code__c).left(5));

        }

        // Check to see if Case has no Asset, but Products so fields can be updated accordingly

        if(cs1.AssetId == NULL && cs1.ProductId != NULL && (oldCase == NULL || oldCase.ProductId != cs1.ProductId)){

        casesWithProductOnly.add(cs1);
        productIds.add(cs1.ProductId);
        postalCode = cs1.Account_Postal_Code__c;
        if(!String.isEmpty(postalCode)) accountPostalCodes.add((cs1.Account_Postal_Code__c).left(5));

        }

        // Determine if Entitlement needs to be updated.  If new or no entitlement, check to see if entitlement applies. 

        if(cs1.AssetId != NULL && (oldCase == NULL || oldCase.AssetId != cs1.AssetId || oldCase.ProductId != cs1.ProductId || 
        oldCase.EntitlementId == NULL && oldCase.Purchase_Order__c == NULL)) {

        casesNeedEntitlement.add(cs1);
        rootAssetIds.add(cs1.Root_Asset_Id__c);
 
        createdDate = cs1.CreatedDate != null ? cs1.CreatedDate.date() : System.today();

        minDate = minDate > createdDate ? createdDate : minDate;
        maxDate = maxDate < createdDate ? createdDate : maxDate; 

        }
        
        cs1.Description = cs1.Description != null ? cs1.Description.replaceAll('<[^>]+>',' ') : null;

      }
 
      // Call methods to update fields from Asset, determine Service Location via postal codes and Entitlement

      if(casesWithProductOnly.size() > 0 && productIds.size() > 0) CaseTriggerActions.updateFieldsFromProduct(casesWithProductOnly, productIds);
      if(casesWithAssets.size() > 0 && assetIds.size() > 0) CaseTriggerActions.updateFieldsFromAsset(casesWithAssets, assetIds);
      if(casesNeedEntitlement.size() > 0) CaseTriggerActions.setCaseEntitlement(casesNeedEntitlement, oldCases);

      reviewCasesFlag = TRUE;

      //}
    }

    /*------------------------------------------------------------
    Author:      Denise Bacher
    Company:     Salesforce.com
    Description: Set the EntitlementId or the Purchase_Order__c for Cases with Record Type B&SH Service
                 Runs before insert, before update
    Inputs:      cases - The list of Cases
                 oldCases - Map of pervious Cases values
    Returns:    N/A
  
    History:
    <Date>      <Authors Name>    <Brief Description of Change>
    06/28/2016    Denise Bacher    Initial Creation (US1311)
    05/01/2017    Raj Sharan       Update to Include Record Type for Diagnostic Service (US-0002505)  
    ------------------------------------------------------------*/
    public static void setCaseEntitlement(List<Case> cases, Map<Id, Case> oldCases){
      List<Case> caseNeedsEntitlement = new List<Case>();
      Set<Id> rootAssetIds = new Set<Id>();
      Map<Id, Id> assetIdToRootId = new Map<Id, Id>();
      Set<Id> coverageRecordTypes = new Set<Id>{RECORD_TYPE_ID_CT_SLA, RECORD_TYPE_ID_CT_PM};
      Date minDate = System.today();
      Date maxDate = System.today();
    
      // collect list of cases that need their entitlement set, capture the asset ids, and the min and max created dates
      for(Case c : cases){
        Case oldCase = oldCases != null && oldCases.containsKey(c.Id) ? oldCases.get(c.Id) : null;
        system.debug('ORG_DEFAULT_OVERRIDE_ENTITLEMENT'+ORG_DEFAULT_OVERRIDE_ENTITLEMENT);
          if((c.RecordTypeId == RECORD_TYPE_ID_CASE_SUPPORT || c.RecordTypeId == RECORD_TYPE_ID_CASE_SERVICE || c.RecordTypeId ==  RECORD_TYPE_ID_DIAGNOSTIC_CASE_SERVICE || c.RecordTypeId == RECORD_TYPE_ID_CASE_INSTALL || 
              c.RecordTypeId == RECORD_TYPE_ID_CASE_PM) && String.isNotBlank(c.Root_Asset_Id__c) && 
              ( (ORG_DEFAULT_OVERRIDE_ENTITLEMENT && (oldCase == null || oldCase.EntitlementId != c.EntitlementId || oldCase.Root_Asset_Id__c != c.Root_Asset_Id__c)) || 
              (!ORG_DEFAULT_OVERRIDE_ENTITLEMENT && c.EntitlementId == null) ) ){
             caseNeedsEntitlement.add(c);
             rootAssetIds.add(c.Root_Asset_Id__c);
        
             Date createdDate = c.CreatedDate != null ? c.CreatedDate.date() : System.today();
        
             minDate = minDate > createdDate ? createdDate : minDate;
             maxDate = maxDate < createdDate ? createdDate : maxDate;  
          }
       }
    //System.debug('caseNeedsEntitlement '+caseNeedsEntitlement.size());
    //System.debug('rootAssetIds '+rootAssetIds);
    
      if(caseNeedsEntitlement.size() > 0){
        // query for entitlments
        Map<Id, List<Entitlement>> entitlementsByRootAssetId = new Map<Id, List<Entitlement>>();
        for(Entitlement e : [Select Id, AssetId, StartDate, EndDate, SLAProcess.SObjectType, Coverage_Template__r.Priority__c, Coverage_Template__r.RecordTypeId 
        From Entitlement
        Where AssetId IN: rootAssetIds
        And Coverage_Template__r.RecordTypeId IN: coverageRecordTypes
        And StartDate <=: minDate
        And EndDate >=: maxDate
        Order By Coverage_Template__r.Priority__c])
      {
        if(!entitlementsByRootAssetId.containsKey(e.AssetId)){
          entitlementsByRootAssetId.put(e.AssetId, new List<Entitlement>());
        }
        entitlementsByRootAssetId.get(e.AssetId).add(e);
      }
      //System.debug('entitlementsByRootAssetId '+entitlementsByRootAssetId);
      
      if(entitlementsByRootAssetId.size() > 0){
        // go through the cases that need entitlements and set it 
        for (Integer i = caseNeedsEntitlement.size() - 1; i >= 0; i--) {
          Case c = caseNeedsEntitlement[i];
          List<Entitlement> entitlements = entitlementsByRootAssetId.containsKey(c.Root_Asset_Id__c) ? entitlementsByRootAssetId.get(c.Root_Asset_Id__c) : new List<Entitlement>();
          
          for(Entitlement e : entitlements){
            // ensure the date ranges match up
            Date createdDate = c.CreatedDate != null ? c.CreatedDate.date() : System.today();

            //Logic added to choose PM or SLA entitlement
            if(e.StartDate <= createdDate && e.EndDate >= createdDate
              && ( (c.RecordTypeId == RECORD_TYPE_ID_CASE_SUPPORT || c.RecordTypeId == RECORD_TYPE_ID_CASE_SERVICE || c.RecordTypeId == RECORD_TYPE_ID_DIAGNOSTIC_CASE_SERVICE ||  c.recordtypeid == RECORD_TYPE_ID_CASE_INSTALL) && 
              e.Coverage_Template__r.RecordTypeId == RECORD_TYPE_ID_CT_SLA &&  e.SLAProcess.SObjectType == 'Case')
              || (c.RecordTypeId == RECORD_TYPE_ID_CASE_PM && e.Coverage_Template__r.RecordTypeId == RECORD_TYPE_ID_CT_PM)
            ){
              c.EntitlementId = e.Id;
              caseNeedsEntitlement.remove(i);
              break;
            }
          }
        }
      }
      
      // if there are cases that still do not have an entitlement, look for a related Purchase_Order__c
      if(caseNeedsEntitlement.size() > 0){
        // query for ContractLineItems
        Map<Id, List<ContractLineItem>> contractLineItemByRootAssetId = new Map<Id, List<ContractLineItem>>();
        for(ContractLineItem cli : [Select Id, AssetId, ServiceContract.StartDate, ServiceContract.EndDate 
          From ContractLineItem
          Where AssetId IN: rootAssetIds
          And ServiceContract.RecordTypeId =: RECORD_TYPE_ID_SC_PURCHASE_ORDER
          And ServiceContract.StartDate <=: minDate
          And ServiceContract.EndDate >=: maxDate])
        {
          if(!contractLineItemByRootAssetId.containsKey(cli.AssetId)){
            contractLineItemByRootAssetId.put(cli.AssetId, new List<ContractLineItem>());
          }
          contractLineItemByRootAssetId.get(cli.AssetId).add(cli);
        }
        
        // go through the remaining cases and set the contract line item
        for (Integer i = caseNeedsEntitlement.size() - 1; i >= 0; i--) {
          Case c = caseNeedsEntitlement[i];
          List<ContractLineItem> contractLineItems = contractLineItemByRootAssetId.containsKey(c.Root_Asset_Id__c) ? contractLineItemByRootAssetId.get(c.Root_Asset_Id__c) : new List<ContractLineItem>();
          
          for(ContractLineItem cli : contractLineItems){
            // ensure the date ranges match up
            Date createdDate = c.CreatedDate != null ? c.CreatedDate.date() : System.today();
            if(cli.ServiceContract.StartDate <= createdDate && cli.ServiceContract.EndDate >= createdDate){
              c.Purchase_Order__c = cli.Id;
              caseNeedsEntitlement.remove(i);
              break;
            }
          }
        }
      }
     }
    }

    /*------------------------------------------------------------
    Author:         Raj Sharan 
    Company:        AppsAssociates 
    Description:    Method to retrieve the Fields based on the Asset being populated on the Case 
    Inputs:         List of Cases being updated
                    List of AssetIds being populated onto Case
    Returns:        N/A
    Test Class:     CaseTrigger_Test

    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    10/3/2017       Raj Sharan          Update for Logic for Diagnostic and Surigical (US 2505)  
    ------------------------------------------------------------*/
    public static void updateFieldsFromProduct(List<Case> updateCases, List<Id> productIds ){

      /*if(productIds.size() > 0){ 

         Map<Id, Product2> productMap = new Map<Id, Product2>([Select Id, Name, Product_Source_Division__r.Source_Product_Line__r.Service_Region__c,
                                                             Product2.Product_Source_Division__r.Name                          
                                                             From Product2 Where Id IN: productIds]);
        String accountPostalCode;

system.debug('In updateFieldsFromProduct ' );
system.debug('In  productMap' + productMap);

        // Update fields on Case based on the Product
        if(updateCases.size() > 0 && !productMap.isEmpty()){
          for(Case c1:updateCases){

            accountPostalCode = c1.Account_Postal_Code__c;

            if(productMap.get(c1.productId).Product_Source_Division__r.Source_Product_Line__r.Service_Region__c != NULL)
              c1.Product_Source_Service_Team_Id__c = productMap.get(c1.productId).Product_Source_Division__r.Source_Product_Line__r.Service_Region__c;
            if(!String.IsEmpty(accountPostalCode)) c1.Install_Postal_Code__c =  accountPostalCode.left(5);

          }
        }
      }*/
    }

    /*------------------------------------------------------------
    Author:         Raj Sharan 
    Company:        AppsAssociates 
    Description:    Method to retrieve the Fields based on the Asset being populated on the Case 
    Inputs:         List of Cases being updated
                    List of AssetIds being populated onto Case
    Returns:        N/A
    Test Class:     CaseTrigger_Test

    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/1/2017       Raj Sharan          Update for Logic for Diagnostic and Surigical (US 2505)  
    ------------------------------------------------------------*/
    public static void updateFieldsFromAsset(List<Case> updateCases, List<Id> assetIds ){

      /*if(assetIds.size() > 0){ 

         Map<Id, Asset> assetMap = new Map<Id, Asset>([Select Id, Name, Product2Id, Product2.Product_Source_Division__r.Source_Product_Line__r.Service_Region__c,
                          Customer_Account__c, Install_Location__r.Zip_Code__c,
                          Ship_To_Location__c, Bill_To_Location__c, Install_Location__c, Product2.Product_Source_Division__r.Name                          
                          From Asset Where Id IN: assetIds]);


        // Update fields on Case based on the Asset
        if(updateCases.size() > 0 && !assetMap.isEmpty()){
          for(Case c1:updateCases){

            c1.ProductId = assetMap.get(c1.AssetId).Product2Id;
            c1.Customer_Name__c = assetMap.get(c1.AssetId).Customer_Account__c;
            c1.Install_Location__c = assetMap.get(c1.AssetId).Install_Location__c;
            c1.Product_Source_Service_Team_Id__c = assetMap.get(c1.AssetId).Product2.Product_Source_Division__r.Source_Product_Line__r.Service_Region__c;
            c1.Install_Postal_Code__c = assetMap.get(c1.AssetId).Install_Location__r.Zip_Code__c;
          }
        }
      }*/
    }
    
     /*------------------------------------------------------------
    Author:         Mani Sundaresan 
    Description:    Method to prevent cases from being dispatched without Case Effort (US 3657)
    Inputs:         cases - The list of Cases
                    oldCases - Map of pervious Cases values
    
    Returns:        N/A
    Test Class:     CaseTrigger_Test

    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    12/06/2017      Mani Sundaresan     Validation to prevent cases from getting dispatched without the Case Effort
    ------------------------------------------------------------*/
    public static void validateDispatchedCases(List<Case> cases, Map<Id, Case> oldCases){
    
        //Variable Declaration Section
        List<Case> caseList = new List<Case>();
        List<Id> caseIds = new List<Id>();
        
        System.debug('caseStatus:'+caseStatus);
        
        //Add all caseIds to a list if the status is changed to Dispatched
        for(Case c : cases){
            Case oldCase = oldCases != null && oldCases.containsKey(c.Id) ? oldCases.get(c.Id) : null;
            system.debug('c.Status::::'+c.Status);
            system.debug('oldCase.Status::::'+oldCase.Status);
            system.debug('caseStatus.Case_Status__c::::'+caseStatus.Case_Status__c);
            system.debug('caseStatus.Case_Status__c::::'+caseStatus.Case_Status_Ext__c);
            //system.debug('(caseStatus.Case_Status__c.contains(c.Status)::::'+(caseStatus.Case_Status__c.contains(c.Status)));
            //system.debug('(caseStatus.Case_Status_Ext__c.contains(c.Status)::::'+(caseStatus.Case_Status_Ext__c.contains(c.Status)));
            
            
            if(c.Status != oldCase.Status && ((caseStatus.Case_Status__c != null && caseStatus.Case_Status__c.contains(c.Status)) || caseStatus.Case_Status_Ext__c != null) && c.RecordTypeId == RECORD_TYPE_ID_CASE_SERVICE){
                caseIds.add(c.Id);    
            }
        }
        
        if(caseIds.size() > 0)
            caseList = [SELECT Id, CaseNumber, (SELECT Id from Session_Time__r) from Case where Id IN :caseIds];
        
        if(caseList.size() > 0)
            for(Case trigCase : cases){
                for(Case c : caseList){
                    if(trigCase.id == c.Id && c.getSObjects('Session_Time__r') == null && bypassValidation.Run_Validation_Rules__c)
                        trigCase.addError('Error: The case status cannot be modified without case effort.');
                }
            }
    }
    
    /*------------------------------------------------------------
    Author:         Mani Sundaresan 
    Description:    Added CalculateBusinessHoursAges trigger functionality 
    Inputs:         cases - The list of Cases
                    oldCases - Map of pervious Cases values
    
    Returns:        N/A
    Test Class:     CaseTrigger_Test

    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    12/18/2017      Mani Sundaresan     Added CalculateBusinessHoursAges trigger functionality 
    ------------------------------------------------------------*/
    public static void calculateBusinessHoursAges_insert(List<Case> cases, Map<Id, Case> oldCases){
    
        for(Case updatedCase : cases){
            updatedCase.Last_Status_Change__c = System.now();
            updatedCase.Time_With_Customer__c = 0;
            updatedCase.Time_With_Support__c = 0;    
        }
    }
    
    /*------------------------------------------------------------
    Author:         Mani Sundaresan 
    Description:    Added CalculateBusinessHoursAges trigger functionality 
    Inputs:         cases - The list of Cases
                    oldCases - Map of pervious Cases values
    
    Returns:        N/A
    Test Class:     CaseTrigger_Test

    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    12/18/2017      Mani Sundaresan     Added CalculateBusinessHoursAges trigger functionality 
    ------------------------------------------------------------*/
    public static void calculateBusinessHoursAges_update(List<Case> cases, Map<Id, Case> oldCases){
    
        //Variable Declaration Section
        List<Id> caseIds = new List<Id>();
        BusinessHours defaultHours = new BusinessHours();
        Set<String> stopStatusSet = new Set<String>();
        Set<String> closedStatusSet = new Set<String>();
        
        for (Case updatedCase : cases) {
            Case oldCase = oldCases != null && oldCases.containsKey(updatedCase.Id) ? oldCases.get(updatedCase.Id) : null;
            if (oldCase.Status!=updatedCase.Status && updatedCase.Last_Status_Change__c!=null) {
                caseIds.add(updatedCase.Id);
            }
        }
        
        if(caseIds.size() > 0){
        
            for (Stop_Status__c stopStatus : stopStatusList) {
                stopStatusSet.add(stopStatus.Name);
            }
        
            //Get the default business hours (we might need it)
            defaultHours = defaultHoursList[0];
    
            //Get the closed statuses (because at the point of this trigger Case.IsClosed won't be set yet)
            for (CaseStatus status : statusList) {
                closedStatusSet.add(status.MasterLabel);
            }
        }
        
        
        //For any case where the status is changed, recalc the business hours in the buckets
           for (Case updatedCase : cases) {
            Case oldCase = oldCases != null && oldCases.containsKey(updatedCase.Id) ? oldCases.get(updatedCase.Id) : null;
            if (oldCase.Status!=updatedCase.Status && updatedCase.Last_Status_Change__c!=null) {
                //OK, the status has changed
                if (!oldCase.IsClosed) {
                    //We only update the buckets for open cases

          //On the off-chance that the business hours on the case are null, use the default ones instead
                    Id hoursToUse = updatedCase.BusinessHoursId!=null?updatedCase.BusinessHoursId:defaultHours.Id;

                    //The diff method comes back in milliseconds, so we divide by 3600000 to get hours.
                    Double timeSinceLastStatus = BusinessHours.diff(hoursToUse, updatedCase.Last_Status_Change__c, System.now())/3600000.0;
                    System.debug(timeSinceLastStatus);

                    //We decide which bucket to add it to based on whether it was in a stop status before
                    if (stopStatusSet.contains(oldCase.Status)) {
                        updatedCase.Time_With_Customer__c += timeSinceLastStatus;
                    } else {
                        updatedCase.Time_With_Support__c += timeSinceLastStatus;
                    }

          if (closedStatusSet.contains(updatedCase.Status)) {
                      updatedCase.Case_Age_In_Business_Hours__c = updatedCase.Time_With_Customer__c + updatedCase.Time_With_Support__c;
          }
                }

                updatedCase.Last_Status_Change__c = System.now();
            }
        }
    
        
        
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Checks to see if incoming records need a service territory
    Inputs:             List of records, Map of old records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testCheckToAssignServiceTerritory
    ------------------------------------------------------------*/
    public static void checkToAssignServiceTerritory(List<Case> cases){
        //Filter cases, while also grabbing parent IDs
        List<Case> validCases = new List<Case>();
        Map<Id, Asset> assetsById = new Map<Id, Asset>();
        Map<Id, Site_Location__c> locsById = new Map<Id, Site_Location__c>();
        Map<Id, Product2> prodsById = new Map<Id, Product2>();
        Map<Id, Account> accsById = new Map<Id, Account>();
        for(Case cas : cases){
            if(cas.Service_Territory__c == null){
                validCases.add(cas);
                
                if(cas.AssetId != null && cas.Install_Location__c != null){
                    //Asset + Location configuration
                    assetsById.put(cas.AssetId, null);
                    locsById.put(cas.Install_Location__c, null);
                } else if(cas.ProductId != null && cas.AccountId != null){
                    //Product + Account configuration
                    prodsById.put(cas.ProductId, null);
                    accsById.put(cas.AccountId, null);
                }
            }
        }
        
        if(validCases.isEmpty()){
            return;
        }
        
        //Asset + Location configuration
        if(assetsById.size() > 0 && locsById.size() > 0){
            assetsById = new Map<Id, Asset>([
                SELECT Id
                      ,Product2.Product_Source_Division__r.Service_Territory__r.TopLevelTerritory.Name
                  FROM Asset
                 WHERE Id IN :assetsById.keySet()
                   AND Product2.Product_Source_Division__r.Service_Territory__r.TopLevelTerritory.Name != null
            ]);
            locsById = new Map<Id, Site_Location__c>([
                SELECT Id
                      ,Zip_Code__c
                      ,Country__c
                  FROM Site_Location__c
                 WHERE Id IN :locsById.keySet()
                   AND Zip_Code__c != null
            ]);
        }
        
        //Product + Account configuration
        if(prodsById.size() > 0 && accsById.size() > 0){
            prodsById = new Map<Id, Product2>([
                SELECT Id
                      ,Product_Source_Division__r.Service_Territory__r.TopLevelTerritory.Name
                  FROM Product2
                 WHERE Id IN :prodsById.keySet()
                   AND Product_Source_Division__r.Service_Territory__r.TopLevelTerritory.Name != null
            ]);
            accsById = new Map<Id, Account>([
                SELECT Id
                      ,BillingPostalCode
                      ,BillingCountryCode
                  FROM Account
                 WHERE Id IN :accsById.keySet()
                   AND BillingPostalCode != null
            ]);
        }
        
        //Gather division and zip values into sets
        Set<String> divs = new Set<String>();
        Set<String> zips = new Set<String>();
        for(Case cas : validCases){
            if(cas.AssetId != null && cas.Install_Location__c != null){
                //Asset + Location configuration
                Asset asst = assetsById.get(cas.AssetId);
                Site_Location__c loc = locsById.get(cas.Install_Location__c);
                if(asst != null && loc != null){
                    divs.add(asst.Product2.Product_Source_Division__r.Service_Territory__r.TopLevelTerritory.Name);
                    String zip = loc.Zip_Code__c;
                    if(loc.Country__c == 'US'){
                    	zip = zip.substring(0, 5);
                    }
                    zips.add(zip);
                }
            } else if(cas.ProductId != null && cas.AccountId != null){
                //Product + Account configuration
                Product2 prod = prodsById.get(cas.ProductId);
                Account acc = accsById.get(cas.AccountId);
                if(prod != null && acc != null){
                    divs.add(prod.Product_Source_Division__r.Service_Territory__r.TopLevelTerritory.Name);
                    String zip = acc.BillingPostalCode;
                    if(acc.BillingCountryCode == 'US'){
                    	zip = zip.substring(0, 5);
                    }
                    zips.add(zip);
                }
            }
        }
        
        if(divs.isEmpty() || zips.isEmpty()){
            return;
        }
        
        //Query for service geography IDs
        Map<String, Id> servGeoIdsByKey = ServiceTerritoryHelper.findServiceTerritoryIds(divs, zips);
        
        for(Case cas : validCases){
            if(cas.AssetId != null && cas.Install_Location__c != null){
                //Asset + Location configuration
                Asset asst = assetsById.get(cas.AssetId);
                Site_Location__c loc = locsById.get(cas.Install_Location__c);
                if(asst != null && loc != null && loc.Zip_Code__c != null && loc.Zip_Code__c.length() >= 5){
                	String key = asst.Product2.Product_Source_Division__r.Service_Territory__r.TopLevelTerritory.Name + '|';
                	if(loc.Country__c == 'US'){
                		key += loc.Zip_Code__c.substring(0, 5);
                	} else {
                		key += loc.Zip_Code__c;
                	}
                    cas.Service_Territory__c = servGeoIdsByKey.get(key);
                }
            } else if(cas.ProductId != null && cas.AccountId != null){
                //Product + Account configuration
                Product2 prod = prodsById.get(cas.ProductId);
                Account acc = accsById.get(cas.AccountId);
                if(prod != null && acc != null && acc.BillingPostalCode != null && acc.BillingPostalCode.length() >= 5){
                    String key = prod.Product_Source_Division__r.Service_Territory__r.TopLevelTerritory.Name + '|';
                    if(acc.BillingCountryCode == 'US'){
                		key += acc.BillingPostalCode.substring(0, 5);
                	} else {
                		key += acc.BillingPostalCode;
                	}
                    cas.Service_Territory__c = servGeoIdsByKey.get(key);
                }
            }
        }
    }
}