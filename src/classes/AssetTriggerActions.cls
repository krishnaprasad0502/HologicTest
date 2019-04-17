/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Asset Trigger functions
Test Class:     AssetTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
04/27/2016      Denise Bacher       Initial Creation (US762)
06/21/2016      Marc Goldstein      Added new function setQuoteLineLookups (US1316)
07/08/2016      Denise Bacher       Add Asset Creation Events (US1072)
05/05/2017      Raj Sharan          Update of Logic to address Hologic Owned Assets to create Internal Coverage Service Contract  (US-0002764) 
05/26/2017      Raj Sharan          Update of Logic to address Hologic Owned Assets to create Service Contract with Account of Hologic Corporation (US-0002764) 
07/27/2017      krishna prasad      When an Asset Status = Return  
                                    Updates that Customer_Account__c =  Configuration Settings.ReturnDefaultCustomerAccount 
                                    and AccountId = Configuration  ttings.ReturnDefaultAccount (US-0002764)
08/08/2017      Raj Sharan          Update the Account and Customer Account on Install Location Update (US-0002764)
08/09/2017      Raj Sharan          Update to Run Logic when Asset is Updated with Order Line and previously null update related Case and Work Order (US-0002764)
08/25/2017      John Christy        Update for Advance Exchange Warranty Creation US-0002764
08/25/2017      Raj Sharan          Update for Advance Exchange Warranty Creation US-0002764
09/05/2017      Mani Sundaresan     Update createServiceContracts - Create warranties when Asset ownership switches to Customer (US3217)
03/22/2018      Raviraj Reddy       Added a new function to call AMPS Merchant Track Method (US3819)
04/02/2018      Chris Jongbloed     Create and/or Update an Account_Product_Family__c record to reflect what Product Families are owned by the Account (US3843)
10/04/2018      Dave Mansell        Rework of previous code
------------------------------------------------------------*/

public class AssetTriggerActions {
    
    public static void checkToSetAccountLookups(List<Asset> assets, Map<Id, Asset> oldMap){
        //Filter for assets with newly populated install locations
        List<Asset> validAssets = new List<Asset>();
        for(Asset asst : assets){
            Asset old = oldMap.get(asst.Id);
            if(asst.Install_Location__c != null && asst.Install_Location__c != old.Install_Location__c){
                validAssets.add(asst);
            }
        }
        
        if(validAssets.size() > 0){
            setAccountLookups(validAssets);
        }
    }
    
    public static void setAccountLookups(List<Asset> assets){
        //Filter for assets with populated install locations
        Map<Id, Asset> assetsBySlocId = new Map<Id, Asset>();
        for(Asset asst : assets){
            if(asst.Install_Location__c != null){
                assetsBySlocId.put(asst.Install_Location__c, asst);
            }
        }
        
        if(assetsBySlocId.isEmpty()){
            return;
        }
        
        //Query for site location values
        Map<Id, Site_Location__c> slocsById = new Map<Id, Site_Location__c>([
            SELECT Id
                  ,Account__c
                  ,Account__r.ParentId
              FROM Site_Location__c
             WHERE Id IN :assetsBySlocId.keySet()
        ]);
        
        Configuration_Settings__c configSetting = Configuration_Settings__c.getInstance(); 
        for(Asset asst : assetsBySlocId.values()){
            if(asst.Status == 'Return'){
                //If status is return, populate fields with static config setting values
                asst.AccountId              = configSetting.Return_Default_Account__c;
                asst.Customer_Account__c    = configSetting.Return_Default_Customer_Account__c;
                asst.Ship_To_Location__c    = configSetting.Hologic_Default_Ship_To_Location__c;
                asst.Bill_To_Location__c    = configSetting.Hologic_Default_Bill_To_Location__c;
            } else {
                //For other statuses, populate fields with install location values
                Site_Location__c sloc = slocsById.get(asst.Install_Location__c);
                
                asst.AccountId = sloc.Account__c;
                if(sloc.Account__r.ParentId == null){
                    asst.Customer_Account__c = sloc.Account__c;
                } else {
                    asst.Customer_Account__c = sloc.Account__r.ParentId;
                }
            }
        }
    }
    
    public static void checkToSetQuoteLineLookups(List<Asset> assets, Map<Id, Asset> oldMap){
        //Filter for assets with no quote line values and newly populated order line item lookups
        List<Asset> validAssets = new List<Asset>();
        for(Asset asst : assets){
            Asset old = oldMap.get(asst.Id);
            if(asst.SBQQ__QuoteLine__c == null && asst.Order_Line_Item__c != null && asst.Order_Line_Item__c != old.Order_Line_Item__c){
                validAssets.add(asst);
            }
        }
        
        if(validAssets.size() > 0){
            setQuoteLineLookups(validAssets);
        }
    }
    
    public static void setQuoteLineLookups(List<Asset> assets){
        //Filter for assets with no quote line value and populated order line item lookups
        Map<Id, Asset> assetsByOIId = new Map<Id, Asset>();
        for(Asset asst : assets){
            if(asst.SBQQ__QuoteLine__c == null && asst.Order_Line_Item__c != null){
                assetsByOIId.put(asst.Order_Line_Item__c, asst);
            }
        }
        
        if(assetsByOIId.isEmpty()){
            return;
        }
        
        //Query for order item values
        Map<Id, OrderItem> oisById = new Map<Id, OrderItem>([
            SELECT Id
                  ,Quote_Line__c
              FROM OrderItem
             WHERE Id IN :assetsByOIId.keySet()
        ]);
        
        Configuration_Settings__c configSetting = Configuration_Settings__c.getInstance(); 
        for(Asset asst : assetsByOIId.values()){
            OrderItem oi = oisById.get(asst.Order_Line_Item__c);
            asst.SBQQ__QuoteLine__c = oi.Quote_Line__c;
        }
    }
    
    public static void checkToCreateServiceContracts(List<Asset> assets, Map<Id, Asset> oldMap){
        //Filter for valid assets
        List<Asset> validAssets = new List<Asset>();
        for(Asset asst : assets){
            Asset old = oldMap.get(asst.Id);
            
            system.debug('asst.RecordTypeId:::::'+asst.RecordTypeId);
            system.debug('asst.Order_Line_Item__c:::::'+asst.Order_Line_Item__c);
            system.debug('asst.Shipped_on_Date__c:::::'+asst.Shipped_on_Date__c);
            
            
            
            if(asst.RecordTypeId == GlobalUtility.getRecordTypeId('Asset', 'System')
                && asst.Order_Line_Item__c != null
                && asst.Shipped_on_Date__c != null
                && asst.Shipped_on_Date__c != old.Shipped_on_Date__c
              ){
              system.debug('::::::INIFLOOP:::::');
                validAssets.add(asst);
            }
        }
        system.debug('validAssets.size():::::'+validAssets.size());
        if(validAssets.size() > 0){
            createServiceContracts(validAssets);
        }
    }
    
    public static void createServiceContracts(List<Asset> assets){
        //Skip this if configuration settings are set to do so
        Configuration_Settings__c orgDefaults = Configuration_Settings__c.getOrgDefaults();
        if(Configuration_Settings__c.getInstance().Disable_Auto_SC_Creation__c == true){
            return;
        }
        
        //Filter for valid assets
        Set<Id> validAssetIds = new Set<Id>();
        for(Asset asst : assets){
            if(asst.RecordTypeId == GlobalUtility.getRecordTypeId('Asset', 'System') && asst.Shipped_on_Date__c != null){
                validAssetIds.add(asst.Id);
            }
        }
        
        if(validAssetIds.isEmpty()){
            return;
        }
        
        //Query for further field values
        assets = [
            SELECT Id
                  ,CreatedDate
                  ,Customer_Account__c
                  ,Order_Line_Item__c
                  ,Order_Line_Item__r.OrderId
                  ,Order_Line_Item__r.Order.Type
                  ,Order_Line_Item__r.Quote_Line__c
                  ,Order_Line_Item__r.Quote_Line__r.CurrencyISOCode
                  ,Order_Line_Item__r.Quote_Line__r.SBQQ__Product__c
                  ,Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__c
                  ,Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__r.SBQQ__PriceBook__c
                  ,Owner_Account__c
                  ,Ownership__c
                  ,Product2Id
                  ,Product2.Internal_Coverage__c
                  ,Product2.Internal_Coverage__r.Description
                  ,Product2.Internal_Coverage__r.Term_Months__c
                  ,Product2.Warranty_Coverage__c
                  ,Product2.Warranty_Coverage__r.Description
                  ,Product2.Warranty_Coverage__r.Term_Months__c
                  ,SerialNumber
                  ,Shipped_on_Date__c
                  ,(SELECT Id
                      FROM ContractLineItems
                     WHERE SBQQSC__ProductName__c LIKE '%WARRANTY%'
                        OR SBQQSC__ProductName__c LIKE '%Internal Coverage%'
                   )
              FROM Asset
             WHERE Id IN :validAssetIds
        ];
        
        Date endDate = System.today();
        List<Asset> assetsNeedingScons = new List<Asset>();
        Map<Id, List<Asset>> assetsByQuoteLineId = new Map<Id, List<Asset>>();
        Set<Id> pricebookIds = new Set<Id>();
        Set<Id> warrantyProductIds = new Set<Id>();
        for(Asset asst : assets){
            if(asst.Shipped_on_Date__c == null){
                asst.Shipped_on_Date__c = asst.CreatedDate.date();
            }
                    system.debug('asst.Order_Line_Item__c:::::'+asst.Order_Line_Item__c);
                    system.debug('asst.Order_Line_Item__r:::::'+asst.Order_Line_Item__r);
                    system.debug('asst.Order_Line_Item__r.Order.Type:::::'+asst.Order_Line_Item__r.Order.Type);
                    system.debug('asst.Product2Id:::::'+asst.Product2Id);
                    system.debug('asst.ContractLineItems.isEmpty():::::'+asst.ContractLineItems.isEmpty());
                    

            if(
        (
            (asst.Order_Line_Item__c != null
                && asst.Order_Line_Item__r.OrderId != null
                && asst.Order_Line_Item__r.Order.Type != 'Advanced Exchange'
            )
            || asst.Order_Line_Item__c == null
        )
        && asst.Product2Id != null
        && (asst.ContractLineItems.isEmpty())
      )
              {
                Id warrantyCoverageId;
                Integer termLength;
                if(asst.Ownership__c == 'Customer Owned' && asst.Product2.Warranty_Coverage__c != null && asst.Product2.Warranty_Coverage__r.Term_Months__c != null){
                    //Customer-owned asset
                    warrantyCoverageId = asst.Product2.Warranty_Coverage__c;
                    termLength = asst.Product2.Warranty_Coverage__r.Term_Months__c.intValue();
                } else if(asst.Ownership__c == 'Hologic Owned' && asst.Product2.Internal_Coverage__c != null && asst.Product2.Internal_Coverage__r.Term_Months__c != null){
                    //Hologic-owned asset
                    warrantyCoverageId = asst.Product2.Internal_Coverage__c;
                    termLength = asst.Product2.Internal_Coverage__r.Term_Months__c.intValue();
                }
                if(termLength == null){
                    continue;
                }
                
                endDate = asst.Shipped_on_Date__c.addMonths(termLength);
                
                if(endDate > System.today()){
                    //Service contracts must be created
                    assetsNeedingScons.add(asst);
                    
                    if(asst.Order_Line_Item__c != null && asst.Order_Line_Item__r.Quote_Line__c != null){
                        List<Asset> assetList = assetsByQuoteLineId.get(asst.Order_Line_Item__r.Quote_Line__c);
                        if(assetList == null){
                            assetList = new List<Asset>();
                        }
                        assetList.add(asst);
                        assetsByQuoteLineId.put(asst.Order_Line_Item__r.Quote_Line__c, assetList);
                        
                        if(asst.Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__c != null && asst.Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__r.SBQQ__PriceBook__c != null){
                            pricebookIds.add(asst.Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__r.SBQQ__PriceBook__c);
                        }
                    }
                    
                    if(warrantyCoverageId != null){
                        warrantyProductIds.add(warrantyCoverageId);
                    }
                }
            }
        }
        
        if(assetsNeedingScons.isEmpty()){
            return;
        }
        
        //Query for quote lines
        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id
                  ,Covered_Asset__c
                  ,POS_Quote_Line__c
                  ,SBQQ__DefaultSubscriptionTerm__c
                  ,SBQQ__Product__c
                  ,SBQQ__Product__r.Description
                  ,SBQQ__Product__r.Term_Months__c
                  ,SBQQ__Quote__c
                  ,SBQQ__Quote__r.SBQQ__Pricebook__c
                  ,SBQQ__RequiredBy__c
              FROM SBQQ__QuoteLine__c
             WHERE SBQQ__Product__r.Service_Subscription__c = true
               AND SBQQ__RequiredBy__c IN :assetsByQuoteLineId.keySet()
        ];
        
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            if(quoteLine.SBQQ__Quote__c != null && quoteLine.SBQQ__Quote__r.SBQQ__PriceBook__c != null){
                priceBookIds.add(quoteLine.SBQQ__Quote__r.SBQQ__PriceBook__c);
            }
            if(quoteLine.SBQQ__Product__c != null){
                warrantyProductIds.add(quoteLine.SBQQ__Product__c);
            }
        }
        
        //Grab the default Service Pricebook, this will be used on Warranty Contracts
        priceBookIds.add(orgDefaults.Service_Pricebook_USD__c);
        
        //Query for and map PBEs by key
        Map<String, PricebookEntry> pbesByKey = new Map<String, PricebookEntry>();
        for(PricebookEntry pbe : [
            SELECT Id
                  ,Product2Id
                  ,Pricebook2Id
              FROM PricebookEntry
             WHERE Product2Id IN :warrantyProductIds
               AND Pricebook2Id IN :pricebookIds
        ]){
            String key = String.valueOf(pbe.Product2Id).substring(0, 15) + '|' + String.valueOf(pbe.Pricebook2Id).substring(0, 15);
            pbesByKey.put(key, pbe);
        }
        
        //Create warranty service contracts
        Map<Id, ServiceContract> warrantySconsByAssetId = new Map<Id, ServiceContract>();
        for(Asset asst : assetsNeedingScons){
            ServiceContract scon = new ServiceContract();
            scon.Name               = 'Warranty Contract for SN: ' + asst.SerialNumber;
            scon.Description        = 'Warranty Contract for SN: ' + asst.SerialNumber;
            scon.ApprovalStatus     = 'Draft';
            scon.CurrencyISOCode    = UserInfo.getDefaultCurrency();
            scon.Pricebook2Id       = orgDefaults.Service_Pricebook_USD__c;
            scon.RecordTypeId       = GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Service_Contract');
            System.debug('asset StartDate:'+asst.Shipped_on_Date__c);
            scon.StartDate          = asst.Shipped_on_Date__c;
            System.debug('scon StartDate:'+scon.StartDate);
            System.debug(LoggingLevel.Info, 'scon startDate:'+scon.StartDate);
            
            if(asst.Ownership__c == 'Customer Owned'){
                scon.AccountId      = asst.Customer_Account__c;
                scon.EndDate        = scon.StartDate.addMonths(asst.Product2.Warranty_Coverage__r.Term_Months__c.intValue());
            } else if(asst.Ownership__c == 'Hologic Owned'){
                scon.AccountId      = asst.Owner_Account__c;
                scon.EndDate        = scon.StartDate.addMonths(asst.Product2.Internal_Coverage__r.Term_Months__c.intValue());
            }
            
            warrantySconsByAssetId.put(asst.Id, scon);
        }
        System.debug('SC Start Date:'+warrantySconsByAssetId.values());
         System.debug(LoggingLevel.Info, 'SC Start Date:'+warrantySconsByAssetId.values());
        insert warrantySconsByAssetId.values();
        
        //Create extended warranty service contracts
        Map<Id, ServiceContract> extendedWarrantySconsByAssetId = new Map<Id, ServiceContract>();
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            List<Asset> quoteLineAssets = assetsByQuoteLineId.get(quoteLine.SBQQ__RequiredBy__c);
            Integer termLength = 0;
            if(quoteLine.SBQQ__DefaultSubscriptionTerm__c != null){
                termLength = Integer.valueOf(quoteLine.SBQQ__DefaultSubscriptionTerm__c);
            }
            
            for(Asset asst : quoteLineAssets){
                ServiceContract warrantyScon = warrantySconsByAssetId.get(asst.Id);
                
                ServiceContract scon = new ServiceContract();
                scon.Name               = 'Extended Warranty Contract for SN: ' + asst.SerialNumber;
                scon.Description        = 'Extended Warranty Contract for SN: ' + asst.SerialNumber;
                scon.AccountId          = asst.Customer_Account__c;
                scon.ApprovalStatus     = 'Draft';
                scon.SBQQSC__Quote__c   = asst.Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__c;
                scon.CurrencyISOCode    = asst.Order_Line_Item__r.Quote_Line__r.CurrencyISOCode;
                scon.Pricebook2Id       = asst.Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__r.SBQQ__Pricebook__c;
                scon.RecordTypeId       = GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Service_Contract');
                scon.StartDate          = warrantyScon.EndDate.addDays(1);
                scon.EndDate            = warrantyScon.EndDate.addMonths(termLength);
                
                extendedWarrantySconsByAssetId.put(asst.Id, scon);
            }
        }
        insert extendedWarrantySconsByAssetId.values();
        
        //Create warranty contract line items
        Map<Id, ContractLineItem> warrantyCLIsByAssetId = new Map<Id, ContractLineItem>();
        for(Asset asst : assetsNeedingScons){
            ServiceContract warrantyScon = warrantySconsByAssetId.get(asst.Id);
            
            String pbeKey;
            String description;
            if(asst.Ownership__c == 'Customer Owned'){
                pbeKey = String.valueOf(asst.Product2.Warranty_Coverage__c).substring(0, 15);
                description = asst.Product2.Warranty_Coverage__r.Description;
            } else if(asst.Ownership__c == 'Hologic Owned'){
                pbeKey = String.valueOf(asst.Product2.Internal_Coverage__c).substring(0, 15);
                description = asst.Product2.Internal_Coverage__r.Description;
            }
            pbeKey += '|' + String.valueOf(orgDefaults.Service_Pricebook_USD__c).substring(0, 15);
            PricebookEntry pbe = pbesByKey.get(pbeKey);
            
            ContractLineItem cli = new ContractLineItem();
            cli.ServiceContractId       = warrantyScon.Id;
            cli.AssetId                 = asst.Id;
            cli.PricebookEntryId        = pbe.Id;
            cli.Description             = description;
            cli.StartDate               = warrantyScon.StartDate;
            cli.EndDate                 = warrantyScon.EndDate;
            cli.Quantity                = 1;
            cli.UnitPrice               = 0;
            cli.Asset_Created__c        = true;
        
            warrantyCLIsByAssetId.put(asst.Id, cli);
        }
        insert warrantyCLIsByAssetId.values();
        
        //Create extended warranty contract line items
        List<ContractLineItem> extendedWarrantyCLIs = new List<ContractLineItem>();
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            List<Asset> quoteLineAssets = assetsByQuoteLineId.get(quoteLine.SBQQ__RequiredBy__c);
            
            String pbeKey = String.valueOf(quoteLine.SBQQ__Product__c).substring(0, 15) + '|' + String.valueOf(quoteLine.SBQQ__Quote__r.SBQQ__Pricebook__c).substring(0, 15);
            PricebookEntry pbe = pbesByKey.get(pbeKey);
            
            Integer termLength = 0;
            if(quoteLine.SBQQ__DefaultSubscriptionTerm__c != null){
                termLength = Integer.valueOf(quoteLine.SBQQ__DefaultSubscriptionTerm__c);
            }
            
            for(Asset asst : quoteLineAssets){
                ServiceContract extendedWarrantyScon = extendedWarrantySconsByAssetId.get(asst.Id);
                ContractLineItem parentCLI = warrantyCLIsByAssetId.get(asst.Id);
                
                ContractLineItem cli = new ContractLineItem();
                cli.ServiceContractId       = extendedWarrantyScon.Id;
                cli.AssetId                 = asst.Id;
                cli.PricebookEntryId        = pbe.Id;
                cli.Description             = quoteLine.SBQQ__Product__r.Description;
                cli.StartDate               = parentCLI.EndDate.addDays(1);
                cli.EndDate                 = parentCLI.EndDate.addMonths(termLength);
                cli.Quantity                = 1;
                cli.UnitPrice               = 0;
                cli.Asset_Created__c        = true;
                
                extendedWarrantyCLIs.add(cli);
            }
        }
        insert extendedWarrantyCLIs;
        
        //Update warranty service contracts to Activated
        for(ServiceContract scon : warrantySconsByAssetId.values()){
            scon.ApprovalStatus = 'Activated';
        }
        update warrantySconsByAssetId.values();
    }
    
    public static void checkToUpdateMultipleAssetLookups(List<Asset> assets, Map<Id, Asset> oldMap){
        //Filter for valid assets
        List<Asset> validAssets = new List<Asset>();
        for(Asset asst : assets){
            Asset old = oldMap.get(asst.Id);
            if(asst.RecordTypeId == GlobalUtility.getRecordTypeId('Asset', 'System')
                && asst.Order_Line_Item__c != null
                && asst.Order_Line_Item__c != old.Order_Line_Item__c
              ){
                validAssets.add(asst);
            }
        }
        
        if(validAssets.size() > 0){
            updateMultipleAssetLookups(validAssets);
        }
    }
    
    public static void updateMultipleAssetLookups(List<Asset> assets){
        //Filter for valid assets
        Map<Id, Asset> validAssetsByOIId = new Map<Id, Asset>();
        for(Asset asst : assets){
            if(asst.RecordTypeId == GlobalUtility.getRecordTypeId('Asset', 'System') && asst.Order_Line_Item__c != null){
                validAssetsByOIId.put(asst.Order_Line_Item__c, asst);
            }
        }
        
        if(validAssetsByOIId.isEmpty()){
            return;
        }
        
        List<OrderItem> ois = [
            SELECT Id
                   ,(SELECT Id
                           ,AssetId
                       FROM Cases__r
                      WHERE RecordType.DeveloperName = 'B_SH_Install'
                        AND AssetId = null
                    )
                   ,(SELECT Id
                       FROM Work_Order_Line_Items__r
                    )
              FROM OrderItem
             WHERE Id IN :validAssetsByOIId.keySet()
        ];
        
        Map<Id, List<WorkOrder>> wosByCaseId = new Map<Id, List<WorkOrder>>();
        for(OrderItem oi : ois){
            for(Case cas : oi.Cases__r){
                wosByCaseId.put(cas.Id, null);
            }
        }
        
        for(WorkOrder wo : [
            SELECT Id
                  ,CaseId
              FROM WorkOrder
             WHERE CaseId IN :wosByCaseId.keySet()
        ]){
            List<WorkOrder> wos = wosByCaseId.get(wo.CaseId);
            if(wos == null){
                wos = new List<WorkOrder>();
            }
            wos.add(wo);
            wosByCaseId.put(wo.CaseId, wos);
        }
        
        List<Case> casesToUpdate = new List<Case>();
        List<WorkOrder> wosToUpdate = new List<WorkOrder>();
        List<WorkOrderLineItem> wolisToUpdate = new List<WorkOrderLineItem>();
        for(OrderItem oi : ois){
            Asset asst = validAssetsByOIId.get(oi.Id);
            
            oi.SBQQ__Asset__c = asst.RootAssetId;
            
            for(Case cas : oi.Cases__r){
                cas.AssetId = asst.RootAssetId;
                casesToUpdate.add(cas);
                
                if(wosByCaseId.size() > 0 && wosByCaseId.get(cas.Id) != null) {
                    for(WorkOrder wo : wosByCaseId.get(cas.Id)){
                        wo.AssetId = asst.RootAssetId;
                        wosToUpdate.add(wo);
                    }
                }
            }
            
            for(WorkOrderLineItem woli : oi.Work_Order_Line_Items__r){
                woli.AssetId = asst.RootAssetId;
                wolisToUpdate.add(woli);
            }
        }
        
        update ois;
        update casesToUpdate;
        update wosToUpdate;
        update wolisToUpdate;
    }
    
    public static void checkToSetAdvancedExchange(List<Asset> assets, Map<Id, Asset> oldMap){
        //Filter for valid assets
        List<Asset> validAssets = new List<Asset>();
        for(Asset asst : assets){
            Asset old = oldMap.get(asst.Id);
            if(asst.Order_Line_Item__c != null && asst.Order_Line_Item__c != old.Order_Line_Item__c){
                validAssets.add(asst);
            }
        }
        
        if(validAssets.size() > 0){
            setAdvancedExchange(validAssets);
        }
    }
    
    public static void setAdvancedExchange(List<Asset> assets){
        //Query for further details on valid assets
        List<Asset> validAssets = new List<Asset>();
        for(Asset asst : assets){
            if(asst.Order_Line_Item__c != null){
                validAssets.add(asst);
            }
        }
        
        if(validAssets.isEmpty()){
            return;
        }
        
        //Query for CLIs, including parent Assets and child Service Billing Schedules
        List<ContractLineItem> originalCLIs = new List<ContractLineItem>([
            SELECT Id
                  ,AssetId
                  ,Asset.Name
                  ,Asset.Order_Line_Item__c
                  ,Asset.Order_Line_Item__r.Line_Type__c
                  ,Asset.Order_Line_Item__r.OrderId
                  ,Asset.Order_Line_Item__r.Order.Type
                  ,Asset.Order_Line_Item__r.Returned_Asset__c
                  ,Asset.Shipped_on_Date__c
                  ,Asset_Created__c
                  ,Asset_Product_Description__c
                  ,Contract_Activated__c
                  ,Covered_Asset__c
                  ,Description
                  ,Discount
                  ,EndDate,PricebookEntryId
                  ,Quantity
                  ,SBQQSC__Bundle__c
                  ,SBQQSC__Bundled__c
                  ,SBQQSC__ComponentDiscountedByPackage__c
                  ,SBQQSC__ContractNumber__c
                  ,SBQQSC__PricingMethod__c
                  ,SBQQSC__ProrateMultiplier__c
                  ,SBQQSC__Quantity__c
                  ,SBQQSC__QuoteLine__c
                  ,Service_Type__c
                  ,ServiceContractId
                  ,StartDate
                  ,Suppress_Credit__c
                  ,Type__c
                  ,UnitPrice
                  ,(SELECT Id
                          ,Name
                          ,Amount__c
                          ,Contract_Line_Item__c
                          ,End_Date__c
                          ,Number_of_Periods__c
                          ,Period__c
                          ,Sequence__c
                          ,Start_Date__c
                      FROM Service_Billing_Schedules__r
                   )
              FROM ContractLineItem
             WHERE AssetId IN :validAssets
               AND Asset.Order_Line_Item__r.Order.Type = 'Advanced Exchange'
               AND (Status = 'Active' OR Status = 'Inactive') 
               AND EndDate > :System.today()
        ]);
        
        if(originalCLIs.isEmpty()){
            return;
        }
        
        Map<Id, List<Entitlement>> entsByAssetId = new Map<Id, List<Entitlement>>();
        List<Entitlement> entsToUpdate = new List<Entitlement>();
        for(Entitlement ent : [
            SELECT Id
                  ,AssetId
                  ,StartDate
              FROM Entitlement
             WHERE AssetId IN :validAssets
        ]){
            List<Entitlement> ents = entsByAssetId.get(ent.AssetId);
            if(ents == null){
                ents = new List<Entitlement>();
            }
            ents.add(ent);
            entsByAssetId.put(ent.AssetId, ents);
            entsToUpdate.add(ent);
        }
        
        //Clone contract line items
        Map<Id, ContractLineItem> clonedCLIsByOriginalCLIId = new Map<Id, ContractLineItem>();
        for(ContractLineItem originalCLI : originalCLIs){
            //Create clone
            ContractLineItem clonedCLI = originalCLI.clone();
            clonedCLI.StartDate = originalCLI.Asset.Shipped_on_Date__c;
            clonedCLIsByOriginalCLIId.put(originalCLI.Id, clonedCLI);
            
            //Cancel original
            originalCLI.EndDate = originalCLI.Asset.Shipped_on_Date__c;
            if(originalCLI.Asset.Shipped_on_Date__c < originalCLI.StartDate){
                originalCLI.EndDate = System.today();
            }
            
            //Cancel entitlements
            if(entsByAssetId.get(originalCLI.AssetId) != null){
                for(Entitlement ent : entsByAssetId.get(originalCLI.AssetId)){
                    ent.EndDate = originalCLI.Asset.Shipped_on_Date__c; 
                    if(originalCLI.Asset.Shipped_on_Date__c < ent.StartDate){
                        ent.EndDate = System.today();
                    }
                }
            }
        }
        insert clonedCLIsByOriginalCLIId.values();
        update originalCLIs;
        update entsToUpdate;
        
        //Clone service billing schedules
        Map<Id, Service_Billing_Schedule__c> clonedSBSesByOriginalSBSId = new Map<Id, Service_Billing_Schedule__c>();
        List<Service_Billing_Schedule__c> originalSBSes = new List<Service_Billing_Schedule__c>();
        for(ContractLineItem originalCLI : originalCLIs){
            ContractLineItem clonedCLI = clonedCLIsByOriginalCLIId.get(originalCLI.Id);
            for(Service_Billing_Schedule__c originalSBS : originalCLI.Service_Billing_Schedules__r){
                //Create clone;
                Service_Billing_Schedule__c clonedSBS = originalSBS.clone();
                clonedSBS.Contract_Line_Item__c = clonedCLI.Id;
                clonedSBS.Start_Date__c = clonedCLI.StartDate;
                clonedSBSesByOriginalSBSId.put(originalSBS.Id, clonedSBS);
                
                //Cancel originals
                originalSBS.End_Date__c = originalCLI.Asset.Shipped_on_Date__c;
                if(originalCLI.Asset.Shipped_on_Date__c < originalSBS.Start_Date__c){
                    originalSBS.End_Date__c = System.today();
                }
                originalSBSes.add(originalSBS);
            }
        }
        insert clonedSBSesByOriginalSBSId.values();
        update originalSBSes;
    }
    
    /*public static void checkToCreateInitiatingTasks(List<Asset> assets, Map<Id, Asset> oldMap){
        //Filter for valid assets
        List<Asset> validAssets = new List<Asset>();
        for(Asset asst : assets){
            Asset old = oldMap.get(asst.Id);
            if(asst.AMPS_Track__c != null && asst.AMPS_Track__c != old.AMPS_Track__c){
                validAssets.add(asst);
            }
        }
        
        if(validAssets.size() > 0){
            createInitiatingTasks(validAssets);
        }
    }
    
    public static void createInitiatingTasks(List<Asset> assets){
        //Filter for valid assets
        List<Asset> validAssets = new List<Asset>();
        for(Asset asst : assets){
            if(asst.AMPS_Track__c != null){
                validAssets.add(asst);
            }
        }
        
        if(validAssets.isEmpty()){
            return;
        }
        
        assets = [
            SELECT Id
                  ,AMPS_Track__c
                  ,(SELECT Id
                          ,User__c
                      FROM Asset_Teams__r
                     WHERE Relationship__c = 'AMPS Representative'
                    )
              FROM Asset
             WHERE Id IN :validAssets
        ];
        
        Map<String, AMPS_Marketing_Activity_Flow__c> flowsByType = new Map<String, AMPS_Marketing_Activity_Flow__c>();
        for(AMPS_Marketing_Activity_Flow__c flow : [
            SELECT Id
                  ,Initiating_Task_Type__c
                  ,Name
                  ,Number_of_days_to_be_added__c
              FROM AMPS_Marketing_Activity_Flow__c
              WHERE Name != NULL
                AND Initiating_Task_Type__c != NULL
        ]){
            flowsByType.put(flow.Initiating_Task_Type__c, flow);
        }
        
        List<Task> tasksToInsert = new List<Task>();
        for(Asset asst : assets){
            AMPS_Marketing_Activity_Flow__c flow = flowsByType.get(asst.AMPS_Track__c);
            if(flow != null && asst.Asset_Teams__r.size() > 0){
                Task tsk = new Task();
                tsk.Priority            = 'Normal';
                tsk.Status              = 'Not Started';
                tsk.OwnerId             = asst.Asset_Teams__r[0].User__c ;
                if(flow.Number_of_days_to_be_added__c != null){
                    tsk.ActivityDate    = System.today().addDays(Integer.valueOf(flow.Number_of_days_to_be_added__c));
                }
                tsk.Subject             = flow.Name;
                tsk.WhatID              = asst.ID;
                tasksToInsert.add(tsk);
            }
        }
        
        insert tasksToInsert;
    }*/
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Updates AccountProductFamily records when an asset is updated
    Inputs:             List of records, Map of old records
    Returns:            N/A
    Test Class(es):     AssetTriggerActions_Test.testUpdateAccountProductFamily
    ------------------------------------------------------------*/
    public static void updateAccountProductFamily (List<Asset> assets){
        //Prep custom setting map
        Map<String, String> familyToFieldMap = new Map<String, String>();
        for(Account_Product_Family_Settings__c apfs : Account_Product_Family_Settings__c.getall().values()){
            familyToFieldMap.put(apfs.Name, apfs.Product_Family_Field__c);
        }
        
        //Loop through assets and get account Ids
        Set<Id> accIds = new Set<Id>();
        for(Asset asst : assets){
            accIds.add(asst.AccountId);
        }
        
        //Query for accounts
        Map<Id, Account> accsById = new Map<Id, Account>([
            SELECT Id
                  ,Account_Product_Family__c
              FROM Account
             WHERE Id IN :accIds
        ]);
        
        //Query for assets counts and map by Account Id
        Map<Id, Map<String, Integer>> assetCountsByAccId = new Map<Id, Map<String, Integer>>();
        for(AggregateResult res : [
            SELECT AccountId accId
                  ,Product2.Family family
                  ,Count(Id) qty
              FROM Asset
             WHERE AccountId IN :accIds
               AND Product2.Family != null
             GROUP BY AccountId, Product2.Family
            ]){
            Id accId = (Id)res.get('accId');
            Map<String, Integer> assetMap = assetCountsByAccId.get(accId);
            if(assetMap == null){
                assetMap = new Map<String, Integer>();
            }
            assetMap.put((String)res.get('family'), (Integer)res.get('qty'));
            assetCountsByAccId.put(accId, assetMap);
        }
        
        //Loop through accounts and update APFs for each
        Map<Id, Account_Product_Family__c> apfsToUpsertByAccId = new Map<Id, Account_Product_Family__c>();
        for(Account acc : accsById.values()){
            //Create new temp APF
            Account_Product_Family__c apf = new Account_Product_Family__c();
            if(acc.Account_Product_Family__c != null){
                apf.Id = acc.Account_Product_Family__c;
            }
            apf.Account__c = acc.Id;
            
            //Reset all to 0
            for(String fieldName : familyToFieldMap.values()){
                apf.put(fieldName, 0);
            }
            
            Map<String, Integer> assetMap = assetCountsByAccId.get(acc.Id);
            if(assetMap != null){
                for(String familyName : assetMap.keySet()){
                    String fieldName = familyToFieldMap.get(familyName);
                    if(fieldName != null){
                        apf.put(fieldName, (Decimal)assetMap.get(familyName));
                    }
                }
            }
            
            apfsToUpsertByAccId.put(acc.Id, apf);
        }
        
        //Upsert AFPs
        upsert apfsToUpsertByAccId.values();
        
        //Loop back through Accounts and update their field values
        List<Account> accsToUpdate = new List<Account>();
        for(Account acc : accsById.values()){
            if(acc.Account_Product_Family__c == null){
                acc.Account_Product_Family__c = apfsToUpsertByAccId.get(acc.Id).Id;
                accsToUpdate.add(acc);
            }
        }
        
        //Update accounts with new APF values
        update accsToUpdate;
    }
 
    public static void updateRelatedWorkOrders(List<Asset> assets, Map<Id, Asset> oldMap){
        //Filter assets
        List<Asset> validAssets = new List<Asset>();
        for(Asset asst : assets){
            Asset old = oldMap.get(asst.Id);
            if(asst.Order_Line_Item__c != null && asst.Order_Line_Item__c != old.Order_Line_Item__c){
                validAssets.add(asst);
            }
        }
        
        if(validAssets.size() > 0){
            updateRelatedWorkOrders(validAssets);
        }
    }
    
    public static void updateRelatedWorkOrders(List<Asset> assets){
        //Filter assets
        List<Asset> validAssets = new List<Asset>();
        for(Asset asst : assets){
            if(asst.Order_Line_Item__c != null){
                validAssets.add(asst);
            }
        }
        
        if(validAssets.isEmpty()){
            return;
        }
        
        Map<Id, OrderItem> oisById = new Map<Id, OrderItem>([
            SELECT Id
                  ,(SELECT Id
                          ,AssetId
                      FROM Work_Orders__r
                     WHERE AssetId = null
                   )
              FROM OrderItem
             WHERE Id IN (
                SELECT Order_Line_Item__c
                  FROM Asset
                 WHERE Id IN :validAssets
                   AND RecordType.DeveloperName = 'System'
             )
        ]);
        
        List<WorkOrder> wosToUpdate = new List<WorkOrder>();
        for(Asset asst : validAssets){
            if(asst.Order_Line_Item__c != null){
                OrderItem oi = oisById.get(asst.Order_Line_Item__c);
                if(oi != null && oi.Work_Orders__r != null && asst.RecordTypeId == GlobalUtility.getRecordTypeId('Asset', 'System')){
                    for(WorkOrder wo : oi.Work_Orders__r){
                        if(wo.AssetId == null){
                            wo.AssetId = asst.Id;
                            wosToUpdate.add(wo);
                            break;
                        }
                    }
                }
            }
        }
        update wosToUpdate;
    }
    
}











/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Asset Trigger functions
Test Class:     AssetTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
04/27/2016      Denise Bacher       Initial Creation (US762)
06/21/2016      Marc Goldstein      Added new function setQuoteLineLookups (US1316)
07/08/2016      Denise Bacher       Add Asset Creation Events (US1072)
05/05/2017      Raj Sharan          Update of Logic to address Hologic Owned Assets to create Internal Coverage Service Contract  (US-0002764) 
05/26/2017      Raj Sharan          Update of Logic to address Hologic Owned Assets to create Service Contract with Account of Hologic Corporation (US-0002764) 
07/27/2017      krishna prasad      When an Asset Status = Return  
                                    Updates that Customer_Account__c =  Configuration Settings.ReturnDefaultCustomerAccount 
                                    and AccountId = Configuration  ttings.ReturnDefaultAccount (US-0002764)
08/08/2017      Raj Sharan          Update the Account and Customer Account on Install Location Update (US-0002764)
08/09/2017      Raj Sharan          Update to Run Logic when Asset is Updated with Order Line and previously null update related Case and Work Order (US-0002764)
08/25/2017      John Christy        Update for Advance Exchange Warranty Creation US-0002764
08/25/2017      Raj Sharan          Update for Advance Exchange Warranty Creation US-0002764
09/05/2017      Mani Sundaresan     Update createServiceContracts - Create warranties when Asset ownership switches to Customer (US3217)
03/22/2018      Raviraj Reddy       Added a new function to call AMPS Merchant Track Method (US3819)
04/02/2018      Chris Jongbloed     Create and/or Update an Account_Product_Family__c record to reflect what Product Families are owned by the Account (US3843)
------------------------------------------------------------*/
/*
public with sharing class AssetTriggerActions {

    //Static Variables
    private static final Id assetSystemRecordTypeId = GlobalUtility.getRecordTypeId('Asset', 'System');
    private static final Id installCaseRecordTypeId = GlobalUtility.getRecordTypeId('Case', 'B_SH_Install');
    static Boolean assetSetAdvancedExchange = false;
*/
    /*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Find and set the account lookups for site and customer if they are null. 
Site Account is populated from the account related to the Install Location
Customer Account is populated from the account that shares the Oracle Paty Id value
Specifically, this can occur on records inserted via Webservice API 
Runs before insert, before update
Inputs:         assets - The list of Assets to modify
oldAssets - Map of assets containing old values
Returns:        N/A

History:
<Date>          <Authors Name>      <Brief Description of Change>
03/29/2016      Denise Bacher       Initial Creation (US460)
07/27/2017      krishna prasad      When an Asset Status = Return  Updates that Customer_Account__c =  Configuration Settings.ReturnDefaultCustomerAccount (US-0002764)
08/08/2017      Raj Sharan          Update the Account, Customer Account, Ship To & Bill To on Install Location Update (US-0002764)

------------------------------------------------------------*/
    /*public static void setAccountLookups(List<Asset> assets, Map<Id, Asset> oldAssets){
        
        //07/27/2017      krishna prasad  return all values from Configuration_Settings__c (custom settings)Instance
        Configuration_Settings__c configSetting = Configuration_Settings__c.getInstance(); 
        Set<Id> siteLocationIds = new Set<ID>(); // site location ids we need to query to get site account lookups
        Map<Id, Site_Location__c> siteLocationIdToAccountsId = new Map<Id, Site_Location__c>();
        List<Asset> assetsNeedingAccountsUpdate = new List<Asset>();
        
        for(Asset a : assets){
            Asset oldAsset = oldAssets != null && oldAssets.containsKey(a.Id) ? oldAssets.get(a.Id) : null;
            
            // find assets that need their site location updated
            if(a.Status != 'Return' && ((a.Install_Location__c != null && oldAsset == null )|| 
              (oldAsset != null && oldAsset.Install_Location__c != a.Install_Location__c && a.Install_Location__c != NULL))) {
                System.debug('a.Install_Location__c = ' + a.Install_Location__c);
                siteLocationIds.add(a.Install_Location__c);
                assetsNeedingAccountsUpdate.add(a);
                
            }
            
        }
        
        // fetch the site locations and their related accounts
        for(Site_Location__c location : [Select Id, Account__c, Account__r.ParentId From Site_Location__c Where Id IN: siteLocationIds]){
            siteLocationIdToAccountsId.put(location.Id, location);
        }
        
        
        // set the site account
        for(Asset a : assetsNeedingAccountsUpdate){
            
            if(siteLocationIdToAccountsId.containsKey(a.Install_Location__c)){
              a.AccountId = siteLocationIdToAccountsId.get(a.Install_Location__c).Account__c;

                if(siteLocationIdToAccountsId.get(a.Install_Location__c).Account__r.ParentId != NULL )  
                  a.Customer_Account__c = siteLocationIdToAccountsId.get(a.Install_Location__c).Account__r.ParentId;

                if(siteLocationIdToAccountsId.get(a.Install_Location__c).Account__r.ParentId == NULL)  
                  a.Customer_Account__c = siteLocationIdToAccountsId.get(a.Install_Location__c).Account__c;

            }
        }       
        
        // 07/27/2017 krishna prasad Asset Status equals Return Updates that Customer_Account__c equals Configuration 
        // Settings.Return Default CustomerAccount, AccountId, Ship To and Bill To 
        
        for(Asset a : assets){
            if(a.status =='Return'){
                system.debug('a Status = ' + a.status);
                a.AccountId  = configSetting.Return_Default_Account__c;
                a.Customer_Account__c  = configSetting.Return_Default_Customer_Account__c;
                a.Ship_To_Location__c  = configSetting.Hologic_Default_Ship_To_Location__c;
                a.Bill_To_Location__c  = configSetting.Hologic_Default_Bill_To_Location__c;
                system.debug('a Status = ' + a.status);
                
            }
        }
    }
    */
/*------------------------------------------------------------
Author:         Marc Goldstein
Company:        Salesforce.com
Description:    Find and set the quote line lookup. 
This method looks at the quote line relationship on the related order line item
to set the quote line relationship on the asset itself
Runs before insert, before update
Inputs:         assets - List of Assets needing a quote line relationship
oldAssets - Map of assets containing old values
Returns:        N/A

History:
<Date>          <Authors Name>      <Brief Description of Change>
06/21/2016      Marc Goldstein      Initial Creation (US1316)
07/08/2016      Denise Bacher       Updated to get SBQQ__Quote_Line__c from Order_Line_Item__c instead of Sales_Order_Line_Item__c (US1072)
------------------------------------------------------------*/
    /*public static void setQuoteLineLookups(List<Asset> assets, Map<Id, Asset> oldAssets){

        Set<Id> orderItemIds = new Set<Id>();
        Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>();
        
        for(Asset a : assets){
            Asset oldAsset = oldAssets != null && oldAssets.containsKey(a.Id) ? oldAssets.get(a.Id) : null;
            
            if(a.SBQQ__QuoteLine__c == null || oldAsset == null || a.Order_Line_Item__c != oldAsset.Order_Line_Item__c){
                orderItemIds.add(a.Order_Line_Item__c);
            }
        }
        
        orderItemMap = new Map<Id, OrderItem>([Select Id, Quote_Line__c From OrderItem Where Id IN: orderItemIds]);
        
        for(Asset a : assets){
            OrderItem assetOrderItem = orderItemMap.containsKey(a.Order_Line_Item__c) ? orderItemMap.get(a.Order_Line_Item__c) : new OrderItem();
            
            if(a.SBQQ__QuoteLine__c != assetOrderItem.Quote_Line__c && assetOrderItem.Quote_Line__c != null){
                a.SBQQ__QuoteLine__c = assetOrderItem.Quote_Line__c;
            }
        }
    }*/
    
/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    If the Asset.Order_Item__c is not null, sets asset lookups on Case (AssetId) and Work Orders (AssetId)
Runs after insert
Inputs:         assets - The list of Assets
Returns:        N/A

History:
<Date>          <Authors Name>      <Brief Description of Change>
07/08/2016      Denise Bacher       Initial Creation (US1072)
08/01/2017      Mani Sundaresan     Update logic to stamp RootAssetId on related Order Line Item, Case, WO's and WOLI's (US3026)
04/11/2018      Ronald Mendoza      Replaced Quote__c with SBQQ__Quote__c reference due to duplicate issue (US-0003947)
------------------------------------------------------------*/
    /*public static void updateCaseWorkOrderAssetLookups(List<Asset> assets, Map<Id, Asset> oldAssets){
       
        Map<Id, Asset> orderItemIdToAsset = new Map<Id, Asset>();
        Set<Id> orderItemIds = new Set<Id>();
        List<OrderItem> orderItems = new List<OrderItem>();
        
        for(Asset a : assets){
            
            Asset oldAsset = oldAssets != null && oldAssets.containsKey(a.Id) ? oldAssets.get(a.Id) : null;
            
            if (a.RecordTypeId == assetSystemRecordTypeId && a.Order_Line_Item__c != null && (oldAsset == null || 
                (oldAsset != null && oldAsset.Order_Line_Item__c != a.Order_Line_Item__c))) {

                    orderItemIds.add(a.Order_Line_Item__c);
                    orderItemIdToAsset.put(a.Order_Line_Item__c, a);
                    //OrderItem oi = new OrderItem(Id = a.Order_Line_Item__c, Asset__c = a.Id);
                    //Replaced Quote__c with SBQQ__Quote__c reference due to duplicate issue (US-0003947)
                    OrderItem oi = new OrderItem(Id = a.Order_Line_Item__c, SBQQ__Asset__c = a.Id);
                    orderItems.add(oi);

                }
        }
        
        // get cases and work orders that need an asset
        List<WorkOrder> workOrders = new List<WorkOrder>();
        List<Case> cases = [Select Id, AssetId, Order_Line_Item__c, (Select Id, AssetId From WorkOrders)
                            From Case
                            Where Order_Line_Item__c IN :orderItemIds
                            AND (RecordTypeId = :installCaseRecordTypeId)
                            AND AssetId = null];

        System.debug('Case List:'+cases);
        
        for(Case c : cases){
            if(orderItemIdToAsset.containsKey(c.Order_Line_Item__c)){
                Id rootAssetId = orderItemIdToAsset.get(c.Order_Line_Item__c).RootAssetId;
                c.AssetId = rootAssetId;
                
                for(WorkOrder wo : c.WorkOrders){
                    wo.AssetId = rootAssetId;
                    workOrders.add(wo);
                }
            }
        }
        
        // get work order line items that need an asset
        List<WorkOrderLineItem> workOrderItems = [Select Id, AssetId, Order_Line_Item__c From WorkOrderLineItem Where Order_Line_Item__c IN: orderItemIds];
        for(WorkOrderLineItem woli: workOrderItems){
            if(orderItemIdToAsset.containsKey(woli.Order_Line_Item__c)){
                Id rootAssetId = orderItemIdToAsset.get(woli.Order_Line_Item__c).RootAssetId;
                woli.AssetId = rootAssetId;
            }
        }
        
        // update the records
        if (orderItems.size() > 0) {
            //06-07-2018-- added by kasmoor as part of US-4718
            try{
                update orderItems;
            }
            catch(DmlException e){
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }

        if (cases.size()> 0) {
            //06-07-2018-- added by kasmoor as part of US-4718
            try{
                update cases;
            }
            catch(DmlException e){
                System.debug('The following exception has occurred: ' + e.getMessage());
            }

        }

        if (workOrders.size()> 0) {
            //06-07-2018-- added by kasmoor as part of US-4718
            try{
                update workOrders;
            }
            catch(DmlException e){
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }

        if (workOrderItems.size()> 0) {
            //06-07-2018-- added by kasmoor as part of US-4718
            try{
                update workOrderItems;
            }
            catch(DmlException e){
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }
    }
    */
    /*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Create the Service Contracts, and Contract Line Items for new Assets
Runs after insert
Inputs:         assets - The list of Assets
Returns:        N/A

History:
<Date>          <Authors Name>      <Brief Description of Change>
07/11/2016      Denise Bacher       Initial Creation (US1072 & US142)
07/29/2016      Denise Bacher       Remove entitlement creation - moved to ContractLineItemTriggerActions (US164)
08/02/2016      Marc Goldstein      Added logic to prevent service contracts when internal accounts (US1426)
08/08/2016      Denise Bacher       Set ContractLineItem.Asset_Created__c to true so ServiceContract.ApprovalStatus isn't reset to 'Draft' (US1444)
11/04/2016      Denise Bacher       Update to create Warranty Service Contracts w/o an OrderItem or a Quote Line (US-0001141)
05/05/2017      Raj Sharan          Update of Logic to address Hologic Owned Assets to create Internal Coverage Service Contract  (US-0002764)
09/05/2017      Mani Sundaresan     Update createServiceContracts - Create warranties when Asset ownership switches to Customer (US3217)
10/03/2017      Raj Sharan          Update to Only create Warranty when Shipment Date and Term Length greater than Today 
------------------------------------------------------------*/
    /*public static void createServiceContracts(List<Asset> assets, Map<Id, Asset> oldAssets){
        Configuration_Settings__c orgDefaults = Configuration_Settings__c.getOrgDefaults();
        Date Today = System.Today();
        Date endDate = System.Today();
        Integer coverageTerm;

        // if the config setting to disable auto service contract creation is set to true, do not perform this function
        Boolean disableServiceContractCreation = (Boolean)Configuration_Settings__c.getInstance().Disable_Auto_SC_Creation__c;
        if(disableServiceContractCreation){
            return;
        }
        
        Id assetSystemRecordTypeId = GlobalUtility.getRecordTypeId('Asset', 'System');
        Id serviceContractServiceContractRecordTypeId = GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Service_Contract');
        Map<Id, Asset> assetsNeedServiceContract = new Map<Id, Asset>();
        Map<Id, Map<Id, Asset>> quoteLineIdToAsset = new Map<Id, Map<Id, Asset>>();
        Set<Id> quoteLineIds = new Set<Id>();
        Set<Id> priceBookIds = new Set<Id>();
        Set<Id> warrantyProductIds = new Set<Id>();
        Set<Id> assetIdSet = new Set<Id>();
        List<Asset> potentialAssetsNeedingContract = new List<Asset>();

        for(Asset a : assets){

            Asset oldAsset = oldAssets != null && oldAssets.containsKey(a.Id) ? oldAssets.get(a.Id) : null;

            if(a.RecordTypeId == assetSystemRecordTypeId && a.Order_Line_Item__c != null && a.Shipped_on_Date__c != null 
              && (oldAsset == null || (oldAsset != null && a.Shipped_on_Date__c != oldAsset.Shipped_on_Date__c))) {

              assetIdSet.add(a.Id);
              potentialAssetsNeedingContract.add(a);
          }
        }
        
        // query asset for additional fields 
        // 05/05/2017 Query updated to include Customer_Account__c  (US-0002764) 
        Map<Id, Asset> assetMap = new Map<Id, Asset>([Select Id, Product2.Warranty_Coverage__c, Product2.Warranty_Coverage__r.Description, Customer_Account__c, 
        Product2.Warranty_Coverage__r.Term_months__c, Product2.Internal_Coverage__c, Product2.Internal_Coverage__r.Description, Product2.Internal_Coverage__r.Term_months__c, 
        Ownership__c, Order_Line_Item__c, Order_Line_Item__r.Quote_Line__c, Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__c, Owner_Account__r.Internal__c, Owner_Account__c,
        Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__r.CurrencyIsoCode, Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__r.SBQQ__PriceBook__c, Order_Line_Item__r.Order.Type, 
        (SELECT Id from ContractLineItems where SBQQSC__ProductName__c LIKE '%WARRANTY%' OR SBQQSC__ProductName__c LIKE '%Internal Coverage%')
                                                      From Asset 
                                                      Where Id IN: assetIdSet]); 

        System.debug('assetMap '+Json.serialize(assetMap));
        
        for(Asset a : potentialAssetsNeedingContract){

            Asset assetOtherVals = assetMap.get(a.Id);

              // 10-03-2017 Updates to only Create Warranties when Shipment Date and term length for coverage is greater than today. 

              if(assetOtherVals != null && a.Ownership__c == 'Customer Owned' && a.Order_Line_Item__r.Order.Type != 'Advanced Exchange') {

               coverageTerm = assetMap.get(a.Id).Product2.Warranty_Coverage__r.Term_months__c.intValue();
               endDate =  a.Shipped_on_Date__c.addMonths(coverageTerm);

               }

              if(assetOtherVals != null && a.Ownership__c == 'Hologic Owned' && a.Order_Line_Item__r.Order.Type != 'Advanced Exchange') { 

               coverageTerm = assetMap.get(a.Id).Product2.Internal_Coverage__r.Term_months__c.intValue();
               endDate =  a.Shipped_on_Date__c.addMonths(coverageTerm);

              }

             system.debug('assetOtherVals.Order_Line_Item__r.Order.Type = '  + assetOtherVals.Order_Line_Item__r.Order.Type);
 
            // Update of Logic to parse only Customer Owned Assets.  Required as Customer Owned requires the Warranty Coverage value on Product2 (US-0002764) 
            if(assetOtherVals != null && assetOtherVals.ContractLineItems.size() == 0 && assetOtherVals.Product2.Warranty_Coverage__c != null && 
                a.RecordTypeId == assetSystemRecordTypeId && a.Ownership__c == 'Customer Owned' && endDate > Today && 
                assetOtherVals.Order_Line_Item__r.Order.Type != 'Advanced Exchange'){

                assetsNeedServiceContract.put(a.Id, a);
                
                // get the order item's quote line
                if(String.isNotBlank(assetOtherVals.Order_Line_Item__r.Quote_Line__c)){
                    quoteLineIds.add(assetOtherVals.Order_Line_Item__r.Quote_Line__c);
                    
                    if(!quoteLineIdToAsset.containsKey(assetOtherVals.Order_Line_Item__r.Quote_Line__c)){
                        quoteLineIdToAsset.put(assetOtherVals.Order_Line_Item__r.Quote_Line__c, new Map<Id, Asset>());
                    }
                    quoteLineIdToAsset.get(assetOtherVals.Order_Line_Item__r.Quote_Line__c).put(a.Id, a);
                }
                
                // get the pricebooks from the order item's related quote
                if(String.isNotBlank(assetOtherVals.Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__r.SBQQ__PriceBook__c)){
                    priceBookIds.add(assetOtherVals.Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__r.SBQQ__PriceBook__c);
                }
                
                // get the warranty product from the asset's related product
                if(String.isNotBlank(assetOtherVals.Product2.Warranty_Coverage__c)){
                    warrantyProductIds.add(assetOtherVals.Product2.Warranty_Coverage__c);
                }
            }
            
            // End of Customer Owned evaluation (US-0002764) 
            // Update of Logic to parse only Hologic Owned Assets.  Required as Hologic Owned requires the Internal Coverage value on Product2 (US-0002764)
 
            if(assetOtherVals != null && assetOtherVals.ContractLineItems.size() == 0 && assetOtherVals.Product2.Internal_Coverage__c != null && 
               a.RecordTypeId == assetSystemRecordTypeId && a.Ownership__c == 'Hologic Owned' && endDate > Today && 
               assetOtherVals.Order_Line_Item__r.Order.Type != 'Advanced Exchange'){

                assetsNeedServiceContract.put(a.Id, a);
                
                // get the order item's quote line
                if(String.isNotBlank(assetOtherVals.Order_Line_Item__r.Quote_Line__c)){
                    quoteLineIds.add(assetOtherVals.Order_Line_Item__r.Quote_Line__c);
                    
                    if(!quoteLineIdToAsset.containsKey(assetOtherVals.Order_Line_Item__r.Quote_Line__c)){
                        quoteLineIdToAsset.put(assetOtherVals.Order_Line_Item__r.Quote_Line__c, new Map<Id, Asset>());
                    }
                    quoteLineIdToAsset.get(assetOtherVals.Order_Line_Item__r.Quote_Line__c).put(a.Id, a);
                }
                
                // get the pricebooks from the order item's related quote
                if(String.isNotBlank(assetOtherVals.Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__r.SBQQ__PriceBook__c)){
                    priceBookIds.add(assetOtherVals.Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__r.SBQQ__PriceBook__c);
                }
                
                // get the warranty product from the asset's related product
                if(String.isNotBlank(assetOtherVals.Product2.Internal_Coverage__c)){
                    warrantyProductIds.add(assetOtherVals.Product2.Internal_Coverage__c);
                }
            }
            // End of Hologic Owned evaluation (US-0002764) 
        }
        
        // grab the default Service Pricebook, this will be used on Warranty Contracts
        if(String.isNotBlank(orgDefaults.Service_Pricebook_USD__c)){
            priceBookIds.add(orgDefaults.Service_Pricebook_USD__c);
        }
        
        // query related quote lines
        List<SBQQ__QuoteLine__c> quoteLines = [Select Id, Covered_Asset__c, SBQQ__RequiredBy__c, POS_Quote_Line__c,
                                               SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__PriceBook__c,
                                               SBQQ__Product__c, SBQQ__Product__r.Description, SBQQ__Product__r.Term_months__c,
                                               SBQQ__Quote__r.SBQQ__EndDate__c, SBQQ__Quote__r.SBQQ__StartDate__c,SBQQ__DefaultSubscriptionTerm__c
                                               From SBQQ__QuoteLine__c
                                               Where SBQQ__Product__r.Service_Subscription__c = true
                                               And SBQQ__RequiredBy__c IN: quoteLineIds];
        
        for(SBQQ__QuoteLine__c ql : quoteLines){
            if(String.isNotBlank(ql.SBQQ__Quote__r.SBQQ__PriceBook__c)){
                priceBookIds.add(ql.SBQQ__Quote__r.SBQQ__PriceBook__c);
            }
            
            if(String.isNotBlank(ql.SBQQ__Product__c)){
                warrantyProductIds.add(ql.SBQQ__Product__c);
            }
        }

        System.debug('quoteLineIds '+Json.serialize(quoteLineIds));
        System.debug('quoteLineIdToAsset '+Json.serialize(quoteLineIdToAsset));
        
        // query related pricebook entries
        Map<Id, Map<Id, PricebookEntry>> productToPricebookToPricebookEntry = new Map<Id, Map<Id, PricebookEntry>>();
        for(PricebookEntry pbe : [Select Id, Pricebook2Id, Product2Id From PricebookEntry Where Pricebook2Id IN: priceBookIds And 
                                  Product2Id IN: warrantyProductIds And CurrencyISOCode =: UserInfo.getDefaultCurrency()]) {

            if(!productToPricebookToPricebookEntry.containsKey(pbe.Product2Id)){
                productToPricebookToPricebookEntry.put(pbe.Product2Id, new Map<Id, PricebookEntry>());
            }
            productToPricebookToPricebookEntry.get(pbe.Product2Id).put(pbe.Pricebook2Id, pbe);
        }

        System.debug('productToPricebookToPricebookEntry '+Json.serialize(productToPricebookToPricebookEntry));
        
        // create service contracts - warranty

        List<ServiceContract> serviceContracts = new List<ServiceContract>();
        List<ServiceContract> warrantyServiceContracts = new List<ServiceContract>();
        Map<Id, ServiceContract> assetIdToServiceContract = new Map<Id, ServiceContract>();

        for(Asset a : assetsNeedServiceContract.values()){
            Asset aOtherVals = assetMap.get(a.Id);
            Integer termLength = 0;
            Id contractAccount;
            // Update to have if statement to determine if Hologic Owned vs Customer Owned and therefore accordingly pull the correct Term in Months. 
            if(aOtherVals.Ownership__c == 'Customer Owned') 
            termLength = aOtherVals.Product2.Warranty_Coverage__r.Term_months__c != null ? (Integer)aOtherVals.Product2.Warranty_Coverage__r.Term_months__c : 0;
            if(aOtherVals.Ownership__c == 'Hologic Owned')  
            termLength = aOtherVals.Product2.Internal_Coverage__r.Term_months__c != null ? (Integer)aOtherVals.Product2.Internal_Coverage__r.Term_months__c : 0;
            // 05/26/2017      Raj Sharan   Update of Logic to address Hologic Owned Assets to create Service Contract with Account of Hologic Corporation (US-0002764) 
            if(aOtherVals.Ownership__c == 'Customer Owned') contractAccount = aOtherVals.Customer_Account__c;
            if(aOtherVals.Ownership__c == 'Hologic Owned')  contractAccount = aOtherVals.Owner_Account__c;
            ServiceContract sc = new ServiceContract(
                Name = 'Warranty Contract for SN: ' + a.SerialNumber
                , Description = 'Warranty Contract for SN: ' + a.SerialNumber
                , AccountId = contractAccount
                , ApprovalStatus = 'Draft'
                , CurrencyIsoCode = UserInfo.getDefaultCurrency() 
                , Pricebook2Id = orgDefaults.Service_Pricebook_USD__c
                , RecordTypeId = serviceContractServiceContractRecordTypeId
                , StartDate = a.Shipped_on_Date__c != null ? a.Shipped_on_Date__c : a.CreatedDate.date()
                , EndDate = a.Shipped_on_Date__c != null ? a.Shipped_on_Date__c.addMonths(termLength) : a.CreatedDate.date().addMonths(termLength)
            );
            
            assetIdToServiceContract.put(a.Id, sc);
            serviceContracts.add(sc);
            warrantyServiceContracts.add(sc);
        }
        System.debug('assetIdToServiceContract '+Json.serialize(assetIdToServiceContract));
        
        // create service contracts - extended warranty
        Map<Id, Map<Id, ServiceContract>> quoteLineIdToAssetIdToServiceContract = new Map<Id, Map<Id, ServiceContract>>();
        for(SBQQ__QuoteLine__c ql : quoteLines){
            quoteLineIdToAssetIdToServiceContract.put(ql.Id, new Map<Id, ServiceContract>());
            Map<Id, Asset> quoteAssets = quoteLineIdToAsset.containsKey(ql.SBQQ__RequiredBy__c) ? quoteLineIdToAsset.get(ql.SBQQ__RequiredBy__c) : new Map<Id, Asset>();
            Integer endDateAttr = Integer.valueOf(ql.SBQQ__DefaultSubscriptionTerm__c);
            system.debug('endDateAttr========'+endDateAttr);
            if(endDateAttr == null)
                endDateAttr = 0;
            for(Asset a : quoteAssets.values()){
                Asset aOtherVals = assetMap.get(a.Id);
                ServiceContract warrantyContract = assetIdToServiceContract.get(a.Id);
                system.debug('warrantyContract========'+warrantyContract);
                ServiceContract sc = new ServiceContract(
                    Name = 'Extended Warranty Contract for SN: ' + a.SerialNumber
                    , Description = 'Extended Warranty Contract for SN: ' + a.SerialNumber
                    , AccountId = a.Customer_Account__c
                    , ApprovalStatus = 'Draft'
                    , SBQQSC__Quote__c = aOtherVals.Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__c
                    , CurrencyIsoCode = aOtherVals.Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__r.CurrencyIsoCode
                    , Pricebook2Id = aOtherVals.Order_Line_Item__r.Quote_Line__r.SBQQ__Quote__r.SBQQ__PriceBook__c
                    , RecordTypeId = serviceContractServiceContractRecordTypeId
                    , StartDate = warrantyContract.EndDate.addDays(1)
                    , EndDate = (warrantyContract.EndDate.addMonths(endDateAttr))
                    //, EndDate = warrantyContract.EndDate.addDays(1 + ql.SBQQ__Quote__r.SBQQ__StartDate__c.daysBetween(ql.SBQQ__Quote__r.SBQQ__EndDate__c))
                    
                );
                system.debug('warrantyContract.EndDate.addDays(1)========'+warrantyContract.EndDate.addDays(1));
                system.debug('warrantyContract.EndDate.addMonths(endDateAttr)========'+warrantyContract.EndDate.addMonths(endDateAttr));
                quoteLineIdToAssetIdToServiceContract.get(ql.Id).put(a.Id, sc);
                serviceContracts.add(sc);
            }
        }
        System.debug('quoteLineIdToAssetIdToServiceContract '+Json.serialize(quoteLineIdToAssetIdToServiceContract));
        insert serviceContracts;
        System.debug('serviceContracts '+Json.serialize(serviceContracts));
        
        // create contract line items - warranty
        List<ContractLineItem> contractLineItems = new List<ContractLineItem>();
        Map<Id, ContractLineItem> assetIdToWntyContractlineItem = new Map<Id, ContractLineItem>();
        for(Asset a : assetsNeedServiceContract.values()){
            Asset aOtherVals = assetMap.get(a.Id);
            Integer termLength = 0;
            //Update with an if statement to determine if Hologic Owned vs Customer Owned and therefore accordingly used Warranty Coverage or 
            //Internal Coverage to determine Term Months. (US-0002764)
            
            if(aOtherVals.Ownership__c == 'Customer Owned') 
              termLength = aOtherVals.Product2.Warranty_Coverage__r.Term_months__c != null ? (Integer)aOtherVals.Product2.Warranty_Coverage__r.Term_months__c : 0;
            if(aOtherVals.Ownership__c == 'Hologic Owned')  
              termLength = aOtherVals.Product2.Internal_Coverage__r.Term_months__c != null ? (Integer)aOtherVals.Product2.Internal_Coverage__r.Term_months__c : 0;
            ServiceContract serviceContract = assetIdToServiceContract.get(a.Id);
            //TODO: Get PBE for product under the service pricebook
            PricebookEntry pbe;
            
            // Update with an if statement to determine if Hologic Owned vs Customer Owned and therefore accordingly get the correct PricebookEntry Value (US-0002764)  
            
            if(aOtherVals.Ownership__c == 'Customer Owned') pbe = productToPricebookToPricebookEntry.containsKey(aOtherVals.Product2.Warranty_Coverage__c) && 
                productToPricebookToPricebookEntry.get(aOtherVals.Product2.Warranty_Coverage__c).containsKey(orgDefaults.Service_Pricebook_USD__c) ?
                productToPricebookToPricebookEntry.get(aOtherVals.Product2.Warranty_Coverage__c).get(orgDefaults.Service_Pricebook_USD__c) : new PricebookEntry();
            
            if(aOtherVals.Ownership__c == 'Hologic Owned') pbe = productToPricebookToPricebookEntry.containsKey(aOtherVals.Product2.Internal_Coverage__c) && 
                productToPricebookToPricebookEntry.get(aOtherVals.Product2.Internal_Coverage__c).containsKey(orgDefaults.Service_Pricebook_USD__c) ?
                productToPricebookToPricebookEntry.get(aOtherVals.Product2.Internal_Coverage__c).get(orgDefaults.Service_Pricebook_USD__c) : new PricebookEntry();
            
            
            //Update with an if statement to determine if Hologic Owned vs Customer Owned and therefore accordingly update description based 
            //   on Warranty Coverage or Internal Coverage. (US-0002764)
            
            String CoverageDescription;            
            if(aOtherVals.Ownership__c == 'Customer Owned')   CoverageDescription = aOtherVals.Product2.Warranty_Coverage__r.Description; 
            if(aOtherVals.Ownership__c == 'Hologic Owned')    CoverageDescription = aOtherVals.Product2.Internal_Coverage__r.Description; 
            
            ContractLineItem cli = new ContractLineItem(
                ServiceContractId = serviceContract.Id,
                AssetId = a.Id,
                PricebookEntryId = pbe.Id, 
                Description = CoverageDescription,
                StartDate = a.Shipped_on_Date__c != null ? a.Shipped_on_Date__c : a.CreatedDate.date(),
                EndDate = a.Shipped_on_Date__c != null ? a.Shipped_on_Date__c.addMonths(termLength) : a.CreatedDate.date().addMonths(termLength),
                Quantity = 1, 
                UnitPrice = 0,
                Asset_Created__c = true
            );
            
            assetIdToWntyContractlineItem.put(a.Id, cli);
            contractLineItems.add(cli);
        }
        System.debug('assetIdToWntyContractlineItem '+Json.serialize(assetIdToWntyContractlineItem));
        
        // create contract line items - extended warranty
        List<ContractLineItem> extWntyContractLineItem = new List<ContractLineItem>();
        for(SBQQ__QuoteLine__c ql : quoteLines){
            Map<Id, Asset> quoteAssets = quoteLineIdToAsset.containsKey(ql.SBQQ__RequiredBy__c) ? quoteLineIdToAsset.get(ql.SBQQ__RequiredBy__c) : new Map<Id, Asset>();
            Integer endDateAttr = Integer.valueOf(ql.SBQQ__DefaultSubscriptionTerm__c);
            if(endDateAttr == null)
                endDateAttr = 0; 
            for(Asset a : quoteAssets.values()){
                Asset aOtherVals = assetMap.get(a.Id);
                ServiceContract serviceContract = quoteLineIdToAssetIdToServiceContract.get(ql.Id).get(a.Id);
                ContractLineItem parentCLI = assetIdToWntyContractlineItem.get(a.Id);
                PricebookEntry pbe = productToPricebookToPricebookEntry.containsKey(ql.SBQQ__Product__c) && 
                    productToPricebookToPricebookEntry.get(ql.SBQQ__Product__c).containsKey(ql.SBQQ__Quote__r.SBQQ__PriceBook__c) ?
                    productToPricebookToPricebookEntry.get(ql.SBQQ__Product__c).get(ql.SBQQ__Quote__r.SBQQ__PriceBook__c) : new PricebookEntry();
                
                ContractLineItem cli = new ContractLineItem(
                    ServiceContractId = serviceContract.Id
                    , AssetId = a.Id
                    , PricebookEntryId = pbe.Id
                    , Description = ql.SBQQ__Product__r.Description
                    , StartDate = parentCLI.EndDate.addDays(1)
                    , EndDate = (parentCLI.EndDate.addMonths(endDateAttr))
                    //, EndDate = parentCLI.EndDate.addDays(1 + ql.SBQQ__Quote__r.SBQQ__StartDate__c.daysBetween(ql.SBQQ__Quote__r.SBQQ__EndDate__c))
                    , Quantity = 1
                    , UnitPrice = 0
                    , Asset_Created__c = true
                );
                
                extWntyContractLineItem.add(cli);
                contractLineItems.add(cli);
                System.debug('Service Type:'+cli.Service_Type__c);
            }
        }
        System.debug('extWntyContractLineItem '+Json.serialize(extWntyContractLineItem));
        insert contractLineItems;
        System.debug('contractLineItems '+Json.serialize(contractLineItems));
        
        
        // after inserting contract lines - set Warranty Service Contracts to Activated
        for(ServiceContract sc :  warrantyServiceContracts){
            sc.ApprovalStatus = 'Activated';
        }
        update warrantyServiceContracts;
    }
*/
    /*------------------------------------------------------------
Author:         John Christy
Company:        AppsAssociates
Description:    Address Advance Exchange of Asset
Inputs:         assets - The list of Assets to modify
oldAssets Map of assets containing old values
Returns:        N/A

History:
<Date>          <Authors Name>      <Brief Description of Change>
08/25/2017      John Christy        Update for Advance Exchange Warranty Creation US-0002764
08/25/2017      Raj Sharan          Update for Advance Exchange Warranty Creation US-0002764
------------------------------------------------------------*/
    /*
    public static void setAdvancedExchange(List<Asset> assets, Map<Id, Asset> oldAssets){


        Date Today = System.Today();

        List<Asset> potentialAssetsAdvanceExchange = new List<Asset>();
        List<ContractLineItem> insertedContractLines = new List<ContractLineItem>();
        List<Id> potentialExchangeAssetIds = new List<Id>();
        List<Id> returnedAssetsIds = new List<Id>();
        Set<Id> returnedAssetsIdSet = new Set<Id>();
        Set<Id> returnedAssetAccSet = new Set<Id>();
        Map<Id, Asset> assetAdvanceExchangeMap = new Map<Id, Asset>();
        Map<Id, Id> correspondingAssetExchangeOldNewMap = new Map<Id, Id>();

        for(Asset a : assets){

            Asset oldAsset = oldAssets != null && oldAssets.containsKey(a.Id) ? oldAssets.get(a.Id) : null;

            system.debug('Current Asset = ' + a);           
            system.debug('oldAsset = ' + oldAsset);           
 
            // find assets that potentially are Advance Exchange 
            if((a.Order_Line_Item__c != null && oldAsset == null) || 
              (oldAsset != null && oldAsset.Order_Line_Item__c != a.Order_Line_Item__c && a.Order_Line_Item__c != NULL)) {

                potentialAssetsAdvanceExchange.add(a);
                potentialExchangeAssetIds.add(a.Id);
            }
            
        }
       
       if(potentialExchangeAssetIds.size() > 0) {

       System.debug('potentialAssetsAdvanceExchange = ' + potentialAssetsAdvanceExchange);

        Map<Id, Asset> assetsPotentiaExchangelMap = new Map<Id, Asset>(
            [SELECT Id, Name, Order_Line_Item__r.Order.Type, Order_Line_Item__r.Line_Type__c, Order_Line_Item__r.Returned_Asset__c, Order_Line_Item__c, 
             Shipped_on_Date__c, Order_Line_Item__r.Returned_Asset__r.Id
             FROM Asset
             WHERE Id in :potentialExchangeAssetIds]);

       System.debug('assetsPotentiaExchangelMap = ' + assetsPotentiaExchangelMap);

        for(Asset a1 : potentialAssetsAdvanceExchange){
            
            if(assetsPotentiaExchangelMap.get(a1.Id).Order_Line_Item__r.Order.Type == 'Advanced Exchange'){

            returnedAssetsIds.add(assetsPotentiaExchangelMap.get(a1.Id).Order_Line_Item__r.Returned_Asset__c);
            returnedAssetsIdSet.add(assetsPotentiaExchangelMap.get(a1.Id).Order_Line_Item__r.Returned_Asset__c);
            returnedAssetAccSet.add(assetsPotentiaExchangelMap.get(a1.Id).Order_Line_Item__r.Returned_Asset__r.Id);
            assetAdvanceExchangeMap.put(a1.Id, a1);
            correspondingAssetExchangeOldNewMap.put(assetsPotentiaExchangelMap.get(a1.Id).Order_Line_Item__r.Returned_Asset__c, a1.Id); 

            System.debug('RMA Asset: ' + assetsPotentiaExchangelMap.get(a1.Id).Order_Line_Item__r.Returned_Asset__c);
                        
           }
         }
        SYSTEM.DEBUG('returnedAssetsIds'+returnedAssetsIds);
          
        
        Map<Id, ContractLineItem> contractLinesToCloneMap = new Map<Id, ContractLineItem>(
            [SELECT Asset_Created__c, Asset_Product_Description__c, AssetId, Contract_Activated__c, Covered_Asset__c, 
             Description, Discount, EndDate, Id, PricebookEntryId, Quantity, SBQQSC__Bundle__c, 
             SBQQSC__Bundled__c, SBQQSC__ComponentDiscountedByPackage__c, SBQQSC__ContractNumber__c, 
             SBQQSC__PricingMethod__c, SBQQSC__ProrateMultiplier__c, SBQQSC__Quantity__c, SBQQSC__QuoteLine__c, 
             Service_Type__c, ServiceContractId, StartDate, Suppress_Credit__c, Type__c, UnitPrice   
             FROM ContractLineItem 
             WHERE AssetId IN :returnedAssetsIds AND ((Status = 'Active' OR Status = 'Inactive') AND EndDate > Today)]);

       System.debug('contractLinesToCloneMap = ' + contractLinesToCloneMap);

 
       Map<Id,Service_Billing_Schedule__c> billingScheduleToCloneMap = new Map<Id, Service_Billing_Schedule__c>( 
            [SELECT Id, Contract_Line_Item__c, Contract_Line_Item__r.AssetId, Contract_Line_Item__r.Asset.Shipped_on_Date__c, Name, 
             Sequence__c, Number_of_Periods__c, Period__c, Amount__c, End_Date__c, Start_Date__c 
             FROM Service_Billing_Schedule__c 
             WHERE Contract_Line_Item__r.Asset.Id IN :returnedAssetsIds]);

       System.debug('billingScheduleToCloneMap = ' + billingScheduleToCloneMap);
       System.debug('contractLinesToCloneMap = ' + contractLinesToCloneMap);

       if(!contractLinesToCloneMap.isEmpty() && !correspondingAssetExchangeOldNewMap.isEmpty() && !assetAdvanceExchangeMap.isEmpty())
       insertedContractLines = ServiceContractUtility.copyContractLines(contractLinesToCloneMap, correspondingAssetExchangeOldNewMap, assetAdvanceExchangeMap);

       system.debug('insertedContractLines = ' + insertedContractLines);
       
       system.debug('Call Billing Schedule = ' + (!billingScheduleToCloneMap.isEmpty() && insertedContractLines.size() > 0 && !correspondingAssetExchangeOldNewMap.isEmpty() && 
          !assetAdvanceExchangeMap.isEmpty() && !contractLinesToCloneMap.isEmpty()));

       if(!billingScheduleToCloneMap.isEmpty() && insertedContractLines.size() > 0 && !correspondingAssetExchangeOldNewMap.isEmpty() && 
          !assetAdvanceExchangeMap.isEmpty() && !contractLinesToCloneMap.isEmpty() )
       ServiceContractUtility.createBillingSchedule(billingScheduleToCloneMap, insertedContractLines, correspondingAssetExchangeOldNewMap, 
                                                    assetAdvanceExchangeMap, contractLinesToCloneMap);

       if(!contractLinesToCloneMap.isEmpty() && !correspondingAssetExchangeOldNewMap.isEmpty() && !assetAdvanceExchangeMap.isEmpty())
       ServiceContractUtility.cancelContractLines(contractLinesToCloneMap, correspondingAssetExchangeOldNewMap, assetAdvanceExchangeMap);

       if(returnedAssetsIds.size() > 0 && !correspondingAssetExchangeOldNewMap.isEmpty() && !assetAdvanceExchangeMap.isEmpty())
       ServiceContractUtility.cancelEntitlements(returnedAssetsIds, correspondingAssetExchangeOldNewMap, assetAdvanceExchangeMap, returnedAssetsIdSet, returnedAssetAccSet);

       if(returnedAssetsIds.size() > 0 && !correspondingAssetExchangeOldNewMap.isEmpty() && !assetAdvanceExchangeMap.isEmpty())
       ServiceContractUtility.cancelPreventiveMaintenancePlans(returnedAssetsIds, correspondingAssetExchangeOldNewMap, assetAdvanceExchangeMap);

       if(!billingScheduleToCloneMap.isEmpty() && !correspondingAssetExchangeOldNewMap.isEmpty() && !assetAdvanceExchangeMap.isEmpty())
       ServiceContractUtility.cancelBillingSchedules(billingScheduleToCloneMap, correspondingAssetExchangeOldNewMap, assetAdvanceExchangeMap);
                      
      }
    }
  */
    /*------------------------------------------------------------
    Author:         Raviraj Reddy
    Company:        Cynosure
    Description:    Method to initate the AMPS Merchant Track
    Inputs:         assets - The list of Assets to modify
    oldAssets Map of assets containing old values
    Returns:        N/A

    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/22/2018      Raviraj Reddy        Initial Creation (US3819)
    ------------------------------------------------------------*/
    /*public static void createInitiatingTasks(Map<ID,Asset> newAssetMap, Map<Id, Asset> oldAssets){
        Map<String, AMPS_Marketing_Activity_Flow__c> flowMap = new Map<String, AMPS_Marketing_Activity_Flow__c>();
        Set<ID> updatedAssets = new Set<ID>();
        for(AMPS_Marketing_Activity_Flow__c objTaskFlow : [ Select Id,Name,Number_of_days_to_be_added__c,
                                                                    AMPS_Track__c,
                                                                    Next_Task__c,Next_Task__r.Name,
                                                                    Cross_object_Asset_Team__c,
                                                                    Sub_Task__c,Sub_Task__r.Name,                                                                    
                                                                    Parent_Task__c,Parent_Task__r.Name,
                                                                    Initiating_Task_Type__c,
                                                                    Type__c,
                                                                    Priority__c 
                                                                    From AMPS_Marketing_Activity_Flow__c
                                                                    WHERE Name != NULL AND Initiating_Task_Type__c != NULL])
            {   
                flowMap.put(objTaskFlow.Initiating_Task_Type__c , objTaskFlow);
            }
        
        System.debug('flowMap:'+flowMap);
        
        Map<ID,Asset_Team__c> assetTeamMap = new Map<ID,Asset_Team__c>();
        
        for(Asset asst: newAssetMap.values()){
            if(asst.AMPS_Track__c != null && asst.AMPS_Track__c != oldAssets.get(asst.id).AMPS_Track__c){
                updatedAssets.add(asst.ID);        
            
            }
        }
        
        System.debug('updatedAssets:'+updatedAssets);
        
        if(!updatedAssets.isEmpty()){
            for(Asset_Team__c team : [select id,Active_User__c,Asset__c,Relationship__c,User__c from Asset_Team__c where Relationship__c ='AMPS Representative' AND Asset__c IN:updatedAssets]){
                assetTeamMap.put(team.Asset__c,team);
            }
            
            List<Task> initialTasks = new List<Task>();
            
            for(ID asstID: updatedAssets){
                Asset asst = newAssetMap.get(asstID);
                if(asst.AMPS_Track__c != null && asst.AMPS_Track__c != oldAssets.get(asst.id).AMPS_Track__c && assetTeamMap.containsKey(asst.id) && flowMap.containsKey(asst.AMPS_Track__c)){
                    Task tsk = new Task();
                    tsk.Priority  = 'Normal';
                    tsk.Status = 'Not Started';
                    tsk.OwnerId = assetTeamMap.get(asst.id).User__c ;
                    Decimal intNumberDays = flowMap.get(asst.AMPS_Track__c).Number_of_days_to_be_added__c;        
                    tsk.ActivityDate = intNumberDays != NULL ? Date.Today().addDays(intNumberDays.intValue()) : NULL;
                    tsk.Subject = flowMap.get(asst.AMPS_Track__c).Name;
                    tsk.WhatID = asst.ID;
                    initialTasks.add(tsk);
                }
            }
            
            System.debug('initialTasks:'+initialTasks);
            
            if(!initialTasks.isEmpty()) insert initialTasks;
        
        }

    }
    */
/*------------------------------------------------------------
Author:         Chris Jongbloed
Company:        AppsAssociates
Description:    Create and/or Update an Account_Product_Family__c record to reflect what Product Families are owned by the Account
Inputs:         assets - The list of Assets to modify
oldAssets Map of assets containing old values
Returns:        N/A

History:
<Date>          <Authors Name>      <Brief Description of Change>
04/02/2018      Chris Jongbloed     Initial Creation
04/19/2018      Dave Mansell        Rewritten to clean up and add functionality
------------------------------------------------------------*/

    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Updates AccountProductFamily records when an asset is updated
    Inputs:             List of records, Map of old records
    Returns:            N/A
    Test Class(es):     AssetTriggerActions_Test.testUpdateAccountProductFamily
    ------------------------------------------------------------*/
    /*public static void updateAccountProductFamily (List<Asset> assets, Map<Id, Asset> oldAssets){
        //Prep custom setting map
        Map<String, String> familyToFieldMap = new Map<String, String>();
        for(Account_Product_Family_Settings__c apfs : Account_Product_Family_Settings__c.getall().values()){
            familyToFieldMap.put(apfs.Name, apfs.Product_Family_Field__c);
        }
        
        //Loop through assets and get account Ids
        Set<Id> accIds = new Set<Id>();
        for(Asset asst : assets){
            accIds.add(asst.AccountId);
        }
        
        //Query for accounts
        Map<Id, Account> accsById = new Map<Id, Account>([
            SELECT Id
                  ,Account_Product_Family__c
              FROM Account
             WHERE Id IN :accIds
        ]);
        
        //Query for assets counts and map by Account Id
        Map<Id, Map<String, Integer>> assetCountsByAccId = new Map<Id, Map<String, Integer>>();
        for(AggregateResult res : [
            SELECT AccountId accId
                  ,Product2.Family family
                  ,Count(Id) qty
              FROM Asset
             WHERE AccountId IN :accIds
               AND Product2.Family != null
             GROUP BY AccountId, Product2.Family
            ]){
            Id accId = (Id)res.get('accId');
            Map<String, Integer> assetMap = assetCountsByAccId.get(accId);
            if(assetMap == null){
                assetMap = new Map<String, Integer>();
            }
            assetMap.put((String)res.get('family'), (Integer)res.get('qty'));
            assetCountsByAccId.put(accId, assetMap);
        }
        
        //Loop through accounts and update APFs for each
        Map<Id, Account_Product_Family__c> apfsToUpsertByAccId = new Map<Id, Account_Product_Family__c>();
        for(Account acc : accsById.values()){
            //Create new temp APF
            Account_Product_Family__c apf = new Account_Product_Family__c();
            if(acc.Account_Product_Family__c != null){
                apf.Id = acc.Account_Product_Family__c;
            }
            apf.Account__c = acc.Id;
            
            //Reset all to 0
            for(String fieldName : familyToFieldMap.values()){
                apf.put(fieldName, 0);
            }
            
            Map<String, Integer> assetMap = assetCountsByAccId.get(acc.Id);
            if(assetMap != null){
                for(String familyName : assetMap.keySet()){
                    String fieldName = familyToFieldMap.get(familyName);
                    if(fieldName != null){
                        apf.put(fieldName, (Decimal)assetMap.get(familyName));
                    }
                }
            }
            
            apfsToUpsertByAccId.put(acc.Id, apf);
        }
        
        //Upsert AFPs
        upsert apfsToUpsertByAccId.values();
        
        //Loop back through Accounts and update their field values
        List<Account> accsToUpdate = new List<Account>();
        for(Account acc : accsById.values()){
            if(acc.Account_Product_Family__c == null){
                acc.Account_Product_Family__c = apfsToUpsertByAccId.get(acc.Id).Id;
                accsToUpdate.add(acc);
            }
        }
        
        //Update accounts with new APF values
        update accsToUpdate;
    }
 
    public static void updateRelatedWorkOrders(List<Asset> assets, Map<Id, Asset> oldMap){
        //Filter assets
        List<Asset> validAssets = new List<Asset>();
        for(Asset asst : assets){
            Asset old = oldMap.get(asst.Id);
            if(asst.Order_Line_Item__c != null && asst.Order_Line_Item__c != old.Order_Line_Item__c){
                validAssets.add(asst);
            }
        }
        
        if(validAssets.size() > 0){
            updateRelatedWorkOrders(validAssets);
        }
    }
    
    public static void updateRelatedWorkOrders(List<Asset> assets){
        //Filter assets
        List<Asset> validAssets = new List<Asset>();
        for(Asset asst : assets){
            if(asst.Order_Line_Item__c != null){
                validAssets.add(asst);
            }
        }
        
        if(validAssets.isEmpty()){
            return;
        }
        
        Map<Id, OrderItem> oisById = new Map<Id, OrderItem>([
            SELECT Id
                  ,(SELECT Id
                          ,AssetId
                      FROM Work_Orders__r
                     WHERE AssetId = null
                   )
              FROM OrderItem
             WHERE Id IN (
                SELECT Order_Line_Item__c
                  FROM Asset
                 WHERE Id IN :validAssets
                   AND RecordType.DeveloperName = 'System'
             )
        ]);
        
        List<WorkOrder> wosToUpdate = new List<WorkOrder>();
        for(Asset asst : validAssets){
            if(asst.Order_Line_Item__c != null){
                OrderItem oi = oisById.get(asst.Order_Line_Item__c);
                if(oi != null && oi.Work_Orders__r != null && asst.RecordTypeId == GlobalUtility.getRecordTypeId('Asset', 'System')){
                    for(WorkOrder wo : oi.Work_Orders__r){
                        if(wo.AssetId == null){
                            wo.AssetId = asst.Id;
                            wosToUpdate.add(wo);
                        }
                    }
                }
            }
        }
        update wosToUpdate;
    }
    */
//}