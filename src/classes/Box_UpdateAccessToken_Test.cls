/**************************************************************************************
    Author 		 : Nikhil Mutyam
    Company 	 : Hexaware Technologies
	Created Date : 8/13/2018 7:30 AM
    Description  : Test Class for Box_UpdateAccessToken 

    History:
    <Date>         	<Author Name>       	<Brief Description of Change> 	<Copa.do US#>
	10/9/2018 	    Nikhil Mutyam			Initial Creation				US-0005861
**************************************************************************************/
@isTest
public class Box_UpdateAccessToken_Test {
	
    private static String accessToken = 'accesstoken';
    private static String refreshToken = 'refreshtoken';
    private static String clientId = 'clientid';
    private static String clientSecret = 'clientsecret';
    private static String authCode = 'authcode';
    private static String entityId = 'entityid';
    private static String userId = 'userid';
    private static String enterpriseId = 'enterpriseid';
    private static String publicKeyId = 'publicKeyId';
    private static String privateKey = BoxTestJsonResponseFactory.AUTH_PRIVATE_KEY;
    private static String privateKeyPassword = 'privateKeyPassword';
    private static BoxJwtEncryptionPreferences.EncryptionAlgorithm algorithm = BoxJwtEncryptionPreferences.EncryptionAlgorithm.RSA_SHA_256;
    
    @testSetup 
    static void setupTestData() {
    	list<Box_Auth__c> Credentials = new list<Box_Auth__c>();
        Credentials = TestUtility.getBoxCredentials(1);
        database.insert(Credentials);
        system.debug('The Cases are: '+Credentials);
    }
    
    private static BoxJwtEncryptionPreferences constructEncryptionPrefs() {
		BoxJwtEncryptionPreferences prefs = new BoxJwtEncryptionPreferences();
		prefs.setEncryptionAlgorithm(algorithm);
		prefs.setPrivateKey(privateKey);
		prefs.setPrivateKeyPassword(privateKeyPassword);
		prefs.setPublicKeyId(publicKeyId);
		return prefs;
	}
    
    public static testMethod void testupdateAccessToken(){
        BoxJwtEncryptionPreferences encryptionPref = constructEncryptionPrefs();
		String authResponse = BoxTestJsonResponseFactory.AUTH_APP_USER_TOKEN;
		Test.setMock(HttpCalloutMock.class, (new BoxTestMockCallout(authResponse, 'OK', 200)));
        
        Test.startTest();
        	String CRON_EXP = '0 0 0 15 3 ? *';
        	String jobId = System.schedule('ScheduleApexClassTest',  CRON_EXP, new BOX_UpdateAccessToken());
        	CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(CRON_EXP, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);
            BOX_UpdateAccessToken.sendException(123,'Test Exception Message');
        Test.stopTest();
    }
}