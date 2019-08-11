public with sharing class RoleAPI extends ProvisioningAPI {

	private static RoleAPI self;
	@TestVisible
	private static final String ROLE_GEN_GENERATORS = 'Generators';
	@TestVisible
	private static final String ROLE_NEGOTIATE_NEGOTIATORS = 'Negotiators';
	@TestVisible
	private static final String ROLE_CLM_ADMINISTRATORS = 'Administrators';
	@TestVisible
	private static final String ROLE_CLM_USERS = 'Users';
	@TestVisible
	private static final String ROLE_CLM_VIEWERS = 'Viewers';
	// This is a map of product groups to application roles.
	private static final Map<String, Map<String, String>> PRODUCT_GROUP_ROLE_MAP = new Map<String, Map<String, String>> {
		Product.ESIGNATURE => new Map<String, String> {
			// TODO: map eSign groups to roles (v2, pending API support)
		},
		Product.GEN => new Map<String, String> {
			// TODO: map Gen groups to roles (pending API support)
			'Generator' => ROLE_GEN_GENERATORS
		},
		Product.NEGOTIATE => new Map<String, String> {
			// TODO: map Negotiator groups to roles (pending API support)
			'Negotiator' => ROLE_NEGOTIATE_NEGOTIATORS
		},
		Product.CLM => new Map<String, String> {
			'Super Administrator' => ROLE_CLM_ADMINISTRATORS,
			'Full Subscriber' => ROLE_CLM_USERS,
			'Guest' => ROLE_CLM_ADMINISTRATORS
		}
	};
	private static final Map<String, Set<String>> PRODUCT_ROLE_MAP = new Map<String, Set<String>> {
		Product.ESIGNATURE => new Set<String>(),
		Product.GEN => new Set<String> {
			ROLE_GEN_GENERATORS
		},
		Product.NEGOTIATE => new Set<String> {
			ROLE_NEGOTIATE_NEGOTIATORS
		},
		Product.CLM => new Set<String> {
			ROLE_CLM_ADMINISTRATORS,
			ROLE_CLM_USERS,
			ROLE_CLM_VIEWERS
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

		public APIGroup(final Product.Role role) {
			if (role != null) {
				this.ds_group_id = String.valueOf(role.id);
				this.group_id = String.valueOf(role.groupId);
				this.group_name = role.name;
				this.description = role.description;
				this.source_product_name = role.product;
				this.is_admin = role.isAdministrator == true;
			}
		}

		public Product.Role toExternalForm() {
			if (String.isBlank(this.source_product_name)
				|| String.isBlank(this.group_name)
				|| String.isBlank(this.group_id)) {

				LoggerService.getInstance().warn('Invalid group for role');
				return null;
			}

			return new Product.Role(
				UUID.tryParse(this.ds_group_id),
				this.group_id == null ? null : Long.valueOf(this.group_id),
				this.source_product_name.toLowerCase(),
				this.group_name,
				this.description,
				this.is_admin == true);
		}

		public Product.Role toExternalForm(final Map<String, String> groupRoles) {
			if (groupRoles == null
				|| String.isBlank(this.source_product_name)
				|| String.isBlank(this.group_name)
				|| String.isBlank(this.group_id)
				|| !groupRoles.containsKey(this.group_name)) {

				// Only add groups to which we have a role mapped
				LoggerService.getInstance().warn(String.format('No role mapped to product "{0}" group "{1}" ({2})',
					new List<Object> { this.source_product_name, this.group_name, this.group_id }));
				return null;
			}

			return new Product.Role(
				UUID.tryParse(this.ds_group_id),
				this.group_id == null ? null : Long.valueOf(this.group_id),
				this.source_product_name.toLowerCase(),
				groupRoles.get(this.group_name),
				this.description,
				this.is_admin == true);
		}
	}

	@TestVisible
	private class APIGroups {
		public List<APIGroup> groups;

		public List<Product.Role> toExternalForm(final Map<String, String> groupRoles) {
			List<Product.Role> result = new List<Product.Role>();
			if (this.groups != null) {
				for (APIGroup g : this.groups) {
					Product.Role r = g.toExternalForm(groupRoles);
					if (r != null) result.add(r);
				}
			}
			return result;
		}
	}

	@TestVisible
	private Map<String, List<Product.Role>> getAccountRoles(
		final Set<String> products,
		final Integer timeout) {

		Map<String, List<Product.Role>> result = new Map<String, List<Product.Role>>();
		if (Collection.isEmpty(products)) return result;

		for (String product : products) {
			if (PRODUCT_ROLE_MAP.containsKey(product)) {
				result.put(product, new List<Product.Role>());
			} else {
				this.log.warn('Unsupported product: ' + product);
			}
		}

		if (result.isEmpty()) return result;

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
				String product = g.source_product_name == null ? '' : g.source_product_name.toLowerCase();
				// Only add if it's in the product role whitelist.
				if (result.containsKey(product) && PRODUCT_ROLE_MAP.get(product).contains(g.group_name)) {
					Product.Role r = g.toExternalForm();
					if (r != null) result.get(product).add(r);
				}
			}
		}

		return result;
	}

	@TestVisible
	private Product.Role createAccountRole(
		final Product.Role role,
		final Integer timeout) {

		if (role == null) return null;

		RestAPI.Response response = this.post(
			new List<Object> { 'dsgroups' },
			QueryString.empty,
			JSON.serialize(new APIGroup(role)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to create account role: ' + response.error);
			throw new APIException(response.error);
		}

		return ((APIGroup)JSON.deserialize(response.body, APIGroup.class)).toExternalForm();
	}

	@TestVisible
	private List<Product.Role> getProductRoles(
		final String product,
		final Integer timeout) {

		if (String.isBlank(product)) return new List<Product.Role>();

		RestAPI.Response response = this.get(
			new List<Object> { 'products', product, 'groups' },
			QueryString.empty,
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get product roles: ' + response.error);
			throw new APIException(response.error);
		}

		return ((APIGroups)JSON.deserialize(response.body, APIGroups.class))
			.toExternalForm(PRODUCT_GROUP_ROLE_MAP.get(product));
	}

	private static Set<String> getRoleDifference(
		final Set<String> expectedRoles,
		final List<Product.Role> currentRoles) {

		if (Collection.isEmpty(currentRoles)) return expectedRoles;

		Set<String> crs = new Set<String>();
		for (Product.Role r : currentRoles) {
			if (r != null && r.name != null) crs.add(r.name);
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
	public Map<String, List<Product.Role>> getRoles(final Set<String> products) {
		return this.getRoles(products, RestAPI.defaultTimeout);
	}

	public Map<String, List<Product.Role>> getRoles(
		final Set<String> products,
		final Integer timeout) {

		// Read any existing account roles.
		Map<String, List<Product.Role>> result = this.getAccountRoles(products, timeout);
		List<Product.Role> toCreate = new List<Product.Role>();
		for (String product : result.keySet()) {
			Set<String> expectedRoles = new Set<String>(PRODUCT_GROUP_ROLE_MAP.get(product).values());
			List<Product.Role> currentRoles = result.get(product);
			Set<String> missingRoles = getRoleDifference(expectedRoles, currentRoles);

			// Find product groups for roles that do not already exist on the account.
			if (Collection.isNotEmpty(missingRoles)) {
				for (Product.Role pr : this.getProductRoles(product, timeout)) {
					if (pr != null && missingRoles.contains(pr.name)) {
						toCreate.add(pr);
					}
				}
			}
		}

		// Create account groups that don't already exist
		for (Product.Role r : toCreate) {
			result.get(r.product).add(this.createAccountRole(r, timeout));
		}

		return result;
	}
}
