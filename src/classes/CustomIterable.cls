/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description:  A Custom Iterator class which should implement Iterator class for wrapper class     
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>       <Brief Description of Change>
    06/15/2017      Kasmoor Reddy        Initial Creation (US2752)
-----------------------------------------------------------------------------------*/
global class CustomIterable implements Iterator<list<ContactWrapper>>
{ 
    //wrapper list declarations
    list<ContactWrapper> InnerList{get; set;}
    list<ContactWrapper> ListRequested{get; set;}
    //Variable declarations
    Integer i {get; set;} 
    public Integer setPageSize {get; set;}
    
/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Constructor for Variable initializion and setting the pagesize
                 to display the contacts on vf page for pagination. 
    Returns:     N/A
      
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    06/15/2017      Kasmoor Reddy              Initial Creation (US2752)
    -----------------------------------------------------------------------------------*/
   public CustomIterable(List<ContactWrapper> lstAccWr)
   {
       InnerList = new list<ContactWrapper >(); 
       ListRequested = new list<ContactWrapper >();     
       InnerList = lstAccWr;
       setPageSize = 10;
       i = 0;
       
   }
    
   
/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: assigning the boolean value to Hasnext method pagination for checking the list of contacts size . 
    Returns:     N/A
      
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    06/15/2017      Kasmoor Reddy              Initial Creation (US2752)
    -----------------------------------------------------------------------------------*/
   global boolean hasNext(){ 
       if(i >= InnerList.size()) {
           return false; 
       } else {
           return true; 
       }
   } 
 /*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: assigning the boolean value to hasprevious method pagination for checking the list of contacts size . 
    Returns:     N/A
      
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    06/15/2017      Kasmoor Reddy              Initial Creation (US2752)
-----------------------------------------------------------------------------------*/  
   global boolean hasPrevious(){ 
       system.debug('I am in hasPrevious' + i);
       if(i <= setPageSize) {
           return false; 
       } else {
           return true; 
       }
   }

/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: declaring the contactwrapper list to next method pagination for checking the list of contacts size . 
    Returns:     N/A
      
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    06/15/2017      Kasmoor Reddy              Initial Creation (US2752)
-----------------------------------------------------------------------------------*/ 
   global list<ContactWrapper > next(){       
       system.debug('i value is ' + i);
       ListRequested = new list<ContactWrapper >(); 
       integer startNumber;
       integer size = InnerList.size();
       if(hasNext())
       {  
           if(size <= (i + setPageSize))
           {
               startNumber = i;
               i = size;
           }
           else
           {
               i = (i + setPageSize);
               startNumber = (i - setPageSize);
           }
           
           
           
           for(integer start = startNumber; start < i; start++)
           {
               ListRequested.add(InnerList[start]);
           }
       } 
       system.debug('InnerList'+InnerList);
       
       system.debug('ListRequested'+ListRequested);
       return ListRequested;
   } 
 /*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: declaring the contactwrapper list to Previous method pagination for checking the list of contacts size . 
    Returns:     N/A
      
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    06/15/2017      Kasmoor Reddy              Initial Creation (US2752)
    -----------------------------------------------------------------------------------*/   
   global list<ContactWrapper > previous(){
       system.debug('i value is ' + i);
       ListRequested = new list<ContactWrapper >(); 
       integer size = InnerList.size(); 
       if(i == size)
       {
           if(math.mod(size, setPageSize) > 0)
           {    
               i = size - math.mod(size, setPageSize);
               
           }
           else
           {
               i = (size - setPageSize);
           } 
       }
       else
       {
           i = (i - setPageSize);
       }
       
       
       
       for(integer start = (i - setPageSize); start < i; )
       {
           system.debug('start======'+start);
           if(start >= 0){
           ListRequested.add(InnerList[start]);
           }   
           start++;
       } 
       
       return ListRequested;
   }   
}