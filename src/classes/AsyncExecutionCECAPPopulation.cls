public class AsyncExecutionCECAPPopulation implements Queueable {

private List<Contract_Agreed_Price__c> recordsList = null; 

public AsyncExecutionCECAPPopulation(List<Contract_Agreed_Price__c> listParam){

 this.recordsList = listParam;

}  

public void execute(QueueableContext context) {

   // DML operation on records list here ( insert , delete, update ) total 10K
   upsert recordsList;

} 

 

}