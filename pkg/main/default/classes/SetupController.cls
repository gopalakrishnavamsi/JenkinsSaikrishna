public with sharing class SetupController extends Controller {

	public class LoginInformation {

		@AuraEnabled
		public Boolean isLoggedIn { get; private set; }
		@AuraEnabled
		public String email { get; private set; }
		@AuraEnabled
		public Long accountNumber { get; private set; }
		@AuraEnabled
		public String environment { get; private set; }
		@AuraEnabled
		public String otherUrl { get; private set; }
		@AuraEnabled
		public Boolean isTrial { get; private set; }
		@AuraEnabled
		public Account.TrialStatus trialStatus { get; private set; }
		@AuraEnabled
		public String status { get; private set; }
		@AuraEnabled
		public List<AccountService.AccountOption> accountOptions { get; private set; }

		private LoginInformation(final Boolean isLoggedIn, final String email, final Long accountNumber, final String environment,
			final String otherUrl, final Boolean isTrial, final Account.TrialStatus trialStatus,
			final AccountService.LoginStatus status, final List<AccountService.AccountOption> accountOptions) {

			this.isLoggedIn = isLoggedIn;
			this.email = email;
			this.accountNumber = accountNumber;
			this.environment = environment;
			this.otherUrl = otherUrl;
			this.isTrial = isTrial;
			this.trialStatus = trialStatus;
			this.status = status == null ? AccountService.LoginStatus.Failure.name() : status.name();
			this.accountOptions = accountOptions;
		}
	}

	private static LoginInformation getLogin(
		final String dsUsername,
		final String dsEnvironment,
		final String dsUrl,
		final AccountService.LoginResult loginResult) {

		Credentials c = null;
		Boolean isLoggedIn = Credentials.isAccountValid();
		if (isLoggedIn) {
			c = Credentials.getInstance();
		}
		Account a = loginResult == null && isLoggedIn ? AccountService.getAccount() : null;

		return new LoginInformation(
			isLoggedIn,
			c != null ? c.email : dsUsername,
			c != null ? c.accountNumber : null,
			c != null ? c.environment.environment.name() : dsEnvironment,
			c != null && c.environment.baseUrl != null ? c.environment.baseUrl.toExternalForm() : dsUrl,
			a != null && a.isTrial,
			a != null && a.isTrial ? a.trialStatus : null,
			loginResult != null ? loginResult.status : null,
			loginResult != null ? loginResult.accountOptions : null);
	}

	@AuraEnabled
	public static LoginInformation getLogin() {
		try {
			Permissions.verifyIsDocuSignAdministrator();

			return getLogin(UserInfo.getUserEmail(), 'Production', null, null);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get setup state');
		}
	}

	@TestVisible
	private static Environment.Target getTarget(final String s) {
		Environment.Target result = Environment.Target.Other;
		if (String.isBlank(s)) {
			result = Environment.Target.Invalid;
		} else if (s == 'prod' || s == 'production') {
			result = Environment.Target.Production;
		} else if (s == 'demo') {
			result = Environment.Target.Demo;
		} else if (s == 'stage') {
			result = Environment.Target.Stage;
		}
		return result;
	}

	@AuraEnabled
	public static LoginInformation login(
		final String dsUsername,
		final String dsPassword,
		final String dsEnvironment,
		final String dsUrl,
		final Integer dsAccountNumber) {

		try {
			return getLogin(
				dsUsername,
				dsEnvironment,
				dsUrl,
				AccountService.login(
					dsUsername,
					dsPassword,
					getTarget(dsEnvironment),
					String.isBlank(dsUrl) ? null : new Url(dsUrl),
					Integer.valueOf(dsAccountNumber)));
		} catch (UnauthorizedException ex) {
			AuraHandledException ex2 = new AuraHandledException(ex.getMessage());
			ex2.setMessage(ex.getMessage());
			throw ex2;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to log into DocuSign.');
		}
	}

	@AuraEnabled
	public static Account getAccount() {
		try {
			return AccountService.getAccount();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to read DocuSign account.');
		}
	}

	@AuraEnabled
	public static void logout(final Boolean resetUsers) {
		try {
			AccountService.resetCredentials(resetUsers);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to log out of DocuSign.');
		}
	}

	@AuraEnabled
	public static AccountService.TrialAccount prepareTrial(final String email) {
		try {
			return AccountService.prepareTrial(email);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to prepare DocuSign trial');
		}
	}

	@AuraEnabled
	public static Account.Membership startTrial(final String trialJson) {
		try {
			return AccountService.createTrial((Account.Trial)JSON.deserialize(trialJson, Account.Trial.class));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to create DocuSign trial.');
		}
	}

	@AuraEnabled
	public static List<Account.User> addUser(final Id sourceId, final String email, final String firstName,
		final String lastName, final Boolean canManageAccount) {

		try {
			List<Account.User> users = AccountService.addUsers(new List<Account.User> {
				new Account.User(sourceId, email, email, firstName, lastName, canManageAccount)
			});
			if (Collection.isNotEmpty(users) && users[0].hasError) {
				throw new APIException(users[0].error);
			}
			return AccountService.getUsers();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to add DocuSign account users.');
		}
	}

	@AuraEnabled
	public static List<Account.User> removeUser(final Id sourceId, final String username) {
		try {
			AccountService.removeUsers(new List<Account.User> {
				new Account.User(sourceId, username)
			}, true);
			return AccountService.getUsers();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to remove DocuSign account users.');
		}
	}

	@AuraEnabled
	public static List<Account.User> getUsers() {
		try {
			return AccountService.getUsers();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to read DocuSign account users.');
		}
	}

	@AuraEnabled
	public static User getUser(final Id userId) {
		try {
			Permissions.verifyIsQueryable(User.getSObjectType(), new List<String> { 'Id', 'Email', 'FirstName', 'LastName' });

			return [SELECT Id, Email, FirstName, LastName FROM User WHERE Id = :userId LIMIT 1];
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to read user.');
		}
	}
}
