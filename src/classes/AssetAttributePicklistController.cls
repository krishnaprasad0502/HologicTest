/*------------------------------------------------------------
Author:         John Christy
Company:        Apps Associates
Description:    Controls the Custom Component for populating Attribute picklists and input fields(AssetAttributePicklist)
Test Class:     AssetAttributesPicklistController_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
07/11/2017      John Christy        Initial Creation (US-0003373)
------------------------------------------------------------*/

public class AssetAttributePicklistController {
    
    public String idValue{get;set;}
    public String categoryValue{get;set;}
    public String picklistValue{get;set;}
    public String selectValue{get;set;}
    public String labelValue{get;set;}
    
    public List<SelectOption> selectOptions = new List<SelectOption>();
    
    // initial getter method used to pass query parameters to getSelectOptions
    public List<SelectOption> getPickListValues(){
        return getSelectOptions(picklistValue, categoryValue);
    }
    
    // populates picklist items via the Asset Attribute Reference custom object
    public List<SelectOption> getSelectOptions(String pickListName, String category) {
        List<Asset_Attribute_Reference__c> entries = 
            [select Name, Attribute_Name__c, Asset_Attribute_Value__c,  Category__c
            from Asset_Attribute_Reference__c 
            where Attribute_Name__c = :pickListName and Category__c = :category 
            order by Asset_Attribute_Value__c ];
        selectOptions.add(new SelectOption('','--None--'));
        for(Asset_Attribute_Reference__c e : entries)
            selectOptions.add(new SelectOption(e.Asset_Attribute_Value__c, e.Asset_Attribute_Value__c ));
        
        return selectOptions;
    }
    
    // used to determine whether or not the picklist/text field is disabled
    public Boolean getIsEditable(){
        Boolean disabled = true;
        Asset_Attribute_Settings__c assetSettings = Asset_Attribute_Settings__c.getValues(picklistValue);
        if(assetSettings != null)
            disabled = !assetSettings.Editable__c;
        return disabled;
    }
    
    // used to determine the field datatype, defaults to a text field
    public String getDataType(){
        String type = 'text';
        Asset_Attribute_Settings__c assetSettings = Asset_Attribute_Settings__c.getValues(picklistValue);
        System.debug('Asset Settings: ' + assetSettings);
        if(assetSettings != null){
            system.debug('date - ' + assetSettings.Date__c);
            if(assetSettings.Date__c)
                type = 'date';
            else if(assetSettings.Checkbox__c)
                type = 'checkbox';
        }
        return type;
    }
    
    // used to determine whether the field is a picklist otherwise defaults to a text field
    public Boolean getIsPicklist(){
        Asset_Attribute_Settings__c assetSettings = Asset_Attribute_Settings__c.getValues(picklistValue);
        if(assetSettings != null && assetSettings.Picklist__c)
            return true;
        else
            return false;
    }
}