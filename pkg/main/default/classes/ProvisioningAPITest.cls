@IsTest
private class ProvisioningAPITest {

	@IsTest
	static void test_getInstance_default() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			ProvisioningAPI result1 = ProvisioningAPI.getInstance();
			ProvisioningAPI result2 = ProvisioningAPI.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 === result2);
		}
	}

	@IsTest
	static void test_getInstance_setup_valid() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			ProvisioningAPI result1 = ProvisioningAPI.getInstance(
				new Url('https://test.docusign.com'), UUID.randomUUID(), 'test');
			ProvisioningAPI result2 = ProvisioningAPI.getInstance(
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
				ProvisioningAPI.getInstance(null, UUID.randomUUID(), 'test');
				throw new AssertException('Expected getInstance to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				ProvisioningAPI.getInstance(new Url('https://test.docusign.com'), null, 'test');
				throw new AssertException('Expected getInstance to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				ProvisioningAPI.getInstance(new Url('https://test.docusign.com'), UUID.randomUUID(), ' ');
				throw new AssertException('Expected getInstance to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				ProvisioningAPI.getInstance(new Url('https://invalid.url'), UUID.randomUUID(), 'test');
				throw new AssertException('Expected getInstance to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getError() {
		System.runAs(UserMock.createDocuSignUser()) {
			ProvisioningAPI client = ProvisioningAPI.getInstance();

			HttpResponse r1 = new HttpResponse();
			r1.setStatusCode(200);
			System.assertEquals(APIError.none, client.getError(r1));

			HttpResponse r2 = new HttpResponse();
			r2.setStatusCode(401);
			r2.setBody('{"error":"not_authorized","error_description":"no way","reference_id":"01234567-89ab-cdef-0123-456789abcdef"}');
			APIError e2 = client.getError(r2);
			System.assertNotEquals(null, e2);
			System.assertEquals(401, e2.code);
			System.assertEquals('no way', e2.description);
			System.assert(e2 instanceof ProvisioningAPI.Error);
			System.assertEquals(UUID.parse('01234567-89ab-cdef-0123-456789abcdef'), ((ProvisioningAPI.Error)e2).referenceId);

			HttpResponse r3 = new HttpResponse();
			r3.setStatusCode(422);
			r3.setStatus('UNIT_TEST');
			APIError e3 = client.getError(r3);
			System.assertEquals(422, e3.code);
			System.assertEquals('UNIT_TEST', e3.description);
			System.assert(!(e3 instanceof ProvisioningAPI.Error));
		}
	}

	@IsTest
	static void test_getProducts_success() {
		ProvisioningAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			List<Product> result = ProvisioningAPI.getInstance().getProducts();
			Test.stopTest();

			System.assertEquals(1, Collection.size(result));
			System.assertNotEquals(null, result[0]);
		}
	}

	@IsTest
	static void test_getProducts_failure() {
		ProvisioningAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				ProvisioningAPI.getInstance().getProducts();
				throw new AssertException('Expected getProducts to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
				System.assert(ex.error instanceof ProvisioningAPI.Error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_addProduct_success() {
		ProvisioningAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Product result = ProvisioningAPI.getInstance().addProduct('p1', true);
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_addProduct_failure() {
		ProvisioningAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				ProvisioningAPI.getInstance().addProduct('p1', false);
				throw new AssertException('Expected addProduct to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
				System.assert(ex.error instanceof ProvisioningAPI.Error);
			}
			Test.stopTest();
		}
	}
}
