@IsTest
public class DocuSignAPIMock extends OAuthTokenMock {

	private AuthAPIMock authMock;
	private ESignatureAPIMock eSignatureMock;
	private ProvisioningAPIMock provisioningMock;
	private GenAPIMock genMock;
	private Boolean success;

	public DocuSignAPIMock(final Boolean success) {
		super(!success);
		this.success = success == true;
	}

	public static DocuSignAPIMock success() {
		return (DocuSignAPIMock)TestUtils.setMock(new DocuSignAPIMock(true));
	}

	public static DocuSignAPIMock failure() {
		return (DocuSignAPIMock)TestUtils.setMock(new DocuSignAPIMock(false));
	}

	private AuthAPIMock getAuthAPIMock() {
		if (this.authMock == null) {
			this.authMock = new AuthAPIMock(this.success);
		}
		return this.authMock;
	}

	private ESignatureAPIMock getESignatureMock() {
		if (this.eSignatureMock == null) {
			this.eSignatureMock = new ESignatureAPIMock(this.success);
		}
		return this.eSignatureMock;
	}

	private ProvisioningAPIMock getProvisioningMock() {
		if (this.provisioningMock == null) {
			this.provisioningMock = new ProvisioningAPIMock(this.success);
		}
		return this.provisioningMock;
	}

	private GenAPIMock getGenMock() {
		if (this.genMock == null) {
			this.genMock = new GenAPIMock(this.success);
		}
		return this.genMock;
	}

	override public HttpResponse getResponse(final HttpRequest request) {
		String path = new Url(request.getEndpoint()).getPath();
		if (path.startsWith('/v1/applications')) {
			return getAuthAPIMock().getResponse(request);
		} else if (path.startsWith('/subscription')) {
			return getProvisioningMock().getResponse(request);
		} else if (path.startsWith('/gen')) {
			return getGenMock().getResponse(request);
		}
		return getESignatureMock().getResponse(request);
	}
}
