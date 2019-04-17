@isTest
private class AssetAttributesUpdateController_Test {
    public static Configuration_Settings__c orgDefaults;
    public static Id accountCustomerRecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Customer');
    public static Asset asset1;
    private static Account siteAccount;
    private static Account custAccount;
    public static Contact Con;
    public static List<Account> customerAccounts = new List<Account>();
    public static Map<Id, Account> customerAccountMap = new Map<Id, Account>();
    public static Map<Id, Id> customerAccountToSiteAccount = new Map<Id, Id>();
    public static Map<Id, Site_Location__c> primarySiteLocationMap = new Map<Id, Site_Location__c>();
    public static Map<Id, Site_Location__c> secondarySiteLocationMap = new Map<Id, Site_Location__c>();
    public static List<Site_Location__c> primaryLocations = new List<Site_Location__c>();
    public static List<Site_Location__c> secondaryLocations = new List<Site_Location__c>();
    public static AssetAttributesUpdateController testController = new AssetAttributesUpdateController();
    
    static{
        orgDefaults = TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('sitelocTrigger');
        // setup an account
        custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        custAccount.BillingCountryCode = 'US';
        custAccount.BillingStateCode = 'NY';        
        insert new List<Account>{custAccount};
            
            for(Integer i = 0; i <2 ; i++){
                customerAccounts.add(TestUtility.newAccount('CustAccount-'+i, 'custParty'+i, null, null, accountCustomerRecordTypeId));
            }
        insert customerAccounts;
        
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', customerAccounts[0].Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';
        insert siteAccount;
        
        Con = TestUtility.newContact('Firstname ','Lastname ', customerAccounts[1].id);
        insert con;
        
        for(Account a : customerAccounts){
            customerAccountMap.put(a.Id, a);
        }       
        
        for(Account a : customerAccounts){
            primaryLocations.add(TestUtility.newSiteLocation('123 A Street Suite 1', '123 A Street', 'Suite 1', null, null,
                                                             'Some City', 'MA', '11111', 'US',
                                                             a.Oracle_Party_Id__c, a.Id, true));
            
            secondaryLocations.add(TestUtility.newSiteLocation('125 A Street Suite 2', '125 A Street', 'Suite 2', null, null,
                                                               'Some City', 'MA', '11111', 'US',
                                                               a.Oracle_Party_Id__c, a.Id, true));
        }
        List<Site_Location__c> temp = new List<Site_Location__c>();
        temp.addAll(primaryLocations);
        temp.addAll(secondaryLocations);
        insert temp;
        
        for(Site_Location__c l : [Select Id, Account__c, Account__r.ParentId From Site_Location__c Where Id IN: primaryLocations]){
            primarySiteLocationMap.put(l.Id, l);
            customerAccountToSiteAccount.put(l.Account__r.ParentId, l.Account__c);
        }
        
        for(Site_Location__c l : [Select Id, Account__c, Account__r.ParentId From Site_Location__c Where Id IN: secondaryLocations]){
            secondarySiteLocationMap.put(l.Id, l);
        }
        
        // setup asset
        List<Asset> assets = new List<Asset>();
        List<Asset> insertassets = new List<Asset>();
        
        for(Integer i = 0; i < customerAccounts.size(); i++){
            insertassets.add(TestUtility.newAsset(customerAccounts[i].Oracle_Party_Id__c, primaryLocations[i].Id, 'Asset-'+i));
        }
        for(asset a : insertassets){
            a.Accountid=customerAccounts[0].id;
            a.Contactid=Con.id;
            a.status = 'Return';
            a.SerialNumber = '123456' + insertassets.iterator();
            assets.add(a);
        }
        
        insert assets;
        
        // setup asset attributes
        asset1 = assets[0];
        Asset_Attribute__c testAssetAttribute = new Asset_Attribute__c();
        testAssetAttribute.Asset__c = asset1.Id;
        testAssetAttribute.Category__c = 'System4';
        testAssetAttribute.Name = 'Operating System';
        testAssetAttribute.Value__c = 'DOS';
        insert testAssetAttribute;
    }
    
    @isTest
    public static void testAssetAttribute(){
        // test based on asset id
        testController.idURL = asset1.Id;
        testController.getAsset();
        testController.getAssetAttributes();
        testController.save();
        
        // test based on asset serial number
        testController.idURL = null;
        testController.serialNumber = asset1.SerialNumber;
        testController.getAsset();
        testController.getAssetAttributes();	
        testController.save();
        
        // test based on null values
        testController.idURL = null;
        testController.serialNumber = null;
        testController.getAsset();
        testController.getAssetAttributes();
    }
}