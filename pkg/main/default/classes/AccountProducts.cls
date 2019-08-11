/**
 * Available DocuSign account features.
 */
public with sharing class AccountProducts {

	@TestVisible
	private static final AccountProducts.Database DB = new AccountProducts.Database();
	@TestVisible
	private static AccountProducts self = null;
	private static final Integer DEFAULT_CHECK_FREQUENCY_MIN = 60; // 1 hour
	private static final Set<String> validProductTrials = new Set<String> { Product.GEN, Product.NEGOTIATE };

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
		final Map<String, Product> products,
		final Datetime lastChecked,
		final Integer checkFrequencyMinutes,
		final Boolean isDirty) {

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
						account == null || account.ScmAuthBaseUrl__c == null ? null : new Url(account.ScmAuthBaseUrl__c),
						account == null || account.ScmApiBaseUrl__c == null ? null : new Url(account.ScmApiBaseUrl__c));
				} when 'negotiate' {
					result = new NegotiateProduct(
						product.Status__c,
						product.IsTrial__c == true,
						product.TrialExpires__c,
						account == null || account.ScmAuthBaseUrl__c == null ? null : new Url(account.ScmAuthBaseUrl__c),
						account == null || account.ScmApiBaseUrl__c == null ? null : new Url(account.ScmApiBaseUrl__c));
				} when 'clm' {
					result = new ClmProduct(
						product.Status__c,
						product.IsTrial__c == true,
						product.TrialExpires__c,
						account == null || account.ScmAuthBaseUrl__c == null ? null : new Url(account.ScmAuthBaseUrl__c),
						account == null || account.ClmLandingPageUrl__c == null ? null : new Url(account.ClmLandingPageUrl__c),
						account == null || account.ClmAdminUrl__c == null ? null : new Url(account.ClmAdminUrl__c));
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

		private AccountSettings__c upsertAccountSettings(
			final Datetime lastChecked,
			final Integer checkFrequencyMinutes) {

			AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
			accountSettings.ProductsLastChecked__c = lastChecked == null ? Datetime.now() : lastChecked;
			accountSettings.ProductsCheckFrequency__c = checkFrequencyMinutes == null || checkFrequencyMinutes <= 0
				? DEFAULT_CHECK_FREQUENCY_MIN : checkFrequencyMinutes;
			upsert accountSettings;
			return accountSettings;
		}

		public List<Product> replaceProducts(
			final List<Product> products,
			final Datetime lastChecked,
			final Integer checkFrequencyMinutes) {

			if (products != null) {
				replaceProductSettings(products);
				upsertAccountSettings(lastChecked, checkFrequencyMinutes);
			}
			return products;
		}

		private List<Product> upsertProducts(final List<Product> products) {
			if (products == null) return null;

			Map<String, ProductSettings__c> settings = ProductSettings__c.getAll();
			List<ProductSettings__c> toUpsert = new List<ProductSettings__c>();
			for (Product p : products) {
				ProductSettings__c ps = convert(p);
				if (settings.containsKey(p.name)) {
					ps.Id = settings.get(p.name).Id;
				}
				toUpsert.add(ps);
			}
			upsert toUpsert;
			return products;
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
	private static AccountProducts resolveProducts(
		final Map<String, Product> configuredProducts,
		final Datetime lastChecked,
		final Integer checkFrequencyMinutes,
		final Url provisioningBaseUrl,
		final Url eSignatureBaseUrl,
		final UUID accountId,
		final String accessToken) {

		AccountProducts result = null;
		if (configuredProducts == null
			|| lastChecked == null
			|| checkFrequencyMinutes == null
			|| lastChecked.addMinutes(checkFrequencyMinutes) <= Datetime.now()) {

			Map<String, Product> products = new Map<String, Product>();
			products.put(
				Product.ESIGNATURE,
				ESignatureProductAPI.getInstance(eSignatureBaseUrl, accountId, accessToken).getProduct());
			ProvisioningAPI client = ProvisioningAPI.getInstance(provisioningBaseUrl, accountId, accessToken);
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
			result = new AccountProducts(products, Datetime.now(), checkFrequencyMinutes, true);
		} else {
			result = new AccountProducts(configuredProducts, lastChecked, checkFrequencyMinutes, false);
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
				c.environment.provisioningBaseUrl,
				c.environment.eSignatureBaseUrl,
				c.account.id,
				c.token.token);
		}
		return self;
	}

	public static AccountProducts getInstance(
		final Url provisioningBaseUrl,
		final Url eSignatureBaseUrl,
		final UUID accountId,
		final String accessToken) {

		if (provisioningBaseUrl == null
			|| eSignatureBaseUrl == null
			|| UUID.isEmpty(accountId)
			|| String.isBlank(accessToken)) {

			throw new DocuSignException(Label.UndefinedArgument);
		}

		if (!DocuSign.isValidUrl(provisioningBaseUrl)
			|| !DocuSign.isValidUrl(eSignatureBaseUrl)) {

			throw new DocuSignException(Label.InvalidEnvironment);
		}

		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		self = resolveProducts(
			DB.queryProducts(),
			s.ProductsLastChecked__c,
			Integer.valueOf(s.ProductsCheckFrequency__c),
			provisioningBaseUrl,
			eSignatureBaseUrl,
			accountId,
			accessToken);
		return self;
	}

	public List<Product> startTrials(final Set<String> productNames) {
		Permissions.verifyIsDocuSignAdministrator();

		if (Collection.isEmpty(productNames)) throw new DocuSignException(Label.UndefinedArgument);

		List<Product> result = new List<Product>();
		ProvisioningAPI client = ProvisioningAPI.getInstance();
		for (String pn : productNames) {
			if (pn == null || !validProductTrials.contains(pn.toLowerCase())) {
				throw new DocuSignException(String.format(Label.InvalidTrialProduct_1, new List<String> { pn }));
			}

			Product p = client.activateProduct(pn.toLowerCase(), true);
			this.products.put(p.name.toLowerCase(), p);
			result.add(p);
		}

		return DB.upsertProducts(result);
	}

	public Url getScmAuthBaseUrl() {
		Url result = null;
		if (this.clm != null && this.clm.authBaseUrl != null) {
			result = this.clm.authBaseUrl;
		} else if (this.negotiate != null && this.negotiate.authBaseUrl != null) {
			result = this.negotiate.authBaseUrl;
		} else if (this.gen != null && this.gen.authBaseUrl != null) {
			result = this.gen.authBaseUrl;
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

	public Url getClmAdminUrl() {
		return this.clm == null ? null : this.clm.adminUrl;
	}

	public Url getClmLandingPageUrl() {
		return this.clm == null ? null : this.clm.landingPageUrl;
	}

	public static Boolean save() {
		Boolean result = self != null && self.isDirty;
		if (result) {
			DB.replaceProducts(
				self.products == null ? new List<Product>() : self.products.values(),
				self.lastChecked,
				self.checkFrequencyMinutes);
			self.isDirty = false;
		}
		return result;
	}
}
