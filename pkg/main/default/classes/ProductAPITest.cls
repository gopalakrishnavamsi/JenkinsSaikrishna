@IsTest
private class ProductAPITest {

	@IsTest
	static void test_getInstance_default() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			ProductAPI result1 = ProductAPI.getInstance();
			ProductAPI result2 = ProductAPI.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 === result2);
		}
	}

	@IsTest
	static void test_getInstance_setup_valid() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			ProductAPI result1 = ProductAPI.getInstance(
				new Url('https://test.docusign.com'), UUID.randomUUID(), 'test');
			ProductAPI result2 = ProductAPI.getInstance(
				new Url('https://test.docusign.com'), UUID.randomUUID(), 'test');
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertNotEquals(null, result2);
			System.assert(result1 !== result2);
		}
	}

	@IsTest
	static void test_getInstance_setup_invalid() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				ProductAPI.getInstance(null, UUID.randomUUID(), 'test');
				throw new AssertException('Expected getInstance to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				ProductAPI.getInstance(new Url('https://test.docusign.com'), null, 'test');
				throw new AssertException('Expected getInstance to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				ProductAPI.getInstance(new Url('https://invalid.url'), UUID.randomUUID(), 'test');
				throw new AssertException('Expected getInstance to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getProducts_success() {
		ProductAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			List<Product> result = ProductAPI.getInstance().getProducts();
			Test.stopTest();

			System.assertEquals(3, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assert(result[0] instanceof GenProduct);
			System.assertNotEquals(null, ((GenProduct)result[0]).apiBaseUrl);
			System.assertNotEquals(null, ((GenProduct)result[0]).authBaseUrl);
			System.assertNotEquals(null, result[1]);
			System.assert(result[1] instanceof NegotiateProduct);
			System.assertNotEquals(null, ((NegotiateProduct)result[1]).apiBaseUrl);
			System.assertNotEquals(null, ((NegotiateProduct)result[1]).authBaseUrl);
			System.assertNotEquals(null, result[2]);
			System.assert(result[2] instanceof ClmProduct);
			System.assertNotEquals(null, ((ClmProduct)result[2]).adminUrl);
			System.assertNotEquals(null, ((ClmProduct)result[2]).authBaseUrl);
			System.assertNotEquals(null, ((ClmProduct)result[2]).landingPageUrl);
		}
	}

	@IsTest
	static void test_getProducts_failure() {
		ProductAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				ProductAPI.getInstance().getProducts();
				throw new AssertException('Expected getProducts to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
				System.assert(ex.error instanceof ProvisioningAPI.Error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_activateProduct_success() {
		ProductAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Product result = ProductAPI.getInstance().activateProduct(ProductAPI.PRODUCT_NEGOTIATE, true);
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_activateProduct_failure() {
		ProductAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				ProductAPI.getInstance().activateProduct('p1', false);
				throw new AssertException('Expected activateProduct to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
				System.assert(ex.error instanceof ProvisioningAPI.Error);
			}
			Test.stopTest();
		}
	}
}
