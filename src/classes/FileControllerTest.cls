@IsTest
private class FileControllerTest {

	@IsTest
	static void test_constructor() {
		Test.startTest();
		FileController result = new FileController();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(Application.lightningNamespace, result.namespace);
		System.assertEquals(Salesforce.getLightningHost(), result.lightningHost);
		System.assertEquals(Salesforce.getVisualforceHost(), result.visualforceHost);
	}
}
