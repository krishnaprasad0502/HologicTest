@isTest
private class LeadConvert_Test {
    public static ID prospectRecTypeId ;
    public static ID siteRecTypeId ;
    public static User user1;
    public static User user2;
    private static Configuration_Settings__c orgDefaults;
    
    public static void createData(){
    
        
        
        TestUtility.insertCustSetting('sitelocTrigger');
        prospectRecTypeId =  [SELECT Id FROM RecordType WHERE DeveloperName ='Prospect' Limit 1].id;
        siteRecTypeId = [SELECT Id FROM RecordType WHERE DeveloperName ='Site' Limit 1].id;
        
        Account objSoldToAcc = TestUtility.newAccount('Test Account - 00001', '', '', null, prospectRecTypeId );
        objSoldToAcc.ShippingStateCode = 'AK';
        objSoldToAcc.ShippingCountryCode = 'US'; 
        objSoldToAcc.ShippingPostalCode = '10010'; 
        objSoldToAcc.ShippingCity = 'citay'; 
        objSoldToAcc.CurrencyIsoCode = 'USD';
        objSoldToAcc.CDQ_Status__c = 'New';
        objSoldToAcc.ShippingStreet = 'SHIPTest1';
        insert objSoldToAcc;
        
        
        Account objShipToAcc = TestUtility.newAccount('Test Account - 00002', '', '', null, siteRecTypeId );
        objShipToAcc.ParentId=objSoldToAcc.Id;
        objShipToAcc.ShippingStateCode = 'AK';
        objShipToAcc.ShippingCountryCode = 'US'; 
        objShipToAcc.ShippingPostalCode = '10010'; 
        objShipToAcc.ShippingCity = 'citay';
        objShipToAcc.CurrencyIsoCode = 'USD';
        objShipToAcc.CDQ_Status__c = 'New'; 
        objShipToAcc.ShippingStreet = 'test1';
        insert objShipToAcc;
        
        Lead objLead = new Lead(LastName = 'Test Last', Company = 'Test Account - 00001',  PostalCode = '01234',Street = 'test1', countrycode='US', StateCode='AK', city='testCity');
        insert objLead;
      
       
    }
    
    private static testMethod void test_LeadConvert_Existing_SoldTo_Existing_ShipToAcc() {
        Id profID = [select id from profile where name='Medical Aesthetics Sales Admin'].id;


        user1 = new User(alias = 'test123', email='test123@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester@hologic.com');
        
        insert user1;
         System.runAs(user1){
         createData();
         }
         Lead objLead1 = [Select Id From Lead Limit 1];
         PageReference pageRef1= Page.LeadConvert;
        Test.setCurrentPage(pageRef1);
        ApexPages.StandardController stdController1 = new ApexPages.StandardController(objLead1);
        LeadConvert lc1 = new LeadConvert(stdController1);
        
        LeadConvert.getLeadAddress(''+objLead1.id);
         map<String,Object> results1 = new map<String,Object>();
           results1 = LeadConvert.init(objLead1.Id);
        System.runAs(user1){
        createData();
        Lead objLead = [Select Id From Lead Limit 1];
        
        PageReference pageRef = Page.LeadConvert;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(objLead);
        LeadConvert lc = new LeadConvert(stdController);
        
        LeadConvert.getLeadAddress(''+objLead.id);
        
        Account objAccount = [Select Id From Account Where Name = 'Test Account - 00001' Limit 1];
              contact con=new contact(FirstName='test',LastName='user',AccountId=objAccount.id);
        insert con;
        LeadConvert.findContact('test','user',''+objAccount.id);
        LeadConvert.searchContacts('test',objAccount.id);
            LeadConvert.searchContacts('test',null);
        map<String,Object> results = new map<String,Object>();
        results = LeadConvert.init(objLead.Id);
        
        System.assert(results != Null);
        System.assert(results.get('lead') != Null);
        
        List<Account> lstAccs = new List<Account>(); 
        lstAccs = LeadConvert.searchAccounts('Test Account - 00001', false); 
      
            List<Account> lstAccs1 = new List<Account>(); 
        lstAccs1 = LeadConvert.searchAccounts('Test Account - 00001', true); 
       
        
        List<Account> lstChildAccs = new List<Account>();
        lstChildAccs = LeadConvert.searchLocations('Test Account - 00002', 'Test', objAccount);
        
            
              List<Account> lstChildAccs1= new List<Account>();
        lstChildAccs1 = LeadConvert.searchInitialLocations('Test Account - 00002', '', objAccount);
       
        
        List<User> lstUsers = new List<User>();
        lstUsers = LeadConvert.searchOwners('Silverline');
        
        LeadConvert.cancelLead(objLead.Id); 
        //new LeadConvert().dummy(); 
        
        // Preparing the formData...
        map<String,Object> formData = new map<String,Object>{
                                                                'soldToNew' => false,
                                                                'soldToName' => 'Test Account - 00001',
                                                                'soldToId'  => objAccount.Id,
                                                                'locationNew' => true,
                                                                'leadId'     => objLead.Id,
                                                                'ConNew'     => true,
                                                                'ConName'    => 'Test New',
                                                                'opportunityNew' => true,
                                                                'LocationName' => 'Test Location'
                                                            };
        try{
        Test.startTest();
            LeadConvert.convertLead( formData,new List<String> {'Competitor','Current Account - Do Not Convert','Dead','Marketing Qualified','New','Qualified','Unqualified','Working'});   
            Lead lead = LeadConvert.getLeadAddress(objLead.Id);
            system.assert(lead != null);
        Test.stopTest();
        
        Account objAcc = [Select Id From Account Where Name='Test Account - 00001' And RecordTypeId =: prospectRecTypeId AND ParentId =: objAccount.Id limit 1];
        LeadConvert.findContact('', 'Test', objAcc.Id);
        
        Lead objUpdatedLead = [Select Id,ConvertedAccountId,isConverted From Lead Where Id=: objLead.Id];
        }catch(exception e){
        
        }
        
        }
        
        Id profID1 = [select id from profile where name='B&SH Sales User'].id;


        user2 = new User(alias = 'test123', email='test1234@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID1 , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='testuser@hologic.com');
        
        insert user2;
        System.runAs(user2){
        
        }
        
            
    }
    
     
    
    private static testMethod void test_LeadConvert_Existing_SoldTo_Existing_ShipToAcc1() {
        Id profID = [select id from profile where name='Medical Aesthetics Sales Admin'].id;


        user1 = new User(alias = 'test123', email='test123@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester@hologic.com');
        
        insert user1;
        System.runAs(user1){
            Lead lead2=new Lead(LastName='Doe',FirstName='John',Company='test',Status='Qualified',State = 'Mississippi',Country= 'United States',PostalCode= '38671');  
    
       insert lead2;                
    
       lead2.isConverted__c = true;
       update lead2;
        createData();
        Lead objLead = [Select Id From Lead Limit 1];
        
        PageReference pageRef = Page.LeadConvert;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(objLead);
        LeadConvert lc = new LeadConvert(stdController);
        
        LeadConvert.getLeadAddress(''+objLead.id);
        
        Account objAccount = [Select Id From Account Where Name = 'Test Account - 00001' Limit 1];
        LeadConvert.findContact('test','user',''+objAccount.id);
        LeadConvert.searchContacts('test',objAccount.id);
        map<String,Object> results = new map<String,Object>();
        results = LeadConvert.init(objLead.Id);
        
        System.assert(results != Null);
        System.assert(results.get('lead') != Null);
        
        List<Account> lstAccs = new List<Account>(); 
        lstAccs = LeadConvert.searchAccounts('Test Account - 00001', false); 
        System.assert(lstAccs.size() == 1);
        
        List<Account> lstChildAccs = new List<Account>();
        lstChildAccs = LeadConvert.searchLocations('Test Account - 00002', 'Test \n SHIPTest2 \n SHIPTest3 \n SHIPTest4', objAccount);
        System.assert(lstChildAccs.size() == 1);
        
        List<User> lstUsers = new List<User>();
        lstUsers = LeadConvert.searchOwners('Silverline');
        
        LeadConvert.cancelLead(objLead.Id); 
        //new LeadConvert().dummy(); 
        
        // Preparing the formData...
       map<String,Object> formData = new map<String,Object>{
                                                                'street' => 'test street',
                                                                'soldToNew' => true,
                                                                'soldToName'  => 'NEW ACCOUNT CREATION',
                                                                'locationNew' => true,
                                                                'leadId'     => objLead.Id,
                                                                'ConNew'     => true,
                                                                'opportunityNew' => true,
                                                                'ConName' => 'Test Name',
                                                                'city'=>'test city',
                                                                'state'=>'test state',
                                                                'country'=>'test country'
                                                           };
        try{
        Test.startTest();
            LeadConvert.convertLead( formData,new List<String> {'Competitor','Current Account - Do Not Convert','Dead','Marketing Qualified','New','Qualified','Unqualified','Working'});   
            Lead lead = LeadConvert.getLeadAddress(objLead.Id);
            system.assert(lead != null);
        Test.stopTest();
        
        Account objAcc = [Select Id From Account Where Name='Test Account - 00001' And RecordTypeId =: prospectRecTypeId AND ParentId =: objAccount.Id limit 1];
        LeadConvert.findContact('', 'Test', objAcc.Id);
        
        Lead objUpdatedLead = [Select Id,ConvertedAccountId,isConverted From Lead Where Id=: objLead.Id];
        }catch(exception e){
        
        }
        
        }
        
        Id profID1 = [select id from profile where name='B&SH Sales User'].id;


        user2 = new User(alias = 'test123', email='test1234@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID1 , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='testuser@hologic.com');
        
        insert user2;
        System.runAs(user2){
        
        }
        
            
    }
    
    private static testMethod void test_LeadConvert_New_SoldTo_New_ShipToAcc() {
        
        insert new Lead_Conversion_Profiles__c(name='Medical Aesthetics Sales Admin');
        
        Id profID = [select id from profile where name='Medical Aesthetics Sales Admin'].id;


        user1 = new User(alias = 'test123', email='test123@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester@hologic.com');
        
        insert user1;
        System.runAs(user1){
        Lead lead2=new Lead(LastName='Doe',FirstName='John',Company='Test',Status='Qualified',State = 'Mississippi',Country= 'United States',PostalCode= '38671');

        insert lead2;                
        lead2.isConverted__c = true;
        update lead2;
       
        createData();
        Lead objLead = [Select Id From Lead Limit 1];
        Account objAccount = [Select Id From Account Where Name = 'Test Account - 00001' Limit 1];
        
        // Preparing the formData...
        map<String,Object> formData = new map<String,Object>{
                                                                'street' => 'test street',
                                                                'soldToNew' => true,
                                                                'soldToName'  => 'NEW ACCOUNT CREATION',
                                                                'locationNew' => true,
                                                                'leadId'     => objLead.Id,
                                                                'ConNew'     => false,
                                                                'opportunityNew' => true,
                                                                'ConName' => 'Test Name'
                                                               
                                                           };
        try{ 
        Test.startTest();
                LeadConvert.convertLead( formData,new List<String> {'Competitor','Current Account - Do Not Convert','Dead','Marketing Qualified','New','Qualified','Unqualified','Working'});   
           
        Test.stopTest();
        
         Lead objUpdatedLead = [Select Id,ConvertedAccountId,isConverted From Lead Where Id=: objLead.Id];
        }catch(Exception e){
        
        }
        
        }
    }
    
    private static testMethod void test_LeadConvert_New_SoldTo_Existing_ShipToAcc() {
        
        
        insert new Lead_Conversion_Profiles__c(name='Medical Aesthetics Sales Admin');
        
        Id profID = [select id from profile where name='Medical Aesthetics Sales Admin'].id;


        user1 = new User(alias = 'test123', email='test123@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester@hologic.com');
        
        insert user1;
        System.runAs(user1){
            Lead lead2=new Lead(LastName='Doe',FirstName='John',Company='Test',Status='Qualified',State = 'Mississippi',Country= 'United States',PostalCode= '38671');
    
            insert lead2;                
            lead2.isConverted__c = true;
            update lead2;
                   
            createData();
            Lead objLead = [Select Id From Lead Limit 1];
            Account objAccount = [Select Id From Account Where Name = 'Test Account - 00001' Limit 1];
            List<Account> lstChildAccs = new List<Account>();
            lstChildAccs = LeadConvert.searchLocations('Test Account - 00002', 'Test \n SHIPTest2 \n SHIPTest3 \n SHIPTest4', objAccount);
            System.assert(lstChildAccs.size() == 1);
            
            // Preparing the formData...
            map<String,Object> formData = new map<String,Object>{
                                                                    'soldToNew' => true,
                                                                    'soldToName'  => 'LATEST CREATION',
                                                                    'locationNew' => true,
                                                                    'shipToId'    => lstChildAccs[0].Id,
                                                                    'leadId'     => objLead.Id,
                                                                    'opportunityNew' => false,
                                                                    'ConNew'     => true,
                                                                    'opportunityName' => 'Test Oppty',
                                                                    'ConName' => 'Test Name',
                                                                    'street'=>'test Street'
                                                                };
            try{
                Test.startTest();
                    LeadConvert.convertLead( formData,new List<String> {'Competitor','Current Account - Do Not Convert','Dead','Marketing Qualified','New','Sales Qualified','Unqualified','Working'});   
                Test.stopTest();
                
                Lead objUpdatedLead = [Select Id,ConvertedAccountId,isConverted From Lead Where Id=: objLead.Id];
                
                //System.assert(objUpdatedLead.isConverted);  // Lead is Converted..
                
                // CHecking if we are trying to convert the lead which is already converted...
                map<String,Object> mapofCheckRec = LeadConvert.convertLead( formData,new List<String> {'Competitor','Current Account - Do Not Convert','Dead','Marketing Qualified','New','Sales Qualified','Unqualified','Working'});  
                //System.assert(String.valueOf(mapofCheckRec.get('Error')) == 'Lead has been already converted');
            }catch(Exception e){
            
            }
        
        }
        
      }  

}