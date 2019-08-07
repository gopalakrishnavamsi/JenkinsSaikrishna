@IsTest
public class GroupAPIMock extends OAuthTokenMock {

	private final Boolean success;

	public GroupAPIMock(final Boolean success) {
		this.success = success;
	}

	/* Supported routes:
		- GET /management/v1/accounts/{{account-id}}/dsgroups
	 */
	override public HttpResponse getResponse(final HttpRequest request) {
		throw new AssertException('Not yet implemented');
	}
}
