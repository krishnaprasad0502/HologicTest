/*--------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Test class for Controller used by GenerateQRCode VF page.

History:
<Date>      <Authors Name>    <Brief Description of Change>
03/13/2019   Mani Sundaresan   Initial Creation
----------------------------------------------------------------------------------------------------------------------*/
@isTest
private class GenerateQRCode_Test{

    //Variable Declaration Section
    private static PageReference pageRef;
    private static GenerateQRCode genQRCode;
    
    static testMethod void testSoftVersions(){
        
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new SecretKeyVersionHTTPResponseGenerator());
        Test.startTest();
        pageRef = Page.QRCodeGenerator;
        Test.setCurrentPage(pageRef);
        
        genQRCode = new GenerateQRCode();
        
        genQRCode.generateSoftVersions();
        Test.stopTest();
    }
    
    static testMethod void testQRCodeGeneration(){
    
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new QRCodeHTTPResponseGenerator());
        Test.startTest();
        
        pageRef = Page.QRCodeGenerator;
        Test.setCurrentPage(pageRef);
        
        genQRCode = new GenerateQRCode();
        
        genQRCode.vVersion = 'Hologic Dashboard FSE (version 1.0)';
        //generate code
        genQRCode.generateqr();
        //download to html doc
        genQRCode.downloadTxt();
        Test.stopTest();
    
        
    }
    
    
}