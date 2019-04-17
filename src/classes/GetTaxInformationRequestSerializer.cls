public class GetTaxInformationRequestSerializer{
    public QuoteHeader header;
    public QuoteLines[] lines;
    
    public class QuoteHeader {
        public String headerId;
        public String orgCode;

    }
    
    public class QuoteLines {
        public String lineId;
        public Integer itemId;
        public String itemNumber;
        public Double qty;
        public Double price;
        public Integer shipToId;
        public Integer invoiceToId;   
    }
    
    public static GetTaxInformationRequestSerializer parse(String json){
        return (GetTaxInformationRequestSerializer) System.JSON.deserialize(json, GetTaxInformationRequestSerializer.class);
    }
}