/**
 * Primary interface point for DocuSign for Salesforce account management.
 */
global with sharing class AccountService {

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
		public LoginStatus status { get; private set; }
		/**
		 * Valid DocuSign accounts from which to choose. Populated if the <code>status</code> is
		 * <code>SelectAccount</code>.
		 */
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

		if (String.isBlank(username) || String.isBlank(password)) throw new UnauthorizedException(Label.InvalidUsernameOrPassword);

		// 2) Get valid DocuSign accounts.
		List<Account.Membership> memberships;
		try {
			memberships = AccountAPI.getInstance(env, username, password).getValidAccounts();
		} catch (UnauthorizedException ex) {
			LOG.exception(ex, 'Failed to read available accounts');
			throw new UnauthorizedException(Label.InvalidUsernameOrPassword);
		}

		if (Collection.isEmpty(memberships)) {
			LOG.warn('No valid ' + target.name() + ' accounts for user ' + username);
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
		if (Collection.size(options) == 1) {
			Environment ae = Environment.fromUrl(validMembership.baseUrl);
			LOG.debug('AccountService.login: account base URL = ' + validMembership.baseUrl.toExternalForm()
				+ ', parsed base = ' + ae.baseUrl.toExternalForm()
				+ ', environment = ' + ae.environment.name().toLowerCase());
			Credentials.save(ae, validMembership.accountId, validMembership.accountNumber, username,
				String.valueOf(validMembership.userId), validMembership.apiPassword, true);
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
	 * Represents a country option.
 	 */
	public class Country {
		/**
		 * The ISO-2 country code.
		 */
		@AuraEnabled
		public String code { get; private set; }
		/**
		 * The country label.
		 */
		@AuraEnabled
		public String label { get; private set; }

		private Country(final String code, final String label) {
			this.code = code;
			this.label = label;
		}
	}

	/**
	 * Marketing opt-in settings for trial account sign-up.
	 */
	public class Marketing {
		/**
		 * Whether to display the marketing opt-in option during trial account sign-up.
		 */
		@AuraEnabled
		public Boolean showOptIn { get; private set; }
		/**
		 * The default marketing opt-in value.
		 */
		@AuraEnabled
		public Boolean defaultOptIn { get; private set; }

		private Marketing(final Boolean showOptIn, final Boolean defaultOptIn) {
			this.showOptIn = showOptIn;
			this.defaultOptIn = defaultOptIn;
		}
	}

	/**
	 * Trial account settings for the current user.
	 * <p>
	 * <em>Marketing opt-in settings must be honored based on the user-selected country to comply with GDPR and other
	 * local regulations.</em>
	 */
	public class TrialAccount {
		/**
		 * The prepared trial account with default options set based on the current Salesforce user record.
		 * <p>
		 * <em>The user must be able to select their country before provisioning the trial account. Based on their
		 * selection, appropriate opt-in settings must be displayed. This selection must be based on the
		 * <code>account.user.countryCode</code>.</em>
		 */
		@AuraEnabled
		public Account.Trial account { get; private set; }
		/**
		 * List of user-selectable countries.
		 */
		@AuraEnabled
		public List<Country> countries { get; private set; }
		/**
		 * Map of ISO-2 country codes to marketing opt-in settings. If a country code is not explicitly contained in
		 * this map, use key <code>DEFAULT</code>.
		 */
		@AuraEnabled
		public Map<String, Marketing> marketing { get; private set; }

		@TestVisible
		private TrialAccount(final Account.Trial account, final List<Country> countries,
			final Map<String, Marketing> marketing) {

			this.account = account;
			this.countries = countries;
			this.marketing = marketing;
		}
	}

	@TestVisible
	private static List<Country> getCountries() {
		return new List<Country> {
			new Country('AF', Label.Afghanistan),
			new Country('AX', Label.AlandIslands),
			new Country('AL', Label.Albania),
			new Country('DZ', Label.Algeria),
			new Country('AS', Label.AmericanSamoa),
			new Country('AD', Label.Andorra),
			new Country('AO', Label.Angola),
			new Country('AI', Label.Anguilla),
			new Country('AQ', Label.Antarctica),
			new Country('AG', Label.AntiguaAndBarbuda),
			new Country('AR', Label.Argentina),
			new Country('AM', Label.Armenia),
			new Country('AW', Label.Aruba),
			new Country('AU', Label.Australia),
			new Country('AT', Label.Austria),
			new Country('AZ', Label.Azerbaijan),
			new Country('BS', Label.Bahamas),
			new Country('BH', Label.Bahrain),
			new Country('BD', Label.Bangladesh),
			new Country('BB', Label.Barbados),
			new Country('BY', Label.Belarus),
			new Country('BE', Label.Belgium),
			new Country('BZ', Label.Belize),
			new Country('BJ', Label.Benin),
			new Country('BM', Label.Bermuda),
			new Country('BT', Label.Bhutan),
			new Country('BO', Label.Bolivia),
			new Country('BA', Label.BosniaAndHerzegovina),
			new Country('BW', Label.Botswana),
			new Country('BV', Label.BouvetIsland),
			new Country('BR', Label.Brazil),
			new Country('IO', Label.BritishIndiaOceanTerritory),
			new Country('VG', Label.BritishVirginIslands),
			new Country('BN', Label.Brunei),
			new Country('BG', Label.Bulgaria),
			new Country('BF', Label.BurkinaFaso),
			new Country('BI', Label.Burundi),
			new Country('KH', Label.Cambodia),
			new Country('CM', Label.Cameroon),
			new Country('CA', Label.Canada),
			new Country('CV', Label.CapeVerde),
			new Country('BQ', Label.CaribbeanNetherlands),
			new Country('KY', Label.CaymanIslands),
			new Country('CF', Label.CentralAfricanRepublic),
			new Country('TD', Label.Chad),
			new Country('CL', Label.Chile),
			new Country('CN', Label.China),
			new Country('CX', Label.ChristmasIsland),
			new Country('CC', Label.CocosKeelingIslands),
			new Country('CO', Label.Colombia),
			new Country('KM', Label.Comoros),
			new Country('CG', Label.CongoBrazzaville),
			new Country('CD', Label.CongoKinshasa),
			new Country('CK', Label.CookIslands),
			new Country('CR', Label.CostaRica),
			new Country('HR', Label.Croatia),
			new Country('CU', Label.Cuba),
			new Country('CW', Label.Curacao),
			new Country('CY', Label.Cyprus),
			new Country('CZ', Label.CzechRepublic),
			new Country('DK', Label.Denmark),
			new Country('DJ', Label.Djibouti),
			new Country('DM', Label.Dominica),
			new Country('DO', Label.DominicanRepublic),
			new Country('EC', Label.Ecuador),
			new Country('EG', Label.Egypt),
			new Country('SV', Label.ElSalvador),
			new Country('GQ', Label.EquatorialGuinea),
			new Country('ER', Label.Eritrea),
			new Country('EE', Label.Estonia),
			new Country('ET', Label.Ethiopia),
			new Country('FK', Label.FalklandIslands),
			new Country('FO', Label.FaroeIslands),
			new Country('FJ', Label.Fiji),
			new Country('FI', Label.Finland),
			new Country('FR', Label.France),
			new Country('GF', Label.FrenchGuiana),
			new Country('PF', Label.FrenchPolynesia),
			new Country('TF', Label.FrenchSouthernTerritories),
			new Country('GA', Label.Gabon),
			new Country('GM', Label.Gambia),
			new Country('GE', Label.Georgia),
			new Country('DE', Label.Germany),
			new Country('GH', Label.Ghana),
			new Country('GI', Label.Gibraltar),
			new Country('GR', Label.Greece),
			new Country('GL', Label.Greenland),
			new Country('GD', Label.Grenada),
			new Country('GP', Label.Guadeloupe),
			new Country('GU', Label.Guam),
			new Country('GT', Label.Guatemala),
			new Country('GG', Label.Guernsey),
			new Country('GN', Label.Guinea),
			new Country('GW', Label.GuineaBissau),
			new Country('GY', Label.Guyana),
			new Country('HT', Label.Haiti),
			new Country('HM', Label.HeardandMcDonaldIslands),
			new Country('HN', Label.Honduras),
			new Country('HK', Label.HongKong),
			new Country('HU', Label.Hungary),
			new Country('IS', Label.Iceland),
			new Country('IN', Label.India),
			new Country('ID', Label.Indonesia),
			new Country('IR', Label.Iran),
			new Country('IQ', Label.Iraq),
			new Country('IE', Label.Ireland),
			new Country('IM', Label.IsleOfMan),
			new Country('IL', Label.Israel),
			new Country('IT', Label.Italy),
			new Country('CI', Label.IvoryCoast),
			new Country('JM', Label.Jamaica),
			new Country('JP', Label.Japan),
			new Country('JE', Label.Jersey),
			new Country('JO', Label.Jordan),
			new Country('KZ', Label.Kazakhstan),
			new Country('KE', Label.Kenya),
			new Country('KI', Label.Kiribati),
			new Country('KW', Label.Kuwait),
			new Country('KG', Label.Kyrgyzstan),
			new Country('LA', Label.Laos),
			new Country('LV', Label.Latvia),
			new Country('LB', Label.Lebanon),
			new Country('LS', Label.Lesotho),
			new Country('LR', Label.Liberia),
			new Country('LY', Label.Libya),
			new Country('LI', Label.Liechtenstein),
			new Country('LT', Label.Lithuania),
			new Country('LU', Label.Luxembourg),
			new Country('MO', Label.Macau),
			new Country('MK', Label.Macedonia),
			new Country('MG', Label.Madagascar),
			new Country('MW', Label.Malawi),
			new Country('MY', Label.Malaysia),
			new Country('MV', Label.Maldives),
			new Country('ML', Label.Mali),
			new Country('MT', Label.Malta),
			new Country('MH', Label.MarshallIslands),
			new Country('MQ', Label.Martinique),
			new Country('MR', Label.Mauritania),
			new Country('MU', Label.Mauritius),
			new Country('YT', Label.Mayotte),
			new Country('MX', Label.Mexico),
			new Country('FM', Label.Micronesia),
			new Country('MD', Label.Moldova),
			new Country('MC', Label.Monaco),
			new Country('MN', Label.Mongolia),
			new Country('ME', Label.Montenegro),
			new Country('MS', Label.Montserrat),
			new Country('MA', Label.Morocco),
			new Country('MZ', Label.Mozambique),
			new Country('MM', Label.Myanmar),
			new Country('NA', Label.Namibia),
			new Country('NR', Label.Nauru),
			new Country('NP', Label.Nepal),
			new Country('NL', Label.Netherlands),
			new Country('NC', Label.NewCaledonia),
			new Country('NZ', Label.NewZealand),
			new Country('NI', Label.Nicaragua),
			new Country('NE', Label.Niger),
			new Country('NG', Label.Nigeria),
			new Country('NU', Label.Niue),
			new Country('NF', Label.NorfolkIsland),
			new Country('KP', Label.NorthKorea),
			new Country('MP', Label.NorthernMarianaIslands),
			new Country('NO', Label.Norway),
			new Country('OM', Label.Oman),
			new Country('PK', Label.Pakistan),
			new Country('PW', Label.Palau),
			new Country('PS', Label.PalestinianTerritory),
			new Country('PA', Label.Panama),
			new Country('PG', Label.PapuaNewGuinea),
			new Country('PY', Label.Paraguay),
			new Country('PE', Label.Peru),
			new Country('PH', Label.Philippines),
			new Country('PN', Label.Pitcairn),
			new Country('PL', Label.Poland),
			new Country('PT', Label.Portugal),
			new Country('PR', Label.PuertoRico),
			new Country('QA', Label.Qatar),
			new Country('RE', Label.Reunion),
			new Country('RO', Label.Romania),
			new Country('RU', Label.RussianFederation),
			new Country('RW', Label.Rwanda),
			new Country('BL', Label.SaintBarthelemy),
			new Country('SH', Label.SaintHelena),
			new Country('KN', Label.SaintKittsAndNevis),
			new Country('LC', Label.SaintLucia),
			new Country('MF', Label.SaintMartinFrance),
			new Country('PM', Label.SaintPierreAndMiquelon),
			new Country('VC', Label.SaintVincentAndTheGrenadines),
			new Country('WS', Label.Samoa),
			new Country('SM', Label.SanMarino),
			new Country('ST', Label.SaoTomeAndPrincipe),
			new Country('SA', Label.SaudiArabia),
			new Country('SN', Label.Senegal),
			new Country('RS', Label.Serbia),
			new Country('SC', Label.Seychelles),
			new Country('SL', Label.SierraLeone),
			new Country('SG', Label.Singapore),
			new Country('SX', Label.SintMaarten),
			new Country('SK', Label.Slovakia),
			new Country('SI', Label.Slovenia),
			new Country('SB', Label.SolomonIslands),
			new Country('SO', Label.Somalia),
			new Country('ZA', Label.SouthAfrica),
			new Country('GS', Label.SouthGeorgiaAndTheSouthSandwichIslands),
			new Country('KR', Label.SouthKorea),
			new Country('SS', Label.SouthSudan),
			new Country('ES', Label.Spain),
			new Country('LK', Label.SriLanka),
			new Country('SD', Label.Sudan),
			new Country('SR', Label.Suriname),
			new Country('SJ', Label.SvalbardAndJanMayen),
			new Country('SZ', Label.Swaziland),
			new Country('SE', Label.Sweden),
			new Country('CH', Label.Switzerland),
			new Country('SY', Label.Syria),
			new Country('TW', Label.Taiwan),
			new Country('TJ', Label.Tajikistan),
			new Country('TZ', Label.Tanzania),
			new Country('TH', Label.Thailand),
			new Country('TL', Label.TimorLeste),
			new Country('TG', Label.Togo),
			new Country('TK', Label.Tokelau),
			new Country('TO', Label.Tonga),
			new Country('TT', Label.TrinidadAndTobago),
			new Country('TN', Label.Tunisia),
			new Country('TR', Label.Turkey),
			new Country('TM', Label.Turkmenistan),
			new Country('TC', Label.TurksAndCaicoIslands),
			new Country('TV', Label.Tuvalu),
			new Country('VI', Label.USVirginIslands),
			new Country('UG', Label.Uganda),
			new Country('UA', Label.Ukraine),
			new Country('AE', Label.UnitedArabEmirates),
			new Country('GB', Label.UnitedKingdom),
			new Country('US', Label.UnitedStates),
			new Country('UM', Label.UnitedStatesMinorOutlyingIslands),
			new Country('UY', Label.Uruguay),
			new Country('UZ', Label.Uzbekistan),
			new Country('VU', Label.Vanuatu),
			new Country('VA', Label.Vatican),
			new Country('VE', Label.Venezuela),
			new Country('VN', Label.Vietnam),
			new Country('WF', Label.WallisAndFutuna),
			new Country('EH', Label.WesternSahara),
			new Country('YE', Label.Yemen),
			new Country('ZM', Label.Zambia),
			new Country('ZW', Label.Zimbabwe)
		};
	}

	@TestVisible
	private static Map<String, Marketing> getMarketing() {
		return new Map<String, Marketing> {
			'DEFAULT' => new Marketing(true, true),
			'US' => new Marketing(false, true),
			'DE' => new Marketing(true, false),
			'AU' => new Marketing(true, false),
			'NZ' => new Marketing(true, false),
			'JP' => new Marketing(true, false),
			'CN' => new Marketing(true, false),
			'TW' => new Marketing(true, false),
			'VN' => new Marketing(true, false),
			'AT' => new Marketing(true, false),
			'BE' => new Marketing(true, false),
			'BG' => new Marketing(true, false),
			'HR' => new Marketing(true, false),
			'CY' => new Marketing(true, false),
			'CZ' => new Marketing(true, false),
			'DK' => new Marketing(true, false),
			'EE' => new Marketing(true, false),
			'FI' => new Marketing(true, false),
			'FR' => new Marketing(true, false),
			'GR' => new Marketing(true, false),
			'HU' => new Marketing(true, false),
			'IE' => new Marketing(true, false),
			'IT' => new Marketing(true, false),
			'LV' => new Marketing(true, false),
			'LT' => new Marketing(true, false),
			'LU' => new Marketing(true, false),
			'MT' => new Marketing(true, false),
			'NL' => new Marketing(true, false),
			'PL' => new Marketing(true, false),
			'PT' => new Marketing(true, false),
			'RO' => new Marketing(true, false),
			'SK' => new Marketing(true, false),
			'SI' => new Marketing(true, false),
			'ES' => new Marketing(true, false),
			'SE' => new Marketing(true, false),
			'GB' => new Marketing(true, false)
		};
	}

	/**
	 * Prepares a DocuSign for Salesforce trial account based on the current Salesforce user. This account is not
	 * actually created at DocuSign. A subsequent call must be made to AccountService.createTrial to do so.
	 * <p>
	 * <em>This must be called prior to creating the trial account to provide the user the option to select their
	 * country and display appropriate marketing consent and opt-in options.</em>
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param email The email address for the desired trial account.
	 *
	 * @return A DocuSign trial account that may be used in subsequent calls.
	 * @see AccountService.createTrial for trial account creation details.
	 */
	public static TrialAccount prepareTrial(final String email) {
		Permissions.verifyIsDocuSignAdministrator();

		User u = DB.queryUser(UserInfo.getUserId());
		Map<String, Marketing> marketing = getMarketing();
		return new TrialAccount(new Account.Trial(
			UserInfo.getOrganizationName(),
			new Account.TrialUser(
				email,
				UserInfo.getFirstName(),
				UserInfo.getLastName(),
				u.Country,
				marketing.containsKey(u.Country) && marketing.get(u.Country).defaultOptIn),
			new Account.Address(
				u.Street,
				null,
				u.City,
				u.State,
				u.PostalCode,
				u.Country,
				String.isBlank(u.Phone) ? u.MobilePhone : u.Phone)),
			getCountries(),
			marketing);
	}

	/**
	 * Creates a DocuSign for Salesforce trial account. This account may be prepared via AccountService.prepareTrial.
	 * <p>
	 * Trial accounts are validated to ensure:
	 * <ul>
	 *     <li>The trial account is non-null</li>
	 *     <li>The trial email is a valid email address</li>
	 *     <li>The trial user's name is not blank</li>
	 *     <li>The trial user's country code is not blank</li>
	 *     <li>The trial user's marketing opt-in preference is not <code>null</code></li>
	 *     <li>The trial company is not blank</li>
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
			String.valueOf(result.userId), result.apiPassword, true);
		return result.scrub(); // Don't return sensitive info.
	}

	@TestVisible
	private static ValidationResult validate(final Account.Trial trial) {
		ValidationResult result = new ValidationResult();
		if (trial == null) {
			result.add(Label.UndefinedArgument);
		} else {
			if (trial.user == null) {
				result.add(Label.EmailRequired);
				result.add(Label.NameRequired);
				result.add(Label.UserCountryRequired);
				result.add(Label.MarketingPreferenceRequired);
			} else {
				if (String.isBlank(trial.user.email)) {
					result.add(Label.EmailRequired);
				} else if (!StringUtils.isValidEmail(trial.user.email)) {
					result.add(Label.InvalidEmail);
				}
				if (String.isBlank(trial.user.name)) {
					result.add(Label.NameRequired);
				}
				if (String.isBlank(trial.user.countryCode)) {
					result.add(Label.UserCountryRequired);
				}
				if (trial.user.marketingOptIn == null) {
					result.add(Label.MarketingPreferenceRequired);
				}
			}
			if (String.isBlank(trial.company)) {
				result.add(Label.CompanyRequired);
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
	global static Url getDocuSignUrl() {
		if (!Permissions.isDocuSignUser()
			|| String.isBlank(UserSettings__c.getInstance(UserInfo.getUserId()).Username__c)) {

			throw new UnauthorizedException(Label.UnauthorizedPageAccess);
		}

		return AccountAPI.getInstance().getConsoleViewUrl();
	}

	/**
	 * Retrieves DocuSign for Salesforce account settings.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return The account settings.
	 */
	public static AccountSettings getSettings() {
		Permissions.verifyIsDocuSignAdministrator();

		return AccountSettings.getInstance();
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
	public static AccountSettings saveSettings(final AccountSettings settings) {
		Permissions.verifyIsDocuSignAdministrator();

		if (settings == null) throw new DocuSignException(Label.UndefinedArgument);

		return AccountSettings.save(settings);
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