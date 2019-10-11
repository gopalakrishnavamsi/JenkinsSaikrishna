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
			System.assertNotEquals(null, ((GenProduct)result[0]).webBaseUrl);
			System.assertNotEquals(null, ((GenProduct)result[0]).apiBaseUrl);
			System.assertNotEquals(null, ((GenProduct)result[0]).mergeBaseUrl);
			System.assertNotEquals(null, result[1]);
			System.assert(result[1] instanceof NegotiateProduct);
			System.assertNotEquals(null, ((NegotiateProduct)result[1]).webBaseUrl);
			System.assertNotEquals(null, ((NegotiateProduct)result[1]).apiBaseUrl);
			System.assertNotEquals(null, ((NegotiateProduct)result[1]).mergeBaseUrl);
			System.assertNotEquals(null, result[2]);
			System.assert(result[2] instanceof ClmProduct);
			System.assertNotEquals(null, ((ClmProduct)result[2]).webBaseUrl);
			System.assertNotEquals(null, ((ClmProduct)result[2]).authBaseUrl);
		}
	}

	private class ClmsfMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setHeader('X-DocuSign-TraceToken', UUID.randomUUID().toString());
			ProductAPI.APIProduct p = new ProductAPI.APIProduct();
			p.product_id = 'clmsf';
			p.free_trial = false;
			p.provision_status = 'active';
			p.expiration_date = null;
			p.activation_properties = new List<ProductAPI.APIProductProperty> {
				new ProductAPI.APIProductProperty('admin_uri', 'https://test.springcm.com/atlas/Admin/AccountSettings'),
				new ProductAPI.APIProductProperty('landing_page_uri', 'https://test.springcm.com/atlas/LandingPage'),
				new ProductAPI.APIProductProperty('web_base_uri', 'https://test.springcm.com/atlas/'),
				new ProductAPI.APIProductProperty('apiauth_base_url', 'https://auth.test.springcm.com/')
			};
			ProductAPI.APIProducts ps = new ProductAPI.APIProducts();
			ps.id = UUID.randomUUID().toString();
			ps.name = 'Unit Test';
			ps.products = new List<ProductAPI.APIProduct> { p };
			response.setBody(JSON.serialize(ps));
			return response;
		}
	}

	@IsTest
	static void test_getProducts_clmsf() {
		Test.setMock(HttpCalloutMock.class, new ClmsfMock());
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			List<Product> result = ProductAPI.getInstance().getProducts();
			Test.stopTest();

			System.assertEquals(1, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assert(result[0] instanceof ClmProduct);
			System.assertNotEquals(null, ((ClmProduct)result[0]).webBaseUrl);
			System.assertNotEquals(null, ((ClmProduct)result[0]).authBaseUrl);
		}
	}

	private class ClmprosfMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setHeader('X-DocuSign-TraceToken', UUID.randomUUID().toString());
			ProductAPI.APIProduct p = new ProductAPI.APIProduct();
			p.product_id = 'clmprosf';
			p.free_trial = false;
			p.provision_status = 'active';
			p.expiration_date = null;
			p.activation_properties = new List<ProductAPI.APIProductProperty> {
				new ProductAPI.APIProductProperty('admin_uri', 'https://test.springcm.com/atlas/Admin/AccountSettings'),
				new ProductAPI.APIProductProperty('landing_page_uri', 'https://test.springcm.com/atlas/LandingPage'),
				new ProductAPI.APIProductProperty('web_base_uri', 'https://test.springcm.com/atlas/'),
				new ProductAPI.APIProductProperty('apiauth_base_url', 'https://auth.test.springcm.com/')
			};
			ProductAPI.APIProducts ps = new ProductAPI.APIProducts();
			ps.id = UUID.randomUUID().toString();
			ps.name = 'Unit Test';
			ps.products = new List<ProductAPI.APIProduct> { p };
			response.setBody(JSON.serialize(ps));
			return response;
		}
	}

	@IsTest
	static void test_getProducts_clmprosf() {
		Test.setMock(HttpCalloutMock.class, new ClmprosfMock());
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			List<Product> result = ProductAPI.getInstance().getProducts();
			Test.stopTest();

			System.assertEquals(1, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assert(result[0] instanceof ClmProduct);
			System.assertNotEquals(null, ((ClmProduct)result[0]).webBaseUrl);
			System.assertNotEquals(null, ((ClmProduct)result[0]).authBaseUrl);
		}
	}

	private class ClmMultipleMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setHeader('X-DocuSign-TraceToken', UUID.randomUUID().toString());
			ProductAPI.APIProduct p1 = new ProductAPI.APIProduct();
			p1.product_id = 'clm';
			p1.free_trial = false;
			p1.provision_status = 'active';
			p1.expiration_date = null;
			p1.activation_properties = new List<ProductAPI.APIProductProperty> {
				new ProductAPI.APIProductProperty('admin_uri', 'https://test1.springcm.com/atlas/Admin/AccountSettings'),
				new ProductAPI.APIProductProperty('landing_page_uri', 'https://test1.springcm.com/atlas/LandingPage'),
				new ProductAPI.APIProductProperty('web_base_uri', 'https://test1.springcm.com/atlas/'),
				new ProductAPI.APIProductProperty('apiauth_base_url', 'https://auth.test1.springcm.com/')
			};
			ProductAPI.APIProduct p2 = new ProductAPI.APIProduct();
			p2.product_id = 'clmpro';
			p2.free_trial = false;
			p2.provision_status = 'active';
			p2.expiration_date = null;
			p2.activation_properties = new List<ProductAPI.APIProductProperty> {
				new ProductAPI.APIProductProperty('admin_uri', 'https://test2.springcm.com/atlas/Admin/AccountSettings'),
				new ProductAPI.APIProductProperty('landing_page_uri', 'https://test2.springcm.com/atlas/LandingPage'),
				new ProductAPI.APIProductProperty('web_base_uri', 'https://test2.springcm.com/atlas/'),
				new ProductAPI.APIProductProperty('apiauth_base_url', 'https://auth.test2.springcm.com/')
			};
			ProductAPI.APIProduct p3 = new ProductAPI.APIProduct();
			p3.product_id = 'clmsf';
			p3.free_trial = false;
			p3.provision_status = 'active';
			p3.expiration_date = null;
			p3.activation_properties = new List<ProductAPI.APIProductProperty> {
				new ProductAPI.APIProductProperty('admin_uri', 'https://test3.springcm.com/atlas/Admin/AccountSettings'),
				new ProductAPI.APIProductProperty('landing_page_uri', 'https://test3.springcm.com/atlas/LandingPage'),
				new ProductAPI.APIProductProperty('web_base_uri', 'https://test3.springcm.com/atlas/'),
				new ProductAPI.APIProductProperty('apiauth_base_url', 'https://auth.test3.springcm.com/')
			};
			ProductAPI.APIProduct p4 = new ProductAPI.APIProduct();
			p4.product_id = 'clmprosf';
			p4.free_trial = false;
			p4.provision_status = 'active';
			p4.expiration_date = null;
			p4.activation_properties = new List<ProductAPI.APIProductProperty> {
				new ProductAPI.APIProductProperty('admin_uri', 'https://test4.springcm.com/atlas/Admin/AccountSettings'),
				new ProductAPI.APIProductProperty('landing_page_uri', 'https://test4.springcm.com/atlas/LandingPage'),
				new ProductAPI.APIProductProperty('web_base_uri', 'https://test4.springcm.com/atlas/'),
				new ProductAPI.APIProductProperty('apiauth_base_url', 'https://auth.test4.springcm.com/')
			};
			ProductAPI.APIProducts ps = new ProductAPI.APIProducts();
			ps.id = UUID.randomUUID().toString();
			ps.name = 'Unit Test';
			ps.products = new List<ProductAPI.APIProduct> { p1, p2, p3, p4 };
			response.setBody(JSON.serialize(ps));
			return response;
		}
	}

	@IsTest
	static void test_getProducts_clm_multiple() {
		Test.setMock(HttpCalloutMock.class, new ClmMultipleMock());
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			List<Product> result = ProductAPI.getInstance().getProducts();
			Test.stopTest();

			System.assertEquals(1, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assert(result[0] instanceof ClmProduct);
			System.assertNotEquals(null, ((ClmProduct)result[0]).webBaseUrl);
			System.assertNotEquals(null, ((ClmProduct)result[0]).authBaseUrl);
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
