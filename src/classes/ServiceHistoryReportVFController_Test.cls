/***************************************************************************************
    Author : Niraj
    Company : Hexaware Technologies
    Description : Test Class for ServiceHistoryReportVFController 

    History:
    <Date>         <Author Name>            <Brief Description of Change>     <Copa.do US#>
    24/09/2018      Niraj                   Initial Creation                   US-0005791
*******************************************************************************************/
@isTest 
public class ServiceHistoryReportVFController_Test {
    private static Account customerAccount;
    private static Account siteAccount;
    private static Product_Source_Division__c psd;
    private static Product2 prod;
    private static List<Product2> products = new List<Product2>();
    private static List<Asset> assets = new List<Asset>();
    private static Asset a1;
    private static Contact cont;
    private static User u;
    
    static testMethod void TestServiceReportVFController() {
         TestUtility.setupConfigurationSettings();
        
        customerAccount = TestUtility.newAccount('Customer Account', 'testCust', null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert customerAccount;
        
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', customerAccount.Id,GlobalUtility.getRecordTypeId('Account', 'Site'));
        insert siteAccount;
        
        System.debug('siteAccount: ' + siteAccount);
        
        cont = new Contact();
        cont.FirstName='Test';
        cont.LastName='Test';
        cont.Accountid= siteAccount.id;
        database.insert(cont);
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('1234','MAMMOGRAPHY');
        psd.Sunshine_Act__c =true;
        Insert psd;
        system.debug('psd===='+psd);
        Product_Source_Division__c psd1 = TestUtility.newProductSourceDivision('12345','MOLECULAR');
        Insert psd1;
        
        Product2 prod = TestUtility.newProduct('Prodrec');
        insert prod;
        for(Integer i = 0; i < 1; i++){
            products.add(TestUtility.newProduct('Product '+i));
            products[i].Product_Source_Division__c = psd.id;
            products[i].Replacement_Part__c = prod.id;
            products[i].Community_Visible__c = true;
        }
        insert products;
        
        for(Product2 p : products){
            a1=TestUtility.newAsset(siteAccount.Name + ' Asset ' + p.Name, siteAccount.Id, customerAccount.Id,p.Id);
            a1.ContactId= cont.Id;
            a1.RecordTypeId = GlobalUtility.getRecordTypeId('Asset','System');
            assets.add(a1);
            
        }
        insert assets;
        
         //Customer Community Plus Login User - Custom
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Plus Login User - Custom']; 
        u = new User(Alias = 'hotest', Email='hotest@test.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='hotest@test.com', ContactId=cont.Id);
        database.insert(u);
        
          System.runAs (u) 
        { 
           test.startTest();
           ServiceReportController.Master mas = new ServiceReportController.Master();
           ServiceReportController.MasterResult m = new ServiceReportController.MasterResult();
           m = ServiceReportController.GetAssetData(siteAccount.id,'Site','');
           mas.accountAddress = siteAccount.BillingStreet;
           mas.assetWrapper  = m.mas.assetWrapper;
             
           System.debug('mas.assetWrapper: ' + mas.assetWrapper );
           String masJSON = System.JSON.serialize(mas);
           
           System.debug('masJSON:' + masJSON );
           ServiceHistoryReportVFController srVFCont = new ServiceHistoryReportVFController();
            
           System.JSONGenerator jsGen = JSON.createGenerator(true);
           jsGen.writeStartObject();
           jsGen.writeStringField('finalassetdata', masJSON);
           jsGen.writeEndObject();
           String dataToSend = jsGen.getAsString();
            
          // String dataToSend = '{ \"finalassetdata\" : ' +  masJSON + '}';
           System.debug('dataToSend:' + dataToSend );
           srVFCont.PDFData = dataToSend;
           PageReference pgRef = srVFCont.downloadPDF();
           System.debug (pgRef.getUrl());
            
           System.assertEquals('/apex/ServiceHistoryReportPDF',pgRef.getUrl());
            
           test.stopTest();
        }
        
        
        
        
    }

}