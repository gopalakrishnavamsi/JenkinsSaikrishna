@IsTest
public class ProvisioningAPIMock extends OAuthTokenMock {

	private static final Pattern PATH_PATTERN = Pattern.compile(
		'\\/subscription\\/([^\\/]+)\\/provision\\/accounts(\\/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|\\d+)(\\/?(.+))?)?');

	public final Boolean success;

	public ProvisioningAPIMock(final Boolean success) {
		super(!success);
		this.success = success == true;
	}

	public static ProvisioningAPIMock success() {
		return (ProvisioningAPIMock)TestUtils.setMock(new ProvisioningAPIMock(true));
	}

	public static ProvisioningAPIMock failure() {
		return (ProvisioningAPIMock)TestUtils.setMock(new ProvisioningAPIMock(false));
	}

	override public HttpResponse getResponse(final HttpRequest request) {
		HttpResponse response = new HttpResponse();
		if (this.success) {
			String method = request.getMethod();
			Url u = new Url(request.getEndpoint());
			Matcher m = PATH_PATTERN.matcher(u.getPath());
			if (!m.matches()) throw new AssertException('API request endpoint was not in expected format: ' + u.getPath());

			String accountId = m.group(2);

			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json');
			response.setHeader('X-DocuSign-TraceToken', UUID.randomUUID().toString());

			if (method == 'POST') { // provision product
				Map<String, Object> reqBody = (Map<String, Object>)JSON.deserializeUntyped(request.getBody());
				ProvisioningAPI.APIProduct p = new ProvisioningAPI.APIProduct();
				p.product_id = (String)reqBody.get('product');
				p.free_trial = (Boolean)reqBody.get('free_trial');
				p.provision_status = 'active';
				p.expiration_date = p.free_trial ? StringUtils.formatDatetime(Datetime.now().addDays(7)) : null;
				p.activation_properties = new List<ProvisioningAPI.APIProductProperty> {
					new ProvisioningAPI.APIProductProperty('api_base_uri', 'https://api.test.springcm.com'),
					new ProvisioningAPI.APIProductProperty('merge_uri', 'https://api.test.springcm.com/gen'),
					new ProvisioningAPI.APIProductProperty('web_base_uri', 'https://test.springcm.com/atlas/')
				};

				response.setBody(JSON.serialize(p));
			} else if (String.isNotBlank(accountId)) { // GET account products
				ProvisioningAPI.APIProducts ps = new ProvisioningAPI.APIProducts();
				ps.id = accountId;
				ps.name = 'Unit Test';
				ProvisioningAPI.APIProduct eSign = new ProvisioningAPI.APIProduct();
				eSign.product_id = Product.ESIGNATURE;
				eSign.free_trial = false;
				eSign.provision_status = 'active';
				ProvisioningAPI.APIProduct gen = new ProvisioningAPI.APIProduct();
				gen.product_id = Product.GEN;
				gen.free_trial = true;
				gen.provision_status = 'active';
				gen.expiration_date = StringUtils.formatDatetime(Datetime.now().addDays(7));
				gen.activation_properties = new List<ProvisioningAPI.APIProductProperty> {
					new ProvisioningAPI.APIProductProperty('api_base_uri', 'https://api.test.springcm.com'),
					new ProvisioningAPI.APIProductProperty('merge_uri', 'https://api.test.springcm.com/gen'),
					new ProvisioningAPI.APIProductProperty('web_base_uri', 'https://test.springcm.com/atlas/')
				};
				ProvisioningAPI.APIProduct negotiate = new ProvisioningAPI.APIProduct();
				negotiate.product_id = Product.NEGOTIATE;
				negotiate.free_trial = true;
				negotiate.provision_status = 'active';
				negotiate.expiration_date = StringUtils.formatDatetime(Datetime.now().addDays(7));
				negotiate.activation_properties = new List<ProvisioningAPI.APIProductProperty> {
					new ProvisioningAPI.APIProductProperty('api_base_uri', 'https://api.test.springcm.com'),
					new ProvisioningAPI.APIProductProperty('merge_uri', 'https://api.test.springcm.com/gen'),
					new ProvisioningAPI.APIProductProperty('web_base_uri', 'https://test.springcm.com/atlas/')
				};
				ProvisioningAPI.APIProduct clm = new ProvisioningAPI.APIProduct();
				clm.product_id = Product.CLM;
				clm.free_trial = false;
				clm.provision_status = 'active';
				clm.expiration_date = null;
				clm.activation_properties = new List<ProvisioningAPI.APIProductProperty> {
					new ProvisioningAPI.APIProductProperty('admin_uri', 'https://test.springcm.com/atlas/Admin/AccountSettings'),
					new ProvisioningAPI.APIProductProperty('landing_page_uri', 'https://test.springcm.com/atlas/LandingPage'),
					new ProvisioningAPI.APIProductProperty('web_base_uri', 'https://test.springcm.com/atlas/')
				};
				ps.products = new List<ProvisioningAPI.APIProduct> {
					eSign, gen, negotiate, clm
				};
				response.setBody(JSON.serialize(ps));
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
