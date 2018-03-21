public class UUID {

	private static final Pattern uuidPattern =
		Pattern.compile('[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}');

	private final String value;

	private UUID(final String canonical) {
		this.value = canonical.toLowerCase();
	}

	public static UUID randomUUID() {
		String s = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
		return new UUID(
			s.substring(0, 8) + '-'
				+ s.substring(8, 12) + '-'
				+ s.substring(12, 16) + '-'
				+ s.substring(16, 20) + '-'
				+ s.substring(20));
	}

	public static UUID fromString(final String s) {
		if (String.isBlank(s)) throw new StringException(Label.InvalidUUID);

		Matcher m = uuidPattern.matcher(s);
		if (!m.matches()) throw new StringException(Label.InvalidUUID);

		return new UUID(s);
	}

	public static UUID tryParse(final String s) {
		UUID result = null;

		if (String.isNotBlank(s)) {
			try {
				result = fromString(s);
			} catch (Exception ex) {
				// Swallow exception
			}
		}

		return result;
	}

	// Return non-null string for legacy APIs.
	public static String toString(final UUID u) {
		return isDefined(u) ? u.toString() : '';
	}

	override public Integer hashCode() {
		return this.value.hashCode();
	}

	public Boolean equals(Object obj) {
		if (this === obj) return true;

		if (obj == null || !(obj instanceof UUID)) return false;

		return this.value.equals(((UUID)obj).value);
	}

	override public String toString() {
		return this.value;
	}

	public String toShortString() {
		return this.value.replace('-', '');
	}

	public static Boolean isDefined(final UUID u) {
		return u != null && String.isNotBlank(u.value);
	}
}
