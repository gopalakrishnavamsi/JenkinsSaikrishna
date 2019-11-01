/**
 * Available DocuSign account features.
 */
public with sharing class AccountProducts {

	@TestVisible
	private static final AccountProducts.Database DB = new AccountProducts.Database();
	@TestVisible
	private static AccountProducts self = null;
	private static final Integer DEFAULT_CHECK_FREQUENCY_MIN = 60; // 1 hour
	private static final Set<String> VALID_PRODUCT_TRIALS = new Set<String> { Product.GEN, Product.NEGOTIATE };

	@TestVisible
	private static final Integer FLAG_MERGE_FIELDS = 1;
	@TestVisible
	private static final Integer FLAG_TEMPLATES = 2;
	@TestVisible
	private static final Integer FLAG_SIGNING_GROUPS = 4;
	@TestVisible
	private static final Integer FLAG_SMS_AUTHENTICATION = 8;
	@TestVisible
	private static final Integer FLAG_BULK_SENDING = 16;

	@TestVisible
	private final Map<String, Product> products;
	private final Datetime lastChecked;
	private final Integer checkFrequencyMinutes;
	@TestVisible
	private Boolean isDirty;
	private DocuSign.Environment environment;
	@TestVisible
	private static List<Product.Role> newRoles;

	@AuraEnabled
	public ESignatureProduct eSignature {
		get {
			return (ESignatureProduct)this.products.get(Product.ESIGNATURE);
		}
	}

	@AuraEnabled
	public GenProduct gen {
		get {
			return (GenProduct)this.products.get(Product.GEN);
		}
	}

	@AuraEnabled
	public NegotiateProduct negotiate {
		get {
			return (NegotiateProduct)this.products.get(Product.NEGOTIATE);
		}
	}

	@AuraEnabled
	public ClmProduct clm {
		get {
			return (ClmProduct)this.products.get(Product.CLM);
		}
	}

	@TestVisible
	private AccountProducts(
		final DocuSign.Environment environment,
		final Map<String, Product> products,
		final Datetime lastChecked,
		final Integer checkFrequencyMinutes,
		final Boolean isDirty) {

		this.environment = environment;
		this.products = products == null ? new Map<String, Product>() : products;
		this.lastChecked = lastChecked;
		this.checkFrequencyMinutes = checkFrequencyMinutes;
		this.isDirty = isDirty;
	}

	private class Database {

		@TestVisible
		private Integer packFeatures(final Set<ESignatureProduct.Feature> features) {
			Integer result = 0;
			if (features != null) {
				for (ESignatureProduct.Feature f : features) {
					if (f == ESignatureProduct.Feature.MergeFields) {
						result |= FLAG_MERGE_FIELDS;
					} else if (f == ESignatureProduct.Feature.Templates) {
						result |= FLAG_TEMPLATES;
					} else if (f == ESignatureProduct.Feature.SigningGroups) {
						result |= FLAG_SIGNING_GROUPS;
					} else if (f == ESignatureProduct.Feature.SmsAuthentication) {
						result |= FLAG_SMS_AUTHENTICATION;
					} else if (f == ESignatureProduct.Feature.BulkSending) {
						result |= FLAG_BULK_SENDING;
					}
				}
			}
			return result;
		}

		@TestVisible
		private Set<ESignatureProduct.Feature> unpackFeatures(final Integer features) {
			Set<ESignatureProduct.Feature> result = new Set<ESignatureProduct.Feature>();
			if ((features & FLAG_MERGE_FIELDS) == FLAG_MERGE_FIELDS) {
				result.add(ESignatureProduct.Feature.MergeFields);
			}
			if ((features & FLAG_TEMPLATES) == FLAG_TEMPLATES) {
				result.add(ESignatureProduct.Feature.Templates);
			}
			if ((features & FLAG_SIGNING_GROUPS) == FLAG_SIGNING_GROUPS) {
				result.add(ESignatureProduct.Feature.SigningGroups);
			}
			if ((features & FLAG_SMS_AUTHENTICATION) == FLAG_SMS_AUTHENTICATION) {
				result.add(ESignatureProduct.Feature.SmsAuthentication);
			}
			if ((features & FLAG_BULK_SENDING) == FLAG_BULK_SENDING) {
				result.add(ESignatureProduct.Feature.BulkSending);
			}
			return result;
		}

		@TestVisible
		private ProductSettings__c convert(final Product product) {
			ProductSettings__c result = null;
			if (product != null) {
				result = new ProductSettings__c(
					Name = product.name,
					Status__c = product.status,
					IsTrial__c = product.isTrial,
					TrialExpires__c = product.trialExpires,
					Features__c = product instanceof ESignatureProduct
						? packFeatures(((ESignatureProduct)product).features)
						: null);
			}
			return result;
		}

		@TestVisible
		private Product convert(
			final ProductSettings__c product,
			final AccountSettings__c account) {

			Product result = null;
			switch on (product == null ? '' : product.Name) {
				when 'e_sign' {
					result = new ESignatureProduct(
						product.Status__c,
						product.IsTrial__c == true,
						product.TrialExpires__c,
						product.Features__c == null ? null : unpackFeatures(Integer.valueOf(product.Features__c)));
				} when 'gen' {
					result = new GenProduct(
						product.Status__c,
						product.IsTrial__c == true,
						product.TrialExpires__c,
						account == null || account.ScmWebBaseUrl__c == null ? null : new Url(account.ScmWebBaseUrl__c),
						account == null || account.ScmApiBaseUrl__c == null ? null : new Url(account.ScmApiBaseUrl__c),
						account == null || account.ScmMergeBaseUrl__c == null ? null : new Url(account.ScmMergeBaseUrl__c));
				} when 'negotiate' {
					result = new NegotiateProduct(
						product.Status__c,
						product.IsTrial__c == true,
						product.TrialExpires__c,
						account == null || account.ScmWebBaseUrl__c == null ? null : new Url(account.ScmWebBaseUrl__c),
						account == null || account.ScmApiBaseUrl__c == null ? null : new Url(account.ScmApiBaseUrl__c),
						account == null || account.ScmMergeBaseUrl__c == null ? null : new Url(account.ScmMergeBaseUrl__c));
				} when 'clm' {
					result = new ClmProduct(
						product.Status__c,
						product.IsTrial__c == true,
						product.TrialExpires__c,
						account == null || account.ScmWebBaseUrl__c == null ? null : new Url(account.ScmWebBaseUrl__c),
						account == null || account.ScmAuthBaseUrl__c == null ? null : new Url(account.ScmAuthBaseUrl__c));
				}
			}
			return result;
		}

		private Map<String, Product> queryProducts() {
			Map<String, Product> result = new Map<String, Product>();
			Map<String, ProductSettings__c> pss = ProductSettings__c.getAll();
			AccountSettings__c accs = AccountSettings__c.getOrgDefaults();
			if (pss != null) {
				for (String key : pss.keySet()) {
					ProductSettings__c ps = pss.get(key);
					if (String.isNotBlank(key) && ps != null) result.put(key, convert(ps, accs));
				}
			}
			return result;
		}

		private List<ProductSettings__c> replaceProductSettings(final List<Product> products) {
			delete ProductSettings__c.getAll().values();
			List<ProductSettings__c> productSettings = new List<ProductSettings__c>();
			for (Product p : products) {
				if (p != null) productSettings.add(convert(p));
			}
			insert productSettings;
			return productSettings;
		}

		public List<ProductSettings__c> deleteProductSettings() {
			List<ProductSettings__c> result = ProductSettings__c.getAll().values();
			delete result;
			return result;
		}

		public List<ProductRoleSettings__c> deleteProductRoleSettings() {
			List<ProductRoleSettings__c> result = ProductRoleSettings__c.getAll().values();
			delete result;
			return result;
		}

		public List<ProductRoleSettings__c> deleteProductRoleSettings(final Set<String> products) {
			List<ProductRoleSettings__c> result = new List<ProductRoleSettings__c>();
			for (ProductRoleSettings__c prs : ProductRoleSettings__c.getAll().values()) {
				if (prs != null && products.contains(prs.ProductName__c)) result.add(prs);
			}
			delete result;
			return result;
		}

		private AccountSettings__c upsertAccountSettings(
			final Url scmWebBaseUrl,
			final Url scmApiBaseUrl,
			final Url scmMergeBaseUrl,
			final Url scmAuthBaseUrl,
			final Datetime lastChecked,
			final Integer checkFrequencyMinutes) {

			AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
			accountSettings.ScmWebBaseUrl__c = scmWebBaseUrl == null ? null : scmWebBaseUrl.toExternalForm();
			accountSettings.ScmApiBaseUrl__c = scmApiBaseUrl == null ? null : scmApiBaseUrl.toExternalForm();
			accountSettings.ScmMergeBaseUrl__c = scmMergeBaseUrl == null ? null : scmMergeBaseUrl.toExternalForm();
			accountSettings.ScmAuthBaseUrl__c = scmAuthBaseUrl == null ? null : scmAuthBaseUrl.toExternalForm();
			accountSettings.ProductsLastChecked__c = lastChecked == null ? Datetime.now() : lastChecked;
			accountSettings.ProductsCheckFrequency__c = checkFrequencyMinutes == null || checkFrequencyMinutes <= 0
				? DEFAULT_CHECK_FREQUENCY_MIN : checkFrequencyMinutes;
			upsert accountSettings;
			return accountSettings;
		}

		public List<Product> replaceProducts(
			final List<Product> products,
			final Url scmWebBaseUrl,
			final Url scmApiBaseUrl,
			final Url scmMergeBaseUrl,
			final Url scmAuthBaseUrl,
			final Datetime lastChecked,
			final Integer checkFrequencyMinutes) {

			if (products != null) {
				replaceProductSettings(products);
				upsertAccountSettings(
					scmWebBaseUrl,
					scmApiBaseUrl,
					scmMergeBaseUrl,
					scmAuthBaseUrl,
					lastChecked,
					checkFrequencyMinutes);
			}
			return products;
		}

		private Product.Role convert(final ProductRoleSettings__c pr) {
			if (pr == null) return null;

			return new Product.Role(
				UUID.tryParse(pr.RoleId__c),
				pr.ProductName__c,
				pr.RoleName__c,
				Product.getRoleLabel(pr.RoleName__c),
				pr.IsAdministrator__c == true);
		}

		@TestVisible
		private String getProductRoleKey(
			final String product,
			final String role) {

			return (product == null ? '' : product.toLowerCase()) + ':' + (role == null ? '' : role.toLowerCase());
		}

		private ProductRoleSettings__c convert(final Product.Role pr) {
			if (pr == null) return null;

			return new ProductRoleSettings__c(
				Name = this.getProductRoleKey(pr.product, pr.role),
				IsAdministrator__c = pr.isAdministrator == true,
				ProductName__c = pr.product == null ? null : pr.product.toLowerCase(),
				RoleId__c = String.valueOf(pr.id),
				RoleName__c = pr.role == null ? null : pr.role.toLowerCase());
		}

		public Map<String, List<Product.Role>> queryProductRoles() {
			Map<String, List<Product.Role>> result = new Map<String, List<Product.Role>>();
			for (ProductRoleSettings__c pr : ProductRoleSettings__c.getAll().values()) {
				Product.Role r = convert(pr);
				if (r != null && String.isNotBlank(r.product)) {
					if (!result.containsKey(r.product)) {
						result.put(r.product, new List<Product.Role> { r });
					} else {
						result.get(r.product).add(r);
					}
				}
			}
			return result;
		}

		public Boolean insertProductRoles(final List<Product.Role> productRoles) {
			Boolean result = false;
			if (productRoles != null) {
				List<ProductRoleSettings__c> toInsert = new List<ProductRoleSettings__c>();
				for (Product.Role pr : productRoles) {
					if (pr != null) toInsert.add(convert(pr));
				}
				insert toInsert;
				result = true;
			}
			return result;
		}
	}

	public Boolean isESignatureTrialExpired() {
		Product p = this.products.get(Product.ESIGNATURE);
		return p != null && p.isExpired;
	}

	public Boolean isESignatureEnabled() {
		Product p = this.products.get(Product.ESIGNATURE);
		return p != null && !p.isExpired;
	}

	public Boolean isGenEnabled() {
		Product p = this.products.get(Product.GEN);
		return p != null && !p.isExpired;
	}

	public Boolean isNegotiateEnabled() {
		Product p = this.products.get(Product.NEGOTIATE);
		return p != null && !p.isExpired;
	}

	public Boolean isClmEnabled() {
		Product p = this.products.get(Product.CLM);
		return p != null && !p.isExpired;
	}

	@TestVisible
	private static AccountProducts refreshProducts() {
		Credentials c = Credentials.getInstance();
		return resolveProducts(
			null,
			null,
			null,
			c.environment.environment,
			c.environment.provisioningBaseUrl,
			c.environment.eSignatureBaseUrl,
			c.account.id,
			c.token.token);
	}

	@TestVisible
	private static AccountProducts resolveProducts(
		final Map<String, Product> configuredProducts,
		final Datetime lastChecked,
		final Integer checkFrequencyMinutes,
		final DocuSign.Environment environment,
		final Url provisioningBaseUrl,
		final Url eSignatureBaseUrl,
		final UUID accountId,
		final String accessToken) {

		AccountProducts result = null;
		if (Permissions.isDocuSignAdministrator() && (configuredProducts == null
			|| lastChecked == null
			|| checkFrequencyMinutes == null
			|| lastChecked.addMinutes(checkFrequencyMinutes) <= Datetime.now())) {

			Map<String, Product> products = new Map<String, Product>();
			products.put(
				Product.ESIGNATURE,
				ESignatureProductAPI.getInstance(eSignatureBaseUrl, accountId, accessToken).getProduct());
			ProductAPI client = ProductAPI.getInstance(provisioningBaseUrl, accountId, accessToken);
			for (Product p : client.getProducts()) {
				if (p != null) {
					Product pp;
					if (p.status == Product.STATUS_PENDING) { // Activate any pending products we care about.
						LoggerService.getInstance().info('Activating product: ' + p.name);
						pp = client.activateProduct(p.name, false);
					} else {
						pp = p;
					}
					products.put(pp.name, pp);
				}
			}
			result = new AccountProducts(environment, products, Datetime.now(), checkFrequencyMinutes, true);
		} else {
			result = new AccountProducts(environment, configuredProducts, lastChecked, checkFrequencyMinutes, false);
		}

		return result;
	}

	/**
	 * Retrieves DocuSign account products.
	 *
	 * @return A DocuSign account products instance.
	 */
	public static AccountProducts getInstance() {
		if (self == null) {
			Credentials c = Credentials.getInstance();
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			self = resolveProducts(
				DB.queryProducts(),
				s.ProductsLastChecked__c,
				Integer.valueOf(s.ProductsCheckFrequency__c),
				DocuSign.parseEnvironment(s.Environment__c),
				c.environment.provisioningBaseUrl,
				c.environment.eSignatureBaseUrl,
				c.account.id,
				c.token.token);
		}
		return self;
	}

	public static AccountProducts initialize(
		final DocuSign.Environment environment,
		final Url provisioningBaseUrl,
		final Url eSignatureBaseUrl,
		final UUID accountId,
		final String accessToken) {

		if (environment == null
			|| provisioningBaseUrl == null
			|| eSignatureBaseUrl == null
			|| UUID.isEmpty(accountId)
			|| String.isBlank(accessToken)) {

			throw new DocuSignException(Label.UndefinedArgument);
		}

		if (environment == DocuSign.Environment.Invalid
			|| !DocuSign.isValidUrl(provisioningBaseUrl)
			|| !DocuSign.isValidUrl(eSignatureBaseUrl)) {

			throw new DocuSignException(Label.InvalidEnvironment);
		}

		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		self = resolveProducts(
			DB.queryProducts(),
			s.ProductsLastChecked__c,
			Integer.valueOf(s.ProductsCheckFrequency__c),
			environment,
			provisioningBaseUrl,
			eSignatureBaseUrl,
			accountId,
			accessToken);
		return self;
	}

	/**
	 * Retrieves the products on the account to be used for Setup and Admin management interfaces on the UI
	 *
	 * @return A List of Products on the account
	 */
	public static List<Product> getProducts() {
		Permissions.verifyIsDocuSignUser();
		return AccountProducts.getInstance().products.values();
	}

	public List<Product> startTrials(final Set<String> productNames) {
		Permissions.verifyIsDocuSignAdministrator();

		if (Collection.isEmpty(productNames)) throw new DocuSignException(Label.UndefinedArgument);

		List<Product> result = new List<Product>();
		ProductAPI client = ProductAPI.getInstance();
		Boolean activated = false;
		for (String pn : productNames) {
			String key = pn == null ? '' : pn.toLowerCase();
			if (!VALID_PRODUCT_TRIALS.contains(key)) {
				throw new DocuSignException(String.format(Label.InvalidTrialProduct_1, new List<String> { pn }));
			}

			// Do not attempt to start a trial if we already have the products
			if (!this.products.containsKey(key)) {
				client.activateProduct(key, true);
				activated = true;
			}
		}

		if (activated) {
			// Refresh products from API. There is logic there to extend trials that we should not replicate here.
			AccountProducts aps = refreshProducts();
			if (Collection.isNotEmpty(aps.products)) this.products.putAll(aps.products);
			this.isDirty = true;
		}

		for (String pn : productNames) {
			Product p = this.products.get(pn.toLowerCase());
			if (p != null) result.add(p);
		}

		return result;
	}

	public Url getScmWebBaseUrl() {
		Url result = null;
		if (this.clm != null && this.clm.webBaseUrl != null) {
			result = this.clm.webBaseUrl;
		} else if (this.negotiate != null && this.negotiate.webBaseUrl != null) {
			result = this.negotiate.webBaseUrl;
		} else if (this.gen != null && this.gen.webBaseUrl != null) {
			result = this.gen.webBaseUrl;
		}
		return result;
	}

	public Url getScmApiBaseUrl() {
		Url result = null;
		if (this.negotiate != null && this.negotiate.apiBaseUrl != null) {
			result = this.negotiate.apiBaseUrl;
		} else if (this.gen != null && this.gen.apiBaseUrl != null) {
			result = this.gen.apiBaseUrl;
		}
		return result;
	}

	public Url getScmMergeBaseUrl() {
		Url result = null;
		if (this.negotiate != null && this.negotiate.mergeBaseUrl != null) {
			result = this.negotiate.mergeBaseUrl;
		} else if (this.gen != null && this.gen.mergeBaseUrl != null) {
			result = this.gen.mergeBaseUrl;
		}
		return result;
	}

	public Url getScmAuthBaseUrl() {
		Url result = null;
		if (this.clm != null && this.clm.authBaseUrl != null) {
			result = this.clm.authBaseUrl;
		}
		return result;
	}

	@TestVisible
	private static Boolean saveRoles(
		final Set<String> oldProducts,
		final Set<String> newProducts) {

		Boolean result = oldProducts != newProducts;
		if (result) {
			Set<String> removed = Collection.difference(oldProducts, newProducts);
			Set<String> added = Collection.difference(newProducts, oldProducts);
			if (Collection.isNotEmpty(added)) {
				// If products were added, delete existing roles to invalidate
				result = Collection.isNotEmpty(DB.deleteProductRoleSettings());
			} else if (Collection.isNotEmpty(removed)) {
				// Else just delete the roles for products that were removed
				result = Collection.isNotEmpty(DB.deleteProductRoleSettings(removed));
			}
		}
		return result;
	}

	@Future(Callout = true)
	private static void createRemoteSites(
		final String environment,
		final Map<String, String> urls) {

		if (Collection.isNotEmpty(urls)) {
			DocuSign.Environment dsEnv = DocuSign.parseEnvironment(environment);
			if (dsEnv == null || dsEnv == DocuSign.Environment.Invalid) throw new DocuSignException(Label.InvalidEnvironment);

			List<MetadataService.RemoteSite> sites = new List<MetadataService.RemoteSite>();
			for (String key : urls.keySet()) {
				Url u = new Url(urls.get(key));
				if (!DocuSign.isValidUrl(u)) throw new DocuSignException(Label.InvalidEnvironment);

				switch on key {
					when 'scmWebBaseUrl' {
						sites.add(MetadataService.newRemoteSite(
							dsEnv,
							MetadataService.REMOTE_SITE_WEB,
							Label.ScmWebServiceDescription,
							new Url('https://' + u.getAuthority())));
					} when 'scmApiBaseUrl' {
						sites.add(MetadataService.newRemoteSite(
							dsEnv,
							MetadataService.REMOTE_SITE_API,
							Label.ScmApiServiceDescription,
							new Url('https://' + u.getAuthority())));
					} when 'scmMergeBaseUrl' {
						sites.add(MetadataService.newRemoteSite(
							dsEnv,
							MetadataService.REMOTE_SITE_MERGE,
							Label.GenServiceDescription,
							new Url('https://' + u.getAuthority())));
					} when 'scmAuthBaseUrl' {
						sites.add(MetadataService.newRemoteSite(
							dsEnv,
							MetadataService.REMOTE_SITE_AUTH,
							Label.ScmAuthServiceDescription,
							new Url('https://' + u.getAuthority())));
					}
				}
			}

			if (Collection.isNotEmpty(sites)) MetadataService.createRemoteSites(sites);
		}
	}

	public static Boolean save() {
		Boolean result = false;

		if (Collection.isNotEmpty(newRoles)) {
			result = DB.insertProductRoles(newRoles);
			newRoles.clear();
		}

		if (self != null && self.isDirty) {
			saveRoles(
				DB.queryProducts().keySet(),
				self.products == null ? new Set<String>() : self.products.keySet());

			Url scmWebBaseUrl = self.getScmWebBaseUrl();
			Url scmApiBaseUrl = self.getScmApiBaseUrl();
			Url scmMergeBaseUrl = self.getScmMergeBaseUrl();
			Url scmAuthBaseUrl = self.getScmAuthBaseUrl();

			DB.replaceProducts(
				self.products == null ? new List<Product>() : self.products.values(),
				scmWebBaseUrl,
				scmApiBaseUrl,
				scmMergeBaseUrl,
				scmAuthBaseUrl,
				self.lastChecked,
				self.checkFrequencyMinutes);

			Map<String, String> urls = new Map<String, String>();
			if (scmWebBaseUrl != null) urls.put('scmWebBaseUrl', scmWebBaseUrl.toExternalForm());
			if (scmApiBaseUrl != null) urls.put('scmApiBaseUrl', scmApiBaseUrl.toExternalForm());
			if (scmMergeBaseUrl != null) urls.put('scmMergeBaseUrl', scmMergeBaseUrl.toExternalForm());
			if (scmAuthBaseUrl != null) urls.put('scmAuthBaseUrl', scmAuthBaseUrl.toExternalForm());

			createRemoteSites(
				String.valueOf(self.environment),
				urls);

			self.isDirty = false;
			result = true;
		}

		Credentials.save();

		return result;
	}

	public static Map<String, Map<UUID, Product.Role>> getRoles(final Set<String> products) {
		if (Collection.isEmpty(products)) throw new DocuSignException(Label.UndefinedArgument);

		Map<String, List<Product.Role>> cachedRoles = DB.queryProductRoles();

		Map<String, Map<UUID, Product.Role>> result = new Map<String, Map<UUID, Product.Role>>();
		Set<String> missingProducts = new Set<String>();
		for (String p : products) {
			if (!Product.isValidProduct(p)) throw new DocuSignException(Label.UnsupportedProducts);

			String pl = p.toLowerCase();
			Map<UUID, Product.Role> idsToRoles = new Map<UUID, Product.Role>();
			if (cachedRoles.containsKey(pl)) {
				for (Product.Role r : cachedRoles.get(pl)) {
					if (r != null) idsToRoles.put(r.id, r);
				}
				result.put(pl, idsToRoles);
			} else {
				missingProducts.add(pl);
			}
		}

		if (Collection.isNotEmpty(missingProducts)) {
			Map<String, Map<UUID, Product.Role>> productRoles = RoleAPI.getInstance().getRoles(missingProducts);
			newRoles = new List<Product.Role>();
			for (String p : productRoles.keySet()) {
				Map<UUID, Product.Role> prs = productRoles.get(p);
				result.put(p, prs);
				newRoles.addAll(prs.values());
			}
		}

		return result;
	}

	public static Boolean clear() {
		Boolean result = Collection.isNotEmpty(DB.deleteProductRoleSettings());
		result |= Collection.isNotEmpty(DB.deleteProductSettings());
		self = null;
		return result;
	}
}
