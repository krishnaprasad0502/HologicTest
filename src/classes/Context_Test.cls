/**************************************************************************************
Author : Nikhil
Company : Hexaware Technologies
Description : Helper class for List Controller to access Custom Metadata
Test Class : ListControllerTest
History:
<Date>         <Author Name>          <Brief Description of Change>     <Copa.do US#>
23/08/2018      Nikhil                 Initial creation                 US-0005633

04/16/2019        Krishna             (US-0006815)Implement status mapping via metadata    
****************************************************************************************/
public class Context_Test {
    //public static String testCase {public get; public set;}
    @testVisible static list<Service_Community_Menu__mdt> customMetadata = new List<Service_Community_Menu__mdt>();
    @testVisible static list<Community_User_Mapper__mdt> communityMapperData = new List<Community_User_Mapper__mdt>();
    //04/16/2019        Krishna             (US-0006815)Implement status mapping via metadata    
    @testVisible static list<WoSa_Status__mdt> WoSaStatusData = new List<WoSa_Status__mdt>();
}