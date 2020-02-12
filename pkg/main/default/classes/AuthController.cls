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
		@AuraEnabled
		public List<Product> products { get; private set; }

		public AuthStatus(
			final Boolean isAuthorized,
			final Boolean isConsentRequired,
			final String message,
			final List<String> eventOrigins,
			final List<Product> products) {

			this.isAuthorized = isAuthorized;
			this.isConsentRequired = isConsentRequired;
			this.message = message;
			this.eventOrigins = eventOrigins;
			this.products = products;
		}
	}

	@AuraEnabled
	public static AuthStatus getAuthStatus() {
		Boolean isAuthorized = true;
		Boolean isConsentRequired = false;
		String message = null;
		List<Product> products = new List<Product>();

		try {
			if (Permissions.isDocuSignUser()) { // Meets minimum requirement for access token
				AuthService.getAccessToken();
				products = processProductCheckInAccountSetting(AccountProducts.getProducts());
			} else {
				isAuthorized = false;
				message = Label.MustBeDocuSignUser;
			}
		} catch (APIException ex) {
			LoggerService.getInstance().exception(ex, 'Error while checking user status for ' + UserInfo.getUserName());
			isAuthorized = false;
			if (ex.error == APIError.consentRequired) {
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
			Salesforce.getVisualforceOrigins(),
			products);
	}

	@AuraEnabled
	public static String beginOAuth(final String target) {
		try {
			return AuthService.getLoginUrl(LoginInformation.TYPE_USER, target).toExternalForm().replace('+', '%20');
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to initiate user OAuth flow.');
		}
	}

	@AuraEnabled
	public static List<Product> getProductsOnAccount() {
		try {
			return processProductCheckInAccountSetting(AccountProducts.getProducts());
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to check Products on account.');
		}
	}

	private static List<Product> processProductCheckInAccountSetting(List<Product> products) {
		if (products != null) {
			Boolean isESignatureEnabled = AccountSettings.getInstance().isESignatureEnabled;
			for (Integer i = 0; i < products.size(); i++) {
				if (products[i].name == Product.ESIGNATURE && products[i].status == Product.STATUS_ACTIVE && !isESignatureEnabled) {
					products.remove(i);
					break;
				}
			}
		}
		return products;
	}
}
