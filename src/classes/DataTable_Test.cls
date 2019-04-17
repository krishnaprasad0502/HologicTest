/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Test class to validate DataTable
                Tests Excecuted:
                
                testPagination - verifies that pagination works as expected
                
                testSorting - verifies that the sorting works as expected
                
                testErroneousAPIName - verify that an exception is thrown when passing the table a bad api name

History:
<Date>          <Authors Name>      <Brief Description of Change>
04/05/2016      Denise Bacher       Initial Creation
------------------------------------------------------------*/
@isTest
private class DataTable_Test {
    private static final Integer numCases = 500;
    private static List<Id> caseRecordTypeIds = new List<Id>(GlobalUtility.getAllObjectRecordTypeById('Case').keySet());
    private static List<String> caseRecordTypeNames = new List<String>(GlobalUtility.getAllObjectRecordTypeById('Case').values());  
    private static List<String> caseTypes = GlobalUtility.getFieldPickListValues(Case.Type);
    private static List<String> caseStatuses = GlobalUtility.getFieldPickListValues(Case.Status);
    private static List<String> casePriorities = GlobalUtility.getFieldPickListValues(Case.Priority);
    private static List<String> caseOrigins = GlobalUtility.getFieldPickListValues(Case.Origin);
    
    static {
        TestUtility.setupConfigurationSettings();
         // 13/09/2017-Krishna Prasad-Added trigger switch to fix case Trigger isuue  
         TestUtility.insertCustSetting('CaseTrigger'); 
        
        // insert an account
        Account custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        custAccount.BillingCountryCode = 'US';
        custAccount.BillingStateCode = 'NY';
        insert custAccount;
        
        Account siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', custAccount.Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';
        insert siteAccount;
        
        // remove 'Reopened' status from case statues due to validation rule
        for(Integer i = 0; i < caseStatuses.size(); i++){
            if(caseStatuses[i] == 'Reopened' || caseStatuses[i] == 'Dispatched'){
                caseStatuses.remove(i);
                i--;
            }
        }
        
        List<Case> cases = new List<Case>();
        for(Integer i = 0; i < numCases; i++){
            Case c = TestUtility.newCase(
                siteAccount.Id, null, null, null, 
                caseRecordTypeIds[Math.mod(i, caseRecordTypeIds.size())], 
                caseTypes[Math.mod(i, caseTypes.size())],
                caseStatuses[Math.mod(i, caseStatuses.size())],
                casePriorities[Math.mod(i, casePriorities.size())],
                caseOrigins[Math.mod(i, caseOrigins.size())]
            );
            c.Agreed_Move_Price__c = 1;
            c.Priority = 'Low';
            /*cases.add(TestUtility.newCase(
                siteAccount.Id, null, null, null, 
                caseRecordTypeIds[Math.mod(i, caseRecordTypeIds.size())], 
                caseTypes[Math.mod(i, caseTypes.size())],
                caseStatuses[Math.mod(i, caseStatuses.size())],
                casePriorities[Math.mod(i, casePriorities.size())],
                caseOrigins[Math.mod(i, caseOrigins.size())]
            ));*/
            cases.add(c);
        }
        insert cases;
        
        caseRecordTypeNames.sort();
        
        // remove sorting of picklist fields, in a query, sorting by a picklist field sorts them as they are configured in the list
        //caseTypes.sort();
        //caseStatuses.sort();
        //casePriorities.sort();
        //caseOrigins.sort();
    }

    static testMethod void testPagination() {
        Test.startTest();
            DataTable table = new DataTable('Case', 'Case', new List<DataTable.Column> {
                new DataTable.Column('Case Number', 'CaseNumber'),
                new DataTable.Column('Status', 'Status'),
                new DataTable.Column('Origin', 'Origin'),
                new DataTable.Column('Record Type', 'RecordType.Name'),
                new DataTable.Column('Case Type', 'Type'),
                new DataTable.Column('Created Date', 'CreatedDate'),
                new DataTable.Column('Incident Date', 'Incident_Date__c')
            });

            table.rowsPerPage = 10;
            table.populate('');

            // the total quantity of objects returned by the dynamic SOQL is equal 500
            System.assertEquals(numCases, table.totalCount);
            
            System.assertEquals(10, table.pageCount);
            System.assertEquals(1, table.page);
            System.assertEquals(10, table.rows.size());
            System.assertEquals(String.format(System.Label.lbl_RecordsRangeOfN, new List<String>{'1', '10', '500'}), table.recordsItoJofN);
            System.assertEquals(String.format(System.Label.lbl_PageXofN, new List<String>{'1', '50'}), table.pageXofN);
            System.assert(table.hasNext);
            System.assert(!table.hasPrevious);
            
            table.nextPage();
            System.assertEquals(10, table.pageCount);
            System.assertEquals(2, table.page);
            System.assertEquals(10, table.rows.size());
            System.assertEquals(String.format(System.Label.lbl_RecordsRangeOfN, new List<String>{'11', '20', '500'}), table.recordsItoJofN);
            System.assertEquals(String.format(System.Label.lbl_PageXofN, new List<String>{'2', '50'}), table.pageXofN);
            System.assert(table.hasNext);
            System.assert(table.hasPrevious);

            table.lastPage();
            System.assertEquals(10, table.pageCount);
            System.assertEquals(50, table.page);
            System.assertEquals(10, table.rows.size());
            System.assertEquals(String.format(System.Label.lbl_RecordsRangeOfN, new List<String>{'491', '500', '500'}), table.recordsItoJofN);
            System.assertEquals(String.format(System.Label.lbl_PageXofN, new List<String>{'50', '50'}), table.pageXofN);
            System.assert(!table.hasNext);
            System.assert(table.hasPrevious);
            
            table.previousPage();
            System.assertEquals(10, table.pageCount);
            System.assertEquals(49, table.page);
            System.assertEquals(10, table.rows.size());
            System.assertEquals(String.format(System.Label.lbl_RecordsRangeOfN, new List<String>{'481', '490', '500'}), table.recordsItoJofN);
            System.assertEquals(String.format(System.Label.lbl_PageXofN, new List<String>{'49', '50'}), table.pageXofN);
            System.assert(table.hasNext);
            System.assert(table.hasPrevious);
            
            table.firstPage();
            System.assertEquals(10, table.pageCount);
            System.assertEquals(1, table.page);
            System.assertEquals(10, table.rows.size());
            System.assertEquals(String.format(System.Label.lbl_RecordsRangeOfN, new List<String>{'1', '10', '500'}), table.recordsItoJofN);
            System.assertEquals(String.format(System.Label.lbl_PageXofN, new List<String>{'1', '50'}), table.pageXofN);
            System.assert(table.hasNext);
            System.assert(!table.hasPrevious);
        Test.stopTest();
    }

    static testMethod void testSorting() {
        Test.startTest();
            DataTable table = new DataTable('Case', 'Case' 
                ,10
                , 'RecordType.Name'
                , 'ASC'
                , new List<DataTable.Column> {
                    new DataTable.Column('Case Number', 'CaseNumber'),
                    new DataTable.Column('Status', 'Status'),
                    new DataTable.Column('Origin', 'Origin'),
                    new DataTable.Column('Record Type', 'RecordType.Name'),
                    new DataTable.Column('Created Date', 'CreatedDate'),
                    new DataTable.Column('Incident Date', 'Incident_Date__c')
                }
            );

            // RecordType.Name Ascending
            table.populate('');
            Case firstCase = (Case)table.objects[0];
            System.assertEquals('ASC', table.sortDirection);
            System.assertEquals(caseRecordTypeNames[0], firstCase.RecordType.Name);
            
            // should switch RecordType.Name to Descending
            table.sort();
            table.populate('');
            firstCase = (Case)table.objects[0];
            System.assertEquals('DESC', table.sortDirection);
            System.assertEquals(caseRecordTypeNames[caseRecordTypeNames.size()-1], firstCase.RecordType.Name);
            
            // switch sort field to Origin, still should be Descending
            table.sortField = 'Origin';
            table.sort();
            table.populate('');
            firstCase = (Case)table.objects[0];
            System.assertEquals('DESC', table.sortDirection);
            System.assertEquals(caseOrigins[caseOrigins.size()-1], firstCase.Origin);
            
            // sort again should switch to Origin Ascending
            table.sort();
            table.populate('');
            firstCase = (Case)table.objects[0];
            System.assertEquals('ASC', table.sortDirection);
            System.assertEquals(caseOrigins[0], firstCase.Origin);
            
            // try to sort by a field we didn't query for, should default sort by column 1, CaseNumber
            table.sortField = 'Type';
            table.sort();
            table.populate('');
            firstCase = (Case)table.objects[0];
            Case secondCase = (Case)table.objects[1];
            System.assertEquals('ASC', table.sortDirection);
            System.assertEquals(-1, firstCase.CaseNumber.compareTo(secondCase.CaseNumber));
        Test.stopTest();
    }
    
    static testMethod void testErroneousAPIName() {
        Test.startTest();
            DataTable table = new DataTable('Case', 'Case' 
                ,10
                , 'Garbage__c'
                , 'ASC'
                , new List<DataTable.Column> {
                    new DataTable.Column('Case Number', 'CaseNumber'),
                    new DataTable.Column('Garbage Field', 'Garbage__c')
                }
            );
            
            try{
                table.populate('');
                System.assert(false, 'Populate should have faild due to bad field api name.');
            }
            catch(Exception e){
                System.assert(e.getTypeName().contains('GenericException'));
            }
        Test.stopTest();
    }
    
}