/*
This class contains utility methods for dealing with strings to/from string-value-only APIs, and handles magic values
relied upon by the client. In an ideal world, this wouldn't be necessary. However, there is still much spaghetti to
untangle upstream, and the v2 DocuSign APIs serialize all primitive types as strings.
 */
public class StringUtils {

	private static final Pattern emailPattern = Pattern.compile(
		'^(?:[a-z0-9!#$%&\'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&\'*+/=?^_`{|}~-]+)*|"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])$');

	public static final String ENCODING = 'UTF-8';

	public static String encode(final String s) {
		if (String.isBlank(s)) return '';
		return EncodingUtil.UrlEncode(s, ENCODING);
	}

	public static String decode(final String s) {
		if (String.isBlank(s)) return '';
		return EncodingUtil.UrlDecode(s, ENCODING);
	}

	public static Boolean parseBoolean(final String s) {
		return String.isNotBlank(s) && (s == '1' || Boolean.valueOf(s));
	}

	public static Boolean parseBoolean(final String s, final Boolean defaultValue) {
		if (String.isBlank(s)) return defaultValue; else return s == '1' || Boolean.valueOf(s);
	}

	public static Decimal parseDecimal(final String s) {
		try {
			return String.isBlank(s) ? null : Decimal.valueOf(s);
		} catch (Exception ex) {
			return null;
		}
	}

	public static Integer parseInteger(final String s) {
		try {
			return String.isBlank(s) ? null : Integer.valueOf(s);
		} catch (Exception ex) {
			return null;
		}
	}

	public static Integer parseInteger(final String s, final Integer defaultValue) {
		try {
			return String.isBlank(s) ? defaultValue : Integer.valueOf(s);
		} catch (Exception ex) {
			return defaultValue;
		}
	}

	public static String fromString(final String s) {
		return String.isBlank(s) || s == Label.UndefinedString ? null : s;
	}

	public static DateTime parseDateTime(final String s) {
		return String.isBlank(s) ? null : (DateTime)JSON.deserialize('"' + s + '"', DateTime.class);
	}

	public static String mkName(final String firstName, final String lastName) {
		String name = '';
		if (String.isNotBlank(firstName)) name += firstName.trim();
		if (String.isNotBlank(lastName)) name += ' ' + lastName.trim();
		return name.trim();
	}

	public static Boolean isValidEmail(final String email) {
		return String.isNotBlank(email) && emailPattern.matcher(email.trim().toLowerCase()).matches();
	}

	public static String replaceUserTags(final String param) {
		if (String.isEmpty(param)) {
			return param;
		} else {
			return param
				.replace('[FirstName]', ((UserInfo.getFirstName() == null) ? '' : UserInfo.getFirstName()))
				.replace('[LastName]', ((UserInfo.getLastName() == null) ? '' : UserInfo.getLastName()))
				.replace('[Email]', ((UserInfo.getUserEmail() == null) ? '' : UserInfo.getUserEmail()));
		}
	}

	public static String replaceNoteTags(final String s) {
		if (String.isBlank(s)) return null;

		return s.replace('_COMMA_', ',')
			.replace('_SEMI_', ';')
			.replace('_TILDE_', '~')
			.replace('\\n', '\n');
	}
}
