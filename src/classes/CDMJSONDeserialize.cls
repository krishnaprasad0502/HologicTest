/*------------------------------------------------------------
Author:         Mani Sundaresan
Description:    JSONDeserialize class for CDM
Test Class:     CDMJSONDeserialize_Test
History:
<Date>          <Authors Name>      <Brief Description of Change>
04/10/2018      Mani Sundaresan      Initial Creation (US-4246)
-------------------------------------------------------------*/
public class CDMJSONDeserialize{
    public cls_DataQualityOrg[] DataQualityOrg;
    public class cls_DataQualityOrg {
        public String DataQualityScore; //53
        public String DataQualityRecordType;    //Result
        public String ResultCode;   //COMPLETED
        public String ResultMessage;    //SUCCESS
        public String AddressLine1 {get; set;} //123 MAIN ST
        public String AddressLine2 {get; set;}
        public String AddressLine3 {get; set;}
        public String AddressLine4 {get; set;}
        public String City {get; set;} //NORTHBROOK
        public String Country {get; set;}  //US
        public String CountrySubEntity {get; set;} //ILLINOIS
        public String OrganizationIdentifier {get; set;}   //300000008168312
        public String OrganizationName;
        public String PartySiteId {get; set;}  //300000008168313
        public String PostalCode {get; set;}  //60093
        public String PartyName {get; set;}
        public String RegistrationId {get; set;}
    }
    
    public static CDMJSONDeserialize parse(String json){
        return (CDMJSONDeserialize) System.JSON.deserialize(json, CDMJSONDeserialize.class);
    }

   
}