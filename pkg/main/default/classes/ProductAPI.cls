public with sharing class ProductAPI extends ProvisioningAPI {

	@TestVisible
	private static final String PRODUCT_GEN = 'Gen';
	@TestVisible
	private static final String PRODUCT_NEGOTIATE = 'Negotiate';
	@TestVisible
	private static final String PRODUCT_CLM = 'CLM';

	private static ProductAPI self;

	private ProductAPI(
		final Url baseUrl,
		final UUID accountId,
		final String accessToken) {

		super(
			baseUrl,
			String.format('/subscription/v1/provision/accounts/{0}/', new List<Object> { accountId }),
			accessToken);
	}

	public static ProductAPI getInstance() {
		if (self == null) {
			Credentials c = Credentials.getInstance();
			self = new ProductAPI(c.environment.provisioningBaseUrl, c.account.id, null);
		}
		return self;
	}

	public static ProductAPI getInstance(
		final Url baseUrl,
		final UUID accountId,
		final String accessToken) {

		if (baseUrl == null || UUID.isEmpty(accountId)) {
			throw new DocuSignException(Label.UndefinedArgument);
		}

		if (!DocuSign.isValidUrl(baseUrl)) throw new DocuSignException(Label.InvalidEnvironment);

		return new ProductAPI(baseUrl, accountId, accessToken);
	}

	@TestVisible
	private class APIProductProperty {
		public String name;
		public String value;

		@TestVisible
		private APIProductProperty(
			final String name,
			final String value) {

			this.name = name;
			this.value = value;
		}
	}

	@TestVisible
	private class APIProduct {
		public String product_id;
		public String provision_status;
		public String expiration_date;
		public Boolean free_trial;
		public List<APIProductProperty> activation_properties;

		public Product toExternalForm() {
			Map<String, String> properties = new Map<String, String>();
			if (this.activation_properties != null) {
				for (APIProductProperty pp : this.activation_properties) {
					if (pp != null) properties.put(pp.name, pp.value);
				}
			}

			Product p = null;
			if (this.product_id == PRODUCT_GEN) {
				p = new GenProduct(
					this.provision_status,
					this.free_trial == true,
					StringUtils.parseDate(this.expiration_date),
					properties.containsKey('web_base_uri')
						? UrlUtils.canonicalizeBaseUrl(new Url(properties.get('web_base_uri'))) : null,
					properties.containsKey('merge_uri')
						? UrlUtils.canonicalizeBaseUrl(new Url(properties.get('merge_uri'))) : null);
			} else if (this.product_id == PRODUCT_NEGOTIATE) {
				p = new NegotiateProduct(
					this.provision_status,
					this.free_trial == true,
					StringUtils.parseDate(this.expiration_date),
					properties.containsKey('web_base_uri')
						? UrlUtils.canonicalizeBaseUrl(new Url(properties.get('web_base_uri'))) : null,
					properties.containsKey('merge_uri')
						? UrlUtils.canonicalizeBaseUrl(new Url(properties.get('merge_uri'))) : null);
			} else if (this.product_id == PRODUCT_CLM) {
				p = new ClmProduct(
					this.provision_status,
					this.free_trial == true,
					StringUtils.parseDate(this.expiration_date),
					properties.containsKey('web_base_uri')
						? UrlUtils.canonicalizeBaseUrl(new Url(properties.get('web_base_uri'))) : null,
					properties.containsKey('landing_page_uri')
						? UrlUtils.canonicalizeBaseUrl(new Url(properties.get('landing_page_uri'))) : null,
					properties.containsKey('admin_uri')
						? UrlUtils.canonicalizeBaseUrl(new Url(properties.get('admin_uri'))) : null);
			}
			return p;
		}
	}

	@TestVisible
	private class APIProducts {
		public String id;
		public String name;
		public List<APIProduct> products;

		public List<Product> toExternalForm() {
			List<Product> result = new List<Product>();
			for (APIProduct p : (this.products == null ? new List<APIProduct>() : this.products)) {
				if (result != null) {
					Product pp = p.toExternalForm();
					if (pp != null) result.add(pp);
				}
			}
			return result;
		}
	}

	public List<Product> getProducts() {
		return this.getProducts(RestAPI.defaultTimeout);
	}

	public List<Product> getProducts(final Integer timeout) {
		RestAPI.Response response = this.get(
			null,
			QueryString.empty,
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get provisioned products: ' + response.error);
			throw new APIException(response.error);
		}
		return ((APIProducts)JSON.deserialize(response.body, APIProducts.class)).toExternalForm();
	}

	public Product activateProduct(
		final String product,
		final Boolean isTrial) {

		return this.activateProduct(product, isTrial, RestAPI.defaultTimeout);
	}

	public Product activateProduct(
		final String product,
		final Boolean isTrial,
		final Integer timeout) {

		if (String.isBlank(product)) throw new DocuSignException(Label.UndefinedArgument);

		RestAPI.Response response = this.post(
			new List<Object> { 'activate' },
			QueryString.empty,
			JSON.serialize(new Map<String, Object> {
				'product' => product,
				'free_trial' => isTrial == true
			}),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to provision product: ' + response.error);
			throw new APIException(response.error);
		}

		return ((APIProduct)JSON.deserialize(response.body, APIProduct.class)).toExternalForm();
	}
}
