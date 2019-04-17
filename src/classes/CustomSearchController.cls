/**************************************************************************************
Author:Sunil Kumar Sharma
Company:Hexaware Technologies
Description: This class contains method to search the text in specified objects for all fields

TestClass: CustomSearchController_Test

History:
<Date>              <Author Name>        <Brief description of change >     <Copa.do US#>
07/09/2018          Sunil Kumar Sharma   Initial creation                   US-0005633
****************************************************************************************/
public class CustomSearchController {
    /*
     * Method Name: searchForIds()
     * Input Param: String
     * Return: List<String> 
     * Description: This method is created to provide list of different object records based on search text.
     */
    @AuraEnabled
    public static List<String> searchForIds(String searchText) {
        List<List<SObject>> results = [FIND :searchText IN ALL FIELDS  RETURNING Account(Id), Campaign(Id), Contact(Id), Lead(Id)];
        List<String> ids = new List<String>();
        for (List<SObject> sobjs : results) {
          for (SObject sobj : sobjs) { ids.add(sobj.Id);
          }
        }
        return ids;
    }
}