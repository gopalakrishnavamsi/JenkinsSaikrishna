/**
 * Provides methods for verifying and enabling authorization to the DocuSign connected application. Authorization
 * allows the DocuSign platform to read and write data to Salesforce, e.g. writing back documents generated with
 * DocuSign Gen or reading merge fields with DocuSign eSignature.
 */
public with sharing class PlatformAuthorizationService {

	@TestVisible
	private static final Database DB = new PlatformAuthorizationService.Database();
	private static final Integer TIMEOUT = 5000;
	@TestVisible
	private static final Integer DEFAULT_CHECK_FREQUENCY_MIN = 15;

	@TestVisible
	private static AuthStatus status = null;

	@TestVisible
	private class Database {

		public AuthStatus queryAuthStatus() {
			UserSettings__c settings = UserSettings__c.getInstance();
			return new AuthStatus(
				settings.IsPlatformAuthorized__c,
				settings.PlatformAuthorizationLastChecked__c,
				Integer.valueOf(settings.PlatformAuthorizationCheckFrequency__c),
				false);
		}

		public AuthStatus updateAuthStatus(final AuthStatus status) {
			if (status != null) {
				UserSettings__c settings = UserSettings__c.getInstance();
				settings.IsPlatformAuthorized__c = status.isAuthorized == true;
				settings.PlatformAuthorizationLastChecked__c = status.lastChecked == null
					? Datetime.now() : status.lastChecked;
				settings.PlatformAuthorizationCheckFrequency__c = status.checkFrequencyMinutes == null
					? DEFAULT_CHECK_FREQUENCY_MIN : status.checkFrequencyMinutes;
				upsert settings;
			}
			return status;
		}

		public Set<Id> queryPermissionSetIds() {
			Set<Id> result = new Set<Id>();
			for (PermissionSet ps : [
				SELECT Id
				FROM PermissionSet
				WHERE Name IN :(new List<String> { 'Docusign_Administrator', 'DocuSign_User' })
				AND NamespacePrefix = :Application.packageNamespace
				WITH SECURITY_ENFORCED
				LIMIT 2
			]) {
				result.add(ps.Id);
			}
			return result;
		}

		public Set<Id> queryConnectedApplicationIds() {
			Set<Id> result = new Set<Id>();
			for (ConnectedApplication ca : [
				SELECT Id
				FROM ConnectedApplication
				WHERE Name LIKE 'DocuSign%'
				WITH SECURITY_ENFORCED
				LIMIT 100
			]) {
				result.add(ca.Id);
			}
			return result;
		}

		public List<SetupEntityAccess> querySetupEntityAccess() {
			return [
				SELECT Id, ParentId, SetupEntityId
				FROM SetupEntityAccess
				WHERE ParentId IN (
					SELECT Id
					FROM PermissionSet
					WHERE Name IN :(new List<String> { 'Docusign_Administrator', 'DocuSign_User' })
					AND NamespacePrefix = :Application.packageNamespace
				)
				AND SetupEntityId IN (
					SELECT Id
					FROM ConnectedApplication
					WHERE Name LIKE 'DocuSign%'
				)
				WITH SECURITY_ENFORCED
				LIMIT 200
			];
		}

		public List<SetupEntityAccess> insertSetupEntityAccess(final List<SetupEntityAccess> seas) {
			Permissions.verifyIsCreateable(SetupEntityAccess.getSObjectType(), new List<String> {
				'ParentId', 'SetupEntityId'
			});

			if (Collection.isNotEmpty(seas)) {
				// allow partial success as the access may already be in place for one or more parents
				LoggerService log = LoggerService.getInstance();
				for (Database.SaveResult sr : System.Database.insert(seas, false)) {
					if (!sr.success) {
						List<String> errors = new List<String>();
						for (Database.Error e : sr.errors) {
							errors.add(String.format('[{0}] {1}. Fields: {2}', new List<Object> {
								e.statusCode, e.message, String.join(e.fields, ', ')
							}));
						}
						log.warn('Failed to insert setup entity access:\n' + String.join(errors, '\n'));
					}
				}
			}
			return seas == null ? new List<SetupEntityAccess>() : seas;
		}

		public List<SetupEntityAccess> deleteSetupEntityAccess(final List<SetupEntityAccess> seas) {
			Permissions.verifyIsDeletable(SetupEntityAccess.getSObjectType());

			if (Collection.isNotEmpty(seas)) delete seas;

			return seas == null ? new List<SetupEntityAccess>() : seas;
		}
	}

	@TestVisible
	private class AuthStatus {
		public Boolean isAuthorized { get; private set; }
		public Datetime lastChecked { get; private set; }
		public Integer checkFrequencyMinutes { get; private set; }
		public Boolean isDirty { get; private set; }

		public AuthStatus(
			final Boolean isAuthorized,
			final Datetime lastChecked,
			final Integer checkFrequencyMinutes,
			final Boolean isDirty) {

			this.isAuthorized = isAuthorized;
			this.lastChecked = lastChecked;
			this.checkFrequencyMinutes = checkFrequencyMinutes;
			this.isDirty = isDirty;
		}

		public AuthStatus clearIsDirty() {
			this.isDirty = false;
			return this;
		}
	}

	@TestVisible
	private class SalesforceOAuthAPI extends RestAPI {

		@TestVisible
		override protected virtual APIError getError(final HttpResponse response) {
			APIError result = super.getError(response);
			if (result != APIError.none) {
				String body = response.getBody();
				this.log.warn('Salesforce authorization service error:\n' + body);
				try {
					Map<String, Object> errResp = (Map<String, Object>)JSON.deserializeUntyped(body);
					String errCode = (String)errResp.get('error');
					String errMsg = (String)errResp.get('error_description');
					// https://help.salesforce.com/articleView?id=remoteaccess_oauth_flow_errors.htm&type=5
					switch on errCode {
						when 'access_denied' { // consent required?
							result = new APIError(APIErrorCode.CONSENT_REQUIRED, Label.ConsentRequired);
						} when 'inactive_user' {
							result = new APIError(APIErrorCode.USER_NOT_ACTIVATED, errMsg);
						} when 'invalid_app_access' { // Typo in documentation? "invalid_app_acess"
							result = new APIError(APIErrorCode.ADMIN_CONSENT_REQUIRED, errMsg);
						} when 'invalid_grant' { // consent required?
							result = new APIError(APIErrorCode.CONSENT_REQUIRED, Label.ConsentRequired);
						} when else {
							this.log.warn('Unknown auth error');
							result = new APIError(APIErrorCode.UNAUTHORIZED, String.isBlank(errMsg)
								? response.getStatus() : errMsg);
						}
					}
				} catch (Exception ex) {
					this.log.exception(ex, 'Failed to parse response as a Salesforce auth error');
				}
			}
			return result;
		}

		@TestVisible
		private String generateJwt(
			final String clientId,
			final String username,
			final String audience,
			final Blob jwtSigningKey) {

			String header = StringUtils.base64UrlEncode(Blob.valueOf('{"alg":"RS256"}'));
			String claims = StringUtils.base64UrlEncode(Blob.valueOf(JSON.serialize(new Map<String, Object> {
				'iss' => clientId,
				'sub' => username,
				'aud' => audience,
				'exp' => Datetime.now().addMinutes(1).getTime() / 1000
			})));
			String signature = StringUtils.base64UrlEncode(Crypto.sign(
				'RSA-SHA256',
				Blob.valueOf(header + '.' + claims),
				jwtSigningKey));

			return header + '.' + claims + '.' + signature;
		}

		public String getAccessToken(
			final String clientId,
			final String username,
			final String audience,
			final Blob jwtSigningKey) {

			RestAPI.Response response = this.post(
				new Url(Salesforce.baseUrl, '/'),
				new List<Object> { 'services', 'oauth2', 'token' },
				QueryString.empty,
				new Map<String, String> {
					'Content-Type' => 'application/x-www-form-urlencoded',
					'Accept' => 'application/json'
				},
				'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' +
					generateJwt(
						clientId,
						username,
						audience,
						jwtSigningKey),
				TIMEOUT);
			if (response.hasError) {
				LoggerService.getInstance().error('Failed to get Salesforce access token: ' + response.error);
				throw new APIException(response.error);
			}

			return (String)((Map<String, Object>)JSON.deserializeUntyped(response.body)).get('access_token');
		}
	}

	@TestVisible
	private static Boolean checkIsAuthorized() {
		Organization__mdt orgMd = [
			SELECT ConnectedAppId__c,
				ConnectedAppJwtSigningKey__c
			FROM Organization__mdt
			WHERE DeveloperName = 'Current'
			LIMIT 1
		];
		Boolean result = false;
		try {
			result = String.isNotBlank(new SalesforceOAuthAPI().getAccessToken(
				orgMd.ConnectedAppId__c,
				UserInfo.getUserName(),
				Salesforce.oauthAudience.toExternalForm(),
				EncodingUtil.base64Decode(orgMd.ConnectedAppJwtSigningKey__c)));
		} catch (APIException ex) {
			if (ex.error != APIError.consentRequired) throw ex;
		}
		return result;
	}

	@TestVisible
	private static AuthStatus getAuthStatus(final AuthStatus status) {
		AuthStatus result;
		if (status == null
			|| status.isAuthorized == null
			|| status.lastChecked == null
			|| status.checkFrequencyMinutes == null
			|| status.lastChecked.addMinutes(status.checkFrequencyMinutes) <= Datetime.now()) {

			result = new AuthStatus(
				checkIsAuthorized(),
				Datetime.now(),
				status.checkFrequencyMinutes == null ? DEFAULT_CHECK_FREQUENCY_MIN : status.checkFrequencyMinutes,
				true);
		} else { // Don't recheck now
			result = new AuthStatus(
				status.isAuthorized,
				status.lastChecked,
				status.checkFrequencyMinutes == null ? DEFAULT_CHECK_FREQUENCY_MIN : status.checkFrequencyMinutes,
				false);
		}
		return result;
	}

	/**
	 * Checks whether a user is authorized to use and has granted consent to the DocuSign connected application.
	 * <p>
	 * Callers must be assigned the <code>DocuSign Administrator</code> or <code>DocuSign User</code> permission set.
	 *
	 * @return <code>true</code> if the user is authorized to use and has granted consent to the DocuSign connected
	 * application, <code>false</code> otherwise.
	 */
	public static Boolean isAuthorized() {
		Permissions.verifyIsDocuSignUser();

		if (status == null) {
			status = getAuthStatus(DB.queryAuthStatus());
		}
		return status.isAuthorized;
	}

	/**
	 * Caches the connected application authorization status if necessary.
	 * <p>
	 * Callers must be assigned the <code>DocuSign Administrator</code> or <code>DocuSign User</code> permission set.
	 *
	 * @return <code>true</code> if the authorization status was dirty and subsequently cached, <code>false</code>
	 * otherwise.
	 */
	public static Boolean save() {
		Permissions.verifyIsDocuSignUser();

		Boolean result = false;
		if (status != null && status.isDirty) {
			DB.updateAuthStatus(status);
			status.clearIsDirty();
			result = true;
		}
		return result;
	}

	/**
	 * Admin authorization for the DocuSign connected application. The app is authorized for the
	 * <code>DocuSign Administrator</code> and <code>DocuSign User</code> permission sets.
	 * <p>
	 * Callers must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return List of <code>SetupEntityAccess</code> created.
	 */
	public static List<SetupEntityAccess> authorize() {
		Permissions.verifyIsDocuSignAdministrator();

		List<SetupEntityAccess> seas = new List<SetupEntityAccess>();
		Set<Id> psIds = DB.queryPermissionSetIds();
		Set<Id> caIds = DB.queryConnectedApplicationIds();
		for (Id psId : psIds) {
			for (Id caId : caIds) {
				seas.add(new SetupEntityAccess(
					ParentId = psId,
					SetupEntityId = caId));
			}
		}

		return DB.insertSetupEntityAccess(seas);
	}

	/**
	 * Removes admin authorization for the DocuSign connected application. The app is deauthorized for the
	 * <code>DocuSign Administrator</code> and <code>DocuSign User</code> permission sets.
	 * <p>
	 * Callers must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return List of <code>SetupEntityAccess</code> created.
	 */
	public static List<SetupEntityAccess> deauthorize() {
		Permissions.verifyIsDocuSignAdministrator();

		return DB.deleteSetupEntityAccess(DB.querySetupEntityAccess());
	}
}
