public class SigningGroup {

	public Integer id { get; private set; }
	public String name { get; private set; }
	public List<Member> members { get; private set; }
	public Boolean isValid { get; private set; }

	public SigningGroup(final Integer id, final String name, final List<Member> members) {
		this.id = id;
		this.name = name;
		this.members = members == null ? new List<Member>() : members;
		this.isValid = !this.members.isEmpty();
	}

	public class Member {
		public String username { get; private set; }
		public String email { get; private set; }

		public Member(final String username, final String email) {
			this.username = username;
			this.email = email;
		}
	}
}
