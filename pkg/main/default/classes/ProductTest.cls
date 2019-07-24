@IsTest(IsParallel = true)
private class ProductTest {

	@IsTest
	static void test_isExpired() {
		Test.startTest();
		System.assert(!new GenProduct(Product.STATUS_ACTIVE, false, null, null).isExpired);
		System.assert(!new NegotiateProduct(Product.STATUS_EXPIRED, false, Date.today().addDays(1), null).isExpired);
		System.assert(!new ClmProduct(Product.STATUS_PENDING, true, Date.today().addDays(1), null).isExpired);
		System.assert(new ESignatureProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null).isExpired);
		Test.stopTest();
	}

	@IsTest
	static void test_daysUntilExpires() {
		Test.startTest();
		System.assertEquals(0, new GenProduct(Product.STATUS_ACTIVE, false, null, null).daysUntilExpires);
		System.assertEquals(0, new NegotiateProduct(Product.STATUS_EXPIRED, false, Date.today().addDays(1), null).daysUntilExpires);
		System.assertEquals(1, new ClmProduct(Product.STATUS_PENDING, true, Date.today().addDays(1), null).daysUntilExpires);
		System.assertEquals(0, new ESignatureProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null).daysUntilExpires);
		Test.stopTest();
	}
}
