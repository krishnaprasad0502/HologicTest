/*--------------------------------------------------------------------------------------------------------------
Author:         Kasmoor Reddy
Description:    Class which supports the lightening component PopulateGeolocation to populate the geolocation
                based on the address on external website contacts.

History:
<Date>          <Authors Name>         <Brief Description of Change>
12/11/2017      Kasmoor Reddy          Initial Creation (US3673)
----------------------------------------------------------------------------------------------------------------*/
public class PopulateLocation {
  
   @AuraEnabled
    public static void contactAddress(id externalcontactid){
   
        External_Website_Contacts__c ExternalContactget = [select id,Street_Address__c,Street_Address_2__c,City__c,State__c,Country__c,Zip_Code__c from External_Website_Contacts__c where Id=:externalcontactid];
        String address = '';
        if (ExternalContactget.Street_Address__c != null)
            address += ExternalContactget.Street_Address__c +', ';
        if (ExternalContactget.Street_Address_2__c != null)
            address += ExternalContactget.Street_Address_2__c +', ';
        if (ExternalContactget.City__c != null)
            address += ExternalContactget.City__c +', ';
        if (ExternalContactget.State__c != null)
            address += ExternalContactget.State__c +', ';
		if (ExternalContactget.Country__c != null)
            address += ExternalContactget.Country__c +'  ';
        if (ExternalContactget.Zip_Code__c != null)
            address += ExternalContactget.Zip_Code__c;

        address = EncodingUtil.urlEncode(address, 'UTF-8');
        
         // build callout
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('http://maps.googleapis.com/maps/api/geocode/json?address='+address+'&sensor=false');
        req.setMethod('GET');
        req.setTimeout(60000);

        try{
		   system.debug('req---'+req);
            // callout
            HttpResponse res = h.send(req);
			system.debug('res---'+res);
			system.debug('resbody---'+res.getBody());
            
            // parse coordinates from response
            JSONParser parser = JSON.createParser(res.getBody());
			system.debug('parser---'+parser);
			system.debug('parsertoken---'+parser.nextToken());
            system.debug('parsertoken---'+parser.getCurrentToken());
            system.debug('parsertoken---'+JSONToken.FIELD_NAME);
            system.debug('parsertoken---'+parser.getText());
             



            double lat = null;
            double lon = null;
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                    (parser.getText() == 'location')){
                       parser.nextToken(); // object start
                       while (parser.nextToken() != JSONToken.END_OBJECT){
                           String txt = parser.getText();
                           parser.nextToken();
                           if (txt == 'lat')
                               lat = parser.getDoubleValue();
                           else if (txt == 'lng')
                               lon = parser.getDoubleValue();
                       }

                }
            }
			system.debug('lat---'+lat);
			system.debug('lon---'+lon);
            // update coordinates if we get back
            if (lat != null && lon != null){
                ExternalContactget.Office_Location__Latitude__s  = lat;
                ExternalContactget.Office_Location__Longitude__s  = lon;
                system.debug('ExternalContactget.Office_Location__Latitude__s----'+ExternalContactget.Office_Location__Latitude__s);
                system.debug('ExternalContactget.Office_Location__Longitude__s----'+ExternalContactget.Office_Location__Longitude__s);
                update ExternalContactget;
            }
            
			} catch (Exception e) {
                
        }
        
    }
}