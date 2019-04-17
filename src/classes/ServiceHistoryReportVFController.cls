/****************************************************************************************
    Author : Niraj
    Company : Hexaware Technologies
    Description : Service History Report VF Page Controller
    Test Class : ServiceHistoryReportVFController_Test    

    History:
    <Date>         <Author Name>      <Brief Description of Change>     <Copa.do US#>
    8/22/2018      Niraj            Initial Creation                     US-0005791
****************************************************************************************/
public class ServiceHistoryReportVFController {
    
    public String PDFData {get; set;} 
    public ServiceReportController.Master finalReportData {get; set;}
    public List<ServiceReportController.asset_Wrapper> finalAssetWrapper {get; set;}
    public List<Account> accountList {get; set;}
    public String sObjectRT {get; set;}
    public String accountAddress {get; set;}
    public Boolean includePricing {get; set;}
    
    public ServiceHistoryReportVFController(){
        PDFData = '';
    }
    
    public PageReference downloadPDF(){
        System.PageReference pageRef = new System.PageReference('/apex/ServiceHistoryReportPDF');
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(PDFData);
        String assetData = (String) m.get('finalassetdata');  
        system.debug('assetData: ' + assetData);
        finalReportData = (ServiceReportController.Master) System.JSON.deserialize(assetData, ServiceReportController.Master.class);
        finalAssetWrapper = finalReportData.assetWrapper;
        sObjectRT = finalReportData.sObjectRT;
        accountList = finalReportData.accountList;
        accountAddress = finalReportData.accountAddress;
        system.debug('finalAssetWrapper:' + finalAssetWrapper);
       //ensure pdf downloads and is assigned with defined name
        pageRef.getHeaders().put('content-disposition', 'attachment; filename=ServiceHistoryReport.pdf');
     
        return pageRef;
    }
}