@IsTest
public class SecretKeyJsonDeserialize_Test {

    
    static testMethod void testParse() {

        String json = '{'+
        '    \"account\": \"Jan 2019 - ALaack\",'+
        '    \"issuer\": \"Hologic DX\",'+
        '    \"secret\": \"HGKX JCVV 3MT6 PTQV DJBN E5LA VTUJ ABHH\",'+
        '    \"uri\": \"otpauth://totp/Hologic%20Dashboard%20FSE%20(version%201.0):Jan%202019%20-%20ALaack?secret=HGKXJCVV3MT6PTQVDJBNE5LAVTUJABHH&algorithm=SHA1&issuer=Hologic%20Dashboard%20FSE%20(version%201.0)\",'+
        '    \"validFrom\": \"12/25/2018\",'+
        '    \"validTo\": \"02/07/2019\",'+
        '    \"statusCode\": \"Y\"'+
        '}';
        SecretKeyJsonDeserialize obj = SecretKeyJsonDeserialize.parse(json);
        System.assert(obj != null);
    }
}