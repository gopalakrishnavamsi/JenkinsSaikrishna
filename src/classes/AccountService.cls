public with sharing class AccountService {

	private static final Database DB = new AccountService.Database();
	private static final LoggerService LOG = LoggerService.getInstance();
	private static Account currentAccount;

	private class Database {

		public User queryUser(final Id userId) {
			Permissions.verifyIsQueryable('User', new List<String> {
				'Phone', 'MobilePhone', 'Street', 'City', 'State',
				'PostalCode', 'Country'
			});
			return [
				SELECT
					Phone, MobilePhone, Street, City, State, PostalCode, Country
				FROM User
				WHERE Id = :userId
				LIMIT 1
			];
		}
	}

	public enum LoginStatus {
		Success, Failure, SelectAccount
	}

	public class LoginResult {
		public LoginStatus status { get; private set; }
		public List<AccountOption> accountOptions { get; private set; }

		private LoginResult(final LoginStatus status, final List<AccountOption> accountOptions) {
			this.status = status == null ? LoginStatus.Failure : status;
			this.accountOptions = accountOptions == null ? new List<AccountOption>() : accountOptions;
		}
	}

	public class AccountOption {
		public Long id { get; private set; }
		public String display { get; private set; }

		private AccountOption(final Long id, final String display) {
			this.id = id;
			this.display = display;
		}
	}

	@TestVisible
	private class TrialStatus {
		public Boolean isExpired { get; private set; }
		public String message { get; private set; }

		public TrialStatus(final Boolean isExpired, final String message) {
			this.isExpired = isExpired;
			this.message = message;
		}
	}

	public static Account getAccount() {
		Permissions.verifyIsDocuSignAdministrator();

		if (currentAccount == null) {
			currentAccount = AccountAPI.getInstance().getAccount();
		}
		return currentAccount;
	}

	@TestVisible
	private static TrialStatus getTrialStatus(final Account account) {
		Boolean isExpired = false;
		String message = null;

		if (account != null
			&& account.billing != null
			&& account.environment != null
			&& account.plan != null
			&& account.plan.id == account.environment.trialPlanId) {

			Integer intDays = Date.today().daysBetween(account.billing.endDate);
			if (intDays < 0) {
				isExpired = true;
				message = Label.TrialAccountExpired;
			} else if (intDays == 0) {
				message = Label.TrialAccountExpiresToday;
			} else if (intDays == 1) {
				message = Label.TrialAccountExpiresOneDay;
			} else if (intDays < 7) {
				message = String.format(Label.TrialAccountExpiresSoon_1, new List<String> { String.valueOf(intDays) });
			}
		}
		return new TrialStatus(isExpired, message);
	}

	@TestVisible
	private static Environment parseEnvironment(final String environmentName, final String otherUrl) {
		// Parse and validate the supplied environment to ensure it is a docusign domain.
		Environment env;
		try {
			env = Environment.fromTarget(environmentName, otherURL);
		} catch (Exception ex) {
			LOG.exception(ex, 'Failed to parse DocuSign environment');
			env = Environment.Invalid;
		}
		return env;
	}

	public static LoginResult login(final String username, final String password, final String environmentName,
		final String otherUrl, Long selectedAccountId) {

		Permissions.verifyIsDocuSignAdministrator();

		// 1) Parse valid DocuSign environment.
		Environment env = parseEnvironment(environmentName, otherUrl);
		if (!Environment.isValid(env)) {
			LOG.error('Invalid DocuSign environment: ' + environmentName + ' => ' + otherURL);
			throw new DocuSignException(Label.InvalidEnvironment);
		}

		// 2) Get valid DocuSign accounts.
		Account.Memberships memberships;
		try {
			memberships = AccountAPI.getInstance(env, username, password).getValidAccounts();
		} catch (UnauthorizedException ex) {
			LOG.exception(ex, 'Failed to read available accounts');
			throw new UnauthorizedException(Label.InvalidUsernameOrPassword);
		}

		if (memberships == null || Collection.isEmpty(memberships.accounts)) {
			throw new DocuSignException(Label.NoValidAccounts);
		}

		// 3) Filter valid accounts.
		List<AccountOption> options = new List<AccountOption>();
		Account.Membership validMembership;
		Boolean selectAccount = selectedAccountId == null || selectedAccountId <= 0L;
		for (Account.Membership a : memberships.accounts) {
			if (selectAccount || selectedAccountId == a.accountId) {
				options.add(new AccountOption(a.accountId, a.name + ' (' + a.accountId + ')'));
				validMembership = a;
			}
		}

		// 4) Save results if only one account is filtered, or return list for user selection.
		LoginStatus status = null;
		if (options.size() == 1) {
			Environment ae = Environment.fromURL(validMembership.baseURL);
			String envString = ae.Environment.name().toLowerCase();
			LOG.debug('AdminManager.login: account base URL = ' + validMembership.baseURL.toExternalForm()
				+ ', parsed base = ' + ae.baseURL.toExternalForm()
				+ ', environment = ' + ae.Environment.name().toLowerCase());

			credentials.save(ae, validMembership.accountUUID, String.valueOf(validMembership.userId),
				validMembership.apiPassword, true, true);
			status = LoginStatus.Success;
		} else { // more than 1 valid account, just return results
			status = LoginStatus.SelectAccount;
		}

		return new LoginResult(options.size() > 1 ? LoginStatus.SelectAccount : LoginStatus.Success, options);
	}

	private static AccountSettings__c completeSetup() {
		AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
		accountSettings.SetupComplete__c = true;
		accountSettings.Features__c = null;
		update accountSettings;
		return accountSettings;
	}

	public static String connect(final String username, final String password) {
		Permissions.verifyIsDocuSignAdministrator();

		String result = AccountSoapAPI.getInstance().setConnectCredentials(username, password);
		completeSetup();
		return result;
	}

	public static Account.Trial prepareTrial(final String email) {
		Permissions.verifyIsDocuSignAdministrator();

		User u = DB.queryUser(UserInfo.getUserId());
		return new Account.Trial(
			UserInfo.getOrganizationName(),
			new Account.TrialUser(
				email,
				UserInfo.getFirstName(),
				UserInfo.getLastName()),
			new Account.Address(
				u.Street,
				null,
				u.City,
				u.State,
				u.PostalCode,
				u.Country,
				String.isBlank(u.Phone) ? u.MobilePhone : u.Phone),
			false);
	}

	public static Account.Membership createTrial(final Account.Trial trial) {
		Permissions.verifyIsDocuSignAdministrator();

		ValidationResult vr = validate(trial);
		if (!vr.isValid) {
			throw new ValidationException(Label.InvalidTrialAccount, vr);
		}

		Account.Membership result = AccountAPI.getInstance(Environment.production).createTrialAccount(trial);
		Credentials.save(Environment.fromURL(result.baseUrl), result.accountUUID, String.valueOf(result.userId),
			result.apiPassword, true, false);
		return result.scrub(); // Don't return sensitive info.
	}

	@TestVisible
	private static ValidationResult validate(final Account.Trial trial) {
		ValidationResult result = new ValidationResult();
		if (trial == null) {
			result.add(Label.UndefinedArgument);
		} else {
			if (trial.user == null || String.isBlank(trial.user.email)) {
				result.add(Label.EmailRequired);
			} else if (trial.user != null && !StringUtils.isValidEmail(trial.user.email)) {
				result.add(Label.InvalidEmail);
			}
			if (trial.user == null || String.isBlank(trial.user.name)) {
				result.add(Label.NameRequired);
			}
			if (String.isBlank(trial.company)) {
				result.add(Label.CompanyRequired);
			}
			if (!trial.termsAccepted) {
				result.add(Label.MustAgreeToTCs);
			}
		}
		return result;
	}

	public static Url getDocuSignUrl() {
		if (!Permissions.isDocuSignUser()
			|| String.isBlank(UserSettings__c.getInstance(UserInfo.getUserId()).Username__c)) {

			throw new UnauthorizedException(Label.UnauthorizedPageAccess);
		}

		return AccountAPI.getInstance().getConsoleViewURL();
	}

	public class Settings {
		public EnvelopeSettings envelope { get; private set; }
		public List<Recipient.EmailSettings> defaultEmailLocalizations { get; private set; }
		public List<Localization.ChatterSettings> defaultChatterLocalizations { get; private set; }
		public Integer calloutTimeout { get; private set; }
		public List<String> entityResolvers { get; private set; }
		public List<String> documentResolvers { get; private set; }
		public List<String> recipientResolvers { get; private set; }
		public SearchBehavior recipientSearchBehavior { get; private set; }

		public Settings(
			final EnvelopeSettings envelope,
			final List<Recipient.EmailSettings> defaultEmailLocalizations,
			final List<Localization.ChatterSettings> defaultChatterLocalizations,
			final Integer calloutTimeout,
			final List<String> entityResolvers,
			final List<String> documentResolvers,
			final List<String> recipientResolvers,
			final SearchBehavior recipientSearchBehavior) {

			this.envelope = envelope;
			this.defaultEmailLocalizations = defaultEmailLocalizations;
			this.defaultChatterLocalizations = defaultChatterLocalizations;
			this.calloutTimeout = calloutTimeout;
			this.entityResolvers = entityResolvers;
			this.documentResolvers = documentResolvers;
			this.recipientResolvers = recipientResolvers;
			this.recipientSearchBehavior = recipientSearchBehavior;
		}
	}

	@TestVisible
	private static SearchBehavior stringToSearchBehavior(final String s) {
		SearchBehavior result = SearchBehavior.DiscreteMatchBeginning;
		if (String.isNotBlank(s)) {
			String s2 = s.trim();
			if (s2 == 'CompoundMatchBeginning') {
				result = SearchBehavior.CompoundMatchBeginning;
			} else if (s2 == 'CompoundMatchExact') {
				result = SearchBehavior.CompoundMatchExact;
			} else if (s2 == 'CompoundMatchAny') {
				result = SearchBehavior.CompoundMatchAny;
			} else if (s2 == 'DiscreteMatchAny') {
				result = SearchBehavior.DiscreteMatchAny;
			} else if (s2 == 'DiscreteMatchExact') {
				result = SearchBehavior.DiscreteMatchExact;
			} else {
				result = SearchBehavior.DiscreteMatchBeginning;
			}
		}
		return result;
	}

	public static Settings getSettings() {
		Permissions.verifyIsDocuSignAdministrator();

		AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
		return new Settings(
			EnvelopeSettings.getInstance(),
			Localization.getDefaultEmailSettings(),
			Localization.getChatterSettings(),
			Integer.valueOf(accountSettings.CalloutTimeout__c),
			String.isBlank(accountSettings.EntityResolvers__c) ? new List<String>() : accountSettings.EntityResolvers__c.split(','),
			String.isBlank(accountSettings.DocumentResolvers__c) ? new List<String>() : accountSettings.DocumentResolvers__c.split(','),
			String.isBlank(accountSettings.RecipientResolvers__c) ? new List<String>() : accountSettings.RecipientResolvers__c.split(','),
			stringToSearchBehavior(accountSettings.RecipientSearchBehavior__c));
	}

	public static Settings saveSettings(final Settings settings) {
		Permissions.verifyIsDocuSignAdministrator();

		if (settings == null) throw new DocuSignException(Label.UndefinedArgument);

		AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
		accountSettings.CalloutTimeout__c = settings.calloutTimeout;
		accountSettings.EntityResolvers__c = Collection.mkString(settings.entityResolvers, ',');
		accountSettings.DocumentResolvers__c = Collection.mkString(settings.documentResolvers, ',');
		accountSettings.RecipientResolvers__c = Collection.mkString(settings.recipientResolvers, ',');
		accountSettings.RecipientSearchBehavior__c = settings.recipientSearchBehavior == null
			? SearchBehavior.DiscreteMatchBeginning.name() : settings.recipientSearchBehavior.name();
		upsert accountSettings;

		return new Settings(
			EnvelopeSettings.save(settings.envelope),
			Localization.getDefaultEmailSettings(),
			Localization.getChatterSettings(),
			Integer.valueOf(accountSettings.CalloutTimeout__c),
			String.isBlank(accountSettings.EntityResolvers__c) ? new List<String>() : accountSettings.EntityResolvers__c.split(','),
			String.isBlank(accountSettings.DocumentResolvers__c) ? new List<String>() : accountSettings.DocumentResolvers__c.split(','),
			String.isBlank(accountSettings.RecipientResolvers__c) ? new List<String>() : accountSettings.RecipientResolvers__c.split(','),
			stringToSearchBehavior(accountSettings.RecipientSearchBehavior__c));
	}

	@TestVisible
	private static List<Account.User> addUsers2(final List<Account.User> users) {
		if (Collection.isEmpty(users)) return users;

		// Update the username and password for the users
		List<Account.User> result = new List<Account.User>();
		Boolean useSOBO = AccountSettings__c.getOrgDefaults().UseSendOnBehalfOf__c;
		Map<Id, Credentials.UserCredentials> creds = new Map<Id, Credentials.UserCredentials>();
		for (Account.User u : users) {
			if (u.hasError && u.error.code == APIErrorCode.USER_ALREADY_EXISTS_IN_ACCOUNT) {
				// Ignore errors when user is already an account member. Something got DFS and DS out of sync.
				result.add(u.withError(null));
			} else if (u.hasError) {
				result.add(u);
			} else {
				creds.put(u.sourceId, new Credentials.UserCredentials(
					String.valueOf(u.id),
					useSOBO && String.isNotBlank(u.apiPassword) ? u.apiPassword : null,
					u.canManageAccount));
				result.add(u);
			}
		}

		Credentials.addUsers(creds);

		return result;
	}

	public static List<Account.User> addUsers(final List<Account.User> users) {
		Permissions.verifyIsDocuSignAdministrator();

		return addUsers2(AccountAPI.getInstance().addUsers(users));
	}

	@TestVisible
	private static Set<Id> getUserIdsToRemove(final List<Account.User> users) {
		Set<Id> result = new Set<Id>();
		if (users != null) {
			String currentDSUsername = UserSettings__c.getInstance().Username__c;
			Id currentUserId = UserInfo.getUserId();
			for (Account.User u : users) {
				if (u.sourceId == currentUserId
					|| (String.isNotBlank(currentDSUsername)
					&& (String.valueOf(u.id) == currentDSUsername
					|| u.username == currentDSUsername))) {

					throw new DocuSignException(Label.CannotRemoveSelf);
				}
				result.add(u.sourceId);
			}
		}
		return result;
	}

	public List<Account.User> removeUsers(final List<Account.User> users, final Boolean closeMembership) {
		Permissions.verifyIsDocuSignAdministrator();

		Set<Id> userIds = getUserIdsToRemove(users);

		List<Account.User> result = new List<Account.User>();
		if (closeMembership) {
			for (Account.User u : AccountAPI.getInstance().removeUsers(users)) {
				if (u.hasError && u.error.code == APIErrorCode.UNKNOWN_USER) {
					// Ignore errors where user is unknown to DS. The user was already removed from the account.
					result.add(u.withError(null));
				} else {
					result.add(u);
				}
			}
		}

		Credentials.clear(userIds);

		return result;
	}
}
