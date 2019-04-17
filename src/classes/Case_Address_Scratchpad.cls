public class Case_Address_Scratchpad {
    @AuraEnabled
    public static Case getAddresses(Id caseId){
        return [SELECT 
                    Qualtrics_Customer_Name__c,
                    Qualtrics_Contact_First_Name__c,
                    Qualtrics_Contact_Last_Name__c,
                    Qualtrics_Contact_Phone__c,
                    CreatedDate,
                    CaseNumber,
                    Product_Description__c,
                    Asset_Serial_Number__c,
                    Bill_To_Site_Location__r.Account__r.Parent.Name,
                    Bill_To_Site_Location__r.Address_Line_1__c,
                    Bill_To_Site_Location__r.City__c,
                    Bill_To_Site_Location__r.State__c,
                    Bill_To_Site_Location__r.Zip_Code__c,
                    Bill_To_Site_Location__r.Country__c,
                    Install_Location__r.Account__r.Parent.Name,
                    Install_Location__r.Address_Line_1__c,
                    Install_Location__r.City__c,
                    Install_Location__r.State__c,
                    Install_Location__r.Zip_Code__c,
                    Install_Location__r.Country__c
                FROM Case
                WHERE Id = :caseId];
    }
}