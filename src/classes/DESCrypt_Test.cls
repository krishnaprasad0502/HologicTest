/*------------------------------------------------------------
Author: Mani Sundaresan

Description: Test Class for DESCrypt used for Salesforce NTLM Authentication

History:
<Date>          <Authors Name>      <Brief Description of Change>
07/17/2018      Mani Sundaresan      Initial Creation (US-0004314)
------------------------------------------------------------*/
@isTest
public class DESCrypt_Test {

    /*
     * Test the encrypt method.
     */
    static testMethod void encryptTest() {
        DESCrypt des = new DESCrypt();
        integer[] plainText = new integer[] { 72, 73, 32, 84, 72, 69, 82, 69 };
        integer[] keyBytes = new integer[] { 0, 1, 2, 3, 4, 5, 6, 7 };
        
        integer[] result = des.encrypt(keyBytes, plainText);
        
        integer[] plainText1 = new integer[] { 72, 73, 32, 84, 72, 69, 82, 69 };
        integer[] keyBytes1 = new integer[] { 128, 64, 32, 16, 8, 4, 2, 1};
        
        integer[] result1 = des.encrypt(keyBytes1, plainText1);
        
        integer[] keyBytes2 = new integer[] { 64, 32, 16, 8, 4, 2, 1, 128};
        integer[] keyBytes3 = new integer[] { 32, 16, 8, 4, 2, 1, 128, 64};
        integer[] keyBytes4 = new integer[] { 16, 8, 4, 2, 1, 128, 64, 32};
        integer[] keyBytes5 = new integer[] { 8, 4, 2, 1, 128, 64, 32, 16};
        integer[] keyBytes6 = new integer[] { 4, 2, 1, 128, 64, 32, 16, 8};
        integer[] keyBytes7 = new integer[] { 2, 1, 128, 64, 32, 16, 8, 4};
        integer[] keyBytes8 = new integer[] { 1, 128, 64, 32, 16, 8, 4, 2};
        
        integer[] result2 = des.encrypt(keyBytes2, plainText1);
        integer[] result3 = des.encrypt(keyBytes3, plainText1);
        integer[] result4 = des.encrypt(keyBytes4, plainText1);
        integer[] result5 = des.encrypt(keyBytes5, plainText1);
        integer[] result6 = des.encrypt(keyBytes6, plainText1);
        integer[] result7 = des.encrypt(keyBytes7, plainText1);
        integer[] result8 = des.encrypt(keyBytes8, plainText1);
        
        
        System.assertEquals(183, result[0], 'result[0] isn\'t 183.');
        System.assertEquals(106, result[1], 'result[1] isn\'t 106.');
        System.assertEquals(35, result[2], 'result[2] isn\'t 35.');
        System.assertEquals(71, result[3], 'result[3] isn\'t 71.');
        System.assertEquals(105, result[4], 'result[4] isn\'t 105.');
        System.assertEquals(106, result[5], 'result[5] isn\'t 106.');
        System.assertEquals(126, result[6], 'result[6] isn\'t 126.');
        System.assertEquals(99, result[7], 'result[7] isn\'t 99.');
        
    }
    
}