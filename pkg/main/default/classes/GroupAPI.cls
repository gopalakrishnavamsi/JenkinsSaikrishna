public with sharing class GroupAPI extends DocuSignAPI {

	private static GroupAPI self;

	private GroupAPI(
		final Url baseUrl,
		final UUID accountId) {

		super(new Url(baseUrl, String.format('/management/v1/accounts/{0}/', new List<Object> { accountId })));
	}

	public static GroupAPI getInstance() {
		if (self == null) {
			Credentials c = Credentials.getInstance();
			self = new GroupAPI(c.environment.provisioningBaseUrl, c.account.id);
		}
		return self;
	}
}
