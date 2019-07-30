/**
 * Available DocuSign account features.
 */
public with sharing class AccountProducts {

	private static AccountProducts self = null;
	private static final Integer DEFAULT_CHECK_FREQUENCY_MIN = 60; // 1 hour

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

	private final Map<String, Product> products;

	@AuraEnabled
	public ESignatureProduct eSignature {
		get {
			return (ESignatureProduct)this.products.get(Product.NAME_ESIGNATURE);
		}
	}

	@AuraEnabled
	public GenProduct gen {
		get {
			return (GenProduct)this.products.get(Product.NAME_GEN);
		}
	}

	@AuraEnabled
	public NegotiateProduct negotiate {
		get {
			return (NegotiateProduct)this.products.get(Product.NAME_NEGOTIATE);
		}
	}

	@AuraEnabled
	public ClmProduct clm {
		get {
			return (ClmProduct)this.products.get(Product.NAME_CLM);
		}
	}

	@TestVisible
	private AccountProducts(final Map<String, Product> products) {
		this.products = products == null ? new Map<String, Product>() : products;
	}

	public Boolean isESignatureTrialExpired() {
		Product p = this.products.get(Product.NAME_ESIGNATURE);
		return p != null && p.isExpired;
	}

	public Boolean isESignatureEnabled() {
		Product p = this.products.get(Product.NAME_ESIGNATURE);
		return p != null && !p.isExpired;
	}

	public Boolean isGenEnabled() {
		Product p = this.products.get(Product.NAME_GEN);
		return p != null && !p.isExpired;
	}

	public Boolean isNegotiateEnabled() {
		Product p = this.products.get(Product.NAME_NEGOTIATE);
		return p != null && !p.isExpired;
	}

	public Boolean isClmEnabled() {
		Product p = this.products.get(Product.NAME_CLM);
		return p != null && !p.isExpired;
	}

	@TestVisible
	private static Map<String, Product> resolveProducts(
		final Map<String, Product> configuredProducts,
		final Datetime lastChecked,
		final Integer checkFrequencyMinutes) {

		Map<String, Product> resolvedProducts = null;
		if (configuredProducts == null
			|| lastChecked == null
			|| checkFrequencyMinutes == null
			|| lastChecked.addMinutes(checkFrequencyMinutes) <= Datetime.now()) {

			resolvedProducts = new Map<String, Product>();
			resolvedProducts.put(
				Product.NAME_ESIGNATURE,
				AccountAPI.getInstance().getProduct());
			for (Product p : ProvisioningAPI.getInstance().getProducts()) {
				if (p != null) resolvedProducts.put(p.name, p);
			}
			updateProducts(
				serializeProducts(resolvedProducts),
				checkFrequencyMinutes);
		} else {
			resolvedProducts = configuredProducts;
		}

		return resolvedProducts;
	}

	@TestVisible
	private static Integer packFeatures(final Set<ESignatureProduct.Feature> features) {
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
	private static Set<ESignatureProduct.Feature> unpackFeatures(final Integer features) {
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

	private static Map<String, String> serializeProducts(final Map<String, Product> products) {
		Map<String, String> result = new Map<String, String>();
		if (products != null) {
			for (String key : products.keySet()) {
				result.put(key, JSON.serialize(products.get(key)));
			}
		}
		return result;
	}

	private static List<Product> deserializeProducts(final Map<String, String> products) {
		List<Product> result = new List<Product>();
		if (products != null) {
			for (String key : products.keySet()) {
				switch on key {
					when 'e_sign' {
						result.add((Product)JSON.deserialize(products.get(key), ESignatureProduct.class));
					} when 'gen' {
						result.add((Product)JSON.deserialize(products.get(key), GenProduct.class));
					} when 'negotiate' {
						result.add((Product)JSON.deserialize(products.get(key), NegotiateProduct.class));
					} when 'clm' {
						result.add((Product)JSON.deserialize(products.get(key), ClmProduct.class));
					}
				}
			}
		}
		return result;
	}

	@Future
	private static void updateProducts(
		final Map<String, String> resolvedProducts,
		final Integer checkFrequencyMinutes) {

		if (resolvedProducts != null) {
			List<Product> ps = deserializeProducts(resolvedProducts);
			delete ProductSettings__c.getAll().values();
			List<ProductSettings__c> productSettings = new List<ProductSettings__c>();
			for (Product p : ps) {
				if (p != null) productSettings.add(convertProduct(p));
			}
			insert productSettings;

			AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
			accountSettings.ProductsLastChecked__c = Datetime.now();
			accountSettings.ProductsCheckFrequency__c = checkFrequencyMinutes == null
				? DEFAULT_CHECK_FREQUENCY_MIN : checkFrequencyMinutes;
			upsert accountSettings;
		}
	}

	private static ProductSettings__c convertProduct(final Product product) {
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

	private static Product convertProduct(final ProductSettings__c product) {
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
					null);
			} when 'negotiate' {
				result = new NegotiateProduct(
					product.Status__c,
					product.IsTrial__c == true,
					product.TrialExpires__c,
					null);
			} when 'clm' {
				result = new ClmProduct(
					product.Status__c,
					product.IsTrial__c == true,
					product.TrialExpires__c,
					null);
			}
		}
		return result;
	}

	private static Map<String, Product> loadProducts() {
		Map<String, Product> result = new Map<String, Product>();
		Map<String, ProductSettings__c> pss = ProductSettings__c.getAll();
		if (pss != null) {
			for (String key : pss.keySet()) {
				ProductSettings__c ps = pss.get(key);
				if (String.isNotBlank(key) && ps != null) result.put(key, convertProduct(ps));
			}
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
			Map<String, Product> products = null;
			try {
				AccountSettings__c s = AccountSettings__c.getOrgDefaults();
				products = resolveProducts(
					loadProducts(),
					s.ProductsLastChecked__c,
					Integer.valueOf(s.ProductsCheckFrequency__c));
			} catch (Exception ex) {
				LoggerService.getInstance().exception(ex, 'Failed to get account products');
			}
			self = new AccountProducts(products);
		}
		return self;
	}
}
