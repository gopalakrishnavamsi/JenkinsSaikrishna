public with sharing class ProvisioningAPI extends DocuSignAPI {

	private static ProvisioningAPI self;
	private final UUID accountId;
	private final String accessToken;

	private ProvisioningAPI(
		final Url baseUrl,
		final UUID accountId,
		final String accessToken) {

		super(new Url(baseUrl, '/subscription/v1/provision/accounts/'));

		this.accountId = accountId;
		this.accessToken = accessToken;
	}

	public static ProvisioningAPI getInstance() {
		if (self == null) {
			Credentials c = Credentials.getInstance();
			self = new ProvisioningAPI(c.environment.provisioningBaseUrl, c.account.id, null);
		}
		return self;
	}

	public static ProvisioningAPI getInstance(
		final Url baseUrl,
		final UUID accountId,
		final String accessToken) {

		if (baseUrl == null || UUID.isEmpty(accountId) || String.isBlank(accessToken)) {
			throw new DocuSignException(Label.UndefinedArgument);
		}

		if (!DocuSign.isValidUrl(baseUrl)) throw new DocuSignException(Label.InvalidEnvironment);

		return new ProvisioningAPI(baseUrl, accountId, accessToken);
	}

	public class Error extends APIError {
		public UUID referenceId { get; private set; }

		public Error(
			final Integer code,
			final UUID referenceId,
			final String description) {

			super(code, description);

			this.referenceId = referenceId;
		}

		override public String toString() {
			return String.format(Label.ApiError_3, new List<String> {
				String.valueOf(this.code),
				this.description,
				String.valueOf(this.referenceId)
			});
		}
	}

	@TestVisible
	override protected virtual APIError getError(final HttpResponse response) {
		APIError e = APIError.none;
		Integer statusCode = response.getStatusCode();
		if (statusCode >= 400) {
			String body = response.getBody();
			try {
				Map<String, Object> error = (Map<String, Object>)JSON.deserializeUntyped(body);
				e = new ProvisioningAPI.Error(
					statusCode,
					UUID.tryParse((String)error.get('reference_id')),
					(String)error.get('error_description')); // OR error_description?
				this.log.warn('Provisioning API error: ' + e);
			} catch (Exception ex) {
				this.log.exception(ex, 'Failed to parse provisioning API error. Response body:\n' + body);
				e = new APIError(statusCode, response.getStatus());
			}
		}
		return e;
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
			return new Product(
				this.product_id,
				this.provision_status,
				this.free_trial == true,
				StringUtils.parseDatetime(this.expiration_date),
				properties);
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
				if (result != null) result.add(p.toExternalForm());
			}
			return result;
		}
	}

	public List<Product> getProducts() {
		return this.getProducts(RestAPI.defaultTimeout);
	}

	public List<Product> getProducts(final Integer timeout) {
		RestAPI.Response response = this.get(
			this.getBaseUrl(),
			new List<Object> { this.accountId },
			QueryString.empty,
			new Map<String, String> {
				'Accept' => 'application/json',
				'Authorization' => 'Bearer '
					+ (String.isBlank(this.accessToken) ? AuthService.getAccessToken() : this.accessToken)
			},
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get provisioned products: ' + response.error);
			throw new APIException(response.error);
		}
		return ((APIProducts)JSON.deserialize(response.body, APIProducts.class)).toExternalForm();
	}

	public Product addProduct(
		final String product,
		final Boolean isTrial) {

		return this.addProduct(product, isTrial, RestAPI.defaultTimeout);
	}

	public Product addProduct(
		final String product,
		final Boolean isTrial,
		final Integer timeout) {

		System.debug('the value of Product :  ' + product);
		System.debug('the value of isTrial :  ' + isTrial);
		System.debug('the value of timeout :  ' + timeout);
		System.debug('the value of request  :  ' + timeout);
		if (String.isBlank(product)) throw new DocuSignException(Label.UndefinedArgument);

		RestAPI.Response response = this.post(
			this.getBaseUrl(),
			new List<Object> { this.accountId, 'activate' },
			QueryString.empty,
			new Map<String, String> {
				'Content-Type' => 'application/json',
				'Accept' => 'application/json',
				'Authorization' => 'Bearer '
					+ (String.isBlank(this.accessToken) ? AuthService.getAccessToken() : this.accessToken)
			},
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
