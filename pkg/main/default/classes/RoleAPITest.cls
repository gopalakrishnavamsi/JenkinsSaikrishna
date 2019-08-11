@IsTest
private class RoleAPITest {

	@IsTest
	static void test_getInstance() {
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			RoleAPI result1 = RoleAPI.getInstance();
			RoleAPI result2 = RoleAPI.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 === result2);
		}
	}

	@IsTest
	static void test_getAccountRoles_empty_products() {
		System.runAs(UserMock.createDocuSignGenerator()) {
			Test.startTest();
			Map<String, List<Product.Role>> result = RoleAPI.getInstance().getAccountRoles(null, 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isEmpty());
		}
	}

	@IsTest
	static void test_getAccountRoles_unsupported_product() {
		System.runAs(UserMock.createDocuSignGenerator()) {
			Test.startTest();
			Map<String, List<Product.Role>> result = RoleAPI.getInstance().getAccountRoles(
				new Set<String> { 'bad' }, 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isEmpty());
		}
	}

	@IsTest
	static void test_getAccountRoles_error() {
		RoleAPIMock.failure();

		System.runAs(UserMock.createDocuSignGenerator()) {
			Test.startTest();
			try {
				RoleAPI.getInstance().getAccountRoles(new Set<String> { 'gen' }, 30000);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
				System.assert(ex.error instanceof ProvisioningAPI.Error);
			}
			Test.stopTest();
		}
	}

	class InvalidGroupMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setStatusCode(200);
			response.setBody('{"groups":[{"source_product_name":"clm","group_name":"Administrators"}]}');
			return response;
		}
	}

	@IsTest
	static void test_getAccountRoles_invalid_group() {
		Test.setMock(HttpCalloutMock.class, new InvalidGroupMock());

		System.runAs(UserMock.createClmViewer()) {
			Test.startTest();
			Map<String, List<Product.Role>> result = RoleAPI.getInstance().getAccountRoles(
				new Set<String> { Product.CLM }, 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.containsKey(Product.CLM));
			System.assertNotEquals(null, result.get(Product.CLM));
			System.assert(result.get(Product.CLM).isEmpty());
		}
	}

	@IsTest
	static void test_getAccountRoles_success() {
		RoleAPIMock.success();

		System.runAs(UserMock.createDocuSignGenerator()) {
			Test.startTest();
			Map<String, List<Product.Role>> result = RoleAPI.getInstance().getAccountRoles(
				new Set<String> { 'gen', 'negotiate', 'clm' }, 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			System.assertEquals(new Set<String> { 'clm', 'negotiate', 'gen' }, result.keySet());
			List<Product.Role> roles = result.get('gen');
			System.assertEquals(1, Collection.size(roles));
			System.assertNotEquals(null, roles[0]);
			roles = result.get('negotiate');
			System.assertEquals(1, Collection.size(roles));
			System.assertNotEquals(null, roles[0]);
			roles = result.get('clm');
			System.assertEquals(3, Collection.size(roles));
			System.assertNotEquals(null, roles[0]);
			System.assertNotEquals(null, roles[1]);
			System.assertNotEquals(null, roles[2]);
		}
	}

	@IsTest
	static void test_createAccountRole_undefined() {
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			Product.Role result = RoleAPI.getInstance().createAccountRole(null, 30000);
			Test.stopTest();

			System.assertEquals(null, result);
		}
	}

	@IsTest
	static void test_createAccountRole_error() {
		RoleAPIMock.failure();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			Product.Role r = new Product.Role(
				null,
				TestUtils.randomInteger(100000),
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				false);

			Test.startTest();
			try {
				RoleAPI.getInstance().createAccountRole(r, 30000);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
				System.assert(ex.error instanceof ProvisioningAPI.Error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createAccountRole_success() {
		RoleAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			Product.Role r = new Product.Role(
				null,
				TestUtils.randomInteger(100000),
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				false);

			Test.startTest();
			Product.Role result = RoleAPI.getInstance().createAccountRole(r, 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertEquals(r.groupId, result.groupId);
			System.assertEquals(r.product, result.product);
			System.assertEquals(r.name, result.name);
			System.assertEquals(r.description, result.description);
			System.assertEquals(r.isAdministrator, result.isAdministrator);
		}
	}

	@IsTest
	static void test_getProductRoles_undefined_product() {
		System.runAs(UserMock.createClmAdministrator()) {
			Test.startTest();
			List<Product.Role> result = RoleAPI.getInstance().getProductRoles(null, 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isEmpty());
		}
	}

	@IsTest
	static void test_getProductRoles_error() {
		RoleAPIMock.failure();

		System.runAs(UserMock.createClmAdministrator()) {
			Test.startTest();
			try {
				RoleAPI.getInstance().getProductRoles(Product.CLM, 30000);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
				System.assert(ex.error instanceof ProvisioningAPI.Error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getProductRoles_gen() {
		RoleAPIMock.success();

		System.runAs(UserMock.createDocuSignGenerator()) {
			Test.startTest();
			List<Product.Role> result = RoleAPI.getInstance().getProductRoles(Product.GEN, 30000);
			Test.stopTest();

			System.assertEquals(1, Collection.size(result));
		}
	}

	@IsTest
	static void test_getProductRoles_negotiate() {
		RoleAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			List<Product.Role> result = RoleAPI.getInstance().getProductRoles(Product.NEGOTIATE, 30000);
			Test.stopTest();

			System.assertEquals(1, Collection.size(result));
		}
	}

	@IsTest
	static void test_getProductRoles_clm() {
		RoleAPIMock.success();

		System.runAs(UserMock.createClmAdministrator()) {
			Test.startTest();
			List<Product.Role> result = RoleAPI.getInstance().getProductRoles(Product.CLM, 30000);
			Test.stopTest();

			System.assertEquals(3, Collection.size(result));
		}
	}

	@IsTest
	static void test_getProductRoles_other() {
		RoleAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			List<Product.Role> result = RoleAPI.getInstance().getProductRoles('other', 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isEmpty());
		}
	}

	@IsTest
	static void test_getRoles_undefined_argument() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Map<String, List<Product.Role>> result = RoleAPI.getInstance().getRoles(null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isEmpty());
		}
	}

	@IsTest
	static void test_getRoles_error() {
		RoleAPIMock.failure();

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				RoleAPI.getInstance().getRoles(new Set<String> { Product.CLM }, 30000);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
				System.assert(ex.error instanceof ProvisioningAPI.Error);
			}
			Test.stopTest();
		}
	}

	class PartiallyProvisionedMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setHeader('Content-Type', 'application/json');
			response.setHeader('X-DocuSign-TraceToken', UUID.randomUUID().toString());
			String endpoint = request.getEndpoint();
			if (request.getMethod() == 'POST') {
				response.setStatusCode(201);
				response.setStatus('CREATED');
				if (endpoint.endsWith('/users')) { // add dsgroup users

				} else { // add account dsgroups
					RoleAPI.APIGroup g = (RoleAPI.APIGroup)JSON.deserialize(request.getBody(), RoleAPI.APIGroup.class);
					g.ds_group_id = UUID.randomUUID().toString();
					response.setBody(JSON.serialize(g));

				}
			} else if (endpoint.contains('/products/')) { // get product groups
				response.setStatusCode(200);
				response.setStatus('OK');
				RoleAPI.APIGroups gs = new RoleAPI.APIGroups();
				gs.groups = new List<RoleAPI.APIGroup>();
				if (endpoint.contains('/clm/')) {
					RoleAPI.APIGroup g = new RoleAPI.APIGroup(null);
					g.group_id = '0';
					g.group_name = 'Super Administrator';
					g.description = 'Administrators!';
					g.source_product_name = 'clm';
					g.is_admin = true;
					gs.groups.add(g);
					g = new RoleAPI.APIGroup(null);
					g.group_id = '1';
					g.group_name = 'Full Subscriber';
					g.description = 'Users!';
					g.source_product_name = 'clm';
					g.is_admin = true;
					gs.groups.add(g);
					g = new RoleAPI.APIGroup(null);
					g.group_id = '2';
					g.group_name = 'Guest';
					g.description = 'Viewers!';
					g.source_product_name = 'clm';
					g.is_admin = true;
					gs.groups.add(g);
					g = new RoleAPI.APIGroup(null);
					g.group_id = '22';
					g.group_name = 'Other Admin';
					g.description = 'should ignore';
					g.source_product_name = 'clm';
					g.is_admin = true;
					gs.groups.add(g);
					g = new RoleAPI.APIGroup(null);
					g.group_id = '33';
					g.group_name = 'Other User';
					g.description = 'should ignore';
					g.source_product_name = 'clm';
					g.is_admin = true;
					gs.groups.add(g);
				} else if (endpoint.contains('/gen/')) {
					RoleAPI.APIGroup g = new RoleAPI.APIGroup(null);
					g.group_id = '3';
					g.group_name = 'Generator'; // TODO: Use final name when available
					g.description = 'Generators!';
					g.source_product_name = 'gen';
					g.is_admin = true;
					gs.groups.add(g);
				} else if (endpoint.contains('/negotiate/')) {
					RoleAPI.APIGroup g = new RoleAPI.APIGroup(null);
					g.group_id = '4';
					g.group_name = 'Negotiator'; // TODO: Use final name when available
					g.description = 'Negotiator!';
					g.source_product_name = 'negotiate';
					g.is_admin = true;
					gs.groups.add(g);
				} else {
					RoleAPI.APIGroup g = new RoleAPI.APIGroup(null);
					g.group_id = '55';
					g.group_name = 'Other';
					g.description = 'should ignore';
					g.source_product_name = 'other';
					g.is_admin = true;
					gs.groups.add(g);
				}
				response.setBody(JSON.serialize(gs));
			} else if (endpoint.contains('/dsgroups')) { // get account groups
				response.setStatusCode(200);
				response.setStatus('OK');
				RoleAPI.APIGroups gs = new RoleAPI.APIGroups();
				gs.groups = new List<RoleAPI.APIGroup>();
				RoleAPI.APIGroup g = new RoleAPI.APIGroup(null);
				g.ds_group_id = UUID.randomUUID().toString();
				g.group_id = '0';
				g.group_name = 'Administrators';
				g.description = 'Administrators!';
				g.source_product_name = 'clm';
				g.is_admin = true;
				gs.groups.add(g);
				g = new RoleAPI.APIGroup(null);
				g.ds_group_id = UUID.randomUUID().toString();
				g.group_id = '2';
				g.group_name = 'Viewers';
				g.description = 'Viewers!';
				g.source_product_name = 'clm';
				g.is_admin = true;
				gs.groups.add(g);
				g = new RoleAPI.APIGroup(null);
				g.ds_group_id = UUID.randomUUID().toString();
				g.group_id = '4';
				g.group_name = 'Negotiators';
				g.description = 'Negotiator!';
				g.source_product_name = 'negotiate';
				g.is_admin = true;
				gs.groups.add(g);
				g = new RoleAPI.APIGroup(null);
				g.ds_group_id = UUID.randomUUID().toString();
				g.group_id = '22';
				g.group_name = 'Other Admins';
				g.description = 'should ignore';
				g.source_product_name = 'clm';
				g.is_admin = true;
				gs.groups.add(g);
				g = new RoleAPI.APIGroup(null);
				g.ds_group_id = UUID.randomUUID().toString();
				g.group_id = '33';
				g.group_name = 'Other Users';
				g.description = 'should ignore';
				g.source_product_name = 'clm';
				g.is_admin = true;
				gs.groups.add(g);
				g = new RoleAPI.APIGroup(null);
				g.ds_group_id = UUID.randomUUID().toString();
				g.group_id = '44';
				g.group_name = 'Others';
				g.description = 'should ignore';
				g.source_product_name = 'other';
				g.is_admin = true;
				gs.groups.add(g);
				response.setBody(JSON.serialize(gs));
			}
			return response;
		}
	}

	@IsTest
	static void test_getRoles_success() {
		Test.setMock(HttpCalloutMock.class, new PartiallyProvisionedMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Map<String, List<Product.Role>> result = RoleAPI.getInstance().getRoles(new Set<String> {
				Product.CLM, Product.GEN, Product.NEGOTIATE, 'other'
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			System.assertEquals(new Set<String> { Product.CLM, Product.GEN, Product.NEGOTIATE }, result.keySet());
			System.assertEquals(1, Collection.size(result.get(Product.GEN)));
			System.assertNotEquals(null, result.get(Product.GEN)[0]);
			System.assertNotEquals(null, result.get(Product.GEN)[0].id);
			System.assertEquals(RoleAPI.ROLE_GEN_GENERATORS, result.get(Product.GEN)[0].name);
			System.assertEquals(1, Collection.size(result.get(Product.NEGOTIATE)));
			System.assertNotEquals(null, result.get(Product.NEGOTIATE)[0]);
			System.assertNotEquals(null, result.get(Product.NEGOTIATE)[0].id);
			System.assertEquals(RoleAPI.ROLE_NEGOTIATE_NEGOTIATORS, result.get(Product.NEGOTIATE)[0].name);
			System.assertEquals(3, Collection.size(result.get(Product.CLM)));
			System.assertNotEquals(null, result.get(Product.CLM)[0]);
			System.assertNotEquals(null, result.get(Product.CLM)[0].id);
			System.assertNotEquals(null, result.get(Product.CLM)[1]);
			System.assertNotEquals(null, result.get(Product.CLM)[1].id);
			System.assertNotEquals(null, result.get(Product.CLM)[2]);
			System.assertNotEquals(null, result.get(Product.CLM)[2].id);
			System.assertEquals(
				new Set<String> {
					RoleAPI.ROLE_CLM_USERS, RoleAPI.ROLE_CLM_ADMINISTRATORS, RoleAPI.ROLE_CLM_VIEWERS
				},
				new Set<String> {
					result.get(Product.CLM)[0].name, result.get(Product.CLM)[1].name, result.get(Product.CLM)[2].name
				});
		}
	}
}
