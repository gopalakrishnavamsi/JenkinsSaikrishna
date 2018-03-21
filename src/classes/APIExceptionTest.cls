@IsTest
private class APIExceptionTest {

	@IsTest
	static void test_constructor() {
		final APIError e1 = new APIError(APIErrorCode.INVALID_CONTENT_TYPE, 'Invalid');
		final APIException ex1 = new APIException(e1);
		final APIException ex2 = new APIException(null);
		final APIException ex3 = new APIException(APIError.generic);

		System.assertEquals(e1, ex1.error);
		System.assertEquals(e1.toString(), ex1.getMessage());
		System.assertEquals(APIError.generic, ex2.error);
		System.assertEquals(Label.SalesforceApiErrorUnexpectedResponse, ex2.getMessage());
		System.assertEquals(APIError.generic, ex3.error);
		System.assertEquals(APIError.generic.toString(), ex3.getMessage());
	}
}
