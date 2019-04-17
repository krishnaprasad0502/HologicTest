@isTest
public class AssetAttributesPicklistController_Test {
    public static AssetAttributePicklistController testController = new AssetAttributePicklistController();
    public static Asset_Attribute_Reference__c testPicklist = new Asset_Attribute_Reference__c ();
    public static Asset_Attribute_Reference__c testDate = new Asset_Attribute_Reference__c ();
    public static Asset_Attribute_Reference__c testCheckbox = new Asset_Attribute_Reference__c ();

    static{
        // create custom settings for asset attribute test
        insert new Asset_Attribute_Settings__c(Name = 'Operating System', Editable__c = true, Picklist__c = true, Checkbox__c = false, Date__c = false, Textbox__c = false);
        insert new Asset_Attribute_Settings__c(Name = 'Date Of Service', Editable__c = true, Picklist__c = false, Checkbox__c = false, Date__c = true, Textbox__c = false);
        insert new Asset_Attribute_Settings__c(Name = 'Channel', Editable__c = false, Picklist__c = false, Checkbox__c = true, Date__c = false, Textbox__c = false);
        
        // create asset attribute reference test data
        testPicklist.Category__c = 'System4';
        testPicklist.Attribute_Name__c = 'Operating System';
        testPicklist.Asset_Attribute_Value__c = 'DOS';
        insert testPicklist;
        
        testDate.Category__c = 'System4';
        testDate.Attribute_Name__c = 'Date Of Service';
        testDate.Asset_Attribute_Value__c = '01/01/2017';
        insert testDate;
        
        testCheckbox.Category__c = 'System4';
        testCheckbox.Attribute_Name__c = 'Channel';
        testCheckbox.Asset_Attribute_Value__c = 'true';
        insert testCheckbox;
    }
    
    // test picklist that is editable true/false
    @isTest
    public static void testPicklist(){
        testController.selectValue = testPicklist.Asset_Attribute_Value__c;
        testController.labelValue = testPicklist.Attribute_Name__c;
        testController.picklistValue = testPicklist.Attribute_Name__c;
        testController.categoryValue = testPicklist.Category__c;
        testController.getPickListValues();
        testController.getIsEditable();
        testController.getDataType();
        testController.getIsPicklist();
        
        // update Editable value on picklist setting to false
        Asset_Attribute_Settings__c operatingSystem = Asset_Attribute_Settings__c.getOrgDefaults(); 
        operatingSystem.Editable__c = false;
        update operatingSystem;
        
        // test if not editable picklist
        testController.picklistValue = testPicklist.Attribute_Name__c;
        testController.categoryValue = testPicklist.Category__c;
        testController.getPickListValues();
        testController.getIsEditable();
        testController.getDataType();
        testController.getIsPicklist();
    }
    
    // test date
    @isTest
    public static void testDate(){
        testController.picklistValue = testDate.Attribute_Name__c;
        testController.getIsEditable();
        testController.getDataType();
        testController.getIsPicklist();
    }
    
    // test checkbox
    @isTest
    public static void testCheckbox(){
        testController.picklistValue = testCheckbox.Attribute_Name__c;
        testController.getIsEditable();
        testController.getDataType();
        testController.getIsPicklist();
    }
}