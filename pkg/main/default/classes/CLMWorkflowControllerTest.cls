@IsTest
private with sharing class CLMWorkflowControllerTest {
    
    @IsTest
    static void test_getWorkflowLink_authorized() {
        DocuSignAPIMock.success();
        System.runAs(UserMock.createClmUser()) {      
            Test.startTest();
            system.assertNotEquals(null,CLMWorkflowController.getWorkflowButtonLink());
            Test.stopTest();    
        }
    }
    
    @IsTest
    static void test_getWorkflowLink_unauthorized() {
        DocuSignAPIMock.success();
        System.runAs(UserMock.createUser()) {    
            Test.startTest();
            try {
                CLMWorkflowController.getWorkflowButtonLink();
            }
            catch (exception e) {
                system.assertEquals(Label.MustBeClmUser, e.getMessage());
            }            
            Test.stopTest();    
        }
    }    
}