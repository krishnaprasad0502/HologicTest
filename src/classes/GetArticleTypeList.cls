/********************************************************************************************
    Author : Niraj
    Company : Hexaware Technologies
    Description : Fetches dynamic picklist rows
	Test Class : TestCustomKnowledgeController    

    History:
    <Date>         <Author Name>                <Brief Description of Change>  	<Copa.do US#>
	22/08/2018		Niraj						Initial Creation				US-0005634
*********************************************************************************************/
global class GetArticleTypeList extends VisualEditor.DynamicPickList{
    
    global override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('All', 'All');
        return defaultValue;
    }
    
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows  myValues = new VisualEditor.DynamicPickListRows();
        /*Get List of Record Types For Knowledge*/
        Schema.DescribeSObjectResult R = Knowledge__kav.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
        //Add default value corresponding all article types
        VisualEditor.DataRow defValue = new VisualEditor.DataRow( 'All', 'All');
        myValues.addRow(defValue);
        for( Schema.RecordTypeInfo recordType : RT )
        {
            if(recordType.Name!='Master') {
              String strRecTypeName = recordType.Name;
              Id devRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get(strRecTypeName).getRecordTypeId();
              VisualEditor.DataRow value = new VisualEditor.DataRow( strRecTypeName, strRecTypeName);
              myValues.addRow(value);
            }
        }
        return myValues;
    }
}