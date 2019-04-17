public class SecretKeyJsonDeserialize {

    public String statusCode;
    public String statusMessage;
    public List<String> issuers;
    public String account;
    public String issuer;
    public String secret;
    public String uri;
    public String validFrom;
    public String validTo;
    public String statusMsg;
    public list<code> codes;
    
    public class code {
        public string account;
        public string issuer;
        public string secret;
        public string uri;
        public string validFrom;
        public string validTo;
        public string statusCode;
        public string statusMsg;
    }



    
    public static SecretKeyJsonDeserialize parse(String json) {
        return (SecretKeyJsonDeserialize) System.JSON.deserialize(json, SecretKeyJsonDeserialize.class);
    }
}