/*------------------------------------------------------------
Author:         John Christy
Company:        Apps Associates
Description:    Controller for AssetAttributesUpdate page to query asset based on serial number or based on record id in url then
				returns Asset Attributes for editing values.
Test Class:     AssetAttributesUpdateController_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
07/11/2017      John Christy        Initial Creation (US-0003373)
------------------------------------------------------------*/

public class AssetAttributesUpdateController {
    public Id idURL {get;set;}
    public String serialNumber{get;set;}
    List<Asset_Attribute__c> myAssetAttributes = new List<Asset_Attribute__c>();
    List<SelectOption> selectOptions = new List<SelectOption>();
    
    // get asset record based on serial number search or current record id, return to page
    public Asset getAsset(){
        if(!Test.isRunningTest())
            idURL = ApexPages.currentPage().getParameters().get('id');
        System.debug('idURL: ' + idURL);
        if(String.isBlank(serialNumber) && String.isBlank(idURL))
            return null;
        else{
            serialNumber = serialNumber + ' ';
            return [SELECT Name, Customer_Account__r.Name, Oracle_System_ID__c, Description, Product2.Name,
                    Install_Location__r.Address_Line_1__c, Install_Location__r.Address_Line_2__c, Install_Location__r.Address_Line_3__c, 
                    Install_Location__r.Address_Line_4__c, Install_Location__r.City__c, Install_Location__r.State__c, Install_Location__r.Zip_Code__c, 
                    Install_Location__r.Country__c, Bill_To_Location__r.Address_Line_1__c, Bill_To_Location__r.Address_Line_2__c, 
                    Bill_To_Location__r.Address_Line_3__c, Bill_To_Location__r.Address_Line_4__c, Bill_To_Location__r.City__c, 
                    Bill_To_Location__r.State__c, Bill_To_Location__r.Zip_Code__c, Bill_To_Location__r.Country__c, 
                    Ship_To_Location__r.Address_Line_1__c, Ship_To_Location__r.Address_Line_2__c, Ship_To_Location__r.Address_Line_3__c, Ship_To_Location__r.Address_Line_4__c, 
                    Ship_To_Location__r.City__c, Ship_To_Location__r.State__c, Ship_To_Location__r.Zip_Code__c, Ship_To_Location__r.Country__c
                    FROM Asset
                    WHERE SerialNumber = :serialNumber.trim() OR Id = :idURL
                    LIMIT 1];
        }
    }
    
    // get asset attributes based on asset serial number or current record id
    public List<Asset_Attribute__c> getAssetAttributes(){
        String dbQuery;
        if(!String.isBlank(idURL))
            dbQuery = 'WHERE Asset__r.Id = \'' + idURL + '\' ';
        else if(!String.isBlank(serialNumber))
            dbQuery = 'WHERE Asset__r.SerialNumber = \'' + serialNumber.trim() + '\' ';
        else
            dbQuery = null;
        
        if(dbQuery != null){
            myAssetAttributes = Database.query(
                'SELECT Name, Asset__r.Product2.Name, Category__c, Value__c ' +
                'FROM Asset_Attribute__c ' +
                dbQuery
            );
            return myAssetAttributes;
        }
        else
            return null;
    }
    
    public PageReference save(){
        Update myAssetAttributes;
        if(!String.isBlank(idURL)){
            PageReference pageRef = new PageReference('/' + idURL);
            return pageRef.setRedirect(true);
        }
        else
            return null;
    }
}