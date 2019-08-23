@IsTest(IsParallel = true)
private class UrlUtilsTest {

	@IsTest
	static void test_canonicalizeBaseUrl() {
		Test.startTest();
		System.assertEquals(null, UrlUtils.canonicalizeBaseUrl(null));
		System.assertEquals('https://unit.test/', UrlUtils.canonicalizeBaseUrl(new Url('http://unit.test')).toExternalForm());
		System.assertEquals('https://unit.test/', UrlUtils.canonicalizeBaseUrl(new Url('http://unit.test/')).toExternalForm());
		System.assertEquals('https://unit.test/path/', UrlUtils.canonicalizeBaseUrl(new Url('http://unit.test/path')).toExternalForm());
		System.assertEquals('https://unit.test/path/', UrlUtils.canonicalizeBaseUrl(new Url('http://unit.test/path/')).toExternalForm());
		System.assertEquals('https://unit.test/path/', UrlUtils.canonicalizeBaseUrl(new Url('http://UNIT.test/Path/')).toExternalForm());
		Test.stopTest();
	}
}
