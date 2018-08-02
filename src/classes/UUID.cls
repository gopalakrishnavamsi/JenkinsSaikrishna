/**
 * Represents a UUID/GUID.
 */
global class UUID {

	private static final Pattern uuidPattern =
		Pattern.compile('[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}');

	/**
	 * The string representation of the UUID.
	 */
	@AuraEnabled
	public String value { get; private set; }

	private UUID(final String canonical) {
		this.value = canonical.toLowerCase();
	}

	/**
	 * Generates a cryptographically-random UUID.
	 *
	 * @return The generated UUID.
	 */
	public static UUID randomUUID() {
		String s = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
		return new UUID(
			s.substring(0, 8) + '-'
				+ s.substring(8, 12) + '-'
				+ s.substring(12, 16) + '-'
				+ s.substring(16, 20) + '-'
				+ s.substring(20));
	}

	/**
	 * Parses a string as a UUID. Throws a <code>StringException</code> if the input string is blank or does not match the UUID pattern.
	 *
	 * @param s The input string matching the pattern <code>[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}</code>.
	 *
	 * @return The parsed UUID, assuming the input string is valid.
	 */
	global static UUID fromString(final String s) {
		if (String.isBlank(s)) throw new StringException(Label.InvalidUUID);

		Matcher m = uuidPattern.matcher(s);
		if (!m.matches()) throw new StringException(Label.InvalidUUID);

		return new UUID(s);
	}

	/**
	 * Attempts to parse a string as a UUID.
	 *
	 * @param s The input string matching the pattern <code>[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}</code>.
	 *
	 * @return The parsed UUID if the input string is valid, or <code>null</code> if the input string is invalid.
	 */
	global static UUID tryParse(final String s) {
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

	/**
	 * Returns a non-null string representation of a UUID.
	 *
	 * @param u The input UUID.
	 *
	 * @return The string representation of the input UUID, or an empty string if the input UUID is null or empty.
	 */
	public static String toString(final UUID u) {
		return isDefined(u) ? u.toString() : '';
	}

	/**
	 * Generates a hash code for the UUID based on the value.
	 *
	 * @return The generated hash code.
	 */
	override public Integer hashCode() {
		return this.value.hashCode();
	}

	/**
	 * Compares an object to the UUID for value equality.
	 *
	 * @param obj The object to compare.
	 *
	 * @return <code>true</code> if the object equals the UUID's value and <code>false</code> otherwise.
	 */
	public Boolean equals(Object obj) {
		if (this === obj) return true;

		if (obj == null || !(obj instanceof UUID)) return false;

		return this.value.equals(((UUID)obj).value);
	}

	/**
	 * Generates the canonical string representation of the UUID. E.g. <code>01234567-89ab-cdef-0123-456789abcdef</code>.
	 *
	 * @return The string representation of the UUID with dashes.
	 */
	override public String toString() {
		return this.value;
	}

	/**
	 * Generates a short form of the string representation of the UUID. E.g. <code>0123456789abcdef0123456789abcdef</code>.
	 *
	 * @return The string representation of the UUID without dashes.
	 */
	public String toShortString() {
		return this.value.replace('-', '');
	}

	/**
	 * Tests whether a UUID is null or has an empty value.
	 *
	 * @param u The input UUID.
	 *
	 * @return <code>true</code> if the input UUID is non-null and has a non-empty value, <code>false</code> otherwise.
	 */
	public static Boolean isDefined(final UUID u) {
		return u != null && String.isNotBlank(u.value);
	}
}
