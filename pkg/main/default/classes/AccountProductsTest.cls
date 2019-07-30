@IsTest
private class AccountProductsTest {

	@IsTest
	static void test_getInstance_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignSender()) {
			Test.startTest();
			AccountProducts result1 = AccountProducts.getInstance();
			AccountProducts result2 = AccountProducts.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 === result2);
			System.assertNotEquals(null, result1.eSignature);
			System.assertNotEquals(null, result1.gen);
			System.assertNotEquals(null, result1.negotiate);
			System.assertNotEquals(null, result1.clm);
		}
	}

	@IsTest
	static void test_getInstance_error() {
		DocuSignAPIMock.failure();

		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			AccountProducts result = AccountProducts.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(null, result.eSignature);
			System.assertEquals(null, result.gen);
			System.assertEquals(null, result.negotiate);
			System.assertEquals(null, result.clm);
		}
	}

	@IsTest
	static void test_isESignatureTrialExpired() {
		AccountProducts aps1 = new AccountProducts(null);
		AccountProducts aps2 = new AccountProducts(new Map<String, Product>());
		AccountProducts aps3 = new AccountProducts(new Map<String, Product> { Product.ESIGNATURE => new ESignatureProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null) });
		AccountProducts aps4 = new AccountProducts(new Map<String, Product> { Product.ESIGNATURE => new ESignatureProduct(Product.STATUS_ACTIVE, false, Date.today().addDays(-1), null) });
		AccountProducts aps5 = new AccountProducts(new Map<String, Product> { Product.ESIGNATURE => new ESignatureProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(1), null) });

		Test.startTest();
		System.assert(!aps1.isESignatureTrialExpired());
		System.assert(!aps2.isESignatureTrialExpired());
		System.assert(aps3.isESignatureTrialExpired());
		System.assert(!aps4.isESignatureTrialExpired());
		System.assert(!aps5.isESignatureTrialExpired());
		Test.stopTest();
	}

	@IsTest
	static void test_isESignatureEnabled() {
		AccountProducts aps1 = new AccountProducts(null);
		AccountProducts aps2 = new AccountProducts(new Map<String, Product>());
		AccountProducts aps3 = new AccountProducts(new Map<String, Product> { Product.ESIGNATURE => new ESignatureProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null) });
		AccountProducts aps4 = new AccountProducts(new Map<String, Product> { Product.ESIGNATURE => new ESignatureProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(1), null) });

		Test.startTest();
		System.assert(!aps1.isESignatureEnabled());
		System.assert(!aps2.isESignatureEnabled());
		System.assert(!aps3.isESignatureEnabled());
		System.assert(aps4.isESignatureEnabled());
		Test.stopTest();
	}

	@IsTest
	static void test_isGenEnabled() {
		AccountProducts aps1 = new AccountProducts(null);
		AccountProducts aps2 = new AccountProducts(new Map<String, Product>());
		AccountProducts aps3 = new AccountProducts(new Map<String, Product> { Product.GEN => new GenProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null, null) });
		AccountProducts aps4 = new AccountProducts(new Map<String, Product> { Product.GEN => new GenProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(1), null, null) });

		Test.startTest();
		System.assert(!aps1.isGenEnabled());
		System.assert(!aps2.isGenEnabled());
		System.assert(!aps3.isGenEnabled());
		System.assert(aps4.isGenEnabled());
		Test.stopTest();
	}

	@IsTest
	static void test_isNegotiateEnabled() {
		AccountProducts aps1 = new AccountProducts(null);
		AccountProducts aps2 = new AccountProducts(new Map<String, Product>());
		AccountProducts aps3 = new AccountProducts(new Map<String, Product> { Product.NEGOTIATE => new NegotiateProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null) });
		AccountProducts aps4 = new AccountProducts(new Map<String, Product> { Product.NEGOTIATE => new NegotiateProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(1), null) });

		Test.startTest();
		System.assert(!aps1.isNegotiateEnabled());
		System.assert(!aps2.isNegotiateEnabled());
		System.assert(!aps3.isNegotiateEnabled());
		System.assert(aps4.isNegotiateEnabled());
		Test.stopTest();
	}

	@IsTest
	static void test_isClmEnabled() {
		AccountProducts aps1 = new AccountProducts(null);
		AccountProducts aps2 = new AccountProducts(new Map<String, Product>());
		AccountProducts aps3 = new AccountProducts(new Map<String, Product> { Product.CLM => new ClmProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null) });
		AccountProducts aps4 = new AccountProducts(new Map<String, Product> { Product.CLM => new ClmProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(1), null) });

		Test.startTest();
		System.assert(!aps1.isClmEnabled());
		System.assert(!aps2.isClmEnabled());
		System.assert(!aps3.isClmEnabled());
		System.assert(aps4.isClmEnabled());
		Test.stopTest();
	}

	@IsTest
	static void test_resolveProducts_update() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
			accountSettings.ProductsLastChecked__c = null;
			update accountSettings;
			delete ProductSettings__c.getAll().values();
			ESignatureProduct esign = new ESignatureProduct(
				'expired',
				true,
				Date.today().addDays(-1),
				new Set<ESignatureProduct.Feature> { ESignatureProduct.Feature.Templates });

			Test.startTest();
			Map<String, Product> result = AccountProducts.resolveProducts(
				new Map<String, Product> { Product.ESIGNATURE => esign },
				Datetime.now().addDays(-1),
				1);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(4, result.size());
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().ProductsLastChecked__c);
			System.assertEquals(4, Collection.size(ProductSettings__c.getAll().values()));
		}
	}

	@IsTest
	static void test_resolveProducts_cached() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			ESignatureProduct esign = new ESignatureProduct(
				'expired',
				true,
				Date.today().addDays(-1),
				new Set<ESignatureProduct.Feature> { ESignatureProduct.Feature.Templates });

			Test.startTest();
			Map<String, Product> result = AccountProducts.resolveProducts(
				new Map<String, Product> { Product.ESIGNATURE => esign },
				Datetime.now().addMinutes(-1),
				60);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().ProductsLastChecked__c);
			System.assertEquals(0, Collection.size(ProductSettings__c.getAll().values()));
		}
	}

	@IsTest
	static void test_packFeatures() {
		Integer flags = AccountProducts.FLAG_BULK_SENDING
			| AccountProducts.FLAG_MERGE_FIELDS
			| AccountProducts.FLAG_SIGNING_GROUPS
			| AccountProducts.FLAG_SMS_AUTHENTICATION
			| AccountProducts.FLAG_TEMPLATES;
		Set<ESignatureProduct.Feature> features = new Set<ESignatureProduct.Feature> {
			ESignatureProduct.Feature.BulkSending,
			ESignatureProduct.Feature.MergeFields,
			ESignatureProduct.Feature.SigningGroups,
			ESignatureProduct.Feature.SmsAuthentication,
			ESignatureProduct.Feature.Templates
		};

		Test.startTest();
		System.assertEquals(flags, AccountProducts.packFeatures(features));
		Test.stopTest();
	}

	@IsTest
	static void test_unpackFeatures() {
		Integer flags = AccountProducts.FLAG_BULK_SENDING
			| AccountProducts.FLAG_MERGE_FIELDS
			| AccountProducts.FLAG_SIGNING_GROUPS
			| AccountProducts.FLAG_SMS_AUTHENTICATION
			| AccountProducts.FLAG_TEMPLATES;
		Set<ESignatureProduct.Feature> features = new Set<ESignatureProduct.Feature> {
			ESignatureProduct.Feature.BulkSending,
			ESignatureProduct.Feature.MergeFields,
			ESignatureProduct.Feature.SigningGroups,
			ESignatureProduct.Feature.SmsAuthentication,
			ESignatureProduct.Feature.Templates
		};

		Test.startTest();
		System.assertEquals(features, AccountProducts.unpackFeatures(flags));
		Test.stopTest();
	}

	@IsTest
	static void test_startTrial_unauthorized() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				AccountProducts.getInstance().startTrial(null);
				throw new AssertException('Expected startTrial to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_startTrial_invalid() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountProducts.getInstance().startTrial(null);
				throw new AssertException('Expected startTrial to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				AccountProducts.getInstance().startTrial('  ');
				throw new AssertException('Expected startTrial to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				AccountProducts.getInstance().startTrial(Product.CLM);
				throw new AssertException('Expected startTrial to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(
					String.format(Label.InvalidTrialProduct_1, new List<String> { Product.CLM }),
					ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_startTrial_success() {
		ProvisioningAPIMock.success();

		System.runAs(UserMock.createDocuSignAdministrator()) {
			delete ProductSettings__c.getAll().values();
			ProductSettings__c ps = new ProductSettings__c(
				Name = Product.GEN
			);
			insert ps;

			Test.startTest();
			Product result1 = AccountProducts.getInstance().startTrial(Product.GEN);
			Product result2 = AccountProducts.getInstance().startTrial(Product.NEGOTIATE);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertNotEquals(null, result2);

			Map<String, ProductSettings__c> pss = ProductSettings__c.getAll();
			System.assertNotEquals(null, pss);
			System.assertEquals(2, pss.size());
			System.assertEquals(new Set<String> { Product.GEN, Product.NEGOTIATE }, pss.keySet());
			System.assertEquals(ps.Id, pss.get(Product.GEN).Id);

		}
	}
}
