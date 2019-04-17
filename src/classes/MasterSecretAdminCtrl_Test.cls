/*--------------------------------------------------------------------------------------------------------------
Author:         Alex Powning
Description:    Test class for Master Secret Admin VF Page Controller

History:
<Date>          <Authors Name>      <Brief Description of Change>
25-Feb-19       Alex Powning        Initial Creation
----------------------------------------------------------------------------------------------------------------*/
@isTest
public class MasterSecretAdminCtrl_Test {

    private static PageReference pageRef;
    private static MasterSecretAdminCtrl ctrl;
    
    static testmethod void testMasterSecretAdmin(){
        
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new DxLabMockHttpResponseGenerator());
        
        pageRef = Page.MasterSecretAdmin;
        Test.setCurrentPage(pageRef);
        
        ctrl = new MasterSecretAdminCtrl();
        
        Test.startTest();
        
        //initialize page
        ctrl.initializePage();
        
        //assert default vals
        System.assert(ctrl.softwareName == '*');
        
        //search all pages
        ctrl.searchMSFirst();
        ctrl.searchMSLast();
        ctrl.searchMSNext();
        ctrl.searchMSPrevious();
        
        //check input validation
        ctrl.softwareName = '';
        ctrl.searchMSFirst();
        ctrl.generateMS();
        
        //check input validation
        ctrl.softwareName = '*';
        ctrl.softwareVersion = '';
        ctrl.searchMSFirst();
        
        //check input validation
        ctrl.softwareName = '*';
        ctrl.softwareVersion = '1.A';
        ctrl.searchMSFirst();
        
        //search with sorting
        ctrl.softwareVersion = '*';
        ctrl.currentSearchSortCol = 'name';
        ctrl.searchMSSortBy();
        ctrl.searchMSFirst();
        
        //generate secret
        ctrl.softwareName = 'Dimensions';
        ctrl.softwareVersion = '1.0';
        ctrl.generateMS();
        
        //filter for specific name
        ctrl.softwareName = 'Dimensions';
        ctrl.filterSoftwareNames();
        
        //set filtered software name
        ctrl.filteredSoftwareName = 'Dimensions';
        ctrl.setSoftwareNameForList();
        
        Test.stopTest();
    }
    
}