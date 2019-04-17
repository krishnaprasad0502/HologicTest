@isTest
private class FSL_AccountSampleTypes_Test {
    
    @isTest static void sampleTypeReturned() {
        // Implement test code
        String result = FSL_AccountSampleTypes.getTypes();
        if(result != null)
            System.assertEquals(15, result.length(), 'A 15-digit ID was not returned');
    }
}