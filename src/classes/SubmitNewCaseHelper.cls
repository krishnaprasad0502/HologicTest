/***************************************************************************
Author:Vrushabh Kataria
Company:Hexaware Technologies
Description: This controller class is used to extend the functionality of SubmitNewCaseController.

TestClass: SubmitNewCaseHelper_Test
Code Coverage: 100%

History:
<Date>              <Author Name>        <Brief description of change >		<Copa.do US#>
10/10/2018			Vrushabh Kataria	 Initial Creation					US-0005861
****************************************************************************/
public without sharing class SubmitNewCaseHelper {
	
    @auraEnabled
    public static AssignmentRule fetchAssignmentRule (){
        AssignmentRule AR = [select id,Active from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
        return AR;
    }
}