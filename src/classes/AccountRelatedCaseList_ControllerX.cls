/*------------------------------------------------------------
Author:			Denise Bacher
Company:		Salesforce.com
Description:	Displays a list of filterable Cases related to the current Account
Test Class:		AccountRelatedCaseList_ControllerX_Test

History:
<Date>			<Authors Name>		<Brief Description of Change>
03/31/2016		Denise Bacher		Initial Creation (US477)
------------------------------------------------------------*/
public with sharing class AccountRelatedCaseList_ControllerX {
	private final Account account;
	private final transient Configuration_Settings__c configSetting = Configuration_Settings__c.getInstance(); 
	private final transient Map<String, Schema.SObjectField> caseFieldMap = Case.sObjectType.getDescribe().fields.getMap();
	private final transient Map<String, Schema.DescribeFieldResult> caseDescribeFieldMap;
	
	// DataTable that contains the case information
	public DataTable cases{
		get{
			if(cases == null && !configSettingUndefined){
				cases = new DataTable('Case', 'Related Cases', (Integer)configSetting.Case_List_Records_Per_Page__c, configSetting.Case_List_Column_01__c
										, 'DESC', columns);	
				populateCaseTable();
			}
			return cases;
		}
		private set;
	}
	
	// list of DataTable columns dispalyed in the DataTable, pulled from the custom setting
	private List<DataTable.Column> columns{
		get{
			if(columns == null && !configSettingUndefined){
				columns = new List<DataTable.Column>();
				
				// there should always be a column 1 (it's required), so need to check if it's blank
				columns.add(newColumn(configSetting.Case_List_Column_01__c.toLowerCase()));
								
				if(String.isNotBlank(configSetting.Case_List_Column_02__c)){
					columns.add(newColumn(configSetting.Case_List_Column_02__c.toLowerCase()));
				}
				if(String.isNotBlank(configSetting.Case_List_Column_03__c)){
					columns.add(newColumn(configSetting.Case_List_Column_03__c.toLowerCase()));
				}
				if(String.isNotBlank(configSetting.Case_List_Column_04__c)){
					columns.add(newColumn(configSetting.Case_List_Column_04__c.toLowerCase()));
				}
				if(String.isNotBlank(configSetting.Case_List_Column_05__c)){
					columns.add(newColumn(configSetting.Case_List_Column_05__c.toLowerCase()));
				}
				if(String.isNotBlank(configSetting.Case_List_Column_06__c)){
					columns.add(newColumn(configSetting.Case_List_Column_06__c.toLowerCase()));
				}
				if(String.isNotBlank(configSetting.Case_List_Column_07__c)){
					columns.add(newColumn(configSetting.Case_List_Column_07__c.toLowerCase()));
				}
				if(String.isNotBlank(configSetting.Case_List_Column_08__c)){
					columns.add(newColumn(configSetting.Case_List_Column_08__c.toLowerCase()));
				}
				if(String.isNotBlank(configSetting.Case_List_Column_09__c)){
					columns.add(newColumn(configSetting.Case_List_Column_09__c.toLowerCase()));
				}
				if(String.isNotBlank(configSetting.Case_List_Column_10__c)){
					columns.add(newColumn(configSetting.Case_List_Column_10__c.toLowerCase()));
				}
			}
			return columns;
		}
		private set;
	}
	
	public Boolean selectedMyCases {get; set;} // filter value: my cases (true), all cases (false)
	
	public String selectedRecordTypeOption {get; set;} // filter value: record type
	public List<SelectOption> recordTypeOptions {
		get{
			if(recordTypeOptions == null){
				recordTypeOptions = new List<SelectOption>();
				recordTypeOptions.add(new SelectOption('', System.Label.plst_All));
				
				Map<String, Id> caseRecordTypesAPIName = GlobalUtility.getAllObjectRecordTypeByName('Case');
				Map<Id, String> caseRecordTypesId = GlobalUtility.getAllObjectRecordTypeById('Case');
				List<String> tempNames = new List<String>(caseRecordTypesAPIName.keySet());
				tempNames.sort();
				
				for(String name : tempNames){
					String value = caseRecordTypesAPIName.get(name);
					String label = caseRecordTypesId.get(value);
					recordTypeOptions.add(new SelectOption(value, label));
				} 
			}
			return recordTypeOptions;
		}
		private set;
	}
	
	public String selectedTypeOption {get; set;} // filter value: case type
	public List<SelectOption> typeOptions{
		get{
			if(typeOptions == null){
				typeOptions = new List<SelectOption>();
				typeOptions.add(new SelectOption('', System.Label.plst_All));
				
				typeOptions.addAll(GlobalUtility.getPickListAsSelectOptions(Case.Type));
			}
			return typeOptions;
		}
		private set;
	}
	
	public String selectedStatusOption {get; set;} // filter value: case status
	public List<SelectOption> statusOptions{
		get{
			if(statusOptions == null){
				statusOptions = new List<SelectOption>();
				statusOptions.add(new SelectOption('', System.Label.plst_All));
				
				statusOptions.addAll(GlobalUtility.getPickListAsSelectOptions(Case.Status));
			}
			return statusOptions;
		}
		private set;
	}
	
	public String selectedPriorityOption {get; set;} // filter value: case priority 
	public List<SelectOption> priorityOptions{
		get{
			if(priorityOptions == null){
				priorityOptions = new List<SelectOption>();
				priorityOptions.add(new SelectOption('', System.Label.plst_All));
				
				priorityOptions.addAll(GlobalUtility.getPickListAsSelectOptions(Case.Priority));
			}
			return priorityOptions;
		}
		private set;
	}
	
	//public Date selectedStartDate {get; set;} // filter value: created start date
	//public Date selectedEndDate {get; set;} // filter value: created end date
	
	public Boolean configSettingUndefined{
		get{
			return configSetting == null || String.isBlank(configSetting.Case_List_Column_01__c) || configSetting.Case_List_Records_Per_Page__c == null;
		}
		private set;
	}
	
	public AccountRelatedCaseList_ControllerX(ApexPages.StandardController ctrl){
		account = (Account)ctrl.getRecord();
		
		// set default filter options
		selectedMyCases = false;
		selectedRecordTypeOption = '';
		selectedTypeOption = '';
		selectedStatusOption = '';
		selectedPriorityOption = '';
		
		// populate the caseFields
		if(configSettingUndefined){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to display related cases. Custom Setting "Configuration Settings" is not defined.'));
		}
		
		// but all the case fields (described) into a map so we can access their values later
		if(caseDescribeFieldMap == null){
			caseDescribeFieldMap = new Map<String, Schema.DescribeFieldResult>();
			for(String key : caseFieldMap.keySet()){
				caseDescribeFieldMap.put(key, caseFieldMap.get(key).getDescribe());
			}
		}
	}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Populate the case table based on the selected filters
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	04/05/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public void populateCaseTable(){
		try{
			String myCasesFilter = selectedMyCases ? ' And OwnerId = \'' + UserInfo.getUserId() + '\'' : '';
			String recordTypeFilter = String.isNotBlank(selectedRecordTypeOption) ? ' And RecordTypeId = \'' + selectedRecordTypeOption + '\'' : '';
			String typeFilter = String.isNotBlank(selectedTypeOption) ? ' And Type = \'' + selectedTypeOption + '\'' : '';
			String statusFilter = String.isNotBlank(selectedStatusOption) ? ' And Status = \'' + selectedStatusOption + '\'' : '';
			String priorityFilter = String.isNotBlank(selectedPriorityOption) ? ' And Priority = \'' + selectedPriorityOption + '\'' : '';
			
			//Time zeroTime = Time.newInstance(0, 0, 0, 0);
			//String startDateFilter = selectedStartDate != null ? ' And CreatedDate >= ' + DateTime.newInstance(selectedStartDate, zeroTime).formatGmt('yyyy-MM-dd\'T\'hh:mm:ssZ') : '';
			//String endDateFilter = selectedEndDate != null ? ' And CreatedDate <= ' + DateTime.newInstance(selectedEndDate, zeroTime).formatGmt('yyyy-MM-dd\'T\'hh:mm:ssZ') : '';
			
			cases.populate('AccountId = \'' + account.Id + '\'' + recordTypeFilter + typeFilter + statusFilter + priorityFilter + myCasesFilter);
		} 
		catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error populating the table.', e.getMessage()));
		}
	}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Resort the case table by the selected field
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	04/05/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public void sortCaseTable(){
		cases.sort();
		populateCaseTable();
	}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	given an object field, create a new column
	Inputs:			field - API name of the field this column represents  
	Returns:		new DataTable.Column
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	04/05/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	private DataTable.Column newColumn(String field){
		String objField = field;
		
		// if the field queried is a lookup field, modify it so we can describe the label
		if(field.contains('.')){
			objField = field.split('\\.')[0];
			objField = objField.contains('__r') ? objField.replace('__r','__c') : objField + 'id';	
		}
		
		return new DataTable.Column(
			caseDescribeFieldMap.get(objField).getLabel() 
			, field, ''
			, caseDescribeFieldMap.get(objField).isSortable() 
		);
	}
}