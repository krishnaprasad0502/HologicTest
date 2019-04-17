/***************************************************************************************************
    Author       : Nikhil Mutyam
    Company      : Hexaware Technologies
    Created Date : 8/13/2018 2:39 AM
    Description  : Test class for LightningSelfRegisterController   

    History:
    <Date>          <Author Name>                   <Brief Description of Change>   <Copa.do US#>
    8/13/2018       Community Enablement            Initial Creation                US-0005630 
    10/15/2018      Niraj Wani                      Approval Process                US-0005861
    10/30/2018      Vrushabh Katariya               Added method for picklist       US-0005861
    11/13/2018      Vrushabh katariya               Updated timezone code           US-0006062
    12/26/2018      Yogitha Malireddy               Updated Country code            US-0006345 
    01/02/2019      Vrushabh Katariya               Grey-out submit button          US-0006703
***************************************************************************************************/

@IsTest(SeeAllData = true)
public with sharing class LightningSelfRegisterControllerTest {
    
    /* Verifies that IsValidPassword method with various password combinations. */
    @IsTest
    static void testIsValidPassword() {
        System.assert(LightningSelfRegisterController.isValidPassword('password?@12334', 'password?@12334') == true);
        System.assert(LightningSelfRegisterController.isValidPassword('password?@12334', 'dummyPassword') == false);
        System.assert(LightningSelfRegisterController.isValidPassword('password?@12334', null) == false);
        System.assert(LightningSelfRegisterController.isValidPassword(null, 'fakePwd') == false);
    }
    
    @IsTest
    static void testSiteAsContainerEnabled() {
        System.assertNotEquals(null, LightningSelfRegisterController.siteAsContainerEnabled('https://portaleu1-developer-edition.eu11.force.com'));
    }
    
    /* Verifies the selfRegistration method flow with various invalid inputs */
    @IsTest
    static void testSelfRegistration() {
        //TestUtility.setupConfigurationSettings();
        //Create test Account record
        
        Id customerRecID = GlobalUtility.getRecordTypeId('Account','Customer');
        Id siteRecID = GlobalUtility.getRecordTypeId('Account','Site');
        
        Account testL2Account ;        
        testL2Account = TestUtility.newAccount('Parent Account', 'Account1');
        testL2Account.RecordTypeId = customerRecID;
        database.insert(testL2Account) ;
        
        Account acc ;        
        acc = TestUtility.newAccount('Test Account',null);
        acc.ParentId = testL2Account.Id;
        acc.RecordTypeId =  siteRecID;
        database.insert(acc) ;
        
        Contact cnt = new Contact();
        cnt.AccountId = acc.Id;
        cnt.FirstName = 'Test First';
        cnt.LastName = 'Test Last';
        cnt.email = 'tncq@gmail.com';
        cnt.MailingCountryCode = 'US';
        cnt.Phone= '(121)999-5544';
        database.insert(cnt);
        
        Map < String, String > paramsMap = initializeParams();
        System.assertNotEquals(null, paramsMap);
        System.assertEquals(Label.Site.lastname_is_required, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), '', paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true, '','','','','','','','','', paramsMap.get('newUserRegUrl') , paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone')));
        System.assertEquals(Label.Site.email_is_required, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), '', paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true, '','','','','','','','','', paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone')));
        System.assertEquals(Label.Site.email_is_required, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), '', null, paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true, '','','','','','','','','', paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone')));
        System.assertEquals(Label.Support_Self_Register_FirstName_Error, LightningSelfRegisterController.selfRegister('', paramsMap.get('lastName'), '', null, paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true, '','','','','','','','','', paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone')));
        //Password related assets commeted out
        //System.assertEquals(Label.Support_Self_Register_Password_Error, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), '', '', null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true, '','','','','','','','', paramsMap.get('newUserRegUrl')));
        //System.assertEquals(Null, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), '1234', '1234', null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true, '','','','','','','','', paramsMap.get('newUserRegUrl')));
        //System.assertEquals(Label.Support_Self_Register_Confirm_Password_Error, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), 'Password@123', '', null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true, '','','','','','','','', paramsMap.get('newUserRegUrl')));
        //System.assertEquals(Label.site.passwords_dont_match, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true, '','','','','','','','', paramsMap.get('newUserRegUrl')));
        System.assertEquals(Label.Community_JobTitle_Required, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), 'tncq@gmail.com', 'sfdc@12345', paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false, '','ABC Inc.','','','123 Street','NY','NY','NY','4001010', paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone')));
        System.assertEquals(Label.Community_Company_Required, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), 'tncq@gmail.com', 'sfdc@12345', paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false, 'Radiologist','','','','123 Street','NY','NY','NY','4001010', paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone')));
        System.assertEquals(Label.Community_OfficePhone_Required, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), 'tncq@gmail.com', 'sfdc@12345', paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false, 'Radiologist','ABC Inc.','','','123 Street','NY','NY','NY','4001010', paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone')));
        System.assertEquals(Label.Community_BusinessStreetAddress_Required, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), 'tncq@gmail.com', 'sfdc@12345', paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false, 'Radiologist','ABC Inc.','','1001111234','','NY','NY','NY','4001010', paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone')));
        System.assertEquals(Label.Community_City_Required, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), 'tncq@gmail.com', 'sfdc@12345', paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false, 'Radiologist','ABC Inc.','','1001111234','123 Street','','NY','NY','4001010', paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone')));
        System.assertEquals(Label.Community_State_Required, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), 'tncq@gmail.com', 'sfdc@12345', paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false, 'Radiologist','ABC Inc.','','1001111234','123 Street','NY','','NY','4001010', paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone')));
        System.assertEquals(Label.Community_Country_Required, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), 'tncq@gmail.com', 'sfdc@12345', paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false, 'Radiologist','ABC Inc.','','1001111234','123 Street','NY','NY','','4001010', paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone')));
        System.assertEquals(Label.Community_Zip_Required, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), 'tncq@gmail.com', 'sfdc@12345', paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false, 'Radiologist','ABC Inc.','','1001111234','123 Street','NY','NY','NY','', paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone')));
        System.assertNotEquals(null, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), '', paramsMap.get('password'), paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false, '','','','','','','','','', paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone')));
        //System.assertEquals(null, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), 'tncq@gmail.com', 'sfdc@12345', paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false, 'Radiologist','ABC Inc.','','1001111234','123 Street','NY','NY','NY','4001010', paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone')));
        System.assertEquals('true', LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), 'tncq@gmail.com', 'sfdc@12345', paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false, 'Radiologist','ABC Inc.','','1001111234','123 Street','NY','NY','NY','4001010', paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone')));
    }
    
    
    /* Verifies the selfRegistration flow for valid inputs */
    @IsTest
    static void testSelfRegisterWithProperCredentials() {
        Map < String, String > paramsMap = initializeParams();
        string str = LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true, '','','','','','','','','', paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone'));
        //System.assertEquals(null, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true, '','','','','','','','',, paramsMap.get('productInterest'), paramsMap.get('serialNumber')));
    }
    
    /* Verifies SelfRegistration flow with an accounId that is created within the test */
    @IsTest
    static void testSelfRegisterWithCreatedAccount() {
        Account acc = new Account(name = 'test acc');
        insert acc;
        List < Account > accounts = [SELECT Id FROM Account LIMIT 1];
        System.assert(!accounts.isEmpty(), 'There must be at least one account in this environment!');
        String accountId = accounts[0].Id;
        Map < String, String > paramsMap = initializeParams();
        string str = LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), accountId, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false, '','','','','','','','','',  paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone') );   
        //System.assertEquals(null, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), accountId, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false, '','','','','','','',''));
    }
    
    //If community user with email already exists
    @IsTest
    static void testErrorExistingCommunityUser() {
        String email;
        Account acc = new Account(name = 'test acc');
        insert acc;
        List < Account > accounts = [SELECT Id FROM Account LIMIT 1];
        System.assert(!accounts.isEmpty(), 'There must be at least one account in this environment!');
        String accountId = accounts[0].Id;
        list<User> existingUsers = [SELECT Id,Email FROM User WHERE UserType = 'PowerCustomerSuccess' LIMIT 1];
        if(existingUsers != Null && existingUsers.size() > 0){
           email= existingUsers[0].Email;
            System.debug('Email: ' + email);
        }
        
        Map < String, String > paramsMap = initializeParams();
        string str = LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), email, 'sfdc@12345', paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false, '','','','','','','','','', paramsMap.get('newUserRegUrl'), paramsMap.get('productInterest'), paramsMap.get('serialNumber'), paramsMap.get('TimeZone'));   
        System.assertEquals(Label.Support_Duplicate_Username_Error, str);
    }
    
    @IsTest
    static void testGetNullExtraFields() {
        System.assertEquals(new List < Map < String, Object >> (), LightningSelfRegisterController.getExtraFields(null));
    }
    
    @IsTest
    static void testGetNonEmptyExtraFields() {
        System.assertEquals(new List < Map < String, Object >> (), LightningSelfRegisterController.getExtraFields('field1'));
    }
    
    /* Verifies validation of extraFields within the Self Registration flow 
    @IsTest
    static void testGetExtraFieldsInSelfRegistration() {
        List < Map < String, Object >> fieldlist = new List < Map < String, Object >> ();
        Map < String, String > paramsMap = initializeParams();
        Map < String, Object > fieldMap = new Map < String, Object > ();
        fieldMap.put('description', 'new field');
        fieldMap.put('fieldPath', 'dummyPath');
        fieldlist.add(fieldMap);
        String extraFields = JSON.serialize(fieldlist);
        System.assertNotEquals(null, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), extraFields, paramsMap.get('startUrl'), true, '','','','','','','','', paramsMap.get('newUserRegUrl')));
    } */
    
    @IsTest
    static void LightningSelfRegisterControllerInstantiation() {
        LightningSelfRegisterController controller = new LightningSelfRegisterController();
        System.assertNotEquals(controller, null);
        LightningSelfRegisterController.setExperienceId('');
        User U = new User(); 
        LightningSelfRegisterController.FetchStatePicklistValues(U); 
         LightningSelfRegisterController.FetchCountryPicklistValues(U);
    }
    
    /*Test method to test fucntionality of controller method -"GetSelectOptions()"*/
    @isTest
    static void testGetselectOptions1(){
        Case TestC = new Case(Subject='Test Controller Acct Case', Priority='Sev 2');
        database.insert(TestC);
        Test.startTest();
            Map <String,String> plicklistVal = LightningSelfRegisterController.getselectOptions(TestC, 'Status');
            Boolean result = plicklistVal.containsKey('Open');
            System.assertEquals(true, result);
        Test.stopTest();
    }
    
    /* Helper method to initialize the parameters required for SelfRegistration. */
    private static Map < String, String > initializeParams() {
        Map < String, String > paramsMap = new Map < String, String > ();
        String firstName = 'test';
        String lastName = 'User';
        String email = 'testUser@salesforce.com';
        String password = 'testuser123';
        String confirmPasswordCorrect = 'testuser123';
        String confirmPasswordWrong = 'wrongpassword';
        String accountId = 'testuser123';
        String regConfirmUrl = 'http://registration-confirm.com';
        String startUrl = 'http://my.company.salesforce.com';
        paramsMap.put('firstName', firstName);
        paramsMap.put('lastName', lastName);
        paramsMap.put('email', email);
        paramsMap.put('password', password);
        paramsMap.put('confirmPasswordCorrect', confirmPasswordCorrect);
        paramsMap.put('confirmPasswordWrong', confirmPasswordWrong);
        paramsMap.put('accountId', accountId);
        paramsMap.put('regConfirmUrl', regConfirmUrl);
        paramsMap.put('startUrl', startUrl);
        paramsMap.put('newUserRegUrl', regConfirmUrl);
        paramsMap.put('productInterest', 'Mammography');
        paramsMap.put('serialNumber', '12345');
        paramsMap.put('TimeZone', 'America/New_York');
        return paramsMap;
    }
}