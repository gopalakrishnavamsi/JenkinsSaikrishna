public with sharing class SetupController extends Controller {

	public class Login {

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

		private Login(final Boolean isLoggedIn, final String email, final Long accountNumber, final String environment,
			final String otherUrl, final Boolean isTrial, final Account.TrialStatus trialStatus) {

			this.isLoggedIn = isLoggedIn;
			this.email = email;
			this.accountNumber = accountNumber;
			this.environment = environment;
			this.otherUrl = otherUrl;
			this.isTrial = isTrial;
			this.trialStatus = trialStatus;
		}
	}

	@AuraEnabled
	public static Login getLogin() {
		try {
			Permissions.verifyIsDocuSignAdministrator();

			Credentials c = null;
			Boolean isLoggedIn = Credentials.isAccountValid();
			if (isLoggedIn) {
				c = Credentials.getInstance();
			}
			Account a = isLoggedIn ? AccountService.getAccount() : null;

			return new Login(
				isLoggedIn,
				c != null ? c.email : UserInfo.getUserEmail(),
				c != null ? c.accountNumber : null,
				c != null ? c.environment.environment.name() : 'Production',
				c != null && c.environment.baseUrl != null ? c.environment.baseUrl.toExternalForm() : null,
				a != null && a.isTrial,
				a != null && a.isTrial ? a.trialStatus : null);
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
	public static AccountService.LoginResult login(final String dsUsername, final String dsPassword,
		final String dsEnvironment, final String dsUrl, final Long dsAccountNumber) {

		try {
			return AccountService.login(dsUsername, dsPassword, getTarget(dsEnvironment),
				String.isBlank(dsUrl) ? null : new Url(dsUrl), dsAccountNumber);
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
	public static Account.Membership startTrial(final String email) {
		try {
			Account.Trial trial = AccountService.prepareTrial(email);
			return AccountService.createTrial(trial.acceptTermsAndConditions());
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to create DocuSign trial.');
		}
	}

	@AuraEnabled
	public static List<Account.User> addUser(final Id sourceId, final String email, final String firstName,
		final String lastName, final Boolean canManageAccount) {

		try {
			return AccountService.addUsers(new List<Account.User> {
				new Account.User(sourceId, email, email, firstName, lastName, canManageAccount)
			});
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to add DocuSign account users.');
		}
	}

	@AuraEnabled
	public static List<Account.User> removeUser(final Id sourceId, final String username) {
		try {
			return AccountService.removeUsers(new List<Account.User> {
				new Account.User(sourceId, username)
			}, true);
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

	// TODO: Why do we need this method? Remove if possible.
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
