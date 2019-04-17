@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
   
    global HTTPResponse respond(HTTPRequest req) {
                HttpResponse res = new HttpResponse();

            string address;
         address = '250 CAMPUS DRIVE,MARLBOROUGH,MA,US 01752';
        System.assertEquals('http://maps.googleapis.com/maps/api/geocode/json?address=12201+Renfert+Way%2C+Ste+205%2C+Austin%2C+TX%2C+US++78758&sensor=false', req.getEndpoint());
        System.assertEquals('GET', req.getMethod());
       
        res.setHeader('Content-Type', 'application/json');
        res.setBody('[{"address_components" : [{"long_name" : "250","short_name" : "250","types" : [ "street_number" ]},{"long_name" : "Campus Drive","short_name" : "Campus Dr","types" : [ "route" ]},{"long_name" : "Marlborough","short_name" : "Marlboro","types" : [ "locality", "political" ]},{"long_name" : "Middlesex County","short_name" : "Middlesex County","types" : [ "administrative_area_level_2", "political"]},{"long_name" : "Massachusetts","short_name" : "MA","types" : [ "administrative_area_level_1", "political" ]},{"long_name" : "United States","short_name" : "US","types" : [ "country", "political" ]},{"long_name" : "01752","short_name" : "01752","types" : [ "postal_code" ]},{"long_name" : "3020","short_name" : "3020","types" : [ "postal_code_suffix" ]}],"formatted_address" : "250 Campus Dr, Marlborough, MA 01752, USA","geometry" : {"bounds" : {"northeast" : {"lat" : 42.3256563,"lng" : -71.5826936},"southwest" : {"lat" : 42.3244072,"lng" : -71.5837178}},"location" : {"lat" : 42.3250317,"lng" : -71.58320569999999},"location_type" : "ROOFTOP","viewport" : {"northeast" : {"lat" : 42.3263807302915,"lng" : -71.5818567197085},"southwest" : {"lat" : 42.3236827697085,"lng" : -71.5845546802915}}},"place_id" : "ChIJh-qL2Cf144kRb7tz8x5dPg0","types" : [ "premise" ]}],"status" : "OK"}');
        res.setStatusCode(200);
        return res;
        
    }
}