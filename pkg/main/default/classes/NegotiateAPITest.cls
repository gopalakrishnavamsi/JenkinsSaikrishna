@IsTest
public with sharing class NegotiateAPITest {

    @IsTest
    static void test_createEOSFolder_success() {
        NegotiateAPIMock.success();

        System.runAs(UserMock.createDocuSignUser()) {

            Test.startTest();
            String result = NegotiateAPI.getInstance().createEOSFolder('Edge Installation', '0061U0000058I2EQAU', 'Opportunity');
            Test.stopTest();

            System.assertNotEquals(null, result);
            System.assertEquals(NegotiateAPIMock.FOLDER_ID, result);

        }
    }

    @IsTest
    static void test_createEOSFolder_failure() {
        NegotiateAPIMock.failure();

        System.runAs(UserMock.createDocuSignUser()) {

            Test.startTest();
            try {
                NegotiateAPI.getInstance().createEOSFolder('Edge Installation', '0061U0000058I2EQAU', 'Opportunity');
                throw new AssertException('Expected createEOSFolder to fail');
            } catch (APIException ex) {
                System.assertNotEquals(null, ex.error);
                System.assertNotEquals(null, ex.error.code);
                System.assertNotEquals(null, ex.error.description);
                System.assert(ex.error instanceof NegotiateAPI.Error);
                System.assert(UUID.isNotEmpty(((NegotiateAPI.Error) ex.error).referenceId));
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void test_createAgreementInEOSFolder_success() {
        NegotiateAPIMock.success();

        System.runAs(UserMock.createDocuSignUser()) {

            Test.startTest();
            String result = NegotiateAPI.getInstance().createAgreementInEOSFolder('0061U0000058I2EQAU',
                    NegotiateAPIMock.FOLDER_ID, 'negotiate.docx');
            Test.stopTest();
            System.assertNotEquals(null, result);
            System.assertEquals('4682d399-29fe-4085-9e48-126e4ffa0566', result);
        }
    }

    @IsTest
    static void test_getAgreements_success() {
        NegotiateAPIMock.success();

        System.runAs(UserMock.createDocuSignUser()) {

            Test.startTest();
            List<Agreement> result = NegotiateAPI.getInstance().getAgreements(NegotiateAPIMock.FOLDER_ID);
            Test.stopTest();

            System.assertNotEquals(null, result);
            System.assertEquals(1, result.size());
            System.assertEquals('docusignlogerror7-23-18-1.docx', result.get(0).name);
        }
    }

    @IsTest
    static void test_renameAgreement_success() {
        NegotiateAPIMock.success();

        System.runAs(UserMock.createDocuSignUser()) {

            Test.startTest();
            Boolean result = NegotiateAPI.getInstance().renameAgreement(NegotiateAPIMock.DOCUMENT_ID, 'docuTestRename.docx');
            Test.stopTest();

            System.assertNotEquals(null, result);
            System.assertEquals(true, result);

        }
    }

    @IsTest
    static void test_deleteAgreement_success() {
        NegotiateAPIMock.success();

        System.runAs(UserMock.createDocuSignUser()) {

            Test.startTest();
            Boolean result = NegotiateAPI.getInstance().deleteAgreement(NegotiateAPIMock.DOCUMENT_ID);
            Test.stopTest();

            System.assertNotEquals(null, result);
            System.assertEquals(true, result);

        }
    }

    @IsTest
    static void test_sendForApproval_success() {
        NegotiateAPIMock.success();

        System.runAs(UserMock.createDocuSignUser()) {

            Test.startTest();
            Boolean result = NegotiateAPI.getInstance().sendForApproval('test-document 123', new List<String>{ NegotiateAPIMock.DOCUMENT_ID }, new List<String>{ NegotiateAPIMock.USER_EMAIL }, 'Test subject', 'Test message body: hello world');
            Test.stopTest();

            System.assertNotEquals(null, result);
            System.assertEquals(true, result);

        }     
    }

    @IsTest
    static void test_sendForExternalReview_success() {
        NegotiateAPIMock.success();

        System.runAs(UserMock.createDocuSignUser()) {

            Test.startTest();
            Boolean result = NegotiateAPI.getInstance().sendForExternalReview('test-document 123', new List<String>{ NegotiateAPIMock.DOCUMENT_ID }, new List<String>{ NegotiateAPIMock.USER_EMAIL }, 'Test subject', 'Test message body: hello world', 5);
            Test.stopTest();

            System.assertNotEquals(null, result);
            System.assertEquals(true, result);

        }     
    }

    @IsTest
    static void test_sendForApproval_failure() {
        NegotiateAPIMock.failure();

        System.runAs(UserMock.createDocuSignUser()) {

            Test.startTest();
            Boolean hasError = false;
            try {            
               NegotiateAPI.getInstance().sendForApproval('test-document 123', new List<String>{ NegotiateAPIMock.DOCUMENT_ID }, new List<String>{ NegotiateAPIMock.USER_EMAIL }, 'Test subject', 'Test message body: hello world');
            } catch (APIException ex) {
                
            }
            Test.stopTest();

            System.assertEquals(hasError, true);

        }     
    }

    @IsTest
    static void test_sendForExternalReview_failure() {
        NegotiateAPIMock.failure();

        System.runAs(UserMock.createDocuSignUser()) {

            Test.startTest();
            Boolean hasError = false;
            try {
                NegotiateAPI.getInstance().sendForExternalReview('test-document 123', new List<String>{ NegotiateAPIMock.DOCUMENT_ID }, new List<String>{ NegotiateAPIMock.USER_EMAIL }, 'Test subject', 'Test message body: hello world', 5);
            } catch(APIException ex) {
                hasError = true;
            }
            Test.stopTest();

            System.assertEquals(hasError, true);

        }
    }   
}