/*--------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Test class for Extension Class used by SearchBeforeCreate_CDM VF page.

History:
<Date>      <Authors Name>    <Brief Description of Change>
04/01/2018   Mani Sundaresan    Initial Creation (US-4246)
----------------------------------------------------------------------------------------------------------------------*/
@isTest
public class CDMExtension_Test  {

    //Variable Declaration
    private static Lead testLead;
    private static PageReference pageRef;
    private static CDMExtension cdmEx;
    
    static{
        testLead = TestUtility.newLead('OZARK FAMILY PRACTICE', 'Armstrong', 'USD', '870-743-4242', 'Open', '');
        testLead.FirstName = 'Stacy';
        testLead.Street = '123 MAIN STREET';
        testLead.City = 'CHICAGO';
        testLead.CountryCode = 'US';
        testLead.PostalCode = '600093';
        testLead.StateCode = 'IL';
                
        insert testLead;
    }
    
    static testMethod void testCDMValidation(){
    
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new CDMMockHttpResponseGenerator());
        
        pageRef = Page.SearchBeforeCreate_CDM;
        Test.setCurrentPage(pageRef);
         
        ApexPages.StandardController con = new ApexPages.StandardController(testLead);
        ApexPages.currentPage().getParameters().put('Id',testLead.id);
        
        cdmEx = new CDMExtension(con);
        
        Test.startTest();
        
        cdmEx.searchCDM();

        
        Test.stopTest();
        
        
    }
    
}