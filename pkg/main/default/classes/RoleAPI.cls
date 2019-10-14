public with sharing class RoleAPI extends ProvisioningAPI {

	private static RoleAPI self;

	// TODO: Use hardcoded, fake IDs for eSignature roles until API supports them.
	@TestVisible
	private static final UUID ESIGNATURE_ADMINISTRATOR_ID = UUID.parse('11111111-1111-1111-1111-111111111111');
	@TestVisible
	private static final UUID ESIGNATURE_USER_ID = UUID.parse('22222222-2222-2222-2222-222222222222');
	@TestVisible
	private static final UUID ESIGNATURE_SENDER_ID = UUID.parse('33333333-3333-3333-3333-333333333333');
	private static final Set<UUID> ESIGNATURE_IDS = new Set<UUID> {
		ESIGNATURE_ADMINISTRATOR_ID, ESIGNATURE_USER_ID, ESIGNATURE_SENDER_ID
	};
	// This is a map of product groups to application roles.
	private static final Map<String, Map<String, String>> PRODUCT_GROUP_ROLE_MAP = new Map<String, Map<String, String>> {
		Product.ESIGNATURE => new Map<String, String> {
			// TODO: map eSign groups to roles (v2, pending API support)
			'Administrator' => ESignatureProduct.ROLE_ADMINISTRATOR,
			'User' => ESignatureProduct.ROLE_USER,
			'Sender' => ESignatureProduct.ROLE_SENDER
		},
		Product.GEN => new Map<String, String> {
			'0' => GenProduct.ROLE_GENERATOR
		},
		Product.NEGOTIATE => new Map<String, String> {
			'0' => NegotiateProduct.ROLE_NEGOTIATOR
		},
		Product.CLM => new Map<String, String> {
			'0' => ClmProduct.ROLE_ADMINISTRATOR,
			'2' => ClmProduct.ROLE_USER,
			'99' => ClmProduct.ROLE_VIEWER
		}
	};

	private RoleAPI(
		final Url baseUrl,
		final UUID accountId) {

		super(
			baseUrl,
			String.format('/management/v1/accounts/{0}/', new List<Object> { accountId }),
			null);
	}

	public static RoleAPI getInstance() {
		if (self == null) {
			Credentials c = Credentials.getInstance();
			self = new RoleAPI(c.environment.provisioningBaseUrl, c.account.id);
		}
		return self;
	}

	@TestVisible
	private class APIGroup {
		public String ds_group_id;
		public String group_id;
		public String group_name;
		public String description;
		public String source_product_name;
		public Boolean is_admin;

		public APIGroup(
			final Product.Role role,
			final String groupId) {

			if (role != null && String.isNotBlank(groupId)) {
				this.ds_group_id = String.valueOf(role.id);
				this.group_id = groupId;
				this.group_name = role.role;
				this.description = Label.ProductRoleDescription;
				this.source_product_name = role.product;
				this.is_admin = role.isAdministrator == true;
			}
		}

		public Product.Role toExternalForm(final String role) {
			if (String.isBlank(role)
				|| String.isBlank(this.source_product_name)
				|| String.isBlank(this.group_id)) {

				LoggerService.getInstance().warn('Invalid group for role ' + role);
				return null;
			}

			return new Product.Role(
				UUID.tryParse(this.ds_group_id),
				this.source_product_name.toLowerCase(),
				role,
				Product.getRoleLabel(role),
				this.is_admin == true);
		}

		public Product.Role toExternalForm(
			final String productName,
			final Map<String, String> groupRoles) {

			if (groupRoles == null
				|| String.isBlank(this.group_id)
				|| !groupRoles.containsKey(this.group_id)) {

				// Only add groups to which we have a role mapped
				LoggerService.getInstance().warn(String.format('No role mapped to product "{0}" group "{1}" ({2})',
					new List<Object> { productName, this.group_name, this.group_id }));
				return null;
			}

			String role = groupRoles.get(this.group_id);
			return new Product.Role(
				UUID.tryParse(this.ds_group_id),
				productName,
				role,
				Product.getRoleLabel(role),
				this.is_admin == true);
		}
	}

	private static String getProductName(final String product) {
		return product == null ? '' : product.toLowerCase();
	}

	@TestVisible
	private class APIGroups {
		public List<APIGroup> groups;

		// Returns a map of products -> map of group IDs -> roles
		public Map<String, Map<String, Product.Role>> toExternalForm(
			final Map<String, Map<String, String>> productGroupRoles) {

			Map<String, Map<String, Product.Role>> result = new Map<String, Map<String, Product.Role>>();
			if (this.groups != null) {
				for (APIGroup g : this.groups) {
					String productName = g == null ? '' : getProductName(g.source_product_name);
					if (Product.isValidProduct(productName)) {
						if (!result.containsKey(productName)) result.put(productName, new Map<String, Product.Role>());

						Product.Role r = g.toExternalForm(productName, productGroupRoles.get(productName));
						if (r != null) result.get(productName).put(g.group_id, r);
					}
				}
			}
			return result;
		}
	}

	private static List<String> filterValid(final Set<String> products) {
		List<String> result = new List<String>();

		if (products != null) {
			for (String p : products) {
				if (Product.isValidProduct(p)) result.add(p.toLowerCase());
			}
		}

		return result;
	}

	private String getRoleName(
		final String productName,
		final String groupId) {

		if (String.isBlank(productName) || String.isBlank(groupId)) return null;

		Map<String, String> roles = PRODUCT_GROUP_ROLE_MAP.get(productName);
		return roles == null ? null : roles.get(groupId);
	}

	@TestVisible
	private Map<String, Map<UUID, Product.Role>> getAccountRoles(
		final Set<String> products,
		final Integer timeout) {

		Map<String, Map<UUID, Product.Role>> result = new Map<String, Map<UUID, Product.Role>>();
		List<String> filteredProducts = filterValid(products);
		if (Collection.isEmpty(filteredProducts)) return result;

		for (String p : filteredProducts) {
			result.put(p, new Map<UUID, Product.Role>());
		}

		// TODO: Special case for eSignature until full API support (v2?)
		if (result.containsKey(Product.ESIGNATURE)) {
			result.get(Product.ESIGNATURE).putAll(new Map<UUID, Product.Role> {
				ESIGNATURE_ADMINISTRATOR_ID => new Product.Role(
					ESIGNATURE_ADMINISTRATOR_ID,
					Product.ESIGNATURE,
					ESignatureProduct.ROLE_ADMINISTRATOR,
					Label.Administrator,
					true),
				ESIGNATURE_USER_ID => new Product.Role(
					ESIGNATURE_USER_ID,
					Product.ESIGNATURE,
					ESignatureProduct.ROLE_USER,
					Label.User,
					false),
				ESIGNATURE_SENDER_ID => new Product.Role(
					ESIGNATURE_SENDER_ID,
					Product.ESIGNATURE,
					ESignatureProduct.ROLE_SENDER,
					Label.Sender,
					false)
			});

			// Short-circuit if this is the only requested product
			if (result.size() == 1) return result;
		}

		// TODO: Implement paging. Is not yet functional in current API.
		RestAPI.Response response = this.get(
			new List<Object> { 'dsgroups' },
			QueryString.empty,
			timeout);
		if (response.hasError) {
			this.log.error('Failed to read account roles: ' + response.error);
			throw new APIException(response.error);
		}

		APIGroups gs = ((APIGroups)JSON.deserialize(response.body, APIGroups.class));
		if (gs != null && gs.groups != null) {
			for (APIGroup g : gs.groups) {
				String productName = g == null ? '' : getProductName(g.source_product_name);
				String role = g == null ? null : getRoleName(productName, g.group_id);
				// Only add if it's in the product role whitelist.
				if (result.containsKey(productName) && String.isNotBlank(role)) {
					Product.Role r = g.toExternalForm(role);
					if (r != null) result.get(productName).put(r.id, r);
				}
			}
		}

		return result;
	}

	@TestVisible
	private Product.Role createAccountRole(
		final Product.Role role,
		final String groupId,
		final Integer timeout) {

		if (role == null || String.isBlank(groupId)) return null;

		RestAPI.Response response = this.post(
			new List<Object> { 'dsgroups' },
			QueryString.empty,
			JSON.serialize(new APIGroup(role, groupId)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to create account role: ' + response.error);
			throw new APIException(response.error);
		}

		// Cannot deserialize directly to object due to 'group' property (reserved keyword).
		Product.Role result = null;
		Map<String, Object> newGroup = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		if (newGroup != null && newGroup.containsKey('group')) {
			result = ((APIGroup)JSON.deserialize(
				JSON.serialize(newGroup.get('group')),
				APIGroup.class)).toExternalForm(role.role);
		} else {
			this.log.error('Unexpected response when creating account role:\n' + response.body);
		}
		return result;
	}

	@TestVisible
	private Map<String, Map<String, Product.Role>> getProductRoles(
		final Set<String> products,
		final Integer timeout) {

		List<String> filteredProducts = filterValid(products);
		// Remove e_sign product from the list as it's not currently supported by MAGNUM.
		Integer eSignIndex = filteredProducts.indexOf(Product.ESIGNATURE);
		if (eSignIndex >= 0) filteredProducts.remove(eSignIndex);
		if (Collection.isEmpty(filteredProducts)) return new Map<String, Map<String, Product.Role>>();

		RestAPI.Response response = this.get(
			new List<Object> { 'products', 'groups' },
			new QueryString(new Map<String, String> {
				'products' => String.join(filteredProducts, ',')
			}),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get product roles: ' + response.error);
			throw new APIException(response.error);
		}

		return ((APIGroups)JSON.deserialize(response.body, APIGroups.class))
			.toExternalForm(PRODUCT_GROUP_ROLE_MAP);
	}

	private static Set<String> getRoleDifference(
		final Set<String> expectedRoles,
		final List<Product.Role> currentRoles) {

		if (Collection.isEmpty(currentRoles)) return expectedRoles;

		Set<String> crs = new Set<String>();
		for (Product.Role r : currentRoles) {
			if (r != null && r.role != null) crs.add(r.role);
		}

		return Collection.difference(expectedRoles, crs);
	}

	/*
		This method retrieves product roles from the MAGNUM API. Behind the scenes:
		1. Read account groups.
		2. Look for groups we care about.
		3. If any group doesn't exist, read product groups.
		4. Create each missing account group.
	 */
	public Map<String, Map<UUID, Product.Role>> getRoles(final Set<String> products) {
		return this.getRoles(products, RestAPI.defaultTimeout);
	}

	public Map<String, Map<UUID, Product.Role>> getRoles(
		final Set<String> products,
		final Integer timeout) {

		// Filter out invalid products
		List<String> filteredProducts = filterValid(products);
		if (Collection.isEmpty(filteredProducts)) return new Map<String, Map<UUID, Product.Role>>();

		// Read any existing account roles.
		Map<String, Map<UUID, Product.Role>> result = this.getAccountRoles(products, timeout);

		// Determine which roles should be on the account.
		Map<String, Set<String>> missingRoles = new Map<String, Set<String>>();
		Map<String, Map<String, Product.Role>> productGroupRolesToCreate = new Map<String, Map<String, Product.Role>>();
		for (String product : result.keySet()) {
			Set<String> expectedRoles = new Set<String>(PRODUCT_GROUP_ROLE_MAP.get(product).values());
			Map<UUID, Product.Role> currentRoles = result.get(product);
			missingRoles.put(product, getRoleDifference(expectedRoles, currentRoles.values()));
		}

		// Find product groups for roles that do not already exist on the account.
		if (Collection.isNotEmpty(missingRoles)) {
			Map<String, Map<String, Product.Role>> productGroupRoles = this.getProductRoles(missingRoles.keySet(), timeout);
			for (String product : productGroupRoles.keySet()) {
				Map<String, Product.Role> groupRoles = productGroupRoles.get(product);
				Map<String, Product.Role> groupRolesToCreate = new Map<String, Product.Role>();
				for (String groupId : groupRoles.keySet()) {
					Product.Role role = groupRoles.get(groupId);
					if (role != null && missingRoles.get(product).contains(role.role)) {
						groupRolesToCreate.put(groupId, role);
					}
				}
				if (!groupRolesToCreate.isEmpty()) productGroupRolesToCreate.put(product, groupRolesToCreate);
			}
		}

		// Create account groups that don't already exist
		for (String product : productGroupRolesToCreate.keySet()) {
			Map<String, Product.Role> groupRolesToCreate = productGroupRolesToCreate.get(product);
			for (String groupId : groupRolesToCreate.keySet()) {
				Product.Role role = this.createAccountRole(groupRolesToCreate.get(groupId), groupId, timeout);
				if (role == null || !result.containsKey(role.product)) throw new DocuSignException(Label.UnsupportedProductRoles);
				result.get(role.product).put(role.id, role);
			}
		}

		return result;
	}

	@TestVisible
	private class UserResults {
		public Boolean success { get; private set; }
		public Map<UUID, APIError> results;

		public UserResults(
			final Boolean success,
			final Map<UUID, APIError> results) {

			this.success = success == true;
			this.results = results == null ? new Map<UUID, APIError>() : results;
		}
	}

	@TestVisible
	private class APIUsers {
		public List<String> user_ids;

		public APIUsers(final Set<UUID> ids) {
			this.user_ids = new List<String>();
			if (ids != null) {
				for (UUID id : ids) {
					if (UUID.isNotEmpty(id)) this.user_ids.add(id.toString());
				}
			}
		}
	}

	@TestVisible
	private class APIErrorDetails {
		public String error;
		public String error_description;

		public APIError toExternalForm() {
			return new APIError(
				this.error == 'invalid_request' ? APIErrorCode.INVALID_OPERATION : APIErrorCode.FAILURE,
				this.error_description);
		}
	}

	@TestVisible
	private class APIGroupUser {
		public String user_id;
		public APIErrorDetails error_details;
	}

	@TestVisible
	private class APIGroupUsers {
		public Boolean is_success;
		public List<APIGroupUser> users;

		public UserResults toExternalForm() {
			Map<UUID, APIError> results = new Map<UUID, APIError>();
			if (users != null) {
				for (APIGroupUser u : users) {
					if (u != null && String.isNotBlank(u.user_id)) {
						results.put(
							UUID.tryParse(u.user_id),
							u.error_details == null ? APIError.none : u.error_details.toExternalForm());
					}
				}
			}
			return new UserResults(this.is_success, results);
		}
	}

	@TestVisible
	private class APIAddUserResult {
		public APIGroupUsers group_users;

		public UserResults toExternalForm() {
			if (this.group_users == null) return new UserResults(false, null);

			return this.group_users.toExternalForm();
		}
	}

	@TestVisible
	private UserResults addRoleUsers(
		final UUID roleId,
		final Set<UUID> userIds,
		final Integer timeout) {

		Map<UUID, APIError> result = new Map<UUID, APIError>();
		if (UUID.isEmpty(roleId) || Collection.isEmpty(userIds)) return new UserResults(false, result);

		// TODO: No API support for eSignature roles, so just return success here.
		if (ESIGNATURE_IDS.contains(roleId)) {
			for (UUID uId : userIds) {
				result.put(uId, APIError.none);
			}
			return new UserResults(true, result);
		}

		RestAPI.Response response = this.post(
			new List<Object> { 'dsgroups', roleId, 'users' },
			QueryString.empty,
			JSON.serialize(new APIUsers(userIds)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to add role users: ' + response.error);
			throw new APIException(response.error);
		}

		return ((APIAddUserResult)JSON.deserialize(response.body, APIAddUserResult.class)).toExternalForm();
	}

	public Map<UUID, UserResults> addRoleUsers(
		final Map<UUID, Account.User> users,
		final Map<UUID, Product.Role> roles) {

		return this.addRoleUsers(users, roles, RestAPI.defaultTimeout);
	}

	public Map<UUID, UserResults> addRoleUsers(
		final Map<UUID, Account.User> users,
		final Map<UUID, Product.Role> roles,
		final Integer timeout) {

		if (Collection.isEmpty(users) || Collection.isEmpty(roles)) return new Map<UUID, UserResults>();

		return this.addRoleUsers(
			getRolesToAdd(users.keySet(), filterCurrentUser(users).keySet(), roles),
			RestAPI.defaultTimeout);
	}

	@TestVisible
	private Map<UUID, UserResults> addRoleUsers(
		final Map<UUID, Set<UUID>> roleUsers,
		final Integer timeout) {

		Map<UUID, UserResults> result = new Map<UUID, UserResults>();
		if (roleUsers != null) {
			for (UUID roleId : roleUsers.keySet()) {
				result.put(roleId, this.addRoleUsers(roleId, roleUsers.get(roleId), timeout));
			}
		}
		return result;
	}

	@TestVisible
	private class APIRemoveUserResult {
		public Boolean is_success;
		public List<APIGroupUser> failed_users;

		public UserResults toExternalForm(final Set<UUID> userIds) {
			Map<UUID, APIError> results = new Map<UUID, APIError>();

			if (userIds == null) return new UserResults(true, results);

			if (this.is_success == true) {
				for (UUID uId : userIds) {
					if (UUID.isNotEmpty(uId)) results.put(uId, APIError.none);
				}
			} else if (this.failed_users != null) {
				for (APIGroupUser u : this.failed_users) {
					if (u != null && String.isNotBlank(u.user_id)) {
						results.put(
							UUID.tryParse(u.user_id),
							u.error_details == null
								? new APIError(APIErrorCode.FAILURE, Label.UnknownError)
								: u.error_details.toExternalForm());
					}
				}
			}

			for (UUID uId : (Set<UUID>)Collection.difference(userIds, results.keySet())) {
				// No results for these users, assume success
				if (UUID.isNotEmpty(uId)) results.put(uId, APIError.none);
			}

			return new UserResults(this.is_success == true, results);
		}
	}

	@TestVisible
	private UserResults removeRoleUsers(
		final UUID roleId,
		final Set<UUID> userIds,
		final Integer timeout) {

		Map<UUID, APIError> result = new Map<UUID, APIError>();
		if (UUID.isEmpty(roleId) || Collection.isEmpty(userIds)) return new UserResults(false, result);

		// TODO: No API support for eSignature roles, so just return success here.
		if (ESIGNATURE_IDS.contains(roleId)) {
			for (UUID uId : userIds) {
				result.put(uId, APIError.none);
			}
			return new UserResults(true, result);
		}

		RestAPI.Response response = this.del(
			new List<Object> { 'dsgroups', roleId, 'users' },
			QueryString.empty,
			JSON.serialize(new APIUsers(userIds)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to remove role users: ' + response.error);
			throw new APIException(response.error);
		}

		return ((APIRemoveUserResult)JSON.deserialize(response.body, APIRemoveUserResult.class))
			.toExternalForm(userIds);
	}

	@TestVisible
	private Map<UUID, UserResults> removeRoleUsers(
		final Map<UUID, Set<UUID>> roleUsers,
		final Integer timeout) {

		Map<UUID, UserResults> result = new Map<UUID, UserResults>();
		if (roleUsers != null) {
			for (UUID roleId : roleUsers.keySet()) {
				result.put(roleId, this.removeRoleUsers(roleId, roleUsers.get(roleId), timeout));
			}
		}
		return result;
	}

	@TestVisible
	private static Map<UUID, Account.User> filterCurrentUser(final Map<UUID, Account.User> users) {
		Map<UUID, Account.User> result = new Map<UUID, Account.User>();
		if (Collection.isNotEmpty(users)) {
			Id currentUserId = UserInfo.getUserId();
			for (UUID uId : users.keySet()) {
				Account.User u = users.get(uId);
				if (u != null && u.sourceId != currentUserId) result.put(uId, u);
			}
		}
		return result;
	}

	@TestVisible
	private static Map<UUID, Set<UUID>> getRolesToRemove(
		final Set<UUID> allUserIds,
		final Set<UUID> filteredUserIds,
		final Map<UUID, Product.Role> allRoles,
		final Map<UUID, Product.Role> newRoles) {

		Map<UUID, Set<UUID>> result = new Map<UUID, Set<UUID>>();
		if (Collection.isNotEmpty(allUserIds) && Collection.isNotEmpty(allRoles) && newRoles != null) {
			Boolean hasFilteredUsers = Collection.isNotEmpty(filteredUserIds);
			for (UUID roleId : Collection.difference(allRoles.keySet(), newRoles.keySet())) {
				// If is an admin role, use filtered list so as not to remove current user's access.
				Product.Role role = allRoles.get(roleId);
				if (role != null) {
					if (hasFilteredUsers && role.isAdministrator) {
						result.put(roleId, filteredUserIds);
					} else {
						result.put(roleId, allUserIds);
					}
				}
			}
		}
		return result;
	}

	@TestVisible
	private static Map<UUID, Product.Role> filterLesserPrivilegedRoles(final Map<UUID, Product.Role> roles) {
		Map<UUID, Product.Role> result = new Map<UUID, Product.Role>();
		if (Collection.isNotEmpty(roles)) {
			UUID dsAdminId = null, dsUserId = null, dsSenderId = null,
				clmAdminId = null, clmUserId = null, clmViewerId = null;
			for (UUID rId : roles.keySet()) {
				Product.Role r = roles.get(rId);
				if (r != null && r.product == Product.ESIGNATURE) {
					if (r.role == ESignatureProduct.ROLE_ADMINISTRATOR) {
						dsAdminId = rId;
					} else if (r.role == ESignatureProduct.ROLE_USER) {
						dsUserId = rId;
					} else if (r.role == ESignatureProduct.ROLE_SENDER) {
						dsSenderId = rId;
					}
				} else if (r != null && r.product == Product.CLM) {
					if (r.role == ClmProduct.ROLE_ADMINISTRATOR) {
						clmAdminId = rId;
					} else if (r.role == ClmProduct.ROLE_USER) {
						clmUserId = rId;
					} else if (r.role == ClmProduct.ROLE_VIEWER) {
						clmViewerId = rId;
					}
				}

				if (r != null) result.put(rId, r);
			}

			// Don't bother with lesser privileged roles if superseded by a higher privileged one.
			if (dsSenderId != null && (dsUserId != null || dsAdminId != null)) {
				result.remove(dsSenderId);
			}

			if (dsUserId != null && dsAdminId != null) {
				result.remove(dsUserId);
			}

			if (clmViewerId != null && (clmUserId != null || clmAdminId != null)) {
				result.remove(clmViewerId);
			}

			if (clmUserId != null && clmAdminId != null) {
				result.remove(clmUserId);
			}
		}
		return result;
	}

	private static Boolean isLesserPrivilegedRole(final Product.Role role) {
		return role != null
			&& (role.product == Product.ESIGNATURE || role.product == Product.CLM)
			&& !role.isAdministrator;
	}

	@TestVisible
	private static Map<UUID, Set<UUID>> getRolesToAdd(
		final Set<UUID> allUserIds,
		final Set<UUID> filteredUserIds,
		final Map<UUID, Product.Role> newRoles) {

		Map<UUID, Set<UUID>> result = new Map<UUID, Set<UUID>>();
		if (Collection.isNotEmpty(allUserIds) && Collection.isNotEmpty(newRoles)) {
			// Filter out current user for lesser-privileged roles
			Boolean hasFilteredUsers = Collection.isNotEmpty(filteredUserIds);
			for (UUID rId : newRoles.keySet()) {
				Product.Role r = newRoles.get(rId);
				if (r != null) {
					if (hasFilteredUsers && isLesserPrivilegedRole(r)) {
						result.put(rId, filteredUserIds);
					} else {
						result.put(rId, allUserIds);
					}
				}
			}
		}
		return result;
	}

	@TestVisible
	private static Map<UUID, Account.User> getUsersToUpdate(
		final Map<UUID, Account.User> users,
		final Set<UUID> newRoleIds) {

		Map<UUID, Account.User> result = new Map<UUID, Account.User>();
		if (Collection.isNotEmpty(users) && Collection.isNotEmpty(newRoleIds)) {
			Id currentUserId = UserInfo.getUserId();
			if (newRoleIds.contains(ESIGNATURE_ADMINISTRATOR_ID)) {
				for (UUID uId : users.keySet()) {
					Account.User u = users.get(uId);
					if (u != null && u.sourceId != currentUserId) result.put(uId, u.withCanManageAccount(true));
				}
			} else if (newRoleIds.contains(ESIGNATURE_USER_ID)) {
				for (UUID uId : users.keySet()) {
					Account.User u = users.get(uId);
					if (u != null && u.sourceId != currentUserId) result.put(uId, u.withCanManageAccount(false));
				}
			} // else no change
		}
		return result;
	}

	private static Map<UUID, Account.User> updateUserResults(
		final Map<UUID, Account.User> users,
		final Map<UUID, Account.User> updatedUsers,
		final Map<UUID, UserResults> userResults) {

		Map<UUID, Account.User> result = updatedUsers == null ? new Map<UUID, Account.User>() : updatedUsers;
		if (Collection.isNotEmpty(users) && Collection.isNotEmpty(userResults)) {
			for (UUID rId : userResults.keySet()) {
				UserResults ur = userResults.get(rId);
				if (ur != null && ur.results != null) {
					for (UUID uId : ur.results.keySet()) {
						Account.User u = result.get(uId);
						if (u == null) {
							u = users.get(uId);
						}
						if (u != null) {
							APIError e = ur.results.get(uId);
							result.put(uId, e == null || e == APIError.none ? u : u.withError(e));
						}
					}
				}
			}
		}
		return result;
	}

	public Map<UUID, Account.User> updateUserRoles(
		final Map<UUID, Account.User> users,
		final Map<UUID, Product.Role> allRoles,
		final Map<UUID, Product.Role> newRoles) {

		return this.updateUserRoles(users, allRoles, newRoles, RestAPI.defaultTimeout);
	}

	public Map<UUID, Account.User> updateUserRoles(
		final Map<UUID, Account.User> users,
		final Map<UUID, Product.Role> allRoles,
		final Map<UUID, Product.Role> newRoles,
		final Integer timeout) {

		Map<UUID, Account.User> result = new Map<UUID, Account.User>();
		if (Collection.isNotEmpty(users) && Collection.isNotEmpty(allRoles)) {
			// Update users via UserAPI if eSign roles have changed, filtering out current user.
			Map<UUID, Account.User> filteredUsers = filterCurrentUser(users);
			Map<UUID, Product.Role> filteredRoles = filterLesserPrivilegedRoles(newRoles);
			Map<UUID, Account.User> toUpdate = getUsersToUpdate(
				filteredUsers == null ? new Map<UUID, Account.User>() : filteredUsers,
				filteredRoles == null ? new Set<UUID>() : filteredRoles.keySet());
			if (Collection.isNotEmpty(toUpdate)) {
				Map<UUID, Account.User> updatedUsers = UserAPI.getInstance().updateUsers(toUpdate, timeout);
				if (Collection.isNotEmpty(updatedUsers)) {
					for (UUID uId : updatedUsers.keySet()) {
						Account.User u = updatedUsers.get(uId);
						Account.User uu = users.get(uId);
						if (u != null && uu != null) {
							result.put(uId, uu.withError(u.error));
						}
					}
				}
			}

			// Add/remove roles via MAGNUM
			Set<UUID> allUserIds = users.keySet();
			Set<UUID> filteredUserIds = filteredUsers == null ? new Set<UUID>() : filteredUsers.keySet();
			Map<UUID, Set<UUID>> toRemove = getRolesToRemove(allUserIds, filteredUserIds, allRoles, filteredRoles);
			Map<UUID, Set<UUID>> toAdd = getRolesToAdd(allUserIds, filteredUserIds, filteredRoles);

			result = updateUserResults(users, result, this.removeRoleUsers(toRemove, timeout));
			result = updateUserResults(users, result, this.addRoleUsers(toAdd, timeout));
		}
		return result;
	}
}
