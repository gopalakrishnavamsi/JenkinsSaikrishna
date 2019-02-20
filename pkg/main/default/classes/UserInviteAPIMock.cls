@IsTest
public class UserInviteAPIMock extends OAuthTokenMock {

	private final Boolean success;
	private static final Pattern PATH_PATTERN = Pattern.compile(
		'\\/v2\\/account\\/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})'
			+ '\\/invite(\\/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}))?(\\/(\\w+))?');

	public UserInviteAPIMock(final Boolean success) {
		super(!success);

		this.success = success;
	}

	public static UserInviteAPIMock success() {
		return (UserInviteAPIMock)TestUtils.setMock(new UserInviteAPIMock(true));
	}

	public static UserInviteAPIMock failure() {
		return (UserInviteAPIMock)TestUtils.setMock(new UserInviteAPIMock(false));
	}

	/* Supported routes:
		- POST /v2/account/{accountId}/invite - invite user
		- POST /v2/account/{accountId}/invite/{inviteId}/resend - resend user invite
		- DELETE /v2/account/{accountId}/invite/{inviteId} - revoke user invite
	 */
	override public HttpResponse getResponse(final HttpRequest request) {
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json; charset=utf-8');
		if (this.success) {
			response.setStatusCode(200);
			response.setStatus('OK');

			String method = request.getMethod();
			String path = new Url(request.getEndpoint()).getPath();
			Matcher m = PATH_PATTERN.matcher(path);
			if (!m.matches()) {
				throw new AssertException('User invite API request endpoint was not in expected format: ' + path);
			}

			String inviteId = m.group(3);
			Map<String, Object> respBody = new Map<String, Object> {
				'user_invite_id' => String.isBlank(inviteId) ? UUID.randomUUID().toString() : inviteId,
				'account_id' => m.group(1),
				'status' => 'pending',
				'events' => new Map<String, Object> {
					'created_on' => 1546329600 // 2019-01-01T00:00:00.000Z
				}
			};
			String op = m.group(5);
			if ((method == 'POST' && (String.isBlank(op) || op == 'resend')) || method == 'DELETE') {
				response.setBody(JSON.serialize(respBody));
			} else {
				throw new AssertException('Unexpected user invite API request: ' + method + ' ' + path);
			}
		} else {
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setBody('{"error":"unit_test","error_description":"test error","reference_id":"'
				+ UUID.randomUUID() + '"}');
		}
		return response;
	}
}
