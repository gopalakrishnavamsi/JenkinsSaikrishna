/**
 * Primary interface point for DocuSign for Salesforce account management.
 */
public with sharing class AccountService {

	private static final Database DB = new AccountService.Database();
	private static final LoggerService LOG = LoggerService.getInstance();
	private static Account currentAccount;

	private class Database {

		private Account.User convert(final User u) {
			if (u == null) return null;

			return new Account.User(
				u.Id,
				u.Username__c,
				u.Email,
				u.FirstName,
				u.LastName,
				u.CanManageAccount__c);
		}

		public User queryUser(final Id userId) {
			Permissions.verifyIsQueryable(User.getSObjectType(), new List<String> {
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

		public List<Account.User> queryUsers() {
			Permissions.verifyIsQueryable(User.getSObjectType(), new List<String> {
				'Id', 'Email', 'FirstName', 'LastName', 'Username__c', 'CanManageAccount__c'
			});

			List<Account.User> result = new List<Account.User>();
			for (User u : [
				SELECT Id, Email, FirstName, LastName, Username__c, CanManageAccount__c
				FROM User
				WHERE Username__c != NULL
			]) {
				result.add(convert(u));
			}
			return result;
		}
	}

	/**
	 * Login statuses:
	 * <ul>
	 *     <li><code>Success</code>: Login was successful and mapped to a single valid DocuSign account.</li>
	 *     <li><code>Failure</code>: Invalid DocuSign username or password.</li>
	 *     <li><code>SelectAccount</code>: Login was successful, but maps to mulitple valid DocuSign accounts.</li>
	 * </ul>
	 */
	public enum LoginStatus {
		Success, Failure, SelectAccount
	}

	/**
	 * Representation of the result of a login attempt.
	 */
	public class LoginResult {
		/**
		 * The status of the login attempt.
		 */
		@AuraEnabled
		public LoginStatus status { get; private set; }
		/**
		 * Valid DocuSign accounts from which to choose. Populated if the <code>status</code> is
		 * <code>SelectAccount</code>.
		 */
		@AuraEnabled
		public List<AccountOption> accountOptions { get; private set; }

		/**
		 * Constructs a login result.
		 *
		 * @param status The status of the login attempt.
		 * @param accountOptions Valid DocuSign accounts.
		 */
		private LoginResult(final LoginStatus status, final List<AccountOption> accountOptions) {
			this.status = status == null ? LoginStatus.Failure : status;
			this.accountOptions = accountOptions == null ? new List<AccountOption>() : accountOptions;
		}
	}

	/**
	 * Representation of a DocuSign account option when more than one is available after login.
	 */
	public class AccountOption {
		/**
		 * The DocuSign account number.
		 */
		@AuraEnabled
		public Long accountNumber { get; private set; }
		/**
		 * The string to display to the user for this option.
		 */
		@AuraEnabled
		public String display { get; private set; }

		/**
		 * Constructs a DocuSign account option.
		 *
		 * @param accountNumber The DocuSign account number.
		 * @param display The string to display to the user for this option.
		 */
		private AccountOption(final Long accountNumber, final String display) {
			this.accountNumber = accountNumber;
			this.display = display;
		}
	}

	/**
	 * Retrieves information for the current DocuSign account. This includes DocuSign trial status if the current
	 * account is a trial account.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return The current DocuSign account.
	 */
	public static Account getAccount() {
		Permissions.verifyIsDocuSignAdministrator();

		if (currentAccount == null) {
			Account a = AccountAPI.getInstance().getAccount();
			if (a.isTrial) {
				Account.TrialStatus ts = getTrialStatus(a);
				if (ts.isExpired) {
					throw new DocuSignException(ts.message);
				}
				currentAccount = a.withTrialStatus(ts);
			} else {
				currentAccount = a;
			}
		}
		return currentAccount;
	}

	@TestVisible
	private static Account.TrialStatus getTrialStatus(final Account account) {
		Boolean isExpired = false;
		String message = null;
		if (account != null && account.isTrial) {
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
		return new Account.TrialStatus(isExpired, message);
	}

	/**
	 * Attempts login to DocuSign with the supplied credentials. This must be invoked successfully prior to any other
	 * DocuSign for Salesforce actions. If the login is successful and maps to a single valid
	 * DocuSign account, DocuSign for Salesforce will be updated with these credentials. If the login is successful and
	 * maps to valid multiple accounts, those account options are returned to the caller to select the desired account
	 * in a subsequent call to this method.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param username The DocuSign username.
	 * @param password The DocuSign password.
	 * @param target The DocuSign environment. Valid values are <code>Stage</code>, <code>Demo</code>,
	 * <code>Production</code>, or <code>Other</code>. If <code>Other</code> is specified, a valid DocuSign base URL
	 * must be supplied via the <code>otherUrl</code> parameter.
	 * @param otherUrl The DocuSign base URL. This must be a valid DocuSign URL if <code>target</code> is
	 * <code>Other</code>
	 * @param selectedAccountNumber The DocuSign account number for the desired DocuSign for Salesforce account. Used
	 * to select an account when the user credentials map to multiple valid DocuSign accounts.
	 *
	 * @return The result of the login. This may succeed with a single account (no additional action is
	 * required to configure DocuSign for Salesforce), or with multiple accounts in which case this method should be
	 * called again with the same parameters and <code>selectedAccountNumber</code> defined with the desired account.
	 */
	public static LoginResult login(final String username, final String password, final Environment.Target target,
		final Url otherUrl, Long selectedAccountNumber) {

		Permissions.verifyIsDocuSignAdministrator();

		// 1) Parse valid DocuSign environment.
		Environment env = Environment.fromTarget(target, otherUrl);
		if (!Environment.isValid(env)) {
			LOG.error('Invalid DocuSign environment: ' + env.environment.name() + ' => ' + otherUrl);
			throw new DocuSignException(Label.InvalidEnvironment);
		}

		// 2) Get valid DocuSign accounts.
		List<Account.Membership> memberships;
		try {
			memberships = AccountAPI.getInstance(env, username, password).getValidAccounts();
		} catch (UnauthorizedException ex) {
			LOG.exception(ex, 'Failed to read available accounts');
			throw new UnauthorizedException(Label.InvalidUsernameOrPassword);
		}

		if (Collection.isEmpty(memberships)) {
			throw new DocuSignException(Label.NoValidAccounts);
		}

		// 3) Filter valid accounts.
		List<AccountOption> options = new List<AccountOption>();
		Account.Membership validMembership;
		Boolean selectAccount = selectedAccountNumber == null || selectedAccountNumber <= 0L;
		for (Account.Membership a : memberships) {
			if (selectAccount || selectedAccountNumber == a.accountNumber) {
				options.add(new AccountOption(a.accountNumber, a.name + ' (' + a.accountNumber + ')'));
				validMembership = a;
			}
		}

		// 4) Save results if only one account is filtered, or return list for user selection.
		LoginStatus status = null;
		if (options.size() == 1) {
			Environment ae = Environment.fromUrl(validMembership.baseUrl);
			LOG.debug('AccountService.login: account base URL = ' + validMembership.baseUrl.toExternalForm()
				+ ', parsed base = ' + ae.baseUrl.toExternalForm()
				+ ', environment = ' + ae.environment.name().toLowerCase());
			Credentials.save(ae, validMembership.accountId, validMembership.accountNumber, username,
				String.valueOf(validMembership.userId), validMembership.apiPassword, true, true);
			status = LoginStatus.Success;
		} else { // more than 1 valid account, just return results
			status = LoginStatus.SelectAccount;
		}

		return new LoginResult(options.size() > 1 ? LoginStatus.SelectAccount : LoginStatus.Success, options);
	}

	private static AccountSettings__c completeSetup() {
		AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
		accountSettings.Features__c = null;
		update accountSettings;
		return accountSettings;
	}

	/**
	 * Connects DocuSign to Salesforce for document retrieval, merge field resolution, and status events.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param username The Salesforce username.
	 * @param password The Salesforce password.
	 *
	 * @return The connection test result from DocuSign.
	 */
	public static String connect(final String username, final String password) {
		Permissions.verifyIsDocuSignAdministrator();

		String result = AccountSoapAPI.getInstance().setConnectCredentials(username, password);
		completeSetup();
		return result;
	}

	/**
	 * Prepares a DocuSign for Salesforce trial account based on the current Salesforce user. This account is not
	 * actually created at DocuSign. A subsequent call must be made to AccountService.createTrial to do so.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param email The email address for the desired trial account.
	 *
	 * @return A DocuSign trial account that may be used in subsequent calls.
	 * @see AccountService.createTrial for trial account creation details.
	 */
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

	/**
	 * Creates a DocuSign for Salesforce trial account. This account may be prepared via AccountService.prepareTrial.
	 * <p>
	 * Trial accounts are validated to ensure:
	 * <ul>
	 *     <li>The trial account is non-null</li>
	 *     <li>The trial email is a valid email address</li>
	 *     <li>The trial user's name is not blank</li>
	 *     <li>The trial company is not blank</li>
	 *     <li>The trial user has agreed to DocuSign's terms and conditions.</li>
	 * </ul>
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param trial The trial account to create.
	 *
	 * @return Details about the newly-created trial account membership.
	 * @see AccountService.prepareTrial for details on how the trial account can be prepared.
	 */
	public static Account.Membership createTrial(final Account.Trial trial) {
		Permissions.verifyIsDocuSignAdministrator();

		ValidationResult vr = validate(trial);
		if (!vr.isValid) throw new ValidationException(Label.InvalidTrialAccount, vr);

		Account.Membership result = AccountAPI.getInstance(Environment.production).createTrialAccount(trial);
		Credentials.save(Environment.fromUrl(result.baseUrl), result.accountId, result.accountNumber, trial.user.email,
			String.valueOf(result.userId), result.apiPassword, true, true);
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

	/**
	 * Retrieves a URL that can be used to display the DocuSign console. This URL can only be used once.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set, and must be an active member of the
	 * DocuSign account.
	 *
	 * @return The DocuSign console URL.
	 */
	public static Url getDocuSignUrl() {
		if (!Permissions.isDocuSignUser()
			|| String.isBlank(UserSettings__c.getInstance(UserInfo.getUserId()).Username__c)) {

			throw new UnauthorizedException(Label.UnauthorizedPageAccess);
		}

		return AccountAPI.getInstance().getConsoleViewUrl();
	}

	/**
	 * DocuSign for Salesforce account-level settings.
	 */
	public class Settings {
		/**
		 * Envelope-related settings.
		 */
		public EnvelopeSettings envelope { get; private set; }
		/**
		 * Default recipient email localizations. Can be modified and saved at the account level.
		 */
		public List<Recipient.EmailSettings> defaultEmailLocalizations { get; private set; }
		/**
		 * Default Chatter event localizations. Can be modified and saved at the account level.
		 */
		public List<Localization.ChatterSettings> defaultChatterLocalizations { get; private set; }
		/**
		 * Apex callout timeout. The default is 90 seconds.
		 */
		public Integer calloutTimeout { get; private set; }
		/**
		 * Salesforce entity resolvers. May be extended to resolve Salesforce objects unknown to DocuSign for Salesforce.
		 */
		public List<String> entityResolvers { get; private set; }
		/**
		 * DocuSign envelope document resolvers. May be extended to resolve Salesforce document types unknown to
		 * DocuSign for Salesforce.
		 */
		public List<String> documentResolvers { get; private set; }
		/**
		 * DocuSign envelope recipient resolvers. May be extended to resolve Salesforce recipient types unknown to
		 * DocuSign for Salesforce.
		 */
		public List<String> recipientResolvers { get; private set; }
		/**
		 * How to perform recipient searches. The ideal method is depended upon the subscriber org (number of contacts,
		 * platform encryption). The default search behavior is <code>DiscreteMatchBeginning</code> which allows partial
		 * matches on the beginning of first and last names. This is an efficient option for most subscriber orgs
		 * and can support deterministic platform encryption of these fields.
		 *
		 * @see Recipient.SearchBehavior for more details on search options.
		 */
		public Recipient.SearchBehavior recipientSearchBehavior { get; private set; }

		/**
		 * Constructs account-level settings.
		 *
		 * @param envelope Envelope-related settings.
		 * @param defaultEmailLocalizations Default recipient email localizations.
		 * @param defaultChatterLocalizations Default Chatter status update localizations.
		 * @param calloutTimeout Apex callout timeout.
		 * @param entityResolvers Entity resolvers.
		 * @param documentResolvers Document resolvers.
		 * @param recipientResolvers Recipient resolvers.
		 * @param recipientSearchBehavior Recipient search behavior.
		 */
		public Settings(
			final EnvelopeSettings envelope,
			final List<Recipient.EmailSettings> defaultEmailLocalizations,
			final List<Localization.ChatterSettings> defaultChatterLocalizations,
			final Integer calloutTimeout,
			final List<String> entityResolvers,
			final List<String> documentResolvers,
			final List<String> recipientResolvers,
			final Recipient.SearchBehavior recipientSearchBehavior) {

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
	private static Recipient.SearchBehavior stringToSearchBehavior(final String s) {
		Recipient.SearchBehavior result = Recipient.SearchBehavior.DiscreteMatchBeginning;
		if (String.isNotBlank(s)) {
			String s2 = s.trim();
			if (s2 == 'CompoundMatchBeginning') {
				result = Recipient.SearchBehavior.CompoundMatchBeginning;
			} else if (s2 == 'CompoundMatchExact') {
				result = Recipient.SearchBehavior.CompoundMatchExact;
			} else if (s2 == 'CompoundMatchAny') {
				result = Recipient.SearchBehavior.CompoundMatchAny;
			} else if (s2 == 'DiscreteMatchAny') {
				result = Recipient.SearchBehavior.DiscreteMatchAny;
			} else if (s2 == 'DiscreteMatchExact') {
				result = Recipient.SearchBehavior.DiscreteMatchExact;
			} else {
				result = Recipient.SearchBehavior.DiscreteMatchBeginning;
			}
		}
		return result;
	}

	/**
	 * Retrieves DocuSign for Salesforce account settings.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return The account settings.
	 */
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

	/**
	 * Updates DocuSign for Salesforce account settings.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param settings The settings to update.
	 *
	 * @return The updated settings.
	 */
	public static Settings saveSettings(final Settings settings) {
		Permissions.verifyIsDocuSignAdministrator();

		if (settings == null) throw new DocuSignException(Label.UndefinedArgument);

		AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
		accountSettings.CalloutTimeout__c = settings.calloutTimeout;
		accountSettings.EntityResolvers__c = Collection.mkString(settings.entityResolvers, ',');
		accountSettings.DocumentResolvers__c = Collection.mkString(settings.documentResolvers, ',');
		accountSettings.RecipientResolvers__c = Collection.mkString(settings.recipientResolvers, ',');
		accountSettings.RecipientSearchBehavior__c = settings.recipientSearchBehavior == null
			? Recipient.SearchBehavior.DiscreteMatchBeginning.name() : settings.recipientSearchBehavior.name();
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

	/**
	 * Retrieves a list of DocuSign account members.
	 *
	 * @return The current DocuSign account members.
	 */
	public static List<Account.User> getUsers() {
		Permissions.verifyIsDocuSignAdministrator();

		return DB.queryUsers();
	}

	@TestVisible
	private static List<Account.User> addUsers2(final List<Account.User> users) {
		if (Collection.isEmpty(users)) return users;

		// Update the username and password for the users
		List<Account.User> result = new List<Account.User>();
		Boolean useSOBO = AccountSettings__c.getOrgDefaults().UseSendOnBehalfOf__c;
		Map<Id, Credentials.UserCredentials> creds = new Map<Id, Credentials.UserCredentials>();
		for (Account.User u : users) {
			// Ignore errors when user is already an account member. Something got DFS and DS out of sync.
			if (u.hasError && u.error.code != APIErrorCode.USER_ALREADY_EXISTS_IN_ACCOUNT) {
				LOG.warn('Error while adding user ' + u.email + ': ' + u.error);
				result.add(u);
			} else {
				creds.put(u.sourceId, new Credentials.UserCredentials(
					String.valueOf(u.id),
					useSOBO && String.isNotBlank(u.apiPassword) ? u.apiPassword : null,
					u.canManageAccount));
				result.add(u.withError(null));
			}
		}

		Credentials.addUsers(creds);

		return result;
	}

	/**
	 * Adds one or more users as members of the current DocuSign account.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param users A list of users to add.
	 *
	 * @return The users added. This may be partially successful with details in the returned <code>User.error</code>
	 * property.
	 * @see Account.User.error for details on any errors.
	 */
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

	/**
	 * Removes one or more users from the current DocuSign account.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param users A list of users to remove.
	 *
	 * @return The users removed. This may be partially successful with details in the returned <code>User.error</code>
	 * property.
	 * @see Account.User.error for details on any errors.
	 */
	public static List<Account.User> removeUsers(final List<Account.User> users, final Boolean closeMembership) {
		Permissions.verifyIsDocuSignAdministrator();

		Set<Id> userIds = getUserIdsToRemove(users);

		List<Account.User> result = new List<Account.User>();
		if (closeMembership) {
			for (Account.User u : AccountAPI.getInstance().removeUsers(users)) {
				// Ignore errors where user is unknown to DS. The user was already removed from the account.
				if (u.hasError && u.error.code != APIErrorCode.UNKNOWN_USER) {
					if (u.sourceId != null) userIds.remove(u.sourceId);
					result.add(u);
				} else {
					result.add(u.withError(null));
				}
			}
		}

		Credentials.clear(userIds);

		return result;
	}

	/**
	 * Runs all post-install scripts again if needed to solve a problem. This is a safe operation as it will not
	 * overwrite current settings if they exist.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return The results of the post-install script execution.
	 */
	public static PostInstallResults executePostInstallScripts() {
		Permissions.verifyIsDocuSignAdministrator();

		return new PostInstall(true).execute(
			UserInfo.getOrganizationId(),
			UserInfo.getUserId(),
			null,
			false,
			false);
	}

	/**
	 * Clears all DocuSign account credentials and optionally user credentials as well. This is an irreversible action,
	 * so invoke only after confirming with the administrator.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param resetUsers Whether or not to also clear user credentials.
	 */
	public static void resetCredentials(final Boolean resetUsers) {
		Permissions.verifyIsDocuSignAdministrator();

		Credentials.clear(resetUsers);
	}
}
