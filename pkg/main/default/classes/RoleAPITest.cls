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
			Map<String, Map<UUID, Product.Role>> result = RoleAPI.getInstance().getAccountRoles(null, 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isEmpty());
		}
	}

	@IsTest
	static void test_getAccountRoles_unsupported_product() {
		System.runAs(UserMock.createDocuSignGenerator()) {
			Test.startTest();
			Map<String, Map<UUID, Product.Role>> result = RoleAPI.getInstance().getAccountRoles(
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
			response.setBody('{"groups":[{"source_product_name":"clm","group_name":"' + ClmProduct.ROLE_ADMINISTRATOR + '"}]}');
			return response;
		}
	}

	@IsTest
	static void test_getAccountRoles_invalid_group() {
		Test.setMock(HttpCalloutMock.class, new InvalidGroupMock());

		System.runAs(UserMock.createClmViewer()) {
			Test.startTest();
			Map<String, Map<UUID, Product.Role>> result = RoleAPI.getInstance().getAccountRoles(
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
			Set<String> products = new Set<String> { Product.ESIGNATURE, Product.GEN, Product.NEGOTIATE, Product.CLM };

			Test.startTest();
			Map<String, Map<UUID, Product.Role>> result = RoleAPI.getInstance().getAccountRoles(products, 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(4, result.size());
			System.assertEquals(products, result.keySet());
			List<Product.Role> roles = result.get(Product.ESIGNATURE).values();
			System.assertEquals(3, Collection.size(roles));
			System.assertNotEquals(null, roles[0]);
			System.assertEquals(RoleAPI.ESIGNATURE_ADMINISTRATOR_ID, roles[0].id);
			System.assertNotEquals(null, roles[1]);
			System.assertEquals(RoleAPI.ESIGNATURE_USER_ID, roles[1].id);
			System.assertNotEquals(null, roles[2]);
			System.assertEquals(RoleAPI.ESIGNATURE_SENDER_ID, roles[2].id);
			roles = result.get(Product.GEN).values();
			System.assertEquals(1, Collection.size(roles));
			System.assertNotEquals(null, roles[0]);
			roles = result.get(Product.NEGOTIATE).values();
			System.assertEquals(1, Collection.size(roles));
			System.assertNotEquals(null, roles[0]);
			roles = result.get(Product.CLM).values();
			System.assertEquals(3, Collection.size(roles));
			System.assertNotEquals(null, roles[0]);
			System.assertNotEquals(null, roles[1]);
			System.assertNotEquals(null, roles[2]);
		}
	}

	@IsTest
	static void test_createAccountRole_undefined() {
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Product.Role pr = new Product.Role(
				UUID.randomUUID(),
				Product.GEN,
				GenProduct.ROLE_GENERATOR,
				Label.Generator,
				false);

			Test.startTest();
			Product.Role result1 = RoleAPI.getInstance().createAccountRole(null, '1234', 30000);
			Product.Role result2 = RoleAPI.getInstance().createAccountRole(pr, null, 30000);
			Product.Role result3 = RoleAPI.getInstance().createAccountRole(pr, ' ', 30000);
			Test.stopTest();

			System.assertEquals(null, result1);
			System.assertEquals(null, result2);
			System.assertEquals(null, result3);
		}
	}

	@IsTest
	static void test_createAccountRole_error() {
		RoleAPIMock.failure();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			Product.Role r = new Product.Role(
				null,
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				false);

			Test.startTest();
			try {
				RoleAPI.getInstance().createAccountRole(r, '1234', 30000);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
				System.assert(ex.error instanceof ProvisioningAPI.Error);
			}
			Test.stopTest();
		}
	}

	class UnexpectedResponseMock extends OAuthTokenMock {

		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(201);
			response.setStatus('CREATED');
			response.setHeader('Content-Type', 'application/json');
			response.setHeader('X-DocuSign-TraceToken', UUID.randomUUID().toString());
			RoleAPI.APIGroup g = new RoleAPI.APIGroup(null, null);
			g.ds_group_id = UUID.randomUUID().toString();
			g.source_product_name = 'whatever';
			g.group_id = '88';
			g.group_name = 'some group';
			g.is_admin = false;
			response.setBody(JSON.serialize(g));
			return response;
		}
	}

	@IsTest
	static void test_createAccountRole_unexpected_response() {
		Test.setMock(HttpCalloutMock.class, new UnexpectedResponseMock());

		System.runAs(UserMock.createClmViewer()) {
			Product.Role r = new Product.Role(
				null,
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				false);

			Test.startTest();
			Product.Role result = RoleAPI.getInstance().createAccountRole(r, '1234', 30000);
			Test.stopTest();

			System.assertEquals(null, result);
		}
	}

	@IsTest
	static void test_createAccountRole_success() {
		RoleAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			Product.Role r = new Product.Role(
				null,
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				false);

			Test.startTest();
			Product.Role result = RoleAPI.getInstance().createAccountRole(r, '1234', 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertEquals(r.product, result.product);
			System.assertEquals(r.role, result.role);
			System.assertEquals(r.role, result.label);
			System.assertEquals(r.isAdministrator, result.isAdministrator);
		}
	}

	@IsTest
	static void test_getProductRoles_undefined_product() {
		System.runAs(UserMock.createClmAdministrator()) {
			Test.startTest();
			Map<String, Map<String, Product.Role>> result1 = RoleAPI.getInstance().getProductRoles(null, 30000);
			Map<String, Map<String, Product.Role>> result2 = RoleAPI.getInstance().getProductRoles(new Set<String>(), 30000);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1.isEmpty());
			System.assertNotEquals(null, result2);
			System.assert(result2.isEmpty());
		}
	}

	@IsTest
	static void test_getProductRoles_eSignature() {
		System.runAs(UserMock.createClmAdministrator()) {
			Test.startTest();
			Map<String, Map<String, Product.Role>> result = RoleAPI.getInstance().getProductRoles(new Set<String> { Product.ESIGNATURE }, 30000);
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
				RoleAPI.getInstance().getProductRoles(new Set<String> { Product.CLM }, 30000);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
				System.assert(ex.error instanceof ProvisioningAPI.Error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getProductRoles_success() {
		RoleAPIMock.success();

		System.runAs(UserMock.createDocuSignGenerator()) {
			Set<String> products = new Set<String> { Product.GEN, Product.NEGOTIATE, Product.CLM };

			Test.startTest();
			Map<String, Map<String, Product.Role>> result = RoleAPI.getInstance().getProductRoles(products, 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			System.assertEquals(products, result.keySet());
			System.assertNotEquals(null, result.get(Product.GEN));
			System.assertEquals(1, result.get(Product.GEN).size());
			System.assertNotEquals(null, result.get(Product.NEGOTIATE));
			System.assertEquals(1, result.get(Product.NEGOTIATE).size());
			System.assertNotEquals(null, result.get(Product.CLM));
			System.assertEquals(3, result.get(Product.CLM).size());
		}
	}

	@IsTest
	static void test_getProductRoles_other() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Map<String, Map<String, Product.Role>> result = RoleAPI.getInstance().getProductRoles(new Set<String> { 'other' }, 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isEmpty());
		}
	}

	@IsTest
	static void test_getRoles_undefined_argument() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Map<String, Map<UUID, Product.Role>> result = RoleAPI.getInstance().getRoles(null);
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
					response.setBody(JSON.serialize(new Map<String, Object> { 'group' => g }));

				}
			} else if (endpoint.contains('/products/')) { // get product groups
				response.setStatusCode(200);
				response.setStatus('OK');
				RoleAPI.APIGroups gs = new RoleAPI.APIGroups();
				gs.groups = new List<RoleAPI.APIGroup>();
				String query = new Url(endpoint).getQuery();

				if (query.contains('clm')) {
					RoleAPI.APIGroup g = new RoleAPI.APIGroup(null, null);
					g.group_id = '0';
					g.group_name = 'Super Administrator';
					g.description = 'Administrators!';
					g.source_product_name = 'clm';
					g.is_admin = true;
					gs.groups.add(g);
					g = new RoleAPI.APIGroup(null, null);
					g.group_id = '2';
					g.group_name = 'Full Subscriber';
					g.description = 'Users!';
					g.source_product_name = 'clm';
					g.is_admin = true;
					gs.groups.add(g);
					g = new RoleAPI.APIGroup(null, null);
					g.group_id = '99';
					g.group_name = 'Guest';
					g.description = 'Viewers!';
					g.source_product_name = 'clm';
					g.is_admin = true;
					gs.groups.add(g);
					g = new RoleAPI.APIGroup(null, null);
					g.group_id = '22';
					g.group_name = 'Other Admin';
					g.description = 'should ignore';
					g.source_product_name = 'clm';
					g.is_admin = true;
					gs.groups.add(g);
					g = new RoleAPI.APIGroup(null, null);
					g.group_id = '33';
					g.group_name = 'Other User';
					g.description = 'should ignore';
					g.source_product_name = 'clm';
					g.is_admin = true;
					gs.groups.add(g);
				}

				if (query.contains('gen')) {
					RoleAPI.APIGroup g = new RoleAPI.APIGroup(null, null);
					g.group_id = '0';
					g.group_name = 'Generator';
					g.description = 'Generators!';
					g.source_product_name = 'gen';
					g.is_admin = true;
					gs.groups.add(g);
				}

				if (query.contains('negotiate')) {
					RoleAPI.APIGroup g = new RoleAPI.APIGroup(null, null);
					g.group_id = '0';
					g.group_name = 'Negotiator';
					g.description = 'Negotiator!';
					g.source_product_name = 'negotiate';
					g.is_admin = true;
					gs.groups.add(g);
				}

				// Return group that should be ignored.
				RoleAPI.APIGroup g = new RoleAPI.APIGroup(null, null);
				g.group_id = '55';
				g.group_name = 'Other';
				g.description = 'should ignore';
				g.source_product_name = 'other';
				g.is_admin = true;
				gs.groups.add(g);

				response.setBody(JSON.serialize(gs));
			} else if (endpoint.contains('/dsgroups')) { // get account groups
				response.setStatusCode(200);
				response.setStatus('OK');
				RoleAPI.APIGroups gs = new RoleAPI.APIGroups();
				gs.groups = new List<RoleAPI.APIGroup>();
				RoleAPI.APIGroup g = new RoleAPI.APIGroup(null, null);
				g.ds_group_id = UUID.randomUUID().toString();
				g.group_id = '0';
				g.group_name = ClmProduct.ROLE_ADMINISTRATOR;
				g.description = 'Administrators!';
				g.source_product_name = 'clm';
				g.is_admin = true;
				gs.groups.add(g);
				g = new RoleAPI.APIGroup(null, null);
				g.ds_group_id = UUID.randomUUID().toString();
				g.group_id = '2';
				g.group_name = ClmProduct.ROLE_VIEWER;
				g.description = 'Viewers!';
				g.source_product_name = 'clm';
				g.is_admin = true;
				gs.groups.add(g);
				g = new RoleAPI.APIGroup(null, null);
				g.ds_group_id = UUID.randomUUID().toString();
				g.group_id = '0';
				g.group_name = NegotiateProduct.ROLE_NEGOTIATOR;
				g.description = 'Negotiator!';
				g.source_product_name = 'negotiate';
				g.is_admin = true;
				gs.groups.add(g);
				g = new RoleAPI.APIGroup(null, null);
				g.ds_group_id = UUID.randomUUID().toString();
				g.group_id = '22';
				g.group_name = 'Other Admins';
				g.description = 'should ignore';
				g.source_product_name = 'clm';
				g.is_admin = true;
				gs.groups.add(g);
				g = new RoleAPI.APIGroup(null, null);
				g.ds_group_id = UUID.randomUUID().toString();
				g.group_id = '33';
				g.group_name = 'Other Users';
				g.description = 'should ignore';
				g.source_product_name = 'clm';
				g.is_admin = true;
				gs.groups.add(g);
				g = new RoleAPI.APIGroup(null, null);
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
			Map<String, Map<UUID, Product.Role>> result = RoleAPI.getInstance().getRoles(new Set<String> {
				Product.CLM, Product.GEN, Product.NEGOTIATE, 'other'
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			System.assertEquals(new Set<String> { Product.CLM, Product.GEN, Product.NEGOTIATE }, result.keySet());
			System.assertNotEquals(null, result.get(Product.GEN));
			System.assertEquals(1, result.get(Product.GEN).size());
			System.assertNotEquals(null, result.get(Product.GEN).values()[0]);
			System.assertNotEquals(null, result.get(Product.GEN).values()[0].id);
			System.assertEquals(GenProduct.ROLE_GENERATOR, result.get(Product.GEN).values()[0].role);
			System.assertNotEquals(null, result.get(Product.NEGOTIATE));
			System.assertEquals(1, result.get(Product.NEGOTIATE).size());
			System.assertNotEquals(null, result.get(Product.NEGOTIATE).values()[0]);
			System.assertNotEquals(null, result.get(Product.NEGOTIATE).values()[0].id);
			System.assertEquals(NegotiateProduct.ROLE_NEGOTIATOR, result.get(Product.NEGOTIATE).values()[0].role);
			System.assertNotEquals(null, result.get(Product.CLM));
			System.assertEquals(3, result.get(Product.CLM).size());
			System.assertNotEquals(null, result.get(Product.CLM).values()[0]);
			System.assertNotEquals(null, result.get(Product.CLM).values()[0].id);
			System.assertNotEquals(null, result.get(Product.CLM).values()[1]);
			System.assertNotEquals(null, result.get(Product.CLM).values()[1].id);
			System.assertNotEquals(null, result.get(Product.CLM).values()[2]);
			System.assertNotEquals(null, result.get(Product.CLM).values()[2].id);
			System.assertEquals(
				new Set<String> {
					ClmProduct.ROLE_USER, ClmProduct.ROLE_ADMINISTRATOR, ClmProduct.ROLE_VIEWER
				},
				new Set<String> {
					result.get(Product.CLM).values()[0].role,
					result.get(Product.CLM).values()[1].role,
					result.get(Product.CLM).values()[2].role
				});
		}
	}

	@IsTest
	static void test_addRoleUsers_empty() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			RoleAPI client = RoleAPI.getInstance();

			Test.startTest();
			RoleAPI.UserResults result1 = client.addRoleUsers(null, new Set<UUID> { UUID.randomUUID() }, 10000);
			RoleAPI.UserResults result2 = client.addRoleUsers(UUID.randomUUID(), new Set<UUID>(), 10000);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(!result1.success);
			System.assertNotEquals(null, result2);
			System.assert(!result2.success);
		}
	}

	@IsTest
	static void test_addRoleUsers_error() {
		RoleAPIMock.failure();

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Set<UUID> userIds = new Set<UUID> {
				UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID()
			};

			Test.startTest();
			try {
				RoleAPI.getInstance().addRoleUsers(UUID.randomUUID(), userIds, 30000);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
				System.assert(ex.error instanceof ProvisioningAPI.Error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_addRoleUsers_success() {
		RoleAPIMock.success();

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Set<UUID> userIds = new Set<UUID> {
				UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID()
			};

			Test.startTest();
			RoleAPI.UserResults result = RoleAPI.getInstance().addRoleUsers(UUID.randomUUID(), userIds, 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
			System.assertNotEquals(null, result.results);
			System.assertEquals(3, result.results.size());
			for (UUID uId : result.results.keySet()) {
				System.assert(userIds.contains(uId));
				System.assertEquals(APIError.none, result.results.get(uId));
			}
		}
	}

	class UserPartialSuccessMock extends OAuthTokenMock {
		private final Set<String> toFail;

		public UserPartialSuccessMock(final Set<String> toFail) {
			this.toFail = toFail == null ? new Set<String>() : toFail;
		}

		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setHeader('Content-Type', 'application/json');
			response.setStatusCode(200);
			response.setStatus('OK');
			RoleAPI.APIUsers users = (RoleAPI.APIUsers)JSON.deserialize(request.getBody(), RoleAPI.APIUsers.class);
			if (request.getMethod() == 'POST') { // add users
				RoleAPI.APIAddUserResult result = new RoleAPI.APIAddUserResult();
				result.group_users = new RoleAPI.APIGroupUsers();
				result.group_users.is_success = false;
				result.group_users.users = new List<RoleAPI.APIGroupUser>();
				for (String uId : users.user_ids) {
					RoleAPI.APIGroupUser u = new RoleAPI.APIGroupUser();
					u.user_id = uId;
					if (this.toFail.contains(uId)) {
						u.error_details = new RoleAPI.APIErrorDetails();
						u.error_details.error = 'invalid_request';
						u.error_details.error_description = 'User is already a member';
					}
					result.group_users.users.add(u);
				}
				response.setBody(JSON.serialize(result));
			} else { // remove users
				RoleAPI.APIRemoveUserResult result = new RoleAPI.APIRemoveUserResult();
				result.is_success = false;
				result.failed_users = new List<RoleAPI.APIGroupUser>();
				for (String uId : users.user_ids) {
					if (this.toFail.contains(uId)) {
						RoleAPI.APIGroupUser u = new RoleAPI.APIGroupUser();
						u.user_id = uId;
						u.error_details = new RoleAPI.APIErrorDetails();
						u.error_details.error = 'invalid_request';
						u.error_details.error_description = 'User is not a member';
						result.failed_users.add(u);
					}
				}
				response.setBody(JSON.serialize(result));
			}
			return response;
		}
	}

	@IsTest
	static void test_addRoleUsers_success_partial() {
		UUID uId1 = UUID.randomUUID(),
			uId2 = UUID.randomUUID(),
			uId3 = UUID.randomUUID(),
			uId4 = UUID.randomUUID();
		Test.setMock(HttpCalloutMock.class, new UserPartialSuccessMock(
			new Set<String> { uId1.toString(), uId3.toString() }));

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			RoleAPI.UserResults result = RoleAPI.getInstance().addRoleUsers(UUID.randomUUID(), new Set<UUID> { uId1, uId2, uId3, uId4 }, 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!result.success);
			System.assertNotEquals(null, result.results);
			System.assertEquals(4, result.results.size());
			APIError err = new APIError(APIErrorCode.INVALID_OPERATION, 'User is already a member');
			System.assertEquals(err, result.results.get(uId1));
			System.assertEquals(APIError.none, result.results.get(uId2));
			System.assertEquals(err, result.results.get(uId3));
			System.assertEquals(APIError.none, result.results.get(uId4));
		}
	}

	@IsTest
	static void test_addRoleUsers_multiple() {
		UUID rId1 = UUID.randomUUID(),
			rId2 = UUID.randomUUID(),
			rId3 = UUID.randomUUID(),
			uId1 = UUID.randomUUID(),
			uId2 = UUID.randomUUID(),
			uId3 = UUID.randomUUID(),
			uId4 = UUID.randomUUID(),
			uId5 = UUID.randomUUID(),
			uId6 = UUID.randomUUID();
		Map<UUID, Set<UUID>> roleUsers = new Map<UUID, Set<UUID>> {
			rId1 => new Set<UUID> { uId1, uId2 },
			rId2 => new Set<UUID> { uId3, uId4 },
			rId3 => new Set<UUID> { uId5, uId6 }
		};
		Test.setMock(HttpCalloutMock.class, new UserPartialSuccessMock(
			new Set<String> { uId2.toString(), uId5.toString() }));

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Map<UUID, RoleAPI.UserResults> result = RoleAPI.getInstance().addRoleUsers(roleUsers);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			System.assertNotEquals(null, result.get(rId1));
			System.assertNotEquals(null, result.get(rId1).results);
			System.assertEquals(new Set<UUID> { uId1, uId2 }, result.get(rId1).results.keySet());
			System.assertNotEquals(null, result.get(rId2));
			System.assertNotEquals(null, result.get(rId2).results);
			System.assertEquals(new Set<UUID> { uId3, uId4 }, result.get(rId2).results.keySet());
			System.assertNotEquals(null, result.get(rId3));
			System.assertNotEquals(null, result.get(rId3).results);
			System.assertEquals(new Set<UUID> { uId5, uId6 }, result.get(rId3).results.keySet());
		}
	}

	@IsTest
	static void test_addRoleUsers_esign() {
		UUID rId1 = RoleAPI.ESIGNATURE_ADMINISTRATOR_ID,
			rId2 = RoleAPI.ESIGNATURE_USER_ID,
			rId3 = RoleAPI.ESIGNATURE_SENDER_ID,
			uId1 = UUID.randomUUID(),
			uId2 = UUID.randomUUID(),
			uId3 = UUID.randomUUID(),
			uId4 = UUID.randomUUID(),
			uId5 = UUID.randomUUID(),
			uId6 = UUID.randomUUID();
		Map<UUID, Set<UUID>> roleUsers = new Map<UUID, Set<UUID>> {
			rId1 => new Set<UUID> { uId1, uId2 },
			rId2 => new Set<UUID> { uId3, uId4 },
			rId3 => new Set<UUID> { uId5, uId6 }
		};

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Map<UUID, RoleAPI.UserResults> result = RoleAPI.getInstance().addRoleUsers(roleUsers);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			System.assertNotEquals(null, result.get(rId1));
			System.assertNotEquals(null, result.get(rId1).results);
			System.assertEquals(new Set<UUID> { uId1, uId2 }, result.get(rId1).results.keySet());
			System.assertNotEquals(null, result.get(rId2));
			System.assertNotEquals(null, result.get(rId2).results);
			System.assertEquals(new Set<UUID> { uId3, uId4 }, result.get(rId2).results.keySet());
			System.assertNotEquals(null, result.get(rId3));
			System.assertNotEquals(null, result.get(rId3).results);
			System.assertEquals(new Set<UUID> { uId5, uId6 }, result.get(rId3).results.keySet());
		}
	}

	@IsTest
	static void test_removeRoleUsers_empty() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			RoleAPI client = RoleAPI.getInstance();

			Test.startTest();
			RoleAPI.UserResults result1 = client.removeRoleUsers(null, new Set<UUID> { UUID.randomUUID() }, 10000);
			RoleAPI.UserResults result2 = client.removeRoleUsers(UUID.randomUUID(), new Set<UUID>(), 10000);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(!result1.success);
			System.assertNotEquals(null, result2);
			System.assert(!result2.success);
		}
	}

	@IsTest
	static void test_removeRoleUsers_error() {
		RoleAPIMock.failure();

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Set<UUID> userIds = new Set<UUID> {
				UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID()
			};

			Test.startTest();
			try {
				RoleAPI.getInstance().removeRoleUsers(UUID.randomUUID(), userIds, 30000);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
				System.assert(ex.error instanceof ProvisioningAPI.Error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_removeRoleUsers_success() {
		RoleAPIMock.success();

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Set<UUID> userIds = new Set<UUID> {
				UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID()
			};

			Test.startTest();
			RoleAPI.UserResults result = RoleAPI.getInstance().removeRoleUsers(UUID.randomUUID(), userIds, 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
			System.assertNotEquals(null, result.results);
			System.assertEquals(3, result.results.size());
			for (UUID uId : result.results.keySet()) {
				System.assert(userIds.contains(uId));
				System.assertEquals(APIError.none, result.results.get(uId));
			}
		}
	}

	@IsTest
	static void test_removeRoleUsers_success_partial() {
		UUID uId1 = UUID.randomUUID(),
			uId2 = UUID.randomUUID(),
			uId3 = UUID.randomUUID(),
			uId4 = UUID.randomUUID();
		Test.setMock(HttpCalloutMock.class, new UserPartialSuccessMock(
			new Set<String> { uId1.toString(), uId3.toString() }));

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			RoleAPI.UserResults result = RoleAPI.getInstance().removeRoleUsers(UUID.randomUUID(), new Set<UUID> { uId1, uId2, uId3, uId4 }, 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!result.success);
			System.assertNotEquals(null, result.results);
			System.assertEquals(4, result.results.size());
			APIError err = new APIError(APIErrorCode.INVALID_OPERATION, 'User is not a member');
			System.assertEquals(err, result.results.get(uId1));
			System.assertEquals(APIError.none, result.results.get(uId2));
			System.assertEquals(err, result.results.get(uId3));
			System.assertEquals(APIError.none, result.results.get(uId4));
		}
	}

	@IsTest
	static void test_removeRoleUsers_multiple() {
		UUID rId1 = UUID.randomUUID(),
			rId2 = UUID.randomUUID(),
			rId3 = UUID.randomUUID(),
			uId1 = UUID.randomUUID(),
			uId2 = UUID.randomUUID(),
			uId3 = UUID.randomUUID(),
			uId4 = UUID.randomUUID(),
			uId5 = UUID.randomUUID(),
			uId6 = UUID.randomUUID();
		Map<UUID, Set<UUID>> roleUsers = new Map<UUID, Set<UUID>> {
			rId1 => new Set<UUID> { uId1, uId2 },
			rId2 => new Set<UUID> { uId3, uId4 },
			rId3 => new Set<UUID> { uId5, uId6 }
		};
		Test.setMock(HttpCalloutMock.class, new UserPartialSuccessMock(
			new Set<String> { uId2.toString(), uId5.toString() }));

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Map<UUID, RoleAPI.UserResults> result = RoleAPI.getInstance().removeRoleUsers(roleUsers);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			System.assertNotEquals(null, result.get(rId1));
			System.assertNotEquals(null, result.get(rId1).results);
			System.assertEquals(new Set<UUID> { uId1, uId2 }, result.get(rId1).results.keySet());
			System.assertNotEquals(null, result.get(rId2));
			System.assertNotEquals(null, result.get(rId2).results);
			System.assertEquals(new Set<UUID> { uId3, uId4 }, result.get(rId2).results.keySet());
			System.assertNotEquals(null, result.get(rId3));
			System.assertNotEquals(null, result.get(rId3).results);
			System.assertEquals(new Set<UUID> { uId5, uId6 }, result.get(rId3).results.keySet());
		}
	}

	@IsTest
	static void test_removeRoleUsers_esign() {
		UUID rId1 = RoleAPI.ESIGNATURE_ADMINISTRATOR_ID,
			rId2 = RoleAPI.ESIGNATURE_USER_ID,
			rId3 = RoleAPI.ESIGNATURE_SENDER_ID,
			uId1 = UUID.randomUUID(),
			uId2 = UUID.randomUUID(),
			uId3 = UUID.randomUUID(),
			uId4 = UUID.randomUUID(),
			uId5 = UUID.randomUUID(),
			uId6 = UUID.randomUUID();
		Map<UUID, Set<UUID>> roleUsers = new Map<UUID, Set<UUID>> {
			rId1 => new Set<UUID> { uId1, uId2 },
			rId2 => new Set<UUID> { uId3, uId4 },
			rId3 => new Set<UUID> { uId5, uId6 }
		};

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Map<UUID, RoleAPI.UserResults> result = RoleAPI.getInstance().removeRoleUsers(roleUsers);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			System.assertNotEquals(null, result.get(rId1));
			System.assertNotEquals(null, result.get(rId1).results);
			System.assertEquals(new Set<UUID> { uId1, uId2 }, result.get(rId1).results.keySet());
			System.assertNotEquals(null, result.get(rId2));
			System.assertNotEquals(null, result.get(rId2).results);
			System.assertEquals(new Set<UUID> { uId3, uId4 }, result.get(rId2).results.keySet());
			System.assertNotEquals(null, result.get(rId3));
			System.assertNotEquals(null, result.get(rId3).results);
			System.assertEquals(new Set<UUID> { uId5, uId6 }, result.get(rId3).results.keySet());
		}
	}

	class UnknownErrorMock extends OAuthTokenMock {

		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setHeader('Content-Type', 'application/json');
			response.setStatusCode(200);
			response.setStatus('OK');
			RoleAPI.APIRemoveUserResult result = new RoleAPI.APIRemoveUserResult();
			result.is_success = false;
			result.failed_users = new List<RoleAPI.APIGroupUser>();
			RoleAPI.APIUsers users = (RoleAPI.APIUsers)JSON.deserialize(request.getBody(), RoleAPI.APIUsers.class);
			for (String uId : users.user_ids) {
				RoleAPI.APIGroupUser u = new RoleAPI.APIGroupUser();
				u.user_id = uId;
				result.failed_users.add(u);
			}
			response.setBody(JSON.serialize(result));
			return response;
		}
	}

	@IsTest
	static void test_removeRoleUsers_unknown_error() {
		UUID uId = UUID.randomUUID();
		Test.setMock(HttpCalloutMock.class, new UnknownErrorMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			RoleAPI.UserResults result = RoleAPI.getInstance().removeRoleUsers(UUID.randomUUID(), new Set<UUID> { uId }, 30000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!result.success);
			System.assertNotEquals(null, result.results);
			System.assertEquals(1, result.results.size());
			System.assertNotEquals(null, result.results.get(uId));
			System.assertEquals(APIErrorCode.FAILURE, result.results.get(uId).code);
			System.assertEquals(Label.UnknownError, result.results.get(uId).description);
		}
	}
}
