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
		@AuraEnabled
		public Permission permission { get; private set; }

		public AuthStatus(
			final Boolean isAuthorized,
			final Boolean isConsentRequired,
			final String message,
			final List<String> eventOrigins,
			final List<Product> products,
			final Permission permission) {

			this.isAuthorized = isAuthorized;
			this.isConsentRequired = isConsentRequired;
			this.message = message;
			this.eventOrigins = eventOrigins;
			this.products = products;
			this.permission = permission;
		}
	}

	public Class Permission {
		@AuraEnabled
		public Boolean isDocuSignAdministrator { get; private set; }
		@AuraEnabled
		public Boolean isDocuSignIntegrationUser { get; private set; }
		@AuraEnabled
		public Boolean isDocuSignNegotiator { get; private set; }
		@AuraEnabled
		public Boolean isDocuSignGenerator { get; private set; }

		public Permission() {
			this.isDocuSignAdministrator = Permissions.isDocuSignAdministrator();
			this.isDocuSignIntegrationUser = Permissions.isDocuSignIntegrationUser();
			this.isDocuSignNegotiator = Permissions.isDocuSignNegotiator();
			this.isDocuSignGenerator = Permissions.isDocuSignGenerator();
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
		} finally {
			AccountProducts.save(); // Save results from API so we do not make unnecessary callouts
		}

		return new AuthStatus(
			isAuthorized,
			isConsentRequired,
			message,
			getAllEventOrigins(), // merging community and visualforce origins
			products, new Permission());
	}

	@AuraEnabled
	public static String beginOAuth(final String target) {
		try {
			//adding site prefix to target url
			return AuthService.getLoginUrl(LoginInformation.TYPE_USER, String.format('{0}{1}', new List<String> { target, Salesforce.sitePrefix })).toExternalForm().replace('+', '%20');
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to initiate user OAuth flow.');
		}
	}

	@AuraEnabled
	public static AuthStatus getConfigAfterAuthorization() {
		try {
			List<Product> products = processProductCheckInAccountSetting(AccountProducts.getProducts());
			AccountProducts.save();
			return new AuthStatus(
				true,
				false,
				null,
				null,
				products, new Permission());
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get config.');
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
	private static List<String> getAllEventOrigins() {
		List<String> allEventOrigins = new List<String>();
		allEventOrigins.addAll(Salesforce.getVisualForceOrigins());
		List<String> communityOrigins = Salesforce.getCommunityOrigins();
		if (communityOrigins != null && !communityOrigins.isEmpty()) {
			allEventOrigins.addAll(communityOrigins);
		}

		return allEventOrigins;
	}
}
