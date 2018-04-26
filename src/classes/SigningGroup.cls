/**
 * A DocuSign signing group.
 */
public class SigningGroup {
	/**
	 * The DocuSign signing group ID.
	 */
	public Integer id { get; private set; }
	/**
	 * The DocuSign signing group name.
	 */
	public String name { get; private set; }
	/**
	 * The DocuSign signing group members.
	 */
	public List<Member> members { get; private set; }
	/**
	 * Whether or not the signing group is valid for envelope recipients. This depends on the signing group having one
	 * or more members.
	 */
	public Boolean isValid { get; private set; }

	/**
	 * Constructs a DocuSign signing group.
	 *
	 * @param id The DocuSign signing group ID.
	 * @param name The DocuSign signing group name.
	 * @param members The DocuSign signing group members.
	 */
	public SigningGroup(final Integer id, final String name, final List<Member> members) {
		this.id = id;
		this.name = name;
		this.members = members == null ? new List<Member>() : members;
		this.isValid = !this.members.isEmpty();
	}

	/**
	 * A DocuSign signing group member.
	 */
	public class Member {
		/**
		 * The member username.
		 */
		public String username { get; private set; }
		/**
		 * The member email.
		 */
		public String email { get; private set; }

		/**
		 * Constructs a DocuSign signing group member.
		 *
		 * @param username The member username.
		 * @param email The member email.
		 */
		public Member(final String username, final String email) {
			this.username = username;
			this.email = email;
		}
	}

	/**
	 * Converts the signing group to a recipient signing group.
	 *
	 * @return The recipient signing group.
	 */
	public Recipient.SigningGroup toRecipientSigningGroup() {
		return new Recipient.SigningGroup(this.id, this.name);
	}
}
