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
                System.assert(UUID.isNotEmpty(((NegotiateAPI.Error)ex.error).referenceId));
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void test_getAgreements_success() {
        NegotiateAPIMock.success();

        System.runAs(UserMock.createDocuSignUser()) {

            Test.startTest();
            List<Agreement> result = NegotiateAPI.getInstance().getAgreements(NegotiateAPIMock.FOLDER_ID);
            System.debug(result);
            Test.stopTest();

            System.assertNotEquals(null, result);
            System.assertEquals(1, result.size());
            System.assertEquals('docusignlogerror7-23-18-1.docx', result.get(0).name);
        }
    }

}