@IsTest
public class RoleAPIMock extends OAuthTokenMock {

	private static final Pattern PATH_PATTERN = Pattern.compile(
		'\\/management\\/([^\\/]+)\\/accounts(\\/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|\\d+)(\\/?(.+))?)?');

	private final Boolean success;

	public RoleAPIMock(final Boolean success) {
		super(!success);
		this.success = success;
	}

	public static RoleAPIMock success() {
		return (RoleAPIMock)TestUtils.setMock(new RoleAPIMock(true));
	}

	public static RoleAPIMock failure() {
		return (RoleAPIMock)TestUtils.setMock(new RoleAPIMock(false));
	}

	/* Supported routes:
		- GET /management/v1/accounts/{{account-id}}/products/{{product}}/groups
		- GET /management/v1/accounts/{{account-id}}/dsgroups
		- POST /management/v1/accounts/{{account-id}}/dsgroups
		- POST /management/v1/accounts/{{account-id}}/dsgroups/{{ds-group-id}}/users
		- DELETE /management/v1/accounts/{{account-id}}/dsgroups/{{ds-group-id}}/users
	 */
	override public HttpResponse getResponse(final HttpRequest request) {
		HttpResponse response = new HttpResponse();
		if (this.success) {
			String method = request.getMethod();
			String endpoint = request.getEndpoint();
			Url u = new Url(endpoint);
			Matcher m = PATH_PATTERN.matcher(u.getPath());
			if (!m.matches()) throw new AssertException('API request endpoint was not in expected format: ' + u.getPath());

			//String accountId = m.group(2);

			response.setHeader('Content-Type', 'application/json');
			response.setHeader('X-DocuSign-TraceToken', UUID.randomUUID().toString());

			if (method == 'POST') {
				response.setStatusCode(201);
				response.setStatus('CREATED');
				if (endpoint.endsWith('/users')) { // add dsgroup users
					RoleAPI.APIAddUserResult result = new RoleAPI.APIAddUserResult();
					result.group_users = new RoleAPI.APIGroupUsers();
					result.group_users.is_success = true;
					result.group_users.users = new List<RoleAPI.APIGroupUser>();
					RoleAPI.APIUsers users = (RoleAPI.APIUsers)JSON.deserialize(request.getBody(), RoleAPI.APIUsers.class);
					if (users != null && users.user_ids != null) {
						for (String uId : users.user_ids) {
							RoleAPI.APIGroupUser gu = new RoleAPI.APIGroupUser();
							gu.user_id = uId;
							result.group_users.users.add(gu);
						}
					}
					response.setBody(JSON.serialize(result));
				} else { // add account dsgroups
					RoleAPI.APIGroup g = (RoleAPI.APIGroup)JSON.deserialize(request.getBody(), RoleAPI.APIGroup.class);
					g.ds_group_id = UUID.randomUUID().toString();
					response.setBody(JSON.serialize(g));

				}
			} else if (method == 'DELETE') { // remove dsgroup users
				response.setStatusCode(200);
				response.setStatus('OK');
				RoleAPI.APIRemoveUserResult result = new RoleAPI.APIRemoveUserResult();
				result.is_success = true;
				response.setBody(JSON.serialize(result));
			} else if (method == 'GET' && endpoint.contains('/products/')) { // get product groups
				response.setStatusCode(200);
				response.setStatus('OK');
				RoleAPI.APIGroups gs = new RoleAPI.APIGroups();
				String query = u.getQuery();
				gs.groups = new List<RoleAPI.APIGroup>();
				if (query.contains('clm')) {
					RoleAPI.APIGroup g = new RoleAPI.APIGroup(null, null);
					g.group_id = '0';
					g.group_name = 'Super Administrator';
					g.description = 'Administrators!';
					g.source_product_name = 'clm';
					g.is_admin = true;
					gs.groups.add(g);
					g = new RoleAPI.APIGroup(null, null);
					g.group_id = '1';
					g.group_name = 'Full Subscriber';
					g.description = 'Users!';
					g.source_product_name = 'clm';
					g.is_admin = true;
					gs.groups.add(g);
					g = new RoleAPI.APIGroup(null, null);
					g.group_id = '2';
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

				// Add a group that should be ignored
				RoleAPI.APIGroup g = new RoleAPI.APIGroup(null, null);
				g.group_id = '55';
				g.group_name = 'Other';
				g.description = 'should ignore';
				g.source_product_name = 'other';
				g.is_admin = true;
				gs.groups.add(g);

				response.setBody(JSON.serialize(gs));
			} else if (method == 'GET' && endpoint.contains('/dsgroups')) { // get account groups
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
				g.group_id = '1';
				g.group_name = ClmProduct.ROLE_USER;
				g.description = 'Users!';
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
				g.group_id = '3';
				g.group_name = GenProduct.ROLE_GENERATOR;
				g.description = 'Generators!';
				g.source_product_name = 'gen';
				g.is_admin = true;
				gs.groups.add(g);
				g = new RoleAPI.APIGroup(null, null);
				g.ds_group_id = UUID.randomUUID().toString();
				g.group_id = '4';
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
		} else {
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json');
			response.setBody('{"error":"unit_test","error_description":"test error","reference_id":"' + UUID.randomUUID() + '"}');
		}
		return response;
	}
}
