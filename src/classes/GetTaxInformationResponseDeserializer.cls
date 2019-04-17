public class GetTaxInformationResponseDeserializer{
    public QuoteHeader header;
    public QuoteLines[] lines;
    
    public class QuoteHeader {
        public String headerId;
        public String status;
        public String statusMsg;
    }
    
    public class QuoteLines {
        public String lineId;
        public Decimal taxRate;
        public Decimal taxAmount;
    }
    
    public static GetTaxInformationResponseDeserializer parse(String json){
        return (GetTaxInformationResponseDeserializer) System.JSON.deserialize(json, GetTaxInformationResponseDeserializer.class);
    }

}