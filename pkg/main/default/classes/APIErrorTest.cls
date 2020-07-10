@IsTest(IsParallel = true)
private class APIErrorTest {

	@IsTest
	static void test_constructor() {
		final APIError e = new APIError(APIErrorCode.NULL_RESPONSE, 'Null response');
		System.assertEquals(APIErrorCode.NULL_RESPONSE, e.code);
		System.assertEquals('Null response', e.description);
	}

	@IsTest
	static void test_equality() {
		final APIError e1 = new APIError(APIErrorCode.UNAUTHORIZED, 'Unauthorized');
		final APIError e2 = new APIError(APIErrorCode.UNAUTHORIZED, 'Unauthorized');
		final APIError e3 = new APIError(APIErrorCode.UNAUTHORIZED, 'Go away');
		final APIError e4 = new APIError(APIErrorCode.BAD_REQUEST, 'Unauthorized');
		final APIError e5 = new APIError(APIErrorCode.SUCCESS, '  ');
		final APIError e6 = new APIError(APIErrorCode.FAILURE, null);
		final APIError e7 = new APIError(APIErrorCode.NOT_FOUND, null);
		final APIError e8 = new APIError(APIErrorCode.UNAUTHORIZED, null);

		System.assertEquals(e1, e1);
		System.assertEquals(e1, e2);
		System.assertEquals(e1.hashCode(), e2.hashCode());
		System.assertEquals(e1, e3);
		System.assertEquals(e1.hashCode(), e3.hashCode());
		System.assertNotEquals(e1, e4);
		System.assertNotEquals(e1.hashCode(), e4.hashCode());
		System.assertNotEquals(null, e1);
		System.assertEquals(APIError.none, e5);
		System.assertEquals(APIError.none.hashCode(), e5.hashCode());
		System.assertEquals(APIError.generic, e6);
		System.assertEquals(APIError.notFound, e7);
		System.assertEquals(APIError.unauthorized, e8);
	}

	@IsTest
	static void test_toString() {
		final APIError e1 = new APIError(APIErrorCode.UNSUPPORTED_MEDIA_TYPE, 'Unsupported media type');
		final APIError e2 = new APIError(APIErrorCode.UNPROCESSABLE_ENTITY, '');
		final APIError e3 = new APIError(APIErrorCode.INTERNAL_SERVER_ERROR, '\t');
		final APIError e4 = new APIError(APIErrorCode.NOT_FOUND, null);
		final APIError e5 = new APIError(-1, 'Successful');

		System.assertEquals('Unsupported media type', e1.toString());
		System.assertEquals('', e2.toString());
		System.assertEquals('', e3.toString());
		System.assertEquals('', e4.toString());
		System.assertEquals('Successful', e5.toString());
	}

	@IsTest
	static void test_fromException() {
		APIException apiEx = new APIException(new APIError(APIErrorCode.UNSUPPORTED_MEDIA_TYPE, 'UNSUPPORTED'));
		ValidationException vEx = new ValidationException('INVALID');
		UnauthorizedException uaEx = new UnauthorizedException('UNAUTHORIZED');
		DmlException dmlEx1 = new DmlException('Uh-oh, storage limit exceeded');
		DmlException dmlEx2 = new DmlException('DML');
		StringException sEx = new StringException('STRING');

		System.assertEquals(APIErrorCode.UNSUPPORTED_MEDIA_TYPE, APIError.fromException(apiEx).code);
		System.assertEquals('UNSUPPORTED', APIError.fromException(apiEx).description);
		System.assertEquals(APIErrorCode.BAD_REQUEST, APIError.fromException(vEx).code);
		System.assertEquals('INVALID', APIError.fromException(vEx).description);
		System.assertEquals(APIErrorCode.UNAUTHORIZED, APIError.fromException(uaEx).code);
		System.assertEquals('UNAUTHORIZED', APIError.fromException(uaEx).description);
		System.assertEquals(APIErrorCode.DATABASE_ERROR, APIError.fromException(dmlEx1).code);
		System.assertEquals(Label.SalesforceOrgStorageLimitExceeded, APIError.fromException(dmlEx1).description);
		System.assertEquals(APIErrorCode.DATABASE_ERROR, APIError.fromException(dmlEx2).code);
		System.assertEquals('DML', APIError.fromException(dmlEx2).description);
		System.assertEquals(APIErrorCode.FAILURE, APIError.fromException(sEx).code);
		System.assertEquals('STRING', APIError.fromException(sEx).description);
	}
}
