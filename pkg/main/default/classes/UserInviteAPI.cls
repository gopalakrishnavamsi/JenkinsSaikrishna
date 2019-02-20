public with sharing class UserInviteAPI extends DocuSignAPI {

	private static UserInviteAPI self;

	private final UUID accountId;
	private final Url inviteRedirectUri;
	private final Url inviteCallbackUri;
	private final String inviteEmailSubject;
	private final String inviteEmailBody;
	private final Long administratorProfileId;
	private final Long senderProfileId;

	@TestVisible
	private UserInviteAPI(
		final Url accountBaseUrl,
		final UUID accountId,
		final Url inviteRedirectUri,
		final Url inviteCallbackUri,
		final String inviteEmailSubject,
		final String inviteEmailBody,
		final Long administratorProfileId,
		final Long senderProfileId) {

		super(new Url(accountBaseUrl, '/v2/account/' + accountId + '/'));

		this.accountId = accountId;
		this.inviteRedirectUri = inviteRedirectUri;
		this.inviteCallbackUri = inviteCallbackUri;
		this.inviteEmailSubject = inviteEmailSubject;
		this.inviteEmailBody = inviteEmailBody;
		this.administratorProfileId = administratorProfileId;
		this.senderProfileId = senderProfileId;
	}

	public static UserInviteAPI getInstance() {
		if (self == null) {
			Permissions.verifyIsQueryable(Configuration__c.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'InviteEmailSubject__c',
				Application.namespacePrefix + 'InviteEmailBody__c'
			});

			Configuration__c cfg = (Configuration__c)Collection.head([
				SELECT InviteEmailSubject__c, InviteEmailBody__c
				FROM Configuration__c
				WHERE Name = 'Gen' // TODO: determine if invite can be used for esign as well.
				LIMIT 1
			]);
			Credentials c = Credentials.getInstance();
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			self = new UserInviteAPI(
				c.environment.accountBaseUrl,
				c.account.id,
				String.isBlank(s.InviteRedirectUrl__c) ? null : new Url(s.InviteRedirectUrl__c),
				String.isBlank(s.InviteCallbackUrl__c) ? null : new Url(s.InviteCallbackUrl__c),
				cfg == null ? null : cfg.InviteEmailSubject__c,
				cfg == null ? null : cfg.InviteEmailBody__c,
				(Long)s.AdministratorProfileId__c,
				(Long)s.SenderProfileId__c);
		}
		return self;
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
	private static Integer getErrorCode(final String dsError, final Integer statusCode) {
		switch on (dsError == null ? '' : dsError.toLowerCase()) {
			when 'userinvite_already_exists' {
				return APIErrorCode.USER_INVITE_ALREADY_EXISTS;
			} when 'userinvite_not_found' {
				return APIErrorCode.USER_INVITE_NOT_FOUND;
			} when 'userinvite_invalid_status' {
				return APIErrorCode.USER_INVITE_INVALID_STATUS;
			} when else {
				return statusCode;
			}
		}
	}

	@TestVisible
	override protected APIError getError(final HttpResponse response) {
		APIError result = APIError.none;
		Integer statusCode = response.getStatusCode();
		if (statusCode >= 400) {
			String body = response.getBody();
			try {
				Map<String, Object> error = (Map<String, Object>)JSON.deserializeUntyped(body);
				result = new Error(
					getErrorCode((String)error.get('error'), statusCode),
					UUID.tryParse((String)error.get('reference_id')),
					error.containsKey('error_description')
						? (String)error.get('error_description') : response.getStatus());
				this.log.warn('User API error: ' + result);
			} catch (Exception ex) {
				this.log.exception(ex, 'Failed to parse User API error. Response body:\n' + body);
				result = new APIError(statusCode, response.getStatus());
			}
		}
		return result;
	}

	@TestVisible
	private static Date getInviteDate(
		final Map<String, Object> events,
		final Date fallbackDate) {

		return events == null
			|| !events.containsKey('created_on')
			? fallbackDate
			: Datetime.newInstance((Long)events.get('created_on') * 1000).date();
	}

	@TestVisible
	private static Account.User handleInviteResponse(
		final Account.User user,
		final RestAPI.Response response) {

		if (user == null || response == null) return user;

		if (response.hasError) {
			LoggerService.getInstance().error('User invite failed: ' + response.error);
			return user.withError(response.error);
		}

		String body = response.body;
		Map<String, Object> resp = String.isBlank(body) ? null : (Map<String, Object>)JSON.deserializeUntyped(body);
		if (Collection.isEmpty(resp)) {
			LoggerService.getInstance().error('User invite failed: empty response');
			return user.withError(new APIError(APIErrorCode.FAILURE, Label.UserInviteFailed));
		}

		return user.withInvite(
			(String)resp.get('status'),
			UUID.parse((String)resp.get('user_invite_id')),
			getInviteDate(
				(Map<String, Object>)resp.get('events'),
				Date.today()));
	}

	private Account.User inviteUser(
		final Account.User user,
		final Integer timeout) {

		if (user == null) return null;

		return handleInviteResponse(
			user,
			this.post(
				this.getBaseUrl(),
				new List<Object> { 'invite' },
				QueryString.empty,
				this.getDefaultHeaders(),
				JSON.serialize(new Map<String, Object> {
					'email' => user.email,
					'given_name' => user.firstName,
					'family_name' => user.lastName,
					'permission_profile_id' => user.canManageAccount
						? this.administratorProfileId : this.senderProfileId,
					'redirect_uri' => this.inviteRedirectUri == null ? null : this.inviteRedirectUri.toExternalForm(),
					'scope' => 'openid signature impersonation spring_write spring_read invite',
					'state' => 'not needed',
					'email_body' => this.inviteEmailBody,
					'email_subject' => this.inviteEmailSubject,
					'callback_uri' => this.inviteCallbackUri == null ? null : this.inviteCallbackUri.toExternalForm()
				}),
				timeout));
	}

	public List<Account.User> inviteUsers(final List<Account.User> users) {
		return this.inviteUsers(users, RestAPI.defaultTimeout);
	}

	public List<Account.User> inviteUsers(
		final List<Account.User> users,
		final Integer timeout) {

		List<Account.User> result = new List<Account.User>();
		for (Account.User user : (users == null ? new List<Account.User>() : users)) {
			result.add(this.inviteUser(
				user,
				timeout)); // TODO: Calculate timeout based on number of users to invite.
		}
		return result;
	}

	private Account.User resendInvite(
		final Account.User user,
		final Integer timeout) {

		if (user == null || UUID.isEmpty(user.inviteId)) return user;

		return handleInviteResponse(
			user,
			this.post(
				this.getBaseUrl(),
				new List<Object> { 'invite', user.inviteId, 'resend' },
				QueryString.empty,
				this.getDefaultHeaders(),
				JSON.serialize(new Map<String, Object> {
					'email_body' => this.inviteEmailBody,
					'email_subject' => this.inviteEmailSubject
				}),
				timeout));
	}

	public List<Account.User> resendInvites(final List<Account.User> users) {
		return this.resendInvites(users, RestAPI.defaultTimeout);
	}

	public List<Account.User> resendInvites(
		final List<Account.User> users,
		final Integer timeout) {

		List<Account.User> result = new List<Account.User>();
		for (Account.User user : (users == null ? new List<Account.User>() : users)) {
			result.add(this.resendInvite(
				user,
				timeout)); // TODO: Calculate timeout based on number of users to invite.
		}
		return result;
	}

	private Account.User revokeInvite(
		final Account.User user,
		final Integer timeout) {

		if (user == null || UUID.isEmpty(user.inviteId)) return user;

		return handleInviteResponse(
			user,
			this.del(
				this.getBaseUrl(),
				new List<Object> { 'invite', user.inviteId },
				QueryString.empty,
				this.getDefaultHeaders(),
				'{}',
				timeout));
	}

	public List<Account.User> revokeInvites(final List<Account.User> users) {
		return this.revokeInvites(users, RestAPI.defaultTimeout);
	}

	public List<Account.User> revokeInvites(
		final List<Account.User> users,
		final Integer timeout) {

		List<Account.User> result = new List<Account.User>();
		for (Account.User user : (users == null ? new List<Account.User>() : users)) {
			result.add(this.revokeInvite(
				user,
				timeout)); // TODO: Calculate timeout based on number of users to invite.
		}
		return result;
	}
}
