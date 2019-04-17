/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Test class to validate AccountRelatedCaseList_ControllerX
                Tests Excecuted:
                
                initializeTable - verifies that the data table loads correctly
                
                sortTable - verifies that re-sorting by column works as expected
                
                filterTable - verifies that filtering works as expected
                
                errorHandling - verifies that errors are handled gracefully when Configuration_Settings__c not set

History:
<Date>          <Authors Name>      <Brief Description of Change>
04/05/2016      Denise Bacher       Initial Creation
------------------------------------------------------------*/
@isTest
private class AccountRelatedCaseList_ControllerX_Test {
    private static final Integer numCases = 156;
    private static final Id runningUserId = UserInfo.getUserId();
    private static Configuration_Settings__c orgDefaults;
    private static List<Case> cases;
    private static Account custAccount;
    private static Account siteAccount;
    private static User otherUser;
    
    private static List<Id> caseRecordTypeIds = new List<Id>(GlobalUtility.getAllObjectRecordTypeById('Case').keySet());
    private static List<String> caseRecordTypeNames = new List<String>(GlobalUtility.getAllObjectRecordTypeById('Case').values());  
    private static List<String> caseTypes = GlobalUtility.getFieldPickListValues(Case.Type);
    private static List<String> caseStatuses = GlobalUtility.getFieldPickListValues(Case.Status);
    private static List<String> casePriorities = GlobalUtility.getFieldPickListValues(Case.Priority);
    private static List<String> caseOrigins = GlobalUtility.getFieldPickListValues(Case.Origin);
    
    static{
        // remove 'Reopened' status from case statues due to validation rule
        for(Integer i = 0; i < caseStatuses.size(); i++){
            if(caseStatuses[i] == 'Reopened' || caseStatuses[i] == 'Dispatched'){
                caseStatuses.remove(i);
                i--;
            }
        }
         // 13/09/2017-Krishna Prasad-Added trigger switch to fix case Trigger isuue       
        TestUtility.insertCustSetting('CaseTrigger'); 
        orgDefaults = TestUtility.setupConfigurationSettings();
        
        orgDefaults.Case_List_Column_02__c = 'Status';
        orgDefaults.Case_List_Column_03__c = 'Origin';
        orgDefaults.Case_List_Column_04__c = 'Priority';
        orgDefaults.Case_List_Column_05__c = 'RecordType.Name';
        orgDefaults.Case_List_Column_06__c = 'Type';
        orgDefaults.Case_List_Column_07__c = 'CreatedDate';
        orgDefaults.Case_List_Column_08__c = 'ClosedDate';
        orgDefaults.Case_List_Column_09__c = 'Subject';
        orgDefaults.Case_List_Column_10__c = 'OwnerId';
        update orgDefaults;
        
        // insert an account
        custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        custAccount.BillingCountryCode = 'US';
        custAccount.BillingStateCode = 'NY';        
        insert custAccount;
        
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', custAccount.Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';
        insert siteAccount;
        
        otherUser = TestUtility.newUser(UserInfo.getProfileId(), 'other');
        insert otherUser;
        
        cases = new List<Case>();
        System.runAs(new User(Id = runningUserId)) {
            for(Integer i = 0; i < numCases; i++){
                Case temp = TestUtility.newCase(
                    siteAccount.Id, null, null, null, 
                    caseRecordTypeIds[Math.mod(i, caseRecordTypeIds.size())], 
                    caseTypes[Math.mod(i, caseTypes.size())],
                    caseStatuses[Math.mod(i, caseStatuses.size())],
                    casePriorities[Math.mod(i, casePriorities.size())],
                    caseOrigins[Math.mod(i, caseOrigins.size())]
                );
                
                temp.OwnerId = Math.mod(i, 2) == 0 ? otherUser.Id : runningUserId;
                temp.Agreed_Move_Price__c = 1;
                temp.Priority = 'Low';
                cases.add(temp);
            }
            insert cases;
        }
    }
    
    static testMethod void initializeTable(){
        PageReference pageRef = Page.AccountRelatedCaseList;
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
            AccountRelatedCaseList_ControllerX ctrl = new AccountRelatedCaseList_ControllerX(new ApexPages.StandardController(siteAccount));
            
            System.assertNotEquals(null, ctrl.cases);
            System.assertEquals(numCases, ctrl.cases.totalCount);
            System.assertEquals(1, ctrl.cases.page);
            System.assertEquals(orgDefaults.Case_List_Records_Per_Page__c, ctrl.cases.pageCount);
            System.assertEquals(orgDefaults.Case_List_Records_Per_Page__c, ctrl.cases.rows.size());
            System.assertEquals(String.format(System.Label.lbl_RecordsRangeOfN, new List<String>{'1', String.valueOf(orgDefaults.Case_List_Records_Per_Page__c), String.valueOf(numCases)}), ctrl.cases.recordsItoJofN);
            System.assertEquals(String.format(System.Label.lbl_PageXofN, new List<String>{'1', String.valueOf(((Decimal)numCases/(Decimal)orgDefaults.Case_List_Records_Per_Page__c).round(System.RoundingMode.UP))}), ctrl.cases.pageXofN);
        Test.stopTest();
    }
    
    static testMethod void sortTable(){
        PageReference pageRef = Page.AccountRelatedCaseList;
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
            AccountRelatedCaseList_ControllerX ctrl = new AccountRelatedCaseList_ControllerX(new ApexPages.StandardController(siteAccount));
            System.assertNotEquals(null, ctrl.cases);
            System.assertEquals(numCases, ctrl.cases.totalCount);
            
            Case firstCase = (Case)ctrl.cases.objects[0];
            Case secondCase = (Case)ctrl.cases.objects[1];
            System.assertEquals('DESC', ctrl.cases.sortDirection);
            System.assertEquals(1, firstCase.CaseNumber.compareTo(secondCase.CaseNumber));
            
            ctrl.cases.sortField = orgDefaults.Case_List_Column_01__c;
            ctrl.sortCaseTable();
            firstCase = (Case)ctrl.cases.objects[0];
            secondCase = (Case)ctrl.cases.objects[1];
            System.assertEquals('ASC', ctrl.cases.sortDirection);
            System.assertEquals(-1, firstCase.CaseNumber.compareTo(secondCase.CaseNumber));
        Test.stopTest();
    }
    
    static testMethod void filterTable(){
        PageReference pageRef = Page.AccountRelatedCaseList;
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
            System.runAs(otherUser) {
                AccountRelatedCaseList_ControllerX ctrl = new AccountRelatedCaseList_ControllerX(new ApexPages.StandardController(siteAccount));
                System.assertNotEquals(null, ctrl.cases);
                System.assertEquals(numCases, ctrl.cases.totalCount);
                
                // verify filters are populated
                System.assertEquals(false, ctrl.selectedMyCases);
                System.assertEquals('', ctrl.selectedRecordTypeOption);
                System.assertEquals(caseRecordTypeIds.size()+1, ctrl.recordTypeOptions.size()); // extra one for the all option
                System.assertEquals('', ctrl.selectedTypeOption);
                System.assertEquals(caseTypes.size()+1, ctrl.typeOptions.size()); // extra one for the all option
                System.assertEquals('', ctrl.selectedStatusOption);
                System.assertEquals(GlobalUtility.getFieldPickListValues(Case.Status).size()+1, ctrl.statusOptions.size()); // extra one for the all option
                System.assertEquals('', ctrl.selectedPriorityOption);
                System.assertEquals(casePriorities.size()+1, ctrl.priorityOptions.size()); // extra one for the all option
                
                // my cases
                ctrl.selectedMyCases = true;
                ctrl.selectedRecordTypeOption = '';
                ctrl.selectedTypeOption = '';
                ctrl.selectedStatusOption = '';
                ctrl.selectedPriorityOption = '';
                ctrl.populateCaseTable();
                System.assertNotEquals(numCases, ctrl.cases.totalCount);
                
                // record type
                ctrl.selectedMyCases = false;
                ctrl.selectedRecordTypeOption = caseRecordTypeIds[0];
                ctrl.selectedTypeOption = '';
                ctrl.selectedStatusOption = '';
                ctrl.selectedPriorityOption = '';
                ctrl.populateCaseTable();
                System.assert(ctrl.cases.totalCount >= numCases/caseRecordTypeIds.size());
                
                // type
                ctrl.selectedMyCases = false;
                ctrl.selectedRecordTypeOption = '';
                ctrl.selectedTypeOption = caseTypes[0];
                ctrl.selectedStatusOption = '';
                ctrl.selectedPriorityOption = '';
                ctrl.populateCaseTable();
                System.assert(ctrl.cases.totalCount >= numCases/caseTypes.size());
                
                // status
                ctrl.selectedMyCases = false;
                ctrl.selectedRecordTypeOption = '';
                ctrl.selectedTypeOption = '';
                ctrl.selectedStatusOption = caseStatuses[0];
                ctrl.selectedPriorityOption = '';
                ctrl.populateCaseTable();
                System.assert(ctrl.cases.totalCount >= numCases/caseStatuses.size());
                
                // priority
                ctrl.selectedMyCases = false;
                ctrl.selectedRecordTypeOption = '';
                ctrl.selectedTypeOption = '';
                ctrl.selectedStatusOption = '';
                ctrl.selectedPriorityOption = casePriorities[0];
                ctrl.populateCaseTable();
                //System.assert(ctrl.cases.totalCount >= numCases/casePriorities.size());
            }
        Test.stopTest();
    }
    
    static testMethod void errorHandling(){
        delete [Select Id From Configuration_Settings__c];
        
        PageReference pageRef = Page.AccountRelatedCaseList;
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
            AccountRelatedCaseList_ControllerX ctrl = new AccountRelatedCaseList_ControllerX(new ApexPages.StandardController(siteAccount));
            
            System.assertEquals(null, ctrl.cases);
            System.assert(ApexPages.hasMessages(), 'No messages');
            System.assertEquals(1, ApexPages.getMessages().size());
            System.assertEquals('Unable to display related cases. Custom Setting "Configuration Settings" is not defined.', ApexPages.getMessages()[0].getSummary());
            
            ctrl.populateCaseTable();
            System.assert(ApexPages.hasMessages(), 'No messages');
            System.assertEquals(2, ApexPages.getMessages().size());
            System.assertEquals('There was an error populating the table.', ApexPages.getMessages()[1].getSummary());
        Test.stopTest();
    }
}