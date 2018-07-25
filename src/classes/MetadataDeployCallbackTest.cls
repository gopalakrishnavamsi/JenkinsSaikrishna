@IsTest
private class MetadataDeployCallbackTest {

	@IsTest
	static void test_handleResult() {
		MetadataDeployCallback cb = new MetadataDeployCallback();

		Test.startTest();
		cb.handleResult(new Metadata.DeployResult(), new Metadata.DeployCallbackContext());
		Test.stopTest();

		// Nothing to verify here as the callback simply logs the result.
		System.assertNotEquals(null, cb);
	}
}
