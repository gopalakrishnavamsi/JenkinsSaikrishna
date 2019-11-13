@IsTest
public class DocuSignAPIMock extends OAuthTokenMock {

	private OAuthMock oauthMock;
	private ApplicationAPIMock applicationMock;
	private ESignatureAPIMock eSignatureMock;
	private ProductAPIMock productMock;
	private ScmAPIMock scmMock;
	private RoleAPIMock roleMock;
	private CLMAPIMock clmMock;
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

	private OAuthMock getOAuthMock() {
		if (this.oauthMock == null) {
			this.oauthMock = new OAuthMock(this.success);
		}
		return this.oauthMock;
	}

	private ApplicationAPIMock getApplicationAPIMock() {
		if (this.applicationMock == null) {
			this.applicationMock = new ApplicationAPIMock(this.success);
		}
		return this.applicationMock;
	}

	private ESignatureAPIMock getESignatureMock() {
		if (this.eSignatureMock == null) {
			this.eSignatureMock = new ESignatureAPIMock(this.success);
		}
		return this.eSignatureMock;
	}

	private ProductAPIMock getProvisioningMock() {
		if (this.productMock == null) {
			this.productMock = new ProductAPIMock(this.success);
		}
		return this.productMock;
	}

	private ScmAPIMock getScmMock() {
		if (this.scmMock == null) {
			this.scmMock = new ScmAPIMock(this.success);
		}
		return this.scmMock;
	}

	private RoleAPIMock getRoleMock() {
		if (this.roleMock == null) {
			this.roleMock = new RoleAPIMock(this.success);
		}
		return this.roleMock;
	}

	private CLMAPIMock getClmMock() {
		if (this.clmMock == null) {
			this.clmMock = new CLMAPIMock(this.success);
		}
		return this.clmMock;
	}

	override public HttpResponse getResponse(final HttpRequest request) {
		String path = new Url(request.getEndpoint()).getPath();
		if (path.startsWith('/oauth')) {
			return this.getOAuthMock().getResponse(request);
		} else if (path.startsWith('/v2/applications')) {
			return this.getApplicationAPIMock().getResponse(request);
		} else if (path.startsWith('/subscription')) {
			return this.getProvisioningMock().getResponse(request);
		} else if (path.startsWith('/management')) {
			return this.getRoleMock().getResponse(request);
		} else if (path.startsWith('/gen') || path.startsWith('/v2')) {
			return this.getScmMock().getResponse(request);
		} else if (path.startsWith('/api/v1/')) {
			return this.getClmMock().getResponse(request);
		}
		return this.getESignatureMock().getResponse(request);
	}
}