@IsTest(isParallel = true)
private class ValidationExceptionTest {

	@IsTest
	static void test_constructor() {
		UUID u = UUID.randomUUID();
		System.assertEquals('message\n' + u, new ValidationException('message', u).getMessage());
		System.assertEquals('message', new ValidationException('message', null).getMessage());
	}
}
