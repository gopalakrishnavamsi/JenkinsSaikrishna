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
					new ProvisioningAPI.APIProductProperty('invite_callback_uri', 'https://integration.test.springcm.com/provisioning/v1/callbacks/UserInvited'),
					new ProvisioningAPI.APIProductProperty('invite_redirect_uri', 'https://test.docusign.com'),
					new ProvisioningAPI.APIProductProperty('merge_uri', 'https://api.test.springcm.com/gen'),
					new ProvisioningAPI.APIProductProperty('web_base_uri', 'https://test.springcm.com/atlas/'),
					new ProvisioningAPI.APIProductProperty('invite_email_subject', 'Unit Test'),
					new ProvisioningAPI.APIProductProperty('invite_email_body', '<html/>')
				};

				response.setBody(JSON.serialize(p));
			} else if (String.isNotBlank(accountId)) { // GET account products
				ProvisioningAPI.APIProducts ps = new ProvisioningAPI.APIProducts();
				ps.id = accountId;
				ps.name = 'Unit Test';
				ps.products = new List<ProvisioningAPI.APIProduct>();
				ProvisioningAPI.APIProduct p = new ProvisioningAPI.APIProduct();
				p.product_id = 'gen';
				p.free_trial = true;
				p.provision_status = 'active';
				p.expiration_date = StringUtils.formatDatetime(Datetime.now().addDays(7));
				p.activation_properties = new List<ProvisioningAPI.APIProductProperty> {
					new ProvisioningAPI.APIProductProperty('api_base_uri', 'https://api.test.springcm.com'),
					new ProvisioningAPI.APIProductProperty('invite_callback_uri', 'https://integration.test.springcm.com/provisioning/v1/callbacks/UserInvited'),
					new ProvisioningAPI.APIProductProperty('invite_redirect_uri', 'https://invite.redirect.docusign.com/'),
					new ProvisioningAPI.APIProductProperty('merge_uri', 'https://api.test.springcm.com/gen'),
					new ProvisioningAPI.APIProductProperty('web_base_uri', 'https://test.springcm.com/atlas/'),
					new ProvisioningAPI.APIProductProperty('invite_email_subject', 'Unit Test'),
					new ProvisioningAPI.APIProductProperty('invite_email_body', '<html/>')
				};
				ps.products.add(p);
				response.setBody(JSON.serialize(ps));
			} else { // GET all account products
				// TODO: Mock resp
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
