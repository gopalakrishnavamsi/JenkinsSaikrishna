public with sharing class AuthController {

	public class AuthStatus {
		@AuraEnabled
		public Boolean isAuthorized { get; private set; }
		@AuraEnabled
		public Boolean isConsentRequired { get; private set; }
		@AuraEnabled
		public String message { get; private set; }
		@AuraEnabled
		public List<String> eventOrigins { get; private set; }

		public AuthStatus(
			final Boolean isAuthorized,
			final Boolean isConsentRequired,
			final String message,
			final List<String> eventOrigins) {

			this.isAuthorized = isAuthorized;
			this.isConsentRequired = isConsentRequired;
			this.message = message;
			this.eventOrigins = eventOrigins;
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
			Salesforce.getVisualforceOrigins());
	}

	@AuraEnabled
	public static String beginOAuth(final String target) {
		try {
			return AuthService.getLoginUrl(target).toExternalForm().replace('+', '%20');
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to initiate user OAuth flow.');
		}
	}

	@AuraEnabled
	public static List<Product> getProductsOnAccount() {
		try {
			return AccountProducts.getProducts();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to check Products on account.');
		}
	}
}
