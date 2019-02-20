@IsTest
private class SecureUtilsTest {

	@IsTest
	static void test_encryption() {
		try {
			SecureUtils.encrypt('test');
			throw new AssertException('Expected encrypt to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.KeyNotFound, ex.getMessage());
		}
		try {
			SecureUtils.decrypt('test');
			throw new AssertException('Expected decrypt to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.KeyNotFound, ex.getMessage());
		}

		TestUtils.generateKey();

		System.assertEquals(null, SecureUtils.encrypt(null));
		System.assertEquals(null, SecureUtils.decrypt(null));
		System.assertNotEquals('test', SecureUtils.encrypt('test'));
		System.assertEquals('test', SecureUtils.decrypt(SecureUtils.encrypt('test')));
	}
}
