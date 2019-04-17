/*------------------------------------------------------------
Author:         Mani Sundaresan
Description:    Test class for CDMJSONDeserialize

History:
<Date>          <Authors Name>      <Brief Description of Change>
04/10/2018      Mani Sundaresan      Initial Creation (US-4246)
-------------------------------------------------------------*/
@IsTest
public class CDMJSONDeserialize_Test {
    
    static testMethod void testParse() {
        String json = '{'+
        '  \"DataQualityOrg\": ['+
        '    {'+
        '      \"DataQualityScore\": \"93\",'+
        '      \"DataQualityRecordType\": \"Result\",'+
        '      \"ResultCode\": \"COMPLETED\",'+
        '      \"ResultMessage\": \"SUCCESS\",'+
        '      \"AddressLine1\": \"123 JEFF ST\",'+
        '      \"AddressLine2\": null,'+
        '      \"AddressLine3\": null,'+
        '      \"AddressLine4\": null,'+
        '      \"City\": \"NORTHBROOK\",'+
        '      \"Country\": \"US\",'+
        '      \"CountrySubEntity\": \"ILLINOIS\",'+
        '      \"OrganizationIdentifier\": \"300000008168183\",'+
        '      \"OrganizationName\": \"TEST\",'+
        '      \"PartySiteId\": \"300000008168184\",'+
        '      \"PostalCode\": \"60093\"'+
        '    },'+
        '    {'+
        '      \"DataQualityScore\": \"93\",'+
        '      \"DataQualityRecordType\": \"Result\",'+
        '      \"ResultCode\": \"COMPLETED\",'+
        '      \"ResultMessage\": \"SUCCESS\",'+
        '      \"AddressLine1\": \"123 Main St\",'+
        '      \"AddressLine2\": null,'+
        '      \"AddressLine3\": null,'+
        '      \"AddressLine4\": null,'+
        '      \"City\": \"NORTHBROOK\",'+
        '      \"Country\": \"US\",'+
        '      \"CountrySubEntity\": \"ILLINOIS\",'+
        '      \"OrganizationIdentifier\": \"300000008701906\",'+
        '      \"OrganizationName\": \"TEST\",'+
        '      \"PartySiteId\": \"300000008701991\",'+
        '      \"PostalCode\": \"60093\"'+
        '    },'+
        '    {'+
        '      \"DataQualityScore\": \"93\",'+
        '      \"DataQualityRecordType\": \"Result\",'+
        '      \"ResultCode\": \"COMPLETED\",'+
        '      \"ResultMessage\": \"SUCCESS\",'+
        '      \"AddressLine1\": \"123 MAIN ST\",'+
        '      \"AddressLine2\": null,'+
        '      \"AddressLine3\": null,'+
        '      \"AddressLine4\": null,'+
        '      \"City\": \"WILMETTE\",'+
        '      \"Country\": \"US\",'+
        '      \"CountrySubEntity\": \"ILLINOIS\",'+
        '      \"OrganizationIdentifier\": \"300000008877291\",'+
        '      \"OrganizationName\": \"TEST\",'+
        '      \"PartySiteId\": \"300000008877296\",'+
        '      \"PostalCode\": \"60093\"'+
        '    },'+
        '    {'+
        '      \"DataQualityScore\": \"93\",'+
        '      \"DataQualityRecordType\": \"Result\",'+
        '      \"ResultCode\": \"COMPLETED\",'+
        '      \"ResultMessage\": \"SUCCESS\",'+
        '      \"AddressLine1\": \"123 MAIN ST\",'+
        '      \"AddressLine2\": null,'+
        '      \"AddressLine3\": null,'+
        '      \"AddressLine4\": null,'+
        '      \"City\": \"NORTHFIELD\",'+
        '      \"Country\": \"US\",'+
        '      \"CountrySubEntity\": \"ILLINOIS\",'+
        '      \"OrganizationIdentifier\": \"300000008877767\",'+
        '      \"OrganizationName\": \"TEST\",'+
        '      \"PartySiteId\": \"300000008877770\",'+
        '      \"PostalCode\": \"60093\"'+
        '    }'+
        '  ]'+
        '}';
        CDMJSONDeserialize obj = CDMJSONDeserialize.parse(json);
        
        System.assert(obj != null);
    }
}