/***************************************************************************
Author:Vrushabh Kataria
Company:Hexaware Technologies
Description: Test Class for SubmitNewCaseController class
Controller Class: SubmitNewCaseHelper

History:
<Date>              <Author Name>        <Brief description of change>		<Copa.do US#>
10/10/2018			Vrushabh Kataria	 Initial creation					US-0005861
****************************************************************************/
@isTest
public class SubmitNewCaseHelper_Test {

    /*Test method to test fucntionality of controller method -"fetchUser()"*/
    @isTest
    static void testFetchfetchAssignmentRule(){
        Test.startTest();
        AssignmentRule AR = SubmitNewCaseHelper.FetchAssignmentRule();
        system.assertEquals(AR.active,True);
        Test.stopTest();
    }
}