public with sharing class AuthController {

	public class AuthStatus {
		@AuraEnabled
		public Boolean isAuthorized { get; private set; }
		@AuraEnabled
		public Boolean isConsentRequired { get; private set; }
		@AuraEnabled
		public String message { get; private set; }
		@AuraEnabled
		public String eventOrigin { get; private set; }

		public AuthStatus(
			final Boolean isAuthorized,
			final Boolean isConsentRequired,
			final String message,
			final String eventOrigin) {

			this.isAuthorized = isAuthorized;
			this.isConsentRequired = isConsentRequired;
			this.message = message;
			this.eventOrigin = eventOrigin;
		}
	}

	@AuraEnabled
	public static AuthStatus getAuthStatus() {
		Boolean isAuthorized = true;
		Boolean isConsentRequired = false;
		String message = null;

		try {
			if (Permissions.isDocuSignUser()) { // Meets minimum requirement for access token
				AuthService.getAccessToken();
			} else {
				isAuthorized = false;
				message = Label.MustBeDocuSignUser;
			}
		} catch (APIException ex) {
			LoggerService.getInstance().exception(ex, 'Error while checking user status for ' + UserInfo.getUserName());
			isAuthorized = false;
			if (ex.error != null
				&& ex.error instanceof AuthService.AuthError
				&& ((AuthService.AuthError)ex.error).reason == APIErrorCode.CONSENT_REQUIRED) {

				isConsentRequired = true;
				message = Label.ConsentRequired;
			} else {
				isAuthorized = false;
				message = ex.getMessage();
			}
		} catch (Exception ex) {
			LoggerService.getInstance().exception(ex, 'Error while checking user status for ' + UserInfo.getUserName());
			isAuthorized = false;
			message = ex.getMessage();
		}

		return new AuthStatus(
			isAuthorized,
			isConsentRequired,
			message,
			Salesforce.getVisualforceOrigin(true));
	}

	@AuraEnabled
	public static String beginOAuth(final String origin) {
		try {
			return AuthService.getLoginUrl(origin).toExternalForm().replace('+', '%20');
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to initiate user OAuth flow.');
		}
	}
}
