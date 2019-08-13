@IsTest(IsParallel = true)
private class ProductTest {

	@IsTest
	static void test_isExpired() {
		Test.startTest();
		System.assert(!new GenProduct(Product.STATUS_ACTIVE, false, null, null, null).isExpired);
		System.assert(!new NegotiateProduct(Product.STATUS_EXPIRED, false, Date.today().addDays(1), null, null).isExpired);
		System.assert(!new ClmProduct(Product.STATUS_PENDING, true, Date.today().addDays(1), null, null, null).isExpired);
		System.assert(new ESignatureProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null).isExpired);
		Test.stopTest();
	}

	@IsTest
	static void test_daysUntilExpires() {
		Test.startTest();
		System.assertEquals(0, new GenProduct(Product.STATUS_ACTIVE, false, null, null, null).daysUntilExpires);
		System.assertEquals(0, new NegotiateProduct(Product.STATUS_EXPIRED, false, Date.today().addDays(1), null, null).daysUntilExpires);
		System.assertEquals(1, new ClmProduct(Product.STATUS_PENDING, true, Date.today().addDays(1), null, null, null).daysUntilExpires);
		System.assertEquals(0, new ESignatureProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null).daysUntilExpires);
		Test.stopTest();
	}

	@IsTest
	static void test_getRoleLabel() {
		Test.startTest();
		System.assertEquals(null, Product.getRoleLabel(null));
		System.assertEquals('foo', Product.getRoleLabel('foo'));
		System.assertEquals(Label.Administrator, Product.getRoleLabel(ESignatureProduct.ROLE_ADMINISTRATOR));
		System.assertEquals(Label.User, Product.getRoleLabel(ESignatureProduct.ROLE_USER));
		System.assertEquals(Label.Sender, Product.getRoleLabel(ESignatureProduct.ROLE_SENDER));
		System.assertEquals(Label.Generator, Product.getRoleLabel(GenProduct.ROLE_GENERATOR));
		System.assertEquals(Label.Negotiator, Product.getRoleLabel(NegotiateProduct.ROLE_NEGOTIATOR));
		System.assertEquals(Label.Administrator, Product.getRoleLabel(ClmProduct.ROLE_ADMINISTRATOR));
		System.assertEquals(Label.User, Product.getRoleLabel(ClmProduct.ROLE_USER));
		System.assertEquals(Label.Viewer, Product.getRoleLabel(ClmProduct.ROLE_VIEWER));
		Test.stopTest();
	}

	@IsTest
	static void test_isValidProduct() {
		Test.startTest();
		System.assert(!Product.isValidProduct(null));
		System.assert(!Product.isValidProduct('  '));
		System.assert(!Product.isValidProduct('whatever'));
		System.assert(Product.isValidProduct('CLM'));
		System.assert(Product.isValidProduct('clm'));
		System.assert(Product.isValidProduct('e_Sign'));
		System.assert(Product.isValidProduct('Gen'));
		System.assert(Product.isValidProduct('Negotiate'));
		Test.stopTest();
	}

	@IsTest
	static void test_isValidRole_string() {
		Test.startTest();
		System.assert(!Product.isValidRole(null, null));
		System.assert(!Product.isValidRole('', '  '));
		System.assert(!Product.isValidRole('whatever', 'whatever'));
		System.assert(!Product.isValidRole('e_sign', 'generator'));
		System.assert(Product.isValidRole('CLM', 'Administrator'));
		System.assert(Product.isValidRole('clm', 'USER'));
		System.assert(Product.isValidRole('clm', 'viewer'));
		System.assert(Product.isValidRole('e_Sign', 'administrator'));
		System.assert(Product.isValidRole('E_SIGN', 'user'));
		System.assert(Product.isValidRole('e_sign', 'sender'));
		System.assert(Product.isValidRole('Gen', 'generator'));
		System.assert(Product.isValidRole('Negotiate', 'negotiator'));
		Test.stopTest();
	}

	@IsTest
	static void test_isValidRole_role() {
		Test.startTest();
		System.assert(!Product.isValidRole(null));
		System.assert(!Product.isValidRole(new Product.Role(null, Product.CLM, ClmProduct.ROLE_USER, '', false)));
		System.assert(!Product.isValidRole(new Product.Role(UUID.randomUUID(), 'whatever', ClmProduct.ROLE_USER, '', false)));
		System.assert(!Product.isValidRole(new Product.Role(UUID.randomUUID(), Product.CLM, '', '', false)));
		System.assert(Product.isValidRole(new Product.Role(UUID.randomUUID(), Product.ESIGNATURE, ESignatureProduct.ROLE_ADMINISTRATOR, '', false)));
		System.assert(Product.isValidRole(new Product.Role(UUID.randomUUID(), Product.ESIGNATURE, ESignatureProduct.ROLE_USER, '', false)));
		System.assert(Product.isValidRole(new Product.Role(UUID.randomUUID(), Product.ESIGNATURE, ESignatureProduct.ROLE_SENDER, '', false)));
		System.assert(Product.isValidRole(new Product.Role(UUID.randomUUID(), Product.GEN, GenProduct.ROLE_GENERATOR, '', false)));
		System.assert(Product.isValidRole(new Product.Role(UUID.randomUUID(), Product.NEGOTIATE, NegotiateProduct.ROLE_NEGOTIATOR, '', false)));
		System.assert(Product.isValidRole(new Product.Role(UUID.randomUUID(), Product.CLM, ClmProduct.ROLE_ADMINISTRATOR, '', false)));
		System.assert(Product.isValidRole(new Product.Role(UUID.randomUUID(), Product.CLM, ClmProduct.ROLE_USER, '', false)));
		System.assert(Product.isValidRole(new Product.Role(UUID.randomUUID(), Product.CLM, ClmProduct.ROLE_VIEWER, '', false)));
		Test.stopTest();
	}
}
