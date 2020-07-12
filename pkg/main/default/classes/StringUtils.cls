/*
This class contains utility methods for dealing with strings to/from string-value-only APIs, and handles magic values
relied upon by the client. In an ideal world, this wouldn't be necessary. However, there is still much spaghetti to
untangle upstream, and the v2 DocuSign APIs serialize all primitive types as strings.
 */
/**
 * String utilities.
 */
public class StringUtils {

	private static final Pattern PATTERN_EMAIL = Pattern.compile(
		'^(?:[a-z0-9!#$%&\'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&\'*+/=?^_`{|}~-]+)*|"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)])$');
	private static final Pattern PATTERN_ID = Pattern.compile('^[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}$');
	private static final String ENCODING = 'UTF-8';

	/**
	 * Url-encodes a string with UTF-8 encoding.
	 *
	 * @param s The input string.
	 *
	 * @return The Url-encoded string or an empty string if the input is blank.
	 */
	public static String encode(final String s) {
		if (String.isBlank(s)) return '';
		return EncodingUtil.urlEncode(s, ENCODING);
	}

	/**
	 * Url-decodes a string with UTF-8 encoding.
	 *
	 * @param s The input string.
	 *
	 * @return The Url-decoded string or an empty string if the input is blank.
	 */
	public static String decode(final String s) {
		if (String.isBlank(s)) return '';
		return EncodingUtil.urlDecode(s, ENCODING);
	}

	/**
	 * Parses a string as a boolean value. Input strings of 'true' or '1' will evaluate to <code>true</code>; anything
	 * else evaluates to <code>false</code>.
	 *
	 * @param s The input string.
	 *
	 * @return The boolean representation of the input string.
	 */
	public static Boolean parseBoolean(final String s) {
		return String.isNotBlank(s) && (s == '1' || Boolean.valueOf(s));
	}

	/**
	 * Parses a string as a boolean value. Input strings of 'true' or '1' will evaluate to <code>true</code>, any
	 * other non-blank value evaluates to <code>false</code>, and blank inputs evaluate to <code>defaultValue</code>.
	 *
	 * @param s The input string.
	 * @param defaultValue The value to use if the input string is blank,
	 *
	 * @return The boolean representation of the input string, or the default value if the input string is blank.
	 */
	public static Boolean parseBoolean(final String s, final Boolean defaultValue) {
		if (String.isBlank(s)) return defaultValue; else return s == '1' || Boolean.valueOf(s);
	}

	/**
	 * Parses a string as a decimal value.
	 *
	 * @param s The input string.
	 *
	 * @return The decimal representation of the input string, or <code>null</code> if the input string is blank or
	 * otherwise invalid.
	 */
	public static Decimal parseDecimal(final String s) {
		try {
			return String.isBlank(s) ? null : Decimal.valueOf(s);
		} catch (Exception ex) {
			return null;
		}
	}

	/**
	 * Parses a string as an integer value.
	 *
	 * @param s The input string.
	 *
	 * @return The integer representation of the input string, or <code>null</code> if the input string is blank or otherwise invalid.
	 */
	public static Integer parseInteger(final String s) {
		try {
			return String.isBlank(s) ? null : Integer.valueOf(s);
		} catch (Exception ex) {
			return null;
		}
	}

	/**
	 * Parses a string as an integer value with a default value to use if the string cannot be parsed.
	 *
	 * @param s The input string.
	 * @param defaultValue The value to return if the input string cannot be parsed as a valid integer.
	 *
	 * @return The integer representation of the input string, or <code>defaultValue</code> if the input string is blank or otherwise invalid.
	 */
	public static Integer parseInteger(final String s, final Integer defaultValue) {
		try {
			return String.isBlank(s) ? defaultValue : Integer.valueOf(s);
		} catch (Exception ex) {
			return defaultValue;
		}
	}

	/**
	 * Parses an ISO 8601 formatted string as <code>Datetime</code>.
	 *
	 * @param s The input string.
	 *
	 * @return The <code>Datetime</code> representation for a valid input string, <code>null</code> otherwise.
	 */
	public static Datetime parseDatetime(final String s) {
		return String.isBlank(s) ? null : (Datetime)JSON.deserialize('"' + s + '"', Datetime.class);
	}

	/**
	 * Parses an ISO 8601 formatted string as <code>Date</code>.
	 *
	 * @param s The input string.
	 *
	 * @return The <code>Date</code> representation for a valid input string, <code>null</code> otherwise.
	 */
	public static Date parseDate(final String s) {
		Datetime dt = parseDatetime(s);
		return dt == null ? null : dt.dateGmt();
	}

	/**
	 * Merges first and last names into one name, allowing for one or the other to be blank and trimming the output.
	 *
	 * @param firstName The first name.
	 * @param lastName The last name.
	 *
	 * @return The combined name.
	 */
	public static String mkName(final String firstName, final String lastName) {
		String name = '';
		if (String.isNotBlank(firstName)) name += firstName.trim();
		if (String.isNotBlank(lastName)) name += ' ' + lastName.trim();
		return name.trim();
	}

	/**
	 * Tests whether an input string is a valid email address.
	 *
	 * @param s The input string.
	 *
	 * @return <code>true</code> if the input string is a valid email address, <code>false</code> otherwise.
	 */
	public static Boolean isValidEmail(final String s) {
		return String.isNotBlank(s) && PATTERN_EMAIL.matcher(s.trim().toLowerCase()).matches();
	}

	/**
	 * Tests whether an input string is a valid Salesforce ID.
	 *
	 * @param s The input string.
	 *
	 * @return <code>true</code> if the input string is a valid Salesforce ID, <code>false</code> otherwise.
	 */
	public static Boolean isValidId(final String s) {
		return String.isNotBlank(s) && PATTERN_ID.matcher(s.trim().toLowerCase()).matches();
	}

	/**
	 * Replaces user tags '[FirstName]', '[LastName]', or '[Email]' with the current user's corresponding values.
	 *
	 * @param s The input string.
	 *
	 * @return The string with replaced user tags, if any.
	 */
	public static String replaceUserTags(final String s) {
		if (String.isEmpty(s)) {
			return s;
		} else {
			return s
				.replace('[FirstName]', ((UserInfo.getFirstName() == null) ? '' : UserInfo.getFirstName()))
				.replace('[LastName]', ((UserInfo.getLastName() == null) ? '' : UserInfo.getLastName()))
				.replace('[Email]', ((UserInfo.getUserEmail() == null) ? '' : UserInfo.getUserEmail()));
		}
	}

	/**
	 * Replaces note tags: '_COMMA_' with ',', '_SEMI_' with ';', '_TILDE_' with '~', and '\\n' with '\n'.
	 *
	 * @param s The input string.
	 *
	 * @return The string with replaced note tags, if any.
	 */
	public static String replaceNoteTags(final String s) {
		if (String.isBlank(s)) return null;

		return s.replace('_COMMA_', ',')
			.replace('_SEMI_', ';')
			.replace('_TILDE_', '~')
			.replace('\\n', '\n');
	}

	/**
	 * Standard ISO 8601 date and time formatting in GMT time zone.
	 *
	 * @param dt The date and time to format.
	 *
	 * @return The formatted date and time.
	 */
	public static String formatDatetime(final Datetime dt) {
		return dt == null ? null : dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
	}

	/**
	 * Hashes a string using SHA256 and returns it in hexadecimal form.
	 *
	 * @param s The input string.
	 *
	 * @return The hashed string in hexadecimal form.
	 */
	public static String hash(final String s) {
		return EncodingUtil.convertToHex(
			Crypto.generateDigest(
				'SHA256',
				Blob.valueOf(String.isBlank(s) ? '' : s)));
	}

	/**
	 * Replaces special character
	 *
	 * @param s The input string
	 * @param replacedBy replaced by string
	 *
	 * @return The string with all special character replaced with string.
	 */
	public static String replaceSpecialCharacter(final String s, final String replacedBy) {
		if (String.isBlank(s)) return null;
		if (replacedBy == null) replacedBy = '';
		return s.replaceAll('[^a-zA-Z0-9\\s+]', replacedBy);
	}

	/**
	 * Base64 and URL encodes a string.
	 *
	 * @param input The input blob to base64 and URL encode.
	 *
	 * @return Base64, URL-encoded string.
	 */
	public static String base64UrlEncode(final Blob input) {
		if (input == null) return '';

		String output = EncodingUtil.base64Encode(input)
			.replace('+', '-')
			.replace('/', '_');
		while (output.endsWith('=')) {
			output = output.substring(0, output.length() - 1);
		}

		return output;
	}
}
