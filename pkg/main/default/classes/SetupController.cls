public with sharing class SetupController extends Controller {

	private static final Integer USER_LIMIT = 10000;

	@AuraEnabled(Cacheable = true)
	public static LoginInformation getLogin() {
		try {
			Permissions.verifyIsDocuSignAdministrator();

			if (Credentials.isAccountValid()) {
				Credentials c = Credentials.getInstance();
				// TODO: Handle trial accounts
				return new LoginInformation(
					c.user.id,
					c.user.name,
					c.account.email,
					new List<LoginInformation.Account> {
						new LoginInformation.Account(
							c.account.id,
							c.account.accountNumber,
							c.account.name,
							c.environment.eSignatureBaseUrl == null
								? null : c.environment.eSignatureBaseUrl.toExternalForm(),
							true)
					});
			} else {
				return new LoginInformation(
					null,
					UserInfo.getName(),
					UserInfo.getUserEmail(),
					null);
			}
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get login status.');
		}
	}

	@RemoteAction
	public static String beginOAuth(
		final String target,
		final String environment,
		final String otherUrl) {

		//since spaces are being replaced with + and this is breaking scopes we will replace + with %20
		return AuthService.getLoginUrl(
			target,
			DocuSign.parseEnvironment(environment),
			String.isBlank(otherUrl) ? null : new Url(otherUrl)).toExternalForm().replace('+', '%20');
	}

	@RemoteAction
	public static LoginInformation completeOAuth(
		final String authorizationCode,
		final String state,
		final String errorCode,
		final String errorMessage) {

		if (String.isBlank(errorCode)) {
			return AuthService.redeemCode(authorizationCode, state);
		} else {
			return AuthService.redeemError(errorCode, errorMessage, state);
		}
	}

	@RemoteAction
	public static String beginSpringOAuth(final String state) {
		return AuthService.getSpringOAuthUrl(state).toExternalForm();
	}

	@RemoteAction
	public static SpringOAuthLoginInformation completeSpringOAuth(final String authorizationCode) {
		return AuthService.completeSpringOAuth(authorizationCode);
	}

	@AuraEnabled
	public static LoginInformation setAccount(
		final String environment,
		final String otherUrl,
		final Long accountNumber) {

		try {
			return AuthService.setAccount(
				DocuSign.parseEnvironment(environment),
				String.isBlank(otherUrl) ? null : new Url(otherUrl),
				accountNumber);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to select account');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static Account getAccount() {
		try {
			return AccountService.getAccount();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to read DocuSign account.');
		}
	}

	@AuraEnabled
	public static LoginInformation logout(final Boolean resetUsers) {
		try {
			AuthService.resetAccount(resetUsers);
			return new LoginInformation(
				null,
				UserInfo.getName(),
				UserInfo.getUserEmail(),
				new List<LoginInformation.Account>());
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to log out of DocuSign.');
		}
	}

	@AuraEnabled
	public static List<Account.User> addUser(
		final Id sourceId,
		final String email,
		final String firstName,
		final String lastName,
		final Boolean canManageAccount) {

		try {
			if (sourceId == null || String.isBlank(email)) throw new DocuSignException(Label.UndefinedArgument);

			List<Account.User> users = UserService.addUsers(new List<Account.User> {
				new Account.User(
					null,
					sourceId,
					email,
					firstName,
					lastName,
					null,
					null,
					canManageAccount == true,
					null,
					APIError.none)
			}, canManageAccount == true
				? new Set<String> { Permissions.DOCUSIGN_ADMINISTRATOR }
				: new Set<String> { Permissions.DOCUSIGN_USER });
			if (Collection.isNotEmpty(users) && users[0].hasError) {
				throw new APIException(users[0].error);
			}
			return UserService.getUsers(USER_LIMIT);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to add DocuSign account users.');
		}
	}

	@AuraEnabled
	public static List<Account.User> removeUser(
		final Id sourceId,
		final String id) {

		try {
			if (sourceId == null || String.isBlank(id)) throw new DocuSignException(Label.UndefinedArgument);

			UserService.removeUsers(new List<Account.User> {
				new Account.User(
					UUID.parse(id),
					sourceId)
			}, true);

			return UserService.getUsers(USER_LIMIT);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to remove DocuSign account users.');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static List<Account.User> getUsers() {
		try {
			return UserService.getUsers(USER_LIMIT);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to read DocuSign account users.');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static User getUser(final Id userId) {
		try {
			Permissions.verifyIsQueryable(User.getSObjectType(), new List<String> {
				'Id', 'Email', 'FirstName', 'LastName'
			});

			return [SELECT Id, Email, FirstName, LastName FROM User WHERE Id = :userId LIMIT 1];
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to read user.');
		}
	}

	@AuraEnabled
	public static Boolean addTrialGen() {
		try {
			return AccountProducts.getInstance().startTrial(Product.GEN) != null;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to add Gen Trial.');
		}
	}
}
