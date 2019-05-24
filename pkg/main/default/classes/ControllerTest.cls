@IsTest(IsParallel = true)
private class ControllerTest {

	@IsTest
	static void test_properties() {
		Controller c = new Controller();
		System.assertNotEquals(null, c);
		System.assertEquals(Application.namespace, c.namespace);
	}

	@IsTest
	static void test_getErrorMessage() {
		System.assertEquals(Label.UnauthorizedUser, Controller.getErrorMessage(new UnauthorizedException('test')));
		System.assertEquals(Label.AccountNotConfigured, Controller.getErrorMessage(UnauthorizedException.accountNotConfigured()));
		System.assertEquals('test', Controller.getErrorMessage(new DocuSignException('test')));
	}

	@IsTest
	static void test_wrapException_message() {
		AuraHandledException result = Controller.wrapException('test');
		System.assertNotEquals(null, result);
		System.assertEquals('test', result.getMessage());
	}

	@IsTest
	static void test_wrapException_exception() {
		System.assertEquals(Label.UnauthorizedUser, Controller.wrapException(new UnauthorizedException('test'), 'ctx').getMessage());
		System.assertEquals(Label.AccountNotConfigured, Controller.wrapException(UnauthorizedException.accountNotConfigured(), 'ctx').getMessage());
		System.assertEquals('test', Controller.wrapException(new DocuSignException('test'), 'ctx').getMessage());
	}
}
